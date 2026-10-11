"""
JOB SeArCh — Multi-Source Job Scraper
Scrapes jobs from public ATS APIs (Greenhouse, Lever) and public remote boards.
No credentials needed — these are all publicly accessible JSON endpoints.
"""

import html as html_module
import re
import socket
import ipaddress
import time
from urllib.parse import urlparse, urljoin, parse_qs
import requests
from bs4 import BeautifulSoup
from dataclasses import dataclass, field, asdict
from config import Config


@dataclass
class ScrapedJob:
    """Standardized job object from any source."""

    title: str
    company: str
    location: str
    is_remote: bool
    description: str  # raw HTML stripped to plain text
    job_url: str
    source: str  # "greenhouse", "lever", "remoteok"
    salary_min: int = 0
    salary_max: int = 0
    tags: list[str] = field(default_factory=list)
    posted_at: str = ""  # ISO timestamp or relative

    def to_dict(self) -> dict:
        return asdict(self)


# ──────────────────────────────────────────
# Security & URL Validation (SSRF Prevention)
# ──────────────────────────────────────────

def is_safe_url(target_url: str) -> bool:
    """
    Validate that target_url uses http/https and does not resolve
    to loopback, private RFC-1918, link-local, or cloud metadata addresses.
    """
    if not target_url or not isinstance(target_url, str):
        return False
    target_url = target_url.strip()
    if not (target_url.startswith("http://") or target_url.startswith("https://")):
        target_url = "https://" + target_url

    try:
        parsed = urlparse(target_url)
    except Exception:
        return False

    if parsed.scheme not in ("http", "https"):
        return False

    hostname = parsed.hostname
    if not hostname:
        return False

    # Block common literal localhost/loopback names
    if hostname.lower() in ("localhost", "127.0.0.1", "0.0.0.0", "::1"):
        return False

    try:
        addr_info = socket.getaddrinfo(hostname, None)
        for entry in addr_info:
            ip_str = entry[4][0]
            ip_obj = ipaddress.ip_address(ip_str)
            if (
                ip_obj.is_private
                or ip_obj.is_loopback
                or ip_obj.is_link_local
                or ip_obj.is_reserved
                or ip_obj.is_multicast
            ):
                return False
        return True
    except Exception:
        # If hostname cannot be resolved, reject
        return False


# ──────────────────────────────────────────
# Utility: Strip HTML tags to plain text
# ──────────────────────────────────────────

def strip_html(html: str) -> str:
    """Remove HTML tags, unescape entities, and collapse whitespace."""
    if not html:
        return ""
    # First unescape HTML entities like &lt; &gt; &amp;
    text = html_module.unescape(html)
    # Then strip actual HTML tags
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def matches_keywords(text: str, keywords: list[str]) -> bool:
    """Check if the text contains at least one keyword (case-insensitive)."""
    text_lower = text.lower()
    return any(kw in text_lower for kw in keywords)


def detect_remote(location: str, title: str, description: str) -> bool:
    """Heuristic to detect if a job is remote-friendly."""
    combined = f"{location} {title} {description}".lower()
    remote_signals = ["remote", "work from home", "distributed", "anywhere", "wfh"]
    return any(signal in combined for signal in remote_signals)


def extract_salary_range(text: str) -> tuple[int, int]:
    """Try to extract salary range from description text."""
    # Match patterns like $120,000 - $180,000 or $120k-$180k
    pattern = r"\$\s*([\d,]+)\s*[kK]?\s*[-–to]+\s*\$?\s*([\d,]+)\s*[kK]?"
    match = re.search(pattern, text)
    if match:
        low = int(match.group(1).replace(",", ""))
        high = int(match.group(2).replace(",", ""))
        # If values look like shorthand (e.g., 120 = 120k)
        if low < 1000:
            low *= 1000
        if high < 1000:
            high *= 1000
        return low, high
    return 0, 0


# ──────────────────────────────────────────
# Greenhouse Public API Scraper
# ──────────────────────────────────────────
# Docs: https://developers.greenhouse.io/job-board.html
# Endpoint: https://boards-api.greenhouse.io/v1/boards/{board_token}/jobs

class GreenhouseScraper:
    """Scrapes jobs from Greenhouse public board API (free, no auth needed)."""

    BASE_URL = "https://boards-api.greenhouse.io/v1/boards"

    def scrape(self, board_token: str, max_jobs: int = 50) -> list[ScrapedJob]:
        """Fetch all jobs from a Greenhouse board."""
        jobs = []
        url = f"{self.BASE_URL}/{board_token}/jobs?content=true"

        try:
            print(f"  [Greenhouse] Fetching: {board_token}...")
            resp = requests.get(url, timeout=15)
            resp.raise_for_status()
            data = resp.json()

            for item in data.get("jobs", [])[:max_jobs]:
                title = item.get("title", "")
                location_name = item.get("location", {}).get("name", "Unknown")
                description_html = item.get("content", "")
                description_text = strip_html(description_html)
                job_url = item.get("absolute_url", "")
                updated_at = item.get("updated_at", "")

                # Filter by keywords
                if not matches_keywords(
                    f"{title} {description_text}", Config.JOB_KEYWORDS
                ):
                    continue

                is_remote = detect_remote(location_name, title, description_text)
                salary_min, salary_max = extract_salary_range(description_text)

                # Extract department/tags from metadata
                tags = []
                for dept in item.get("departments", []):
                    dept_name = dept.get("name", "")
                    if dept_name:
                        tags.append(dept_name)

                jobs.append(
                    ScrapedJob(
                        title=title,
                        company=board_token.replace("-", " ").title(),
                        location=location_name,
                        is_remote=is_remote,
                        description=description_text[:3000],  # cap length
                        job_url=job_url,
                        source="greenhouse",
                        salary_min=salary_min,
                        salary_max=salary_max,
                        tags=tags,
                        posted_at=updated_at,
                    )
                )

            print(f"  [Greenhouse] {board_token}: {len(jobs)} jobs matched")

        except requests.RequestException as e:
            print(f"  [Greenhouse] Error scraping {board_token}: {e}")

        return jobs


# ──────────────────────────────────────────
# Lever Public API Scraper
# ──────────────────────────────────────────
# Endpoint: https://api.lever.co/v0/postings/{company}?mode=json

class LeverScraper:
    """Scrapes jobs from Lever public postings API (free, no auth needed)."""

    BASE_URL = "https://api.lever.co/v0/postings"

    def scrape(self, company_slug: str, max_jobs: int = 50) -> list[ScrapedJob]:
        """Fetch all jobs from a Lever company page."""
        jobs = []
        url = f"{self.BASE_URL}/{company_slug}?mode=json"

        try:
            print(f"  [Lever] Fetching: {company_slug}...")
            resp = requests.get(url, timeout=15)
            resp.raise_for_status()
            postings = resp.json()

            for item in postings[:max_jobs]:
                title = item.get("text", "")
                categories = item.get("categories", {})
                location_name = categories.get("location", "Unknown")
                team = categories.get("team", "")
                commitment = categories.get("commitment", "")
                description_html = item.get("descriptionPlain", "") or strip_html(
                    item.get("description", "")
                )
                lists_html = item.get("lists", [])
                # Append list content to description
                for lst in lists_html:
                    description_html += " " + strip_html(lst.get("content", ""))

                job_url = item.get("hostedUrl", "")
                created_at = item.get("createdAt", "")

                # Filter by keywords
                if not matches_keywords(
                    f"{title} {description_html}", Config.JOB_KEYWORDS
                ):
                    continue

                is_remote = detect_remote(
                    f"{location_name} {commitment}", title, description_html
                )
                salary_min, salary_max = extract_salary_range(description_html)

                tags = []
                if team:
                    tags.append(team)
                if commitment:
                    tags.append(commitment)

                jobs.append(
                    ScrapedJob(
                        title=title,
                        company=company_slug.replace("-", " ").title(),
                        location=location_name,
                        is_remote=is_remote,
                        description=description_html[:3000],
                        job_url=job_url,
                        source="lever",
                        salary_min=salary_min,
                        salary_max=salary_max,
                        tags=tags,
                        posted_at=str(created_at),
                    )
                )

            print(f"  [Lever] {company_slug}: {len(jobs)} jobs matched")

        except requests.RequestException as e:
            print(f"  [Lever] Error scraping {company_slug}: {e}")

        return jobs


# ──────────────────────────────────────────
# RemoteOK Public API Scraper
# ──────────────────────────────────────────
# Endpoint: https://remoteok.com/api (free, public JSON)

class RemoteOKScraper:
    """Scrapes jobs from RemoteOK public API (free, no auth needed)."""

    API_URL = "https://remoteok.com/api"

    def scrape(self, max_jobs: int = 50) -> list[ScrapedJob]:
        """Fetch remote jobs from RemoteOK."""
        jobs = []

        try:
            print("  [RemoteOK] Fetching remote jobs...")
            resp = requests.get(
                self.API_URL,
                timeout=15,
                headers={"User-Agent": "JOBSeArCh-Scraper/1.0"},
            )
            resp.raise_for_status()
            data = resp.json()

            # First item is metadata, skip it
            for item in data[1 : max_jobs + 1]:
                title = item.get("position", "")
                company = item.get("company", "Unknown")
                location = item.get("location", "Remote")
                description = strip_html(item.get("description", ""))
                job_url = item.get("url", "")
                tags = item.get("tags", [])
                salary_min = item.get("salary_min", 0) or 0
                salary_max = item.get("salary_max", 0) or 0
                date = item.get("date", "")

                if not matches_keywords(
                    f"{title} {description} {' '.join(tags)}", Config.JOB_KEYWORDS
                ):
                    continue

                jobs.append(
                    ScrapedJob(
                        title=title,
                        company=company,
                        location=location if location else "Remote",
                        is_remote=True,  # RemoteOK is all remote
                        description=description[:3000],
                        job_url=job_url,
                        source="remoteok",
                        salary_min=salary_min,
                        salary_max=salary_max,
                        tags=tags[:6],
                        posted_at=date,
                    )
                )

            print(f"  [RemoteOK] {len(jobs)} jobs matched")

        except requests.RequestException as e:
            print(f"  [RemoteOK] Error: {e}")

        return jobs


# ──────────────────────────────────────────
# AshbyHQ Public API Scraper
# ──────────────────────────────────────────
# Endpoint: https://api.ashbyhq.com/posting-api/job-board/{board_name}

class AshbyScraper:
    """Scrapes jobs from AshbyHQ public job board API (free, no auth needed)."""

    BASE_URL = "https://api.ashbyhq.com/posting-api/job-board"

    def scrape(self, board_name: str, max_jobs: int = 50) -> list[ScrapedJob]:
        """Fetch all jobs from an Ashby board."""
        jobs = []
        url = f"{self.BASE_URL}/{board_name}"

        try:
            print(f"  [Ashby] Fetching: {board_name}...")
            resp = requests.get(url, timeout=15)
            resp.raise_for_status()
            data = resp.json()

            for item in data.get("jobs", [])[:max_jobs]:
                title = item.get("title", "")
                location_name = item.get("location", "Remote")
                is_remote = bool(item.get("isRemote", False)) or detect_remote(
                    location_name, title, ""
                )
                job_url = item.get("jobUrl", "")
                dept = item.get("department", "")
                desc = strip_html(item.get("descriptionHtml", ""))
                salary_min, salary_max = extract_salary_range(desc)

                tags = [dept] if dept else []

                jobs.append(
                    ScrapedJob(
                        title=title,
                        company=board_name.replace("-", " ").title(),
                        location=location_name,
                        is_remote=is_remote,
                        description=desc[:3000],
                        job_url=job_url,
                        source="ashby",
                        salary_min=salary_min,
                        salary_max=salary_max,
                        tags=tags,
                        posted_at=item.get("publishedAt", ""),
                    )
                )

            print(f"  [Ashby] {board_name}: {len(jobs)} jobs matched")
        except requests.RequestException as e:
            print(f"  [Ashby] Error scraping {board_name}: {e}")

        return jobs


# ──────────────────────────────────────────
# Generic Career Webpage Scraper
# ──────────────────────────────────────────

class GenericWebScraper:
    """Heuristic crawler for arbitrary company career pages with Scrapling anti-bot fallback."""

    @staticmethod
    def _is_cloudflare_blocked(status_code: int, html_text: str) -> bool:
        """Detect if Cloudflare or anti-bot challenge blocked the request."""
        if status_code in (403, 503):
            return True
        sample = (html_text or "")[:2500].lower()
        signals = [
            "cloudflare",
            "turnstile",
            "just a moment...",
            "checking your browser",
            "enable javascript and cookies",
            "cf-chl-bypass",
            "cf-mitigated",
            "attention required! | cloudflare",
        ]
        return any(s in sample for s in signals)

    @staticmethod
    def _fetch_with_scrapling(url: str) -> str:
        """Fallback engine: Uses Scrapling's StealthyFetcher to bypass Cloudflare Turnstile."""
        try:
            from scrapling.fetchers import StealthyFetcher
            print(f"  [Scrapling] Engaging StealthyFetcher for anti-bot bypass on {url}...")
            fetcher = StealthyFetcher()
            # solve_cloudflare=True automatically solves Cloudflare Turnstile / verification challenges
            page = fetcher.fetch(url, solve_cloudflare=True)
            return page.html or ""
        except ImportError:
            print("  [Scrapling] scrapling package not available.")
            return ""
        except Exception as e:
            print(f"  [Scrapling] StealthyFetcher bypass failed: {e}")
            return ""

    def scrape(self, url: str, max_jobs: int = 40) -> list[ScrapedJob]:
        if not is_safe_url(url):
            raise ValueError(f"Restricted or invalid target URL: '{url}'. Only public HTTP/HTTPS URLs are allowed.")

        jobs = []
        headers = {
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        }

        html_content = ""
        try:
            print(f"  [GenericCrawler] Fast crawl: {url}...")
            resp = requests.get(url, headers=headers, timeout=12)
            if self._is_cloudflare_blocked(resp.status_code, resp.text):
                print(f"  [GenericCrawler] Cloudflare challenge detected ({resp.status_code}). Triggering Scrapling fallback...")
                html_content = self._fetch_with_scrapling(url)
            else:
                resp.raise_for_status()
                html_content = resp.text
        except requests.RequestException as e:
            print(f"  [GenericCrawler] Direct request failed ({e}). Falling back to Scrapling...")
            html_content = self._fetch_with_scrapling(url)

        if not html_content:
            return []

        try:
            soup = BeautifulSoup(html_content, "html.parser")

            # Extract company name from meta or title
            company = "Target Company"
            og_site = soup.find("meta", property="og:site_name")
            if og_site and og_site.get("content"):
                company = og_site["content"].strip()
            elif soup.title and soup.title.string:
                title_clean = soup.title.string.split("|")[0].split("-")[0].strip()
                if title_clean:
                    company = title_clean

            seen_urls = set()
            job_keywords = ["job", "career", "position", "opening", "vacancy", "role"]

            for a in soup.find_all("a", href=True):
                href = a["href"].strip()
                text = a.get_text(strip=True)

                if not href or href.startswith("javascript:") or href.startswith("mailto:"):
                    continue

                full_url = urljoin(url, href)
                if full_url in seen_urls:
                    continue

                href_lower = href.lower()
                text_lower = text.lower()

                # Check if link points to an individual role
                is_candidate = any(kw in href_lower for kw in job_keywords) or any(
                    role_word in text_lower
                    for role_word in [
                        "engineer",
                        "developer",
                        "designer",
                        "manager",
                        "lead",
                        "analyst",
                        "intern",
                        "architect",
                        "specialist",
                    ]
                )

                if is_candidate and 4 < len(text) < 100:
                    seen_urls.add(full_url)
                    is_remote = detect_remote("", text, "")
                    jobs.append(
                        ScrapedJob(
                            title=text,
                            company=company,
                            location="See Posting (Remote / Hybrid)",
                            is_remote=is_remote,
                            description=f"Open role discovered at {url}. Click link for complete job description and application details.",
                            job_url=full_url,
                            source="custom_url",
                            salary_min=0,
                            salary_max=0,
                            tags=["Careers"],
                            posted_at="Recent",
                        )
                    )
                    if len(jobs) >= max_jobs:
                        break

            print(f"  [GenericCrawler] Found {len(jobs)} postings from {url}")
        except Exception as e:
            print(f"  [GenericCrawler] Error parsing {url}: {e}")

        return jobs


# ──────────────────────────────────────────
# Smart Custom URL Router
# ──────────────────────────────────────────

def scrape_custom_url(url: str, max_jobs: int = 50) -> list[ScrapedJob]:
    """Smart router: extracts jobs from any Greenhouse, Lever, Ashby, or generic careers page URL."""
    url = url.strip()
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url

    if not is_safe_url(url):
        raise ValueError(f"Restricted or invalid target URL: '{url}'. Only public HTTP/HTTPS URLs are allowed.")

    parsed = urlparse(url)
    netloc = parsed.netloc.lower()
    path = parsed.path.strip("/")
    parts = [p for p in path.split("/") if p]

    # 1. Greenhouse Detection
    # Examples:
    # boards.greenhouse.io/figma
    # job-boards.greenhouse.io/stripe
    # boards.greenhouse.io/embed/job_board?for=stripe
    if "greenhouse.io" in netloc:
        token = ""
        if "for=" in parsed.query:
            query_dict = parse_qs(parsed.query)
            token = query_dict.get("for", [""])[0]
        elif parts:
            token = parts[0]
            if token in ["embed", "v1", "job-board", "job_board"] and len(parts) > 1:
                token = parts[1]
        if token:
            return GreenhouseScraper().scrape(token, max_jobs=max_jobs)

    # 2. Lever Detection
    # Examples: jobs.lever.co/netflix, api.lever.co/v0/postings/netflix
    if "lever.co" in netloc:
        slug = parts[0] if parts else ""
        if slug == "v0" and len(parts) > 2:
            slug = parts[2]
        if slug:
            return LeverScraper().scrape(slug, max_jobs=max_jobs)

    # 3. Ashby Detection
    # Examples: jobs.ashbyhq.com/linear, jobs.ashbyhq.com/openai
    if "ashbyhq.com" in netloc:
        slug = parts[0] if parts else ""
        if slug:
            return AshbyScraper().scrape(slug, max_jobs=max_jobs)

    # 4. Fallback: Generic Web Crawler
    return GenericWebScraper().scrape(url, max_jobs=max_jobs)


# ──────────────────────────────────────────
# Master Scraper Orchestrator
# ──────────────────────────────────────────

def scrape_all_sources() -> list[ScrapedJob]:
    """Run all scrapers and return a combined, deduplicated list."""
    all_jobs: list[ScrapedJob] = []

    greenhouse = GreenhouseScraper()
    lever = LeverScraper()
    remoteok = RemoteOKScraper()

    max_per = Config.MAX_JOBS_PER_SOURCE

    # Greenhouse boards
    for board in Config.GREENHOUSE_BOARDS:
        jobs = greenhouse.scrape(board, max_jobs=max_per)
        all_jobs.extend(jobs)
        time.sleep(0.5)  # Be polite to the API

    # Lever companies
    for company in Config.LEVER_COMPANIES:
        jobs = lever.scrape(company, max_jobs=max_per)
        all_jobs.extend(jobs)
        time.sleep(0.5)

    # Ashby companies
    ashby = AshbyScraper()
    for company in Config.ASHBY_COMPANIES:
        jobs = ashby.scrape(company, max_jobs=max_per)
        all_jobs.extend(jobs)
        time.sleep(0.5)

    # RemoteOK
    all_jobs.extend(remoteok.scrape(max_jobs=max_per))

    # Deduplicate by job_url
    seen_urls = set()
    unique_jobs = []
    for job in all_jobs:
        if job.job_url and job.job_url not in seen_urls:
            seen_urls.add(job.job_url)
            unique_jobs.append(job)

    print(f"\n✓ Total unique jobs scraped: {len(unique_jobs)}")
    return unique_jobs


# ──────────────────────────────────────────
# Standalone test
# ──────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("JOB SeArCh — Job Scraper Test Run")
    print("=" * 60)

    jobs = scrape_all_sources()

    print(f"\nSample of first 5 jobs:")
    for i, job in enumerate(jobs[:5]):
        print(f"\n  [{i+1}] {job.title}")
        print(f"      Company:  {job.company}")
        print(f"      Location: {job.location} {'(Remote)' if job.is_remote else ''}")
        print(f"      Salary:   ${job.salary_min:,} - ${job.salary_max:,}")
        print(f"      Tags:     {', '.join(job.tags[:4])}")
        print(f"      URL:      {job.job_url[:60]}...")
        print(f"      Desc:     {job.description[:120]}...")

# 🔌 JOB SeArCh — API & Backend Reference

The **JOB SeArCh** backend service is a high-performance Python 3.12 FastAPI microservice providing live ATS scraping, custom career page parsing, telemetry logging, and local automation support.

- **Base URL (Local)**: `http://localhost:8000`
- **Interactive Documentation**: Swagger UI at `http://localhost:8000/docs`, ReDoc at `http://localhost:8000/redoc`
- **Rate Limiting**: Managed via `slowapi` based on client IP.

---

## 📑 Endpoints Overview

| Method | Endpoint | Rate Limit | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | 60/min | System and scraper health telemetry |
| `POST` | `/api/scrape-url` | 10/min | Live headless extraction from an arbitrary careers URL |
| `POST` | `/api/scrape-all` | 2/hour | Batch synchronization across Greenhouse, Lever, and Ashby boards |

---

## 1. System Health Check

### `GET /api/health`
Returns system status, active version, and the operational readiness of scraper modules.

#### Response (`200 OK`)
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "services": {
    "scraper": "online",
    "greenhouse": "ready",
    "lever": "ready",
    "ashby": "ready",
    "generic_crawler": "ready",
    "rate_limiter": "active"
  }
}
```

#### Example cURL
```bash
curl -X GET "http://localhost:8000/api/health"
```

---

## 2. Live Custom URL Scraper

### `POST /api/scrape-url`
Extracts structured job openings from an arbitrary company careers URL or job posting page. Automatically extracts job titles, salary bands, location, remote status, tags, and direct application links.

#### Request Body (`application/json`)
```json
{
  "url": "https://linear.app/careers",
  "max_jobs": 25
}
```

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `url` | `string` | **Yes** | Fully qualified URL of the target careers portal |
| `max_jobs` | `integer` | No | Maximum count of jobs to parse (default: 50) |

#### Response (`200 OK`)
```json
{
  "status": "success",
  "url": "https://linear.app/careers",
  "count": 2,
  "jobs": [
    {
      "title": "Senior Frontend Engineer",
      "company": "Linear",
      "location": "San Francisco, CA / Remote",
      "is_remote": true,
      "salary_min": 170000,
      "salary_max": 210000,
      "job_url": "https://jobs.ashbyhq.com/linear/1a2b3c",
      "description": "We are seeking a senior engineer to craft fast, responsive UI interfaces...",
      "tags": ["Frontend", "TypeScript", "React", "Live Scraped"],
      "source": "ashby",
      "posted_at": "2026-03-28"
    }
  ]
}
```

#### Error Responses
- **`400 Bad Request`**: URL is empty, missing, or malformed (< 4 characters).
  ```json
  {
    "detail": "A valid URL is required."
  }
  ```
- **`429 Too Many Requests`**: Rate limit exceeded (limit: 10 calls per minute).
- **`500 Internal Server Error`**: Target site inaccessible or scraper error.

#### Example cURL
```bash
curl -X POST "http://localhost:8000/api/scrape-url" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://boards.greenhouse.io/figma", "max_jobs": 15}'
```

---

## 3. Batch Board Synchronization

### `POST /api/scrape-all`
Initiates a batch synchronization across all configured ATS targets (Greenhouse, Lever, Ashby) defined in `backend/config.py`.

#### Response (`200 OK`)
```json
{
  "status": "success",
  "scraped_count": 84,
  "sources": ["greenhouse", "lever", "ashby"],
  "jobs": [...]
}
```

---

## 🏗️ Data Model Specifications

### `ScrapedJob` (Python Dataclass)
```python
@dataclass
class ScrapedJob:
    title: str
    company: str
    location: str
    is_remote: bool
    description: str
    job_url: str
    source: str          # "greenhouse" | "lever" | "ashby" | "custom_url"
    salary_min: int = 0
    salary_max: int = 0
    tags: list[str] = field(default_factory=list)
    posted_at: str = ""
```

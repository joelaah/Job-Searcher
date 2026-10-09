"""
Unit & Integration Tests for JOB SeArCh FastAPI Backend
Run with: python -m unittest test_server.py
"""

import unittest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from server import app
from scraper import ScrapedJob


class TestJobSearchAPI(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_health_check(self):
        """Verify the health check endpoint returns 200 and online services."""
        response = self.client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["version"], "2.0.0")
        self.assertIn("services", data)
        self.assertEqual(data["services"]["scraper"], "online")
        self.assertEqual(data["services"]["greenhouse"], "ready")
        self.assertEqual(data["services"]["lever"], "ready")
        self.assertEqual(data["services"]["ashby"], "ready")
        self.assertEqual(data["services"]["auto_apply"], "ready")

    def test_scrape_url_empty_validation(self):
        """Verify endpoint rejects empty or whitespace-only URLs with 400."""
        response = self.client.post("/api/scrape-url", json={"url": "   ", "max_jobs": 10})
        self.assertEqual(response.status_code, 400)
        self.assertIn("A valid URL is required", response.json()["detail"])

    def test_scrape_url_short_validation(self):
        """Verify endpoint rejects too-short URLs (< 4 chars) with 400."""
        response = self.client.post("/api/scrape-url", json={"url": "ab", "max_jobs": 10})
        self.assertEqual(response.status_code, 400)

    @patch("server.scrape_custom_url")
    def test_scrape_url_success(self, mock_scrape):
        """Verify successful scraping returns structured jobs matching ScrapedJob schema."""
        mock_job = ScrapedJob(
            title="Senior Systems Engineer",
            company="Acme Corp",
            location="Remote",
            is_remote=True,
            salary_min=160000,
            salary_max=200000,
            job_url="https://acme.com/jobs/1",
            description="High-throughput distributed systems development.",
            tags=["Go", "Distributed Systems", "Cloud"],
            source="custom_url",
            posted_at="2026-03-30",
        )
        mock_scrape.return_value = [mock_job]

        response = self.client.post(
            "/api/scrape-url",
            json={"url": "https://acme.com/careers", "max_jobs": 25}
        )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["count"], 1)
        job = data["jobs"][0]
        self.assertEqual(job["title"], "Senior Systems Engineer")
        self.assertEqual(job["company"], "Acme Corp")
        self.assertEqual(job["salary_min"], 160000)
        self.assertEqual(job["job_url"], "https://acme.com/jobs/1")
        self.assertTrue(job["is_remote"])

    def test_scraped_job_model_to_dict(self):
        """Verify ScrapedJob dataclass serialization and formatting."""
        job = ScrapedJob(
            title="AI Researcher",
            company="DeepMind Partner",
            location="San Francisco, CA",
            is_remote=False,
            salary_min=180000,
            salary_max=240000,
            job_url="https://example.com/apply/42",
            description="Developing next-generation reasoning agents.",
            tags=["AI", "PyTorch", "Transformers"],
            source="greenhouse",
        )
        d = job.to_dict()
        self.assertEqual(d["title"], "AI Researcher")
        self.assertEqual(d["company"], "DeepMind Partner")
        self.assertEqual(d["tags"], ["AI", "PyTorch", "Transformers"])
        self.assertEqual(d["source"], "greenhouse")
        self.assertEqual(d["job_url"], "https://example.com/apply/42")
        self.assertFalse(d["is_remote"])

    def test_ssrf_blocking_loopback(self):
        """Verify endpoint rejects loopback IP addresses (SSRF prevention)."""
        response = self.client.post(
            "/api/scrape-url",
            json={"url": "http://127.0.0.1:8000/internal", "max_jobs": 10},
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Restricted or invalid target URL", response.json()["detail"])

    def test_ssrf_blocking_metadata(self):
        """Verify endpoint rejects cloud metadata IP addresses."""
        response = self.client.post(
            "/api/scrape-url",
            json={"url": "http://169.254.169.254/latest/meta-data/", "max_jobs": 10},
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Restricted or invalid target URL", response.json()["detail"])

    def test_ssrf_blocking_private_subnet(self):
        """Verify endpoint rejects private RFC 1918 subnets."""
        response = self.client.post(
            "/api/scrape-url",
            json={"url": "http://192.168.1.1/admin", "max_jobs": 10},
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Restricted or invalid target URL", response.json()["detail"])

    def test_cors_trusted_origin(self):
        """Verify CORS allows trusted GitHub Pages origin."""
        response = self.client.options(
            "/api/scrape-url",
            headers={
                "Origin": "https://joelaah.github.io",
                "Access-Control-Request-Method": "POST",
            },
        )
        self.assertEqual(
            response.headers.get("access-control-allow-origin"),
            "https://joelaah.github.io",
        )

    def test_work_authorization_international_applicant(self):
        """Verify international candidate in India is not misrepresented for US roles."""
        from auto_applier.question_answerer import determine_work_auth_answer, answer_screening_question

        india_candidate = {
            "country": "India",
            "work_auth_country": "India",
            "authorized_to_work": True,
            "requires_sponsorship": False,
            "authorized_in_us": False,
            "requires_us_sponsorship": True,
            "authorized_countries": ["India"],
        }

        # US work authorization question -> Must answer No
        ans_us_auth = determine_work_auth_answer(
            "Are you legally authorized to work in the United States?",
            india_candidate,
        )
        self.assertEqual(ans_us_auth, "No")

        # US work auth with regex \bus\b phrasing -> Must answer No
        ans_us_word_boundary = determine_work_auth_answer(
            "Do you have US work authorization?",
            india_candidate,
        )
        self.assertEqual(ans_us_word_boundary, "No")

        # Compound sponsorship question mentioning work authorization -> Must answer Yes
        ans_compound_sponsor = determine_work_auth_answer(
            "Do you now or in the future require sponsorship for work authorization in the US?",
            india_candidate,
        )
        self.assertEqual(ans_compound_sponsor, "Yes")

        # Inverted negative sponsorship question -> Must answer No (they DO require sponsorship)
        ans_negative_sponsor = determine_work_auth_answer(
            "Will you NOT require visa sponsorship to work in the United States?",
            india_candidate,
        )
        self.assertEqual(ans_negative_sponsor, "No")

        # "Authorized without sponsorship" question -> Must answer No
        ans_auth_without_sponsor = determine_work_auth_answer(
            "Are you legally authorized to work in the United States without sponsorship?",
            india_candidate,
        )
        self.assertEqual(ans_auth_without_sponsor, "No")

        # US visa sponsorship question -> Must answer Yes
        ans_us_sponsor = determine_work_auth_answer(
            "Will you now or in the future require visa sponsorship to work in the United States?",
            india_candidate,
        )
        self.assertEqual(ans_us_sponsor, "Yes")

        # India work authorization -> Must answer Yes
        ans_india_auth = determine_work_auth_answer(
            "Are you legally authorized to work in India?",
            india_candidate,
        )
        self.assertEqual(ans_india_auth, "Yes")

        # India sponsorship -> Must answer No
        ans_india_sponsor = determine_work_auth_answer(
            "Will you require visa sponsorship to work in India?",
            india_candidate,
        )
        self.assertEqual(ans_india_sponsor, "No")

        # Third-party unauthorized country (UK) -> Must answer Yes to sponsorship
        ans_uk_sponsor = determine_work_auth_answer(
            "Will you require visa sponsorship to work in the United Kingdom?",
            india_candidate,
        )
        self.assertEqual(ans_uk_sponsor, "Yes")

        # General screening question wrapper
        ans_screening = answer_screening_question(
            question="Are you authorized to work in the United States?",
            job_title="Software Engineer",
            job_company="Stripe",
            job_description="Remote US role",
            resume_text="Backend engineer in India",
            candidate_info=india_candidate,
        )
        self.assertEqual(ans_screening, "No")

    def test_candidate_profile_work_auth_loading(self):
        """Verify CandidateProfile loads jurisdiction-aware work authorization fields."""
        from candidate_profile import load_profile

        profile = load_profile()
        self.assertEqual(profile.work_auth.country, "India")
        self.assertFalse(profile.work_auth.authorized_in_us)
        self.assertTrue(profile.work_auth.requires_us_sponsorship)
        self.assertIn("India", profile.work_auth.authorized_countries)

        form_dict = profile.to_form_dict()
        self.assertEqual(form_dict["work_auth_country"], "India")
        self.assertFalse(form_dict["authorized_in_us"])
        self.assertTrue(form_dict["requires_us_sponsorship"])

    def test_detect_ats_type(self):
        """Verify ATS type detection across Ashby, Greenhouse, Lever, and Generic URLs."""
        from auto_applier.engine import detect_ats_type, ATSType

        self.assertEqual(
            detect_ats_type("https://jobs.ashbyhq.com/linear/123"),
            ATSType.ASHBY,
        )
        self.assertEqual(
            detect_ats_type("https://boards.greenhouse.io/figma/jobs/456"),
            ATSType.GREENHOUSE,
        )
        self.assertEqual(
            detect_ats_type("https://jobs.lever.co/netflix/789"),
            ATSType.LEVER,
        )
        self.assertEqual(
            detect_ats_type("https://careers.google.com/jobs/results/"),
            ATSType.GENERIC,
        )

    def test_stealth_evasion_script_content(self):
        """Verify stealth script overrides webdriver to false, plugins, and WebGL."""
        from auto_applier.engine import STEALTH_EVASION_SCRIPT

        self.assertIn("webdriver", STEALTH_EVASION_SCRIPT)
        self.assertIn("get: () => false", STEALTH_EVASION_SCRIPT)
        self.assertIn("navigator", STEALTH_EVASION_SCRIPT)
        self.assertIn("window.chrome", STEALTH_EVASION_SCRIPT)
        self.assertIn("PDF Viewer", STEALTH_EVASION_SCRIPT)
        self.assertIn("WebGLRenderingContext", STEALTH_EVASION_SCRIPT)
        self.assertIn("hardwareConcurrency", STEALTH_EVASION_SCRIPT)
        self.assertIn("deviceMemory", STEALTH_EVASION_SCRIPT)


if __name__ == "__main__":
    unittest.main()

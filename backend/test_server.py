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


if __name__ == "__main__":
    unittest.main()

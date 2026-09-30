"""
JOB SeArCh — FastAPI Backend Server
Provides REST endpoints for live job scraping, custom URL crawling,
and zero-knowledge local client automation support.
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from typing import List, Optional
import uvicorn

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from scraper import scrape_custom_url, scrape_all_sources, ScrapedJob, is_safe_url

# Initialize Limiter keyed by client IP address
limiter = Limiter(key_func=get_remote_address, default_limits=["120/minute"])

app = FastAPI(
    title="JOB SeArCh Engine API",
    description="High-performance backend for live job crawling, matching, and application automation.",
    version="1.0.0",
)

# Attach limiter to FastAPI state and register exception handler
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Explicit trusted origins for Flutter Web & local clients (prevents cross-origin attacks)
ALLOWED_ORIGINS = [
    "https://joelaah.github.io",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


class ScrapeUrlRequest(BaseModel):
    url: str
    max_jobs: Optional[int] = 50


class HealthResponse(BaseModel):
    status: str
    version: str
    services: dict


@app.get("/api/health")
@limiter.limit("60/minute")
def health_check(request: Request):
    return {
        "status": "healthy",
        "version": "1.0.0",
        "services": {
            "scraper": "online",
            "greenhouse": "ready",
            "lever": "ready",
            "ashby": "ready",
            "generic_crawler": "ready",
            "rate_limiter": "active",
        },
    }


@app.post("/api/scrape-url")
@limiter.limit("10/minute")
def api_scrape_url(request: Request, payload: ScrapeUrlRequest):
    clean_url = payload.url.strip() if payload.url else ""
    if not clean_url or len(clean_url) < 4:
        raise HTTPException(status_code=400, detail="A valid URL is required.")

    if not is_safe_url(clean_url):
        raise HTTPException(
            status_code=400,
            detail="Restricted or invalid target URL. Only public HTTP/HTTPS URLs are allowed (SSRF protection).",
        )

    try:
        jobs: List[ScrapedJob] = scrape_custom_url(
            url=clean_url, max_jobs=payload.max_jobs or 50
        )
        return {
            "status": "success",
            "url": clean_url,
            "count": len(jobs),
            "jobs": [j.to_dict() for j in jobs],
        }
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to scrape URL: {str(e)}"
        )


@app.post("/api/scrape-all")
@limiter.limit("2/hour")
def api_scrape_all(request: Request):
    try:
        jobs = scrape_all_sources()
        return {
            "status": "success",
            "count": len(jobs),
            "jobs": [j.to_dict() for j in jobs[:100]],
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to run master scrape: {str(e)}"
        )


if __name__ == "__main__":
    uvicorn.run("server:app", host="127.0.0.1", port=8000, reload=True)


"""
JOB SeArCh — FastAPI Backend Server
Provides REST endpoints for live job scraping, custom URL crawling,
and zero-knowledge local client automation support.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from typing import List, Optional
import uvicorn

from scraper import scrape_custom_url, scrape_all_sources, ScrapedJob

app = FastAPI(
    title="JOB SeArCh Engine API",
    description="High-performance backend for live job crawling, matching, and application automation.",
    version="1.0.0",
)

# Enable CORS for Flutter Web (localhost:5000 and all local origins)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
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
def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "services": {
            "scraper": "online",
            "greenhouse": "ready",
            "lever": "ready",
            "ashby": "ready",
            "generic_crawler": "ready",
        },
    }


@app.post("/api/scrape-url")
def api_scrape_url(payload: ScrapeUrlRequest):
    if not payload.url or len(payload.url.strip()) < 4:
        raise HTTPException(status_code=400, detail="A valid URL is required.")

    try:
        jobs: List[ScrapedJob] = scrape_custom_url(
            url=payload.url.strip(), max_jobs=payload.max_jobs or 50
        )
        return {
            "status": "success",
            "url": payload.url.strip(),
            "count": len(jobs),
            "jobs": [j.to_dict() for j in jobs],
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to scrape URL: {str(e)}"
        )


@app.post("/api/scrape-all")
def api_scrape_all():
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

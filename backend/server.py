"""
JOB SeArCh — FastAPI Backend Server
Provides REST endpoints for live job scraping, custom URL crawling,
auto-apply engine, and zero-knowledge local client automation support.
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, HttpUrl
from typing import List, Optional
import uvicorn
import os
import asyncio

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
    version="2.0.0",
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


class AutoApplyRequest(BaseModel):
    job_url: str
    job_title: Optional[str] = ""
    job_company: Optional[str] = ""
    job_description: Optional[str] = ""
    resume_text: Optional[str] = ""
    headless: Optional[bool] = True


class HealthResponse(BaseModel):
    status: str
    version: str
    services: dict


@app.get("/api/health")
@limiter.limit("60/minute")
def health_check(request: Request):
    return {
        "status": "healthy",
        "version": "2.0.0",
        "services": {
            "scraper": "online",
            "greenhouse": "ready",
            "lever": "ready",
            "ashby": "ready",
            "generic_crawler": "ready",
            "auto_apply": "ready",
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


# ═══════════════════════════════════════════════════
# Auto-Apply Engine Endpoints
# ═══════════════════════════════════════════════════


@app.post("/api/auto-apply")
@limiter.limit("5/minute")
def api_auto_apply(request: Request, payload: AutoApplyRequest):
    """
    🚀 Auto-Apply Engine
    
    Launches a Playwright stealth browser, detects the ATS type,
    fills the application form with the candidate profile, and
    returns a structured result with a verification screenshot.
    
    DOES NOT SUBMIT — the user always reviews first.
    """
    clean_url = payload.job_url.strip() if payload.job_url else ""
    if not clean_url or len(clean_url) < 10:
        raise HTTPException(status_code=400, detail="A valid job URL is required.")

    try:
        from auto_applier.engine import run_auto_apply, detect_ats_type

        result = run_auto_apply(
            job_url=clean_url,
            job_title=payload.job_title or "",
            job_company=payload.job_company or "",
            job_description=payload.job_description or "",
            resume_text=payload.resume_text or "",
            headless=payload.headless if payload.headless is not None else True,
        )

        return {
            "status": "success" if result.success else "error",
            "ats_type": result.ats_type,
            "job_url": result.job_url,
            "fields_filled": result.fields_filled,
            "duration_seconds": result.duration_seconds,
            "screenshot_path": result.screenshot_path,
            "log": result.log,
            "error": result.error,
        }
    except ImportError as ie:
        raise HTTPException(
            status_code=500,
            detail=f"Auto-apply dependency missing: {str(ie)}. Run: pip install playwright && python -m playwright install chromium",
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Auto-apply failed: {str(e)}"
        )


@app.get("/api/auto-apply/screenshot/{filename}")
def get_screenshot(filename: str):
    """Serve a verification screenshot from the auto-apply engine."""
    screenshot_dir = os.path.join(os.path.dirname(__file__), "apply_screenshots")
    filepath = os.path.join(screenshot_dir, filename)

    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Screenshot not found.")

    # Prevent path traversal
    real_path = os.path.realpath(filepath)
    real_dir = os.path.realpath(screenshot_dir)
    if not real_path.startswith(real_dir):
        raise HTTPException(status_code=403, detail="Access denied.")

    return FileResponse(filepath, media_type="image/png")


@app.get("/api/profile/status")
@limiter.limit("30/minute")
def profile_status(request: Request):
    """Check if the candidate profile is configured."""
    try:
        from candidate_profile import load_profile

        profile = load_profile()
        return {
            "configured": profile.is_configured,
            "name": profile.full_name,
            "email": profile.email,
            "has_resume": profile.has_resume,
            "fields_filled": sum(1 for v in profile.to_form_dict().values() if v),
            "total_fields": len(profile.to_form_dict()),
        }
    except Exception as e:
        return {
            "configured": False,
            "error": str(e),
        }


@app.get("/api/email/status")
@limiter.limit("30/minute")
def email_status(request: Request):
    """Check configuration and health of email job copilot."""
    try:
        from email_copilot import EmailReader, NotificationManager, EmailCopilot
        reader = EmailReader()
        notifs = NotificationManager.load_notifications()
        jobs = EmailCopilot.load_actionable_jobs()
        return {
            "configured": reader.is_configured(),
            "host": reader.host,
            "user": reader.user,
            "unread_notifications": len([n for n in notifs if not n.get("read", False)]),
            "total_notifications": len(notifs),
            "actionable_jobs": len(jobs),
        }
    except Exception as e:
        return {"configured": False, "error": str(e)}


class EmailScanRequest(BaseModel):
    limit: Optional[int] = 15
    unread_only: Optional[bool] = True
    simulate: Optional[bool] = False
    auto_apply: Optional[bool] = False
    fit_threshold: Optional[int] = 75


@app.post("/api/email/scan")
@limiter.limit("10/minute")
def email_scan(request: Request, payload: EmailScanRequest):
    """Scan inbox or run simulation to process emails, notify on recruiters, and extract jobs."""
    try:
        from email_copilot import EmailCopilot, EmailReader
        reader = EmailReader()
        copilot = EmailCopilot(reader=reader)

        if payload.simulate or not reader.is_configured():
            results = copilot.run_simulation(
                auto_apply_enabled=payload.auto_apply,
                fit_threshold=payload.fit_threshold,
            )
            mode = "simulation"
        else:
            results = copilot.scan_inbox(
                limit=payload.limit or 15,
                unread_only=payload.unread_only if payload.unread_only is not None else True,
                auto_apply_enabled=payload.auto_apply,
                fit_threshold=payload.fit_threshold,
            )
            mode = "live"

        return {"mode": mode, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Email scan failed: {str(e)}")


@app.get("/api/email/notifications")
@limiter.limit("60/minute")
def email_notifications(request: Request):
    """Retrieve notifications triggered by recruiter outreach, interview invites, and high-fit jobs."""
    try:
        from email_copilot import NotificationManager
        return {"notifications": NotificationManager.load_notifications()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/email/jobs")
@limiter.limit("60/minute")
def email_jobs(request: Request):
    """Retrieve actionable jobs extracted from emails."""
    try:
        from email_copilot import EmailCopilot
        return {"jobs": EmailCopilot.load_actionable_jobs()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class EmailApplyRequest(BaseModel):
    job_url: str
    job_title: Optional[str] = ""
    job_company: Optional[str] = ""
    job_description: Optional[str] = ""


@app.post("/api/email/apply")
@limiter.limit("10/minute")
def email_apply(request: Request, payload: EmailApplyRequest):
    """Trigger auto-apply directly for a high-fit job extracted from email."""
    try:
        from candidate_profile import load_profile
        from auto_applier.engine import run_auto_apply
        profile = load_profile()
        result = run_auto_apply(
            job_url=payload.job_url,
            job_title=payload.job_title or "",
            job_company=payload.job_company or "",
            job_description=payload.job_description or "",
            profile=profile,
            headless=True,
        )
        return {"result": result.to_dict()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Auto-apply execution failed: {str(e)}")


if __name__ == "__main__":
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("server:app", host=host, port=port, reload=True)



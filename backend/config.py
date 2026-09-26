"""
JOB SeArCh — Configuration Loader
Loads environment variables and provides typed config access.
"""

import os
from dotenv import load_dotenv

# Load .env from backend directory
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))


class Config:
    """Central configuration loaded from environment variables."""

    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY", "")

    # AI Providers
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    # Scraper settings
    GREENHOUSE_BOARDS: list[str] = [
        b.strip()
        for b in os.getenv(
            "GREENHOUSE_BOARDS",
            "figma,cloudflare,vercel,stripe,gitlab,discord,coinbase",
        ).split(",")
        if b.strip()
    ]

    LEVER_COMPANIES: list[str] = [
        c.strip()
        for c in os.getenv("LEVER_COMPANIES", "anduril,ramp,brex,deel").split(",")
        if c.strip()
    ]

    JOB_KEYWORDS: list[str] = [
        k.strip().lower()
        for k in os.getenv(
            "JOB_KEYWORDS",
            "engineer,developer,software,frontend,backend,fullstack,full-stack,devops,data,machine learning,AI,product",
        ).split(",")
        if k.strip()
    ]

    MAX_JOBS_PER_SOURCE: int = int(os.getenv("MAX_JOBS_PER_SOURCE", "50"))
    SCRAPE_INTERVAL_HOURS: int = int(os.getenv("SCRAPE_INTERVAL_HOURS", "6"))

    # Embedding model config
    EMBEDDING_MODEL: str = "BAAI/bge-base-en-v1.5"  # 768-dim local FastEmbed
    EMBEDDING_DIMENSIONS: int = 768
    GROQ_MODEL: str = "qwen/qwen3.8-27b"
    LLM_MODEL: str = "gemini-2.0-flash"

    @classmethod
    def validate(cls) -> list[str]:
        """Returns a list of missing required config keys."""
        missing = []
        if not cls.SUPABASE_URL:
            missing.append("SUPABASE_URL")
        if not cls.SUPABASE_KEY:
            missing.append("SUPABASE_KEY")
        if not cls.GROQ_API_KEY and not cls.GEMINI_API_KEY:
            missing.append("GROQ_API_KEY (or GEMINI_API_KEY)")
        return missing

    @classmethod
    def summary(cls) -> str:
        """Print a human-readable config summary."""
        return (
            f"  Supabase URL:       {cls.SUPABASE_URL[:40]}...\n"
            f"  Gemini API Key:     {'✓ Set' if cls.GEMINI_API_KEY else '✗ Missing'}\n"
            f"  Greenhouse Boards:  {len(cls.GREENHOUSE_BOARDS)} companies\n"
            f"  Lever Companies:    {len(cls.LEVER_COMPANIES)} companies\n"
            f"  Job Keywords:       {len(cls.JOB_KEYWORDS)} filters\n"
            f"  Max Jobs/Source:    {cls.MAX_JOBS_PER_SOURCE}\n"
            f"  Embedding Model:    {cls.EMBEDDING_MODEL} ({cls.EMBEDDING_DIMENSIONS}d)\n"
            f"  LLM Model:          {cls.LLM_MODEL}"
        )

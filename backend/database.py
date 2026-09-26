"""
JOB SeArCh — Supabase Database Client
Handles all database operations: storing jobs, embeddings, user profiles,
interaction telemetry, and pgvector similarity search.

Prerequisites:
  Run the SQL migration in your Supabase dashboard first (see db_schema.sql).
"""

import json
from supabase import create_client, Client
from config import Config
from scraper import ScrapedJob


# ──────────────────────────────────────────
# Client Initialization
# ──────────────────────────────────────────

_supabase: Client | None = None


def get_client() -> Client:
    """Lazy-initialize the Supabase client."""
    global _supabase
    if _supabase is None:
        if not Config.SUPABASE_URL or not Config.SUPABASE_KEY:
            raise ValueError(
                "SUPABASE_URL and SUPABASE_KEY must be set in your .env file.\n"
                "Sign up for free at https://supabase.com"
            )
        _supabase = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)
    return _supabase


# ──────────────────────────────────────────
# Jobs Table Operations
# ──────────────────────────────────────────

def upsert_jobs(jobs: list[ScrapedJob], embeddings: list[list[float]]) -> int:
    """
    Insert or update jobs in the database with their embedding vectors.

    Uses job_url as the unique key for deduplication — if a job with the
    same URL already exists, it gets updated instead of duplicated.

    Returns the number of jobs upserted.
    """
    client = get_client()
    upserted = 0

    for job, embedding in zip(jobs, embeddings):
        row = {
            "title": job.title,
            "company": job.company,
            "location": job.location,
            "is_remote": job.is_remote,
            "salary_min": job.salary_min,
            "salary_max": job.salary_max,
            "description": job.description,
            "job_url": job.job_url,
            "source": job.source,
            "tags": job.tags,
            "posted_at": job.posted_at if job.posted_at else None,
            "job_embedding": embedding,
        }

        try:
            client.table("jobs").upsert(
                row, on_conflict="job_url"
            ).execute()
            upserted += 1
        except Exception as e:
            print(f"  [DB] Error upserting job '{job.title}': {e}")

    print(f"  [DB] ✓ Upserted {upserted}/{len(jobs)} jobs")
    return upserted


# ──────────────────────────────────────────
# Vector Similarity Search (pgvector)
# ──────────────────────────────────────────

def match_jobs_for_resume(
    resume_embedding: list[float],
    match_threshold: float = 0.65,
    match_count: int = 20,
    filter_remote: bool | None = None,
) -> list[dict]:
    """
    Find the top matching jobs for a resume embedding using pgvector
    cosine similarity search.

    This calls the `match_jobs_for_user` Postgres function we defined
    in the database migration.

    Args:
        resume_embedding: 768-dim vector from the user's resume.
        match_threshold: Minimum cosine similarity (0.0 to 1.0).
        match_count: Maximum number of results to return.
        filter_remote: If True, only return remote jobs. None = no filter.

    Returns:
        List of job dicts with similarity scores, ordered by best match.
    """
    client = get_client()

    result = client.rpc(
        "match_jobs_for_user",
        {
            "query_embedding": resume_embedding,
            "match_threshold": match_threshold,
            "match_count": match_count,
            "filter_remote": filter_remote,
        },
    ).execute()

    jobs = result.data or []
    print(f"  [DB] ✓ Found {len(jobs)} matching jobs (threshold: {match_threshold})")
    return jobs


# ──────────────────────────────────────────
# User Profile Operations
# ──────────────────────────────────────────

def upsert_user_profile(
    user_id: str,
    full_name: str,
    target_roles: list[str],
    preferred_location: str,
    min_salary: int,
    resume_url: str | None,
    parsed_resume_json: dict | None,
    resume_embedding: list[float] | None,
) -> dict:
    """Store or update a user's profile and resume embedding."""
    client = get_client()

    row = {
        "id": user_id,
        "full_name": full_name,
        "target_roles": target_roles,
        "preferred_location": preferred_location,
        "min_salary": min_salary,
        "resume_url": resume_url,
        "parsed_resume_json": json.dumps(parsed_resume_json) if parsed_resume_json else None,
        "resume_embedding": resume_embedding,
    }

    result = client.table("user_profiles").upsert(row).execute()
    print(f"  [DB] ✓ Upserted profile for {full_name}")
    return result.data[0] if result.data else {}


# ──────────────────────────────────────────
# User Interaction Telemetry (Learning Loop)
# ──────────────────────────────────────────

def log_interaction(
    user_id: str,
    job_id: str,
    interaction_type: str,
    feedback_notes: str = "",
) -> None:
    """
    Log a user interaction for the learning feedback loop.

    interaction_type must be one of: 'viewed', 'saved', 'applied', 'dismissed'

    These logs are used to:
    1. Dynamically adjust the user's resume vector (Rocchio algorithm)
    2. Train a custom reranker model when enough data is collected
    """
    client = get_client()

    client.table("user_job_interactions").insert(
        {
            "user_id": user_id,
            "job_id": job_id,
            "interaction_type": interaction_type,
            "feedback_notes": feedback_notes,
        }
    ).execute()


def get_user_interactions(user_id: str) -> list[dict]:
    """Fetch all interactions for a user (for vector drift calculation)."""
    client = get_client()

    result = (
        client.table("user_job_interactions")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )

    return result.data or []


# ──────────────────────────────────────────
# Stats
# ──────────────────────────────────────────

def get_job_count() -> int:
    """Get total number of jobs in the database."""
    client = get_client()
    result = client.table("jobs").select("id", count="exact").execute()
    return result.count or 0


def get_sources_summary() -> dict[str, int]:
    """Get count of jobs per source."""
    client = get_client()
    result = client.table("jobs").select("source").execute()
    counts: dict[str, int] = {}
    for row in result.data or []:
        source = row.get("source", "unknown")
        counts[source] = counts.get(source, 0) + 1
    return counts

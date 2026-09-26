"""
JOB SeArCh — Main Pipeline Orchestrator
═══════════════════════════════════════════

This is the main entry point that ties everything together:
  1. Scrapes jobs from public ATS APIs (Greenhouse, Lever, RemoteOK)
  2. Generates embeddings for each job using Gemini (free)
  3. Stores jobs + vectors in Supabase pgvector
  4. Matches a resume against stored jobs
  5. Scores the top matches with Gemini Flash (free)

Usage:
  python pipeline.py scrape         — Scrape & store jobs
  python pipeline.py match          — Match a test resume against stored jobs
  python pipeline.py full           — Run the complete pipeline
  python pipeline.py test-scrape    — Test scraper only (no DB/embeddings needed)
  python pipeline.py scheduler      — Run scraper on a recurring schedule
"""

import sys
import time
from config import Config


def run_scrape_pipeline():
    """Step 1-3: Scrape → Embed → Store in Supabase."""
    from scraper import scrape_all_sources
    from embeddings import generate_embeddings_batch, embed_job_description
    from database import upsert_jobs, get_job_count, get_sources_summary

    print("\n" + "=" * 60)
    print("STEP 1: Scraping jobs from public ATS APIs")
    print("=" * 60)

    jobs = scrape_all_sources()

    if not jobs:
        print("\n⚠ No jobs found. Check your GREENHOUSE_BOARDS and LEVER_COMPANIES in .env")
        return

    print(f"\n{'=' * 60}")
    print(f"STEP 2: Generating {len(jobs)} embeddings (Gemini free tier)")
    print("=" * 60)

    # Build description strings for embedding
    texts_to_embed = []
    for job in jobs:
        # Combine title + company + description for richer embeddings
        combined = f"{job.title} at {job.company}. {job.description}"
        texts_to_embed.append(combined)

    embeddings = generate_embeddings_batch(texts_to_embed)

    print(f"\n{'=' * 60}")
    print(f"STEP 3: Storing in Supabase (pgvector)")
    print("=" * 60)

    upserted = upsert_jobs(jobs, embeddings)

    # Summary
    total = get_job_count()
    sources = get_sources_summary()

    print(f"\n{'=' * 60}")
    print(f"✓ PIPELINE COMPLETE")
    print(f"{'=' * 60}")
    print(f"  New jobs upserted this run:  {upserted}")
    print(f"  Total jobs in database:      {total}")
    print(f"  Jobs by source:")
    for source, count in sorted(sources.items()):
        print(f"    {source}: {count}")


def run_match_pipeline(resume_text: str | None = None):
    """Step 4-5: Embed resume → Vector search → LLM score top matches."""
    from embeddings import embed_resume
    from database import match_jobs_for_resume
    from scorer import batch_score_jobs

    if resume_text is None:
        resume_text = (
            "Full-stack software engineer with 4 years building production applications. "
            "Core skills: Flutter, Dart, TypeScript, React, Python, FastAPI, PostgreSQL, "
            "Supabase, pgvector, Docker, REST & GraphQL APIs. "
            "Built real-time collaborative tools, RAG-based semantic search engines, "
            "and cross-platform mobile apps with 50k+ active users. "
            "Looking for: Senior Flutter Engineer, Full-Stack Product Engineer, "
            "or AI/RAG Application Developer roles. Remote preferred. $130k+ salary."
        )

    print(f"\n{'=' * 60}")
    print("STEP 4: Embedding resume & running pgvector search")
    print("=" * 60)

    resume_vec = embed_resume(resume_text)
    print(f"  Resume vector: {len(resume_vec)} dimensions")

    matches = match_jobs_for_resume(
        resume_embedding=resume_vec,
        match_threshold=0.60,
        match_count=15,
        filter_remote=None,
    )

    if not matches:
        print("\n⚠ No matching jobs found. Try lowering the match_threshold or scraping more jobs.")
        return

    print(f"\n{'=' * 60}")
    print(f"STEP 5: LLM scoring top {min(10, len(matches))} matches (Gemini Flash free)")
    print("=" * 60)

    scored = batch_score_jobs(
        resume_text=resume_text,
        jobs=matches,
        max_to_score=10,
    )

    # Sort by match_score descending
    scored.sort(key=lambda j: j.get("match_score", 0), reverse=True)

    print(f"\n{'=' * 60}")
    print("✓ TOP JOB MATCHES")
    print("=" * 60)

    for i, job in enumerate(scored[:10]):
        score = job.get("match_score", 0)
        similarity = job.get("similarity", 0)

        # Color indicator
        if score >= 90:
            indicator = "🟢"
        elif score >= 75:
            indicator = "🟡"
        else:
            indicator = "🔴"

        print(f"\n  {indicator} [{score}%] {job['title']}")
        print(f"     Company:    {job['company']}")
        print(f"     Location:   {job['location']} {'(Remote)' if job.get('is_remote') else ''}")
        print(f"     Cosine Sim: {similarity:.3f}")
        print(f"     Salary:     ${job.get('salary_min', 0):,} - ${job.get('salary_max', 0):,}")

        why = job.get("why_it_fits", [])
        if why:
            print(f"     Why it fits:")
            for reason in why[:2]:
                print(f"       • {reason}")

        gaps = job.get("skill_gaps", [])
        if gaps:
            print(f"     Gaps:")
            for gap in gaps[:1]:
                print(f"       ⚠ {gap}")

        pitch = job.get("tailored_pitch", "")
        if pitch:
            print(f"     Pitch: {pitch[:100]}...")

        print(f"     URL: {job.get('job_url', 'N/A')}")


def run_test_scrape():
    """Test the scraper without needing Supabase or Gemini keys."""
    from scraper import scrape_all_sources

    print(f"\n{'=' * 60}")
    print("TEST MODE: Scraping jobs (no DB or embeddings)")
    print("=" * 60)

    jobs = scrape_all_sources()

    print(f"\n{'─' * 60}")
    print(f"First 10 jobs:")
    print(f"{'─' * 60}")

    for i, job in enumerate(jobs[:10]):
        print(f"\n  [{i+1}] {job.title}")
        print(f"      Company:    {job.company}")
        print(f"      Location:   {job.location} {'🌐 Remote' if job.is_remote else '🏢 On-site'}")
        print(f"      Salary:     ${job.salary_min:,} - ${job.salary_max:,}")
        print(f"      Tags:       {', '.join(job.tags[:4])}")
        print(f"      Source:     {job.source}")
        print(f"      URL:        {job.job_url[:70]}")
        print(f"      Desc (50c): {job.description[:50]}...")


def run_scheduler():
    """Run the scrape pipeline on a recurring schedule."""
    import schedule as sched

    interval = Config.SCRAPE_INTERVAL_HOURS

    print(f"\n{'=' * 60}")
    print(f"SCHEDULER: Running scrape pipeline every {interval} hours")
    print(f"Press Ctrl+C to stop")
    print(f"{'=' * 60}")

    # Run immediately on start
    run_scrape_pipeline()

    # Schedule recurring
    sched.every(interval).hours.do(run_scrape_pipeline)

    while True:
        sched.run_pending()
        time.sleep(60)


# ──────────────────────────────────────────
# CLI Entry Point
# ──────────────────────────────────────────

def main():
    print(r"""
       ╔══════════════════════════════════════════╗
       ║     JOB SeArCh — RAG Pipeline v1.0       ║
       ║  Scrape → Embed → Store → Match → Score  ║
       ╚══════════════════════════════════════════╝
    """)

    # Print config summary
    print("Configuration:")
    print(Config.summary())
    print()

    if len(sys.argv) < 2:
        print("Usage:")
        print("  python pipeline.py test-scrape  — Test scraper (no API keys needed)")
        print("  python pipeline.py scrape       — Scrape & store jobs in Supabase")
        print("  python pipeline.py match        — Match test resume against stored jobs")
        print("  python pipeline.py full         — Run complete pipeline")
        print("  python pipeline.py scheduler    — Run scraper on recurring schedule")
        return

    command = sys.argv[1].lower()

    if command == "test-scrape":
        run_test_scrape()

    elif command == "scrape":
        missing = Config.validate()
        if missing:
            print(f"✗ Missing required config: {', '.join(missing)}")
            print("  Copy .env.example to .env and fill in your keys.")
            return
        run_scrape_pipeline()

    elif command == "match":
        missing = Config.validate()
        if missing:
            print(f"✗ Missing required config: {', '.join(missing)}")
            return
        run_match_pipeline()

    elif command == "full":
        missing = Config.validate()
        if missing:
            print(f"✗ Missing required config: {', '.join(missing)}")
            return
        run_scrape_pipeline()
        print("\n\n" + "━" * 60)
        print("Now matching a test resume against the scraped jobs...")
        print("━" * 60)
        run_match_pipeline()

    elif command == "scheduler":
        missing = Config.validate()
        if missing:
            print(f"✗ Missing required config: {', '.join(missing)}")
            return
        run_scheduler()

    else:
        print(f"Unknown command: {command}")
        print("Valid commands: test-scrape, scrape, match, full, scheduler")


if __name__ == "__main__":
    main()

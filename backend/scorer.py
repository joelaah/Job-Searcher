"""
JOB SeArCh — LLM Match Scorer
Uses Gemini Flash (free tier) to generate human-readable fit analysis,
skill gap identification, and tailored elevator pitches.

Cost: $0 — Gemini Flash free tier allows 15 requests/minute.
"""

import json
from google import genai
from config import Config


_client = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        _client = genai.Client(api_key=Config.GEMINI_API_KEY)
    return _client


def score_job_fit(
    resume_text: str,
    job_title: str,
    job_company: str,
    job_description: str,
    cosine_similarity: float,
) -> dict:
    """
    Use Gemini Flash to generate a detailed fit analysis between
    a candidate's resume and a specific job posting.

    Returns a dict with:
      - match_score: int (0-100)
      - why_it_fits: list[str] (3 bullet points)
      - skill_gaps: list[str] (1-2 gaps)
      - tailored_pitch: str (2-3 sentence elevator pitch)
      - recruiter_message: str (short email template)
    """
    client = _get_client()

    prompt = f"""You are an expert career advisor and job matching AI.

Given a candidate's resume and a job posting, analyze the fit and return a JSON response.

CANDIDATE RESUME:
{resume_text[:3000]}

JOB POSTING:
Title: {job_title}
Company: {job_company}
Description: {job_description[:2000]}

Vector Cosine Similarity Score: {cosine_similarity:.3f}

Return ONLY valid JSON (no markdown, no code fences) with these exact keys:
{{
  "match_score": <integer 0-100, factor in the cosine similarity but also use your judgment>,
  "why_it_fits": ["<reason 1>", "<reason 2>", "<reason 3>"],
  "skill_gaps": ["<gap 1>"],
  "tailored_pitch": "<2-3 sentence elevator pitch the candidate can send to the hiring manager>",
  "recruiter_message": "<short professional email template with Subject line>"
}}"""

    try:
        response = client.models.generate_content(
            model=Config.LLM_MODEL,
            contents=prompt,
        )

        # Parse the JSON response
        text = response.text.strip()
        # Clean potential markdown code fences
        if text.startswith("```"):
            text = text.split("\n", 1)[1] if "\n" in text else text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        result = json.loads(text)

        # Validate and clamp
        result["match_score"] = max(0, min(100, int(result.get("match_score", 50))))
        result["why_it_fits"] = result.get("why_it_fits", [])[:3]
        result["skill_gaps"] = result.get("skill_gaps", [])[:3]
        result["tailored_pitch"] = result.get("tailored_pitch", "")
        result["recruiter_message"] = result.get("recruiter_message", "")

        return result

    except json.JSONDecodeError as e:
        print(f"  [LLM] JSON parse error: {e}")
        return _fallback_score(cosine_similarity)
    except Exception as e:
        print(f"  [LLM] Error scoring job '{job_title}': {e}")
        return _fallback_score(cosine_similarity)


def _fallback_score(cosine_similarity: float) -> dict:
    """Fallback when LLM is unavailable — use raw cosine similarity."""
    score = int(cosine_similarity * 100)
    return {
        "match_score": score,
        "why_it_fits": [f"Vector similarity: {cosine_similarity:.2f}"],
        "skill_gaps": ["Unable to analyze — LLM unavailable"],
        "tailored_pitch": "",
        "recruiter_message": "",
    }


def batch_score_jobs(
    resume_text: str,
    jobs: list[dict],
    max_to_score: int = 10,
) -> list[dict]:
    """
    Score the top N jobs from a vector search result.

    Only the top matches get LLM scoring (to stay within free tier limits).
    Lower-ranked jobs use the raw cosine similarity as their score.

    Args:
        resume_text: The candidate's full resume text.
        jobs: List of job dicts from match_jobs_for_resume().
        max_to_score: Max number of jobs to run through the LLM.

    Returns:
        The same list of jobs, each enriched with scoring fields.
    """
    import time

    scored_jobs = []

    for i, job in enumerate(jobs):
        similarity = job.get("similarity", 0.5)

        if i < max_to_score:
            print(f"  [LLM] Scoring {i+1}/{min(len(jobs), max_to_score)}: {job['title']}")

            analysis = score_job_fit(
                resume_text=resume_text,
                job_title=job["title"],
                job_company=job["company"],
                job_description=job.get("description", ""),
                cosine_similarity=similarity,
            )

            job.update(analysis)

            # Rate limit: 15 req/min on free tier → ~4 sec between calls
            if i < max_to_score - 1:
                time.sleep(4)
        else:
            # Use fallback for remaining jobs
            job.update(_fallback_score(similarity))

        scored_jobs.append(job)

    return scored_jobs


# ──────────────────────────────────────────
# Standalone test
# ──────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("JOB SeArCh — LLM Scorer Test")
    print("=" * 60)

    test_resume = (
        "Full-stack software engineer with 4 years of experience. "
        "Built production Flutter apps, Python FastAPI microservices, "
        "and PostgreSQL databases with pgvector for semantic search. "
        "Experienced with Docker, CI/CD, and real-time web sockets."
    )

    test_job = {
        "title": "Senior Flutter Engineer",
        "company": "Acme Tech",
        "description": (
            "We are looking for a Senior Flutter Engineer to build our "
            "cross-platform mobile and web application. Must have experience "
            "with Dart, Bloc state management, REST APIs, and PostgreSQL."
        ),
        "similarity": 0.87,
    }

    print("\nScoring job fit...")
    result = score_job_fit(
        resume_text=test_resume,
        job_title=test_job["title"],
        job_company=test_job["company"],
        job_description=test_job["description"],
        cosine_similarity=test_job["similarity"],
    )

    print(f"\n  Match Score: {result['match_score']}%")
    print(f"  Why It Fits:")
    for reason in result["why_it_fits"]:
        print(f"    • {reason}")
    print(f"  Skill Gaps:")
    for gap in result["skill_gaps"]:
        print(f"    ⚠ {gap}")
    print(f"  Pitch: {result['tailored_pitch'][:120]}...")

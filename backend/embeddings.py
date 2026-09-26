"""
JOB SeArCh — Embedding Generator
Uses Google Gemini's free-tier text-embedding-004 model to generate
768-dimensional vectors for job descriptions and user resumes.

Cost: $0 — Gemini embedding API is free up to 1,500 requests/minute.
"""

import time
from google import genai
from config import Config


# ──────────────────────────────────────────
# Gemini Client Initialization
# ──────────────────────────────────────────

_client = None


def _get_client() -> genai.Client:
    """Lazy-initialize the Gemini client."""
    global _client
    if _client is None:
        if not Config.GEMINI_API_KEY:
            raise ValueError(
                "GEMINI_API_KEY is not set. Get a free key at https://aistudio.google.com/apikey"
            )
        _client = genai.Client(api_key=Config.GEMINI_API_KEY)
    return _client


# ──────────────────────────────────────────
# Single Text → Vector
# ──────────────────────────────────────────

def generate_embedding(text: str) -> list[float]:
    """
    Generate a 768-dimensional embedding vector for a single text.

    Args:
        text: The input text (job description, resume chunk, etc.)

    Returns:
        A list of 768 floats representing the semantic vector.
    """
    if not text or not text.strip():
        return [0.0] * Config.EMBEDDING_DIMENSIONS

    client = _get_client()

    # Truncate to ~8000 chars (model has token limits, this is safe)
    truncated = text[:8000]

    result = client.models.embed_content(
        model=Config.EMBEDDING_MODEL,
        contents=truncated,
    )

    return result.embeddings[0].values


# ──────────────────────────────────────────
# Batch Text → Vectors (with rate limiting)
# ──────────────────────────────────────────

def generate_embeddings_batch(
    texts: list[str],
    batch_size: int = 20,
    delay_between_batches: float = 1.0,
) -> list[list[float]]:
    """
    Generate embeddings for multiple texts with rate limiting.

    The free tier allows 1,500 req/min, so we batch and add a small delay
    to be safe and avoid hitting limits.

    Args:
        texts: List of text strings to embed.
        batch_size: Number of texts to embed per API call.
        delay_between_batches: Seconds to wait between batches.

    Returns:
        List of embedding vectors (same order as input texts).
    """
    all_embeddings: list[list[float]] = []
    total = len(texts)

    for i in range(0, total, batch_size):
        batch = texts[i : i + batch_size]
        batch_num = (i // batch_size) + 1
        total_batches = (total + batch_size - 1) // batch_size

        print(
            f"  [Embeddings] Batch {batch_num}/{total_batches} "
            f"({len(batch)} texts)..."
        )

        client = _get_client()

        # Process each text in the batch individually
        # (Gemini embed_content supports single content per call)
        for text in batch:
            try:
                truncated = text[:8000] if text else ""
                if not truncated.strip():
                    all_embeddings.append([0.0] * Config.EMBEDDING_DIMENSIONS)
                    continue

                result = client.models.embed_content(
                    model=Config.EMBEDDING_MODEL,
                    contents=truncated,
                )
                all_embeddings.append(result.embeddings[0].values)

            except Exception as e:
                print(f"    [Embeddings] Error embedding text: {e}")
                all_embeddings.append([0.0] * Config.EMBEDDING_DIMENSIONS)

        # Rate limit pause between batches
        if i + batch_size < total:
            time.sleep(delay_between_batches)

    print(f"  [Embeddings] ✓ Generated {len(all_embeddings)} vectors")
    return all_embeddings


# ──────────────────────────────────────────
# Resume-Specific Embedding
# ──────────────────────────────────────────

def embed_resume(resume_text: str) -> list[float]:
    """
    Generate an optimized embedding for a user's resume.
    Prepends a task instruction to improve retrieval quality.
    """
    # Adding a retrieval prefix helps the embedding model understand
    # the intent and improves cosine similarity matching accuracy
    prefixed = (
        "Represent this job candidate's resume for matching against job descriptions: "
        + resume_text
    )
    return generate_embedding(prefixed)


def embed_job_description(description: str) -> list[float]:
    """
    Generate an optimized embedding for a job description.
    """
    prefixed = (
        "Represent this job posting for matching against candidate resumes: "
        + description
    )
    return generate_embedding(prefixed)


# ──────────────────────────────────────────
# Standalone test
# ──────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("JOB SeArCh — Embedding Generator Test")
    print("=" * 60)

    test_resume = (
        "Full-stack software engineer with 4 years of experience in Flutter, "
        "TypeScript, React, Python, PostgreSQL, and Supabase. Built real-time "
        "collaborative apps and RAG-based search engines."
    )

    test_job = (
        "Senior Flutter Engineer wanted to build cross-platform mobile and web "
        "apps. Must have experience with Dart, state management (Bloc/Riverpod), "
        "REST APIs, and PostgreSQL."
    )

    print("\nGenerating resume embedding...")
    resume_vec = embed_resume(test_resume)
    print(f"  Vector dimensions: {len(resume_vec)}")
    print(f"  First 5 values: {resume_vec[:5]}")

    print("\nGenerating job embedding...")
    job_vec = embed_job_description(test_job)
    print(f"  Vector dimensions: {len(job_vec)}")
    print(f"  First 5 values: {job_vec[:5]}")

    # Calculate cosine similarity manually
    import math

    dot = sum(a * b for a, b in zip(resume_vec, job_vec))
    mag_a = math.sqrt(sum(a * a for a in resume_vec))
    mag_b = math.sqrt(sum(b * b for b in job_vec))
    similarity = dot / (mag_a * mag_b) if mag_a and mag_b else 0

    print(f"\n✓ Cosine similarity between resume & job: {similarity:.4f}")
    print(f"  (1.0 = perfect match, 0.0 = no relation)")

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
# Embedding Model Initialization (FastEmbed Local + Gemini Fallback)
# ──────────────────────────────────────────

_fastembed_model = None
_gemini_client = None


def _get_fastembed():
    """Lazy-initialize the local FastEmbed model (768-dimensional BAAI/bge-base-en-v1.5)."""
    global _fastembed_model
    if _fastembed_model is None:
        from fastembed import TextEmbedding
        _fastembed_model = TextEmbedding(model_name="BAAI/bge-base-en-v1.5")
    return _fastembed_model


def _get_gemini_client():
    """Lazy-initialize Gemini client if configured."""
    global _gemini_client
    if _gemini_client is None and Config.GEMINI_API_KEY:
        from google import genai
        _gemini_client = genai.Client(api_key=Config.GEMINI_API_KEY)
    return _gemini_client


# ──────────────────────────────────────────
# Single Text → Vector
# ──────────────────────────────────────────

def generate_embedding(text: str) -> list[float]:
    """
    Generate a 768-dimensional embedding vector for a single text.
    Uses local FastEmbed (BAAI/bge-base-en-v1.5) by default ($0 cost, 0 API keys required).
    """
    if not text or not text.strip():
        return [0.0] * Config.EMBEDDING_DIMENSIONS

    # Try Gemini if API key is present
    gemini = _get_gemini_client()
    if gemini is not None:
        try:
            result = gemini.models.embed_content(
                model="text-embedding-004",
                contents=text[:8000],
            )
            return list(result.embeddings[0].values)
        except Exception as e:
            print(f"[Embeddings] Gemini embedding failed, falling back to local FastEmbed: {e}")

    # Primary: FastEmbed local ONNX model (768 dims)
    model = _get_fastembed()
    embeddings = list(model.embed([text[:4000]]))
    return [float(x) for x in embeddings[0]]


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

    # Use local FastEmbed if Gemini is not configured
    gemini = _get_gemini_client()
    if gemini is None:
        model = _get_fastembed()
        cleaned_texts = [(t[:4000] if t else " ") for t in texts]
        embeddings = list(model.embed(cleaned_texts, batch_size=batch_size))
        all_embeddings = [[float(x) for x in emb] for emb in embeddings]
        print(f"  [Embeddings] ✓ Generated {len(all_embeddings)} vectors via FastEmbed (Local)")
        return all_embeddings

    # Otherwise use Gemini with rate limit pacing
    for i in range(0, total, batch_size):
        batch = texts[i : i + batch_size]
        batch_num = (i // batch_size) + 1
        total_batches = (total + batch_size - 1) // batch_size

        print(
            f"  [Embeddings] Batch {batch_num}/{total_batches} "
            f"({len(batch)} texts)..."
        )

        for text in batch:
            try:
                truncated = text[:8000] if text else ""
                if not truncated.strip():
                    all_embeddings.append([0.0] * Config.EMBEDDING_DIMENSIONS)
                    continue

                result = gemini.models.embed_content(
                    model=Config.EMBEDDING_MODEL,
                    contents=truncated,
                )
                all_embeddings.append(result.embeddings[0].values)

            except Exception as e:
                print(f"    [Embeddings] Error embedding text: {e}")
                all_embeddings.append([0.0] * Config.EMBEDDING_DIMENSIONS)

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

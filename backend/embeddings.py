"""
JOB SeArCh — Embedding Generator
Uses Google Gemini's free-tier text-embedding-004 model to generate
768-dimensional vectors for job descriptions and user resumes.

Cost: $0 — Gemini embedding API is free up to 1,500 requests/minute.
"""

import hashlib
import math
import os
import re
import time
from google import genai
from config import Config


# ──────────────────────────────────────────
# Embedding Model Initialization (FastEmbed Local + Gemini Fallback)
# ──────────────────────────────────────────

_fastembed_model = None
_gemini_client = None


def _is_low_ram_cloud() -> bool:
    """Detect 512MB cloud tiers (e.g., Render free plan) where ONNX FastEmbed can OOM."""
    return (
        os.getenv("RENDER", "").strip().lower() == "true"
        or os.getenv("DISABLE_LOCAL_FASTEMBED", "").strip().lower() in ("1", "true", "yes")
    )


def _compute_lightweight_vector(text: str, dims: int = 768) -> list[float]:
    """Deterministic sub-millisecond 768-dim hashed token+trigram vector (<1 MB RAM)."""
    vec = [0.0] * dims
    if not text or not text.strip():
        return vec
    tokens = re.findall(r"[a-z0-9\+\#\.]{2,}", text.lower())
    features: list[str] = list(tokens)
    for tok in tokens:
        if len(tok) >= 4:
            for i in range(len(tok) - 2):
                features.append(tok[i : i + 3])
    for feat in features:
        digest = hashlib.md5(feat.encode("utf-8")).digest()
        idx = int.from_bytes(digest[:4], "little") % dims
        sign = 1.0 if (digest[4] & 1) == 0 else -1.0
        vec[idx] += sign
    norm = math.sqrt(sum(v * v for v in vec))
    if norm > 0:
        vec = [v / norm for v in vec]
    return vec


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

    # Avoid loading ~400MB ONNX FastEmbed on 512MB cloud free tiers unless explicitly enabled
    if _is_low_ram_cloud():
        return _compute_lightweight_vector(text, Config.EMBEDDING_DIMENSIONS)

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

    # Use lightweight vectors on 512MB cloud tiers or local FastEmbed when Gemini is unset
    gemini = _get_gemini_client()
    if gemini is None:
        if _is_low_ram_cloud():
            all_embeddings = [
                _compute_lightweight_vector(t or "", Config.EMBEDDING_DIMENSIONS)
                for t in texts
            ]
            print(f"  [Embeddings] ✓ Generated {len(all_embeddings)} lightweight vectors (Low-RAM Cloud)")
            return all_embeddings
        model = _get_fastembed()
        cleaned_texts = [(t[:4000] if t else " ") for t in texts]
        embeddings = list(model.embed(cleaned_texts, batch_size=batch_size))
        all_embeddings = [[float(x) for x in emb] for emb in embeddings]
        print(f"  [Embeddings] ✓ Generated {len(all_embeddings)} vectors via FastEmbed (Local)")
        return all_embeddings

    # Otherwise use Gemini with rate limit pacing, falling back to FastEmbed on failure
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
                    model="text-embedding-004",
                    contents=truncated,
                )
                all_embeddings.append(list(result.embeddings[0].values))

            except Exception as e:
                if _is_low_ram_cloud():
                    print(
                        f"    [Embeddings] Gemini batch embedding failed ({e}), "
                        "falling back to lightweight vectors (Low-RAM Cloud)..."
                    )
                    return [
                        _compute_lightweight_vector(t or "", Config.EMBEDDING_DIMENSIONS)
                        for t in texts
                    ]
                print(
                    f"    [Embeddings] Gemini batch embedding failed ({e}), "
                    "falling back to local FastEmbed for batch..."
                )
                model = _get_fastembed()
                cleaned_texts = [(t[:4000] if t else " ") for t in texts]
                embeddings = list(model.embed(cleaned_texts, batch_size=batch_size))
                return [[float(x) for x in emb] for emb in embeddings]

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

# ADR 0003: Client-Side Heuristic Re-ranking vs. Backend Dense Vector Pipeline

## Status
Accepted

## Context
Initial conceptual drafts referred to client-side real-time 768-dimensional vector steering in Supabase pgvector directly from UI sliders. However, running dense vector embedding generation and HNSW similarity searches on every user slider tick directly over remote HTTP roundtrips introduces unacceptable latency, rate limits, and network fragility.

## Decision
Decouple client-side interactive exploration from the backend vector retrieval pipeline:
1. **Client-Side (Flutter BLoC)**:
   - Evaluates dynamic heuristic re-ranking and semantic affinity calculations locally in real-time (instant 60 FPS slider responsiveness).
   - Renders the 2D Latent Space Constellation to visualize spatial affinity clusters without requiring live remote vector calls on every frame.
2. **Backend (Python FastAPI + Supabase)**:
   - Houses the dense 768-dimensional embedding model (FastEmbed `BAAI/bge-base-en-v1.5`) and Supabase PostgreSQL `pgvector` HNSW index.
   - Executes dense vector matching RPC (`match_jobs`) during heavy scrape/ingestion batch jobs or dedicated synchronization tasks.

## Consequences
- **Positive**: Sub-16ms instantaneous UI responsiveness on all platforms; zero API thrashing or unnecessary LLM/embedding inference costs.
- **Negative**: Client state and backend vector representations are synchronized asynchronously rather than synchronously in-memory.

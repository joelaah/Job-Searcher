-- ══════════════════════════════════════════════════════════════
-- JOB SeArCh — Supabase Database Migration
-- ══════════════════════════════════════════════════════════════
-- Run this SQL in your Supabase Dashboard → SQL Editor → New Query
-- This sets up pgvector, all tables, indexes, and the match function.
-- Cost: $0 (included in Supabase free tier)
-- ══════════════════════════════════════════════════════════════

-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Jobs table (stores scraped listings + their embeddings)
CREATE TABLE IF NOT EXISTS jobs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    company     TEXT NOT NULL,
    location    TEXT DEFAULT 'Unknown',
    is_remote   BOOLEAN DEFAULT false,
    salary_min  INT DEFAULT 0,
    salary_max  INT DEFAULT 0,
    description TEXT NOT NULL,
    job_url     TEXT NOT NULL UNIQUE,  -- deduplicate by URL
    source      TEXT DEFAULT 'manual', -- greenhouse, lever, remoteok, manual
    tags        TEXT[] DEFAULT '{}',
    posted_at   TEXT,
    job_embedding VECTOR(768),        -- Gemini text-embedding-004 output
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Fast vector similarity index (HNSW = best for real-time queries)
CREATE INDEX IF NOT EXISTS jobs_embedding_hnsw_idx
    ON jobs USING hnsw (job_embedding vector_cosine_ops);

-- 4. Text search indexes for hybrid search
CREATE INDEX IF NOT EXISTS jobs_title_idx ON jobs USING gin (to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS jobs_company_idx ON jobs (company);
CREATE INDEX IF NOT EXISTS jobs_source_idx ON jobs (source);

-- 5. User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id                  UUID PRIMARY KEY,
    full_name           TEXT,
    target_roles        TEXT[] DEFAULT '{}',
    preferred_location  TEXT DEFAULT 'Remote',
    min_salary          INT DEFAULT 0,
    resume_url          TEXT,
    parsed_resume_json  JSONB,
    resume_embedding    VECTOR(768),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 6. User interaction telemetry (the learning/training data)
CREATE TABLE IF NOT EXISTS user_job_interactions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    job_id           UUID REFERENCES jobs(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (
        interaction_type IN ('viewed', 'saved', 'applied', 'dismissed')
    ),
    feedback_notes   TEXT DEFAULT '',
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS interactions_user_idx
    ON user_job_interactions (user_id, created_at DESC);

-- 7. pgvector similarity search function
--    Called from Python: supabase.rpc("match_jobs_for_user", {...})
CREATE OR REPLACE FUNCTION match_jobs_for_user(
    query_embedding  VECTOR(768),
    match_threshold  FLOAT DEFAULT 0.65,
    match_count      INT DEFAULT 20,
    filter_remote    BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id         UUID,
    title      TEXT,
    company    TEXT,
    location   TEXT,
    is_remote  BOOLEAN,
    salary_min INT,
    salary_max INT,
    description TEXT,
    job_url    TEXT,
    source     TEXT,
    tags       TEXT[],
    posted_at  TEXT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        j.id,
        j.title,
        j.company,
        j.location,
        j.is_remote,
        j.salary_min,
        j.salary_max,
        j.description,
        j.job_url,
        j.source,
        j.tags,
        j.posted_at,
        (1 - (j.job_embedding <=> query_embedding))::FLOAT AS similarity
    FROM jobs j
    WHERE
        j.job_embedding IS NOT NULL
        AND (filter_remote IS NULL OR j.is_remote = filter_remote)
        AND (1 - (j.job_embedding <=> query_embedding)) > match_threshold
    ORDER BY j.job_embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- 8. Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE OR REPLACE TRIGGER profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- ══════════════════════════════════════════════════════════════
-- Done! Your database is ready for JOB SeArCh.
-- ══════════════════════════════════════════════════════════════

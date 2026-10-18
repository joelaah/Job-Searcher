-- ══════════════════════════════════════════════════════════════
-- PERMANENT SUPABASE KEEP-ALIVE HEARTBEAT MIGRATION
-- ══════════════════════════════════════════════════════════════
-- Run this in Supabase Dashboard → SQL Editor → New Query:
-- https://supabase.com/dashboard/project/apezpfkigivawkufnurw/sql/new
--
-- Why this prevents pausing permanently:
-- Supabase checks for real PostgreSQL write transactions / WAL activity.
-- A read query on an empty table produces 0 WAL activity, which can lead
-- to inactivity false-positives.
-- This creates a dedicated heartbeat table and RPC that executes an actual
-- INSERT ... ON CONFLICT DO UPDATE transaction every time the cron runs.
-- ══════════════════════════════════════════════════════════════

-- 1. Heartbeat tracking table
CREATE TABLE IF NOT EXISTS public._keep_alive (
    service_name TEXT PRIMARY KEY,
    last_ping    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ping_count   BIGINT NOT NULL DEFAULT 1,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Enable Row-Level Security
ALTER TABLE public._keep_alive ENABLE ROW LEVEL SECURITY;

-- 3. Policies for keep-alive access
DROP POLICY IF EXISTS "Allow heartbeat select for everyone" ON public._keep_alive;
CREATE POLICY "Allow heartbeat select for everyone"
    ON public._keep_alive
    FOR SELECT
    TO anon, authenticated, service_role
    USING (true);

DROP POLICY IF EXISTS "Allow heartbeat upsert for everyone" ON public._keep_alive;
CREATE POLICY "Allow heartbeat upsert for everyone"
    ON public._keep_alive
    FOR ALL
    TO anon, authenticated, service_role
    USING (true)
    WITH CHECK (true);

-- 4. RPC function to record a guaranteed PostgreSQL write transaction
CREATE OR REPLACE FUNCTION public.ping_keep_alive(caller_name TEXT DEFAULT 'github_actions')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result_record RECORD;
BEGIN
    INSERT INTO public._keep_alive (service_name, last_ping, ping_count)
    VALUES (caller_name, NOW(), 1)
    ON CONFLICT (service_name)
    DO UPDATE SET
        last_ping = NOW(),
        ping_count = public._keep_alive.ping_count + 1
    RETURNING * INTO result_record;

    RETURN json_build_object(
        'status', 'ok',
        'service', result_record.service_name,
        'last_ping', result_record.last_ping,
        'ping_count', result_record.ping_count
    );
END;
$$;

-- 5. Grant execute permission on the RPC function to all roles
GRANT EXECUTE ON FUNCTION public.ping_keep_alive(TEXT) TO anon, authenticated, service_role;

-- 6. Initial test execution to seed the record and immediately register activity
SELECT public.ping_keep_alive('setup_initial_ping');

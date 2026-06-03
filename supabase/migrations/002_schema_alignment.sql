-- FlowOS Supabase Migration v2 — Schema Alignment
-- Aligns cloud schema with Drift local schema.
-- Adds missing columns to focus_sessions, xp_ledger, and browsing_sessions.

-- ═══════════════════════════════════════════════════════════════════
-- FOCUS SESSIONS — Add 5 missing columns from Drift schema
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS pause_count INT DEFAULT 0;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS app_background_count INT DEFAULT 0;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS ambient_sound TEXT;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS energy_before INT CHECK (energy_before BETWEEN 1 AND 5);
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS energy_after INT CHECK (energy_after BETWEEN 1 AND 5);


-- ═══════════════════════════════════════════════════════════════════
-- XP LEDGER — Add missing is_reversible column
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.xp_ledger ADD COLUMN IF NOT EXISTS is_reversible BOOLEAN DEFAULT FALSE;


-- ═══════════════════════════════════════════════════════════════════
-- BROWSING SESSIONS — Add title column for extension payload
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.browsing_sessions ADD COLUMN IF NOT EXISTS title TEXT;


-- ═══════════════════════════════════════════════════════════════════
-- SCROLL LOGS — Add daily_score_impact column from Drift
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE public.scroll_logs ADD COLUMN IF NOT EXISTS daily_score_impact INT DEFAULT 0;

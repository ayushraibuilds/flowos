-- Migration 003: Add daily_scores table for v2 daily scoring synchronization

CREATE TABLE IF NOT EXISTS public.daily_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    composite_score INT NOT NULL DEFAULT 0,
    grade VARCHAR(5) NOT NULL DEFAULT 'F',
    focus_points DOUBLE PRECISION NOT NULL DEFAULT 0,
    intent_points DOUBLE PRECISION NOT NULL DEFAULT 0,
    attention_points DOUBLE PRECISION NOT NULL DEFAULT 0,
    care_points DOUBLE PRECISION NOT NULL DEFAULT 0,
    coverage_state VARCHAR(20) NOT NULL DEFAULT 'partial',
    scoring_version INT NOT NULL DEFAULT 2,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    device_id TEXT,
    CONSTRAINT unique_user_daily_score_day UNIQUE (user_id, day)
);

-- Enable RLS
ALTER TABLE public.daily_scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own daily_scores"
    ON public.daily_scores FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_daily_scores_user_day ON public.daily_scores (user_id, day DESC);
CREATE INDEX IF NOT EXISTS idx_daily_scores_user_updated ON public.daily_scores (user_id, updated_at DESC);

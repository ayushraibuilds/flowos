-- FlowOS Supabase Migration v3 — Unlock Attempts
-- Logs bypass attempts for protected apps/sites.

CREATE TABLE IF NOT EXISTS public.unlock_attempts (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  platform TEXT NOT NULL,
  target TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('reflect', 'guard', 'deep')),
  requested_break_minutes INT NOT NULL,
  intention TEXT,
  wait_outcome TEXT NOT NULL,
  session_id UUID, -- Optional focus session UUID context
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.unlock_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "unlock_attempts_select_own" ON public.unlock_attempts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "unlock_attempts_insert_own" ON public.unlock_attempts FOR INSERT WITH CHECK (auth.uid() = user_id);

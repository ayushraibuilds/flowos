-- FlowOS Supabase Migration v1
-- Creates all core tables with RLS policies.
-- XP ledger is append-only (INSERT + SELECT only, no UPDATE/DELETE).

-- ═══════════════════════════════════════════════════════════════════
-- TASKS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  title TEXT NOT NULL,
  energy_level TEXT NOT NULL CHECK (energy_level IN ('deep', 'medium', 'light')),
  estimated_minutes INT,
  due_date DATE,
  category TEXT,
  is_mit BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  sort_order INT DEFAULT 0,
  recurrence_rule TEXT,
  parent_task_id UUID REFERENCES public.tasks(id),
  friction_score FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tasks_select_own" ON public.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tasks_insert_own" ON public.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_update_own" ON public.tasks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "tasks_delete_own" ON public.tasks FOR DELETE USING (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- FOCUS SESSIONS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.focus_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  task_id UUID REFERENCES public.tasks(id),
  session_type TEXT NOT NULL CHECK (session_type IN ('pomodoro', 'deepWork', 'custom')),
  duration_minutes INT NOT NULL,
  actual_minutes INT,
  quality_score TEXT,
  xp_earned INT DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  device_id TEXT
);

ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sessions_select_own" ON public.focus_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "sessions_insert_own" ON public.focus_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sessions_update_own" ON public.focus_sessions FOR UPDATE USING (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- XP LEDGER — APPEND-ONLY (no UPDATE, no DELETE)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.xp_ledger (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  action_type TEXT NOT NULL,
  points_delta INT NOT NULL,
  source_entity_id UUID,
  explanation TEXT,
  prompt_version INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
  -- NO updated_at. NO deleted_at. Append-only by design.
);

ALTER TABLE public.xp_ledger ENABLE ROW LEVEL SECURITY;
CREATE POLICY "xp_select_own" ON public.xp_ledger FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "xp_insert_own" ON public.xp_ledger FOR INSERT WITH CHECK (auth.uid() = user_id);
-- ⛔ No UPDATE or DELETE policies. XP is immutable.


-- ═══════════════════════════════════════════════════════════════════
-- SCROLL LOGS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.scroll_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  app_name TEXT NOT NULL,
  duration_minutes INT NOT NULL,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  recovery_action_taken BOOLEAN DEFAULT FALSE,
  recovery_action_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  device_id TEXT
);

ALTER TABLE public.scroll_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "scroll_select_own" ON public.scroll_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "scroll_insert_own" ON public.scroll_logs FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- ENERGY CHECK-INS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.energy_checkins (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  energy_level INT NOT NULL CHECK (energy_level BETWEEN 1 AND 5),
  time_of_day TEXT NOT NULL,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  device_id TEXT
);

ALTER TABLE public.energy_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "energy_select_own" ON public.energy_checkins FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "energy_insert_own" ON public.energy_checkins FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- DAILY PLANS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.daily_plans (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  plan_date DATE NOT NULL,
  mit_1_id UUID REFERENCES public.tasks(id),
  mit_2_id UUID REFERENCES public.tasks(id),
  mit_3_id UUID REFERENCES public.tasks(id),
  morning_energy INT CHECK (morning_energy BETWEEN 1 AND 5),
  scroll_budget_minutes INT DEFAULT 30,
  intention_completed BOOLEAN DEFAULT FALSE,
  shutdown_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  device_id TEXT,
  UNIQUE(user_id, plan_date)
);

ALTER TABLE public.daily_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "plans_select_own" ON public.daily_plans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "plans_insert_own" ON public.daily_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "plans_update_own" ON public.daily_plans FOR UPDATE USING (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- DAILY REPORTS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.daily_reports (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  report_date DATE NOT NULL,
  report_json JSONB NOT NULL,
  daily_score INT CHECK (daily_score BETWEEN 0 AND 100),
  xp_earned_today INT DEFAULT 0,
  attention_cost_today INT DEFAULT 0,
  prompt_version INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, report_date)
);

ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reports_select_own" ON public.daily_reports FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "reports_insert_own" ON public.daily_reports FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  achievement_key TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_key)
);

ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "achievements_select_own" ON public.achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "achievements_insert_own" ON public.achievements FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- BROWSING SESSIONS (Chrome Extension — Phase 7)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.browsing_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  url TEXT NOT NULL,
  domain TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('productive', 'neutral', 'distracting')),
  duration_seconds INT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  device_id TEXT DEFAULT 'chrome-extension',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.browsing_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "browsing_select_own" ON public.browsing_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "browsing_insert_own" ON public.browsing_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════
-- INDEXES for performance
-- ═══════════════════════════════════════════════════════════════════

CREATE INDEX idx_tasks_user_active ON public.tasks(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_due ON public.tasks(user_id, due_date) WHERE deleted_at IS NULL AND is_completed = FALSE;
CREATE INDEX idx_sessions_user_date ON public.focus_sessions(user_id, started_at DESC);
CREATE INDEX idx_xp_user_date ON public.xp_ledger(user_id, created_at DESC);
CREATE INDEX idx_scroll_user_date ON public.scroll_logs(user_id, logged_at DESC);
CREATE INDEX idx_plans_user_date ON public.daily_plans(user_id, plan_date DESC);
CREATE INDEX idx_browsing_user_date ON public.browsing_sessions(user_id, started_at DESC);


-- ═══════════════════════════════════════════════════════════════════
-- auto-update updated_at trigger
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tasks_updated_at BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sessions_updated_at BEFORE UPDATE ON public.focus_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER plans_updated_at BEFORE UPDATE ON public.daily_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

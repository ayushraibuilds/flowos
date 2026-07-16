-- FlowOS Supabase Migration v4 — Sync Protocol Rebuild
-- Adds updated_at, deleted_at, intention_note, and garden seed fields.
-- Sets up RLS update/delete policies for mutable synced tables.

-- 1. Align public.daily_reports with Drift schema
ALTER TABLE public.daily_reports RENAME COLUMN report_date TO date;
ALTER TABLE public.daily_reports RENAME COLUMN created_at TO generated_at;
ALTER TABLE public.daily_reports ADD COLUMN IF NOT EXISTS coverage_state TEXT;
ALTER TABLE public.daily_reports ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.daily_reports ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 2. Update public.daily_plans schema
ALTER TABLE public.daily_plans ADD COLUMN IF NOT EXISTS intention_note TEXT;
ALTER TABLE public.daily_plans ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 3. Update public.focus_sessions schema
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS garden_seed_kind TEXT;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS garden_variant INT;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS garden_seed_emoji TEXT;

-- 4. Update public.scroll_logs schema
ALTER TABLE public.scroll_logs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.scroll_logs ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 5. Update public.energy_checkins schema
ALTER TABLE public.energy_checkins ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.energy_checkins ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 6. Update public.achievements schema
ALTER TABLE public.achievements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.achievements ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 7. Add auto-update updated_at triggers for daily_reports, scroll_logs, energy_checkins, and achievements
CREATE TRIGGER reports_updated_at BEFORE UPDATE ON public.daily_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER scroll_updated_at BEFORE UPDATE ON public.scroll_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER energy_updated_at BEFORE UPDATE ON public.energy_checkins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER achievements_updated_at BEFORE UPDATE ON public.achievements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 8. Enable ROW LEVEL SECURITY policies for UPDATE/DELETE on mutable tables
CREATE POLICY "reports_update_own" ON public.daily_reports FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "reports_delete_own" ON public.daily_reports FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "plans_delete_own" ON public.daily_plans FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "scroll_update_own" ON public.scroll_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "scroll_delete_own" ON public.scroll_logs FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "energy_update_own" ON public.energy_checkins FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "energy_delete_own" ON public.energy_checkins FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "achievements_update_own" ON public.achievements FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "achievements_delete_own" ON public.achievements FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "sessions_delete_own" ON public.focus_sessions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "unlock_attempts_update_own" ON public.unlock_attempts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "unlock_attempts_delete_own" ON public.unlock_attempts FOR DELETE USING (auth.uid() = user_id);

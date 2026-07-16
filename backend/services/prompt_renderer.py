"""Prompt Renderer Service — formats and renders versioned prompt templates."""

from ..prompts.v1 import (
    DAILY_REPORT_PROMPT, BREAK_SUGGESTION_PROMPT,
    BRAIN_DUMP_PROMPT, WEEKLY_REVIEW_PROMPT
)

class PromptRenderer:
    @staticmethod
    def render_daily_report(
        daily_score: int,
        grade: str,
        xp_earned_today: int,
        level: int,
        streak_days: int,
        total_focus_minutes: int,
        session_count: int,
        tasks_completed: int,
        tasks_total: int,
        mits_completed: int,
        scroll_minutes: int,
        scroll_budget: int,
        recovery_actions_taken: int,
        energy_readings: str,
        intention_completed: bool,
        shutdown_completed: bool,
        task_details: str,
    ) -> str:
        """Render the daily report prompt template with dynamic parameters."""
        intention_status = "✅" if intention_completed else "❌"
        shutdown_status = "✅" if shutdown_completed else "❌"
        
        return DAILY_REPORT_PROMPT.format(
            daily_score=daily_score,
            grade=grade,
            xp_earned_today=xp_earned_today,
            level=level,
            streak_days=streak_days,
            total_focus_minutes=total_focus_minutes,
            session_count=session_count,
            tasks_completed=tasks_completed,
            tasks_total=tasks_total,
            mits_completed=mits_completed,
            scroll_minutes=scroll_minutes,
            scroll_budget=scroll_budget,
            recovery_actions_taken=recovery_actions_taken,
            energy_readings=energy_readings,
            intention_status=intention_status,
            shutdown_status=shutdown_status,
            task_details=task_details,
        )

    @staticmethod
    def render_break_suggestion(
        session_type: str,
        focus_minutes: int,
        quality_grade: str,
        xp_earned: int,
        energy_level: str,
        preferred_type: str,
        content_type: str,
    ) -> str:
        """Render the break content suggestion prompt template."""
        return BREAK_SUGGESTION_PROMPT.format(
            session_type=session_type,
            focus_minutes=focus_minutes,
            quality_grade=quality_grade,
            xp_earned=xp_earned,
            energy_level=energy_level,
            preferred_type=preferred_type,
            content_type=content_type,
        )

    @staticmethod
    def render_brain_dump(raw_text: str, current_energy: str) -> str:
        """Render the brain dump parsing prompt template."""
        return BRAIN_DUMP_PROMPT.format(
            raw_text=raw_text,
            current_energy=current_energy,
        )

    @staticmethod
    def render_weekly_review(
        week_start: str,
        week_end: str,
        daily_scores: list[int],
        avg_score: float,
        total_focus_hours: float,
        total_tasks_completed: int,
        total_xp: int,
        scroll_total_minutes: int,
        recovery_actions: int,
        streak_days: int,
        best_day_score: int,
        worst_day_score: int,
        mits_completed: int,
        mits_total: int,
    ) -> str:
        """Render the weekly review analysis prompt template."""
        return WEEKLY_REVIEW_PROMPT.format(
            week_start=week_start,
            week_end=week_end,
            daily_scores=daily_scores,
            avg_score=avg_score,
            total_focus_hours=total_focus_hours,
            total_tasks_completed=total_tasks_completed,
            total_xp=total_xp,
            scroll_total_minutes=scroll_total_minutes,
            recovery_actions=recovery_actions,
            streak_days=streak_days,
            best_day_score=best_day_score,
            worst_day_score=worst_day_score,
            mits_completed=mits_completed,
            mits_total=mits_total,
        )

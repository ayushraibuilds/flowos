"""FlowOS AI Router — all AI-powered endpoints.

POST /ai/daily-report    → daily data → structured insight
POST /ai/break-suggestion → session context → break content
POST /ai/brain-dump      → raw text → sorted tasks
POST /ai/weekly-review   → weekly data → insights + questions
"""

import os
import random
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Request
from ..services.auth_service import get_current_user_id
from ..services.limiter import limiter

RATE_LIMIT_DAILY_REPORT = os.getenv("RATE_LIMIT_DAILY_REPORT", "5/minute")
RATE_LIMIT_BREAK_SUGGESTION = os.getenv("RATE_LIMIT_BREAK_SUGGESTION", "10/minute")
RATE_LIMIT_BRAIN_DUMP = os.getenv("RATE_LIMIT_BRAIN_DUMP", "10/minute")
RATE_LIMIT_WEEKLY_REVIEW = os.getenv("RATE_LIMIT_WEEKLY_REVIEW", "5/minute")


def _escape_prompt_text(text: str) -> str:
    """Escape prompt template formatting characters and block delimiters to mitigate prompt injection."""
    if not text:
        return ""
    escaped = text.replace("{", "(").replace("}", ")")
    escaped = escaped.replace("---", "- - -")
    return escaped


from ..models.schemas import (
    DailyReportRequest, DailyReportResponse, DailyReportInsight,
    BreakSuggestionRequest, BreakSuggestionResponse,
    BrainDumpRequest, BrainDumpResponse, SortedTask,
    WeeklyReviewRequest, WeeklyReviewResponse,
    BreakContentType,
)
from ..services.gemini_service import (
    generate_json,
    FALLBACK_REPORT, FALLBACK_BREAK_SUGGESTIONS, FALLBACK_WEEKLY,
)
from ..services.prompt_renderer import PromptRenderer
from ..prompts.v1 import VERSION as PROMPT_VERSION

logger = logging.getLogger("flowos.ai")
router = APIRouter(prefix="/ai", tags=["AI"])


# ─── Daily Report ────────────────────────────────────────────────

@router.post("/daily-report", response_model=DailyReportResponse)
@limiter.limit(RATE_LIMIT_DAILY_REPORT)
async def generate_daily_report(req: DailyReportRequest, request: Request, user_id: str = Depends(get_current_user_id)):
    """Generate AI-powered daily report from productivity data."""

    # Build task details (respecting private mode)
    task_details = ""
    if not req.private_mode and req.task_summaries:
        task_lines = []
        for t in req.task_summaries:
            status = "✅" if t.completed else "❌"
            mit = " (MIT)" if t.is_mit else ""
            clean_title = _escape_prompt_text(t.title)
            task_lines.append(f"  {status} {clean_title}{mit} [{t.energy_level.value}]")
        task_details = "\nTasks:\n" + "\n".join(task_lines)

    # Calculate grade
    grade = _score_to_grade(req.daily_score)

    prompt = PromptRenderer.render_daily_report(
        daily_score=req.daily_score,
        grade=grade,
        xp_earned_today=req.xp_earned_today,
        level=req.level,
        streak_days=req.streak_days,
        total_focus_minutes=req.total_focus_minutes,
        session_count=len(req.sessions),
        tasks_completed=req.tasks_completed,
        tasks_total=req.tasks_total,
        mits_completed=req.mits_completed,
        scroll_minutes=req.scroll_minutes,
        scroll_budget=req.scroll_budget,
        recovery_actions_taken=req.recovery_actions_taken,
        energy_readings=str(req.energy_readings) if req.energy_readings else "Not recorded",
        intention_completed=req.intention_completed,
        shutdown_completed=req.shutdown_completed,
        task_details=task_details,
    )

    result = await generate_json(prompt)

    if not result:
        logger.warning("AI failed for daily report, using fallback")
        return DailyReportResponse(
            insight=DailyReportInsight(**FALLBACK_REPORT),
            prompt_version=PROMPT_VERSION,
        )

    try:
        insight = DailyReportInsight(**result)
        return DailyReportResponse(
            insight=insight,
            prompt_version=PROMPT_VERSION,
        )
    except Exception as e:
        logger.error(f"Failed to parse report response: {e}")
        return DailyReportResponse(
            insight=DailyReportInsight(**FALLBACK_REPORT),
            prompt_version=PROMPT_VERSION,
        )


# ─── Break Suggestion ────────────────────────────────────────────

@router.post("/break-suggestion", response_model=BreakSuggestionResponse)
@limiter.limit(RATE_LIMIT_BREAK_SUGGESTION)
async def generate_break_suggestion(req: BreakSuggestionRequest, request: Request, user_id: str = Depends(get_current_user_id)):
    """Generate a break content suggestion after a focus session."""

    # Determine content type
    content_type = req.preferred_type or random.choice(list(BreakContentType))

    prompt = PromptRenderer.render_break_suggestion(
        session_type=req.session_type.value,
        focus_minutes=req.focus_minutes,
        quality_grade=req.quality_grade,
        xp_earned=req.xp_earned,
        energy_level=str(req.energy_level) if req.energy_level else "unknown",
        preferred_type=content_type.value,
        content_type=content_type.value,
    )

    result = await generate_json(prompt, temperature=0.9)

    if not result:
        # Use fallback — pick one matching the content type or random
        matching = [f for f in FALLBACK_BREAK_SUGGESTIONS
                    if f["content_type"] == content_type.value]
        fallback = random.choice(matching) if matching else random.choice(FALLBACK_BREAK_SUGGESTIONS)
        return BreakSuggestionResponse(
            **fallback,
            prompt_version=PROMPT_VERSION,
        )

    try:
        return BreakSuggestionResponse(
            content_type=BreakContentType(result.get("content_type", content_type.value)),
            content=result["content"],
            answer=result.get("answer"),
            source=result.get("source"),
            prompt_version=PROMPT_VERSION,
        )
    except Exception as e:
        logger.error(f"Failed to parse break suggestion: {e}")
        fallback = random.choice(FALLBACK_BREAK_SUGGESTIONS)
        return BreakSuggestionResponse(**fallback, prompt_version=PROMPT_VERSION)


# ─── Brain Dump ───────────────────────────────────────────────────

@router.post("/brain-dump", response_model=BrainDumpResponse)
@limiter.limit(RATE_LIMIT_BRAIN_DUMP)
async def process_brain_dump(req: BrainDumpRequest, request: Request, user_id: str = Depends(get_current_user_id)):
    """Process raw brain dump text into sorted, actionable tasks."""

    clean_raw_text = _escape_prompt_text(req.raw_text)

    prompt = PromptRenderer.render_brain_dump(
        raw_text=clean_raw_text,
        current_energy=str(req.current_energy) if req.current_energy else "unknown",
    )

    result = await generate_json(prompt, temperature=0.4, max_tokens=2048)

    if not result or "tasks" not in result:
        raise HTTPException(
            status_code=503,
            detail="AI service unavailable. Try again or add tasks manually."
        )

    try:
        tasks = [SortedTask(**t) for t in result["tasks"]]
        return BrainDumpResponse(
            tasks=tasks,
            prompt_version=PROMPT_VERSION,
        )
    except Exception as e:
        logger.error(f"Failed to parse brain dump: {e}")
        raise HTTPException(
            status_code=503,
            detail="AI returned unexpected format. Try again."
        )


# ─── Weekly Review ────────────────────────────────────────────────

@router.post("/weekly-review", response_model=WeeklyReviewResponse)
@limiter.limit(RATE_LIMIT_WEEKLY_REVIEW)
async def generate_weekly_review(req: WeeklyReviewRequest, request: Request, user_id: str = Depends(get_current_user_id)):
    """Generate AI-powered weekly review with insights and reflection questions."""

    avg_score = (sum(req.daily_scores) / len(req.daily_scores)
                 if req.daily_scores else 0)

    prompt = PromptRenderer.render_weekly_review(
        week_start=req.week_start,
        week_end=req.week_end,
        daily_scores=req.daily_scores,
        avg_score=round(avg_score, 1),
        total_focus_hours=req.total_focus_hours,
        total_tasks_completed=req.total_tasks_completed,
        total_xp=req.total_xp,
        scroll_total_minutes=req.scroll_total_minutes,
        recovery_actions=req.recovery_actions,
        streak_days=req.streak_days,
        best_day_score=req.best_day_score,
        worst_day_score=req.worst_day_score,
        mits_completed=req.mits_completed,
        mits_total=req.mits_total,
    )

    result = await generate_json(prompt)

    if not result:
        return WeeklyReviewResponse(**FALLBACK_WEEKLY, prompt_version=PROMPT_VERSION)

    try:
        return WeeklyReviewResponse(
            summary=result.get("summary", FALLBACK_WEEKLY["summary"]),
            wins=result.get("wins", FALLBACK_WEEKLY["wins"]),
            growth_areas=result.get("growth_areas", FALLBACK_WEEKLY["growth_areas"]),
            reflection_questions=result.get("reflection_questions", FALLBACK_WEEKLY["reflection_questions"]),
            next_week_focus=result.get("next_week_focus", FALLBACK_WEEKLY["next_week_focus"]),
            prompt_version=PROMPT_VERSION,
        )
    except Exception as e:
        logger.error(f"Failed to parse weekly review: {e}")
        return WeeklyReviewResponse(**FALLBACK_WEEKLY, prompt_version=PROMPT_VERSION)


# ─── Helpers ──────────────────────────────────────────────────────

def _score_to_grade(score: int) -> str:
    if score >= 90: return "A+"
    if score >= 80: return "A"
    if score >= 70: return "B"
    if score >= 55: return "C"
    if score >= 40: return "D"
    return "F"

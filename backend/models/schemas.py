"""Pydantic models for FlowOS AI API requests and responses."""

from __future__ import annotations
from pydantic import BaseModel, Field
from enum import Enum
from typing import Optional


# ─── Enums ────────────────────────────────────────────────────────

class EnergyLevel(str, Enum):
    deep = "deep"
    medium = "medium"
    light = "light"


class SessionType(str, Enum):
    pomodoro = "pomodoro"
    deep_work = "deepWork"
    custom = "custom"


class BreakContentType(str, Enum):
    riddle = "riddle"
    fact = "fact"
    breathing = "breathing"
    book = "book"
    quote = "quote"


# ─── Daily Report ─────────────────────────────────────────────────

class SessionSummary(BaseModel):
    session_type: SessionType
    duration_minutes: int = Field(ge=0, le=1440)
    quality_grade: str = Field(max_length=5)
    task_title: Optional[str] = Field(None, max_length=200)


class TaskSummary(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    energy_level: EnergyLevel
    completed: bool
    is_mit: bool
    xp_earned: int = Field(default=0, ge=0, le=10000)


class DailyReportRequest(BaseModel):
    """Daily data sent to the AI for report generation."""
    date: str = Field(min_length=10, max_length=10)
    daily_score: int = Field(ge=0, le=100)
    xp_earned_today: int = Field(ge=0, le=50000)
    lifetime_xp: int = Field(ge=0)
    level: int = Field(ge=0, le=200)
    streak_days: int = Field(ge=0, le=10000)

    # Focus
    total_focus_minutes: int = Field(ge=0, le=1440)
    sessions: list[SessionSummary] = Field(default_factory=list, max_length=50)

    # Tasks
    tasks_completed: int = Field(ge=0, le=1000)
    tasks_total: int = Field(ge=0, le=1000)
    mits_completed: int = Field(ge=0, le=3)
    task_summaries: list[TaskSummary] = Field(default_factory=list, max_length=100)

    # Attention
    scroll_minutes: int = Field(ge=0, le=1440)
    scroll_budget: int = Field(ge=0, le=1440, default=30)
    recovery_actions_taken: int = Field(ge=0, le=1000)

    # Energy
    energy_readings: list[int] = Field(default_factory=list, max_length=24)

    # Rituals
    intention_completed: bool = False
    shutdown_completed: bool = False

    # Config
    private_mode: bool = True
    prompt_version: int = 1


class DailyReportInsight(BaseModel):
    """Structured AI insight for the daily report."""
    headline: str = Field(description="One-sentence summary of the day", max_length=200)
    highlight: str = Field(description="Best thing about today, with specific numbers", max_length=200)
    growth_area: str = Field(description="One specific improvement suggestion, framed positively", max_length=200)
    energy_insight: str = Field(description="What the energy pattern suggests", max_length=200)
    tomorrow_tip: str = Field(description="One actionable recommendation for tomorrow", max_length=200)


class DailyReportResponse(BaseModel):
    insight: DailyReportInsight
    prompt_version: int


# ─── Break Suggestion ────────────────────────────────────────────

class BreakSuggestionRequest(BaseModel):
    session_type: SessionType
    focus_minutes: int = Field(ge=0, le=1440)
    quality_grade: str = Field(max_length=5)
    xp_earned: int = Field(ge=0, le=10000)
    energy_level: Optional[int] = Field(None, ge=1, le=5)
    preferred_type: Optional[BreakContentType] = None
    prompt_version: int = 1


class BreakSuggestionResponse(BaseModel):
    content_type: BreakContentType
    content: str = Field(max_length=1000)
    answer: Optional[str] = Field(None, max_length=500)  # For riddles
    source: Optional[str] = Field(None, max_length=500)  # For facts/quotes
    prompt_version: int


# ─── Brain Dump ───────────────────────────────────────────────────

class BrainDumpRequest(BaseModel):
    raw_text: str = Field(min_length=3, max_length=5000)
    current_energy: Optional[int] = Field(None, ge=1, le=5)
    prompt_version: int = 1


class SortedTask(BaseModel):
    title: str = Field(max_length=200)
    energy_level: EnergyLevel
    estimated_minutes: int = Field(ge=5, le=480)
    friction_score: float = Field(ge=0.0, le=1.0, description="0=easy start, 1=high friction")
    suggested_order: int = Field(ge=1, le=100)
    reasoning: str = Field(max_length=500)


class BrainDumpResponse(BaseModel):
    tasks: list[SortedTask]
    prompt_version: int


# ─── Weekly Review ────────────────────────────────────────────────

class WeeklyReviewRequest(BaseModel):
    week_start: str = Field(min_length=10, max_length=10)
    week_end: str = Field(min_length=10, max_length=10)
    daily_scores: list[int] = Field(default_factory=list, max_length=7)  # 7 scores
    total_focus_hours: float = Field(default=0.0, ge=0.0, le=168.0)
    total_tasks_completed: int = Field(default=0, ge=0, le=5000)
    total_xp: int = Field(default=0, ge=0)
    scroll_total_minutes: int = Field(default=0, ge=0, le=10080)
    recovery_actions: int = Field(default=0, ge=0, le=5000)
    streak_days: int = Field(default=0, ge=0, le=10000)
    best_day_score: int = Field(default=0, ge=0, le=100)
    worst_day_score: int = Field(default=0, ge=0, le=100)
    mits_completed: int = Field(default=0, ge=0, le=21)
    mits_total: int = Field(default=0, ge=0, le=21)
    private_mode: bool = False
    prompt_version: int = 1


class WeeklyReviewResponse(BaseModel):
    summary: str = Field(max_length=1000)
    wins: list[str] = Field(max_length=10)
    growth_areas: list[str] = Field(max_length=10)
    reflection_questions: list[str] = Field(max_length=10)
    next_week_focus: str = Field(max_length=500)
    prompt_version: int

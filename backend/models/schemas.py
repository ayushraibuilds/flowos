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
    duration_minutes: int
    quality_grade: str
    task_title: Optional[str] = None  # None in private mode


class TaskSummary(BaseModel):
    title: Optional[str] = None  # None in private mode
    energy_level: EnergyLevel
    completed: bool
    is_mit: bool
    xp_earned: int = 0


class DailyReportRequest(BaseModel):
    """Daily data sent to the AI for report generation."""
    date: str
    daily_score: int = Field(ge=0, le=100)
    xp_earned_today: int = Field(ge=0)
    lifetime_xp: int = Field(ge=0)
    level: int = Field(ge=0)
    streak_days: int = Field(ge=0)

    # Focus
    total_focus_minutes: int = Field(ge=0)
    sessions: list[SessionSummary] = []

    # Tasks
    tasks_completed: int = Field(ge=0)
    tasks_total: int = Field(ge=0)
    mits_completed: int = Field(ge=0, le=3)
    task_summaries: list[TaskSummary] = []

    # Attention
    scroll_minutes: int = Field(ge=0)
    scroll_budget: int = Field(ge=0, default=30)
    recovery_actions_taken: int = Field(ge=0)

    # Energy
    energy_readings: list[int] = []  # 1-5, up to 3

    # Rituals
    intention_completed: bool = False
    shutdown_completed: bool = False

    # Config
    private_mode: bool = False
    prompt_version: int = 1


class DailyReportInsight(BaseModel):
    """Structured AI insight for the daily report."""
    headline: str = Field(description="One-sentence summary of the day")
    highlight: str = Field(description="Best thing about today, with specific numbers")
    growth_area: str = Field(description="One specific improvement suggestion, framed positively")
    energy_insight: str = Field(description="What the energy pattern suggests")
    tomorrow_tip: str = Field(description="One actionable recommendation for tomorrow")


class DailyReportResponse(BaseModel):
    insight: DailyReportInsight
    prompt_version: int


# ─── Break Suggestion ────────────────────────────────────────────

class BreakSuggestionRequest(BaseModel):
    session_type: SessionType
    focus_minutes: int = Field(ge=0)
    quality_grade: str
    xp_earned: int = Field(ge=0)
    energy_level: Optional[int] = None  # 1-5
    preferred_type: Optional[BreakContentType] = None
    prompt_version: int = 1


class BreakSuggestionResponse(BaseModel):
    content_type: BreakContentType
    content: str
    answer: Optional[str] = None  # For riddles
    source: Optional[str] = None  # For facts/quotes
    prompt_version: int


# ─── Brain Dump ───────────────────────────────────────────────────

class BrainDumpRequest(BaseModel):
    raw_text: str = Field(min_length=3, max_length=5000)
    current_energy: Optional[int] = None  # 1-5
    prompt_version: int = 1


class SortedTask(BaseModel):
    title: str
    energy_level: EnergyLevel
    estimated_minutes: int = Field(ge=5, le=480)
    friction_score: float = Field(ge=0, le=1, description="0=easy start, 1=high friction")
    suggested_order: int
    reasoning: str


class BrainDumpResponse(BaseModel):
    tasks: list[SortedTask]
    prompt_version: int


# ─── Weekly Review ────────────────────────────────────────────────

class WeeklyReviewRequest(BaseModel):
    week_start: str
    week_end: str
    daily_scores: list[int] = []  # 7 scores
    total_focus_hours: float = 0
    total_tasks_completed: int = 0
    total_xp: int = 0
    scroll_total_minutes: int = 0
    recovery_actions: int = 0
    streak_days: int = 0
    best_day_score: int = 0
    worst_day_score: int = 0
    mits_completed: int = 0
    mits_total: int = 0
    private_mode: bool = False
    prompt_version: int = 1


class WeeklyReviewResponse(BaseModel):
    summary: str
    wins: list[str]
    growth_areas: list[str]
    reflection_questions: list[str]
    next_week_focus: str
    prompt_version: int

"""Gemini AI Service — calls Google AI Studio (free tier).

Uses google-genai SDK with structured JSON output.
Falls back to safe defaults on any failure.
"""

import json
import os
import logging
from typing import Optional

from google import genai
from google.genai import types

logger = logging.getLogger("flowos.ai")

# Initialize client
_client: Optional[genai.Client] = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not set")
        _client = genai.Client(api_key=api_key)
    return _client


async def generate_json(
    prompt: str,
    model: str = "gemini-2.0-flash",
    temperature: float = 0.7,
    max_tokens: int = 1024,
) -> dict:
    """Call Gemini and parse structured JSON response.

    Uses response_mime_type="application/json" for reliable JSON output.
    Falls back to text parsing if JSON mode fails.
    """
    try:
        client = _get_client()

        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=temperature,
                max_output_tokens=max_tokens,
                response_mime_type="application/json",
            ),
        )

        text = response.text
        if not text:
            logger.warning("Empty response from Gemini")
            return {}

        return json.loads(text)

    except json.JSONDecodeError as e:
        logger.error(f"JSON parse error: {e}")
        # Try to extract JSON from markdown code blocks
        if response and response.text:
            text = response.text
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0].strip()
                try:
                    return json.loads(text)
                except json.JSONDecodeError:
                    pass
        return {}

    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        return {}


# ─── Fallback Responses ──────────────────────────────────────────

FALLBACK_REPORT = {
    "headline": "Day in review — check your stats below.",
    "highlight": "You showed up today. That matters more than any score.",
    "growth_area": "Try setting your MITs before 9 AM tomorrow for a stronger start.",
    "energy_insight": "Track your energy 3x daily to unlock personalized insights.",
    "tomorrow_tip": "Pick one deep task first thing. Momentum builds from there."
}

FALLBACK_BREAK_SUGGESTIONS = [
    {
        "content_type": "riddle",
        "content": "I have cities, but no houses live there. I have mountains, but no trees grow there. I have water, but no fish swim there. What am I?",
        "answer": "A map",
        "source": None
    },
    {
        "content_type": "fact",
        "content": "The average person walks about 100,000 miles in a lifetime — that's the equivalent of walking around the Earth 4 times.",
        "answer": None,
        "source": "National Geographic"
    },
    {
        "content_type": "quote",
        "content": "The mind is not a vessel to be filled, but a fire to be kindled.",
        "answer": None,
        "source": "Plutarch"
    },
    {
        "content_type": "breathing",
        "content": "Box breathing: Inhale 4 seconds → Hold 4 seconds → Exhale 4 seconds → Hold 4 seconds. Repeat 4 times. Used by Navy SEALs for calm under pressure.",
        "answer": None,
        "source": None
    },
    {
        "content_type": "riddle",
        "content": "What can travel around the world while staying in a corner?",
        "answer": "A stamp",
        "source": None
    },
    {
        "content_type": "fact",
        "content": "Honey never spoils. Archaeologists have found 3000-year-old honey in Egyptian tombs that was still perfectly edible.",
        "answer": None,
        "source": "Smithsonian Magazine"
    },
    {
        "content_type": "quote",
        "content": "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
        "answer": None,
        "source": "Will Durant (commonly attributed to Aristotle)"
    },
    {
        "content_type": "breathing",
        "content": "4-7-8 technique: Inhale through nose for 4 seconds → Hold for 7 seconds → Exhale through mouth for 8 seconds. Repeat 3 times. Activates the parasympathetic nervous system.",
        "answer": None,
        "source": "Dr. Andrew Weil"
    },
]

FALLBACK_WEEKLY = {
    "summary": "Another week in the books. Check the numbers below for your trends.",
    "wins": ["You kept showing up — consistency is the real game.", "Every focus session is progress."],
    "growth_areas": ["Try protecting your first 90 minutes for deep work.", "Use recovery actions after scrolling to bounce back."],
    "reflection_questions": [
        "What was your best focus session this week, and what made it work?",
        "If you could only do 3 things next week, what would they be?",
        "What drained your energy most? Can you reduce or eliminate it?"
    ],
    "next_week_focus": "Start each day with one deep work session before checking messages."
}

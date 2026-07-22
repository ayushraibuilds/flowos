"""Gemini AI Service — calls Google AI Studio (free tier).

Uses google-genai SDK with structured JSON output.
Runs synchronous calls outside FastAPI's event loop.
Protected by a circuit breaker, retries, and timeout settings.
Outputs are validated and sanitized to mitigate prompt injection.
"""

import json
import os
import logging
import asyncio
import time
import re
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
        # Enforce HTTP timeout client-side at 10.0 seconds
        _client = genai.Client(
            api_key=api_key,
            http_options={'timeout': 10.0}
        )
    return _client


# ─── Circuit Breaker Pattern ──────────────────────────────────────

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: float = 30.0):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = 0.0
        self.state = "CLOSED"  # CLOSED, OPEN, HALF-OPEN

    def record_success(self):
        self.failure_count = 0
        self.state = "CLOSED"

    def record_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"
            logger.warning(f"🚨 Circuit Breaker tripped: state=OPEN, threshold={self.failure_threshold}")

    def can_execute(self) -> bool:
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF-OPEN"
                logger.info("⚡ Circuit Breaker recovery timeout expired: state=HALF-OPEN")
                return True
            return False
        return True

_breaker = CircuitBreaker()


# ─── Output Sanitizer ─────────────────────────────────────────────

def _sanitize_string(val) -> any:
    """Recursively strip markdown links, HTML, and script code from output fields."""
    if isinstance(val, str):
        # 1. Strip markdown links: [text](url) -> text (removes external redirection urls)
        val = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', val)
        # 2. Strip HTML tags
        val = re.sub(r'<[^>]*>', '', val)
        # 3. Strip dangerous execution contexts/protocols
        val = re.sub(r'(?:javascript:|data:text/html|system:|sudo\s)', '', val, flags=re.IGNORECASE)
        return val.strip()
    elif isinstance(val, list):
        return [_sanitize_string(item) for item in val]
    elif isinstance(val, dict):
        return {k: _sanitize_string(v) for k, v in val.items()}
    return val


class SafetyBlockException(Exception):
    """Raised when Gemini blocks content due to safety filters."""
    pass


# ─── GenAI Thread Execution ───────────────────────────────────────

def _generate_sync(client: genai.Client, model: str, prompt: str, temperature: float, max_tokens: int) -> str:
    """Blocking synchronous call to the GenAI SDK."""
    response = client.models.generate_content(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_tokens,
            response_mime_type="application/json",
        ),
    )
    if response and hasattr(response, 'prompt_feedback') and getattr(response.prompt_feedback, 'block_reason', None):
        block_reason = getattr(response.prompt_feedback, 'block_reason')
        logger.warning(f"Gemini prompt safety block: {block_reason}")
        raise SafetyBlockException(f"Content blocked: {block_reason}")

    if not response or not response.text:
        raise ValueError("Empty response received from model provider")
    return response.text


# ─── Main generate_json Function ──────────────────────────────────

async def generate_json(
    prompt: str,
    model: str = "gemini-2.0-flash",
    temperature: float = 0.7,
    max_tokens: int = 1024,
) -> dict:
    """Call Gemini in a non-blocking background thread with circuit breaker, timeout, and retries.

    Returns sanitized, structured dictionary, or an empty dictionary on error/breaker trip.
    """
    if not _breaker.can_execute():
        logger.warning("🚫 Circuit Breaker is OPEN. Gemini request skipped.")
        return {}

    # Read configuration keys
    try:
        client = _get_client()
    except Exception as e:
        logger.error(f"Failed to initialize Gemini client: {e}")
        return {}

    # Retry loop with max 3 attempts
    max_retries = 3
    for attempt in range(1, max_retries + 1):
        try:
            # Run the synchronous GenAI SDK generate_content call in a separate thread.
            # Free up the main loop thread to continue serving FastAPI routes/rate limiting.
            text = await asyncio.to_thread(
                _generate_sync, client, model, prompt, temperature, max_tokens
            )
            
            # Parse json
            result = json.loads(text)
            
            # Success: update breaker state
            _breaker.record_success()
            
            # Recursively sanitize model output to block prompt injections from executing links/HTML
            return _sanitize_string(result)

        except SafetyBlockException as e:
            logger.warning(f"Gemini safety block encountered: {e}. Skipping retries.")
            return {}

        except json.JSONDecodeError as e:
            logger.error(f"JSON parse error (attempt {attempt}/{max_retries}): {e}")
            # Attempt parsing fallback from markdown code blocks
            try:
                if "```json" in text:
                    text_extracted = text.split("```json")[1].split("```")[0].strip()
                    result = json.loads(text_extracted)
                    _breaker.record_success()
                    return _sanitize_string(result)
            except Exception:
                pass
            
            if attempt == max_retries:
                _breaker.record_failure()
                
        except Exception as e:
            logger.error(f"Gemini error (attempt {attempt}/{max_retries}): {e}")
            if attempt == max_retries:
                _breaker.record_failure()
            # Brief backoff before retry
            await asyncio.sleep(0.5 * attempt)

    return {}


# ─── Fallback Responses ──────────────────────────────────────────

FALLBACK_REPORT = {
    "headline": "Day in review — check your stats below.",
    "highlight": "You showed up today. That matters more than any score.",
    "growth_area": "Try setting your MITs before 9 AM tomorrow for a strongest start.",
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
        "What was your focus session look like this week, and what made it work?",
        "If you could only do 3 things next week, what would they be?",
        "What drained your energy most? Can you reduce or eliminate it?"
    ],
    "next_week_focus": "Start each day with one deep work session before checking messages."
}

"""Unit tests for backend/routers/ai.py utility functions and input sanitization."""

import sys
import unittest
from pathlib import Path

# Ensure project root is in sys.path
root_dir = Path(__file__).resolve().parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

try:
    from backend.routers.ai import _escape_prompt_text  # type: ignore
    from backend.models.schemas import DailyReportRequest  # type: ignore
except ImportError:
    from routers.ai import _escape_prompt_text  # type: ignore
    from models.schemas import DailyReportRequest  # type: ignore


class TestAIRouter(unittest.TestCase):
    def test_escape_prompt_text_sanitizes_delimiters(self):
        # Escapes curly braces and Markdown block separators to mitigate prompt injection
        input_text = "Task title {ignore prompt} --- malicious instructions"
        escaped = _escape_prompt_text(input_text)

        self.assertNotIn("{", escaped)
        self.assertNotIn("}", escaped)
        self.assertNotIn("---", escaped)
        self.assertEqual(escaped, "Task title (ignore prompt) - - - malicious instructions")

    def test_daily_report_request_private_mode_defaults_to_true(self):
        # Default for privacy-by-default must be True
        req = DailyReportRequest(
            date="2026-07-22",
            daily_score=85,
            xp_earned_today=100,
            lifetime_xp=500,
            level=2,
            streak_days=3,
            total_focus_minutes=120,
            tasks_completed=3,
            tasks_total=5,
            mits_completed=2,
            scroll_minutes=15,
            scroll_budget=30,
            recovery_actions_taken=1,
        )

        self.assertTrue(req.private_mode, "private_mode should default to True for privacy")


if __name__ == "__main__":
    unittest.main()

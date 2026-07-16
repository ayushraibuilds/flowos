import unittest
from backend.services.prompt_renderer import PromptRenderer

class TestPromptRenderer(unittest.TestCase):
    def test_render_daily_report_representative(self):
        # 1. Representative input
        prompt = PromptRenderer.render_daily_report(
            daily_score=85,
            grade="A",
            xp_earned_today=120,
            level=3,
            streak_days=5,
            total_focus_minutes=150,
            session_count=6,
            tasks_completed=4,
            tasks_total=6,
            mits_completed=2,
            scroll_minutes=15,
            scroll_budget=30,
            recovery_actions_taken=3,
            energy_readings="[4, 3, 5]",
            intention_completed=True,
            shutdown_completed=False,
            task_details="\nTasks:\n  ✅ Complete code review\n  ❌ Finish slide deck",
        )
        self.assertIn("Daily Score: 85/100 (Grade: A)", prompt)
        self.assertIn("Morning Intention: ✅", prompt)
        self.assertIn("Shutdown Ritual: ❌", prompt)
        self.assertIn("Complete code review", prompt)

    def test_render_daily_report_empty(self):
        # 2. Empty/minimum input
        prompt = PromptRenderer.render_daily_report(
            daily_score=0,
            grade="F",
            xp_earned_today=0,
            level=0,
            streak_days=0,
            total_focus_minutes=0,
            session_count=0,
            tasks_completed=0,
            tasks_total=0,
            mits_completed=0,
            scroll_minutes=0,
            scroll_budget=30,
            recovery_actions_taken=0,
            energy_readings="Not recorded",
            intention_completed=False,
            shutdown_completed=False,
            task_details="",
        )
        self.assertIn("Daily Score: 0/100 (Grade: F)", prompt)
        self.assertIn("Morning Intention: ❌", prompt)
        self.assertIn("Shutdown Ritual: ❌", prompt)

    def test_render_daily_report_private(self):
        # 3. Private mode input (no task details / title text)
        prompt = PromptRenderer.render_daily_report(
            daily_score=95,
            grade="A+",
            xp_earned_today=250,
            level=5,
            streak_days=12,
            total_focus_minutes=240,
            session_count=8,
            tasks_completed=5,
            tasks_total=5,
            mits_completed=3,
            scroll_minutes=5,
            scroll_budget=45,
            recovery_actions_taken=1,
            energy_readings="[5, 5, 4]",
            intention_completed=True,
            shutdown_completed=True,
            task_details="",  # empty in private mode
        )
        self.assertNotIn("\nTasks:\n", prompt)
        self.assertIn("Morning Intention: ✅", prompt)
        self.assertIn("Shutdown Ritual: ✅", prompt)

    def test_render_daily_report_max_size(self):
        # 4. Maximum-size input
        large_task_details = "\nTasks:\n" + "\n".join([f"  ✅ Task item number {i} with a very long descriptive title details" for i in range(100)])
        prompt = PromptRenderer.render_daily_report(
            daily_score=100,
            grade="A+",
            xp_earned_today=5000,
            level=99,
            streak_days=365,
            total_focus_minutes=1440,
            session_count=99,
            tasks_completed=100,
            tasks_total=100,
            mits_completed=3,
            scroll_minutes=999,
            scroll_budget=999,
            recovery_actions_taken=99,
            energy_readings="[5, 5, 5, 5, 5, 5, 5]",
            intention_completed=True,
            shutdown_completed=True,
            task_details=large_task_details,
        )
        self.assertIn("Daily Score: 100/100 (Grade: A+)", prompt)
        self.assertIn("Task item number 99", prompt)

    def test_render_break_suggestion(self):
        prompt = PromptRenderer.render_break_suggestion(
            session_type="pomodoro",
            focus_minutes=25,
            quality_grade="A",
            xp_earned=50,
            energy_level="4",
            preferred_type="riddle",
            content_type="riddle",
        )
        self.assertIn("Type: pomodoro", prompt)
        self.assertIn("Duration: 25 min", prompt)

    def test_render_brain_dump(self):
        prompt = PromptRenderer.render_brain_dump(
            raw_text="buy milk and clean the desk by 5pm",
            current_energy="3",
        )
        self.assertIn("buy milk and clean the desk by 5pm", prompt)

    def test_render_weekly_review(self):
        prompt = PromptRenderer.render_weekly_review(
            week_start="2026-07-10",
            week_end="2026-07-16",
            daily_scores=[80, 85, 90, 75, 70, 95, 90],
            avg_score=83.5,
            total_focus_hours=12.5,
            total_tasks_completed=28,
            total_xp=840,
            scroll_total_minutes=140,
            recovery_actions=5,
            streak_days=7,
            best_day_score=95,
            worst_day_score=70,
            mits_completed=15,
            mits_total=21,
        )
        self.assertIn("WEEK DATA (2026-07-10 to 2026-07-16)", prompt)
        self.assertIn("avg: 83.5", prompt)

if __name__ == '__main__':
    unittest.main()

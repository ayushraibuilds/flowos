# Implementation Plan: Four Engagement Features
 
## Context
 
FlowOS currently has:
- A **generic 3-page onboarding** (`onboarding_screen.dart`) that ends at `/auth` with no preferences stored and no first success moment.
- **Insights** that still use placeholder peak windows; session quality + timestamps exist in `FocusSessions` but are never turned into an **actionable** recommendation.
- **Scroll Tracker** that starts a timer on tap with no intent gate; recovery only appears *after* logging.
- **Daily / weekly reports** that summarize and optionally call AI, but end with “Done” / share — **no commit-to-change CTA**.
 
These four features close the loop from **first open → first win → local intelligence → intentional scrolling → weekly behavior change**, without requiring OS Screen Time APIs for v1.
 
---
 
## Goals (product)
 
| # | Feature | Success looks like |
|---|---------|-------------------|
| **F1** | First-win onboarding | User configures goals/distractions/window/protection in ~90s, then completes a **10-min “plant your first seed”** focus session. |
| **F2** | Adaptive rhythm | After enough local data, Home (and Insights) show **one** evidence-based rec with **Accept → schedule / start session**. |
| **F3** | Mindful interruption | Before any distraction timer starts: **“What are you here for?”**; rest → timed intentional break. |
| **F4** | Weekly story → one change | Weekly (and daily) report ends with **one concrete action** user can accept into tomorrow’s plan. |
 
**Non-goals (this plan):** Android/iOS OS-level app blocking; AI-required recommendations (local first); multi-week experiment framework.
 
---
 
## Architecture overview
 
```text
┌─────────────────────┐     prefs + optional Drift
│  UserProfilePrefs   │◄──── onboarding answers
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐     FocusSessions + ScrollLogs + Plans
│  RhythmEngine       │◄──── local aggregates
│  (one Recommendation)│
└──────────┬──────────┘
           │ Accept
           ▼
┌─────────────────────┐
│  SuggestedSession   │──► FocusScreen / DailyPlans / Tasks
└─────────────────────┘
 
Scroll intent sheet ──► ScrollLogs (+ intent) or RestBreakScreen
WeeklyActionEngine  ──► one ActionCard → apply to plan/tasks
```
 
**Storage strategy (v1):**
- **Onboarding + protection mode + distraction list + protected window:** `SharedPreferences` via a small `UserProfileStore` (fast, no migration pain).
- **Optional later:** Drift `user_preferences` table if sync needed — out of scope unless multi-device is required immediately.
- **Scroll intent:** extend `ScrollLogs` (schema migration) or store intent in free-text field — **recommend migration**.
- **Accepted weekly actions / recommendations:** prefs last-accepted id + optional `daily_plans` note / MIT / scheduled focus extras.
 
---
 
## Feature 1 — First-win onboarding
 
### UX flow (5 steps + session)
 
| Step | Title | Interaction | Validation |
|------|--------|-------------|------------|
| 0 | What do you want more of? | Multi-select chips: **Deep work, Study, Rest, Less scrolling** (1–3 max) | ≥1 required |
| 1 | Your top distractions | Multi-select exactly **3** from: Instagram, YouTube/Shorts, TikTok, X/Twitter, Reddit, Browser, Games, Other | Exactly 3 |
| 2 | Protected window | Pick **weekday pattern** (every day / weekdays) + **start–end** (e.g. 9:00–11:00) via two time pickers or preset chips | End > start |
| 3 | Protection style | **Gentle** vs **Firm** (explain in one line each) | Required |
| 4 | Plant your first seed | Copy: “10 minutes to plant your first seed.” CTA → start session | — |
 
**Protection semantics (v1, app-level only):**
 
| Mode | Behavior |
|------|----------|
| **Gentle** | During protected window: soft banner on Home “You’re in protected time”; scroll tracker shows a calm reminder; no hard block. |
| **Firm** | During protected window: opening Scroll Tracker shows intent sheet first; after “avoiding” intent, require confirmation; optional future OS block hooks. Distraction apps list prioritizes in UI. |
 
**First seed session:**
- Navigate to focus with **forced 10-minute custom** session (`durationMinutes: 10`, `SessionTypeColumn.custom`).
- Copy/branding: title “Plant your first seed” (pass via route `extra`).
- **XP gate:** current custom min is **5 min** (`XpConstants.minCustomSeconds`) — 10 min natural complete is fine; mark session with `ambientSound` or explanation tag “first_seed”.
- On complete → Break celebration → Home (onboarding complete flag set **before** session so kill mid-session still doesn’t re-show full onboarding; use `first_seed_completed` separately for garden metaphor later).
 
### Routing & first-run gate
 
**Today:** `app_router.dart` `initialLocation: '/home'`; onboarding never auto-shown.
 
**Implement:**
1. Bootstrap in `main.dart`: load `flowos_onboarding_complete` from SharedPreferences.
2. `initialLocation`: incomplete → `/onboarding`, else `/home`.
3. Optional: existing users with any XP/plans auto-set complete (migration one-shot).
4. Remove or demote “Skip” to “Use offline without setup” (still set defaults: deep work, 3 default distractions, weekdays 9–11, gentle).
 
**Auth:** After first seed, offer auth optionally — **do not force** before first win. Flow:
 
```text
/onboarding (setup) → /focus?firstSeed=true → /break → /home
                                           ↘ optional /auth from settings
```
 
### Files to create / modify
 
| Path | Action |
|------|--------|
| `lib/features/onboarding/models/user_profile.dart` | Goals enum, protection enum, protected window model, JSON/prefs encode |
| `lib/features/onboarding/services/user_profile_store.dart` | Load/save SharedPreferences |
| `lib/features/onboarding/providers/onboarding_providers.dart` | Riverpod |
| `lib/presentation/screens/onboarding/onboarding_screen.dart` | **Replace** PageView marketing with 5-step setup wizard |
| `lib/presentation/screens/onboarding/widgets/` | Step widgets (chips, time presets) |
| `lib/presentation/navigation/app_router.dart` | Bootstrap initial route; focus extras for first seed |
| `lib/presentation/screens/focus/focus_screen.dart` | Accept `extra: { minutes: 10, title, firstSeed: true }` auto-start or preselect |
| `lib/main.dart` | Load onboarding flag before `runApp` |
 
### Reuse
 
- Theme tokens: `AppColors`, `AppSpacing`, `AppTypography`
- Focus insert + `FocusSessionService.completeSession` for custom 10m
- Break route already fixed with `context.go`
 
### Edge cases
 
- User kills app mid-wizard → resume at last step index in prefs.
- User finishes setup but abandons seed under min → still complete onboarding; show Home CTA “Finish planting your seed (10m).”
- Firm mode without OS permissions → still meaningful via intent friction (F3).
 
---
 
## Feature 2 — Adaptive rhythm (not generic AI)
 
### Principle
 
**One recommendation, local math, evidence-based.** No LLM required for v1. AI can later rephrase copy only.
 
### Data inputs (already in Drift)
 
- `FocusSessions`: `startedAt`, `actualMinutes`, `qualityScore` (A/B/C/D), `sessionType`, `completedAt`
- `Tasks` / MITs + completion times (optional)
- `EnergyCheckIns` when present (optional boost)
- `DailyPlans` weekday patterns
 
### Eligibility thresholds (tunable constants)
 
```text
MIN_SESSIONS = 8          // completed sessions with actualMinutes >= 5
MIN_DISTINCT_DAYS = 5
MIN_QUALITY_SESSIONS = 5  // with non-empty qualityScore
```
 
If not met → **no card** (or “Keep logging — unlock your rhythm after ~1 week”). Never show placeholder peaks as truth.
 
### Algorithm (`RhythmEngine`)
 
File: `lib/features/rhythm/services/rhythm_engine.dart`
 
1. Load sessions in last **28 days** with `actualMinutes >= 5` and `completedAt != null`.
2. Bucket by:
   - **Hour-of-day** (or 2-hour windows: 6–8, 8–10, …)
   - **Weekday**
3. Score each bucket:
 
   ```text
   qualityWeight(A=1.0, B=0.85, C=0.65, D=0.4, empty=0.5)
   bucketScore = sum(actualMinutes * qualityWeight) / count
   ```
 
4. Pick best hour window with `count >= 3` sessions.
5. Pick best weekday among those sessions (or overall weekday focus volume).
6. Compose **one** `RhythmRecommendation`:
 
   ```dart
   class RhythmRecommendation {
     final String id; // hash of window+weekday for dismiss/accept
     final String headline; // "Your highest-quality sessions land 9–11 AM"
     final String actionLabel; // "Protect Tuesday morning for your hardest MIT"
     final int windowStartHour;
     final int windowEndHour;
     final int? preferredWeekday; // 1=Mon … 7=Sun
     final List<String> evidence; // "12 sessions · avg grade B · 6.2h total"
     final DateTime generatedAt;
   }
   ```
 
7. **Stability:** regenerate at most daily; if user dismissed, don’t show same `id` for 7 days.
 
### Accept as suggested session (not read-only)
 
**UI surfaces:**
1. **Home** primary card when eligible (above MITs) — highest priority.
2. Insights — same card, not fake forecast charts until data ready.
 
**Accept actions (sheet):**
 
| Action | Effect |
|--------|--------|
| **Schedule next window** | Create/update tomorrow (or next preferred weekday) `DailyPlans` intention note / store `suggested_focus_start` in prefs; optional local notification at window start |
| **Start now** | `context.push('/focus')` or deep work with preselected duration (25 or 45) |
| **Pick hardest MIT** | If MITs exist, mark top incomplete MIT; else open tasks |
| **Not now** | Dismiss 7 days |
 
**Suggested session model** (in-memory / prefs):
 
```dart
class SuggestedSession {
  final DateTime? scheduledFor;
  final int durationMinutes;
  final String? taskId;
  final String source; // 'rhythm'
}
```
 
Home CTA when `SuggestedSession` is for today and within ±30 min of window: **“Start protected focus”**.
 
### Files
 
| Path | Action |
|------|--------|
| `lib/features/rhythm/models/rhythm_recommendation.dart` | Models |
| `lib/features/rhythm/services/rhythm_engine.dart` | Pure aggregation + tests |
| `lib/features/rhythm/providers/rhythm_providers.dart` | Riverpod |
| `lib/presentation/widgets/rhythm_recommendation_card.dart` | Shared UI |
| `lib/presentation/screens/home/home_screen.dart` | Embed card + accept sheet |
| `lib/presentation/screens/insights/insights_dashboard_screen.dart` | Replace fake energy forecast with real engine or empty |
| `test/unit/rhythm_engine_test.dart` | Synthetic sessions → expected window |
 
### Reuse
 
- `FocusSessionsDao.getByDateRange`
- `FocusQualityCalculator` grades already on sessions
- `NotificationService` (if scheduled) for window reminder — only if already initialized; else prefs + Home banner
 
---
 
## Feature 3 — Mindful interruption for scrolling
 
### Principle
 
**Interrupt before the timer**, not after. Frame as agency, not shame.
 
### Flow
 
```text
User taps Instagram (or any distraction app / quick log)
  → if firm protection OR always (product: always for distraction list)
  → show IntentBottomSheet: "What are you here for?"
      · Reply to someone
      · Look something up
      · Rest
      · I'm avoiding something
      · Just scrolling (honest)
  → branch:
      Rest → IntentionalRestScreen (timed 5/10/15 min, no doom content)
      Reply / Lookup → start scroll timer with intent tagged; optional soft timebox (5–10 min) firm mode
      Avoiding → micro-prompt: "Want a 2-min breath or a tiny task instead?" then allow proceed or divert to focus
      Just scrolling → start timer; firm mode shows 10s breathing pause first
```
 
### Data model
 
**Migration `schemaVersion` 1 → 2** on `AppDatabase`:
 
```text
ScrollLogs:
  + intent text nullable  // reply | lookup | rest | avoiding | scrolling
  + was_timeboxed bool default false
  + planned_minutes int nullable
```
 
Update `scroll_logs_dao.dart` + companion inserts.
 
**Onboarding distractions** highlight which apps use the interruption by default (all selected 3).
 
### UI components
 
| Path | Role |
|------|------|
| `lib/features/attention/widgets/scroll_intent_sheet.dart` | 5 options |
| `lib/presentation/screens/rest/intentional_rest_screen.dart` | Timer + “rest well” copy + optional ambient; on end → optional bounce-back XP **without** scroll cost |
| `lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart` | Gate `_toggleApp` / `_quickLog` through intent sheet |
 
### Firm vs gentle
 
| | Gentle | Firm |
|--|--------|------|
| Intent sheet | Yes for top 3 distractions | Yes for all apps + quick log |
| Rest path | Optional | Encouraged when “avoiding” |
| Timebox | Soft snackbar at 10m | Auto-stop timer + recovery sheet |
| Protected window | Banner only | Intent sheet mandatory + longer copy |
 
Read `UserProfileStore.protectionMode` + `distractions`.
 
### Rest session (not a lecture)
 
- Title: “Intentional rest”
- Duration chips: 5 / 10 / 15
- Simple breathing circle or quiet timer (reuse ritual breath patterns if present)
- End: “How do you feel?” optional 1–5 energy check-in hook (if energy UI exists later)
- **Do not** log as scroll; optional `recoveryActionTaken` on a zero-duration scroll log **or** separate XP `breakContentUsed` — prefer no scroll cost.
 
### Reuse
 
- Scroll app grid list already on tracker
- Recovery sheet after log — keep for post-session; intent is pre-session
- `XpConstants.bounceBackBonus` only if user does recovery after doomscroll, not after intentional rest
 
---
 
## Feature 4 — Weekly story, then one change
 
### Principle
 
Analytics without commitment is incomplete. Every weekly review (and daily report) ends with **exactly one** action the user can accept.
 
### Action types (enum)
 
```dart
enum WeeklyActionType {
  scheduleFocusWindow,  // book protected time
  reduceOneTrigger,     // lower budget or flag one distraction for firm treatment
  moveTaskToEnergy,     // reschedule / re-energy a hard task
}
```
 
### Action engine (local)
 
File: `lib/features/reports/services/weekly_action_engine.dart`
 
Inputs: last 7 days focus, scroll by app, MIT completion, energy if any, user goals from onboarding.
 
**Priority rules (first match wins):**
 
1. If one distraction app > 40% of scroll → `reduceOneTrigger` (that app).
2. Else if best quality window known (RhythmEngine) and user has incomplete deep tasks → `moveTaskToEnergy` or `scheduleFocusWindow` on that weekday/hour.
3. Else if focus minutes < 60 for week → `scheduleFocusWindow` (25m tomorrow morning).
4. Else → `scheduleFocusWindow` using protected window from onboarding.
 
Copy examples:
- “Schedule one 45-minute focus window tomorrow at 9:00.”
- “Treat Instagram as firm for 7 days (intent required).”
- “Move ‘Write proposal’ to your 9–11 deep window.”
 
### UI changes
 
**Weekly review** (`weekly_review_screen.dart`):
- Keep summary / wins / growth / reflection steps.
- Replace final “Done” step with **`_buildOneChangeStep()`**:
  - Story line (1–2 sentences from data, not generic AI if offline).
  - Action card with primary **Accept** and secondary **Choose different** (cycle next rule) / **Skip**.
- On Accept:
  - `scheduleFocusWindow` → write prefs + optional notification; Home shows tomorrow CTA.
  - `reduceOneTrigger` → update distraction firm list in profile store.
  - `moveTaskToEnergy` → set task energy to deep / sort order; if no task, open tasks.
- Persist `last_weekly_action_id` + accepted date to avoid re-proposing same action next week without new data.
 
**Daily report** (`daily_report_screen.dart`):
- Add bottom section **“One thing for tomorrow”** (lighter than weekly): single line + Accept.
- Can reuse a thinner `DailyActionEngine` (subset of rules on today’s data).
 
### AI role
 
- Optional: pass action into weekly AI prompt as `suggested_action` so narrative aligns.
- Fallback always works offline.
 
### Files
 
| Path | Action |
|------|--------|
| `lib/features/reports/models/weekly_action.dart` | Model |
| `lib/features/reports/services/weekly_action_engine.dart` | Rules |
| `lib/features/reports/services/daily_action_engine.dart` | Daily subset |
| `lib/presentation/screens/report/weekly_review_screen.dart` | Final step + apply |
| `lib/presentation/screens/report/daily_report_screen.dart` | Tomorrow CTA |
| `lib/presentation/widgets/action_commit_card.dart` | Shared Accept UI |
| `test/unit/weekly_action_engine_test.dart` | Rule priority tests |
 
### Reuse
 
- Existing `_weekData` aggregation in weekly review
- `DailyScoreCalculator` / plan upsert patterns from morning intention
- Onboarding protected window + distractions as defaults
 
---
 
## Shared infrastructure
 
### `UserProfileStore` keys
 
```text
flowos_onboarding_complete          bool
flowos_onboarding_step              int
flowos_goals                        stringList
flowos_distractions                 stringList  // exactly 3 after setup
flowos_protected_start_hour         int
flowos_protected_end_hour           int
flowos_protected_weekdays_only      bool
flowos_protection_mode              gentle|firm
flowos_first_seed_completed         bool
flowos_rhythm_dismissed_id          string?
flowos_rhythm_dismissed_until       ms?
flowos_suggested_session_json       string?
flowos_last_weekly_action_json      string?
```
 
### Router extras convention
 
```dart
// Focus
extra: {
  'durationMinutes': 10,
  'sessionLabel': 'Plant your first seed',
  'firstSeed': true,
  'autoStart': true,
}
 
// Deep work / rhythm
extra: {
  'durationMinutes': 45,
  'taskId': '...',
  'source': 'rhythm',
}
```
 
### Schema migration (F3)
 
In `app_database.dart`:
- Bump `schemaVersion` to `2`
- `onUpgrade`: add columns to `scroll_logs` with defaults
- Regenerate Drift with `build_runner` if needed
 
---
 
## Implementation phases (execution order)
 
### Phase A — Profile + First-win onboarding (2–3 days)
 
1. `UserProfile` + `UserProfileStore`
2. Rewrite onboarding wizard (5 steps)
3. Bootstrap routing + migration for existing installs
4. First-seed 10m focus path (auto-start custom)
5. Wire firm/gentle flags for later steps
6. Manual QA: cold install → seed → break → home
 
### Phase B — Mindful scroll interruption (1–2 days)
 
1. Schema migration + DAO
2. Intent sheet + rest screen
3. Gate scroll tracker; respect firm/gentle + distraction list
4. Tests for intent enum mapping
 
### Phase C — Adaptive rhythm (2 days)
 
1. `RhythmEngine` + unit tests with synthetic sessions
2. Recommendation card + accept sheet
3. Home + Insights integration
4. Empty state when under threshold
 
### Phase D — Weekly/daily one change (1–2 days)
 
1. `WeeklyActionEngine` + tests
2. Weekly final step Accept
3. Daily “tomorrow” CTA
4. Apply handlers → prefs / tasks / schedule
 
### Phase E — Polish & verify (1 day)
 
1. Protected-window Home banner
2. Copy pass (non-guilt tone)
3. Analyzer + full test suite
4. Dogfood script
 
**Total estimate:** ~7–10 focused days.
 
---
 
## Critical files summary
 
| Area | Files |
|------|--------|
| Onboarding | `onboarding_screen.dart`, new `user_profile*.dart`, `main.dart`, `app_router.dart`, `focus_screen.dart` |
| Rhythm | new `rhythm_engine.dart`, `home_screen.dart`, `insights_dashboard_screen.dart` |
| Scroll intent | `scroll_tracker_screen.dart`, `scroll_logs_table.dart`, `app_database.dart`, new intent/rest UI |
| Reports | `weekly_review_screen.dart`, `daily_report_screen.dart`, new action engines |
| Existing services | `FocusSessionService`, `FocusSessionsDao`, `ScrollLogsDao`, `DailyPlansDao`, `NotificationService` |
 
---
 
## Verification
 
### Automated
 
```bash
cd flowos
flutter test test/unit/rhythm_engine_test.dart
flutter test test/unit/weekly_action_engine_test.dart
flutter test test/focus_session_service_test.dart
flutter analyze lib/
```
 
### Manual scenarios
 
**F1**
- [ ] Fresh install lands on setup, not Home
- [ ] Cannot proceed without goals / 3 distractions / window / mode
- [ ] Completing setup starts 10m seed; finishing awards XP (if ≥5m min for custom)
- [ ] Kill mid-wizard resumes step; completing seed once doesn’t re-onboard
 
**F2**
- [ ] With <8 sessions: no fake peak card
- [ ] Seed 10 quality sessions in same morning hour (debug/seed script) → recommendation names that window
- [ ] Accept → Start now opens focus; Accept → Schedule shows Home CTA next day
 
**F3**
- [ ] Tap Instagram → intent sheet before timer
- [ ] Rest → intentional rest timer; no scroll cost
- [ ] Avoiding → alternative offered; can still proceed
- [ ] Firm vs gentle differs for non-listed apps
 
**F4**
- [ ] Weekly last step shows one action
- [ ] Accept reduce-trigger updates profile
- [ ] Accept schedule shows up on Home
- [ ] Daily report shows tomorrow action
 
### Tone checklist
 
- [ ] No shame language on scroll intent
- [ ] Recommendations cite counts/grades, not “you should be better”
- [ ] Reports always end with change, not only charts
 
---
 
## Risks & decisions (locked for this plan)
 
| Topic | Decision |
|-------|----------|
| AI for rhythm | **Local first**; AI optional rephrase later |
| OS app blocking | **Out of scope**; firm = in-app friction |
| Onboarding skip | Defaults + mark complete; still offer first seed |
| Min XP for 10m seed | Custom min 5m already allows full credit at natural end |
| Scroll schema | **Migrate** Drift for intent column |
| Multiple recommendations | **Never** — one rhythm card, one weekly action |
 
---
 
## Out of scope follow-ups
 
- Flow Garden growth from first seed visual
- Chrome extension sharing distraction list
- Android UsageStats auto-fill
- Calendar write for protected window
- Server-side personalization
 
---
 
## Definition of done
 
All four features ship when:
 
1. New users get a **configured profile + first 10m session** without reading marketing slides.
2. Power users with enough history see **one evidence-based, acceptable session** on Home.
3. Every distraction log is **preceded by intent**; rest is a real break mode.
4. Weekly review cannot finish without **seeing** a one-change action (accept or explicit skip).
 
*Built with intention — first win, then wisdom, then one change.*

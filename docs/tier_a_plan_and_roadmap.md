# FlowOS — Tier A Implementation Plan & Future Feature Roadmap

> **Status:** Ready to execute
> **Scope:** Pre-public v1 completion (Tier A) + deferred feature specs (Tier B / C)
> **Created:** 2026-07-09
> **Companion docs:** `implementation_plan.md`, `offline_vs_online_report.md`, `STORE_LISTING.md`

---

## Table of contents

1. [Goals & non-goals](#1-goals--non-goals)
2. [Current baseline](#2-current-baseline)
3. [Tier A overview](#3-tier-a-overview)
4. [Tier A detailed implementation](#4-tier-a-detailed-implementation)
5. [Tier A execution schedule](#5-tier-a-execution-schedule)
6. [Tier A verification checklist](#6-tier-a-verification-checklist)
7. [Future feature additions — Tier B](#7-future-feature-additions--tier-b)
8. [Future feature additions — Tier C](#8-future-feature-additions--tier-c)
9. [Dependency graph](#9-dependency-graph)
10. [Risks & decisions](#10-risks--decisions)

---

## 1. Goals & non-goals

### Goals (Tier A)

Ship a **honest, habit-forming v1** that:

1. Makes **energy** a first-class daily action (not just a table).
2. Shows **one correct streak** everywhere.
3. Never displays **fake insights** or sample charts as if they were real.
4. Guides first-run and the **daily intention → focus → shutdown** loop.
5. Actually delivers **notifications** users enable.
6. Applies **unlockable themes** to the live app shell.
7. Keeps **brain dump** useful offline.
8. Lets users **export** their data (trust + App Store privacy narrative).

### Non-goals (Tier A)

- Screen Time / Digital Wellbeing APIs
- Apple Watch / Wear OS
- Social / team features
- Full domain-layer rewrite
- Flow Garden visual product (Tier B)
- Native home widgets (Tier B)
- OS Focus Mode / calendar blocking (Tier B)
- Backend monetization / multi-tenant scale

---

## 2. Current baseline

| Area | State | Implication for Tier A |
|------|--------|-------------------------|
| Energy DAO + table + sync | ✅ Built | Need UI + providers + XP wiring |
| Energy check-in UI | ❌ Missing | Primary P0 |
| `StreakService` (prefs, XP activity, grace) | ✅ | Canonical source |
| `dashboard_providers.streakProvider` (plans / intention) | ⚠️ Diverges | Must delete or re-point |
| `xp_providers.streakProvider` | ✅ Uses `StreakService` | Align Home with this |
| Weekly review aggregates | ✅ Real DAO queries | Wire energy check-ins into daily score loop |
| Insights charts | ❌ Hardcoded sample data | Empty states + real queries |
| Notifications service | ✅ Built | Never called from `main.dart` |
| Onboarding / auth routes | ✅ Exist | Not gated; app opens on `/home` |
| `themeProvider` + settings picker | ✅ Persist theme id | Not applied to `MaterialApp` |
| Brain dump AI | ✅ Online | Offline = snackbar only, no local parse |
| Settings toggles | ⚠️ In-memory only | Scroll budget, sounds, sync not persisted |
| Data export | ❌ None | New feature |
| Ambient sounds assets | ✅ Present | Out of Tier A scope |
| Audit P0/P1 fixes | ✅ Done | Do not regress |

---

## 3. Tier A overview

| ID | Feature | Priority | Est. effort | Depends on |
|----|---------|----------|-------------|------------|
| **A1** | Energy check-in UI + 3×/day loop | P0 | 1–1.5 days | — |
| **A2** | Unify streaks | P0 | 0.5 day | — |
| **A3** | Real Insights + empty states | P0 | 1–1.5 days | A1 (for energy forecast) |
| **A4** | First-run + daily intention gate | P0 | 0.5–1 day | — |
| **A5** | Notification lifecycle | P1 | 0.5 day | A1, A4 (deep links) |
| **A6** | Theme applied end-to-end | P1 | 0.5 day | — |
| **A7** | Offline brain-dump fallback | P1 | 0.5–1 day | A1 (optional energy) |
| **A8** | Data export (JSON/CSV) | P1 | 0.5 day | — |
| **A9** | Settings persistence + polish | P1 | 0.5 day | A5, A6 |

**Total estimate:** ~5–7 focused engineering days.

**"Work with my energy" smart sort** is included as **A1.5** under energy (same ship train) — small UI/provider change, high product leverage.

---

## 4. Tier A detailed implementation

### A1 — Energy check-in UI + 3×/day loop

#### Problem

Brand promise is energy-aware productivity. `EnergyCheckIns` exists in Drift and contributes to `DailyScoreCalculator.ritualScore`, but users cannot log energy. Insights energy forecast and brain-dump energy defaults stay empty/default forever.

#### Product behavior

1. **Quick check-in** (3 taps max): open sheet → pick 1–5 → optional note later (v1 can skip note; table has no note column yet) → save.
2. **Time-of-day bucket:** morning / afternoon / evening derived from clock (or user override chips).
3. **Cap:** max **1 check-in per bucket per day** (upsert if user re-logs same period).
4. **3× bonus:** when `countToday() == 3`, call `XpCalculator.awardEnergyCheckin3xBonus()` once (ledger already has anti-double pattern for similar bonuses).
5. **Surfaces:**
   - Home: energy chip / card ("Energy · —" or last value + "Log")
   - After break screen: optional soft prompt once per session
   - Notification deep link → open same sheet
6. **Smart sort (A1.5):** Tasks list filter/sort mode "Match energy" using latest check-in:
   - Energy 4–5 → deep first, then medium, light
   - Energy 3 → medium first
   - Energy 1–2 → light first, high-friction last

#### Data model

Existing table is enough for v1:

```text
EnergyCheckIns: id, timeOfDay (morning|afternoon|evening), value (1–5), date
```

Optional later (not Tier A): `note TEXT`, `device_id`, `created_at` for sync precision.

**Bucket helper** (new util):

```dart
// lib/core/utils/time_of_day_bucket.dart
TimeOfDayColumn bucketFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return TimeOfDayColumn.morning;
  if (h < 17) return TimeOfDayColumn.afternoon;
  return TimeOfDayColumn.evening;
}
```

#### DAO extensions

File: `lib/data/local/dao/energy_checkins_dao.dart`

| Method | Purpose |
|--------|---------|
| `getTodayCheckIns()` | List for Home / score |
| `getForBucket(TimeOfDayColumn)` today | Detect re-log |
| `upsertTodayCheckIn({bucket, value})` | Insert or update same-day same-bucket |
| `watchToday()` | Stream for reactive Home chip |
| `getCheckInsInRange(start, end)` | Insights / weekly |
| `averageByHourBucket(days)` | Insights energy forecast |

Upsert strategy without schema migration:

1. Query today's row for `timeOfDay`.
2. If exists: update `value` + `date` (or delete + insert).
3. If not: insert new UUID.

If Drift table lacks update helper, add companion update or replace row.

#### New files

| Path | Role |
|------|------|
| `lib/features/energy/widgets/energy_checkin_sheet.dart` | Modal UI |
| `lib/features/energy/providers/energy_providers.dart` | `todayEnergyProvider`, `latestEnergyProvider`, `logEnergy` |
| `lib/features/energy/services/energy_checkin_service.dart` | Upsert + 3× XP + achievement check |
| `lib/core/utils/time_of_day_bucket.dart` | Bucket helper |
| `test/unit/energy_checkin_service_test.dart` | Upsert + 3× bonus |

#### UI spec — sheet

- Title: **How's your energy?**
- Subtitle: auto-detected bucket with chip override (Morning / Afternoon / Evening)
- Five large tappable levels:

  | Value | Label | Emoji |
  |-------|--------|-------|
  | 1 | Drained | 😴 |
  | 2 | Low | 🌤 |
  | 3 | Steady | ⚡ |
  | 4 | High | 🔥 |
  | 5 | Peak | 🚀 |

- Primary button: **Log energy**
- Success: haptic + snackbar "Logged · afternoon 4/5" + dismiss
- If third of day: confetti-lite / snackbar "+20 XP · all check-ins done"

#### Wire-up points

| File | Change |
|------|--------|
| `home_screen.dart` | Energy chip in header or under Flow Score; tap → `showModalBottomSheet` |
| `break_screen.dart` | Secondary "Log energy" after XP reveal (once) |
| `app_router.dart` | Route `/energy-checkin` for notification payload |
| `tasks_screen.dart` | Sort mode enum: default / match energy (A1.5) |
| `task_providers.dart` | Sort comparator using `latestEnergyProvider` |
| `dashboard_providers.dart` | Already uses `countToday()` — keep; ensure reactive invalidation |
| `weekly_review_screen.dart` | Pass real `energyCheckIns` per day into score calc (currently `0`) |

#### XP / achievements

- On successful log: `StreakService.recordActivity()` (energy is valid activity)
- On 3rd unique bucket today: `awardEnergyCheckin3xBonus()`
- `AchievementChecker.runCheck(db)` after bonus

#### Acceptance criteria

- [ ] User can log energy from Home in ≤3 taps
- [ ] Same bucket same day overwrites; different buckets stack (max 3/day)
- [ ] Third check-in awards +20 XP once
- [ ] Daily score ritual component changes with check-in count
- [ ] "Match energy" reorders task list correctly for high vs low energy
- [ ] Unit tests cover upsert + 3× bonus idempotency

---

### A2 — Unify streaks

#### Problem

Two definitions of "streak" exist:

| Source | Definition | Used by |
|--------|------------|---------|
| `StreakService` | Day counts if **any XP** earned; miss 1 → pause; miss 2 → reset | Achievements, XP multipliers, `xp_providers` |
| `dashboard_providers.streakProvider` | Days with `DailyPlans.intentionCompleted` | Home header fire badge |

Users see inconsistent numbers; grace-day rules are ignored on Home.

#### Decision (locked for Tier A)

**Canonical:** `StreakService` (effort-based + grace days). Matches product copy: "reward showing up," not only morning ritual.

Intention remains part of **Daily Score**, not streak identity.

#### Implementation steps

1. **Delete or rewrite** `streakProvider` in `dashboard_providers.dart` to:

   ```dart
   final streakProvider = FutureProvider<int>((ref) {
     return StreakService.getStreak();
   });
   ```

   Prefer **single** provider in `xp_providers.dart` and re-export / import from Home to avoid duplication.

2. **Home UI:** show pause state:

   ```dart
   final paused = ref.watch(streakPausedProvider).valueOrNull ?? false;
   // 🔥 12   or   ⏸️ 12 (paused)
   ```

3. **Call `StreakService.recordActivity()`** from every XP path that might miss it:
   - `TaskCompletionService` — already calls
   - `XpCalculator.awardSessionXP` / ritual / bounce-back / energy — **add** `recordActivity` in calculator or a thin `XpAwardFacade` so no path forgets

   Preferred pattern: wrap ledger append in one place that always records streak.

4. **On app open** (`main.dart` or first Home build): `StreakService.getStreak()` triggers `_checkAndUpdate` (already does on read).

5. **Weekly review** streak loop that walks `intentionCompleted` → replace with `StreakService.getStreak()` / `getBestStreak()` for summary cards; keep intention stats separate as "intention days this week."

6. **Tests:** expand `test/unit/streak_service_test.dart` (or create):

   | Case | Expected |
   |------|----------|
   | Activity today | streak ≥ 1 |
   | Activity yesterday only, open today morning | still holding / not reset |
   | Miss 1 full day | paused true, streak preserved |
   | Miss 2 consecutive | reset 0 |
   | Best streak updates | max tracked |

#### Files to touch

- `lib/features/dashboard/providers/dashboard_providers.dart`
- `lib/presentation/screens/home/home_screen.dart`
- `lib/features/xp/models/xp_calculator.dart` (and/or callers)
- `lib/presentation/screens/report/weekly_review_screen.dart`
- `lib/features/xp/models/streak_service.dart` (docs + any edge-case fixes)
- `test/unit/streak_service_test.dart` (new)

#### Acceptance criteria

- [ ] Home, Profile, achievements, XP multiplier all read same number
- [ ] Grace day shows paused UI, not zero
- [ ] No remaining intention-based streak math on Home
- [ ] Tests green for grace rules

---

### A3 — Real Insights + empty states

#### Problem

`InsightsDashboardScreen` uses hardcoded peaks and weekday scores. That trains users to distrust the product.

#### Product rules

1. **Never show fabricated series as live data.**
2. If sample history is insufficient, show **empty state** with progress ("3 / 7 days of focus data").
3. Minimum thresholds:

| Chart | Minimum data | Empty copy |
|-------|--------------|------------|
| Energy forecast | ≥ 7 days with ≥ 1 check-in each, or ≥ 14 check-ins total | "Log energy for a week to unlock your peak windows." |
| Daily score by weekday | ≥ 7 scored days (or ≥ 5 with intention/focus) | "Keep using FlowOS for a week to see weekday patterns." |
| Focus quality by hour | ≥ 10 completed sessions | "Complete more focus sessions to map your best hours." |
| Scroll vs focus (7 days) | Always computable if any logs; else empty | "Log focus or scroll to see attention trends." |
| Task funnel | Always from task table | Show zeros honestly |

#### Implementation design

**New providers** (recommended file):

`lib/features/insights/providers/insights_providers.dart`

| Provider | Computation |
|----------|-------------|
| `weekdayScoresProvider` | Last 8–12 weeks optional later; v1: last 28 days, average score per weekday |
| `hourlyFocusHeatmapProvider` | Sessions bucketed by `startedAt.hour`, average quality or total minutes |
| `scrollVsFocusWeekProvider` | Last 7 days: focus minutes + scroll minutes per day |
| `energyForecastProvider` | Average energy by morning/afternoon/evening; map high averages to "windows" |
| `taskFunnelProvider` | created (all non-deleted) / started (sessions with taskId) / completed |

**Score recompute helper:** share logic with weekly review (extract):

`lib/features/insights/services/history_aggregator.dart`

```text
for each day in range:
  focusMinutes, mitsCompleted, scroll, plan flags, energyCount
  → DailyScoreCalculator.calculate(...)
```

Use for weekly review (already partial) and insights.

#### UI changes

File: `lib/presentation/screens/insights/insights_dashboard_screen.dart`

- Convert to data-driven `ConsumerWidget` / stateful with `AsyncValue` handling
- Loading: shimmer or skeleton cards
- Empty: `_EmptyInsightCard(message, progress?)`
- Populated: existing chart widgets fed real lists
- Footer: "Based on local data only · private"

#### Acceptance criteria

- [ ] Fresh install → all insight cards empty, not fake numbers
- [ ] After seed / dogfood data → charts match DAO aggregates (±1 rounding)
- [ ] Energy forecast uses A1 check-ins only
- [ ] No hardcoded `[65, 72, 80, ...]` left in insights file

---

### A4 — First-run + daily intention gate

#### Problem

`initialLocation: '/home'` skips onboarding. New users land in an empty command center with no mental model. Returning users are never nudged to set MITs.

#### Product behavior

**First launch**

```text
/onboarding → /auth (optional offline) → /home
```

- Flag: `SharedPreferences['flowos_onboarding_complete'] = true` on finish/skip from last page
- Onboarding "Get started" already goes to `/auth`; set flag there and on "Use offline"

**Cold start router redirect** (GoRouter `redirect`):

```text
if !onboardingComplete → /onboarding
else if !hasTodayPlan && hour < 12 && !dismissedIntentionToday → /morning-intention (optional soft)
else → requested route
```

**Daily intention gate (soft, not hard-block):**

| Mode | Behavior |
|------|----------|
| Soft (recommended v1) | Home shows sticky banner: "Set today's intention" → `/morning-intention` |
| Hard (optional flag) | Redirect before Home until plan exists (can frustrate power users) |

Tier A ships **soft banner + first-run hard gate only**.

**Dismiss:** banner can be dismissed for today (`prefs flowos_intention_banner_dismissed_yyyy-mm-dd`).

#### Files

| File | Change |
|------|--------|
| `app_router.dart` | `redirect` + read prefs (async redirect pattern or bootstrap flag loaded in `main`) |
| `main.dart` | Load bootstrap flags before `runApp` into a simple `AppBootstrap` / Riverpod override |
| `onboarding_screen.dart` | Persist completion |
| `auth_screen.dart` | Offline path also sets onboarding complete if needed |
| `home_screen.dart` | Intention banner when `todayPlanProvider` is null |

#### Bootstrap pattern (avoid async redirect races)

```dart
// main.dart
final prefs = await SharedPreferences.getInstance();
final onboardingDone = prefs.getBool('flowos_onboarding_complete') ?? false;

runApp(ProviderScope(
  overrides: [
    onboardingCompleteProvider.overrideWithValue(onboardingDone),
  ],
  child: FlowOSApp(),
));
```

Initial location: `onboardingDone ? '/home' : '/onboarding'`.

#### Acceptance criteria

- [ ] Fresh install always sees onboarding first
- [ ] Completing/skipping never re-shows onboarding
- [ ] Home shows intention CTA when no plan for today
- [ ] Existing installs: migration sets onboarding complete if any DailyPlan or XP exists (avoid re-onboarding dogfooders)

---

### A5 — Notification lifecycle

#### Problem

`NotificationService` is complete (channels, energy, report, weekly, streak) but **never initialized**. Settings toggles schedule energy only when flipped in-session and prefs may not persist (A9).

#### Implementation

**`main.dart` (after binding init):**

```dart
await NotificationService.initialize();
// Permissions: request on first settings enable or after onboarding page 3
```

**Permission strategy**

- iOS/Android: do **not** spam permission on first frame.
- After onboarding complete OR first energy log OR Settings "Enable reminders" → request permission then schedule.

**Default schedule after permission granted**

| ID range | Notification | When |
|----------|--------------|------|
| 100–102 | Energy check-ins | 9:00 / 13:00 / 17:00 |
| 200 | Daily report | 21:00 |
| 201 | Weekly review | Sunday 20:00 |
| 300 | Streak warning | 20:00 (only useful if activity check; see note) |

**Streak warning note:** current API always schedules a daily 8 PM message. Improve to:

- Schedule generic reminder, **or**
- On app open evening, if `!activityToday` show local notif once (Tier A: keep scheduled body soft: "Log a few minutes of focus if you want to keep momentum" — avoid false "at risk" if grace day).

**Deep links / payload**

Wire `onDidReceiveNotificationResponse`:

| Payload | Navigate |
|---------|----------|
| `energy` | `/energy-checkin` |
| `report` | `/daily-report` |
| `weekly` | `/weekly-review` |
| `streak` | `/focus` |
| `intention` | `/morning-intention` |

Use `appRouter.go(...)` via a global navigator key or `GoRouter` instance already exported.

**Settings**

- Energy reminders toggle → schedule / cancel 100–102
- Report reminder toggle (add if missing)
- Persist via A9

#### Files

- `lib/main.dart`
- `lib/features/notifications/services/notification_service.dart` (payload handlers, cancel helpers)
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/presentation/navigation/app_router.dart` (navigatorKey if needed)

#### Acceptance criteria

- [ ] After enabling reminders + granting permission, energy notif fires at next scheduled slot (test with short-offset debug method)
- [ ] Tap energy notif opens check-in sheet/route
- [ ] Disable toggle cancels scheduled ids
- [ ] App does not crash if permissions denied

---

### A6 — Theme applied end-to-end

#### Problem

`themeProvider` persists selection; Settings picker works; `MaterialApp` always uses `AppTheme.dark`. Unlockable themes never change UI.

#### Implementation

1. Convert `FlowOSApp` to `ConsumerWidget` (already under `ProviderScope`).

2. Map `FlowTheme` → `ThemeData`:

   File: `lib/core/theme/app_theme.dart`

   ```dart
   static ThemeData fromFlowTheme(FlowTheme t) {
     // Clone dark ThemeData but override:
     // scaffoldBackgroundColor, colorScheme.primary, card colors, etc.
     // from t.background0..3 and t.accent*
   }
   ```

3. Bridge tokens used by screens:

   Many screens import `AppColors` statics, **not** `Theme.of(context)`. Full migration is large.

   **Tier A pragmatic approach:**

   | Approach | Pros | Cons |
   |----------|------|------|
   | A. Only ThemeData | Correct long-term | Most screens ignore theme |
   | B. Make `AppColors` reactive via InheritedWidget / provider | Fast visual win | Slightly unconventional |
   | C. Hybrid: ThemeData + `AppColors.overrideFrom(FlowTheme)` on change | Ship-able | Need careful reset |

   **Choose C for Tier A:**

   - On theme change: `AppColors.applyTheme(flowTheme)` mutates (or better: `ref.watch(themeProvider)` and pass colors through a thin `FlowColors` provider).
   - Prefer **immutable provider**:

   ```dart
   final flowColorsProvider = Provider((ref) {
     final t = ref.watch(themeProvider);
     return FlowColorScheme.from(t);
   });
   ```

   Migrating every screen is too big for Tier A. Minimum:

   - `MaterialApp.theme = AppTheme.fromFlowTheme(t)`
   - Shell bottom nav + Home header accent use `Theme.of(context).colorScheme.primary`
   - Document follow-up: replace static `AppColors.emerald` gradually

4. **Level lock:** Settings already has unlock checks; ensure locked themes cannot apply.

5. **System UI:** update `SystemChrome` nav bar color when theme changes.

#### Files

- `lib/main.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart` (optional scheme helper)
- `lib/features/themes/models/flow_theme.dart` (already has notifier)
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/presentation/navigation/app_router.dart` (shell colors)

#### Acceptance criteria

- [ ] Selecting Deep Space changes accent + backgrounds on shell and new screens
- [ ] Theme survives restart
- [ ] Locked theme cannot be selected below unlock level
- [ ] Default theme matches current Midnight Emerald

---

### A7 — Offline brain-dump fallback

#### Problem

Offline (or AI down): user sees failure snackbar and empty result. Local-first promise breaks on a flagship feature.

#### Behavior

```text
Try AiService.processBrainDump
  → success: show AI tasks (badge: "Sorted by AI")
  → null/error: run LocalBrainDumpParser
       → show tasks (badge: "Local sort · AI offline")
       → never leave user with zero structure if text has lines
```

#### Local parser rules (`lib/features/ai/services/local_brain_dump_parser.dart`)

1. Split on newlines / `;` / `•` / numbered lists.
2. Trim; drop empty; max 10 items; title ≤ 60 chars (truncate).
3. Heuristic energy:

   | Keywords (case-insensitive) | Energy |
   |-----------------------------|--------|
   | deep, design, write, code, study, research, plan, architecture | deep |
   | email, call, message, schedule, pay, buy, clean, admin | light |
   | default | medium |

4. Friction: longer titles / "maybe" / "should" / "figure out" → higher friction (0.2–0.8).
5. Order: if current energy ≤ 2 → light first; if ≥ 4 → deep first; else keep input order.
6. `estimated_minutes`: default 25; if contains `\d+\s*m` parse; clamp 5–480.

#### UI

- Banner on results: local vs AI
- Snackbar only if **both** AI fails **and** parse yields 0 tasks (e.g. single word noise)

#### Files

- `lib/features/ai/services/local_brain_dump_parser.dart`
- `lib/presentation/screens/brain_dump/brain_dump_screen.dart`
- `test/unit/local_brain_dump_parser_test.dart`

#### Acceptance criteria

- [ ] Airplane mode: multi-line dump produces tasks
- [ ] Accept still inserts into Drift (already wired path)
- [ ] Online AI path unchanged when backend works
- [ ] Parser unit tests cover split, keywords, energy ordering

---

### A8 — Data export (JSON/CSV)

#### Problem

Privacy policy and trust require user-owned data. No export path.

#### Product

Settings → **Export my data**

- Formats: **JSON** (full fidelity) + **CSV zip or multi-share** (tasks, sessions, xp)
- Share via `share_plus` (already in pubspec)
- Exclude auth tokens; include schema version

#### JSON schema (v1)

```json
{
  "export_version": 1,
  "exported_at": "ISO-8601",
  "app_version": "0.1.0",
  "tasks": [ ... ],
  "focus_sessions": [ ... ],
  "xp_ledger": [ ... ],
  "scroll_logs": [ ... ],
  "energy_checkins": [ ... ],
  "daily_plans": [ ... ],
  "daily_reports": [ ... ],
  "achievements": [ ... ]
}
```

#### Implementation

| File | Role |
|------|------|
| `lib/features/export/services/data_export_service.dart` | Query all DAOs → encode |
| `lib/presentation/screens/settings/settings_screen.dart` | Action tile + progress indicator |

CSV: one file per table joined with `\n\n` or share JSON only in Tier A if zip is heavy — **JSON is mandatory; CSV tasks+sessions optional stretch**.

#### Privacy

- Confirm sheet: "Export includes task titles and activity history. Share only with apps you trust."
- No automatic upload

#### Acceptance criteria

- [ ] Export produces non-empty JSON with current tasks after creating one
- [ ] Share sheet opens on iOS/Android
- [ ] No Supabase keys in file
- [ ] Works fully offline

---

### A9 — Settings persistence + polish

#### Problem

Settings local state (`_scrollBudget`, `_soundEnabled`, `_autoSync`, reminder toggles) resets on restart. Theme already persists; others do not.

#### Keys

| Key | Type | Default |
|-----|------|---------|
| `flowos_scroll_budget` | int | 30 |
| `flowos_ambient_sounds` | bool | true |
| `flowos_auto_sync` | bool | true |
| `flowos_energy_reminders` | bool | true |
| `flowos_report_reminder` | bool | true |
| `flowos_streak_reminder` | bool | true |
| `selected_theme` | string | already |

#### Implementation

- `lib/features/settings/providers/settings_providers.dart` — `SettingsNotifier extends StateNotifier`
- Load in constructor; save on each change
- Scroll budget: also update **today's plan** if exists (`dailyPlansDao`) so Home attention budget matches
- Ambient: focus screens read `settingsProvider.soundEnabled` before `AmbientSoundPlayer.play`
- Auto sync: `SyncEngine` mutation debounce checks flag

#### Light theme TODO

Leave `AppTheme.light` as future; unlockable themes cover variety without full light mode.

#### Acceptance criteria

- [ ] Kill app → reopen → all toggles restored
- [ ] Scroll budget reflects on Home attention card
- [ ] Sound disabled → no ambient audio on focus start

---

## 5. Tier A execution schedule

### Week 1 — Core honesty & habit

| Day | Work | Deliverable |
|-----|------|-------------|
| 1 | A1 energy service + sheet + Home chip | Log energy E2E |
| 1–2 | A1.5 match-energy sort + weekly score energy | Differentiator live |
| 2 | A2 streak unification + tests | One streak number |
| 3 | A4 first-run + intention banner | Onboarding gate |
| 3–4 | A5 notifications init + payloads | Reminders work |
| 4 | A9 settings persistence (partial with A5) | Toggles stick |

### Week 2 — Trust & polish

| Day | Work | Deliverable |
|-----|------|-------------|
| 5 | A3 insights aggregator + empty states | Honest charts |
| 6 | A7 offline brain dump + tests | Offline useful |
| 6 | A8 data export | Settings export |
| 7 | A6 theme application + shell | Visual unlock works |
| 7 | Regression, analyzer, dogfood script | Tier A done |

### Parallelization notes

- A2, A8 independent of A1
- A3 energy forecast needs A1 data (can stub empty first)
- A6 independent
- A5 depends on A1 route for best UX

---

## 6. Tier A verification checklist

### Automated

```bash
cd flowos
flutter analyze
flutter test
```

Add/ensure tests:

- [ ] `energy_checkin_service_test.dart`
- [ ] `streak_service_test.dart`
- [ ] `local_brain_dump_parser_test.dart`
- [ ] `history_aggregator_test.dart` (score averages)
- [ ] `data_export_service_test.dart` (in-memory DB)

### Manual dogfood (14-day ready script, min 1 day)

- [ ] Fresh install → onboarding → offline continue → Home
- [ ] Set intention → 3 MITs → start Pomodoro → complete → XP + streak
- [ ] Log energy morning/afternoon/evening → +20 XP
- [ ] Match energy sort changes order
- [ ] Airplane mode brain dump → local tasks → accept → Tasks list
- [ ] Insights empty → after sessions, charts populate
- [ ] Change theme → survives restart
- [ ] Export JSON → open on device
- [ ] Enable energy reminder → tap notif → sheet
- [ ] Home streak matches Profile

### Store listing honesty gate

Before public listing, remove or mark "Coming soon" for:

- Flow Garden (unless Tier B done)
- Home widgets (unless Tier B done)
- Claims of automatic phone scroll tracking
- Any AI feature that fails closed without fallback

---

## 7. Future feature additions — Tier B

> **Target window:** v1.1–v1.2 after Tier A dogfood (2–6 weeks post-internal launch).
> **Theme:** deepen the OS feel without diluting the personal, non-guilt ethos.

### B1 — Flow Garden (minimal viable metaphor)

**Pitch:** Visual growth from focus minutes — calm gamification, not leaderboard energy.

| Spec item | Detail |
|-----------|--------|
| **Concept** | A single plant/garden scene; growth stages from lifetime or weekly focus minutes |
| **Stages** | Seed → Sprout → Sapling → Tree → Grove (map to XP tiers or focus hours) |
| **Data** | Derive from `FocusSessions` sum; optional water from bounce-back recovery actions |
| **UI** | New tab or Profile section; Rive/Lottie **or** pure Flutter CustomPainter (prefer Flutter first to avoid empty asset trap) |
| **Non-goals** | Social gardens, PvP, pay-to-skip wilt |
| **Wilt rules** | Optional soft "dry" visual after 3 idle days — **never** delete XP or punish score |
| **Files (planned)** | `lib/features/flow_garden/models/garden_state.dart`, `widgets/garden_view.dart`, provider from sessions |
| **Effort** | 3–5 days |
| **Depends on** | Stable focus session logging (done) |

### B2 — OS Focus / DND during Deep Work

**Pitch:** Starting Deep Work flips system focus; ending restores previous state.

| Platform | Approach |
|----------|----------|
| **iOS** | App Intents / Focus Filter if available; else guide user to enable Focus; Screen Time API limited |
| **Android** | `NotificationManager` DND policy access (special permission); fallback: silent mode + persistent notif |
| **In-app** | Toggle "Protect this session" on Deep Work start; auto-off on complete/cancel |
| **Privacy** | No reading other apps' content |
| **Effort** | 3–4 days + platform QA |
| **Risk** | Permission UX friction; document in onboarding |

### B3 — Calendar block for Deep Work

**Pitch:** Optional "Block 90 min on calendar" when scheduling Deep Work.

| Spec | Detail |
|------|--------|
| **Providers** | device_calendar / native EventKit & CalendarContract |
| **Flow** | Deep Work setup → "Add to calendar" → create event titled "FlowOS Deep Work" |
| **Permissions** | Calendar read/write; deny = skip silently |
| **Sync** | One-way create; no two-way task sync in B3 |
| **Effort** | 2–3 days |

### B4 — Recurring tasks that actually recur

**Pitch:** Complete a daily/weekly task → next occurrence appears.

| Spec | Detail |
|------|--------|
| **Model** | Existing `recurrenceRule` enum on tasks + optional `RecurrenceRule` model |
| **On complete** | `TaskCompletionService` clones incomplete child with next `dueDate` / sortOrder |
| **Rules** | daily, weekdays, weekly, monthly (enum already exists) |
| **MIT interaction** | Recurring task can be MIT only for the instance day |
| **UI** | Create/edit task: recurrence picker |
| **Effort** | 2–3 days |
| **Tests** | Next date calculation edge cases (month end, weekdays) |

### B5 — iOS / Android home widgets

**Pitch:** Glanceable Flow Score, next MIT, start focus.

| Spec | Detail |
|------|--------|
| **iOS** | WidgetKit extension; App Group shared `UserDefaults` via `home_widget` |
| **Android** | Glance or XML widget; same package |
| **Data already pushed** | `home_widget_provider.dart` — complete native side |
| **Sizes** | Small: score + streak; Medium: + MIT titles; Large: + attention budget |
| **Tap** | Deep link `flowos://focus`, `flowos://intention` |
| **Update** | On app resume + after XP events |
| **Effort** | 4–6 days (native) |
| **Depends on** | A2 streak truth, Home data stability |

### B6 — Extension ↔ app attention merge

**Pitch:** Chrome distraction minutes feed mobile attention budget / scroll cost.

| Spec | Detail |
|------|--------|
| **Transport** | Supabase table already partially used by extension; align schemas with `scroll_logs` or `extension_visits` |
| **Auth** | Same user id in extension options (setup docs) |
| **Mobile** | Daily report includes "Desktop attention cost"; optional auto-fill scroll tracker |
| **Conflict** | Manual mobile log + extension: sum with source tags, don't double-penalize same hour without rules |
| **Privacy** | Domain categories, not full URLs in mobile UI by default |
| **Effort** | 3–5 days |
| **Depends on** | Deployed Supabase + extension auth |

### B7 — Custom ambient audio import

**Pitch:** User picks local audio file as focus loop.

| Spec | Detail |
|------|--------|
| **API** | file_picker + copy into app documents; register key in player map |
| **Limits** | Max 3 custom tracks; size cap e.g. 20 MB |
| **Loop** | Existing `AmbientSoundPlayer` loop mode |
| **Effort** | 1–2 days |

### B8 — Pomodoro variants (DeskTime, Flowtime, custom)

**Pitch:** Power-user timers beyond 25/90.

| Mode | Work | Break |
|------|------|-------|
| Classic | 25 | 5 |
| DeskTime | 52 | 17 |
| Deep Work | 90 | 15 |
| Flowtime | open-ended until user stops | optional |
| Custom | user mm | user mm |

| Spec | Detail |
|------|--------|
| **XP** | Scale with actual minutes (already partial via custom session type) |
| **UI** | Focus screen mode chips |
| **Effort** | 1–2 days |

### B9 — "Work with my energy" v2 (auto-suggest MIT)

**Pitch:** Beyond sort — morning intention suggests 3 MIT candidates from backlog using energy + friction + due date.

| Spec | Detail |
|------|--------|
| **Algorithm** | Score = f(energy match, low friction when energy low, due soon, incomplete age) |
| **UI** | "Suggested MITs" on morning intention |
| **AI optional** | Local first; AI later for rationale |
| **Depends on** | A1 energy history |
| **Effort** | 2–3 days |

### B10 — Break content cache & wellbeing mini-kit

**Pitch:** Fill empty `wellbeing/` with offline-first breathing, stretch, short walks (recovery actions already partially exist).

| Spec | Detail |
|------|--------|
| **Content pack** | 10 breathing scripts, 10 stretches, 10 riddles offline |
| **AI** | Enhances when online; cache last N |
| **Effort** | 2 days |

### B11 — Polish & architecture follow-ups (engineering)

| Item | Why |
|------|-----|
| Repository layer for tasks/sessions | Testability + sync isolation |
| Plan-scoped MITs (`mit_1_id`…) | Cleaner than `isMIT` flag |
| Daily reports in `SyncEngine` | Multi-device reflection history |
| `AttentionCosts` DAO or drop table | Schema honesty |
| Crash reporting opt-in | Production readiness |
| Replace static `AppColors` with theme scheme | Finish A6 properly |
| Integration test: full day loop | Prevent regressions |

---

## 8. Future feature additions — Tier C

> **Target window:** v0.5+ / post product-market fit.
> **Rule:** Do not start until Tier A is dogfooded and Tier B widgets/garden/OS hooks have validated retention.
> **Ethic:** No social guilt, no data resale, no dark patterns.

### C1 — Screen Time / Digital Wellbeing auto scroll

| Spec | Detail |
|------|--------|
| **iOS** | FamilyControls / DeviceActivity (entitlements, Apple approval friction) |
| **Android** | UsageStatsManager (special access settings) |
| **UX** | Explicit opt-in; show "FlowOS will read app usage to estimate attention cost" |
| **Output** | Auto daily scroll estimate; user can adjust |
| **Risk** | High rejection / permission drop-off; maintain manual path forever |
| **Effort** | 2–4 weeks including review |

### C2 — Apple Watch / Wear OS companion

| Spec | Detail |
|------|--------|
| **Watch surfaces** | Energy 1–5, active timer remaining, MIT checklist (2 items), complication score |
| **Sync** | WatchConnectivity / Wear Data Layer → phone Drift |
| **Offline** | Queue check-ins on watch |
| **Effort** | 3–6 weeks |
| **Why later** | Native dual-platform cost; Tier A energy UI must exist first |

### C3 — AI energy prediction & auto-schedule

| Spec | Detail |
|------|--------|
| **Input** | ≥14 days energy + session quality by hour |
| **Output** | "Tomorrow 9–11 is deep work; schedule MIT-1" |
| **Model** | Start rule-based; optional on-device or Gemini batch weekly |
| **UI** | Insights card + optional calendar blocks (B3) |
| **Guardrail** | Suggestions only; never auto-force tasks |
| **Effort** | 2–3 weeks |
| **Depends on** | A1, A3, enough history |

### C4 — Accountability partners (non-leaderboard)

| Spec | Detail |
|------|--------|
| **Model** | Pair invite code; share **streak alive?** and weekly focus hours only — not raw scroll shaming |
| **Opt-in** | Both parties; revoke anytime |
| **Non-goals** | Global leaderboards, public profiles, rank anxiety |
| **Effort** | 3–4 weeks + backend |
| **Risk** | Can become guiltware if poorly designed — design review required |

### C5 — Team / multiplayer workspaces

| Spec | Detail |
|------|--------|
| **Use case** | Small studio: shared deep work hours, not micromanagement |
| **Data** | Aggregate focus minutes; no keystroke surveillance |
| **Effort** | Large (auth roles, orgs) — treat as separate product line |

### C6 — Marketplace (rituals, sound packs, themes)

| Spec | Detail |
|------|--------|
| **Monetization** | Optional packs; core loop free forever |
| **Content** | Community breathing scripts, ambient packs, theme skins |
| **Effort** | Store + moderation + payments — post-revenue validation |

### C7 — Full second-brain / notes graph

| Spec | Detail |
|------|--------|
| **Risk** | Scope explosion vs Notion/Obsidian |
| **Allowed thin wedge** | Session notes attached to focus sessions (small) |
| **Avoid** | Full PKM until FlowOS wins on energy+focus |

### C8 — Cross-platform desktop app

| Spec | Detail |
|------|--------|
| **Stack** | Flutter desktop or separate |
| **Synergy** | Extension + desktop timer |
| **Effort** | High; prioritize extension merge (B6) first |

### C9 — Therapist / coach export mode

| Spec | Detail |
|------|--------|
| **Pitch** | Privacy-preserving weekly PDF for coaches |
| **Data** | Scores, focus hours, energy curves — user-approved |
| **Effort** | 1–2 weeks |
| **Fits** | Wellness positioning without social feed |

### C10 — Explicitly rejected (do not build)

| Idea | Why rejected |
|------|----------------|
| Public XP leaderboards | Guiltware / against ethos |
| Streak freezes as IAP | Pay-to-avoid-honesty |
| Infinite scroll gamification | Hypocritical |
| Reading user message content | Privacy |
| Punitive lockout ("can't use phone") | Toxic; OS Focus optional only |
| Ads | Breaks trust |

---

## 9. Dependency graph

```text
                    ┌─────────────┐
                    │  A4 First-run │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐     ┌──────────┐      ┌──────────┐
   │ A1 Energy │────▶│ A3 Insights│      │ A5 Notifs │
   └────┬─────┘     └──────────┘      └────┬─────┘
        │                                   │
        ├──────────▶ A7 Brain dump          │
        │                                   ▼
        │                            ┌──────────┐
        │                            │ A9 Settings│
        │                            └──────────┘
   ┌──────────┐     ┌──────────┐      ┌──────────┐
   │ A2 Streak │     │ A8 Export │      │ A6 Themes │
   └──────────┘     └──────────┘      └──────────┘

Tier B (after A):
  A1 ──▶ B9 energy suggest
  focus data ──▶ B1 Garden
  A2 + Home ──▶ B5 Widgets
  Supabase ──▶ B6 Extension merge
  Deep Work ──▶ B2 DND, B3 Calendar

Tier C (after B validated):
  A1+A3 history ──▶ C3 predictions
  C1 Screen Time optional upgrade path from manual scroll
  B5 ──▶ C2 Watch complications
```

---

## 10. Risks & decisions

| Risk | Mitigation |
|------|------------|
| Theme still looks static on old screens | A6 hybrid + backlog replace `AppColors` |
| Notification permission denied | Soft banner in Settings; app fully usable offline |
| Streak change confuses existing dogfooders | Changelog: "Streak now tracks any productive day (XP), with 1 grace day" |
| Insights empty for first week | Empty states are intentional; seed optional demo data **behind debug flag only** |
| Scope creep into Garden/Widgets | Parked in Tier B; strip store claims |
| Local brain dump quality poor | Label clearly; AI path preferred when online |
| Export shares sensitive titles | Confirm dialog |

### Open decisions (resolve during A1–A2)

1. Soft vs hard intention gate → **default soft**
2. Energy note field → **defer schema change**
3. Streak definition → **locked: XP activity + grace**
4. Theme migration depth → **shell + ThemeData first**

---

## Appendix A — File change map (Tier A)

| Feature | Primary files |
|---------|----------------|
| A1 | `energy_checkins_dao.dart`, `energy_checkin_sheet.dart`, `energy_providers.dart`, `energy_checkin_service.dart`, `home_screen.dart`, `tasks_screen.dart`, `app_router.dart`, `weekly_review_screen.dart` |
| A2 | `dashboard_providers.dart`, `home_screen.dart`, `xp_calculator.dart`, `streak_service.dart`, tests |
| A3 | `insights_dashboard_screen.dart`, `history_aggregator.dart`, `insights_providers.dart` |
| A4 | `main.dart`, `app_router.dart`, `onboarding_screen.dart`, `home_screen.dart` |
| A5 | `main.dart`, `notification_service.dart`, `settings_screen.dart` |
| A6 | `main.dart`, `app_theme.dart`, `flow_theme.dart`, shell |
| A7 | `local_brain_dump_parser.dart`, `brain_dump_screen.dart`, tests |
| A8 | `data_export_service.dart`, `settings_screen.dart` |
| A9 | `settings_providers.dart`, `settings_screen.dart`, focus screens, sync |

---

## Appendix B — Definition of done (Tier A complete)

Tier A is **done** when:

1. A new user can understand and complete one full day: intention → energy ×3 → focus → shutdown → report without fake data.
2. Streak, score, and XP never contradict each other on Home vs Profile.
3. Airplane mode still supports tasks, focus, XP, energy, local brain dump, export.
4. `flutter analyze` clean; new unit tests pass.
5. Store listing text matches shipped reality.

**Next after DoD:** 14-day personal dogfood → cherry-pick Tier B (widgets + garden + DND) by retention need.

---

*Built with intention. Ship honesty first.*

# FlowOS — Engagement Wiring & Product Completion Plan

> **Status:** Ready to execute  
> **Created:** 2026-07-14  
> **Scope:** Wire half-built engines into UI, fix trust/soul gaps, then platform depth  
> **Companion docs:** `TIER_A_IMPLEMENTATION_PLAN.md`, `implementation_plan.md`, session plan for four engagement features  

---

## Table of contents

1. [Context & principles](#1-context--principles)
2. [Current baseline](#2-current-baseline)
3. [Goals & non-goals](#3-goals--non-goals)
4. [Phase P0 — Wire unfinished engines](#4-phase-p0--wire-unfinished-engines)
5. [Phase P1 — Soul of daily use](#5-phase-p1--soul-of-daily-use)
6. [Phase P2 — Honesty & polish](#6-phase-p2--honesty--polish)
7. [Phase P3 — Platform depth](#7-phase-p3--platform-depth)
8. [Feature additions roadmap](#8-feature-additions-roadmap)
9. [Execution schedule](#9-execution-schedule)
10. [Dependency graph](#10-dependency-graph)
11. [Verification](#11-verification)
12. [Risks & locked decisions](#12-risks--locked-decisions)
13. [Definition of done](#13-definition-of-done)

---

## 1. Context & principles

### Why this plan exists

FlowOS has a solid offline core and honest focus sessions (`FocusSessionService`). First-win onboarding and several “engagement engines” exist as code:

| Engine / feature | Location | User-facing today? |
|------------------|----------|--------------------|
| Focus integrity | `lib/features/focus/services/focus_session_service.dart` | **Yes** |
| First-win onboarding | `lib/presentation/screens/onboarding/onboarding_screen.dart` | **Yes** |
| Scroll intent sheet | `lib/features/attention/widgets/scroll_intent_sheet.dart` | **No** |
| Intentional rest | `lib/presentation/screens/rest/intentional_rest_screen.dart` | **No path from scroll** |
| Rhythm engine | `lib/features/rhythm/services/rhythm_engine.dart` | **No** |
| Weekly action engine | `lib/features/reports/services/weekly_action_engine.dart` | **No** |
| User profile store | `lib/features/onboarding/services/user_profile_store.dart` | Partial (onboarding only) |

**Principle:** Stop adding new feature folders until Home, Scroll, Insights, and Weekly **call the engines already written**.

### Product rule of thumb

```text
Onboarding → Seed session → Living Home → Honest attention → One weekly change
```

Every phase below closes one missing arrow.

---

## 2. Current baseline

### Confirmed strengths (do not regress)

- Offline Drift: tasks, sessions, XP ledger, plans, scroll logs  
- Focus min duration + partial XP + double-complete guard  
- Break exit uses `context.go` (not `Navigator.pop` after `go`)  
- Pomodoro ambient audio via `AmbientSoundPlayer`  
- Onboarding 5-step wizard → 10m first seed; `main.dart` bootstrap  

### Confirmed flaws (this plan fixes)

| ID | Flaw | Severity |
|----|------|----------|
| F-A | Scroll starts timer with no intent gate | P0 |
| F-B | RhythmEngine unused; Insights show fake peaks | P0 |
| F-C | WeeklyActionEngine unused; report ends with Done only | P0 |
| F-D | Dual streak (Home plans vs `StreakService`) | P0 |
| F-E | Brain Dump / Roulette buttons are no-ops | P0 |
| F-F | Profile (window, firm/gentle, distractions) unused on Home/Scroll | P0–P1 |
| F-G | No energy check-in UI | P1 |
| F-H | Home has no contextual primary CTA | P1 |
| F-I | Notifications never initialized | P1 |
| F-J | Settings toggles often not persisted | P1–P2 |
| F-K | Themes not applied to live `MaterialApp` | P2 |
| F-L | Offline brain dump weak; no local parser | P2 |
| F-M | Empty Flow Garden / store overclaims | P2–P3 |
| F-N | No OS/extension doomscroll auto-track | P3 |

---

## 3. Goals & non-goals

### Goals

1. Every distraction open is **preceded by intent** (or intentional rest).  
2. Users with enough history see **one evidence-based rhythm rec** they can **accept as a session**.  
3. Weekly (and daily) reports end with **one concrete action**.  
4. **One streak number** everywhere.  
5. Home feels alive: profile-aware banner, next action, optional energy.  
6. No fake charts.  
7. Notifications and settings work after restart.  

### Non-goals (this plan)

- Full OS app blocking (Screen Time / DND as default)  
- Social leaderboards / multiplayer  
- Full second-brain notes product  
- Complete domain-layer rewrite  
- iOS FamilyControls (defer to P3 research only)  

---

## 4. Phase P0 — Wire unfinished engines

**Goal:** Scaffold becomes product.  
**Estimate:** 2–4 focused days  
**Rule:** Prefer integrating existing files over new abstractions.

---

### P0.1 — Mindful scroll interruption (wire F3)

#### Problem

`scroll_tracker_screen.dart` calls `_toggleApp` → starts timer immediately.  
`showScrollIntentSheet` exists but is never called.  
`/intentional-rest` is registered in `createAppRouter` but unreachable from scroll.

#### Precise steps

1. **Open** `lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart`.

2. **Add imports:**
   - `../../../features/attention/widgets/scroll_intent_sheet.dart`
   - `../../../features/attention/models/scroll_intent.dart`
   - `../../../features/onboarding/providers/onboarding_providers.dart`
   - `../../../features/onboarding/models/user_profile.dart`
   - `package:go_router/go_router.dart` (if missing)

3. **State:** add `ScrollIntent? _activeIntent` and optional `String? _activeApp` already exists.

4. **Replace `_toggleApp` start branch** with async gate:

   ```text
   IF stopping active app → log as today (include intent if stored)
   ELSE (starting):
     a. Load profile from ref.read(userProfileProvider).valueOrNull
        or await UserProfileStore().load()
     b. Determine requireIntent:
        - firm mode → true for all apps + quick log
        - gentle → true only if appName is in profile.distractions
          (map "YouTube" / "Twitter/X" carefully to grid names)
     c. IF requireIntent:
          intent = await showScrollIntentSheet(context, appName: appName, firm: isFirm)
          IF intent == null → return (cancelled)
          IF intent == ScrollIntent.rest:
             context.push('/intentional-rest', extra: { minutes: 10 })
             return (do NOT start scroll timer)
          IF intent == ScrollIntent.avoiding:
             show micro dialog:
               "Want a 2-min breath or a tiny focus instead?"
               [Continue to scroll] [Go to Focus]
               Focus → context.go('/focus'); return
          store _activeIntent = intent
     d. Start timer as today
   ```

5. **Logging:** when inserting `ScrollLogsCompanion`, encode intent without schema migration for v1:

   ```dart
   recoveryActionType: Value(
     _activeIntent != null ? 'intent:${_activeIntent!.id}' : null,
   ),
   ```

   Document in code comment that this is intentional until Drift migration.

6. **Quick log:** call the same intent gate before `_logScroll('Quick Log', ...)`.

7. **Firm timebox (minimal):** if firm and intent is `scrolling` or `lookup`, after 10 minutes of active timer, stop + log + recovery sheet (Timer check each tick or separate Timer).

8. **UI copy:** change subtitle under app grid to:  
   `"Choose why first. Rest opens intentional rest — not a scroll log."`

#### Files

| File | Action |
|------|--------|
| `lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart` | Gate start/quick log |
| `lib/features/attention/widgets/scroll_intent_sheet.dart` | Reuse as-is |
| `lib/presentation/screens/rest/intentional_rest_screen.dart` | Reuse as-is |
| `lib/presentation/navigation/app_router.dart` | Confirm `/intentional-rest` route (already present) |

#### Acceptance criteria

- [ ] Tap Instagram → intent sheet before timer  
- [ ] Choose Rest → rest screen; no new scroll log with positive minutes  
- [ ] Cancel intent → no timer  
- [ ] Gentle: non-listed “Other” may skip intent if product chooses; firm: always intent  
- [ ] Log row stores `intent:*` in `recoveryActionType` until proper column exists  

---

### P0.2 — Adaptive rhythm on Home + kill fake Insights (wire F2)

#### Problem

`RhythmEngine.analyze` is pure and testable but unused.  
Insights still hardcodes peak windows.

#### Precise steps

##### A. Provider

Create `lib/features/rhythm/providers/rhythm_providers.dart`:

```dart
final rhythmRecommendationProvider = FutureProvider<RhythmRecommendation?>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 28));
  final sessions = await db.focusSessionsDao.getByDateRange(start, now.add(const Duration(days: 1)));
  final rec = RhythmEngine.analyze(sessions);
  if (rec == null) return null;
  final store = ref.watch(userProfileStoreProvider);
  if (await store.isRhythmDismissed(rec.id)) return null;
  return rec;
});
```

##### B. Shared card widget

Create `lib/presentation/widgets/rhythm_recommendation_card.dart`:

- Show `headline`, `actionLabel`, evidence chips  
- Buttons: **Start now** | **Schedule** | **Not now**  
- Style: `AppColors.background2`, emerald border, match Home cards  

##### C. Accept handlers

Create `lib/features/rhythm/services/rhythm_accept_service.dart` (or methods on store):

| Action | Implementation |
|--------|----------------|
| **Start now** | `context.go('/focus', extra: { durationMinutes: 25 or 45, sessionLabel: 'Protected focus', autoStart: true })` |
| **Schedule** | Build `SuggestedSession` JSON via `UserProfileStore.saveSuggestedSessionJson`; set `scheduledFor` to next preferred weekday at `windowStartHour` |
| **Not now** | `UserProfileStore.dismissRhythm(rec.id)` then `ref.invalidate(rhythmRecommendationProvider)` |

Use `dart:convert` `jsonEncode(SuggestedSession.toJson())` — model already has toJson/fromJson in `rhythm_recommendation.dart`.

##### D. Home integration

Edit `lib/presentation/screens/home/home_screen.dart`:

1. Import rhythm providers + card.  
2. After Flow Score / XP bar (before MITs), insert:

   ```dart
   ref.watch(rhythmRecommendationProvider).when(
     data: (rec) => rec == null
         ? const SizedBox.shrink()
         : RhythmRecommendationCard(...),
     loading: () => const SizedBox.shrink(),
     error: (_, __) => const SizedBox.shrink(),
   );
   ```

3. If `SuggestedSession` is for today (load from store in a small provider), show secondary CTA: **“Start protected focus”**.

##### E. Insights — honesty

Edit `lib/presentation/screens/insights/insights_dashboard_screen.dart`:

1. **Delete** hardcoded `peaks` list in `_buildEnergyForecast`.  
2. Replace section with:
   - Same `rhythmRecommendationProvider` card, **or**  
   - Empty state:  
     `"Need ~8 quality sessions over 5 days to unlock your rhythm. Keep focusing."`  
3. Do **not** show fabricated 4.2 / 3.5 bars.

##### F. Tests

Create `test/unit/rhythm_engine_test.dart` (if missing):

- Empty list → null  
- 8+ sessions clustered 9–10 AM → window includes 8–10 or 9–11  
- Below minDistinctDays → null  

#### Files

| File | Action |
|------|--------|
| `lib/features/rhythm/providers/rhythm_providers.dart` | **Create** |
| `lib/presentation/widgets/rhythm_recommendation_card.dart` | **Create** |
| `lib/presentation/screens/home/home_screen.dart` | Embed card |
| `lib/presentation/screens/insights/insights_dashboard_screen.dart` | Remove fake data |
| `lib/features/rhythm/services/rhythm_engine.dart` | Reuse |
| `test/unit/rhythm_engine_test.dart` | **Create/expand** |

#### Acceptance criteria

- [ ] Fresh install / few sessions: no fake peak chart; empty copy only  
- [ ] With seeded history: Home shows one rec with real hours  
- [ ] Start now opens focus with sensible duration  
- [ ] Not now hides card for 7 days (same id)  
- [ ] Insights never shows sample `[65, 72, 80, ...]` as if real without label (prefer remove or wire later)  

---

### P0.3 — Weekly story → one change (wire F4)

#### Problem

`WeeklyActionEngine.candidates` exists; weekly UI ends with Done / Skip only.

#### Precise steps

1. **Edit** `lib/presentation/screens/report/weekly_review_screen.dart`.

2. After `_loadReview` builds `_weekData`, also compute:

   ```dart
   // Aggregate scroll by app from scroll logs (already loaded)
   Map<String, int> scrollByApp = {};
   // focusMinutesWeek from totalFocusMinutes
   // profile from UserProfileStore
   // rhythm from RhythmEngine.analyze(sessions)
   // optional incomplete deep task from tasksDao
   _actions = WeeklyActionEngine.candidates(...);
   _actionIndex = 0;
   ```

3. **Change steps list** from ending at `_buildNextWeekStep` to include **`_buildOneChangeStep()` as final step** (or replace next-week with one-change that includes next-week copy).

   Recommended step order:
   1. Summary  
   2. Wins  
   3. Growth  
   4. Reflection  
   5. **One change** (required view; accept or explicit skip)

4. **`_buildOneChangeStep` UI:**
   - Title: “One change for next week”  
   - Story: 1 line from data (e.g. focus hours + top distraction)  
   - Card: `_actions[_actionIndex].title` + `.body`  
   - Buttons:  
     - **Accept** → `_applyWeeklyAction(action)` then `context.go('/home')`  
     - **Choose different** → cycle `_actionIndex = (_actionIndex + 1) % _actions.length`  
     - **Skip** → `Navigator`/`context.go` home without applying  

5. **`_applyWeeklyAction`:**

   | Type | Implementation |
   |------|----------------|
   | `reduceOneTrigger` | `UserProfileStore.addFirmTrigger(appName)`; optionally ensure app in distractions list |
   | `scheduleFocusWindow` | Save `SuggestedSession` JSON with tomorrow or next weekday at `focusHour` |
   | `moveTaskToEnergy` | If `taskId` set: update task energy to `deep` via TasksDao if method exists; else bump sortOrder / show snackbar + go `/tasks` |

6. Persist accepted action: `UserProfileStore.saveWeeklyActionJson(action.toJsonString())`.

7. **Daily report** (`daily_report_screen.dart`): at bottom of scroll content, add **“One thing for tomorrow”** using a thin rule set:

   - Prefer `WeeklyActionEngine` first candidate with *today’s* scroll + focus (or extract `DailyActionEngine` that calls same rules with 1-day maps).  
   - Accept → same apply helpers.  

8. **Navigation fix:** replace bare `Navigator.pop` on Done with `context.go('/home')` when review was opened via full-screen route (safer).

#### Files

| File | Action |
|------|--------|
| `lib/presentation/screens/report/weekly_review_screen.dart` | Final step + apply |
| `lib/presentation/screens/report/daily_report_screen.dart` | Tomorrow CTA |
| `lib/features/reports/services/weekly_action_engine.dart` | Reuse |
| `lib/features/reports/models/weekly_action.dart` | Reuse |
| `lib/presentation/widgets/action_commit_card.dart` | **Optional create** shared Accept UI |
| `test/unit/weekly_action_engine_test.dart` | **Create** rule priority tests |

#### Acceptance criteria

- [ ] Weekly review last step shows one action before Done  
- [ ] Accept reduce-trigger → firm list contains app  
- [ ] Accept schedule → suggested session prefs non-null  
- [ ] Choose different cycles actions  
- [ ] Skip is explicit (not silent)  
- [ ] Daily report shows tomorrow line  

---

### P0.4 — Unify streaks

#### Problem

`dashboard_providers.dart` `streakProvider` walks `DailyPlans.intentionCompleted`.  
`xp_providers.dart` / achievements use `StreakService`.

#### Precise steps

1. **Edit** `lib/features/dashboard/providers/dashboard_providers.dart`.

2. **Replace** the entire plan-walking `streakProvider` with:

   ```dart
   final streakProvider = FutureProvider<int>((ref) {
     return StreakService.getStreak();
   });
   ```

3. Add companion providers if missing (or import from `xp_providers.dart` and **delete duplicate**):

   ```dart
   // Prefer single source: re-export from xp_providers
   // Remove local streakProvider if identical name conflicts — keep ONE file as source of truth.
   ```

   **Locked decision:** Canonical file = `lib/features/xp/providers/xp_providers.dart` (`streakProvider`, `streakPausedProvider`, `bestStreakProvider`).  
   Home should `import` those; remove conflicting definition from `dashboard_providers.dart`.

4. **Edit** `home_screen.dart` header streak pill:
   - Watch `streakPausedProvider`  
   - If paused: show `⏸️` or muted fire + same count  
   - If 0: tertiary color  

5. **Weekly review** streak calculation that walks intention days → replace with `StreakService.getStreak()` / `getBestStreak()` for display; keep intention days as separate metric if needed (“X intention days”).

6. **Ensure** every XP path calls `StreakService.recordActivity()` (FocusSessionService already does on award; TaskCompletionService should too — verify and add if missing).

7. **Tests:** `test/unit/streak_service_test.dart` for grace day (1 miss pause, 2 reset).

#### Files

| File | Action |
|------|--------|
| `lib/features/dashboard/providers/dashboard_providers.dart` | Remove dual streak |
| `lib/features/xp/providers/xp_providers.dart` | Canonical providers |
| `lib/presentation/screens/home/home_screen.dart` | Paused UI |
| `lib/presentation/screens/report/weekly_review_screen.dart` | Align streak display |
| `lib/features/tasks/services/task_completion_service.dart` | Verify `recordActivity` |
| `test/unit/streak_service_test.dart` | **Create** |

#### Acceptance criteria

- [ ] Home, Profile, achievements math use same count  
- [ ] Grace day shows paused, not zero  
- [ ] Completing a task increments streak activity for “today”  

---

### P0.5 — Dead buttons & navigation hygiene

#### Precise steps

1. **Tasks screen** (`tasks_screen.dart`):

   ```dart
   _buildSmallButton('🧠 Brain Dump', () => context.push('/brain-dump')),
   ```

   - Roulette: either implement simple random incomplete task → snackbar + optional deep work, **or** hide button until implemented.  
   - **Locked:** implement minimal roulette: pick random incomplete from `activeTasksProvider`, show dialog “Start focus on X?”, yes → `/deep-work` extras.

2. **Weekly/Daily** exit: prefer `context.go('/home')` over `Navigator.pop` when stack may be empty.

3. **Profile/Settings:** ensure links to Insights, Weekly review, Daily report exist if not already.

#### Acceptance criteria

- [ ] Brain Dump opens real screen  
- [ ] Roulette either works or is removed (no dead control)  

---

### P0.6 — Profile-aware protected window (minimal)

#### Precise steps

1. On **Home**, if `userProfileProvider` has complete profile and `profile.isInProtectedWindow()`:

   - Show banner:  
     `"Protected window · ${profile.protectedWindowLabel}"`  
     CTA: **Start focus**

2. On **Scroll tracker** open, if firm + protected window:

   - SnackBar once: `"You're in protected time. Intent required."`

#### Files

- `home_screen.dart`  
- `scroll_tracker_screen.dart`  
- Reuse `UserProfile.isInProtectedWindow`

#### Acceptance criteria

- [ ] During configured hours on matching days, banner appears  
- [ ] Outside window, banner hidden  

---

## 5. Phase P1 — Soul of daily use

**Goal:** Day-2 Home feels intentional.  
**Estimate:** 3–5 days  

---

### P1.1 — Energy check-in UI

#### Problem

`EnergyCheckInsDao` contributes to daily score; no way to log energy.

#### Precise steps

1. Create `lib/features/energy/services/energy_checkin_service.dart`:
   - Derive bucket morning/afternoon/evening from hour  
   - Upsert: if today+bucket exists, update value; else insert  
   - If `countToday() == 3` and no ledger entry today for `energyCheckin3x` → `XpCalculator.awardEnergyCheckin3xBonus()`  
   - `StreakService.recordActivity()` + `AchievementChecker.runCheck`

2. Create `lib/features/energy/widgets/energy_checkin_sheet.dart`:
   - Title “How’s your energy?”  
   - 1–5 chips with emoji  
   - Optional bucket override chips  
   - Save button  

3. **Home:** energy chip in header (show latest value or “Log”) → open sheet.

4. **Providers:** `latestEnergyProvider`, `todayEnergyCountProvider` via DAO streams/futures; invalidate `dailyScoreProvider` after log.

5. Optional: post-break soft prompt once (secondary).

#### DAO extensions (`energy_checkins_dao.dart`)

Add if missing:

- `getForBucketToday(TimeOfDayColumn)`  
- `upsertToday({bucket, value})`  
- `watchToday()` if needed  

#### Acceptance criteria

- [ ] Log 3 times → +20 XP once  
- [ ] Daily score ritual component moves  
- [ ] Same bucket same day overwrites  

---

### P1.2 — Alive Home contextual CTA

#### Precise steps

1. Create helper `lib/features/dashboard/services/next_action_resolver.dart`:

   ```text
   Inputs: todayPlan?, firstSeedCompleted, hour, suggestedSession?, incomplete MITs
   Output: NextAction { label, route, extra? }

   Priority:
   1. !firstSeedCompleted → Plant seed (10m focus)
   2. plan == null && hour < 14 → Set morning intention
   3. suggestedSession for today near window → Start protected focus
   4. incomplete MIT exists → Start focus on MIT 1 (deep-work extra)
   5. hour >= 20 && !shutdown → Shutdown ritual
   6. else → Start Pomodoro
   ```

2. Home: large primary `ElevatedButton` under score using resolver.

3. Keep secondary chips (Scroll, Tasks) smaller.

#### Acceptance criteria

- [ ] Morning without plan → intention CTA  
- [ ] Evening without shutdown → shutdown CTA  
- [ ] One primary action dominates visual hierarchy  

---

### P1.3 — Celebration service

#### Precise steps

1. Create `lib/features/xp/services/celebration_service.dart`:
   - `celebrateXp(context, amount)` — snackbar + haptic  
   - `celebrateLevelUp` — already have `LevelUpOverlay`  
   - Optional confetti using `confetti` package on Break when `xpEarned > 0`

2. Break screen: confetti overlay 1.5s on reveal.

3. MIT complete on Home: short haptic + emerald snackbar (if not already).

#### Acceptance criteria

- [ ] Completing credited focus feels louder than a plain snackbar  
- [ ] Reduce motion: skip confetti if `MediaQuery.disableAnimations`  

---

### P1.4 — Notifications lifecycle

#### Precise steps

1. Do **not** request permission on cold start.  

2. After onboarding complete **or** first Settings enable:

   ```dart
   await NotificationService.initialize();
   // then schedule based on toggles
   ```

3. Wire `onDidReceiveNotificationResponse` payloads:
   - `energy` → show energy sheet or go home with flag  
   - `report` → `/daily-report`  
   - `weekly` → `/weekly-review`  
   - `intention` → `/morning-intention`  

4. Call from `main.dart` only `initialize` if permission already granted (check platform APIs); else Settings.

5. Soften streak warning copy (no false “at risk” if grace day) — optional text change in `notification_service.dart`.

#### Acceptance criteria

- [ ] Enabling energy reminders schedules 9/13/17  
- [ ] Disable cancels those ids  
- [ ] Denied permission does not crash  

---

### P1.5 — Match-energy task sort

#### Precise steps

1. `task_providers.dart` or tasks screen: sort mode enum `default | matchEnergy`.  
2. Comparator uses latest energy check-in:
   - 4–5: deep → medium → light  
   - 1–2: light → medium → deep  
   - 3: medium first  
3. Chip on Tasks: “Match energy”.

#### Acceptance criteria

- [ ] With energy 2, light tasks float to top among incomplete  

---

## 6. Phase P2 — Honesty & polish

**Estimate:** 2–3 days  

---

### P2.1 — Offline brain-dump parser

1. Create `lib/features/ai/services/local_brain_dump_parser.dart` (line split + keyword energy).  
2. In `brain_dump_screen.dart`: on AI null, run parser; badge “Local sort · AI offline”.  
3. Unit tests for split/keywords.

---

### P2.2 — Settings persistence

1. Create `lib/features/settings/providers/settings_providers.dart` with SharedPreferences keys:
   - scroll budget, ambient, auto-sync, energy/report/streak reminders  
2. Load in `SettingsScreen.initState` / provider.  
3. Scroll budget also updates today’s plan if exists.  
4. Focus screens read ambient enabled flag before `AmbientSoundPlayer.play`.

---

### P2.3 — Theme application (pragmatic)

1. Convert `FlowOSApp` to use `themeProvider` + `AppTheme.fromFlowTheme`.  
2. Shell bottom nav uses `Theme.of(context).colorScheme.primary`.  
3. Document follow-up: replace static `AppColors` gradually.  
4. Locked themes cannot apply below unlock level (settings already checks).

---

### P2.4 — Data export

1. `lib/features/export/services/data_export_service.dart` — dump DAOs to JSON v1.  
2. Settings tile “Export my data” → `share_plus`.  
3. Confirm dialog about sensitive titles.

---

### P2.5 — Store listing honesty

1. Edit `STORE_LISTING.md` / marketing:  
   - Mark Flow Garden / widgets “coming soon” if unbuilt  
   - Do not claim automatic phone screen time until P3  
2. Prefer empty states over sample charts everywhere remaining.

---

### P2.6 — Scroll intent schema (optional but recommended)

1. Bump Drift `schemaVersion` to 2.  
2. Add to `ScrollLogs`: `intent` text nullable, `wasTimeboxed` bool, `plannedMinutes` int nullable.  
3. `onUpgrade` add columns.  
4. Run `dart run build_runner build -d`.  
5. Migrate insertLog to use real columns; stop encoding in `recoveryActionType`.

---

## 7. Phase P3 — Platform depth

**Estimate:** 1–3 weeks depending on OS work  
**Start only after P0–P1 dogfood.**

---

### P3.1 — Android Attention Radar

1. Add `usage_stats` (or MethodChannel).  
2. Permission UX: Usage Access settings.  
3. Watchlist packages → Instagram, YouTube, TikTok, etc.  
4. Diff daily totals → append scroll logs with source `android` (needs source column).  
5. Home “Attention today” bars.  

**Do not claim Reels vs Feed precision.**

---

### P3.2 — Extension merge

1. Align extension payload with Supabase `scroll_logs` / visits.  
2. Mobile pull distracting minutes into daily score.  
3. Auth: same user id in extension options.

---

### P3.3 — Flow Garden MVP

1. Fill `lib/features/flow_garden/`:  
   - Stages from weekly focus minutes  
   - Home thumbnail  
   - First seed completion already flagged → start at Sprout  
2. Wilt is visual only (no XP punishment).

---

### P3.4 — Home widgets + OS Focus (optional)

1. Complete native WidgetKit / Glance using `home_widget_provider.dart`.  
2. Optional Deep Work → DND / Focus Mode (permission-heavy).

---

### P3.5 — Explicitly out of scope

- Public leaderboards  
- Streak freeze IAP  
- Forced phone lock as default  
- Ads  

---

## 8. Execution schedule

| Day | Work | Exit criteria |
|-----|------|----------------|
| 1 | P0.1 Scroll intent + rest | Intent before timer |
| 1–2 | P0.2 Rhythm Home + Insights honesty | No fake peaks |
| 2 | P0.3 Weekly one-change | Accept applies |
| 2 | P0.4 Streak unify + P0.5 dead buttons | One streak; Brain Dump works |
| 3 | P0.6 Protected banner + dogfood P0 | Profile shapes UI |
| 4–5 | P1.1 Energy + P1.2 Alive CTA | Energy logs; one primary CTA |
| 5–6 | P1.3 Celebration + P1.4 Notifications + P1.5 Match energy | Soul + reminders |
| 7–8 | P2 polish (parser, settings, theme, export, listing) | Trust + polish |
| Later | P3 platform | After retention check |

---

## 9. Dependency graph

```text
P0.4 Streak ─────────────────────────────────┐
P0.5 Buttons ────────────────────────────────┤
P0.1 Scroll intent ──► uses UserProfile ─────┤
P0.2 Rhythm ──► Home + Insights ─────────────┼──► Dogfood
P0.3 Weekly action ──► SuggestedSession ─────┤
P0.6 Protected banner ──► UserProfile ───────┘
         │
         ▼
P1.1 Energy ──► score + match energy (P1.5)
P1.2 Alive CTA ──► plan, seed, suggested session
P1.4 Notifications ──► energy sheet route
         │
         ▼
P2 → P3
```

---

## 10. Verification

### Automated

```bash
cd flowos
flutter analyze lib/
flutter test
```

**Required tests after P0–P1:**

| Test file | Covers |
|-----------|--------|
| `test/focus_session_service_test.dart` | Already exists — keep green |
| `test/unit/rhythm_engine_test.dart` | Thresholds + peak window |
| `test/unit/weekly_action_engine_test.dart` | Priority order |
| `test/unit/streak_service_test.dart` | Grace rules |
| `test/unit/local_brain_dump_parser_test.dart` | P2 |
| `test/unit/energy_checkin_service_test.dart` | Upsert + 3× bonus |

### Manual dogfood script

**P0**

1. Fresh install → onboarding → seed → break → home  
2. Scroll Instagram → intent → Rest → rest screen  
3. Scroll → Just scrolling → timer → log  
4. Insights without history → empty, not fake peaks  
5. Seed 8+ sessions in one hour band (debug) → rhythm card → Start now  
6. Weekly review → Accept action → Home reflects schedule/firm  
7. Complete task → streak matches Profile  

**P1**

8. Log energy 3× → XP + score  
9. Morning Home CTA = intention  
10. Enable notifications → receive energy prompt (or schedule smoke test with short offset in debug)  

**Tone**

11. No shaming copy on scroll intent  
12. Rhythm cites counts, not “you should”  

---

## 11. Risks & locked decisions

| Topic | Decision |
|-------|----------|
| Scroll intent storage v1 | Encode `intent:` in `recoveryActionType` until schema v2 |
| Streak source of truth | `StreakService` only |
| Insights without data | Empty state — never sample-as-real |
| Rhythm volume | Exactly one recommendation card |
| Weekly end | Must show one-change step (accept or explicit skip) |
| OS blocking | Not in P0–P2 |
| AI for rhythm/actions | Local engines first; AI optional rephrase later |
| Roulette | Minimal random-task focus, not leave dead button |
| Theme depth | Shell + ThemeData first; full AppColors migration later |

---

## 12. Definition of done

### P0 complete when

1. Distraction opens require intent (per gentle/firm rules).  
2. Rest path works without scroll cost.  
3. Home can show a real rhythm recommendation; Insights never fakes peaks.  
4. Weekly review ends with one actionable change.  
5. One streak number app-wide.  
6. Brain Dump navigates correctly.  
7. Protected window surfaces on Home.  

### P1 complete when

1. Energy can be logged and affects score.  
2. Home has one smart primary CTA.  
3. Celebrations fire on meaningful wins.  
4. Notifications can be enabled and scheduled.  

### Product complete for public beta when

- P0 + P1 + P2 store honesty + no known crash on focus/break path  
- `flutter test` green  
- Dogfood 7 days without dual-streak or fake-chart issues  

---

## Appendix A — Critical file index

| Concern | Path |
|---------|------|
| Focus completion | `lib/features/focus/services/focus_session_service.dart` |
| Onboarding UI | `lib/presentation/screens/onboarding/onboarding_screen.dart` |
| Profile store | `lib/features/onboarding/services/user_profile_store.dart` |
| Scroll UI | `lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart` |
| Intent sheet | `lib/features/attention/widgets/scroll_intent_sheet.dart` |
| Rest | `lib/presentation/screens/rest/intentional_rest_screen.dart` |
| Rhythm engine | `lib/features/rhythm/services/rhythm_engine.dart` |
| Weekly engine | `lib/features/reports/services/weekly_action_engine.dart` |
| Home | `lib/presentation/screens/home/home_screen.dart` |
| Insights | `lib/presentation/screens/insights/insights_dashboard_screen.dart` |
| Weekly UI | `lib/presentation/screens/report/weekly_review_screen.dart` |
| Daily UI | `lib/presentation/screens/report/daily_report_screen.dart` |
| Dashboard providers | `lib/features/dashboard/providers/dashboard_providers.dart` |
| Streak | `lib/features/xp/models/streak_service.dart` |
| Router | `lib/presentation/navigation/app_router.dart` |
| Entry | `lib/main.dart` |

---

## Appendix B — Implementation order checklist (copy/paste)

```text
[ ] P0.1 Scroll intent + rest wiring
[ ] P0.2 Rhythm provider + Home card + Insights honesty
[ ] P0.3 Weekly one-change + daily tomorrow CTA
[ ] P0.4 Streak unify + tests
[ ] P0.5 Brain dump + roulette
[ ] P0.6 Protected window banner
[ ] P0 dogfood sign-off
[ ] P1.1 Energy check-in
[ ] P1.2 Alive Home CTA
[ ] P1.3 Celebrations
[ ] P1.4 Notifications
[ ] P1.5 Match energy sort
[ ] P1 dogfood sign-off
[ ] P2.1 Offline brain dump
[ ] P2.2 Settings persistence
[ ] P2.3 Themes
[ ] P2.4 Export
[ ] P2.5 Store listing
[ ] P2.6 Scroll schema migration (optional)
[ ] P3 backlog prioritization after retention
```

---

*Built with intention. Wire what you already wrote, then make Home live.*

# FlowOS — Implementation Plan

Consolidated from a full read of the repo (Flutter app, Android native, Python backend, Chrome extension, Supabase schema) plus a pass on live screenshots. Items already fixed in your recent commits (Phase 0–5) are **not** included here — this is only what's still open, re-verified against your latest `main` branch.

## How to read this

Each item has:
- **Problem** — what's wrong and why it matters
- **Files** — exact file(s)/line(s) as of the latest commit
- **Fix** — concrete steps
- **Verify** — how to confirm it's actually fixed
- **Effort** — S (< 1 hr), M (a few hours), L (a day+)

Priorities: **P0** = breaks the core promise or creates real legal/trust exposure. **P1** = visible bug, quick to fix, high first-impression impact. **P2** = quality/polish/process. **P3** = new feature work.

---

## Quick-scan summary

| # | Item | Priority | Effort |
|---|------|----------|--------|
| 1 | Foreground service for focus/sleep block lease | P0 | L |
| 2 | Chrome extension sync `ReferenceError` | P0 | S |
| 3 | Privacy policy contradicts actual data collection | P0 | S |
| 4 | Level label mismatch (Level 0 vs Level 1) | P1 | S |
| 5 | Day-1 "F" grade with zero activity | P1 | S |
| 6 | Extension options page wipes paired `supabaseUrl` | P1 | S |
| 7 | Escape hatch claims "30s + XP cost" that doesn't exist | P1 | S/M |
| 8 | Garden renders as bare emoji, no illustration | P2 | L |
| 9 | Focus timer screen has no personality | P2 | M |
| 10 | "Guardrail" copy undersells real blocking behavior | P2 | S |
| 11 | Empty-state / layout polish (Tasks, chip overflow) | P2 | S/M |
| 12 | Icon/color language inconsistency (red "no sound") | P2 | S |
| 13 | No CI/CD | P2 | S |
| 14 | Empty `test/widget`, `test/integration` dirs | P2 | M |
| 15 | Oversized files (settings_screen.dart 1400+ lines, etc.) | P2 | M/L |
| 16 | Streak service DST edge case | P2 | S |
| 17 | STORE_LISTING.md is stale (missing blocking, garden, sleep mode) | P2 | S |
| 18 | Cross-device live focus mode (extension ↔ app) | P3 | M |
| 19 | Literal pet-care layer on the garden | P3 | L |
| 20 | Surface `unlock_attempts` as a pattern insight | P3 | M |
| 21 | Proactive blocklist suggestions from usage-stats data | P3 | M |
| 22 | iOS blocking parity (Screen Time API) | P3 | L |
| 23 | Home/lock-screen widget expansion | P3 | M |
| 24 | Scheduled/automatic data export | P3 | S/M |

---

## P0 — Core reliability & trust

### 1. Foreground service for the focus/sleep block lease
**Problem:** The accessibility service (`FocusBlockerService.kt`) only blocks apps while `activeUntil` (a timestamp in SharedPreferences) is in the future. That timestamp is kept fresh by a plain Dart `Timer.periodic(20s)` that renews it +2 minutes each tick. This timer only runs while the Flutter isolate is alive and not throttled. Once the app is backgrounded for a while — screen off, user using a different app, Doze mode kicking in (especially aggressive on Xiaomi/Vivo/Oppo/OnePlus) — Android can pause that timer. The lease then expires ~2 minutes later and blocking silently lifts mid-session, with no error, no notification, nothing. This is the single biggest risk to the feature you specifically asked me to audit.

**Files:**
- `lib/features/focus/providers/focus_timer_provider.dart:478-488` (the `_leaseTicker`)
- `lib/features/focus/services/protection_policy_service.dart:24,41` (3-minute lease window)
- `android/app/src/main/AndroidManifest.xml` (no `FOREGROUND_SERVICE` permission or service declared)
- `android/app/src/main/kotlin/com/flowos/flowos/FocusBlockerService.kt` (accessibility service — stays alive fine, unaffected)

**Fix:**
1. Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>` and (Android 14+) `android.permission.FOREGROUND_SERVICE_SPECIAL_USE` or the closest matching foreground service type to `AndroidManifest.xml`.
2. Create a new `FocusSessionForegroundService.kt` (a plain `Service`, not the accessibility service) that:
   - Starts when a focus/sleep session activates (call from `MainActivity`'s method channel or directly from `activateFocusPolicy`/`renewLease` on the Dart side via a platform channel call).
   - Shows a persistent, low-priority notification: "Focus session active — 24:53 remaining · Tap to end early."
   - On a native `Handler`/coroutine loop (not a Dart timer), re-writes `activeUntil` in SharedPreferences every 20–30s directly from native code — this removes the Dart-isolate dependency entirely.
   - Stops itself when the session ends/is cancelled, or self-terminates safely if it can't reach the app after some maximum session length as a safety net.
3. Keep the existing Dart `_leaseTicker` as a secondary/redundant renewer — cheap insurance, no harm in both writing the same value.
4. Add a `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` prompt during onboarding (or in Settings) so users can exempt FlowOS from aggressive OEM battery managers — standard practice for this app category (Forest, Opal, One Sec all do this), and pair it with a short "why we ask" explanation screen.

**Verify:** Start a Deep Work (90 min) session with Guardrail/Shield protection on a device with aggressive battery management (or manually force-Doze via `adb shell dumpsys deviceidle force-idle`), lock the screen, and confirm the protected app is still blocked after 10+ minutes.

**Effort:** L — this touches native Android service lifecycle, which is the fiddliest part of the whole codebase to get right. Budget real testing time across a few device brands, not just emulator.

---

### 2. Chrome extension sync `ReferenceError`
**Problem:** `syncToSupabase()` references bare `supabaseUrl` and `supabasePublishableKey` instead of `config.supabaseUrl`/`config.supabasePublishableKey`. Neither is ever declared in that function's scope, so every sync attempt throws `ReferenceError: supabaseUrl is not defined`, caught silently by the `try/catch`. Browsing session data collected by the extension never reaches Supabase — confirmed by reproducing the error directly in Node.

**Files:** `flowos-extension/service-worker.js:322,326`

**Fix:**
```js
// Line 322 — change:
const res = await fetch(`${supabaseUrl}/rest/v1/browsing_sessions`, {
// to:
const res = await fetch(`${config.supabaseUrl}/rest/v1/browsing_sessions`, {

// Line 326 — change:
'apikey': supabasePublishableKey,
// to:
'apikey': config.supabasePublishableKey,
```
Compare against the already-correct pattern at lines 402/405 in the same file (`syncFocusState`) — same fix, just applied to `syncToSupabase`.

**Verify:** Open `chrome://extensions`, click "service worker" under FlowOS to open its DevTools console, browse a few sites for >5s each, wait for the sync alarm (or trigger manually), and confirm no `ReferenceError` and a successful `POST .../rest/v1/browsing_sessions` in the Network tab. Then check the `browsing_sessions` table in Supabase for new rows.

**Effort:** S — two-line fix, the hard part was finding it.

---

### 3. Privacy policy contradicts actual data collection
**Problem:** `PRIVACY_POLICY.md` states "We do not access your device's Screen Time or Digital Wellbeing APIs," but the Android app's core blocking/tracking feature is built entirely on `UsageStatsManager` (Android's usage-access/Digital Wellbeing data source) plus an `AccessibilityService` that observes every app the user opens. This reads like leftover copy from an earlier, manual-tracking-only version of the app. This isn't just a documentation nit — Google Play specifically scrutinizes apps requesting `PACKAGE_USAGE_STATS` and `BIND_ACCESSIBILITY_SERVICE` for exactly this kind of mismatch between disclosed and actual data use, and it's one of the more common rejection/suspension reasons during review.

**Files:** `PRIVACY_POLICY.md:25` (and the "Data We Do NOT Collect" section generally, lines 24-28)

**Fix:**
1. Remove or rewrite the "We do not access your device's Screen Time or Digital Wellbeing APIs" line to accurately describe what's collected: local on-device app usage minutes (via Usage Access) and app-open events (via Accessibility Service) used *only* to power blocking/scoring, never transmitted raw off-device (confirm this last claim is actually true in the sync payload before writing it — check what `device_usage_records` / `unlock_attempts` actually sync to Supabase).
2. Add an explicit section describing the Accessibility Service and Usage Access permissions: what they see, what they're used for, and that they're optional (app works in manual-logging mode without them).
3. Cross-check every other claim in the doc against current behavior — the "No tracking" line in `STORE_LISTING.md` (see item 17) has the same root cause and should be reconciled in the same pass.

**Verify:** Read the privacy policy start to finish alongside the current feature set (README + STORE_LISTING once updated) and make sure every listed permission or data flow appears in the policy.

**Effort:** S — it's a writing task, not a code task, but don't skip it; do it before your first Play Store submission or resubmission.

---

## P1 — Visible bugs, quick fixes, high first-impression impact

### 4. Level label mismatch (Level 0 vs Level 1)
**Problem:** On the Home screen, the hero card shows `Level $level` (current level, correctly 0 for a new user), while scrolling down to the XP progress bar shows `Level ${level + 1}` — same screen, same 0 XP state, two different numbers with identical labels. Confirmed via screenshots and in code.

**Files:** `lib/presentation/screens/home/home_screen.dart:189` (correct, current level) vs `:366` (`level + 1`, mislabeled)

**Fix:** Relabel line 366 so it reads as a target, not a current state:
```dart
// Current:
Text('Level ${level + 1}', ...)
// Change to something like:
Text('Next: Lv ${level + 1}', ...)
```
Or restructure the row to read "20 / 100 XP → Level 2" so the arrow does the semantic work. Either way, the fix is purely presentational — the underlying `level` value is correct in both places, only the label is misleading.

**Verify:** Fresh install (or reset XP to 0), open Home, confirm both the hero card and the XP bar section communicate the same current level unambiguously.

**Effort:** S

---

### 5. Day-1 "F" grade with zero activity
**Problem:** A brand-new user with literally zero focus minutes, zero tasks, zero everything sees a Grade **F** (score 25) on their very first look at the app. Traced the exact cause: `DailyScoreCalculator._attentionScore()` returns a perfect 100/100 whenever `scrollMinutes <= 0` (line 145) — trivially true before anyone has done anything. With focus/intent/care all correctly at 0, the Attention pillar alone contributes 100 × 0.25 weight = 25 raw points, which maps to grade F. The `isIncomplete`/`grade: null` path only fires when native attention *permissions* aren't connected (`DataCoverage != complete`) — there's no separate guard for "coverage is technically complete, but nothing has happened *today* yet." This directly undercuts the "no guiltware" design philosophy that's written into the comments elsewhere in this codebase, and it's the worst possible first impression: showing a failing grade before the user has had a chance to do anything.

**Files:**
- `lib/features/xp/models/daily_score_calculator.dart:139-153` (`_attentionScore`, the root cause)
- `lib/features/dashboard/providers/dashboard_providers.dart:58,114` (where `DailyScoreCalculator.calculate` gets called with the day's live values)
- `lib/presentation/screens/home/home_screen.dart:281-311` (where `grade` renders, already has a `?? '—'` fallback ready to use)

**Fix:**
1. In `dashboard_providers.dart`, before calling `DailyScoreCalculator.calculate`, compute a simple `hasEngagedToday` flag: `focusMinutes > 0 || mitsCompleted > 0 || (plan?.intentionCompleted ?? false) || (plan?.shutdownCompleted ?? false) || recoveryActions > 0`.
2. When `hasEngagedToday` is false, skip the calculation and return a result equivalent to the existing "incomplete" shape (`grade: null`, appropriate `message`, e.g. "Your day hasn't started yet — go set an intention or start a focus session.") so the UI's existing `score?.grade ?? '—'` fallback renders cleanly with no separate UI change needed.
3. Add a unit test for this exact scenario (all-zero inputs → `grade == null`) alongside whatever tests already exist for `DailyScoreCalculator`.

**Verify:** Fresh account, open Home before doing anything — should show `—` or a neutral "not scored yet" message, not a letter grade. Then complete one focus session and confirm a real grade appears.

**Effort:** S

---

### 6. Extension options page wipes the paired `supabaseUrl` on every reopen
**Problem:** `loadSettings()` unconditionally runs `chrome.storage.local.remove(['supabaseUrl', 'supabaseKey'])` every time the options page loads — intended to purge a legacy manually-entered config from an old build. But the *current* pairing flow reuses the same `supabaseUrl` storage key to persist the paired connection. So every time a user reopens the options/settings page after pairing, the paired `supabaseUrl` gets deleted again. It's partially masked because the release build's `config.js` may have a real production URL to fall back to — but `supabasePublishableKey` uses a different, un-removed key (`supabasePublishableKey` vs the deleted `supabaseKey`), so the two values can end up out of sync, and the fallback is fragile in self-built/sideloaded extensions where `config.js` is intentionally left blank.

**Files:** `flowos-extension/options/options.js:27` (destructive removal), `:220-221` (pairing sets the same keys)

**Fix:**
1. Remove the blanket `chrome.storage.local.remove(['supabaseUrl', 'supabaseKey'])` call, or scope it so it only runs once (e.g., gated behind a `migratedLegacyKeys` flag set after the first run) rather than on every page load.
2. If a genuine migration is still needed for very old installs, do it once on extension update (`chrome.runtime.onInstalled` with `reason === 'update'`), not on every options-page view.

**Verify:** Pair the extension with a test account, close and reopen the options page several times, and confirm the paired connection stays intact (check `chrome.storage.local.get(['supabaseUrl','supabasePublishableKey','isPaired'])` in the service worker console each time).

**Effort:** S

---

### 7. Escape hatch claims "30 seconds + XP cost" that don't exist
**Problem:** `blocked.js` is headed with the comment "escape hatch with XP cost," and the override button's comment says "Disable blocking temporarily (30 seconds)." Neither is true: the override calls `TOGGLE_FOCUS`, which disables blocking indefinitely (no timer re-enables it), and there is no XP deduction anywhere in the extension. The only thing that can silently re-arm blocking is the next `syncFocusState()` alarm cycle (~1 minute, and only if the extension is paired and a focus session is still active server-side) — meaning in the unpaired/standalone case, clicking override turns blocking off permanently until manually toggled back on. `escapeHatchCount` is incremented in storage but never displayed anywhere, so there's no visible accountability either.

**Files:** `flowos-extension/blocked.js:1,26-41` (comments vs actual behavior), `service-worker.js` `TOGGLE_FOCUS` handler and `syncFocusState()`

**Fix — pick one direction and implement it fully rather than leaving the mismatch:**
- **Option A (match the comment):** Implement what's described — a real timed bypass. On override, record `bypassUntil = now + 30s` in storage, have the blocking-check logic in `service-worker.js` respect it (skip redirect/block for that specific domain until it expires), and auto re-arm without depending on the sync alarm. Add an actual XP deduction: call your existing XP ledger insert path (mirroring how the Flutter side writes negative `pointsDelta` entries) so the cost is real and shows up in the user's history.
- **Option B (match reality, simpler):** Rewrite the copy to be honest about what happens today — e.g., "This turns off blocking until your next focus sync." Surface `escapeHatchCount` somewhere visible (popup or sidepanel) so at least there's a visible tally even without a hard cost.
- Given the app's stated "consent-based, never punish" philosophy (see `focus_protection.dart` doc comment), Option A with a *small, transparent* cost is more in keeping with the rest of the product than silently doing nothing — but that's a product call, not just an engineering one.

**Verify:** Trigger a block, use the override, and confirm the actual behavior (duration, any XP change) matches whatever the UI now says — no daylight between claim and reality either way.

**Effort:** S (Option B) / M (Option A)

---

## P2 — UX & visual polish (the "soulless / dull" feedback)

### 8. Garden renders as bare emoji, no illustration
**Problem:** The garden — described as the emotional centerpiece of the app — is, in the current build, raw system emoji (🌲🌳🌴🌸🌻🌷🌼💧☀️🦋) positioned by percentage x/y coordinates on a flat `LinearGradient` rectangle (`GardenObject.fromFocusSession`/`fromPersistedSeed` in `garden_day.dart`). The screenshots confirm this exactly: a single butterfly floating in an empty dark-green void. Emoji also render inconsistently across devices/OS versions, so there's no guaranteed visual consistency even within what's already there.

**Files:** `lib/features/flow_garden/models/garden_day.dart` (emoji selection logic), `lib/features/flow_garden/widgets/home_garden_scene.dart`, `garden_plot.dart`, `home_garden_hero.dart` (rendering)

**Fix (phased, since this is a real design investment, not a quick patch):**
1. **Short term (S, do this first):** Replace raw emoji with custom SVG/vector assets for the existing categories (tree, flower, water droplet, sun, butterfly) at 2-3 growth-stage variants each. Keeps the same data model (`GardenObjectKind`, x/y placement, `_stableSeed` variant picking) — you're swapping the rendering layer, not the logic.
2. **Medium term (M):** Add a simple ground/ambient layer behind the objects — a gradient-to-texture transition, some depth via subtle parallax or layered shadows, a horizon line — so the plot doesn't read as "objects floating in a void" even on light days.
3. **Longer term (L):** Lean into the seasonal theming that's already written (`GardenSeason.forDate`) — vary background tone/lighting by season, not just the caption text, since the copy is already there and unused visually.
4. Keep the "resting soil, nothing lost" philosophy exactly as-is — that's genuinely good design, don't undo it while reskinning.

**Verify:** Side-by-side before/after on a day with 2-3 sessions logged — does it read as "a garden" at a glance, without reading the caption text.

**Effort:** L overall, but step 1 alone (S/M) will move the needle the most for the least cost.

---

### 9. Focus timer screen has no personality
**Problem:** The screen a user stares at for 25–90 minutes straight is a bare countdown ring on black, with a large amount of unstyled empty space above and below. No garden tie-in, no ambient motion, nothing that reflects the "your focus is growing something" concept the rest of the app is built around.

**Files:** the Focus timer running screen widget (search for the countdown/`elapsedSeconds` ring in `lib/presentation/screens/focus/`)

**Fix:**
1. Add a subtle, low-motion background element tied to the session's garden seed (e.g., a soft glow or slow-drifting particle effect using the seed's color, or a faint silhouette of what's about to grow).
2. Reduce dead vertical space by either centering content more deliberately or adding a small "today so far" strip (mirrors the "🌸 +1 today" pattern other habit apps use) between the timer and the ambient sound row.
3. Reconsider the ambient-sound icon row's visual weight — it's currently the most detailed part of the screen; balancing it against a more intentional timer area would help.

**Verify:** Design/gut check against the Home hero card and Garden screen — the three should feel like the same app.

**Effort:** M

---

### 10. "Guardrail" copy undersells what it actually does
**Problem:** On the Focus Cave setup screen, selecting "Guardrail" shows: *"Your timer pauses when you leave FlowOS, so you can return by choice."* That's accurate about the in-app timer, but incomplete: `FocusProtectionLevel.pauseAndProtect.toProtectionMode()` maps to `ProtectionMode.guard`, which also arms the real, system-level accessibility-service blocking for anything in the user's Protected Apps list. Someone with Instagram protected who picks Guardrail expecting "I can return by choice" will actually get redirected out of Instagram in real time — a materially stronger intervention than the copy implies. Not a wiring bug (the text does update correctly per selection) — it's that the copy only discloses one of the two systems it's controlling.

**Files:** `lib/features/focus/models/focus_protection.dart:22-29` (the three description strings), `lib/features/focus/widgets/focus_protection_selector.dart:71-77` (renders `value.description`)

**Fix:** Rewrite the `pauseAndProtect` and `intentionalExit` descriptions to mention both layers when a protected-apps list is configured, e.g.: *"Your timer pauses when you leave FlowOS. Apps on your Protected list will also redirect you back if you open them."* Consider making the description dynamic — if the user has zero apps protected, the system-blocking half is moot and can be omitted or shown as "add apps to protect them during this mode."

**Verify:** Select Guardrail with at least one protected app configured, read the description, then actually try opening that app during a session — confirm the described behavior matches what happens.

**Effort:** S

---

### 11. Empty-state / layout polish
**Problem:** Tasks screen has a large stretch of unstyled black space below a short task list instead of an empty-state treatment. The horizontally-scrolling action chips at the top of Tasks (Brain Dump / Roulette / a third cut-off chip) get clipped at the screen edge with no fade or arrow hinting there's more to scroll to.

**Files:** `lib/presentation/screens/tasks/tasks_screen.dart`

**Fix:**
1. Add a real empty/light state for the task list area (illustration + prompt, e.g., "Add a task or pull one from Brain Dump") rather than letting the list just end into blank space.
2. Add a trailing fade gradient (or a subtle chevron) to the horizontal chip row so its scrollability is visually obvious.

**Verify:** Fresh account with 0-2 tasks — screen should feel intentional, not unfinished.

**Effort:** S/M

---

### 12. Icon/color language inconsistency
**Problem:** On the running Focus timer screen, the "no ambient sound" option uses a red prohibition-style icon (circle-slash over a speaker), which visually reads as "blocked/error" rather than "a valid neutral choice you can pick." Red should be reserved for destructive/warning actions (which the Stop button already correctly uses).

**Files:** the ambient sound selector row, likely in `lib/features/focus/services/ambient_sound_player.dart` or the widget that renders the icon row on the timer screen

**Fix:** Swap the "no sound" icon to a neutral gray/muted-tone icon (e.g., a plain speaker-off glyph without the red prohibition ring), consistent with the other four ambient-sound options' styling.

**Verify:** Visual review of the timer screen's icon row — the five options should read as "five equal choices," with red reserved only for Stop.

**Effort:** S

---

## P2 — Engineering process & maintainability

### 13. No CI/CD
**Problem:** No `.github/workflows` directory — nothing runs `flutter analyze`/`flutter test`/lints automatically on push or PR, so regressions in the 34+ existing tests can go unnoticed until someone runs them manually.

**Fix:** Add a basic GitHub Actions workflow: checkout → `flutter pub get` → `flutter analyze` → `flutter test`. Optionally add a second job for the Python backend (`pip install -r requirements.txt` → `pytest` — you already have `backend/tests/test_prompt_renderer.py`, so there's a real test to run). Keep it minimal at first; expand with build checks later.

**Effort:** S

---

### 14. Empty `test/widget/` and `test/integration/` directories
**Problem:** Existing tests are solid where they exist (e.g., `protection_policy_service_test.dart` covers real conflict-resolution edge cases well), but they skew entirely toward unit/logic tests. `test/widget/` and `test/integration/` are scaffolded but empty — meaning none of the actual permission-request flows, onboarding, or end-to-end blocking behavior have automated coverage, despite being the hardest parts of the app to get right and the most likely to regress silently (as items 4 and 5 above demonstrate — both are exactly the kind of thing a widget test on the Home screen would have caught).

**Fix:** Start with 2-3 high-value widget tests: Home screen renders a consistent level number across all its sections (would have caught #4 directly); dashboard score shows `—` not a letter grade with zero engagement (would have caught #5 directly). Add integration tests for the onboarding permission flow once it stabilizes.

**Effort:** M

---

### 15. Oversized files
**Problem:** Several files are large enough to be a real maintenance drag: `settings_screen.dart` (~1400 lines), `focus_screen.dart` (~730), `home_garden_scene.dart` (~680), `scroll_tracker_screen.dart` (~670). Large single-file screens make it easy for exactly the kind of "two places show two different numbers" bug (#4) to creep in, since related UI state ends up duplicated rather than shared.

**Fix:** No urgency to do this all at once — tackle opportunistically when touching these files for other reasons. Break each into smaller widgets grouped by section (e.g., `settings_screen.dart` → `AccountSection`, `PermissionsSection`, `ThemeSection` as separate files), which also makes future widget testing (item 14) much easier to write.

**Effort:** M/L, spread over time

---

### 16. Streak service DST edge case
**Problem:** `StreakService` computes elapsed days via `DateTime.now().difference(lastDate).inDays`, which is calendar-aware in virtually all cases — except immediately after a "spring forward" DST transition, where a user active in roughly the first hour after midnight on the day following the transition could see `daysSince == 0` computed instead of `1`, which falls through to the "2+ days missed → reset" branch instead of "consecutive day." Low frequency (1-2x/year, narrow time window), but a real, silent streak-reset bug for anyone it hits.

**Files:** `lib/features/xp/models/streak_service.dart:49-64`

**Fix:** Compare calendar dates directly rather than differencing `DateTime` instants — e.g., normalize both `lastDate` and `now` to `DateTime(y,m,d)` at local midnight and compute `.difference(...).inDays` between those two normalized values (removes any DST-instant arithmetic from the comparison entirely).

**Verify:** Unit test with a mocked "now" set to just after midnight on a historical spring-forward date, `lastActive` set to the day before — should classify as consecutive (`daysSince == 1`), not reset.

**Effort:** S

---

### 17. STORE_LISTING.md is stale
**Problem:** The store listing draft doesn't mention app blocking, the Flow Garden, or Sleep Mode at all — the three most distinctive things this app does per your own description — and calls the Chrome extension "coming soon" despite it already existing (if partially broken). It also claims "No tracking," which needs the same reconciliation as the privacy policy (item 3) once that's rewritten.

**Files:** `STORE_LISTING.md`

**Fix:** Rewrite once items 1-3 and 8-10 are further along, so the listing describes the app as it will actually ship, not a v1 snapshot. Bundle this with the privacy policy pass (item 3) since they share the same root cause (docs written early, not revisited as native features shipped).

**Effort:** S

---

## P3 — Feature suggestions

### 18. Cross-device live focus mode
Once item 2 (extension sync) is fixed, `syncFocusState()` in `service-worker.js` already polls for an active focus session and arms extension-side blocking accordingly — the intent is already built, it's just currently inert because the data never syncs. Worth explicitly testing and marketing as a real feature once #2 lands: start a session on your phone, your laptop browser blocks distracting sites too, automatically.

### 19. A literal pet-care layer on top of the garden/companion
The "wildlife companion" (butterfly, tap for a 2-minute recovery session) is the closest thing to a pet today. If the Tamagotchi-style hook you originally described is something you want more literally, consider a small companion with 2-3 visible states (resting / attentive / thriving) tied to recent care actions — keeping the existing no-punishment philosophy (it never "starves," it just waits, matching the garden's "resting soil" framing).

### 20. Surface `unlock_attempts` as a pattern insight
You're already recording every time someone tries to open a blocked app during a session (`unlock_attempts` table: package, time, requested break length, intention text). None of that comes back to the user as insight today. A simple weekly callout — "You tried to open Instagram most around 3pm this week" — turns data you're already collecting into one of the more genuinely useful features an app like this can offer.

### 21. Proactive blocklist suggestions from usage-stats data
Since native usage tracking is already wired up, you have the raw data to suggest protected apps rather than requiring the user to think of them upfront — e.g., a one-time or periodic prompt: "Instagram: 47 min yesterday — add it to your protected list?"

### 22. iOS blocking parity
The accessibility-service approach has no direct iOS equivalent. Apple's Screen Time APIs (`FamilyControls`, `ManagedSettings`, `DeviceActivity`, iOS 16+) can achieve a similar effect but work very differently — token-based app selection rather than package names, no visibility into *which* specific app was opened (only that a monitored category was accessed), and it requires requesting a specific Apple entitlement with a written justification before you can ship it. Worth scoping as a separate, iOS-specific effort rather than assuming the Android design ports over.

### 23. Home/lock-screen widget expansion
`home_widget` is already a dependency and `lib/features/widgets/` already exists — worth extending to show a live focus countdown or the day's garden state directly on the home screen, building on infrastructure that's already there rather than starting fresh.

### 24. Scheduled/automatic data export
`lib/features/export/services/data_export_service.dart` already exists for manual export — consider extending it to a scheduled/automatic backup (e.g., periodic export to a user-chosen location) and/or a calendar export of completed focus sessions as time blocks, both natural extensions of infrastructure you've already built.

---

## Suggested execution order

If working through this roughly in order of "stop losing users" impact:

1. **Week 1:** Items 2, 4, 5, 6 — all small, all fix visible/first-impression breakage.
2. **Week 1-2:** Item 3 (privacy policy) — do this before any Play Store submission.
3. **Week 2-3:** Item 1 (foreground service) — the biggest lift, but it's the actual core promise of the "advanced Android features" you set out to build.
4. **Ongoing:** Items 8-12 (visual polish) — pick these up as a design pass once the reliability work above is solid; no point polishing a garden screen while the underlying block can silently fail.
5. **Opportunistic:** Items 13-17 (process/docs) — cheap, do them alongside whatever else you're touching.
6. **When ready to grow the feature set:** Items 18-24, roughly in the order listed — 18 and 20 are the cheapest given what's already built.

# FlowOS — Implementation Plan (Merged)

This replaces the earlier plan. It merges three rounds of analysis: the original code audit, a follow-up pass on Play Store readiness (Play Protect, app detection, screen time accuracy), and this round's live-testing bug reports plus fresh screenshots. Items confirmed fixed are listed briefly for the record; everything else is organized by priority with exact files, root causes, and fixes.

## Status legend
✅ Fixed and verified against latest `main`. 🔴 P0 — breaks the core promise or blocks launch. 🟠 P1 — visible bug, quick fix, high impact. 🟡 P2 — polish/process. 🟢 P3 — new feature work.

---

## ✅ Already fixed (verified this session)

Foreground service for the block lease · Chrome extension sync `ReferenceError` · Extension options page wiping paired credentials · Escape hatch now uses a real `chrome.alarms`-based 30s rearm · Level 0/Level 1 label mismatch on Home · Day-1 "F" grade (now shows a neutral "your day hasn't started" state) · Streak service DST edge case (now compares UTC calendar dates) · CI workflow added · Tasks screen empty state (now has illustration + CTA instead of blank space) · Garden objects repainted as custom vector art instead of raw emoji · Insights dashboard screen built (unlock attempts, phone unlocks, notifications-by-app) — see item 15, it's built but unreachable.

---

## 🔴 P0 — Launch blockers

### 1. Block lease doesn't survive backgrounding under Guardrail/Shield — now confirmed as the cause of a live bug
**This merges the original "foreground service" finding with your new "first minimize doesn't track" report — they're the same root cause.**

`FocusProtectionLevel.pausesWhenLeaving` (`focus_protection.dart:31`) is `true` for **both** Guardrail and Shield (`this != FocusProtectionLevel.softReturn` — only Gentle is excluded). So backgrounding the app under Guardrail or Shield calls `pauseSession()` (`focus_timer_provider.dart:294`), which calls `_stopTickers()` (line 298) — and `_stopTickers()` **cancels `_leaseTicker`** (line 521-522), the only thing renewing the native `activeUntil` lease that `FocusBlockerService.kt` checks before blocking/tracking anything. The foreground service you added starts the service process, but it does **not** independently renew the lease natively — that job is still solely the Dart timer's, and pausing the session kills that timer outright.

So: every time you background the app under Guardrail/Shield, the lease stops renewing. If you're backgrounded past whatever time was left on the lease (up to ~2 min after the last renewal), blocking and tracking silently stop until you return. This explains "sometimes works, sometimes doesn't" — it depends entirely on how much lease time was left the moment you backgrounded, which is inherently inconsistent test-to-test, not a clean first/second split. If your specific first-vs-second-time pattern holds up under more testing, it's likely because the very first backgrounding in a session happens soon after the initial 3-minute lease window starts (least time elapsed, most margin), while a later backgrounding happens after intervening renewals have reset the clock differently — worth checking Logcat for `FocusSessionForegroundService` and `FocusBlockerService` timestamps across a repeat test to pin the exact window down.

**Files:** `lib/features/focus/models/focus_protection.dart:31`, `lib/features/focus/providers/focus_timer_provider.dart:294-298,518-523`, `android/app/src/main/kotlin/com/flowos/flowos/FocusSessionForegroundService.kt`

**Fix:**
1. Move lease renewal into `FocusSessionForegroundService.kt` itself — a native `Handler`/coroutine loop that re-writes `activeUntil` in SharedPreferences every 20-30s for as long as the service is alive, independent of whether the Dart-side session is "paused" or "running." This was the original recommendation; today's bug report is direct evidence it's not optional.
2. Stop `pauseSession()` from cancelling `_leaseTicker` — the visible countdown pausing (a UX choice for Guardrail/Shield) and the native protection lease staying alive are two different concerns; conflating them is what's causing this. Once native renewal exists (step 1), this stops mattering, but even independently, the Dart ticker shouldn't tie its lifecycle to the visible-timer pause state.
3. Add the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` prompt during onboarding (still not present) so aggressive OEM battery managers (Xiaomi/Vivo/Oppo/OnePlus especially) don't compound this.

**Verify:** Start a Guardrail session, background the app immediately, wait 3+ minutes, open a protected app — should still redirect. Repeat starting from a fresh session each time to confirm consistency (not just "second time only").

**Effort:** L

### 2. Play Protect flags the app as unsafe
`android/app/build.gradle.kts` falls back to signing with the **debug keystore** whenever `android/key.properties` doesn't exist locally — which it doesn't in this repo (correctly gitignored, but that means every sideloaded "release" build so far has actually been debug-signed). Debug-signed APKs combined with the Accessibility + Usage Stats + Notification Listener permission bundle are a strong Play Protect trigger.

**Fix:**
1. Generate a real upload keystore, create `android/key.properties` locally (never commit it).
2. Enable R8 shrinking for release (`isMinifyEnabled`/`isShrinkResources` are currently absent from the `release` block).
3. Push to a Play Console **Internal Testing** track as soon as you have a real keystore — Play-distributed installs get materially less Protect friction than sideloaded ones, and this is the standard way to test this exact scenario.

**Effort:** S (keystore + gradle) / ongoing (Play Console track)

### 3. App detection fails on Android 11+ devices
`AndroidManifest.xml` only declares a `<queries>` entry for Flutter's `PROCESS_TEXT` boilerplate — no `MAIN`/`LAUNCHER` intent. Since Android 11, `queryIntentActivities()` (used in `MainActivity.kt:395` for the app picker) silently returns a filtered subset without this declaration. Explains "works on some devices, not others" precisely — any device on Android 11+ is affected.

**Fix:**
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```
**Effort:** S

### 4. Privacy policy contradicts actual data collection
`PRIVACY_POLICY.md:25` states "we do not access Screen Time or Digital Wellbeing APIs" — directly contradicted by the `UsageStatsManager`/`AccessibilityService` usage that blocking depends on. Real Play Store review risk. `STORE_LISTING.md` has the same root cause (says "No tracking," omits blocking/garden/sleep mode, calls the extension "coming soon").

**Fix:** Rewrite both to accurately describe current data collection and features, once the fixes below stabilize what "current" means. Also fill out the Play Console Data Safety form to match.

**Effort:** S

---

## 🟠 P1 — High-impact bugs

### 5. Stop button permanently stops working after certain flows
**Root cause found and confirmed in code.** `_isFinalizing` (`focus_screen.dart:67`) is set to `true` at the top of `_stopSession()` (line 222) and `_completeSession()`-equivalent (line 267), but is **never reset to `false`** anywhere in the file:
```dart
Future<void> _stopSession() async {
  if (_isFinalizing) return;          // <- guard
  setState(() => _isFinalizing = true);
  final active = ref.read(focusTimerNotifierProvider);
  if (active == null) return;         // <- early return, flag never reset!
  ...
```
If `active` is `null` when this runs — plausible after the pause/resume dance triggered by a Guardrail/Shield block interruption — the function exits at that early return, `_isFinalizing` stays `true` forever, and the guard at the top silently no-ops every future tap of Stop for the rest of that screen instance. This is why it's specifically Guardrail/Shield affected: Gentle never triggers `_checkBlockedAppTrigger()`'s pause/resume state changes that put the provider into this state.

**Fix:** Wrap the body in `try/finally` and reset the flag on every exit path that doesn't navigate away:
```dart
Future<void> _stopSession() async {
  if (_isFinalizing) return;
  setState(() => _isFinalizing = true);
  try {
    final active = ref.read(focusTimerNotifierProvider);
    if (active == null) return;
    // ... existing logic
  } finally {
    if (mounted) setState(() => _isFinalizing = false);
  }
}
```
Apply the same pattern to whatever's at line 266-267.

**Verify:** Trigger a Guardrail block-and-return cycle a few times during one session, then confirm Stop still works afterward.

**Effort:** S

### 6. "Take a break" appears not to work
Traced the full plumbing — Dart write → SharedPreferences → native reactive listener → native block-skip check — and structurally it's wired correctly: `grantScopedBreak()` writes a `ScopedBreak` (`protection_policy_service.dart:45-75`), `FocusBlockerService.kt` has a registered `OnSharedPreferenceChangeListener` (line 33-38) that reloads policy on write, and the block-decision logic does check `policy.focusBreaks[packageName]` and correctly skips redirecting when a break is active (`FocusBlockerService.kt:145-157`). So this isn't an obviously broken wire — two more likely explanations:

- **(A) By design, but not communicated.** In `focus_screen.dart:159-168`, granting a break calls `resumeSession()` — meaning your overall Pomodoro clock keeps counting the whole time you're on your "break," it never pauses for it. If you expected the countdown to freeze during a break the way it's frozen during the block screen, "the timer keeps running" isn't a bug, it's confusing UX: a break from the *specific blocked app* is not the same as a break from your *focus session*, and nothing on screen says so.
- **(B) A possible lost-update race.** Both `renewLease()` (fires every 20s from the Dart lease ticker) and `grantScopedBreak()` do a read-current-policy → modify → write-back-whole-object sequence against the same SharedPreferences key, with no locking. If a lease renewal's write happens to land between a break-grant's read and write, the break write could get silently overwritten and never actually reach the native side, even though the UI shows success and logs the unlock attempt.

**Fix:**
1. For (A): decide the intended behavior and make it explicit either way — either genuinely pause the overall session timer for the break duration (probably the more intuitive choice — "breaks" shouldn't cost you session progress), or keep current behavior but say so on the button/confirmation ("Your focus timer keeps running during this break").
2. For (B): make policy writes atomic — e.g., route all writes for `flowos_active_policies` through a single serialized queue/mutex in `PolicyWriter`, or use a proper read-modify-write transaction pattern instead of independent read-then-write calls from different callers.

**Verify:** Grant a 5-min break, confirm you can actually reopen the target app without being redirected for the full 5 minutes, and separately confirm whether your overall session countdown moved during that window — check against whichever behavior you land on for (A).

**Effort:** M

### 7. Screen time tracking gaps (Games, Reddit, non-Chrome browsers)
Confirmed and unchanged from the prior pass. "Distracting" isn't inferred — it's gated by a `distractions` watchlist, and:
```dart
// attention_data_repository.dart:446 (duplicated in app_picker_providers.dart:61)
'browser' => 'com.android.chrome',
_ => null,   // Games, Other -> silently dropped
```
- Your Settings → Shape Focus sheet offers 8 options (Instagram, YouTube/Shorts, TikTok, X/Twitter, Reddit, Browser, **Games**, **Other**) but the mapping only knows 6 — Games and Other are selectable but silently do nothing.
- `UserProfile.defaults()` (`user_profile.dart:31`) hardcodes `['Instagram', 'YouTube/Shorts', 'TikTok']` — Reddit has a valid mapping but isn't in the default, so it's untracked unless someone manually visits the new settings sheet.
- `Browser` hardcodes to Chrome only — Samsung Internet/Firefox/Brave users get zero tracking.
- The Scroll Tracker manual-log screen (screenshots) offers a *different* 6-option set (Instagram/YouTube/Twitter-X/Reddit/TikTok/Other, no Games at all) than the Settings sheet's 8 — two different lists for conceptually the same thing.

**Fix:**
1. Extract the mapping into one shared location both files import (it's duplicated verbatim right now).
2. For Games/Other: since there's no fixed package, open the existing app picker (already built for Protected Apps) instead of silently dropping the selection.
3. For Browser: detect the actual default browser via `Intent.ACTION_VIEW` + `http://` resolution instead of hardcoding Chrome.
4. Reconcile the two different option lists (Settings sheet vs. Scroll Tracker) into one.

**Effort:** M

### 8. Popular distracting apps should sort to the top of the picker
Confirmed — the native list is purely alphabetical:
```kotlin
// MainActivity.kt:406
return apps.sortedBy { (it["label"] as? String)?.lowercase() }
```
**Fix:** Sort with a priority tier — pin a known set of commonly-distracting packages (reuse the mapping from item 7) to the top, alphabetical within that tier, then alphabetical for everything else.

**Effort:** S — this is the item you asked me to implement directly; happy to do it now if you want.

### 9. Insights dashboard is fully built but unreachable
`InsightsDashboardScreen` (`lib/presentation/screens/insights/insights_dashboard_screen.dart`, 776 lines) already has exactly what you asked for — total phone unlocks, notifications-by-app, unlock-attempt patterns — routed at `/insights` in `app_router.dart:267-269`. But there is **no navigation entry point anywhere in the app** that links to it — confirmed by searching every screen for a call to push that route. It exists, it's reachable by URL, nobody can find it.

**Fix:** Add an entry point — most natural spots are the Profile screen (near "Visit Flow Garden") or the hamburger menu visible in your screenshots' bottom-left corner. This is close to free given the screen is already built.

**Effort:** S

---

## 🟡 P2 — Polish, consistency, process

### 10. XP/streak shown without matching activity
Screenshot (Profile) shows **11 lifetime XP** and **1 current/best streak**, while **Focus Time: 0m** and **Tasks Done: 0** on the same screen. Likely explanation: the morning intention/energy check-in flow grants a small amount of XP and counts as a "day," independent of focus/tasks — plausible by design, but the display doesn't explain *why* you have XP and a streak with nothing else done, which reads as inconsistent. Worth a one-line clarifier wherever XP/streak first shows up on a light-activity day ("Streak day earned — morning check-in counts").

**Effort:** S

### 11. Icon choices don't match their apps (Scroll Tracker)
From the screenshots: Instagram uses a camera-with-flash emoji, Twitter/X uses a parrot 🦜 (doesn't read as X/Twitter at all), Reddit uses a generic robot rather than anything evoking Reddit. These undercut the "polish" work already done elsewhere (the new garden vector art, for instance). Worth custom icon treatment here consistent with that effort — this is a quick, high-visibility fix given how often this screen gets used.

**Effort:** S

### 12. Morning Intention → MIT flow has a chicken-and-egg gap
Screenshot shows "Pick 3 MITs for today" with "No tasks yet — Add tasks first, then pick your MITs here," inside the same morning flow that's supposed to be the fast on-ramp into the day. Requires leaving the flow to add tasks elsewhere before this step is usable. Consider letting users add a task inline from this exact screen instead of routing them away.

**Effort:** S/M

### 13. Guardrail/Shield copy still doesn't disclose the full picture
Carried over from the last round, still open: "A kind cue welcomes you back; your timer keeps moving" (Gentle) and the Guardrail description don't mention that Guardrail/Shield also arm real app-level blocking via the Protected list. Once item 6's design decision lands (does the timer pause during a break or not), update this copy at the same time so it's all consistent and honest about what each mode actually does.

**Effort:** S

### 14. Garden interactivity (carried over, unchanged)
`GardenObjectPainter` is a real visual upgrade but fully static — no idle motion, and tapping a grown plant starts a *new* session rather than showing you the record behind the one you're looking at. `home_garden_scene.dart` already has the `AnimationController` pattern this needs; it just hasn't been ported to `garden_plot.dart` (the full-screen garden). Also: the resting-day indicator is still a raw 🌙 emoji while everything else was vectorized.

**Effort:** M

### 15. General UI "feel" — where to focus next
Not a single bug, more a design direction: the Home hero gradient, the new garden vector art, and the pink/green "Visit Flow Garden" button are your best visual moments right now. Everything else — Scroll Tracker, Tasks, Focus Cave, Profile stat grids — is flat navy-on-black cards with the same accent green, which is why it reads as "better but still lacking feel" even as individual screens improve. Concretely:
- Reuse the organic gradient/blob treatment from the Home hero on at least Focus Cave and the Scroll Tracker headers.
- The half-circle blue timer-style selector control (Focus Cave, bottom of screen) still reads as an unfinished placeholder shape rather than a designed control — worth a first-class custom widget.
- Empty states are inconsistent in quality now — Tasks got a proper illustration + CTA treatment; the Garden's empty week-view cards (all-identical moon+"Resting plot") and the Activity heatmap (uniform blank grid) didn't get the same care.

**Effort:** L, ongoing design work — no single fix, but items 11 and 14 above are the highest-leverage pieces of it to start with.

### 16. No crash reporting
Still nothing in `pubspec.yaml` (no Crashlytics/Sentry). Add before wider testing — you'll have zero visibility into production crashes otherwise.

**Effort:** S

### 17. `targetSdk` inherited rather than pinned
Currently `flutter.targetSdkVersion` (Flutter's default) rather than an explicit value. Play's minimum target API deadline moves yearly independent of your Flutter version — worth explicitly verifying against the current requirement before submission.

**Effort:** S

---

## 🟢 P3 — Feature suggestions (carried over, still relevant)

- **Cross-device live focus mode** — once extension sync issues are fully settled, `syncFocusState()` already polls for an active session and arms extension-side blocking; this becomes a real, marketable feature almost for free.
- **Literal pet-care layer** on the garden/companion, keeping the no-punishment philosophy already established.
- **Proactive blocklist suggestions** using usage-stats data you already collect ("Instagram: 47 min yesterday — protect it?").
- **iOS blocking parity** via Apple's Screen Time APIs (`FamilyControls`/`ManagedSettings`/`DeviceActivity`) — a separate project, different mechanics (token-based, no per-app visibility), requires an Apple entitlement request.
- **Home/lock-screen widget expansion** — `home_widget` is already a dependency; extend it to show live focus countdown or garden state.
- **Scheduled/automatic data export** — `data_export_service.dart` already exists for manual export; extend to scheduled backups or a calendar export of completed sessions.

---

## Suggested execution order

1. **Now:** Item 8 (app picker sort) — small, well-specified, you asked for it directly.
2. **This week:** Items 5, 9 (stop button, insights nav entry) — both are small, both are confirmed root-caused, both fix things that look broken but have cheap fixes.
3. **Next:** Item 1 (native lease renewal) — the highest-effort item, but it's now confirmed to be causing a live, reproducible bug, not just a theoretical risk. This should move up ahead of visual polish.
4. **Before any Play Store submission:** Items 2, 3, 4 (keystore, `<queries>` fix, privacy policy/store listing).
5. **Alongside 1-4:** Item 6 (break behavior) needs a product decision before it can be fixed correctly — worth deciding on option (A) vs confirming/fixing (B) soon since it's user-facing and currently confusing either way.
6. **Ongoing:** Items 10-15 as a design/polish pass once the above are stable — items 11 and 14 are the cheapest, highest-visibility wins in that group.

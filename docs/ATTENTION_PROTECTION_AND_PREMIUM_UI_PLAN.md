# FlowOS Attention Protection & Premium Experience Plan

**Status:** implementation blueprint  
**Scope:** selected-app protection, screen-time permissions and data, sleep mode, notification/unlock insights, scoring, onboarding, Home Garden, and Focus Timer

This is the source of truth for the next product release. It is deliberately Android-first: the Android APIs can provide the requested signals now, while iOS requires Apple approval for Screen Time capabilities and cannot promise feature parity.

---

## 1. Product contract

FlowOS helps someone protect attention; it does not punish them for using a phone.

- The Garden is the Home screen's living canvas, not another dashboard card.
- A missed day is always rest/dormancy; no plants die and no streak is destroyed.
- All device data stays local by default. Permission denial, revocation, or platform limits are presented as **unavailable**, never as zero usage or a lower score.
- "Time saved" is never claimed as a fact. The product shows **potential time to reclaim** above the person's chosen budget.
- Phone calls, emergency features, system Settings, launcher access, and the person's own ability to disable FlowOS are never claimed to be blocked.

## 2. Current-state diagnosis

| Area | What exists | Why it is insufficient |
|---|---|---|
| App blocking | Android `FocusBlockerService` can redirect a hard-coded package during a focus session. | It maps generic onboarding labels to a few package names; people cannot select installed apps or review an allowlist. |
| Usage data | `UsageStatsManager` bridge and two Dart usage services. | The services duplicate responsibility, one uses a hard-coded social watchlist, and usage can be written into two incompatible stores. |
| Permissions | Onboarding and Permission Center open Android Settings. | The journey does not explain each permission clearly, does not reliably resume/sync after return, and iOS shows a non-working placeholder. |
| Garden | A code-native interactive Home scene is available. | It is still placed after a separate Hero card rather than composing the entire first Home viewport. |
| Score | Daily Score already weighs focus, tasks, attention, and rituals. | Missing usage data is treated as perfect attention; historical aggregation uses planned rather than actual focus duration in places. |
| Insights | Existing charts cover focus and scroll patterns. | They do not present one trusted source of screen-time data, coverage, reclaimable time, or daily/weekly/monthly score states. |
| Timer | Deep Work has richer motion than standard Focus. | Two different visual languages make the core moment feel inconsistent and card-heavy. |

## 3. Platform capability rules

| Capability | Android release | iOS release |
|---|---|---|
| Selected-app blocking | Yes: user-enabled Accessibility service, explicit consent, FlowOS-branded shield. | Only after Family Controls + App & Website Usage entitlement, native extensions, and user authorization. |
| Per-app foreground usage | Yes: Usage Access / `UsageStatsManager`. | Only after Apple entitlement and native Screen Time implementation. |
| Notification count by app | Yes: optional `NotificationListenerService`; store package and count only. | Not part of the consumer iOS release. |
| Phone unlocks | Yes: daily `KEYGUARD_HIDDEN` event count, labelled **Phone unlocks**. | Not part of the consumer iOS release. SensorKit exposes this only to Apple-approved research studies. |
| Physical "pickups" | No reliable consumer API. Do not show this metric. | No reliable consumer API. Do not show this metric. |
| Sleep Mode | Yes: shield selected non-essential apps on a local schedule. | Same behavior only after Screen Time entitlement. |

Android's usage events require Usage Access and include keyguard-hidden events; detailed events should be synced daily because the system retains them only temporarily. [UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager)

Apple's App & Website Usage entitlement is required before a person can authorize access to their app and website usage. [Apple entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.family-controls.app-and-website-usage) SensorKit unlock/notification reporting is **research-study only**, so it is not a valid consumer-product fallback. [SensorKit configuration](https://developer.apple.com/documentation/sensorkit/configuring-your-project-for-sensor-reading)

## 4. Delivery order

Do not begin native iOS feature work or new charts before completing Milestones 0–2. Those milestones create the trusted data and permission foundation every other feature depends on.

### Milestone 0 — Consolidate attention data

**Goal:** one source of truth for device usage and one unambiguous data-coverage state.

1. Replace `UsageStatsService` and `DeviceUsageService` with one `AttentionDataRepository`.
2. Replace the `flowos/usage_stats` bridge with `flowos/device_attention`; retire the old methods after all callers migrate.
3. Add these native bridge methods:

   ```text
   getPermissionStates() -> {usageAccess, accessibility, notificationAccess, platformSupport}
   openUsageAccessSettings()
   openAccessibilitySettings()
   openNotificationListenerSettings()
   getLaunchableApps() -> [{packageName, label, iconBytes, category?}]
   getDailyUsage(startInclusive, endExclusive) -> [{day, packageName, label, minutes}]
   getDailyUnlockEvents(startInclusive, endExclusive) -> [{day, timestamp}]
   ```

4. Add Drift schema version 5:

   | Table | Required fields | Purpose |
   |---|---|---|
   | `protected_apps` | id, platform, appRef, displayName, category, protectsFocus, protectsSleep, isEssential, createdAt | User-selected app policy. `appRef` is an Android package name or permitted iOS token. |
   | `device_usage_records` additions | source, category, isDistracting, coverageState | Preserve whether a record is Android usage, iOS usage, or manual input. |
   | `device_day_metrics` | day, platform, unlockCount nullable, screenWakeCount nullable, usageSyncedAt | Daily device-level metrics and coverage. |
   | `notification_daily_counts` | day, platform, appRef, displayName, count, syncedAt | Count only; never store content, sender, notification key, or text. |
   | `sleep_schedules` | id, days, bedtimeMinute, wakeMinute, timezoneId, protectionLevel, enabled | Repeating Sleep Mode policy. |

5. Migrate old `DeviceUsageRecords` rows as `android_usage`; preserve manual `ScrollLogs` as `manual`. Never copy Android rows into `ScrollLogs` again.
6. Change every score/insight query to select exactly one attention source per day: native selected-app usage when available, otherwise manual logs, otherwise **unknown**.
7. Add a `dataCoverage` value to all score and chart view models: `complete`, `partial`, `manualOnly`, `notConnected`, or `unsupported`.

**Acceptance:** a day cannot show both auto screen-time and the same minutes as manual scroll; revoked permission changes UI to unavailable; a database upgrade preserves all focus, Garden, scroll, and unlock-attempt history.

### Milestone 1 — Android app picker and protection policy

**Goal:** a person chooses exactly what FlowOS may protect.

1. Implement `getLaunchableApps()` in Kotlin with `ACTION_MAIN` + `CATEGORY_LAUNCHER`; sort by localized label.
2. Return app icons lazily with a `loadAppIcon(packageName)` method so opening the picker does not transfer every icon across the platform channel.
3. Build `AppPickerScreen` with search, selected state, "Distracting apps" and "Always available" tabs, plus a visible essential-app exclusion list.
4. Exclude FlowOS, launcher, Settings, phone, emergency, and default SMS apps from selectable blockers by default. Let a person reclassify only non-critical apps.
5. Store selection in `protected_apps`. Do not infer selection from profile labels such as “Browser” or “Games.”
6. When a focus session begins, write a short-lived effective policy to native-readable SharedPreferences:

   ```text
   activeUntil, selectedPackages, protectionLevel, temporaryBreakUntil, source=focus|sleep
   ```

   The native service must stop enforcing when `activeUntil` passes, even if Flutter crashes.

7. Refactor `FocusBlockerService` to read this effective policy. When a selected app opens, it routes to the existing FlowOS shield with the app name, strictness, and remaining wait.
8. Implement three explicit behaviors:

   | Mode | Behavior |
   |---|---|
   | Nudge | No app interception; FlowOS records the event and offers a return cue. |
   | Guard | A selected app triggers the shield; after 20 seconds, the person may take a timed 5/10/15-minute break. |
   | Deep | A selected app triggers the shield; no temporary break is available before the session ends. |

9. Add a standalone disclosure immediately before opening Accessibility Settings. It must say that FlowOS detects the foreground app only to apply the person's selected focus/sleep rule, keeps this data on device, and can be disabled in Settings.

Google Play requires this kind of prominent disclosure, affirmative consent, policy declaration, and accurate listing documentation for non-accessibility-tool uses of `AccessibilityService`. [Google Play policy](https://support.google.com/googleplay/android-developer/answer/10964491)

**Acceptance:** selecting Instagram blocks Instagram but not Phone; removing Instagram from the list takes effect on the next session; a disabled Accessibility service shows “protection unavailable,” never “protected.”

### Milestone 2 — Rebuild onboarding and permission recovery

**Goal:** a clear, non-coercive first-run experience that produces a useful profile and asks permission with context.

Use four screens for a fresh install:

1. **Welcome to your Garden** — local-first promise, three-line explanation, Continue / Set up later.
2. **Shape your rhythm** — goal, preferred focus length, normal focus window, optional bedtime. Avoid requiring a fixed number of distractions.
3. **Choose what pulls you away** — Android app picker; iOS explains that app selection will be available after native Screen Time support ships.
4. **Connect FlowOS** — one permission card at a time:
   - Usage Access: selected-app screen time and score coverage.
   - Accessibility: selected-app shields during focus/sleep.
   - Notification Access: interruption counts by app, with no content collection.

Each card needs `Connect`, `Not now`, a concrete data explanation, and live status after returning from Android Settings. On a successful Usage Access grant, sync the last seven days immediately and show the first real screen-time summary. Do not block Home if someone declines.

Existing users receive a dismissible `Finish device setup` sheet rather than repeating onboarding. iOS must hide unavailable controls behind a capability flag; no “verify permission” button should appear until native authorization exists.

**Acceptance:** first-run completion does not require a sensitive permission; a declined permission can be enabled later; returning from Settings automatically updates status and triggers the correct sync.

### Milestone 3 — Sleep Mode and interruption metrics

**Goal:** offer a reliable night boundary without false promises or invasive data collection.

1. Add `SleepModeScreen`: bedtime, wake time, repeat days, selected-app preview, essentials, and strictness.
2. At bedtime, write the sleep policy into native-readable preferences. The Accessibility service checks it whenever a selected app enters the foreground; no exact-alarm permission is required merely to shield an app when opened.
3. At wake time, permit apps automatically and show a gentle Home return state. “All apps” means **all selected non-essential launchable apps**, never emergency/system apps.
4. Add Android `NotificationListenerService`; request Notification Access only after the person enables interruption insights.
5. In `onNotificationPosted`, persist only `{day, packageName, count + 1}`. Explicitly reject notification extras, title, text, sender, images, action buttons, and deep links.
6. Query daily `KEYGUARD_HIDDEN` events from UsageStats, dedupe timestamps, and persist the count. Label it **Phone unlocks**. Do not call it pickups.
7. Show interruption data only after a full day of coverage and make it removable from Settings with one “Delete interruption history” action.

Android's notification-listener API receives callbacks for posted/removed notifications; enabling it is sensitive, which is why FlowOS must retain only counts and package labels. [NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)

**Acceptance:** notification content never appears in SQLite/export logs; Android Settings revocation stops collection immediately; Sleep Mode never blocks essential apps; overnight schedules work across midnight and daylight-saving transitions.

### Milestone 4 — Daily, weekly, and monthly insight system

**Goal:** explain attention in a way that is actionable and honest.

Replace the existing score calculator with a coverage-aware `DailyScoreV2`:

| Pillar | Weight | Input |
|---|---:|---|
| Focus | 35% | Completed `actualMinutes` and quality, never planned duration |
| Intent | 25% | Completed priority tasks and daily intention |
| Attention | 25% | Selected distracting-app minutes versus personal budget |
| Care | 15% | Recovery, shutdown, and energy check-ins |

Implementation rules:

- When native usage is missing, omit the Attention pillar from the visible calculation and label the result **Incomplete**. Never award it 100 points.
- Before the configurable evening cutoff, call the number a **live score**, not a final grade.
- Notification and unlock counts inform insight narratives only; they are not direct penalties.
- Weekly and monthly score are weighted averages of days with valid coverage. Show `n of 7` or `n of 30` scored days beside every aggregate.
- Calculate potential reclaimable time as `sum(max(0, selected distracting minutes - daily budget))`; label it as potential, not proven savings.

Build the Insights screen around one period selector: **Today / 7 days / 30 days**.

| View | Visual | Required data |
|---|---|---|
| Today | Score ring with four tappable pillars; focus-vs-distraction timeline; selected-app impact list | Focus, task, attention coverage |
| Week | Seven-day score terrain; focus/distraction trend; top reclaimable app | Seven days of records |
| Month | Calendar heatmap; active-day average; protected minutes; attention budget trend | Thirty days or available history |
| Interruptions | Notification count by app and unlock trend, only on Android with consent | Notification + usage permissions |

Empty states must say precisely what is missing and offer the appropriate connection action. They must never display zero usage as a completed measurement.

**Acceptance:** manual and native usage never double count; every score explains its inputs; “potential reclaimable time” can be reproduced from shown data; no-data days do not lower weekly/monthly averages.

### Milestone 5 — Premium Home and Focus experience

**Goal:** remove the “stack of boxes and text” feel.

#### Home

1. Replace the current Hero card + separate Garden block + separate score card with `HomeGardenHero` as the first 45–55% of the viewport.
2. Use the existing code-native `HomeGardenScene` as the scene layer. The plant lives at the lower edge; its vitality controls light, leaf posture, water, and companion behavior.
3. Overlay only three compact elements: greeting/energy, live score, and primary `Start focus` action. The plant remains the visual focus.
4. Make plant tap start focus, companion tap start recovery, and a small icon open the full Garden. The rest of Home begins beneath a soft scene fade—not a bordered card.
5. Move rhythm, tasks, and attention details into a scrollable “today flow” below the hero with only interactive surfaces receiving borders/elevation.

#### Focus timer

1. Extract a shared `FocusTimerStage` used by Focus and Deep Work.
2. Use one large radial timer with a layered progress arc, task/seed label, discreet session state, and calm breathing glow.
3. Move sound selection into a bottom sheet; keep pause and end as two clear icon buttons with haptic confirmation.
4. During a session, animate only the timer pulse and a small Garden seed state. On completion, run the existing seed-to-growth transition before recovery.
5. Remove XP from the timer's main focal point; show it in the completion result instead.

#### Design system rules

- Use existing `AppColors`, `AppSpacing`, `AppTypography`, and `MotionTokens` as semantic tokens; add missing semantic names rather than scattering new literal colors.
- Use one large scene/section per viewport, no card inside a card, and at most one primary action per screen.
- Use gradient light, depth, subtle blurred glow, strong type scale, and motion to create hierarchy—not extra outlines.
- Respect `MediaQuery.disableAnimations`, minimum 44×44 touch targets, contrast requirements, and screen-reader semantics.

**Acceptance:** Home opens on a Garden scene rather than generic panels; Focus and Deep Work look like one product; reduced-motion mode remains complete and usable; screenshots show no nested generic card patterns.

### Milestone 6 — iOS Screen Time release gate

This milestone is blocked until the Account Holder has Apple Developer Program membership and Apple approves the required Family Controls distribution entitlement.

1. Register the host iOS app plus Device Activity Monitor, Device Activity Report, Shield Action, and Shield Configuration extensions.
2. Request Family Controls and App & Website Usage entitlements for the host and relevant extensions.
3. Implement FamilyControls authorization, app/category selection, ManagedSettings shields, DeviceActivity schedules, and App Group aggregate storage behind `iosScreenTimeEnabled`.
4. Mirror only features Apple permits: usage summaries, selected-app/category shielding, focus/sleep schedules, and shield actions.
5. Run authorization, selection, schedule, shield, revocation, and App Store build tests on physical devices before enabling the feature flag.

Until this succeeds, iOS remains a full Focus/Garden/manual-reflection app; it must not promise native device tracking, app blocking, notification count, or unlock count.

## 5. Library and asset decision

### Do not add a UI library by default

The project already includes the packages needed for the polished release:

| Existing package | Use in this plan |
|---|---|
| `flutter_animate` | Page entrances, scene transitions, score/timer micro-motion |
| `fl_chart` | Score trends, timelines, heatmaps, app impact charts |
| `shimmer` | Permission/data-loading skeletons only |
| `flutter_svg` | Optional branded vector icons/illustration layers |
| `confetti` | Completion only, never the core Garden animation |
| `flutter_local_notifications` | Sleep-start/wake and focus notifications |

Do **not** add `permission_handler`: it cannot grant Usage Access, Accessibility, Notification Access, or Apple Family Controls, so it would create a misleading abstraction. Do not add a third-party screen-time/blocking Flutter plugin; use native Kotlin/Swift bridges because policy, entitlement, and consent behavior must remain explicit and auditable. Do not add glassmorphism/card packages; the premium look comes from the existing theme tokens and composition.

### Required native work, not Flutter libraries

- Android: `UsageStatsManager`, `AccessibilityService`, `NotificationListenerService`, package-manager app picker, and Kotlin platform channel.
- iOS: `FamilyControls`, `ManagedSettings`, `DeviceActivity`, Screen Time extensions, and App Group storage after entitlement approval.

### Asset decision

No new Lottie, Rive, video, or 3D asset is required for this release. The current Home Garden is code-native and should remain so until the product language is proven.

Optional post-release polish may add a small **owned** SVG pack:

```text
assets/images/garden_scene/
  leaf.svg
  flower.svg
  firefly.svg
  water-drop.svg
  soft-grain.svg
```

Use it only if the Flutter `CustomPainter` scene needs more visual character. Every imported asset must have commercial rights documented in `assets/ASSET_LICENSES.md`. Do not download anonymous stock Lottie files or mix licenses into the app.

## 6. Verification checklist

### Automated

- Drift migration test: versions 3/4 upgrade to version 5 without data loss.
- Repository tests: source priority, no double counting, selected-app filtering, timezone/day boundary, permission revocation, and score coverage.
- Widget/golden tests: onboarding states, Home Garden vitality, score states, Insights period views, Focus timer, reduced motion, and accessibility semantics.
- Native bridge tests: Android permission status, app list, usage aggregation, unlock event parsing, and notification count-only storage.

### Real-device release checks

- Android: denied/granted/revoked permissions; app selector; selected/allowlisted app behavior; session end; timed break; sleep across midnight; device restart; Accessibility/notification listener disconnect.
- Google Play: prominent disclosure, Accessibility declaration, policy video, privacy policy, Data Safety form, and accurate store screenshots.
- iOS: physical-device entitlement, authorization, picker, shield, schedule, revoke, and distribution-profile validation before enabling the feature flag.

## 7. Completion definition

The release is complete when an Android user can select installed apps, grant only the permissions they understand, see real selected-app screen time, use a trustworthy coverage-aware score, inspect daily/weekly/monthly attention patterns, enter Sleep Mode, and return to an immersive Garden-first Home without the app claiming unsupported protection or measurements.

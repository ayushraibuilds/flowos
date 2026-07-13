# FlowOS: launch-ready focus and Garden plan

## Product direction

Garden remains FlowOS’s emotional center: focus grows a living landscape; recovery restores it; missed days become dormancy, never punishment. A small bird/butterfly companion adds warmth, but is not a second pet economy.

Research supports combining Forest’s immediate visual focus outcome with Opal-style configurable protection and transparent reports, while avoiding Forest’s “dead tree” guilt loop and metric-heavy streak pressure. [Forest](https://www.forestapp.cc/en/) [Opal](https://opalapp.com/help/what-is-opal) [Cape](https://getcape.app/)

Current issues to fix first:

- The MP3 assets are valid and already declared, but the normal Focus timer never starts `AmbientSoundPlayer`.
- “Forest” currently maps to a piano asset; relabel it as “Piano” until a licensed forest loop is added.
- Android has basic daily usage access, but no multi-day normalized screen-time store or real app shield.
- iOS has no Screen Time native bridge, entitlement, extensions, or capability.
- Onboarding blocks the first meaningful product moment: planting a seed.

## Implementation sequence

### 1. Trust, audio, and first-session experience

- Replace the onboarding redirect with direct entry to Home. Keep existing profile defaults silently, and move goals, distractions, and protected hours to an optional “Shape your focus” sheet in Settings/Home after the first session.
- Add a persistent Home `FirstSeedCard` until at least one saved session has recorded one or more focused minutes, whether completed fully or partially.
- The card opens Focus preconfigured for a 10-minute starter session, a task field, and a selected seed; it never auto-starts a timer.
- Extend focus navigation with a `FocusSessionConfig` containing duration, task, and seed type. Display that exact task and seed during the session; on completion, animate it into the Garden and replace the card with today’s live plot.
- Consolidate sound playback behind `FocusAudioController`:
  - Register only the five shipped audio files with accurate names.
  - Configure `audio_session` for music playback and configure looping with `just_audio`.
  - Start sound from both generic Focus and Deep Work only once a timer actually starts.
  - Pause while the session is paused, preserve position, resume in place, and fade/stop only when the session ends or is abandoned.
  - Handle phone-call/audio-focus interruptions safely; show a quiet “Sound paused by your device” state rather than failing silently.
  - Support background playback during an active session with the required iOS audio background mode and Android media playback service/notification; stop at timer end.
  - Keep playback fully local and show a visible unavailable state if an asset cannot load. [just_audio](https://pub.dev/packages/just_audio) [audio_session](https://pub.dev/packages/audio_session)

### 2. Make the Home Garden interactive and emotionally useful

- Commission/create one Rive scene at `assets/animations/garden_home.riv`; use a single state machine with `vitality`, `isFocusing`, `tend`, and `reducedMotion` inputs.
- The scene contains the existing plant/plot plus a secondary wildlife companion. Tapping the plant opens a focus starter; tapping the companion opens a two-minute recovery action.
- Add a derived `GardenVitality` view model, never a new gamification currency:
  - `flourishing`: focused today or balanced attention.
  - `growing`: first/partial focus has begun.
  - `thirsty`: known distracting usage exceeds the person’s selected budget; leaves droop gently but nothing dies.
  - `recovering`: water/light/recovery action is completed.
  - `resting`: no data, a missed day, or a quiet day; use dormancy and moonlight rather than decay.
- Only allow device usage to affect vitality after the user grants that permission. Missing, revoked, or unavailable data renders a neutral resting garden, not a negative judgment.
- Add a static Flutter fallback if the Rive asset cannot load, and honor reduced-motion settings by using a still illustration plus short opacity transitions.
- Preserve the existing daily plot, weekly landscape cards, and seasons. A completed day is a saved landscape, not a streak score.

### 3. Screen-time foundation, visualizations, and personalization

- Create a platform-neutral `DeviceUsageRecord` store separate from manual `ScrollLogs`: day, platform, source, package/token when permitted, display label/category, minutes, and sync time. Keep it local, allow deletion, and retain source metadata so manual and device data cannot be silently confused or double-counted.
- Expand the native platform contract to expose authorization state, last sync, daily/weekly usage summaries, selected protected apps, and platform limitations.
- Android:
  - Upgrade the existing UsageStats bridge from today-only totals to 1/7/30-day per-app and category summaries.
  - Explain it as foreground app usage—not a perfect device “screen-on” measurement—and show a permission-required state instead of zeroes.
  - Use targeted launcher-app discovery for app selection; avoid broad package inventory permissions.
  - `PACKAGE_USAGE_STATS` is the required usage-access path for aggregate app usage. [Android UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- iOS:
  - Make this entitlement-gated. Apply for Apple’s Family Controls and App & Website Usage entitlements before claiming iPhone tracking or blocking.
  - Add native FamilyControls, DeviceActivity, ManagedSettings, DeviceActivityReport, ShieldConfiguration, and ShieldAction targets behind a disabled feature flag until approval.
  - Once approved, let the person grant authorization, select apps/categories through Apple’s picker, and store only the permitted aggregate summaries in the shared App Group.
  - Until entitlement approval, iOS clearly offers manual logging and explains that native usage/shielding is unavailable—no fake analytics. [Apple Screen Time frameworks](https://developer.apple.com/documentation/ScreenTimeAPIDocumentation) [Family Controls entitlement](https://developer.apple.com/documentation/FamilyControls/requesting-the-family-controls-entitlement)
- Replace the current generic dashboard with source-labeled views:
  - daily focus versus distracting-use trend;
  - category/app breakdown;
  - hourly attention timeline;
  - seven-day focus/scroll correlation;
  - protection overrides and recovery actions;
  - a simple “attention budget” progress card.
- After seven days with sufficient data, generate only local, dismissible suggestions such as “your best focus window is 9–11 AM” or “try a recovery after 15 minutes of social use.” Never infer health, shame the person, or treat missing data as behavior.

### 4. Focus Protection Ladder with real resistance

- Preserve the existing in-app ladder and formalize three user-selected modes:

  | Mode | Behaviour |
  |---|---|
  | Reflect | Existing FlowOS interruption check and a 10-second intentional pause. |
  | Guard | Selected apps/sites are shielded; a 30-second reflection wait precedes a 5/10/15-minute planned break. |
  | Deep | Selected apps/sites remain shielded for the session; no temporary FlowOS override, only an explicit end-session choice. |

- Every mode has an editable essentials allowlist. Phone, emergency, and system-critical access are never represented as “blocked.”
- Android Guard/Deep uses a user-enabled `AccessibilityService` plus an accessibility overlay to detect a selected foreground app and show the native FlowOS shield. It must include a just-in-time consent screen, a privacy policy, Play Console declaration/demo, and an explicit explanation of exactly what is observed and why. It cannot prevent uninstalling or disabling the service, and the product must say so. Google permits this use only with clear disclosure/consent and prohibits bypassing system controls. [Google Play Accessibility policy](https://support.google.com/googleplay/android-developer/answer/16558241)
- iOS Guard/Deep uses ManagedSettings shields only after entitlement and user authorization; its shield/action extensions offer the same intentional-break wording within Apple’s extension constraints.
- Connect the existing browser extension to the same active focus policy through explicit user pairing, not hidden synchronization. Browser protection remains an optional companion to mobile protection.
- Add an `UnlockAttempt` log: platform, protected target/category, level, requested break length, optional intention, wait outcome, and session context. Use it for private reflection, not penalties.
- Update all privacy copy: remove the inaccurate promise that FlowOS does not access Screen Time/Digital Wellbeing APIs; replace it with what is collected, where it stays, how to revoke access, and how to delete it.

### 5. Unified visual system and launch polish

- Convert the current colors and repeated card styles into a single `FlowTheme`: semantic colors, typography scale, spacing, radii, elevation, garden gradients, status colors, and dark/light surface rules.
- Apply it first to Home, Focus, Deep Work, Garden, Insights/Attention Radar, protection settings, and all empty/loading/error states.
- Use calm 200–400 ms motion, one primary action per screen, consistent bottom sheets, accessible contrast, large touch targets, haptic confirmation for start/complete, and reduced-motion alternatives.
- Add an in-app Permission Center showing audio, usage, accessibility, and iOS Screen Time status with a plain-language “why,” revoke path, last sync, and limitation per platform.
- Maintain an asset provenance manifest for every sound and Rive asset: creator/source, license, attribution requirement, file checksum, and replacement policy.

## Validation and release gates

- Unit-test audio state transitions, asset registry integrity, first-seed completion criteria, Garden vitality derivation, data aggregation/deduplication, and protection-level rules.
- Add Drift migration tests preserving existing focus, Garden, and manual scroll records.
- Add integration tests for first launch, partial focus, full focus, timer completion, audio interruption, permission denial/revocation, timezone boundaries, and empty analytics.
- Test Android shields on real devices across selected apps, device restart, disabled accessibility service, allowed apps, and delayed break expiry.
- Test iOS usage/shields only on physical devices after entitlement approval; block the iOS release flag until authorization, reporting, and shield extensions work end to end.
- Run visual golden tests for Home, Focus, Garden states, analytics, and permission states in normal and reduced-motion modes.
- Release in order: trust/audio/first seed → interactive Garden and theme → Android usage analytics → Android shields → iOS entitlement-enabled analytics and shields.

## Assumptions and deliberate non-goals

- Defaults used: Rive Garden animation and an Android Accessibility-powered shield with explicit consent; these can be swapped before implementation.
- FlowOS remains local-first; cloud sync, social competition, real-tree donations, and a second reward economy are not part of this release.
- The strongest retention additions after launch should be a weekly reflection/landscape card and optional recurring focus rituals—not streak resets, dead plants, or punitive scores.

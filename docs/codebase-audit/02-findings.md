# FlowOS Codebase Audit — Findings

Findings are ordered by severity and expected value. Line references describe the audited snapshot and may move after implementation.

## FINDING-001 — Unverified JWT identity bypasses backend authentication

- Category: Security / authentication / backend cost control
- Severity: S0 — Critical
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: An unauthenticated caller can impersonate an arbitrary user identity and invoke paid Gemini endpoints, consume quota, and submit arbitrary content.
- Engineering impact: Authentication and per-user rate limiting cannot be trusted; incident attribution is unreliable.
- Evidence:
  - `backend/services/limiter.py:12-28` decodes a bearer token with `verify_signature: False`, reads `sub`, and writes it to `request.state.user_id`.
  - `backend/services/auth_service.py:21-39` returns `request.state.user_id` before verifying the supplied credentials.
  - `backend/routers/ai.py:54-55`, `118-119`, `173-174`, `209-210` apply the limiter and authentication dependency to every AI endpoint, creating the exploitable middleware/dependency sequence.
  - A direct local reproduction supplied an invalid credential plus `request.state.user_id = "forged-user"` and `get_current_user_id` returned `forged-user`.
- Root cause: Rate-limit identity and authenticated identity share mutable request state even though the former comes from an unverified token.
- Recommended correction: Never let the limiter establish authenticated state. Verify the JWT exactly once in the auth boundary, attach a distinct verified principal, and make the limiter use either that verified principal, a safe token digest, or IP fallback. Require Redis in multi-worker production if limits are intended to be global.
- Alternatives considered: Decoding an unverified token only for a rate-limit key is acceptable only if the value remains untrusted and cannot bypass authentication; the current shared state makes that alternative unsafe.
- Verification method: Endpoint tests must show a forged/unsigned/wrong-secret/expired token returns 401, a valid token succeeds, arbitrary `sub` values do not create trusted state, and rate-limit buckets cannot be reset by forging subjects.
- Related findings: FINDING-005, FINDING-020

## FINDING-002 — Local and queued sync data are not isolated by account

- Category: Security / privacy / data integrity / synchronization
- Severity: S0 — Critical
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: A second person signing into the same installation can see the prior person's local data. Unsynced mutations created under one account can be uploaded under another account.
- Engineering impact: The offline-first and multi-device consistency guarantees are invalid across account switches; remediation may require a data migration.
- Evidence:
  - `lib/features/auth/services/auth_service.dart:125-129` signs out of Supabase but does not switch, clear, or lock local storage.
  - `lib/presentation/screens/settings/settings_screen.dart:784-799` explicitly promises that local data is preserved across sign-out.
  - `lib/data/local/database/app_database.dart:49-69` defines one global set of tables with no account namespace/owner column.
  - `lib/data/local/tables/sync_outbox_table.dart:4-13` queues operations without an owner user ID.
  - `lib/features/sync/services/sync_engine.dart:35-47` keys sync cursors by table only, not by account.
  - `lib/features/sync/services/sync_engine.dart:284-355` maps queued records using the currently authenticated `_userId`, not the identity that created the operation.
  - Supabase RLS in `supabase/migrations/001_initial_schema.sql:30-34` and equivalent table policies protects cloud reads, but cannot detect a client that relabels a local row as the current user.
- Root cause: “Local profile” and “cloud account” are not modeled as separate identities, and ownership is assigned at upload time.
- Recommended correction: First make a product decision between one device-local profile, per-account local profiles, or a deliberate merge workflow. Then scope the database (or every account-owned row), outbox, cursors, and cached account state to an immutable owner. Block syncing if orphaned ownership is ambiguous.
- Alternatives considered: Clearing all local data on sign-out is simpler but contradicts the current product promise and can destroy unsynced work. A per-account database is easier to reason about than adding owner columns to every table, but needs careful migration and local-only mode handling.
- Verification method: Automated A→sign-out→B tests must prove no local visibility, cursor, or outbox crossover; offline rows must either stay with A or follow an explicit, confirmed merge workflow.
- Related findings: FINDING-011, FINDING-012, FINDING-015, FINDING-019

## FINDING-003 — Focus completion can execute twice and duplicate rewards

- Category: Correctness / state ownership / data integrity
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: A completed focus session can be finalized and rewarded twice, producing incorrect XP, achievements, garden growth, and sync events.
- Engineering impact: Completion has multiple owners and is not idempotent, making lifecycle and process-recovery behavior unsafe.
- Evidence:
  - `lib/features/focus/providers/focus_timer_provider.dart:471-494` calls `completeSession()` when the countdown reaches its target.
  - `lib/features/focus/providers/focus_timer_provider.dart:410-435` finalizes the database session and then publishes `FocusTimerPhase.completed`.
  - `lib/presentation/screens/focus/focus_screen.dart:368-375` listens for `completed` and calls `_onComplete`; `_onComplete` calls notifier `completeSession()` again at `305-320`.
  - `lib/presentation/screens/focus/deep_work_screen.dart:304-311` and `246-259` repeat the same sequence.
  - `lib/features/focus/providers/focus_timer_provider.dart:146-163` can also finalize during process rehydration before publishing `completed`.
  - `lib/features/xp/models/xp_calculator.dart:82-96` appends a new UUID ledger entry each time; `lib/data/local/tables/xp_ledger_table.dart:5-23` has no uniqueness rule for action plus source entity.
- Root cause: Timer/domain completion and UI celebration/navigation are coupled through a phase transition, but the UI repeats the domain mutation instead of consuming a stored result/effect.
- Recommended correction: Give the notifier/service sole ownership of finalization; expose a one-shot completion result for UI effects. Make session completion transactional and idempotent, and enforce XP uniqueness by source/action in storage.
- Alternatives considered: A UI-only `_isFinalizing` flag does not protect the notifier, rehydration, multiple screens, process death, or retry.
- Verification method: Fake-clock notifier/widget tests and a database constraint test must show timer expiry, repeated taps, rebuild, route switch, and rehydration produce one completion and one XP row.
- Related findings: FINDING-018

## FINDING-004 — Chosen focus-protection strictness is not applied

- Category: Correctness / platform policy / product trust
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: Gentle or Shield selections can behave as Guardrail, so the central protection promise does not match what the user selected.
- Engineering impact: Session state cannot faithfully restore native protection after pause, resume, or process death.
- Evidence:
  - `lib/features/focus/models/focus_protection.dart:31-40` maps the three UI levels to native `nudge`, `guard`, and `deep`.
  - `lib/features/focus/providers/focus_timer_provider.dart:231-249` accepts no protection mode and calls `FocusSessionService.startSession` without one.
  - `lib/features/focus/services/focus_session_service.dart:48-53` therefore uses its default `ProtectionMode.guard`.
  - `lib/features/focus/providers/focus_timer_provider.dart:355-372` explicitly recreates a Guard policy on resume and drops prior scoped breaks.
- Root cause: Protection mode is presentation/settings state rather than part of the persisted focus-session state machine.
- Recommended correction: Add the effective mode to timer state and persistence; pass it through start/service/policy activation; preserve it on pause, resume, lease renewal, rehydration, and sync-safe session transitions.
- Alternatives considered: Reading current settings on resume is insufficient because a running session should preserve the choice made at start.
- Verification method: Tests for Gentle/Guardrail/Shield must assert exact native policy payloads across start, pause, resume, background catch-up, and process rehydration.
- Related findings: FINDING-003, FINDING-017

## FINDING-005 — Flutter AI requests do not satisfy the backend auth contract

- Category: Correctness / authentication / networking
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: AI reports, suggestions, brain dump, and weekly review fail for both signed-in and local-only users, or expose confusing generic fallbacks.
- Engineering impact: Client and server contracts disagree; token refresh, 401 handling, and anonymous availability are undefined.
- Evidence:
  - `backend/routers/ai.py:54-55`, `118-119`, `173-174`, `209-210` requires `get_current_user_id` for every AI endpoint.
  - `lib/features/ai/services/ai_service.dart:19-29` creates Dio with only JSON content headers and never adds a bearer token.
  - UI call sites construct or consume `AiService` without injecting `AuthService`/a token-aware HTTP client.
  - The application intentionally supports local-only operation when Supabase is not configured or the user skips sign-in.
- Root cause: Authentication was added server-side without a coordinated client capability and product availability policy.
- Recommended correction: Provide a single Riverpod-owned Dio client that obtains/refreshed a Supabase token, serializes refresh, and normalizes 401/403/network/server failures. Explicitly disable or label cloud AI for local-only users unless a separate anonymous quota policy is approved.
- Alternatives considered: Anonymous AI endpoints would require abuse controls and a product/cost decision; embedding a Gemini key in Flutter is not acceptable.
- Verification method: Contract tests using valid, expired, missing, and forged tokens plus widget tests for logged-out, offline, and backend-unavailable states.
- Related findings: FINDING-001, FINDING-011, FINDING-020

## FINDING-006 — Mobile auth callback scheme is not registered

- Category: Correctness / authentication / navigation / release configuration
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: OAuth sign-in, signup confirmation, and password-reset flows may leave the app and fail to return.
- Engineering impact: Auth cannot be considered device-ready even if email/password tests pass.
- Evidence:
  - `lib/core/config/supabase_config.dart:34-36` defines `io.supabase.flowos://login-callback/`.
  - `lib/features/auth/services/auth_service.dart:68-72`, `88-108`, `118-122` uses it for signup, Apple, Google, and reset flows.
  - `android/app/src/main/AndroidManifest.xml` contains no `VIEW`/`BROWSABLE` intent filter for that scheme.
  - `ios/Runner/Info.plist` contains no `CFBundleURLTypes` registration.
  - `ios/Runner/GoogleService-Info.plist` is absent; external provider configuration could not be verified.
- Root cause: Dart auth implementation was not completed with platform URL routing and provider-console configuration.
- Recommended correction: Register an exact, minimally scoped callback on Android and iOS, validate route/state handling, document Supabase/provider settings, and test cold/warm app callback cases.
- Alternatives considered: Universal/App Links improve domain trust but require owned-domain configuration; a custom scheme is acceptable if OAuth state/PKCE is correctly enforced.
- Verification method: Physical-device signup, Google, Apple, password-reset, cancel, invalid-state, warm-start, and cold-start matrix.
- Related findings: FINDING-011, FINDING-017

## FINDING-007 — Known divergent installed databases have no repair path

- Category: Database / migration / reliability
- Severity: S1 — High
- Urgency: Now
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: Upgrading users can be locked out of Tasks, Profile, achievements, and other database-backed screens instead of receiving a data-preserving recovery.
- Engineering impact: Schema version alone is assumed to reflect physical schema state; partial or historically divergent migrations cannot self-heal.
- Evidence:
  - `lib/data/local/database/app_database.dart:97-200` applies sequential `addColumn`/`createTable` operations based only on `user_version`.
  - No `beforeOpen` schema validation, idempotent column check, corruption quarantine, or repair migration is present.
  - Existing migration coverage is limited and does not provide fixtures for each shipped schema or a partially migrated schema.
  - Prior supplied device evidence showed `duplicate column name: notification_observed_from` and `duplicate column name: source`, the exact columns added at `app_database.dart:121-123` and `136-138`.
- Root cause: The migration system covers ideal version transitions but not previously shipped schema drift or interrupted/incorrect version bookkeeping.
- Recommended correction: Capture anonymized schema manifests from affected installs, add real database fixtures for every shipped version, and implement a one-time data-preserving repair migration that inspects physical columns/tables. Provide a last-resort export/quarantine path rather than deleting silently.
- Alternatives considered: Uninstall/clear-data fixes the crash but destroys local-first user data and is not acceptable as the production strategy.
- Verification method: Upgrade fixture matrix, including the observed duplicate-column states, with row-count/content assertions and idempotent reopen.
- Related findings: FINDING-017, FINDING-019

## FINDING-008 — Reminder scheduling uses UTC as the device timezone

- Category: Correctness / date-time / notifications
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: User-selected local reminder hours fire offset by the device's UTC difference; at UTC+05:30, a nominal 09:00 reminder is built for 09:00 UTC.
- Engineering impact: Every recurring schedule based on `tz.local` is unreliable outside UTC and across timezone travel.
- Evidence:
  - `lib/features/notifications/services/notification_service.dart:48-54` initializes timezone data and explicitly sets the local location to `UTC`.
  - The same service constructs energy, report, weekly, and streak schedules with `tz.local`, including `241-242` and `278-279`.
- Root cause: Device timezone discovery was replaced with a fixed fallback that is treated as authoritative.
- Recommended correction: Obtain the IANA timezone from a supported native/plugin path, use a documented fallback only on failure, and reschedule when the timezone or relevant preference changes.
- Alternatives considered: Scheduling raw local `DateTime` values avoids the fixed UTC bug but handles DST/reboot recurrence less reliably than correct timezone-aware schedules.
- Verification method: Fake timezone tests for UTC, Asia/Kolkata, America/New_York DST boundaries, and a device travel/reschedule test.
- Related findings: FINDING-013, FINDING-017

## FINDING-009 — Android release signing falls back to the debug key

- Category: Security / release engineering
- Severity: S1 — High
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: A release artifact can be signed with a publicly known debug credential, preventing a safe production identity and potentially causing irreversible update-channel problems.
- Engineering impact: Missing release secrets do not fail the build, so CI or a developer can produce a misleading “release” artifact.
- Evidence:
  - `android/app/build.gradle.kts:36-51` loads `key.properties` but explicitly copies the debug signing configuration when the file is absent.
  - `android/app/build.gradle.kts:57-58` assigns that configuration to the release build type.
  - `android/key.properties` was absent during the audit.
- Root cause: Developer convenience is implemented as a release fail-open rather than a separate local build mode.
- Recommended correction: Make release signing fail closed, use Play App Signing/managed CI secrets, and keep any locally debug-signed artifact explicitly named/configured as non-release.
- Alternatives considered: A debug fallback may be retained for a dedicated benchmark/internal build type, never the production `release` variant.
- Verification method: A release build without credentials must fail with a clear message; CI/authorized signing must produce the expected certificate fingerprint.
- Related findings: FINDING-019

## FINDING-010 — Static analysis gate fails and includes a real unreachable comparison

- Category: Correctness / developer experience / CI
- Severity: S2 — Medium
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: The deep-work timeline can be classified/rendered incorrectly; other warnings increase the chance of lifecycle regressions.
- Engineering impact: The repository's own CI `flutter analyze` step cannot pass, so it does not protect `main`.
- Evidence:
  - `flutter analyze` exited 1 with 77 issues.
  - `lib/features/insights/widgets/focus_session_timeline.dart:95` compares an enum-valued `sessionType` with the string `'deepWork'`; analysis reports unrelated-type equality.
  - `lib/features/reports/services/daily_action_engine.dart:2`, `weekly_action_engine.dart:2`, and `lib/features/rhythm/services/rhythm_engine.dart:2` import `crypto` although it is not declared directly in `pubspec.yaml`.
  - Analysis also reported stale async-context use, unused code/imports, deprecated APIs, and invalid mock overrides.
  - `.github/workflows/flutter_ci.yml` runs `flutter analyze` without an exception baseline.
- Root cause: Refactors and generated/mock changes were merged without restoring the static-analysis contract.
- Recommended correction: Fix correctness and dependency errors first, then mechanically clean warnings in bounded feature slices. Keep analysis at zero issues rather than suppressing broad categories.
- Alternatives considered: Relaxing CI or globally excluding warnings would hide the enum defect and is not recommended.
- Verification method: `flutter analyze` exits 0 and a timeline test proves a deep-work session follows the deep-work rendering branch.
- Related findings: FINDING-018, FINDING-019, FINDING-021

## FINDING-011 — Auth and router state have competing, partly stale sources

- Category: Architecture / state management / navigation
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: Login/logout UI and redirects can lag or disagree after auth transitions.
- Engineering impact: Auth behavior is hard to test because some consumers watch a stream, others read a nonreactive singleton, and routing uses module globals.
- Evidence:
  - `lib/features/auth/services/auth_service.dart:21-35` defines a reactive `authStateProvider`, but `currentUserProvider` does not watch it; `isLoggedInProvider` only watches `currentUserProvider`.
  - `lib/presentation/navigation/app_router.dart:43-62` stores onboarding state and router refresh objects globally.
  - `RouterRefreshListenable` creates an auth stream listener whose subscription is not retained/disposed.
  - settings and sync providers consume different pieces of this state.
- Root cause: Authentication, onboarding, and router refresh evolved independently instead of sharing one provider-owned session state.
- Recommended correction: Model session/onboarding readiness in a provider-owned app-session state, derive user/login selectors from the auth stream, and give the router a disposable, testable refresh dependency.
- Alternatives considered: Manually invalidating providers at every sign-in/out call is fragile and misses token expiry or external auth events.
- Verification method: Router/provider tests for login, logout, token refresh, local-only mode, onboarding completion, and account switch without manual invalidation.
- Related findings: FINDING-002, FINDING-005, FINDING-006

## FINDING-012 — Sync lacks robust cancellation, retry, and partial-failure behavior

- Category: Networking / offline behavior / reliability
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: A transient table failure can abort a full sync, status is coarse, and recovery may wait for a later trigger without clear feedback.
- Engineering impact: Sync is difficult to reason about under backgrounding, auth changes, concurrent mutation, and partial server failure.
- Evidence:
  - `lib/features/sync/services/sync_engine.dart` wraps the full multi-table cycle in broad orchestration rather than isolating retryable table failures.
  - `schedulePush()` launches a later `fullSync()` without a cancellation token tied to auth/account lifecycle.
  - Sync status exposes a general error string but not per-table progress/retry disposition.
  - Pagination and existing-row updates are present, so the earlier fixed-limit/session-pull defects are no longer current findings.
- Root cause: Correctness work improved cursors and mappings, but the engine still behaves as a monolithic app-lifetime job.
- Recommended correction: After account ownership is fixed, serialize one sync per account, cancel on account change, use bounded exponential backoff for retryable failures, persist safe high-water marks, and report partial state without advancing failed cursors.
- Alternatives considered: Retrying the entire cycle is simpler but increases load and can repeat otherwise successful work.
- Verification method: Deterministic fake-backend tests for mid-page failure, 401, timeout, app background, account switch, concurrent local mutation, retry, and restart.
- Related findings: FINDING-002, FINDING-011, FINDING-020

## FINDING-013 — Nonessential initialization delays the first frame

- Category: Performance / startup / lifecycle
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: Cold startup can feel slow, especially while notification plugins and platform storage initialize.
- Engineering impact: Unrelated startup failures are coupled before the widget tree exists.
- Evidence:
  - `lib/main.dart:20-75` serially initializes the notification plugin, schedules four recurring notification groups, loads preferences, resolves the documents directory, checks the database file, initializes a device ID, and initializes Supabase before `runApp`.
  - Four schedule methods perform persistence/plugin work even when no immediate frame depends on it.
- Root cause: Bootstrap distinguishes required setup poorly from post-frame maintenance.
- Recommended correction: Measure startup, keep only framework/configuration prerequisites before `runApp`, and schedule idempotent notification maintenance after the first frame or through a background-ready coordinator.
- Alternatives considered: Blind parallelization can create plugin/order races; the work should first be classified and instrumented.
- Verification method: Trace cold-start first-frame time before/after and test degraded notification/Supabase initialization without blocking local UI.
- Related findings: FINDING-008, FINDING-020

## FINDING-014 — Reactive garden aggregation can overlap and performs repeated queries

- Category: Performance / state consistency / database
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 8/10
- Status: HIGH CONFIDENCE
- User impact: Bursts of writes can cause delayed or briefly stale garden/week updates and unnecessary battery/database work.
- Engineering impact: Multiple consumers can independently rebuild an entire week, and earlier asynchronous builds can publish after newer ones.
- Evidence:
  - `lib/features/flow_garden/services/garden_service.dart:194-251` listens to broad table updates and launches asynchronous `buildDay`/`buildCurrentWeek` work without serialization, debounce, switch-map, or generation guards.
  - `buildCurrentWeek` at `184-191` builds seven days.
  - `buildDay` performs multiple queries and per-session task resolution, multiplying work for each table event.
  - The old 12-second polling implementation is no longer present; reactive Drift updates are a verified improvement.
- Root cause: The service changed its trigger mechanism without introducing a shared, coalesced derived-data pipeline.
- Recommended correction: Measure query/event frequency, share one cached stream per scope, coalesce bursts, discard stale generations, and batch task/session reads.
- Alternatives considered: Returning to polling would reduce event bursts but reintroduce latency and idle battery work.
- Verification method: Instrumented DAO tests assert bounded query counts and latest-write-wins emission order during a burst.
- Related findings: FINDING-013, FINDING-018

## FINDING-015 — “Backup” export omits sensitive and product-critical tables

- Category: Data portability / privacy / UX
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 10/10
- Status: CONFIRMED
- User impact: A user can believe they backed up FlowOS while losing screen-time history, app protection choices, sleep schedules, notification metrics, unlocks, and daily scores.
- Engineering impact: Export version 1 has no declared completeness/restore contract and shares a large raw JSON body directly.
- Evidence:
  - `lib/features/export/services/data_export_service.dart:16-39` exports nine tables only.
  - `lib/data/local/database/app_database.dart:49-69` contains 18 tables, including omitted device usage, unlock attempts, protected apps, device metrics, sleep schedules, notification counts/batches, daily scores, and outbox.
  - `data_export_service.dart:44-49` labels the shared raw text `FlowOS Backup Data`; no restore implementation, encryption, file lifecycle, or schema manifest is shown.
- Root cause: An early diagnostic/export helper is presented as a complete backup.
- Recommended correction: Decide whether this is a human-readable export or restorable backup. Version and document the schema, include or explicitly exclude each dataset, omit internal outbox state, generate a controlled file, and warn before sharing sensitive attention data.
- Alternatives considered: Renaming it “Export selected data” is a safe short-term correction if complete restore is not planned.
- Verification method: Fixture-based export manifest tests, restore round-trip if promised, large-dataset test, and privacy copy review.
- Related findings: FINDING-002, FINDING-016

## FINDING-016 — Android backup policy for attention data is implicit

- Category: Privacy / platform configuration
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 8/10
- Status: HIGH CONFIDENCE
- User impact: Tasks, usage, notifications, unlock behavior, policies, and preferences may follow Android's default backup behavior without an explicit user-facing retention decision.
- Engineering impact: Backup/restore can reintroduce stale preferences and database mismatches; compliance expectations are unclear.
- Evidence:
  - `android/app/src/main/AndroidManifest.xml` does not explicitly set `android:allowBackup`, `android:dataExtractionRules`, or legacy full-backup rules.
  - The app stores device-attention and protection data in SQLite and SharedPreferences.
  - `lib/main.dart:45-52` already removes selected restored preferences when no database file exists, showing that partial platform restore is a known state.
- Root cause: Sensitive-data backup eligibility and restore consistency were not designed as one policy.
- Recommended correction: Obtain product/privacy guidance, define included/excluded stores for Android 12+ and older devices, document behavior, and test restore combinations.
- Alternatives considered: Disabling all backup is safer operationally but removes user convenience; selective encrypted/cloud sync may better match the product.
- Verification method: Manifest/config inspection plus Android backup/restore tests for clean install, database-only, preferences-only, and both.
- Related findings: FINDING-007, FINDING-015

## FINDING-017 — Critical platform and cross-layer flows have no executable integration suite

- Category: Testing / release readiness
- Severity: S2 — Medium
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: Permission setup, focus blocking, upgrades, auth callbacks, and account switching can regress while all unit/widget tests remain green.
- Engineering impact: 154 passing tests create confidence mainly in isolated Dart behavior, not the highest-risk system boundaries.
- Evidence:
  - 31 Dart test files exist, but root `integration_test/` contains no runnable test.
  - No Android instrumentation test suite covers method channels or accessibility/notification services.
  - Current CI runs only `flutter analyze` and `flutter test`.
  - Backend tests do not exercise a forged token through a real FastAPI endpoint.
  - Migration coverage does not include every shipped database or the observed divergent schemas.
- Root cause: Milestone implementation emphasized unit/widget completion while platform contract and upgrade fixtures remained manual.
- Recommended correction: Build a small, high-value integration matrix rather than a broad fragile suite: database upgrades, focus completion/protection payloads, account switch/sync, backend auth, auth callback routing, and Android permission/service smoke tests.
- Alternatives considered: Manual QA remains necessary for OEM behavior but cannot replace deterministic regression tests.
- Verification method: CI runs the platform-independent integration layer; release checklist records passing physical-device matrix for platform-only flows.
- Related findings: FINDING-001 through FINDING-009

## FINDING-018 — Large screens combine UI, navigation, and domain side effects

- Category: Architecture / maintainability / testability
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 10/10
- Status: CONFIRMED
- User impact: Visual and lifecycle changes are more likely to break timer, data, or navigation behavior.
- Engineering impact: Reviews are broad, widgets are hard to test in isolation, and duplicated focus/deep-work logic has already produced a correctness defect.
- Evidence:
  - Non-generated line counts include settings 1,134; focus 968; scroll tracker 808; insights 776; home garden scene 677; tasks 616; home 610; onboarding connect 609; weekly review 604; daily report 597; morning intention 593; sleep mode 571; deep work 564.
  - Focus and deep-work screens duplicate completion, audio, shield, and routing coordination.
  - Settings owns account, permissions, data export/deletion, appearance, notifications, and navigation actions in one file.
- Root cause: Features were added vertically into existing screens without extracting stable presentation sections or moving effects to coordinators.
- Recommended correction: Refactor only after correctness state ownership is fixed. Extract pure widgets first, then shared focus presentation/effects, then settings sections with explicit callbacks. Avoid a repository-wide rewrite.
- Alternatives considered: File length alone is not a reason to split; extraction should follow responsibility and test seams, not arbitrary line targets.
- Verification method: Characterization tests before extraction, focused widget tests after, no navigation/domain mutations in pure components, and unchanged golden/device behavior.
- Related findings: FINDING-003, FINDING-004, FINDING-010, FINDING-014

## FINDING-019 — Application dependency resolution is not reproducible

- Category: Build / dependency health / release engineering
- Severity: S2 — Medium
- Urgency: Now
- Confidence: 10/10
- Status: CONFIRMED
- User impact: A clean CI or developer environment can resolve different compatible package versions and produce different behavior.
- Engineering impact: Rollbacks, bisects, audits, and generated plugin configuration are less deterministic.
- Evidence:
  - `.gitignore:10` ignores `pubspec.lock`.
  - `pubspec.lock` exists locally but `git ls-files pubspec.lock` returns no tracked file.
  - This repository is an application (`publish_to: none`), where committing the lockfile is the normal reproducibility boundary.
  - Flutter also warns that Kotlin 1.9.24 support will soon be dropped.
- Root cause: Library-package ignore conventions were applied to an application repository.
- Recommended correction: Review the current resolved graph, commit the lockfile, define controlled dependency-update cadence, and separately plan the Kotlin/Gradle compatibility update.
- Alternatives considered: Ignoring a lockfile is appropriate for some reusable packages, not for a deployable app with native plugins.
- Verification method: Two clean checkouts resolve identical versions and pass analyze/test/build; dependency updates are explicit diffs.
- Related findings: FINDING-007, FINDING-009, FINDING-010, FINDING-021

## FINDING-020 — Error handling and observability lose actionable context

- Category: Reliability / observability / supportability
- Severity: S2 — Medium
- Urgency: Next
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: Failures often appear as generic fallback/absence, making setup and recovery confusing.
- Engineering impact: Production diagnosis cannot reliably distinguish permission, auth, network, database, or policy failures.
- Evidence:
  - Broad `catch (_) {}` paths exist in focus policy resume and several platform/repository calls.
  - `lib/main.dart:24-33` captures Flutter framework errors but does not install a `PlatformDispatcher.onError` or zone boundary for all unhandled asynchronous errors.
  - Sentry is disabled when no DSN is supplied and application-level failures are primarily `debugPrint`.
  - Sync exposes coarse error state rather than normalized per-domain failures.
- Root cause: Individual milestone fallbacks were optimized for “do not crash” without a shared error taxonomy, structured diagnostics, or user recovery contract.
- Recommended correction: Define typed failures at platform/network/storage boundaries, log structured redacted context, capture unhandled async errors, and provide user-visible recovery for permission/auth/offline/database cases.
- Alternatives considered: Logging every caught exception at high severity would create noise and privacy risk; expected fallbacks need typed levels and sampling.
- Verification method: Fault-injection tests and a staging Sentry/support-bundle review confirm useful, redacted context and correct user messaging.
- Related findings: FINDING-001, FINDING-005, FINDING-007, FINDING-012, FINDING-013

## FINDING-021 — Unused dependencies and broad font assets increase build surface

- Category: Dependency health / package size / cleanup
- Severity: S3 — Low
- Urgency: Later
- Confidence: 9/10
- Status: HIGH CONFIDENCE
- User impact: Potentially larger downloads and slower dependency/native build work; exact release-size impact is not yet measured.
- Engineering impact: More transitive packages and native plugin configuration must be maintained and audited.
- Evidence:
  - No `package:` imports were found under `lib/` or `test/` for `rive`, `google_fonts`, `shimmer`, `percent_indicator`, `flutter_svg`, `dynamic_color`, `google_sign_in`, `sign_in_with_apple`, or the `haptic_feedback` package.
  - `pubspec.yaml:81-103` declares both entire `assets/fonts/` and `assets/fonts/ttf/` directories while registering only six Inter/JetBrains Mono files.
  - `assets/fonts` contains 70 files and is about 17 MB; all assets are about 29 MB.
  - Two ignored APKs make `test/` about 477 MB, although they do not ship or enter Git.
- Root cause: Experiments and asset families accumulated without a measured dependency/asset budget.
- Recommended correction: Build an analyze-size baseline, remove only proven-unused dependencies/assets in small batches, and store large manual artifacts outside `test/`.
- Alternatives considered: Retaining a package for an imminent approved feature is reasonable if documented; do not remove by search result alone without checking generated/platform references.
- Verification method: Release analyze-size comparison, full build/tests, and asset-loading smoke test.
- Related findings: FINDING-019

## FINDING-022 — Localization, accessibility, and responsive behavior lack a system-level baseline

- Category: Accessibility / internationalization / UI quality
- Severity: S3 — Low
- Urgency: Later
- Confidence: 8/10
- Status: HIGH CONFIDENCE
- User impact: Large text, screen readers, landscape/tablet layouts, RTL, and non-English users may receive degraded or inaccessible experiences.
- Engineering impact: Hard-coded copy and screen-specific sizing make future localization and responsive changes expensive.
- Evidence:
  - No ARB/localization generation setup exists.
  - A targeted search found hundreds of obvious hard-coded user-facing string literals.
  - Large custom-painted and gesture-driven surfaces, including the shell navigation and garden/focus controls, do not have a repository-wide semantics test baseline.
  - Several screens use substantial fixed dimensions and were not covered by golden tests across text scale/device sizes.
- Root cause: Visual product work advanced without an explicit localization/accessibility/responsive acceptance matrix.
- Recommended correction: Start with critical journeys and shared components: semantic roles/labels, 48 dp targets, text scales, contrast, small/tablet layouts, then extract localization keys by feature. Obtain design/product language scope before broad conversion.
- Alternatives considered: A repository-wide localization rewrite now would distract from release blockers; phased shared-component coverage gives better leverage.
- Verification method: Semantics/widget tests, Android TalkBack and iOS VoiceOver passes, text scale 1.0–2.0, small phone/tablet/landscape goldens, and an RTL smoke locale.
- Related findings: FINDING-018, FINDING-021

## Verified concerns that are already addressed

These items were investigated and should not be reopened as current defects without new evidence:

- `FocusBlockerService.kt:21-46`, `176-230` caches parsed policy and essential-package state and refreshes it on a background executor.
- `MainActivity.kt:31-33`, `139-159`, `502-528` loads app icons on an IO coroutine, coalesces in-flight requests, and caches bytes.
- `GardenService.watchToday/watchCurrentWeek` uses Drift table-update streams rather than fixed 12-second polling.
- `backend/main.py:59-80` uses a development origin regex and requires explicit production CORS origins.
- AI prompt rendering no longer contains the previously reported inline `.format()` conditional; backend prompt tests pass.
- Sync pull uses pagination/composite cursors and updates existing records; the prior fixed-limit and insert-only session problems are not present in the audited engine.


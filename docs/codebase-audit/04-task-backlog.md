# FlowOS Implementation Task Backlog

All effort estimates are relative. Every completed task requires independent `REASONING_MODEL` verification against the actual diff and tests.

## TASK-001 — Separate verified authentication from rate-limit identity

- Source findings: FINDING-001, FINDING-005
- Objective: Make every paid backend endpoint reject forged credentials and use a safe, globally enforceable rate-limit key.
- Priority: Now
- Severity: S0 — Critical
- Effort: S
- Scores: user impact 9/10; security/reliability 10/10; leverage 10/10; implementation risk 7/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-002, TASK-003, TASK-008, TASK-009, TASK-010
- Depends on: None
- Blocks: TASK-005, production AI endpoints
- Suggested branch: `codex/task-001-backend-auth-boundary`
- Likely files: `backend/services/limiter.py`, `backend/services/auth_service.py`, `backend/main.py`, `backend/tests/`
- Do not modify: Flutter UI, prompt content, Gemini response schemas
- Context: The limiter puts an unverified `sub` on `request.state.user_id`; auth trusts it.
- Detailed implementation steps:
  1. Reproduce the bypass through a FastAPI endpoint test, not only a direct function call.
  2. Remove any auth-service trust in limiter-created state.
  3. Verify signature, algorithm, expiry, audience, issuer, and subject in one auth boundary.
  4. Key limits by a verified principal when available and a safe fallback otherwise; never mutate authenticated state in the key function.
  5. Require/document Redis for multi-worker production limits and fail configuration checks appropriately.
- Acceptance criteria:
  - [ ] Forged, unsigned, expired, wrong-audience, and wrong-issuer tokens return 401.
  - [ ] A valid Supabase-shaped token reaches the endpoint.
  - [ ] Changing an unverified `sub` cannot bypass auth or create trusted request state.
  - [ ] Production multi-worker rate-limit storage expectations are explicit.
- Required tests:
  - [ ] FastAPI endpoint auth matrix
  - [ ] Rate-limit key tests with valid/invalid/missing tokens
  - [ ] Regression test for the exact request-state bypass
- Required commands: `backend/.venv/bin/python -m unittest discover -s backend/tests -v`; backend static/type checks if configured
- Edge cases: missing secret; key rotation/JWKS strategy; malformed header; absent client IP; Redis unavailable
- Rollback strategy: Revert the isolated backend change; keep endpoints disabled rather than restoring the bypass.
- Risks: Supabase may use asymmetric/JWKS signing in the target environment; verify actual production token configuration.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-002 — Establish account-scoped local storage and sync ownership

- Source findings: FINDING-002, FINDING-011, FINDING-012, FINDING-015
- Objective: Ensure every local row, queued operation, cursor, and sync run has unambiguous ownership across local-only mode and account switches.
- Priority: Now
- Severity: S0 — Critical
- Effort: XL
- Scores: user impact 10/10; security/reliability 10/10; leverage 10/10; implementation risk 10/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-001 and TASK-003; schema design must coordinate with TASK-007
- Depends on: Product answer OPEN-001
- Blocks: TASK-012, TASK-015, safe multi-account release
- Suggested branch: `codex/task-002-account-isolation`
- Likely files: Drift tables/database/migrations/DAOs, `sync_outbox_table.dart`, `sync_engine.dart`, auth/settings flows, SharedPreferences key helpers, tests
- Do not modify: scoring formulas, garden rules, unrelated visual design
- Context: One database is preserved at sign-out; outbox and cursors have no owner; upload applies the current user ID.
- Detailed implementation steps:
  1. Produce an architecture decision record for per-account databases versus owner columns plus a device-local profile.
  2. Add immediate containment: block account switching/sync when unresolved queued data belongs to another identity.
  3. Add immutable owner identity to the selected storage boundary, outbox, cursors, and scheduled sync jobs.
  4. Create a data-preserving migration for existing local-only and first-account data with an explicit claim/merge decision.
  5. Make sign-in/out switch storage scope atomically and cancel the prior user's work.
  6. Test two accounts, local-only mode, offline writes, reinstall/restore, and interrupted migration.
- Acceptance criteria:
  - [ ] Account B cannot query or render Account A's account-owned data.
  - [ ] An outbox row created for A can never be uploaded with B's user ID.
  - [ ] Cursors and last-sync timestamps are account-scoped.
  - [ ] Existing local data is neither silently deleted nor silently assigned to the wrong user.
  - [ ] Sign-out copy accurately describes retention.
- Required tests:
  - [ ] A→logout→B integration test
  - [ ] Offline queue/account-switch test
  - [ ] Existing local-only data migration test
  - [ ] Interrupted migration/reopen test
- Required commands: `dart run build_runner build --delete-conflicting-outputs`; targeted migration/sync tests; `flutter analyze`; `flutter test`
- Edge cases: anonymous-to-account claim; account deletion; same account returning; pending deletes; partial sync; Android backup restore
- Rollback strategy: Feature-gate cloud sync and preserve a read-only copy of pre-migration data; never downgrade a migrated DB blindly.
- Risks: Highest-risk task in the plan; schema and product ownership decisions can cause data loss if rushed.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-003 — Make focus completion transactional and idempotent

- Source findings: FINDING-003, FINDING-018
- Objective: Guarantee exactly one domain completion, XP award, achievement evaluation, garden growth result, and completion sync event per session.
- Priority: Now
- Severity: S1 — High
- Effort: M
- Scores: user impact 10/10; security/reliability 9/10; leverage 10/10; implementation risk 8/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-001, TASK-002 design, TASK-008; coordinate with TASK-004
- Depends on: None
- Blocks: TASK-017 and focus release
- Suggested branch: `codex/task-003-idempotent-focus-completion`
- Likely files: timer provider/state, focus session service/DAO, XP ledger/table/DAO, focus/deep-work screens, focus tests
- Do not modify: protection strictness behavior except shared state compatibility; visual redesign
- Context: Timer expiry completes in the notifier; both screens call completion again after receiving `completed`.
- Detailed implementation steps:
  1. Add a failing notifier+widget regression that traces the current double call.
  2. Define the notifier/service as sole mutation owner and a one-shot immutable completion result/effect for UI.
  3. Guard database completion with a transaction and completed-state compare/update.
  4. Enforce XP idempotency by action/source identity and handle an existing duplicate safely.
  5. Make rehydration and Flowtime manual completion use the same operation.
  6. Remove domain completion calls from UI listeners; retain celebration/navigation only.
- Acceptance criteria:
  - [ ] Timer expiry, repeated tap, rebuild, route switch, and rehydration each produce one completion.
  - [ ] UI receives the original XP/garden/achievement result exactly once.
  - [ ] Repeating completion is a safe no-op or returns the persisted result.
  - [ ] No completed session is accidentally converted to stopped.
- Required tests:
  - [ ] Fake-clock countdown expiry widget test
  - [ ] Rehydration and Flowtime tests
  - [ ] XP uniqueness/transaction test
  - [ ] Focus and deep-work UI effect tests
- Required commands: targeted focus/XP tests; `flutter analyze`; `flutter test`
- Edge cases: app killed at expiry; completion during sync; daily XP cap; zero-minute custom session; database exception after session update
- Rollback strategy: Revert state/effect changes together; retain the new idempotency constraint if compatible.
- Risks: Transaction boundaries across achievement/garden services may require a persisted completion receipt.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-004 — Persist and honor the selected focus-protection mode

- Source findings: FINDING-004
- Objective: Apply Gentle, Guardrail, or Shield exactly as selected throughout the session lifecycle.
- Priority: Now
- Severity: S1 — High
- Effort: M
- Scores: user impact 10/10; security/reliability 9/10; leverage 9/10; implementation risk 7/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Backend tasks; coordinate edits with TASK-003
- Depends on: Timer-state compatibility decision in TASK-003
- Blocks: focus protection release, TASK-017
- Suggested branch: `codex/task-004-protection-mode-state`
- Likely files: focus timer state/provider, session service, policy models/writer, focus setup UI, SharedPreferences serialization, tests
- Do not modify: Android strictness semantics or sleep precedence unless a test proves necessary
- Context: Start omits the mode; service defaults to Guard; resume hard-codes Guard.
- Detailed implementation steps:
  1. Add the effective native mode to persisted timer state with a backward-compatible default.
  2. Pass the chosen UI level into timer start and session/policy activation.
  3. Reuse the stored mode and scoped breaks on pause/resume, lease renewal, and rehydration.
  4. Decide how settings changes affect an already running session; default to preserving start-time choice.
  5. Add payload-level tests for all modes and lifecycle transitions.
- Acceptance criteria:
  - [ ] Gentle writes `nudge`, Guardrail writes `guard`, Shield writes `deep`.
  - [ ] Pause/resume and process restart preserve the initial choice.
  - [ ] Scoped package breaks survive only where policy allows.
  - [ ] Legacy persisted sessions receive a documented safe default.
- Required tests:
  - [ ] Three-mode start tests
  - [ ] Pause/resume/rehydration payload tests
  - [ ] Legacy JSON state test
- Required commands: targeted focus/policy tests; `flutter analyze`; `flutter test`
- Edge cases: no protected apps; accessibility disabled; sleep policy stricter; settings changed mid-session
- Rollback strategy: Retain compatible state parsing and fall back to Guard only for legacy sessions.
- Risks: Must not weaken active sleep protection or restore expired scoped breaks.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-005 — Implement an authenticated and offline-aware AI client

- Source findings: FINDING-005, FINDING-011, FINDING-020
- Objective: Align Flutter requests with backend authentication and expose explicit local-only/offline/error states.
- Priority: Now
- Severity: S1 — High
- Effort: M
- Scores: user impact 8/10; security/reliability 9/10; leverage 9/10; implementation risk 7/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-007, TASK-008 after dependencies
- Depends on: TASK-001; preferably TASK-011
- Blocks: production AI features
- Suggested branch: `codex/task-005-authenticated-ai-client`
- Likely files: `ai_service.dart`, auth providers/service, AI call-site screens, error models, tests
- Do not modify: prompt wording or Gemini model behavior unless separately approved
- Context: Backend requires a bearer token; Dio sends none; local-only mode is supported.
- Detailed implementation steps:
  1. Create one injected Dio/client provider with bounded timeouts and a token supplier.
  2. Serialize token refresh and retry at most once after a verified refresh.
  3. Normalize missing auth, offline, timeout, 401/403, validation, quota, and server errors.
  4. Replace direct service construction at all call sites.
  5. Define UI behavior for local-only users; safe default is disable cloud AI with a clear optional-sign-in explanation.
- Acceptance criteria:
  - [ ] Signed-in calls contain a current bearer token.
  - [ ] Logged-out calls never hit paid endpoints under an invented identity.
  - [ ] Concurrent 401s do not create a refresh storm or duplicate mutation.
  - [ ] Each relevant screen offers a recoverable, truthful state.
- Required tests:
  - [ ] Dio/mock server auth and one-retry tests
  - [ ] Concurrent refresh test
  - [ ] Logged-out/offline/quota widget states
- Required commands: targeted AI/auth tests; `flutter analyze`; `flutter test`; backend contract tests
- Edge cases: auth expires mid-request; Supabase unavailable; user signs out during refresh; slow backend; malformed response
- Rollback strategy: Feature-gate AI and retain local/manual flows.
- Risks: Retrying non-idempotent brain-dump requests may duplicate server cost; attach request IDs or avoid automatic retry where needed.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-006 — Register and validate mobile auth callbacks

- Source findings: FINDING-006, FINDING-017
- Objective: Make signup confirmation, OAuth, and password reset return safely to Android and iOS.
- Priority: Now
- Severity: S1 — High
- Effort: M
- Scores: user impact 9/10; security/reliability 8/10; leverage 8/10; implementation risk 6/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-001, TASK-003, TASK-008
- Depends on: Supabase/Google/Apple dashboard access for final validation
- Blocks: social auth/reset release, TASK-016 closure
- Suggested branch: `codex/task-006-auth-deep-links`
- Likely files: Android manifest, iOS Info.plist/entitlements, router/auth bootstrap, auth docs/tests
- Do not modify: unrelated app links or bundle/application IDs
- Context: Dart emits `io.supabase.flowos://login-callback/`; neither platform declares it.
- Detailed implementation steps:
  1. Register the exact callback on both platforms with minimal matching scope.
  2. Confirm Supabase redirect allow-list and provider callback values.
  3. Route verified auth callbacks through the Supabase SDK and app-session refresh.
  4. Handle cancel, invalid state, error, warm app, and cold app.
  5. Document provider-console setup without committing secrets.
- Acceptance criteria:
  - [ ] All supported auth/reset flows return to the intended screen.
  - [ ] Unrelated URLs cannot trigger privileged app actions.
  - [ ] Cold and warm callbacks behave consistently.
- Required tests:
  - [ ] Router callback parsing tests
  - [ ] Android intent and iOS URL configuration checks
  - [ ] Physical-device provider matrix
- Required commands: `plutil -lint ios/Runner/Info.plist`; Android manifest/build checks; `flutter analyze`; `flutter test`
- Edge cases: app uninstalled; duplicate callback; canceled browser; invalid OAuth state; provider not installed
- Rollback strategy: Disable affected UI methods until configuration is restored.
- Risks: External console misconfiguration can look like an app defect.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-007 — Add data-preserving migration fixtures and schema repair

- Source findings: FINDING-007, FINDING-016, FINDING-017
- Objective: Upgrade every supported installed schema, including known divergent states, without duplicate-column crashes or silent data loss.
- Priority: Now
- Severity: S1 — High
- Effort: L
- Scores: user impact 10/10; security/reliability 10/10; leverage 9/10; implementation risk 10/10; confidence 9/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-001 and TASK-003; schema implementation coordinates with TASK-002
- Depends on: anonymized affected schema manifests; TASK-002 schema-order decision
- Blocks: upgrade release
- Suggested branch: `codex/task-007-database-repair`
- Likely files: Drift database/migrations, generated schema snapshots, migration tests/fixtures, startup recovery UI
- Do not modify: user data by blanket deletion; unrelated DAO behavior
- Context: Version-based `addColumn` assumes an ideal physical schema; supplied device evidence showed duplicate columns.
- Detailed implementation steps:
  1. Export schema-only manifests from representative v1–v9 and affected installations.
  2. Add immutable fixture databases and expected row/content manifests.
  3. Design a one-way repair that inspects actual tables/columns/indexes before change.
  4. Run migration transactionally; verify schema and data before advancing.
  5. Add corruption quarantine/export and user recovery if repair cannot prove safety.
  6. Test reopening the repaired DB to prove idempotency.
- Acceptance criteria:
  - [ ] Every fixture opens at v9/current without error.
  - [ ] Observed duplicate-column states repair successfully.
  - [ ] Critical table row counts and representative content are preserved.
  - [ ] Failure never silently clears the database.
- Required tests:
  - [ ] Version-by-version migration matrix
  - [ ] Divergent/partial schema fixtures
  - [ ] Interrupted repair/reopen
  - [ ] Restore mismatch fixture
- Required commands: code generation; targeted migration tests; `flutter analyze`; `flutter test`
- Edge cases: missing table with advanced user_version; column exists with wrong null/default type; low disk; interrupted transaction
- Rollback strategy: Copy/quarantine the original DB before repair and support rollback to the pre-repair app build only if schema remains compatible.
- Risks: A guessed repair can destroy the only local copy; fixtures and real schema evidence are mandatory.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-008 — Schedule recurring notifications in the actual device timezone

- Source findings: FINDING-008, FINDING-013
- Objective: Fire user-configured reminders at local wall-clock time across DST and timezone changes.
- Priority: Now
- Severity: S1 — High
- Effort: M
- Scores: user impact 8/10; security/reliability 8/10; leverage 7/10; implementation risk 5/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-001, TASK-002, TASK-003, TASK-010
- Depends on: device timezone source selection
- Blocks: trustworthy reminders
- Suggested branch: `codex/task-008-notification-timezone`
- Likely files: notification service, platform/dependency configuration, notification tests, startup coordinator
- Do not modify: reminder copy/frequency without product approval
- Context: The service sets `tz.local` to UTC and then schedules local-hour reminders against it.
- Detailed implementation steps:
  1. Add a testable timezone provider returning an IANA zone.
  2. Initialize `tz.local` from the device and define an observable fallback.
  3. Reschedule when timezone or reminder preference changes.
  4. Keep scheduling idempotent and preserve notification IDs.
  5. Add DST and non-whole-hour-zone tests.
- Acceptance criteria:
  - [ ] A 09:00 setting fires at 09:00 device local time.
  - [ ] Asia/Kolkata and DST transitions are correct.
  - [ ] Failure to resolve a zone is visible and noncrashing.
- Required tests:
  - [ ] UTC/IST/DST schedule calculation tests
  - [ ] Reschedule/idempotency tests
  - [ ] Physical-device time-change smoke
- Required commands: targeted notification tests; `flutter analyze`; `flutter test`
- Edge cases: timezone changes while app is closed; ambiguous/nonexistent DST times; reboot; permission denied
- Rollback strategy: Disable affected recurring schedules rather than force UTC.
- Risks: Plugin/platform API compatibility needs Android and iOS verification.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-009 — Make production signing fail closed

- Source findings: FINDING-009
- Objective: Prevent any production release variant from using a debug signing identity.
- Priority: Now
- Severity: S1 — High
- Effort: S
- Scores: user impact 8/10; security/reliability 10/10; leverage 8/10; implementation risk 4/10; confidence 10/10
- Primary executor: `HUMAN_OR_EXTERNAL_INPUT`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: All non-Gradle tasks
- Depends on: Authorized signing/Play Console decision and credentials
- Blocks: Android production release
- Suggested branch: `codex/task-009-release-signing`
- Likely files: `android/app/build.gradle.kts`, CI secret configuration/documentation
- Do not modify: application ID, existing production key, or Play signing configuration without authorization
- Context: Missing `key.properties` copies the debug signing configuration into release.
- Detailed implementation steps:
  1. Choose Play App Signing and CI/local credential ownership.
  2. Remove the release debug fallback and emit a clear missing-credential failure.
  3. Add a distinct internal/debug-signed build type if local distribution is needed.
  4. Record and securely verify the production certificate fingerprint.
- Acceptance criteria:
  - [ ] `release` without credentials fails.
  - [ ] Authorized release uses the expected certificate.
  - [ ] No key material is committed or printed.
- Required tests:
  - [ ] Negative missing-credential build check
  - [ ] Authorized CI signing/fingerprint check
- Required commands: `flutter build appbundle --release` in authorized CI; `apksigner verify --print-certs`
- Edge cases: Play upload key versus app-signing key; key rotation; developer internal builds
- Rollback strategy: Re-enable only a separate internal build type, never release fallback.
- Risks: Incorrect key choice can make future updates impossible.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-010 — Restore the static-analysis correctness baseline

- Source findings: FINDING-010, FINDING-019
- Objective: Make `flutter analyze` pass while fixing, not suppressing, the detected semantic and dependency errors.
- Priority: Now
- Severity: S2 — Medium
- Effort: M
- Scores: user impact 6/10; security/reliability 7/10; leverage 9/10; implementation risk 5/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Security tasks; avoid files concurrently owned by TASK-003/004
- Depends on: None
- Blocks: trustworthy CI, TASK-016
- Suggested branch: `codex/task-010-analyzer-baseline`
- Likely files: timeline widget/test, pubspec, affected tests, bounded warning sites
- Do not modify: analysis rules to hide classes of warning; unrelated behavior
- Context: Analysis exits 1 with 77 issues, including enum/string equality and undeclared direct `crypto`.
- Detailed implementation steps:
  1. Snapshot issues by category and owner.
  2. Fix semantic/type/dependency/mock errors with targeted tests.
  3. Address async-context and deprecated APIs by feature slice.
  4. Remove dead imports/code only after checking call sites.
  5. Keep CI's zero-issue contract.
- Acceptance criteria:
  - [ ] Deep-work timeline uses enum-safe logic and has a regression test.
  - [ ] Every imported package is a direct declared dependency.
  - [ ] `flutter analyze` exits 0 without broad suppression.
- Required tests:
  - [ ] Timeline classification test
  - [ ] Existing full Flutter suite
- Required commands: `dart format`; `flutter analyze`; `flutter test`
- Edge cases: generated files; mocks with intentional broad signatures; dirty working-tree overlap
- Rollback strategy: Revert by feature slice, not one repository-wide cleanup commit.
- Risks: Mechanical cleanup can accidentally change behavior; small commits and characterization tests are required.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-011 — Consolidate reactive auth and router session state

- Source findings: FINDING-002, FINDING-005, FINDING-006, FINDING-011
- Objective: Provide one provider-owned source for authentication, local-only mode, onboarding readiness, and router refresh.
- Priority: Next
- Severity: S2 — Medium
- Effort: M
- Scores: user impact 7/10; security/reliability 8/10; leverage 10/10; implementation risk 7/10; confidence 9/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-008, TASK-013 discovery
- Depends on: Account-state terminology from TASK-002
- Blocks: TASK-005 preferred design, TASK-012
- Suggested branch: `codex/task-011-app-session-state`
- Likely files: auth service/providers, app router, onboarding completion store, settings and sync providers, tests
- Do not modify: route visual layouts or auth provider configuration
- Context: Reactive auth stream, nonreactive current user, module globals, and undisposed router listening coexist.
- Detailed implementation steps:
  1. Define explicit loading/local-only/authenticated/unauthenticated session states.
  2. Derive current user and login selectors from the auth stream.
  3. Inject a disposable router refresh source and remove mutable onboarding globals.
  4. Migrate consumers and add transition tests.
- Acceptance criteria:
  - [ ] Login/logout/token refresh immediately updates consumers and redirects once.
  - [ ] Local-only mode never throws by reading Supabase providers.
  - [ ] Router subscriptions dispose in tests/app teardown.
- Required tests:
  - [ ] Provider transition tests
  - [ ] Router redirect matrix
  - [ ] Account switch and token refresh tests
- Required commands: targeted auth/router tests; `flutter analyze`; `flutter test`
- Edge cases: Supabase disabled; auth event before onboarding load; expired session; callback during cold start
- Rollback strategy: Keep old selectors behind adapters until all call sites migrate, then remove them.
- Risks: Router loops or splash flicker if loading state is modeled incorrectly.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-012 — Make sync serialized, cancellable, and retry-safe

- Source findings: FINDING-002, FINDING-012, FINDING-020
- Objective: Run one account-bound sync at a time with safe cursors, cancellation, retry classification, and actionable status.
- Priority: Next
- Severity: S2 — Medium
- Effort: L
- Scores: user impact 8/10; security/reliability 9/10; leverage 9/10; implementation risk 9/10; confidence 9/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-017 after dependencies; not with overlapping TASK-002 sync edits
- Depends on: TASK-002, TASK-011, error taxonomy from TASK-018
- Blocks: trustworthy multi-device sync
- Suggested branch: `codex/task-012-resilient-sync`
- Likely files: sync engine/providers/status models, cursors/outbox DAO, cloud fakes/tests
- Do not modify: conflict rules without documenting compatibility; server RLS
- Context: Current engine has improved pagination but coarse whole-cycle failure and weak lifecycle cancellation.
- Detailed implementation steps:
  1. Serialize sync per account and cancel on sign-out/account switch/disposal.
  2. Classify auth, validation, retryable transport, and terminal row errors.
  3. Add bounded jittered backoff and connectivity-triggered resume.
  4. Advance each cursor only after its page is durably applied.
  5. Expose per-stage status and a safe manual retry.
- Acceptance criteria:
  - [ ] Concurrent triggers coalesce into one account-bound run.
  - [ ] Failed pages do not advance their cursor.
  - [ ] Account changes cancel before another user's mapping/upload.
  - [ ] Nonretryable rows do not create an infinite retry loop.
- Required tests:
  - [ ] Mid-page and mid-table failures
  - [ ] 401/refresh/account switch
  - [ ] Concurrent local mutation and restart
  - [ ] Backoff/cancellation fake-clock tests
- Required commands: targeted sync tests; `flutter analyze`; `flutter test`
- Edge cases: clock skew; soft delete conflict; duplicate server row; app killed after apply before cursor save
- Rollback strategy: Disable automatic sync and preserve outbox/cursors for a corrected build.
- Risks: Cursor changes can duplicate or skip data; deterministic fixtures are mandatory.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-013 — Shorten and isolate application startup

- Source findings: FINDING-008, FINDING-013, FINDING-020
- Objective: Render the local-first shell after required initialization while deferring recoverable maintenance.
- Priority: Next
- Severity: S2 — Medium
- Effort: M
- Scores: user impact 7/10; security/reliability 6/10; leverage 8/10; implementation risk 6/10; confidence 9/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-014; profiling can start before TASK-018
- Depends on: TASK-018 for final error reporting; TASK-008 notification API stability
- Blocks: None
- Suggested branch: `codex/task-013-startup-coordinator`
- Likely files: `main.dart`, notification/bootstrap services, providers, startup tests
- Do not modify: onboarding routing semantics or data migration order
- Context: Four notification schedules and several I/O steps execute serially before `runApp`.
- Detailed implementation steps:
  1. Capture startup timeline for clean/returning/offline cases.
  2. Classify required versus post-frame initialization.
  3. Add a testable startup coordinator and defer idempotent notification maintenance.
  4. Keep migration/storage readiness explicit before data screens query.
  5. Show a bounded recoverable state only for truly blocking initialization.
- Acceptance criteria:
  - [ ] Notification/Supabase maintenance failure does not prevent local UI.
  - [ ] First-frame critical dependencies remain race-free.
  - [ ] Before/after traces and startup stages are documented.
- Required tests:
  - [ ] Coordinator ordering and failure tests
  - [ ] Clean/upgrade/local-only widget bootstrap tests
- Required commands: profile trace on device; targeted tests; `flutter analyze`; `flutter test`
- Edge cases: migration failure; restored preferences without DB; notification plugin exception; Supabase timeout
- Rollback strategy: Move individual stages back before `runApp` if a proven dependency requires it.
- Risks: Incorrect deferral can let UI query an unopened/migrating database.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-014 — Coalesce and batch garden-derived data

- Source findings: FINDING-014
- Objective: Keep garden updates immediate while bounding queries and preventing stale async emissions.
- Priority: Next
- Severity: S2 — Medium
- Effort: M
- Scores: user impact 6/10; security/reliability 5/10; leverage 7/10; implementation risk 5/10; confidence 8/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-013, TASK-015
- Depends on: Query/event measurement
- Blocks: None
- Suggested branch: `codex/task-014-garden-reactivity`
- Likely files: garden service, DAOs/aggregate queries, providers, tests
- Do not modify: garden product rules, object mapping, season copy
- Context: Broad table updates launch full async day/week rebuilds and repeated task lookups.
- Detailed implementation steps:
  1. Instrument build/event/query counts in tests/profile mode.
  2. Share cached today/week streams rather than creating one pipeline per consumer.
  3. Coalesce bursts and use generation/switch-map semantics.
  4. Batch session/task lookup in one query or map.
  5. Preserve immediate correctness for the final event.
- Acceptance criteria:
  - [ ] A burst emits the latest result and no stale overwrite.
  - [ ] Query counts are bounded by an asserted test threshold.
  - [ ] Multiple listeners share work.
- Required tests:
  - [ ] Burst ordering
  - [ ] Shared-listener query count
  - [ ] Session/task batch mapping
- Required commands: targeted garden tests; `flutter analyze`; `flutter test`
- Edge cases: midnight rollover; table write during build; listener cancellation; empty week
- Rollback strategy: Retain reactive source and revert only coalescing/batching layer.
- Risks: Over-debounce can make growth feel delayed; use short/coherent event batching.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-015 — Define and implement truthful export and backup behavior

- Source findings: FINDING-002, FINDING-015, FINDING-016
- Objective: Make data export complete and safe for its stated purpose, and explicitly control Android backup/restore.
- Priority: Next
- Severity: S2 — Medium
- Effort: L
- Scores: user impact 8/10; security/reliability 8/10; leverage 7/10; implementation risk 8/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: TASK-014 after product answers
- Depends on: TASK-002; OPEN-005 and OPEN-006
- Blocks: backup/restore promise
- Suggested branch: `codex/task-015-data-portability`
- Likely files: export service/models/tests, settings copy/UI, Android backup rules, privacy docs
- Do not modify: sync outbox as user backup content; legal copy without approval
- Context: Current “Backup Data” exports nine of 18 tables as raw shared text and has no restore path.
- Detailed implementation steps:
  1. Decide export-only versus restorable backup and enumerate every dataset.
  2. Version a manifest with app/schema/export versions and ownership semantics.
  3. Generate a controlled temporary file; warn that it contains sensitive attention data.
  4. Exclude internal transient state or document why it is included.
  5. Add restore/validation if promised; otherwise rename and remove backup claims.
  6. Add Android data extraction/full-backup rules consistent with the policy.
- Acceptance criteria:
  - [ ] UI copy matches actual scope.
  - [ ] Every table has an explicit include/exclude reason.
  - [ ] Shared files have a controlled lifecycle and no secrets/tokens.
  - [ ] Android backup behavior is explicit across OS versions.
- Required tests:
  - [ ] Manifest/content fixture
  - [ ] Large export and failed share cleanup
  - [ ] Round-trip test if restore exists
  - [ ] Android backup/restore matrix
- Required commands: targeted export tests; manifest lint/build; `flutter analyze`; `flutter test`
- Edge cases: multiple accounts; partial/corrupt file; future schema; low disk; canceled share
- Rollback strategy: Rename to limited export and disable restore while preserving files.
- Risks: Exporting notification/usage data increases privacy exposure; consent copy needs review.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-016 — Build the critical cross-layer regression matrix

- Source findings: FINDING-001 through FINDING-010, FINDING-017
- Objective: Exercise the smallest set of integration paths that would have caught the release blockers.
- Priority: Now/continuous
- Severity: S2 — Medium
- Effort: L
- Scores: user impact 8/10; security/reliability 10/10; leverage 10/10; implementation risk 5/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Harness/fixtures can start immediately; assertions close after source tasks
- Depends on: Individual fixes for final green status
- Blocks: release candidate
- Suggested branch: `codex/task-016-critical-integration-tests`
- Likely files: backend tests, Dart integration/contract tests, migration fixtures, Android instrumentation/test docs, CI
- Do not modify: production behavior solely to make tests convenient
- Context: Unit/widget tests pass, but no runnable root integration or Android instrumentation suite covers critical boundaries.
- Detailed implementation steps:
  1. Add backend endpoint-level forged-token tests.
  2. Add database upgrade fixtures and two-account sync fakes.
  3. Add a mounted focus timer screen/notifier regression and policy payload contract tests.
  4. Add auth callback parsing/redirect tests.
  5. Create Android permission/app-blocking/notification smoke instrumentation where automation is stable.
  6. Add a documented physical-device matrix for OEM-only behavior.
  7. Gate CI on stable platform-independent layers.
- Acceptance criteria:
  - [ ] Every S0/S1 finding has an automated regression where environment permits.
  - [ ] Remaining manual checks have device, setup, expected result, and evidence fields.
  - [ ] CI runtime/flakiness is bounded and failures are actionable.
- Required tests:
  - [ ] As described above
- Required commands: backend tests; `flutter analyze`; `flutter test`; selected `flutter test integration_test/...`; Android connected tests in device CI
- Edge cases: permission UI cannot be fully automated; OEM accessibility differences; unavailable external auth provider
- Rollback strategy: Quarantine only proven-flaky device tests with an owner/expiry; never remove deterministic regressions.
- Risks: An overly broad end-to-end suite becomes slow and ignored; keep tests rooted in identified failures.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-017 — Decompose focus and settings screens along behavior boundaries

- Source findings: FINDING-003, FINDING-004, FINDING-018, FINDING-022
- Objective: Separate pure presentation from session/account/data side effects without changing product behavior.
- Priority: Next
- Severity: S2 — Medium
- Effort: L
- Scores: user impact 6/10; security/reliability 6/10; leverage 9/10; implementation risk 7/10; confidence 10/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Settings extraction can run separately from focus extraction with coordination
- Depends on: TASK-003, TASK-004, TASK-010
- Blocks: broad premium UI iteration
- Suggested branch: `codex/task-017-screen-boundaries`
- Likely files: focus/deep-work/settings screens, new focused widgets/coordinators, tests
- Do not modify: timer semantics, settings persistence keys, visual redesign, unrelated large screens
- Context: Large screens mix UI, navigation, audio, mutation, permissions, account, and export coordination.
- Detailed implementation steps:
  1. Add characterization tests for critical current states.
  2. Extract pure focus timer controls/scene/setup sections driven by immutable view data.
  3. Move shared focus/deep-work presentation effects to one coordinator.
  4. Extract settings sections with explicit callbacks and narrow provider subscriptions.
  5. Run device/golden comparisons before considering other screens.
- Acceptance criteria:
  - [ ] Pure widgets perform no database/network/navigation mutation.
  - [ ] Focus and deep work do not duplicate lifecycle/completion code.
  - [ ] Settings sections can be widget-tested independently.
  - [ ] No visible/behavior change without a separately approved design task.
- Required tests:
  - [ ] Characterization and component widget tests
  - [ ] Focus lifecycle regression suite
  - [ ] Settings destructive-action tests
- Required commands: `dart format`; `flutter analyze`; `flutter test`
- Edge cases: screen rotation; route replacement during completion; permission settings resume; text scaling
- Rollback strategy: One extraction per commit, retaining adapters until verified.
- Risks: Mechanical extraction before state fixes can preserve or duplicate flawed ownership.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-018 — Introduce typed failures and redacted observability

- Source findings: FINDING-005, FINDING-007, FINDING-012, FINDING-013, FINDING-020
- Objective: Preserve actionable failure context across platform, database, auth, network, and sync boundaries without leaking private data.
- Priority: Next
- Severity: S2 — Medium
- Effort: M
- Scores: user impact 7/10; security/reliability 8/10; leverage 9/10; implementation risk 6/10; confidence 9/10
- Primary executor: `REASONING_MODEL`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Taxonomy/design can run with TASK-011
- Depends on: Privacy logging rules/product input for support bundles
- Blocks: TASK-012/013 final observability
- Suggested branch: `codex/task-018-error-observability`
- Likely files: core failure/logging services, main error hooks, platform repositories, sync/AI, Sentry config, tests
- Do not modify: raw user content logging; global swallowing/suppression policy
- Context: Broad catches keep the app alive but lose error type and recovery information.
- Detailed implementation steps:
  1. Define typed boundary failures and recovery actions.
  2. Add redacted structured logging/correlation IDs.
  3. Capture unhandled async/dispatcher errors in addition to Flutter framework errors.
  4. Replace critical silent catches with expected-fallback or reported-failure paths.
  5. Map failures to user-facing permission/auth/offline/storage states.
- Acceptance criteria:
  - [ ] Critical failures retain category, operation, and safe context.
  - [ ] Tokens, task text, app usage detail, and notification content are not logged by default.
  - [ ] Expected permission denial is not treated as a crash.
  - [ ] Unhandled async errors reach staging observability.
- Required tests:
  - [ ] Redaction tests
  - [ ] Failure mapping tests
  - [ ] Unhandled async capture smoke
- Required commands: targeted tests; `flutter analyze`; `flutter test`
- Edge cases: Sentry disabled; recursive logger failure; offline flood; platform exception details
- Rollback strategy: Keep typed failures while disabling a noisy sink via configuration.
- Risks: Overlogging sensitive attention data; privacy review is required.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-019 — Commit deterministic dependencies and remove proven-unused build inputs

- Source findings: FINDING-019, FINDING-021
- Objective: Make clean builds reproducible and reduce only measured dependency/asset waste.
- Priority: Now for lockfile; Later for trimming
- Severity: S2 — Medium
- Effort: S
- Scores: user impact 4/10; security/reliability 7/10; leverage 9/10; implementation risk 4/10; confidence 10/10
- Primary executor: `GEMINI_3_6_FLASH`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Most tasks after avoiding `pubspec.yaml` overlap
- Depends on: Approved exact removal list; no active dependency upgrade
- Blocks: deterministic CI
- Suggested branch: `codex/task-019-dependency-reproducibility`
- Likely files: `.gitignore`, `pubspec.yaml`, `pubspec.lock`, asset declarations, developer docs
- Do not modify: package versions beyond the approved lock resolution; audio/image assets; generated plugin files by hand
- Context: The app lockfile is ignored; nine packages have no Dart imports; 70 fonts are broadly declared; large APKs sit in `test/`.
- Detailed implementation steps:
  1. Stop ignoring and commit the reviewed current lockfile.
  2. Move/remove local APK artifacts from the test tree without changing product code.
  3. Capture `appbundle --analyze-size`.
  4. Remove one approved batch of unused dependencies and unreferenced fonts.
  5. Re-resolve, build, test, and compare size.
- Acceptance criteria:
  - [ ] Clean checkouts use the same locked graph.
  - [ ] No referenced/generated/platform dependency is removed.
  - [ ] Size change is measured rather than estimated.
  - [ ] Test discovery no longer traverses giant local APK artifacts.
- Required tests:
  - [ ] Full Flutter suite
  - [ ] Android debug/release-size build
  - [ ] Font/audio/image smoke
- Required commands: `flutter pub get`; `flutter analyze`; `flutter test`; `flutter build appbundle --analyze-size`
- Edge cases: platform-only package use; future feature branch dependency; generated plugin registrant changes
- Rollback strategy: Restore an individual dependency/asset and its lockfile entry.
- Risks: Search-only removal can miss platform/config use; reasoning verification must inspect registrants and call sites.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes

## TASK-020 — Define accessibility, responsive, and localization acceptance baselines

- Source findings: FINDING-022, FINDING-018
- Objective: Establish approved target languages/device classes and make critical journeys usable with assistive technology and large text.
- Priority: Later
- Severity: S3 — Low
- Effort: L
- Scores: user impact 7/10; security/reliability 4/10; leverage 8/10; implementation risk 5/10; confidence 8/10
- Primary executor: `HUMAN_OR_EXTERNAL_INPUT`
- Required verification model: `REASONING_MODEL`
- Can run in parallel: Feature opportunities after TASK-017
- Depends on: Product language scope and design review; TASK-017 for stable shared components
- Blocks: localization/accessibility launch claims
- Suggested branch: `codex/task-020-accessibility-baseline`
- Likely files: localization config/ARB, shared components, shell/focus/onboarding/tasks/settings/garden tests
- Do not modify: all copy repository-wide in one pass; scoring/product semantics
- Context: No localization system or multi-size semantics/golden baseline exists.
- Detailed implementation steps:
  1. Select supported languages, device classes, text scales, contrast target, and assistive-tech checklist.
  2. Audit critical journeys and shared controls first.
  3. Add semantics roles/labels, focus order, and 48 dp targets.
  4. Add small-phone/tablet/landscape/text-scale goldens.
  5. Introduce localization generation and migrate one feature at a time.
- Acceptance criteria:
  - [ ] Critical journeys pass TalkBack/VoiceOver review.
  - [ ] Text scale 2.0 does not hide primary actions.
  - [ ] Shared shell works on approved small/tablet layouts.
  - [ ] Localization extraction has translator context and plural/date handling.
- Required tests:
  - [ ] Semantics tests
  - [ ] Device/text-scale goldens
  - [ ] RTL smoke
- Required commands: localization generation; `flutter analyze`; `flutter test`; device accessibility checklist
- Edge cases: emoji announcement; custom painters; dynamic garden labels; RTL timers/charts; reduced motion
- Rollback strategy: Migrate by feature behind shared string/semantics adapters.
- Risks: Without design/language decisions, mechanical string extraction can encode poor UX.
- Verification checklist:
  - [ ] Diff matches scope
  - [ ] Tests cover regression
  - [ ] Static analysis passes
  - [ ] Failure paths verified
  - [ ] No unrelated changes


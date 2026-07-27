# FlowOS Audit — Validation Results

Validation date: 2026-07-27  
Host: macOS, Asia/Kolkata timezone  
Audited revision: `d61394c` plus the pre-existing working-tree changes below

## Working-tree state

The audit began with these uncommitted changes:

```text
 M .flutter-plugins-dependencies
 M android/app/proguard-rules.pro
 M lib/features/notifications/services/notification_service.dart
 M lib/main.dart
```

They were treated as user work and were not reverted or rewritten. The only intentional audit changes are the eight files under `docs/codebase-audit/`.

## Toolchain

### `flutter --version`

- Result: PASS
- Observed:
  - Flutter 3.41.4, stable channel
  - framework revision `ff37bef603`
  - Dart 3.11.1
  - DevTools 2.54.1
- Environment note: Flutter needed access to its SDK cache outside the workspace sandbox.

### Declared application constraints

- `pubspec.yaml`: Dart `^3.11.0`
- Application version: `0.1.0+1`
- Android/iOS are present; other Flutter platform folders are absent.

## Static analysis and formatting

### `flutter analyze`

- Result: FAIL, exit code 1
- Count: 77 issues
- Important observed classes:
  - enum/string equality in `focus_session_timeline.dart`, making the deep-work comparison invalid;
  - `crypto` imported without being a direct dependency;
  - stale `BuildContext` use across async gaps;
  - unused imports/declarations;
  - deprecated API use;
  - invalid mock override signatures.
- Interpretation: This is an application quality-gate failure, not an environment failure. The repository CI runs the same command, so the current CI analyze job is expected to fail.

### `dart format --output=none --set-exit-if-changed lib test`

- Result: FAIL, exit code 1
- Files examined: 209
- Files that would change: 158
- Safety: `--output=none` was used; no formatting rewrite was requested during the audit.
- Interpretation: Formatting drift is broad and should be repaired in bounded commits after correctness changes, not mixed into security diffs.

### `git diff --check`

- Result: PASS
- Interpretation: No whitespace-error finding was reported in the existing tracked diff or new documentation.

## Flutter tests

### `flutter test --reporter compact`

- Result: PASS
- Count: all 154 tests passed
- Scope: Dart unit and widget tests
- Limitation: A passing isolated suite did not exercise the mounted timer completion path, real platform channels/services, two-account sync, auth callbacks, or real installed database upgrades.

### Test inventory

- Dart test files: 31
- Executable root `integration_test/` files: 0
- Android instrumentation tests for accessibility/notification/usage integration: none found
- Coverage: not generated during this audit
- Large local artifacts: two ignored APKs of about 238 MB each under `test/`; these are not tests and make the directory about 477 MB.

## Backend tests and security reproduction

### `pytest`

- Result: NOT RUN
- Exact blocker: the selected Python environment reported `No module named pytest`.
- Interpretation: Environment/tooling limitation, not a test failure.

### `backend/.venv/bin/python -m unittest discover -s backend/tests -v`

- Result: PASS
- Count: 14 tests passed
- Warnings: tests use a 27-byte HMAC key, shorter than the recommended HS256 key length.
- Missing behavior: no endpoint-level regression for the rate-limiter/auth request-state interaction.

### Authentication bypass reproduction

- Result: CONFIRMED
- Method: constructed a request whose state contained a forged user ID and supplied invalid credentials to `get_current_user_id`.
- Observed result: the function returned the forged state identity before credential verification.
- No production secret or token was used or printed.

## Android build

### `flutter build apk --debug`

- Result: INCONCLUSIVE / TERMINATED
- Observations:
  - An early sandboxed attempt could not update Flutter's external engine stamp.
  - A second attempt encountered a Gradle lock held by the first build.
  - A clean escalated attempt entered `assembleDebug`, emitted a Kotlin compatibility warning, and produced no further output or APK. It was terminated after 1,144.8 seconds; exit code 130.
  - No `build/app/outputs/flutter-apk/app-debug.apk` artifact was present afterward.
- Kotlin warning: Flutter support for project Kotlin 1.9.24 will be dropped in a future release; at least Kotlin 2.1.0 is recommended.
- Interpretation: A debug build is not claimed as passing. The long-running Gradle behavior may be host/cache/network-related and needs a clean build environment investigation; it is separate from the analyzer failure already confirmed.

## Configuration checks

| Check | Result |
|---|---|
| `android/key.properties` | Absent |
| Release fallback to debug signing | Confirmed in Gradle configuration |
| `ios/Runner/GoogleService-Info.plist` | Absent |
| Android auth callback intent filter | Not found |
| iOS `CFBundleURLTypes` callback registration | Not found |
| Production CORS explicit origins | Present |
| Supabase table RLS | Present in migrations |
| `pubspec.lock` locally present | Yes |
| `pubspec.lock` tracked | No; ignored by `.gitignore` |
| Localization/ARB setup | Not found |
| Sentry | Conditional on `SENTRY_DSN` |

## Repository inventory observations

- Non-generated Dart source: approximately 32,506 lines.
- Screens over 600 lines include Settings, Focus, Scroll Tracker, Insights, Tasks, Home, Onboarding Connect, and Weekly Review.
- Assets: approximately 29 MB.
- Fonts: approximately 17 MB across 70 files.
- Git object store: approximately 155 MB.
- Packages with no Dart imports found in `lib/` or `test/`: `rive`, `google_fonts`, `shimmer`, `percent_indicator`, `flutter_svg`, `dynamic_color`, `google_sign_in`, `sign_in_with_apple`, and `haptic_feedback`.
- These package findings require generated/platform call-site review before removal; they are not proof that each can be deleted blindly.

## Checks intentionally not run

| Check | Reason |
|---|---|
| `flutter test --coverage` | Full tests already passed; coverage generation was lower value than tracing missing system boundaries and would not add platform coverage. |
| `flutter test integration_test` | No runnable root integration tests exist. |
| iOS build/pod install | No Xcode signing/provider configuration and no physical iOS environment was available. |
| Android connected tests | No connected/emulated device test target was configured. |
| Production Supabase/Gemini calls | No production credentials or authorization; avoiding cost and data exposure. |
| `dart pub outdated` | Would add low-value package-upgrade noise during a correctness/security audit and can require registry access. |
| Release app bundle | Signing configuration is intentionally incomplete and currently fails open to debug signing. |
| Performance/profile traces | No controlled physical device or profile build was available. |

## Recommended CI additions

1. Preserve `flutter analyze` and restore it to zero issues.
2. Commit `pubspec.lock` and use deterministic Flutter/Dart versions.
3. Run backend endpoint auth tests, including forged/expired/wrong-audience tokens.
4. Run migration fixtures for every supported schema and observed divergent states.
5. Add mounted focus timer/protection contract tests.
6. Add two-account sync and outbox ownership tests.
7. Add a build configuration check that production release cannot use the debug key.
8. Add Android manifest and iOS plist checks for auth callbacks.
9. Add a small integration suite in CI and a separate physical-device release matrix.
10. Add release size reporting and dependency review as informational gates, not blockers until a baseline is approved.

## Overall validation result

- Unit/widget baseline: green
- Backend isolated baseline: green
- Static-analysis/format baseline: red
- Android build: not proven
- Platform/end-to-end coverage: insufficient
- Security/release readiness: red because of the two S0 findings and seven S1 findings


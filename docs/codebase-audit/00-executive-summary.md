# FlowOS Codebase Audit — Executive Summary

Audit date: 2026-07-27  
Audited revision: `d61394c` on `main`, including the pre-existing uncommitted changes listed in [validation results](06-validation-results.md#working-tree-state)  
Scope: Flutter mobile app, Android native services, iOS configuration, FastAPI AI backend, Supabase schema, browser extension, tests, CI, assets, and release configuration  
Change policy: audit documentation only; no application code was changed

## Application overview

FlowOS is a local-first focus and attention application. Its core product loop combines tasks, focus timers, ambient audio, a persistent garden, attention and interruption metrics, Android app protection, sleep protection, daily scoring, notifications, reports, and optional Supabase account sync. The repository also contains a FastAPI/Gemini service for AI-assisted reports and task processing, plus a Chrome extension.

The application has meaningful product depth and a credible local-first foundation. The Android usage and accessibility bridge has already been improved to move expensive work off the main thread and cache policy and app metadata. The garden aggregation has also moved away from fixed polling toward Drift table-update streams. Those earlier concerns are therefore not current release blockers.

The present release is not ready to ship, however. Two independent trust-boundary failures are critical:

1. the backend can accept an identity copied from an unverified JWT by the rate limiter;
2. local records, sync cursors, and queued writes are not isolated by account, allowing one signed-in user to see or upload another local user's data.

Several high-severity correctness issues follow: focus completion is not idempotent, the selected protection strictness is not propagated into a session, the Flutter AI client does not authenticate against its backend, auth callbacks are not registered on either mobile platform, installed database upgrades have no repair path for known divergent schemas, reminder scheduling forces UTC, and Android release signing falls back to the debug key.

## Architecture summary

- **Client:** Flutter 3.41.4 / Dart 3.11.1, Riverpod, GoRouter, Drift/SQLite, optional Supabase.
- **Native Android:** Kotlin method channels, `UsageStatsManager`, accessibility blocking, notification listener, foreground focus service, shared preference policy bridge.
- **iOS:** standard Flutter shell; no Screen Time/App Blocking implementation and no registered auth callback URL scheme.
- **Backend:** FastAPI, Gemini API, JWT authentication, SlowAPI rate limiting, optional Redis, prompt rendering and request validation.
- **Cloud data:** Supabase Postgres with row-level security policies keyed by `auth.uid()`.
- **Extension:** Chrome Manifest V3 extension with a separate browsing-protection surface.
- **Testing:** 154 passing Flutter tests and 14 passing Python `unittest` tests, but no executable Flutter integration suite or Android instrumentation coverage.

See [repository map](01-repository-map.md) for the component and data-flow diagrams.

## Repository health assessment

| Area | Assessment | Reason |
|---|---|---|
| Product architecture | Promising but uneven | Local-first data and feature modules are strong; account boundaries and UI/service ownership are inconsistent. |
| Correctness | High risk | Focus completion and protection-mode propagation can violate the primary product promise. |
| Security | Release blocking | Backend identity bypass and cross-account local/sync leakage are confirmed. |
| Database | High risk on upgrade | Versioned migrations exist, but known partially migrated databases have no repair strategy. |
| Android native performance | Improved | Policy parsing, essential packages, and icon work are cached/backgrounded. Remaining hot-path work should be profiled. |
| Test suite | Useful but incomplete | Unit/widget suite passes; critical platform, account-switch, migration, and end-to-end paths are absent. |
| CI and reproducibility | Unhealthy | `flutter analyze` fails, formatting is substantially divergent, and the application lockfile is ignored. |
| Maintainability | Material debt | Several screens exceed 600 lines and combine UI, navigation, effects, and business coordination. |
| Release operations | Incomplete | Release signing fails open to a debug key; auth callbacks and production device verification are missing. |

## Findings by severity

| Severity | Count |
|---|---:|
| S0 — Critical | 2 |
| S1 — High | 7 |
| S2 — Medium | 11 |
| S3 — Low | 2 |
| **Total** | **22** |

The complete evidence and corrections are in [findings](02-findings.md).

## Top five risks

1. **Forged backend identity and Gemini quota abuse — S0.** The rate-limit key function decodes a token without verifying its signature, stores its `sub` on request state, and the authentication dependency trusts that state.
2. **Cross-account local data exposure and misattributed uploads — S0.** The database and sync outbox have no account owner, table cursors are global, and queued rows are mapped to whichever user is currently signed in.
3. **Duplicate focus finalization and XP — S1.** The timer finalizes a session, emits `completed`, and both focus screens respond by finalizing the same session again. The XP ledger has no source-level uniqueness guard.
4. **Selected protection level is ignored — S1.** Timer startup uses the service default (`guard`), and resume explicitly reconstructs a guard policy regardless of the user's Gentle/Guardrail/Shield choice.
5. **Upgrade, auth callback, and release configuration gaps — S1.** Known divergent databases can remain unusable; OAuth/reset callbacks have no Android or iOS scheme registration; Android release can be signed with the debug key.

## Five highest-value improvements

1. Repair the backend authentication boundary and add forged-token endpoint tests.
2. Define and implement an explicit account-isolation model for the database, sync cursors, and outbox.
3. Make focus completion a single-owner, transactional, idempotent operation.
4. Persist and honor protection strictness across start, pause, resume, rehydration, and completion.
5. Add migration fixtures and a data-preserving repair path for every shipped schema.

## Release-readiness assessment

**Decision: NO-GO for production release.**

Minimum conditions for a release candidate:

- close both S0 findings;
- close all focus-timer and protection-mode S1 findings;
- make database upgrade repairable and test real upgrade fixtures;
- register and device-test auth callbacks, or remove/disable those entry points;
- fix local-time notification scheduling;
- make Android release signing fail closed;
- restore a passing static-analysis gate;
- execute a small Android end-to-end smoke matrix on a clean install and an upgraded install.

UI decomposition and package cleanup should not delay those trust fixes, but they should follow quickly because the present screen structure makes regressions harder to contain.

## Testing assessment

`flutter test` passed all 154 tests, and the backend's 14 `unittest` cases passed. This is a useful baseline, not release proof. No runnable root `integration_test/` suite exists, and no Android instrumentation tests exercise permissions, accessibility interception, app selection, service leases, notification collection, or installed-database upgrades. Existing focus-provider tests do not mount the screens that trigger the double-completion path. Existing backend tests do not test a forged bearer token against a real endpoint.

## Security and privacy assessment

The Supabase schema correctly enables row-level security for cloud tables, and production CORS uses explicit origins. The critical security weakness is instead the backend middleware/dependency interaction. The local app also needs a deliberate account boundary. Device-attention data is stored in ordinary app storage while Android backup eligibility is left to platform defaults; the product needs an explicit retention, backup, and export policy for this sensitive dataset.

No secret values are reproduced in this audit.

## Performance assessment

No numerical performance claims are made because a profile build and device trace were not available. Code evidence supports these priorities:

- defer nonessential notification rescheduling until after the first frame;
- coalesce garden table-update events and remove per-session task lookups;
- profile the remaining telephony/audio checks in the accessibility hot path;
- remove unused packages and excessive font assets after a measured size baseline.

The previously reported Android policy parsing, essential-package lookup, and app-icon main-thread problems are **verified as addressed** by cached/background implementations.

## Recommended implementation sequence

1. **Security containment:** backend identity, account isolation decision, release-signing guard.
2. **Core product correctness:** focus finalization, protection strictness, authenticated AI client, reminder timezone.
3. **Upgrade and auth reliability:** database repair migrations and platform callback registration.
4. **State and sync foundations:** reactive auth/router ownership, resilient sync, explicit error taxonomy.
5. **Performance and maintainability:** startup deferral, garden aggregation, focused screen extraction.
6. **Release confidence:** platform integration tests, upgrade fixtures, device smoke matrix, then accessibility and package cleanup.

The dependency-aware sequence is in [implementation roadmap](03-implementation-roadmap.md).

## Important limitations

- The audit used static inspection and safe local commands; no production credentials, Supabase project, Redis, Gemini account, App Store/Play Console, or telemetry were available.
- No physical Android or iOS device was connected, so OEM accessibility behavior, deep links, notification timing, background survival, layout, screen readers, and performance require device verification.
- The Android debug build was still running at the time the initial evidence set was captured; its final status is recorded in [validation results](06-validation-results.md).
- Test coverage percentage was not generated; coverage conclusions are based on test inventory and traced critical paths.
- The working tree was already dirty. Findings describe the exact audited snapshot, including those uncommitted changes; the audit did not rewrite or revert them.


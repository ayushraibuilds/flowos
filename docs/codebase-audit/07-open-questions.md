# FlowOS Audit — Open Questions

Only questions that materially change implementation are listed. Safe defaults are containment choices, not final product decisions.

## OPEN-001 — What owns existing local data when a user first signs in or switches accounts?

- Why it matters: This determines whether FlowOS needs per-account databases, owner columns, a device-local profile, or an explicit merge/claim flow. The wrong assumption can expose or destroy data.
- Affected findings/tasks: FINDING-002, FINDING-007, FINDING-011, FINDING-012, FINDING-015; TASK-002, TASK-007, TASK-011, TASK-012, TASK-015
- Safe default assumption: One installation has one unclaimed local profile. The first account may claim it only after explicit confirmation; later accounts get isolated empty storage. Never auto-upload unowned rows after an account switch.
- Who should answer it: Product owner, privacy lead, and senior mobile/data engineer

## OPEN-002 — Should cloud AI require sign-in, or will an anonymous quota exist?

- Why it matters: The backend currently requires authentication while the app supports optional accounts. This changes UI availability, abuse controls, cost, and privacy copy.
- Affected findings/tasks: FINDING-001, FINDING-005; TASK-001, TASK-005
- Safe default assumption: Cloud AI is available only to authenticated users; local/manual alternatives remain available without sign-in.
- Who should answer it: Product owner, backend owner, and cost/security owner

## OPEN-003 — What JWT verification scheme does the production Supabase project use?

- Why it matters: The backend currently assumes a shared HS256 secret. Supabase project configuration/key rotation may require JWKS/asymmetric verification and cache behavior.
- Affected findings/tasks: FINDING-001; TASK-001
- Safe default assumption: Use Supabase's supported verified-token/JWKS path for the actual project and reject tokens when verification configuration is unavailable.
- Who should answer it: Backend/infra owner with Supabase project access

## OPEN-004 — Which application/database versions have reached real devices?

- Why it matters: A safe migration fixture matrix needs every shipped schema and the exact duplicate-column states seen on affected installations.
- Affected findings/tasks: FINDING-007, FINDING-017; TASK-007, TASK-016
- Safe default assumption: Treat versions 1–9 and both observed divergent schemas as supported until release history proves otherwise.
- Who should answer it: Release owner and mobile engineer with affected device/database access

## OPEN-005 — Is “Export/Backup Data” intended to be restorable?

- Why it matters: A readable export and a transactional backup have different completeness, schema, encryption, validation, and account-ownership requirements.
- Affected findings/tasks: FINDING-015; TASK-015
- Safe default assumption: Rename the current action to “Export selected data” and do not promise restore until round-trip tests exist.
- Who should answer it: Product owner and privacy/data owner

## OPEN-006 — Which local datasets may participate in Android/iCloud device backup?

- Why it matters: Device usage, notification counts, unlocks, protected apps, and preferences are sensitive, and partial restore can recreate schema/onboarding inconsistencies.
- Affected findings/tasks: FINDING-016, FINDING-007, FINDING-015; TASK-007, TASK-015
- Safe default assumption: Exclude sensitive attention metrics and transient policy/outbox state from platform backup; rely on explicitly scoped export/sync after review.
- Who should answer it: Privacy/legal owner, product owner, and mobile platform owner

## OPEN-007 — What is the authorized Android production signing workflow?

- Why it matters: Removing the debug fallback is straightforward, but the correct upload key, Play App Signing owner, CI secret path, and rotation policy require authority outside the repository.
- Affected findings/tasks: FINDING-009; TASK-009
- Safe default assumption: Production `release` fails without credentials; no developer machine produces a production-signed build unless explicitly authorized.
- Who should answer it: Play Console/release owner

## OPEN-008 — Are Apple Family Controls entitlements available or planned?

- Why it matters: Native iOS screen-time selection and app shielding cannot be implemented or tested to production quality without the paid developer program, entitlement approval, extension targets, and physical devices.
- Affected findings/tasks: Feature OPPORTUNITY-003
- Safe default assumption: Market iOS as local focus/planning/garden functionality only; do not promise app blocking or device screen-time tracking.
- Who should answer it: Product owner and Apple Developer account owner

## OPEN-009 — What production deployment topology and rate-limit policy will the AI backend use?

- Why it matters: Process-local SlowAPI limits multiply per worker and reset on restart. Proxy/IP handling and Redis availability affect anonymous fallback safety.
- Affected findings/tasks: FINDING-001; TASK-001
- Safe default assumption: Require Redis and trusted-proxy configuration for multi-worker production; fail deployment readiness checks if absent.
- Who should answer it: Backend/infra owner

## OPEN-010 — Which languages, device classes, orientations, and accessibility targets are launch commitments?

- Why it matters: It defines localization architecture, test matrices, copy review, and whether current fixed layouts are release blockers.
- Affected findings/tasks: FINDING-022; TASK-020
- Safe default assumption: English only for the immediate stabilization release, portrait phones as the declared layout target, WCAG-aligned contrast/touch targets, text scale through 2.0, TalkBack and VoiceOver on critical journeys. Do not claim tablet/landscape localization support until tested.
- Who should answer it: Product/design owner and accessibility QA

## OPEN-011 — Is the Chrome extension part of the same near-term product release?

- Why it matters: Account linking, token storage, browsing-data privacy, schema compatibility, and store review materially expand the release/security surface.
- Affected findings/tasks: Feature OPPORTUNITY-004; indirectly TASK-001, TASK-002, TASK-012
- Safe default assumption: Treat the extension as a separate future release; do not share production credentials or enable cross-device sync until its threat model is audited.
- Who should answer it: Product owner and extension/security owner


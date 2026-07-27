# FlowOS Feature Opportunities

Feature work should follow the trust and correctness phases. These opportunities extend capabilities already represented in the repository; they do not introduce a competing gamification system.

## Ranked overview

| Rank | Opportunity | Class | User value | Effort | Product uncertainty | Risk | Timing |
|---:|---|---|---|---|---|---|---|
| 1 | Permission and protection health center | Partially built completion | Very high | M | Low | Medium | Current roadmap, after core fixes |
| 2 | Sync status, conflict recovery, and support bundle | Reliability/UX | Very high | L | Low | Medium | Current roadmap, after account isolation |
| 3 | Explainable score and data-confidence view | Reliability/UX | High | M | Low | Low | Next cycle |
| 4 | Safe export/restore and device migration | Partially built completion | High | L | Medium | High | Current roadmap after ownership decision |
| 5 | Focus recovery and completion receipt | Reliability/UX | High | M | Low | Medium | With focus correctness |
| 6 | Garden seasons and landscape history | New product functionality | High | L | Medium | Medium | Future backlog |
| 7 | Personalized protection suggestions | New product functionality | Medium-high | L | Medium | High/privacy | Future backlog |
| 8 | iOS Screen Time and app shielding | Partially built platform completion | Very high for iOS | XL | High/external | High | Investigate |
| 9 | Browser-extension account linking | Partially built platform completion | Medium | L | Medium | High/security | Future backlog |
| 10 | Companion/avatar system beyond the garden | Speculative | Unclear | XL | Very high | High | Do not schedule |

## Completion of partially built functionality

### OPPORTUNITY-001 — Permission and protection health center

- User problem addressed: Users cannot tell whether Usage Access, accessibility protection, notification access, battery optimization exemption, and selected-app policy are all still operational after OS/OEM changes.
- Supporting evidence:
  - `MainActivity.kt` already exposes consolidated permission states and settings launchers.
  - onboarding and permission-center UI already request the integrations.
  - focus and sleep policy services already contain the relevant state.
- Proposed behavior: One trust-focused status surface showing “working,” “limited,” or “action needed,” last successful data collection, protected-app count, active policy, and a guided retest.
- Likely implementation areas: device-attention platform/repository, permission center, settings, focus/sleep policy status, diagnostics.
- Backend/product dependencies: None for local status; copy should be reviewed for Android-only limitations.
- Complexity: M
- Risk: Medium; OEM settings cannot be assumed from permission flags alone.
- Expected value: Very high because it directly reduces “I granted it but nothing works” failures.
- Timing: Current roadmap after TASK-004, TASK-008, and typed failures.

### OPPORTUNITY-002 — Safe export/restore and device migration

- User problem addressed: Local-first users need a trustworthy path to preserve or move their data.
- Supporting evidence:
  - `DataExportService` already labels a partial JSON share as backup.
  - 18 local tables and optional cloud sync already exist.
- Proposed behavior: A versioned, validated export with clear scope and privacy warning; optional restore after account-ownership rules are settled.
- Likely implementation areas: export service/models, Drift import transaction, settings, file picker/share, Android backup rules.
- Backend/product dependencies: Local/cloud ownership policy and privacy copy.
- Complexity: L
- Risk: High because import can duplicate or misattribute data.
- Expected value: High.
- Timing: Current roadmap as TASK-015 after TASK-002.

### OPPORTUNITY-003 — iOS Screen Time and app shielding

- User problem addressed: iOS users currently cannot receive the core screen-time and app-protection experience available on Android.
- Supporting evidence:
  - attention repository/platform support distinguishes Android from manual/unsupported paths;
  - onboarding contains platform-specific setup behavior;
  - product models already represent protected apps and daily attention data.
- Proposed behavior: FamilyControls authorization, app/category selection, DeviceActivity monitoring, ManagedSettings shields, and privacy-preserving aggregate reporting.
- Likely implementation areas: new iOS extension targets, entitlements, Swift platform bridge, selection token storage, Flutter capability UI.
- Backend/product dependencies: Apple Developer Program, Family Controls entitlement approval, physical iOS devices, legal/privacy review.
- Complexity: XL
- Risk: High; entitlement approval and Apple APIs constrain the design.
- Expected value: Very high for iOS, but unavailable through code alone.
- Timing: Investigate only after Android release stability and entitlement feasibility.

### OPPORTUNITY-004 — Browser-extension account linking

- User problem addressed: Focus protection can stop at the phone while distraction shifts to desktop browsing.
- Supporting evidence: `flowos-extension/` already contains a Manifest V3 extension and browsing-related cloud schema exists.
- Proposed behavior: Explicitly link the extension to a FlowOS account/device, sync only approved protection schedules/domains, and show desktop attention as a separate coverage source.
- Likely implementation areas: extension auth, backend/Supabase device registration, browsing sessions, settings and score coverage.
- Backend/product dependencies: Threat model, browser-store review, account isolation, privacy policy.
- Complexity: L
- Risk: High because browser data and tokens are sensitive.
- Expected value: Medium for cross-device users.
- Timing: Future backlog after TASK-001, TASK-002, and TASK-012.

## Reliability and UX features

### OPPORTUNITY-005 — Sync status, conflict recovery, and support bundle

- User problem addressed: Users cannot distinguish “saved locally,” “waiting to sync,” “auth expired,” and “conflict requires attention.”
- Supporting evidence: Sync status is coarse; outbox/cursors exist but have no user-facing diagnostic contract.
- Proposed behavior: A compact sync indicator with last successful time, pending count, account scope, retry action, and a redacted diagnostic bundle. Never expose raw task or notification content by default.
- Likely implementation areas: sync status model/provider, settings/account area, typed failures, export/support service.
- Backend/product dependencies: Account ownership and support/privacy policy.
- Complexity: L
- Risk: Medium.
- Expected value: Very high for trust and support load.
- Timing: Build with TASK-012 and TASK-018.

### OPPORTUNITY-006 — Explainable score and data-confidence view

- User problem addressed: A score can feel judgmental or arbitrary when permissions are absent or device coverage is incomplete.
- Supporting evidence:
  - daily scores already store component points, available weight, incomplete flag, coverage, and scoring version;
  - attention repository models native/manual/unknown coverage.
- Proposed behavior: Tapping the score reveals Focus, Intent, Attention, and Care contributions, coverage confidence, missing data, and one kind next action. Avoid ranking the person.
- Likely implementation areas: daily score snapshot/history, insights UI, permission health route.
- Backend/product dependencies: Product copy and scoring-policy approval.
- Complexity: M
- Risk: Low if it reads stored components rather than recalculating.
- Expected value: High.
- Timing: Next cycle after score/migration stability.

### OPPORTUNITY-007 — Focus recovery and completion receipt

- User problem addressed: If completion occurs while the app is backgrounded or the UI route changes, the user still needs a reliable, calm result and recovery transition.
- Supporting evidence: persisted timer rehydration exists; current duplicate-completion bug stems from combining finalization with screen effects.
- Proposed behavior: Persist a single completion receipt containing XP, garden growth, quality, and next recovery action; consume it once from any route.
- Likely implementation areas: timer state/service, completion receipt table/model or durable state, shell notification/banner, break route.
- Backend/product dependencies: None.
- Complexity: M
- Risk: Medium; receipt retention and duplicate consumption need care.
- Expected value: High and directly aligned with the garden/recovery promise.
- Timing: Implement as part of TASK-003 rather than as a separate gamification feature.

## Genuinely new product functionality

### OPPORTUNITY-008 — Garden seasons and landscape history

- User problem addressed: Users need a compassionate long-term memory of progress without streak guilt.
- Supporting evidence: daily GardenDay, week/season language, persistent seeds, landscape cards, and vector painters already exist.
- Proposed behavior: Save a completed day's composition as a stable landscape card, group weeks into seasonal chapters, and let users revisit/share a privacy-safe rendered image. Missed days remain restful/dormant rather than damaged.
- Likely implementation areas: garden snapshot schema, renderer, history screen, export/share, migrations.
- Backend/product dependencies: Art direction and retention/storage decision.
- Complexity: L
- Risk: Medium; snapshot determinism and migration size need design.
- Expected value: High retention value without adding another points system.
- Timing: Future backlog after garden query work and data portability.

### OPPORTUNITY-009 — Personalized protection suggestions from on-device patterns

- User problem addressed: Users may not know which apps or times are actually disrupting their goals.
- Supporting evidence: the app already has selected apps, usage totals, unlocks, notifications, focus windows, and coverage metadata.
- Proposed behavior: On-device, explainable suggestions such as “You usually open X during your morning focus window; add it to Guardrail?” Require confirmation and never auto-block.
- Likely implementation areas: local attention aggregation, suggestion rules, permission health, protected-app editor.
- Backend/product dependencies: Privacy/product thresholds; no cloud AI is required.
- Complexity: L
- Risk: High privacy/false-positive risk.
- Expected value: Medium-high if suggestions remain transparent and optional.
- Timing: Future backlog after measurement accuracy and account privacy are proven.

## Speculative ideas

### OPPORTUNITY-010 — A second companion or avatar progression system

- User problem addressed: Unclear; it could add emotional attachment.
- Supporting evidence: The current garden already acts as the visual companion and progress memory.
- Proposed behavior: None recommended now.
- Likely implementation areas: broad UI/art/state expansion.
- Backend/product dependencies: Significant art and product research.
- Complexity: XL
- Risk: High; dilutes the garden, duplicates gamification, and can introduce guilt mechanics.
- Expected value: Unproven.
- Timing: Do not schedule. Improve garden interaction and season history first.


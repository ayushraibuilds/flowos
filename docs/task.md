# Audit Fix — 7 Findings

## P0
- [x] P0-1: Duplicate daily plans — upsert + check in morning intention
- [x] P0-2: MITs global accumulation — clear old MITs before setting new ones

## P1
- [x] P1-1: Home completion skips XP ledger — extract TaskCompletionService
- [x] P1-2: Session sync checks wrong ID — add getById to FocusSessionsDao
- [x] P1-3: Push fallback resends all tasks — remove fallback

## P2
- [x] P2-1: Bounce-back XP TODO — wire the call
- [x] P2-2: Smoke test placeholder — replace with real test

## Verification
- [x] flutter analyze — 0 errors
- [x] flutter test — 49 tests passing

# Audit Verification — All 7 Findings Confirmed

> Verified against the live codebase at commit `3e6a8bc`. Every finding is **real and still present**.

---

## P0-1: Duplicate Daily Plans ✅ CONFIRMED — Still Broken

**The problem:** `_saveAndStart()` always does a raw `INSERT`. No check for existing plan.

**Evidence:**

- [morning_intention_screen.dart:355](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/morning_intention/morning_intention_screen.dart#L355) — `await db.dailyPlansDao.insertPlan(...)` — raw insert, no guard
- [daily_plans_dao.dart:13](file:///Users/dankmagician/Documents/New%20project/flowos/lib/data/local/dao/daily_plans_dao.dart#L13) — `insertPlan()` is a plain `into(dailyPlans).insert(entry)` — no `insertOnConflictUpdate`
- [daily_plans_table.dart:25-26](file:///Users/dankmagician/Documents/New%20project/flowos/lib/data/local/tables/daily_plans_table.dart#L25-L26) — Primary key is `{id}`, no unique constraint on `date`
- [daily_plans_dao.dart:29](file:///Users/dankmagician/Documents/New%20project/flowos/lib/data/local/dao/daily_plans_dao.dart#L29) — `getToday()` uses `getSingleOrNull()` — **will throw if 2+ rows match**

**Crash path:** User opens Morning Intention → saves → goes back → opens again → saves again → `getToday()` throws `StateError: Too many elements`.

**Fix needed:**
1. Add `@UniqueIndex` on `date` column (or date-only extraction) in the Drift table
2. Change `insertPlan` to `insertOnConflictUpdate` (upsert)
3. OR: Check `getToday()` first in `_saveAndStart()` and call `updatePlan()` if exists

---

## P0-2: MITs Are Global, Not Daily-Scoped ✅ CONFIRMED — Still Broken

**The problem:** `isMIT` is a permanent flag on the task row. Morning Intention sets it but never clears yesterday's MITs.

**Evidence:**

- [tasks_dao.dart:34-37](file:///Users/dankmagician/Documents/New%20project/flowos/lib/data/local/dao/tasks_dao.dart#L34-L37) — `getMITs()` queries `isMIT.equals(true)` with no date filter
- [morning_intention_screen.dart:367-369](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/morning_intention/morning_intention_screen.dart#L367-L369) — `toggleMIT(id, true)` for selected tasks, **never calls `toggleMIT(oldId, false)` for previous MITs**
- [dashboard_providers.dart:51](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/dashboard/providers/dashboard_providers.dart#L51) — `tasksDao.getMITs()` — used for score calculation

**Accumulation path:** Day 1 picks tasks A, B, C as MITs. Day 2 picks D, E, F. Now `getMITs()` returns 3 of {A,B,C,D,E,F} (whichever `limit(3)` picks). Dashboard score counts stale MITs. Daily report sends wrong MIT completion count.

**Fix needed:**
1. In `_saveAndStart()`: clear all existing MITs first: `await db.tasksDao.clearAllMITs();`
2. Add `clearAllMITs()` to `TasksDao`: `UPDATE tasks SET is_mit = false WHERE is_mit = true AND deleted_at IS NULL`
3. OR: Make MITs plan-scoped by reading `mit_1_id`, `mit_2_id`, `mit_3_id` from `DailyPlans` instead of from the task flag

---

## P1-1: Home MIT Completion Skips XP Ledger ✅ CONFIRMED — Still Broken

**The problem:** Two different completion paths give different XP behavior.

**Evidence — Tasks Screen (correct):**
- [tasks_screen.dart:224](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/tasks/tasks_screen.dart#L224) — Calls `completeTask(task.id, xp)`
- [tasks_screen.dart:227-236](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/tasks/tasks_screen.dart#L227-L236) — **Also appends XP ledger entry** ← ✅

**Evidence — Home Screen (broken):**
- [home_screen.dart:258](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/home/home_screen.dart#L258) — Calls `completeTask(task.id, XpConstants.mitComplete)`
- **No XP ledger entry** ← ❌

**Result:** Completing a MIT from Home updates the task's `xpEarned` field but doesn't add a row to `xp_ledger`. `lifetimeXpProvider` (which sums the ledger) won't reflect the XP. The user sees "+75 XP" on the task but their total XP doesn't increase.

**Fix needed:** Extract a shared `TaskCompletionService` that both screens call, which does:
1. `tasksDao.completeTask(id, xp)`
2. `xpLedgerDao.appendEntry(...)`
3. Check all-MITs bonus
4. Check achievements

---

## P1-2: Session Sync Checks by Task ID Instead of Session ID ✅ CONFIRMED — Still Broken

**The problem:** `_pullSessions()` uses `getByTask(serverId)` to check if a session exists locally, but `serverId` is a **session** ID, not a task ID.

**Evidence:**

- [sync_engine.dart:202](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/sync/services/sync_engine.dart#L202) — `await _db.focusSessionsDao.getByTask(serverId)` ← `serverId` is from `row['id']` (session ID)
- [focus_sessions_dao.dart:54-58](file:///Users/dankmagician/Documents/New%20project/flowos/lib/data/local/dao/focus_sessions_dao.dart#L54-L58) — `getByTask(taskId)` filters by `s.taskId.equals(taskId)` — will **never find a match** unless a task happens to have the same UUID as the session
- [sync_engine.dart:203](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/sync/services/sync_engine.dart#L203) — `locals.any((s) => s.id == serverId)` — double-checks against the wrong result set

**Result:** `getByTask(sessionId)` returns empty list → `exists` is always `false` → every pull tries to re-insert every session → insert silently fails (duplicate PK) or creates duplicates if IDs differ.

**Fix needed:**
1. Add `getById(String id)` to `FocusSessionsDao`
2. Change line 202 to: `final existing = await _db.focusSessionsDao.getById(serverId);`
3. Change existence check to: `if (existing == null) { insert... }`

---

## P1-3: Push Tasks Fallback Resends Everything ✅ CONFIRMED — Still Broken

**The problem:** When `getModifiedSince(lastSync)` returns empty, the code falls back to `getAllActive()`.

**Evidence:**

- [sync_engine.dart:296](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/sync/services/sync_engine.dart#L296) — `final tasks = await _db.tasksDao.getAllActive();`
- [sync_engine.dart:298](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/sync/services/sync_engine.dart#L298) — `final allTasks = await _db.tasksDao.getModifiedSince(lastSync);`
- [sync_engine.dart:299](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/sync/services/sync_engine.dart#L299) — `final toPush = allTasks.isNotEmpty ? allTasks : tasks;` ← **falls back to ALL active tasks**

**Result:** After a clean sync with no local changes, `getModifiedSince` returns `[]`, so `toPush` becomes all active tasks. Every `fullSync()` re-upserts the entire task list to Supabase. This is wasted bandwidth and could overwrite newer server-side data (LWW uses `updated_at`, but the local `updated_at` hasn't changed, so it's a no-op — just wasteful).

**Fix needed:** Remove the fallback. If nothing was modified since last sync, push nothing:
```dart
final toPush = await _db.tasksDao.getModifiedSince(lastSync);
if (toPush.isEmpty) return 0;
```

---

## P2-1: Bounce-Back XP Promised But Not Awarded ✅ CONFIRMED — Still Broken

**Evidence:**

- [scroll_tracker_screen.dart:456](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart#L456) — UI shows: `'Bounce back? Pick a recovery action for +25 XP 🔄'`
- [scroll_tracker_screen.dart:470](file:///Users/dankmagician/Documents/New%20project/flowos/lib/presentation/screens/scroll_tracker/scroll_tracker_screen.dart#L470) — `// TODO: Award bounce-back XP, start action`

The method `XpCalculator.awardBounceBackBonus()` exists and works ([xp_calculator.dart:186-198](file:///Users/dankmagician/Documents/New%20project/flowos/lib/features/xp/models/xp_calculator.dart#L186-L198)). It just needs to be called.

**Fix:** Add after line 469:
```dart
final xpCalc = XpCalculator(ref.read(databaseProvider).xpLedgerDao);
await xpCalc.awardBounceBackBonus(action.type);
```

---

## P2-2: Smoke Test Asserts 1+1=2 ✅ CONFIRMED — Still There

**Evidence:**

- [widget_test.dart:6](file:///Users/dankmagician/Documents/New%20project/flowos/test/widget_test.dart#L6) — `expect(1 + 1, 2);`

This test passes but tests nothing about FlowOS. The 48 real tests are in `xp_constants_test.dart` (22) and `daily_score_calculator_test.dart` (26+). The "smoke test" is meaningless.

**Fix:** Either delete it or replace with a real app-startup test (pump `MaterialApp` with `ProviderScope` and check for a widget).

---

## Summary

| Finding | Priority | Status | Effort |
|---------|----------|--------|--------|
| Duplicate daily plans (crash on 2nd Morning Intention) | **P0** | ❌ Unfixed | ~30 min |
| MITs accumulate globally across days | **P0** | ❌ Unfixed | ~45 min |
| Home completion skips XP ledger | **P1** | ❌ Unfixed | ~1 hr (extract service) |
| Session sync checks wrong ID | **P1** | ❌ Unfixed | ~15 min |
| Push fallback resends all tasks | **P1** | ❌ Unfixed | ~10 min |
| Bounce-back XP TODO | **P2** | ❌ Unfixed | ~5 min |
| Placeholder smoke test | **P2** | ❌ Unfixed | ~20 min |

> [!IMPORTANT]
> **All 7 findings are real and unfixed.** The two P0s are the most dangerous — P0-1 can crash the app, and P0-2 silently corrupts the dashboard score over time. Both are in the Morning Intention flow that runs every day.

### Do you want me to fix all 7 now?

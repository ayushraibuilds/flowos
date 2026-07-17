import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';

const _uuid = Uuid();

/// Morning Intention — start your day with energy, MITs, and scroll budget.
class MorningIntentionScreen extends ConsumerStatefulWidget {
  const MorningIntentionScreen({super.key});

  @override
  ConsumerState<MorningIntentionScreen> createState() =>
      _MorningIntentionScreenState();
}

class _MorningIntentionScreenState
    extends ConsumerState<MorningIntentionScreen> {
  int _energy = 3; // 1-5
  int _scrollBudget = 30; // minutes
  final _energyEmojis = ['😴', '😐', '🙂', '⚡', '🔥'];
  final Set<String> _selectedMitIds = {};
  List<Task> _incompleteTasks = [];
  bool _saving = false;

  final _inlineTitleController = TextEditingController();
  int _inlineEnergy = 1; // 0=deep, 1=medium, 2=light
  int _inlineMinutes = 25;
  bool _showAddTaskForm = false;

  @override
  void dispose() {
    _inlineTitleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final db = ref.read(databaseProvider);
    final tasks = await db.tasksDao.getIncomplete();
    if (mounted) {
      setState(() => _incompleteTasks = tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxxl * 2),
              // ─── Greeting ─────────────────────────────────────
              Text(
                '$greeting.',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dateStr,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Quote ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border(
                    left: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
                child: Text(
                  '"Energy, not time, is the fundamental currency of high performance."\n— Jim Loehr',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Energy Check-in ──────────────────────────────
              Text(
                "How's your energy right now?",
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final isActive = i == _energy - 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _energy = i + 1);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.emerald.withValues(alpha: 0.15)
                            : AppColors.background2,
                        border: Border.all(
                          color: isActive
                              ? AppColors.emerald
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _energyEmojis[i],
                          style: TextStyle(fontSize: isActive ? 24 : 20),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── MITs ─────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pick 3 MITs for today',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // MITs from real task list
              if (_incompleteTasks.isEmpty && !_showAddTaskForm)
                GestureDetector(
                  onTap: () => setState(() => _showAddTaskForm = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No tasks yet — tap to add one',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showAddTaskForm)
                _buildInlineAddTaskForm(),
              if (_incompleteTasks.isNotEmpty)
                ..._incompleteTasks.map((task) {
                  final isSelected = _selectedMitIds.contains(task.id);
                  final energyEmoji = switch (task.energyLevel) {
                    EnergyLevelColumn.deep => '🔥',
                    EnergyLevelColumn.medium => '⚡',
                    EnergyLevelColumn.light => '🌿',
                  };
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSelected) {
                          _selectedMitIds.remove(task.id);
                        } else if (_selectedMitIds.length < 3) {
                          _selectedMitIds.add(task.id);
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.emerald.withValues(alpha: 0.1)
                            : AppColors.background2,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.emerald
                              : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.emerald
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.emerald
                                    : AppColors.textTertiary,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(energyEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              task.title,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${task.estimatedMinutes}m',
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (_incompleteTasks.isNotEmpty && !_showAddTaskForm)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _showAddTaskForm = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background2,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.emerald),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Add a task',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_selectedMitIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '${_selectedMitIds.length}/3 MITs selected',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Scroll Budget ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's scroll budget",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_scrollBudget > 0) {
                            setState(() => _scrollBudget -= 5);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 20, color: AppColors.textSecondary),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      Text(
                        '${_scrollBudget}m',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _scrollBudget += 5);
                        },
                        icon: const Icon(Icons.add_circle_outline,
                            size: 20, color: AppColors.textSecondary),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Start Your Day CTA ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAndStart,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Start Your Day'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndStart() async {
    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final db = ref.read(databaseProvider);
    final mitIds = _selectedMitIds.toList();
    final planId = _uuid.v4();

    // P0-1 fix: Upsert today's plan (safe to call multiple times per day)
    final savedPlanId = await db.dailyPlansDao.upsertToday(DailyPlansCompanion(
      id: Value(planId),
      date: Value(DateTime.now()),
      mit1Id: Value(mitIds.isNotEmpty ? mitIds[0] : null),
      mit2Id: Value(mitIds.length > 1 ? mitIds[1] : null),
      mit3Id: Value(mitIds.length > 2 ? mitIds[2] : null),
      morningEnergy: Value(_energy),
      scrollBudgetMinutes: Value(_scrollBudget),
      intentionCompleted: const Value(true),
    ));

    // P0-2 fix: Clear all existing MITs before setting today's new ones.
    // This prevents stale MITs from previous days accumulating.
    await db.tasksDao.clearAllMITs();

    // Mark selected tasks as MITs
    for (final id in mitIds) {
      await db.tasksDao.toggleMIT(id, true);
    }

    // Award intention XP
    await db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.focusRitualComplete),
      pointsDelta: const Value(XpConstants.focusRitualComplete),
      sourceEntityId: Value(savedPlanId),
      explanation: const Value('Completed morning intention ritual'),
    ));

    if (mounted) context.go('/home');
  }

  Widget _buildInlineAddTaskForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inlineTitleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Task title...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAddTaskForm = false),
                child: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          // Energy level chips
          Row(
            children: [
              _inlineEnergyChip(0, '🔥', 'Deep'),
              const SizedBox(width: AppSpacing.xs),
              _inlineEnergyChip(1, '⚡', 'Med'),
              const SizedBox(width: AppSpacing.xs),
              _inlineEnergyChip(2, '🌿', 'Light'),
              const Spacer(),
              // Time stepper
              GestureDetector(
                onTap: () {
                  if (_inlineMinutes > 5) setState(() => _inlineMinutes -= 5);
                },
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background0,
                  ),
                  child: const Icon(Icons.remove, size: 14, color: Colors.white54),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '${_inlineMinutes}m',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _inlineMinutes += 5),
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background0,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white54),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _saveInlineTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
                elevation: 0,
              ),
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineEnergyChip(int index, String emoji, String label) {
    final isSelected = _inlineEnergy == index;
    return GestureDetector(
      onTap: () => setState(() => _inlineEnergy = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emerald.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(
            color: isSelected
                ? AppColors.emerald
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '$emoji $label',
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.emerald : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Future<void> _saveInlineTask() async {
    final title = _inlineTitleController.text.trim();
    if (title.isEmpty) return;
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    await db.tasksDao.insertTask(TasksCompanion(
      id: Value(id),
      title: Value(title),
      energyLevel: Value(EnergyLevelColumn.values[_inlineEnergy]),
      estimatedMinutes: Value(_inlineMinutes),
      isMIT: const Value(false),
      category: const Value(TaskCategoryColumn.personal),
    ));
    _inlineTitleController.clear();
    setState(() {
      _inlineEnergy = 1;
      _inlineMinutes = 25;
      _showAddTaskForm = false;
    });
    await _loadTasks();
  }
}

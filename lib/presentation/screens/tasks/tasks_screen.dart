import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../features/tasks/providers/task_providers.dart';
import '../../../features/tasks/services/task_completion_service.dart';
import '../../widgets/task_card.dart';
import '../../widgets/state_widgets.dart';

const _uuid = Uuid();

/// Tasks screen — energy-grouped task list with add, reorder, and complete.
/// Now wired to Drift DAOs for real persistence.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _selectedSegment = 0;
  final _segments = ['All', '🔥 Deep', '⚡ Med', '🌿 Light'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // ─── Title + Brain Dump ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _buildSmallButton('🧠 Brain Dump', () {}),
                      const SizedBox(width: AppSpacing.sm),
                      _buildSmallButton('🎲 Roulette', () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ─── Segmented Control ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _buildSegmentedControl(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ─── Task List ────────────────────────────────────────
            Expanded(
              child: _buildTaskList(),
            ),
          ],
        ),
      ),
      // ─── Add Task FAB ─────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.emerald,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }

  Widget _buildSmallButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      child: Row(
        children: List.generate(_segments.length, (i) {
          final isActive = i == _selectedSegment;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSegment = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.background3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Text(
                  _segments[i],
                  style: AppTypography.bodySmall.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasksAsync = ref.watch(activeTasksProvider);

    return tasksAsync.when(
      loading: () => const FlowLoadingState(message: 'Loading tasks...'),
      error: (e, _) => FlowErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(activeTasksProvider),
      ),
      data: (tasks) {
        // Filter by energy segment
        final filtered = _selectedSegment == 0
            ? tasks
            : tasks.where((t) {
                return t.energyLevel == EnergyLevelColumn.values[_selectedSegment - 1];
              }).toList();

        if (filtered.isEmpty) {
          if (_selectedSegment > 0 && tasks.isNotEmpty) {
            return Center(
              child: Text(
                'No ${_segments[_selectedSegment]} tasks',
                style: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            );
          }
          return FlowEmptyState.tasks(
            onAdd: () => _showAddTaskSheet(context),
          );
        }

        // Group: incomplete first, then completed
        final incomplete = filtered.where((t) => !t.isCompleted).toList();
        final completed = filtered.where((t) => t.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            // Incomplete tasks
            ...incomplete.map((task) => TaskCard(
                  task: task,
                  onComplete: () => _completeTask(task),
                  onDelete: () => _deleteTask(task),
                  onTap: () => _startDeepWork(task),
                )),

            // Completed section
            if (completed.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Completed (${completed.length})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...completed.map((task) => TaskCard(
                    task: task,
                    onComplete: () {},
                    onDelete: () => _deleteTask(task),
                  )),
            ],

            const SizedBox(height: 80), // FAB clearance
          ],
        );
      },
    );
  }

  Future<void> _completeTask(Task task) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final service = TaskCompletionService(db);

    final xp = await service.completeTask(task);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$xp XP! ${task.isMIT ? "⭐ MIT done!" : "Task done!"}'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startDeepWork(Task task) {
    context.push('/deep-work', extra: {
      'taskId': task.id,
      'taskTitle': task.title,
    });
  }

  Future<void> _deleteTask(Task task) async {
    final db = ref.read(databaseProvider);
    await db.tasksDao.softDelete(task.id);
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddTaskSheet(),
    );
  }
}

/// Add task bottom sheet — title, energy, estimated time, MIT toggle.
/// Now persists to Drift via TasksDao.
class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _titleController = TextEditingController();
  int _selectedEnergy = 1; // 0=deep, 1=medium, 2=light
  int _estimatedMinutes = 25;
  bool _isMIT = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'New Task',
            style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Title
          TextField(
            controller: _titleController,
            autofocus: true,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'What needs to be done?'),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Energy picker
          Text(
            'Energy Level',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _energyButton(0, '🔥 Deep', AppColors.energyDeep),
              const SizedBox(width: AppSpacing.sm),
              _energyButton(1, '⚡ Medium', AppColors.energyMedium),
              const SizedBox(width: AppSpacing.sm),
              _energyButton(2, '🌿 Light', AppColors.energyLight),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Estimated time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Time',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_estimatedMinutes > 5) {
                        setState(() => _estimatedMinutes -= 5);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  Text(
                    '${_estimatedMinutes}m',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _estimatedMinutes += 5);
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ],
          ),
          // MIT toggle
          SwitchListTile(
            title: Text(
              '⭐ Mark as MIT',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Most Important Task for today',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            value: _isMIT,
            onChanged: (v) => setState(() => _isMIT = v),
            activeTrackColor: AppColors.emerald,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTask,
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.mediumImpact();

    final db = ref.read(databaseProvider);
    final id = _uuid.v4();

    await db.tasksDao.insertTask(TasksCompanion(
      id: Value(id),
      title: Value(title),
      energyLevel: Value(EnergyLevelColumn.values[_selectedEnergy]),
      estimatedMinutes: Value(_estimatedMinutes),
      isMIT: Value(_isMIT),
      category: const Value(TaskCategoryColumn.personal),
    ));

    if (mounted) Navigator.pop(context);
  }

  Widget _energyButton(int index, String label, Color color) {
    final isSelected = _selectedEnergy == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedEnergy = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

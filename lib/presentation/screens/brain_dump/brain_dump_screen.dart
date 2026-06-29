import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/ai/services/ai_service.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';

/// Brain Dump Screen — text input → AI sorts → accept/edit flow.
/// User dumps thoughts, AI organizes into actionable tasks with
/// energy levels and friction scores.
class BrainDumpScreen extends ConsumerStatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  ConsumerState<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends ConsumerState<BrainDumpScreen> {
  final _textController = TextEditingController();
  bool _processing = false;
  List<BrainDumpTask>? _sortedTasks;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _processDump() async {
    if (_textController.text.trim().length < 3) return;

    HapticFeedback.mediumImpact();
    setState(() => _processing = true);

    final db = ref.read(databaseProvider);
    final latestCheckin = await db.energyCheckInsDao.getLatest();
    final energy = latestCheckin?.value ?? 3;

    final aiService = AiService();
    final tasks = await aiService.processBrainDump(
      rawText: _textController.text.trim(),
      currentEnergy: energy,
    );

    setState(() {
      _processing = false;
      _sortedTasks = tasks;
    });

    if (tasks == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI unavailable. Try again or add tasks manually.'),
            backgroundColor: AppColors.dangerCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text('Brain Dump',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: _sortedTasks != null
            ? _buildResults()
            : _buildInput(),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            '🧠 Dump everything.',
            style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Write everything on your mind. Don't organize — just pour it out. AI will sort it.",
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Need to call the dentist...\nFinish the report for work\nGroceries - milk, eggs\nResearch that API integration\nClean up the garage\nSchedule team meeting...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.6,
                ),
                filled: true,
                fillColor: AppColors.background2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : _processDump,
              child: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Text('Sort with AI ✨'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${_sortedTasks!.length} tasks extracted',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Review and accept the ones you want to add.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Task list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: _sortedTasks!.length,
            itemBuilder: (context, i) {
              final task = _sortedTasks![i];
              final energyColor = switch (task.energyLevel) {
                'deep' => AppColors.energyDeep,
                'medium' => AppColors.energyMedium,
                _ => AppColors.energyLight,
              };
              final energyEmoji = switch (task.energyLevel) {
                'deep' => '🔥',
                'medium' => '⚡',
                _ => '🌿',
              };

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: energyColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Order badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: energyColor.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              '${task.suggestedOrder}',
                              style: AppTypography.caption.copyWith(
                                color: energyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Meta row
                    Row(
                      children: [
                        Text(
                          '$energyEmoji ${task.energyLevel}',
                          style: AppTypography.caption.copyWith(
                            color: energyColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${task.estimatedMinutes}m',
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _frictionBar(task.frictionScore),
                      ],
                    ),
                    if (task.reasoning.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        task.reasoning,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _sortedTasks = null);
                  },
                  child: const Text('Redo'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    if (_sortedTasks != null) {
                      final db = ref.read(databaseProvider);
                      for (final task in _sortedTasks!) {
                        final id = const Uuid().v4();
                        await db.tasksDao.insertTask(TasksCompanion(
                          id: Value(id),
                          title: Value(task.title),
                          energyLevel: Value(_parseEnergyLevel(task.energyLevel)),
                          estimatedMinutes: Value(task.estimatedMinutes),
                          frictionScore: Value((task.frictionScore * 100).round()),
                          category: const Value(TaskCategoryColumn.personal),
                          description: Value(task.reasoning),
                        ));
                      }
                    }
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Add All Tasks'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _frictionBar(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'friction',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 3,
              backgroundColor: AppColors.background0,
              valueColor: AlwaysStoppedAnimation(
                score > 0.7
                    ? AppColors.dangerCoral
                    : score > 0.4
                        ? AppColors.warningAmber
                        : AppColors.emerald,
              ),
            ),
          ),
        ),
      ],
    );
  }

  EnergyLevelColumn _parseEnergyLevel(String level) {
    switch (level.toLowerCase()) {
      case 'deep':
        return EnergyLevelColumn.deep;
      case 'light':
        return EnergyLevelColumn.light;
      case 'medium':
      default:
        return EnergyLevelColumn.medium;
    }
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/motion_tokens.dart';
import '../models/garden_day.dart';
import 'garden_object_painter.dart';

/// Shared, animated garden canvas used both on Home and in the full Garden.
///
/// The plot deliberately animates only a little: plants breathe and wildlife
/// drifts, while reduced-motion users see the same composition at rest.
class GardenPlot extends StatefulWidget {
  final GardenDay day;
  final double height;
  final String? animateObjectId;
  final bool showCopy;

  const GardenPlot({
    super.key,
    required this.day,
    this.height = 240,
    this.animateObjectId,
    this.showCopy = true,
  });

  @override
  State<GardenPlot> createState() => _GardenPlotState();
}

class _GardenPlotState extends State<GardenPlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldReduce = MediaQuery.of(context).disableAnimations;
    if (shouldReduce == _reduceMotion) return;
    _reduceMotion = shouldReduce;
    if (_reduceMotion) {
      _idleController.stop();
    } else {
      _idleController.repeat();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _handleObjectTap(GardenObject object) async {
    if (object.kind == GardenObjectKind.wildlife) {
      context.push(
        '/rest',
        extra: const {'defaultMinutes': 2, 'autoStart': true},
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _GardenRecordSheet(
        day: widget.day,
        object: object,
        onStartFocus: object.focusMinutes == null
            ? null
            : () {
                sheetContext.pop();
                context.push('/focus');
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        gradient: const LinearGradient(
          colors: [Color(0xFF102A34), Color(0xFF102118), Color(0xFF171A17)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _idleController,
          builder: (context, _) {
            final idle = _reduceMotion ? 0.0 : _idleController.value;
            return Stack(
              children: [
                Positioned(
                  top: -height * 0.34,
                  right: -height * 0.20,
                  child: Container(
                    width: height * 0.65,
                    height: height * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.recoveryTeal.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -height * 0.32,
                  child: Container(
                    height: height * 0.62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF263321),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.elliptical(
                          constraints.maxWidth,
                          height * 0.22,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.day.isResting)
                  Align(
                    alignment: const Alignment(0, 0.22),
                    child: RestingMoonArtwork(size: 48, idleValue: idle),
                  ),
                ...widget.day.objects.map(
                  (object) => _GardenObjectNode(
                    object: object,
                    idleValue: idle,
                    isGrowing: widget.animateObjectId == object.id,
                    canvasWidth: constraints.maxWidth,
                    canvasHeight: height,
                    onTap: () => _handleObjectTap(object),
                  ),
                ),
                if (widget.showCopy)
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.day.headline,
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.day.supportingText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GardenObjectNode extends StatelessWidget {
  final GardenObject object;
  final double idleValue;
  final bool isGrowing;
  final double canvasWidth;
  final double canvasHeight;
  final VoidCallback onTap;

  const _GardenObjectNode({
    required this.object,
    required this.idleValue,
    required this.isGrowing,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = object.kind == GardenObjectKind.tree ? 50.0 : 38.0;
    final phase = idleValue * math.pi * 2 + (object.x * 7.0);
    final amplitude = switch (object.kind) {
      GardenObjectKind.wildlife => 4.0,
      GardenObjectKind.tree => 1.2,
      GardenObjectKind.flower => 1.8,
      _ => 1.0,
    };
    final dy = math.sin(phase) * amplitude;
    final dx = object.kind == GardenObjectKind.wildlife
        ? math.cos(phase) * 2.2
        : 0.0;
    final scale =
        1 +
        math.sin(phase) *
            (object.kind == GardenObjectKind.wildlife ? .035 : .018);
    final label = object.focusMinutes == null
        ? '${object.title}. ${object.detail ?? 'Open its garden note.'}'
        : '${object.title}, grown from a ${object.focusMinutes}-minute focus session. ${object.detail ?? 'Open its session record.'}';

    return Positioned(
      left: canvasWidth * object.x - size / 2,
      top: canvasHeight * object.y - size / 2,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedScale(
            duration: MotionTokens.resolve(context, MotionTokens.dramatic),
            curve: Curves.elasticOut,
            scale: isGrowing ? 1.24 : 1,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                child: GardenObjectArtwork(object: object, size: size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenRecordSheet extends StatelessWidget {
  final GardenDay day;
  final GardenObject object;
  final VoidCallback? onStartFocus;

  const _GardenRecordSheet({
    required this.day,
    required this.object,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(day.date);
    final isFocusObject = object.focusMinutes != null;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.emerald.withValues(alpha: .25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                GardenObjectArtwork(object: object, size: 54),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        object.title,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        date,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFocusObject
                  ? '${object.focusMinutes} minutes of focus grew this ${object.kind == GardenObjectKind.tree ? 'tree' : 'flower'}.'
                  : object.detail ??
                        'A small moment of care is part of this landscape.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isFocusObject && object.detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Task: ${object.detail}',
                style: AppTypography.caption.copyWith(color: AppColors.emerald),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Close'),
                  ),
                ),
                if (onStartFocus != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onStartFocus,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Plant another'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

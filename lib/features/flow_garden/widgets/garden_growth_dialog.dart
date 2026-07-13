import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/garden_day.dart';

/// Shown before recovery: the same session seed visibly becomes its garden object.
class GardenGrowthDialog extends StatefulWidget {
  final GardenObject object;

  const GardenGrowthDialog({super.key, required this.object});

  static Future<void> celebrate(BuildContext context, GardenObject object) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.background0.withValues(alpha: 0.88),
      builder: (_) => GardenGrowthDialog(object: object),
    );
  }

  @override
  State<GardenGrowthDialog> createState() => _GardenGrowthDialogState();
}

class _GardenGrowthDialogState extends State<GardenGrowthDialog> {
  bool _grown = false;
  Timer? _growTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _growTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _grown = true);
    });
    _closeTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _growTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.38)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your focus took root',
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedScale(
              scale: _grown ? 1.28 : 0.78,
              duration: const Duration(milliseconds: 780),
              curve: Curves.elasticOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  _grown ? object.emoji : object.seedEmoji,
                  key: ValueKey(_grown),
                  style: const TextStyle(fontSize: 68),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              object.detail ?? object.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'It’s waiting in today’s plot.',
              style: AppTypography.caption.copyWith(color: AppColors.emerald),
            ),
          ],
        ),
      ),
    );
  }
}

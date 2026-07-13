import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ScrollIntentSheet extends StatelessWidget {
  const ScrollIntentSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ScrollIntentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      (key: 'reply', emoji: '💬', title: 'Reply to someone', desc: 'Direct communication check-in'),
      (key: 'lookup', emoji: '🔍', title: 'Look something up', desc: 'Specific query search'),
      (key: 'rest', emoji: '🔋', title: 'Take a rest break', desc: 'Step away to recharge without screen scrolling'),
      (key: 'avoiding', emoji: '🫣', title: "I'm avoiding something", desc: 'Resistance check-in'),
      (key: 'scrolling', emoji: '📱', title: 'Just scrolling', desc: 'Honest casual browsing'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusCard),
          topRight: Radius.circular(AppSpacing.radiusCard),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                color: AppColors.background2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'What are you here for?',
            style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Setting a clear intent preserves focus and agency.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Options list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final opt = options[index];
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, opt.key);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      children: [
                        Text(opt.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.desc,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WellbeingGuideCard {
  final String icon;
  final String title;
  final String content;

  const WellbeingGuideCard({
    required this.icon,
    required this.title,
    required this.content,
  });
}

/// A swipable carousel of recovery and wellbeing guides for break sessions.
class WellbeingGuideCards extends StatelessWidget {
  const WellbeingGuideCards({super.key});

  static const List<WellbeingGuideCard> guides = [
    WellbeingGuideCard(
      icon: '🧘',
      title: 'Neck Release',
      content: 'Drop your left ear towards your left shoulder. Hold for 15 seconds, taking deep breaths. Repeat on the right side to release screen tension.',
    ),
    WellbeingGuideCard(
      icon: '👁️',
      title: '20-20-20 Eye Detox',
      content: 'Look away from your screen. Focus on an object 20 feet away for 20 seconds. Roll your eyes slowly clockwise, then counter-clockwise.',
    ),
    WellbeingGuideCard(
      icon: '💪',
      title: 'Shoulder Shrugs',
      content: 'Shrug your shoulders up towards your ears. Hold for 3 seconds, then roll them back and drop them down. Repeat 5 times to loosen up.',
    ),
    WellbeingGuideCard(
      icon: '💧',
      title: 'Hydro Focus',
      content: 'Drink a glass of water. Dehydration causes a drop in concentration and cognitive processing speed. Replenish your mind.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery Tips',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: PageView.builder(
            itemCount: guides.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final item = guides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              item.content,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

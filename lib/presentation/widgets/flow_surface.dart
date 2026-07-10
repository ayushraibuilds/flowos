import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum FlowSurfaceVariant {
  standard,
  elevated,
  floating,
}

/// A reusable glassmorphic surface component for FlowOS.
/// Unifies container styling across screens using defined glass tokens.
class FlowSurface extends StatelessWidget {
  const FlowSurface({
    super.key,
    required this.child,
    this.variant = FlowSurfaceVariant.standard,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final FlowSurfaceVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final finalBorderRadius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusCard);

    // Fetch theme-based configurations mapping to defined glass tokens
    final Color tintColor;
    final double blurAmount;
    final BoxBorder finalBorder;

    switch (variant) {
      case FlowSurfaceVariant.standard:
        tintColor = AppColors.background2.withValues(alpha: 0.72);
        blurAmount = AppColors.glassBlur;
        finalBorder = border ?? Border.all(color: AppColors.glassBorder, width: 0.5);
        break;
      case FlowSurfaceVariant.elevated:
        tintColor = AppColors.background3.withValues(alpha: 0.80);
        blurAmount = AppColors.glassElevatedBlur;
        finalBorder = border ?? Border.all(color: AppColors.glassElevatedBorder, width: 0.5);
        break;
      case FlowSurfaceVariant.floating:
        tintColor = AppColors.background3.withValues(alpha: 0.85);
        blurAmount = AppColors.glassFloatingBlur;
        finalBorder = border ?? Border.all(color: AppColors.glassFloatingBorder, width: 0.5);
        break;
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: finalBorderRadius,
        boxShadow: variant == FlowSurfaceVariant.floating
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: finalBorderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius: finalBorderRadius,
              border: finalBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

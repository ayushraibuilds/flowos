import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A short user-selected pause before ending a protected focus session.
class IntentionalExitDialog extends StatefulWidget {
  const IntentionalExitDialog({super.key});

  static Future<bool> confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => const IntentionalExitDialog(),
        ) ??
        false;
  }

  @override
  State<IntentionalExitDialog> createState() => _IntentionalExitDialogState();
}

class _IntentionalExitDialogState extends State<IntentionalExitDialog> {
  int _seconds = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
      }
      if (mounted) setState(() => _seconds = (_seconds - 1).clamp(0, 5));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEnd = _seconds == 0;
    return AlertDialog(
      backgroundColor: AppColors.background2,
      title: Text(
        'Take one breath',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      content: Text(
        'You chose Intentional Exit. You can pause instead, or end this session after a short moment.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep focus'),
        ),
        TextButton(
          onPressed: canEnd ? () => Navigator.of(context).pop(true) : null,
          child: Text(canEnd ? 'End session' : 'End in $_seconds s'),
        ),
      ],
    );
  }
}

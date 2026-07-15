import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/effective_policy.dart';
import '../../../data/local/database/app_database.dart';
import '../../../core/config/supabase_config.dart';
import '../../../features/sync/providers/sync_providers.dart';

/// Full-screen, premium focus protection shield overlay.
/// Displayed when a blocked app is intercepted.
class FocusShieldOverlay extends ConsumerStatefulWidget {
  final String packageName;
  final String appDisplayName;
  final ProtectionMode protectionMode;
  final VoidCallback onKeepFocus;
  final VoidCallback onCancelSession;
  final Function(int minutes)? onGrantBreak;
  final bool bypassAllowed;

  const FocusShieldOverlay({
    super.key,
    required this.packageName,
    required this.appDisplayName,
    required this.protectionMode,
    required this.onKeepFocus,
    required this.onCancelSession,
    this.onGrantBreak,
    this.bypassAllowed = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String packageName,
    required String appDisplayName,
    required ProtectionMode protectionMode,
    required VoidCallback onKeepFocus,
    required VoidCallback onCancelSession,
    Function(int minutes)? onGrantBreak,
    bool bypassAllowed = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.background0.withValues(alpha: 0.96),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => FocusShieldOverlay(
        packageName: packageName,
        appDisplayName: appDisplayName,
        protectionMode: protectionMode,
        onKeepFocus: () {
          Navigator.pop(ctx);
          onKeepFocus();
        },
        onCancelSession: () {
          Navigator.pop(ctx);
          onCancelSession();
        },
        onGrantBreak: onGrantBreak != null
            ? (min) {
                Navigator.pop(ctx);
                onGrantBreak(min);
              }
            : null,
        bypassAllowed: bypassAllowed,
      ),
    );
  }

  @override
  ConsumerState<FocusShieldOverlay> createState() => _FocusShieldOverlayState();
}

class _FocusShieldOverlayState extends ConsumerState<FocusShieldOverlay>
    with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  bool _canAction = false;
  int _selectedBreakMinutes = 5;

  Future<void> _logUnlockAttempt({
    required String outcome,
    required int breakMinutes,
    String? intention,
  }) async {
    try {
      final db = ref.read(databaseProvider);
      final id = const Uuid().v4();
      await db.unlockAttemptsDao.insertAttempt(
        UnlockAttemptsCompanion(
          id: Value(id),
          platform: const Value('android'),
          target: Value(widget.packageName),
          level: Value(widget.protectionMode.name),
          requestedBreakMinutes: Value(breakMinutes),
          intention: Value(intention),
          waitOutcome: Value(outcome),
          sessionId: const Value(null),
          timestamp: Value(DateTime.now()),
        ),
      );
      if (SupabaseConfig.isConfigured) {
        ref.read(syncEngineProvider).schedulePush();
      }
    } catch (e) {
      debugPrint('Error logging unlock attempt: $e');
    }
  }

  Future<void> _showIntentionDialog(int breakMinutes) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'State your Intention',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why do you need to unlock ${widget.appDisplayName} right now?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Checking flight status, quick update...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.dangerCoral),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(
              'Skip',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              'Confirm',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.dangerCoral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _logUnlockAttempt(
        outcome: 'completed_wait',
        breakMinutes: breakMinutes,
        intention: result.isNotEmpty ? result : null,
      );
      widget.onGrantBreak?.call(breakMinutes);
    }
  }

  Future<void> _handleResumeFocus() async {
    await _logUnlockAttempt(
      outcome: 'returned_to_focus',
      breakMinutes: 0,
    );
    widget.onKeepFocus();
  }

  Future<void> _handleCancelSession() async {
    await _logUnlockAttempt(
      outcome: 'session_cancelled',
      breakMinutes: 0,
    );
    widget.onCancelSession();
  }

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Guard mode has a 20-second countdown before showing break buttons.
    // Deep mode has a 30-second reflection countdown before showing the give-up button.
    // Nudge mode has a short 10-second countdown.
    _secondsRemaining = switch (widget.protectionMode) {
      ProtectionMode.nudge || ProtectionMode.guard => 20,
      ProtectionMode.deep => 30,
    };

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsRemaining = 0;
            _canAction = true;
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
          if (_secondsRemaining <= 5) {
            HapticFeedback.lightImpact();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background2,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dangerCoral.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.protectionMode == ProtectionMode.deep
                          ? Icons.gpp_bad_outlined
                          : Icons.shield_outlined,
                      color: AppColors.dangerCoral,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                '${widget.appDisplayName} is shielded',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _getInstructionText(),
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background1,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_canAction)
                        CircularProgressIndicator(
                          value: _secondsRemaining /
                              (widget.protectionMode == ProtectionMode.nudge
                                  ? 10
                                  : widget.protectionMode == ProtectionMode.guard
                                      ? 20
                                      : 30),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dangerCoral),
                          backgroundColor: AppColors.background2,
                          strokeWidth: 4,
                        ),
                      if (!_canAction)
                        Text(
                          '$_secondsRemaining',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.dangerCoral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_canAction) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 32,
                          color: AppColors.emerald,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),

              // Actions Block
              if (_canAction) ...[
                if ((widget.protectionMode == ProtectionMode.guard || widget.protectionMode == ProtectionMode.nudge) && widget.bypassAllowed) ...[
                  ElevatedButton(
                    onPressed: _handleResumeFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Resume Focus'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showIntentionDialog(_selectedBreakMinutes),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Take a break'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBreakDurationSelector(),
                ] else ...[
                  ElevatedButton(
                    onPressed: _handleResumeFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Resume'),
                  ),
                  if (widget.protectionMode == ProtectionMode.deep) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _handleCancelSession,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerCoral,
                        side: BorderSide(color: AppColors.dangerCoral),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Cancel Focus Session'),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakDurationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ActivePolicies.guardBreakOptions.map((m) {
        final isSel = _selectedBreakMinutes == m;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBreakMinutes = m;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.dangerCoral.withValues(alpha: 0.15) : AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: isSel ? AppColors.dangerCoral : Colors.transparent,
              ),
            ),
            child: Text(
              '$m min',
              style: AppTypography.bodySmall.copyWith(
                color: isSel ? AppColors.dangerCoral : AppColors.textSecondary,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getInstructionText() {
    return switch (widget.protectionMode) {
      ProtectionMode.nudge || ProtectionMode.guard =>
        'Take a 20-second pause to reflect. You can request a short timed break from this specific app once the count ends.',
      ProtectionMode.deep =>
        'This is Deep Focus. You cannot bypass this shield without terminating your entire focus session.',
    };
  }
}

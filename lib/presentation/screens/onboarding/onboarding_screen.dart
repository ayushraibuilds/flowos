import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/onboarding/models/user_profile.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../navigation/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  int _currentStep = 0;

  // Form State
  final List<String> _selectedGoals = [];
  final List<String> _selectedDistractions = [];
  bool _weekdaysOnly = true;
  int _startHour = 9;
  int _endHour = 11;
  String _protectionMode = 'gentle'; // 'gentle' | 'firm'

  final List<String> _goalsOptions = [
    'Deep work',
    'Study',
    'Rest',
    'Less scrolling',
  ];

  final List<String> _distractionsOptions = [
    'Instagram',
    'YouTube/Shorts',
    'TikTok',
    'X/Twitter',
    'Reddit',
    'Browser',
    'Games',
    'Other',
  ];

  bool _usagePermissionActive = false;
  bool _accessibilityPermissionActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    const channel = MethodChannel('flowos/usage_stats');
    try {
      final bool usage = await channel.invokeMethod<bool>('checkUsagePermission') ?? false;
      final bool access = await channel.invokeMethod<bool>('checkAccessibilityPermission') ?? false;
      if (mounted) {
        setState(() {
          _usagePermissionActive = usage;
          _accessibilityPermissionActive = access;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestUsagePermission() async {
    const channel = MethodChannel('flowos/usage_stats');
    try {
      await channel.invokeMethod('requestUsagePermission');
    } catch (_) {}
  }

  Future<void> _requestAccessibilityPermission() async {
    const channel = MethodChannel('flowos/usage_stats');
    try {
      await channel.invokeMethod('requestAccessibilityPermission');
    } catch (_) {}
  }

  bool get _isNextEnabled {
    return switch (_currentStep) {
      0 => _selectedGoals.isNotEmpty,
      1 => _selectedDistractions.length == 3,
      2 => _endHour > _startHour,
      3 => true, // protection mode is default 'gentle'
      4 => true, // setup step is always continueable
      5 => true, // seed step
      _ => true,
    };
  }

  Future<void> _saveAndProceed() async {
    final profile = UserProfile(
      goals: _selectedGoals,
      distractions: _selectedDistractions,
      protectedStartHour: _startHour,
      protectedEndHour: _endHour,
      protectedWeekdaysOnly: _weekdaysOnly,
      protectionMode: _protectionMode,
    );

    // Save profile configurations
    await ref.read(userProfileProvider.notifier).updateProfile(profile);

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      // Mark onboarding complete early so that dropping focus mid-session doesn't lock user in onboarding
      await completeOnboarding();
      if (mounted) {
        // Go to focus screen with first seed configurations
        context.go('/focus', extra: {
          'durationMinutes': 10,
          'sessionLabel': 'Plant your first seed',
          'firstSeed': true,
          'autoStart': true,
        });
      }
    }
  }

  Future<void> _useOfflineWithoutSetup() async {
    HapticFeedback.mediumImpact();
    // Save defaults
    final profile = UserProfile.defaults();
    await ref.read(userProfileProvider.notifier).updateProfile(profile);
    await completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip and Back
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                      onPressed: _goBack,
                    )
                  else
                    const SizedBox(width: 40),
                  TextButton(
                    onPressed: _useOfflineWithoutSetup,
                    child: Text(
                      'Skip to Dashboard',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: List.generate(6, (i) {
                  final isActive = i <= _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.emerald
                            : AppColors.background2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Main Contents based on step
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNextEnabled
                      ? () {
                          HapticFeedback.selectionClick();
                          _saveAndProceed();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.background2,
                    disabledForegroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Text(
                    _currentStep == 5 ? 'Plant my seed' : 'Continue',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => _buildGoalsStep(),
      1 => _buildDistractionsStep(),
      2 => _buildProtectedWindowStep(),
      3 => _buildProtectionStyleStep(),
      4 => _buildPermissionsStep(),
      5 => _buildPlantSeedStep(),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Goal Step ──────────────────────────────────────────
  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What do you want more of?', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text('Select at least one priority goal to focus on.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _goalsOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return _buildOptionChip(
              label: goal,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Distractions Step ──────────────────────────────────
  Widget _buildDistractionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your top distractions', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select exactly 3 sources of attention leaks.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Selected: ${_selectedDistractions.length}/3',
          style: AppTypography.monoSmall.copyWith(
            color: _selectedDistractions.length == 3 ? AppColors.emerald : AppColors.warningAmber,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _distractionsOptions.map((app) {
            final isSelected = _selectedDistractions.contains(app);
            return _buildOptionChip(
              label: app,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDistractions.remove(app);
                  } else {
                    if (_selectedDistractions.length < 3) {
                      _selectedDistractions.add(app);
                    } else {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select exactly 3 distraction sources.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Protected Window Step ──────────────────────────────
  Widget _buildProtectedWindowStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Protected window', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text('Define when your focus time is protected daily.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.xxl),

        // Segmented Control / Choice for days
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _weekdaysOnly = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _weekdaysOnly ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.background2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: _weekdaysOnly ? AppColors.emerald : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Weekdays',
                      style: AppTypography.body.copyWith(
                        color: _weekdaysOnly ? AppColors.emerald : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _weekdaysOnly = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: !_weekdaysOnly ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.background2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: !_weekdaysOnly ? AppColors.emerald : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Every Day',
                      style: AppTypography.body.copyWith(
                        color: !_weekdaysOnly ? AppColors.emerald : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Hours Selectors
        Text('Hours range (Start - End)', style: AppTypography.monoSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Start Hour Dropdown
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _startHour,
                    dropdownColor: AppColors.background2,
                    items: List.generate(24, (i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00', style: AppTypography.body),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _startHour = val);
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('to', style: AppTypography.body),
            ),
            // End Hour Dropdown
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _endHour,
                    dropdownColor: AppColors.background2,
                    items: List.generate(24, (i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00', style: AppTypography.body),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _endHour = val);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_endHour <= _startHour) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '⚠️ End hour must be greater than start hour.',
            style: AppTypography.caption.copyWith(color: AppColors.dangerCoral),
          ),
        ],
      ],
    );
  }

  // ─── Protection Style Step ─────────────────────────────
  Widget _buildProtectionStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Protection style', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text('Choose how FlowOS guards your attention.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.xxl),

        // Gentle Style Button Card
        _buildStyleCard(
          mode: 'gentle',
          title: 'Gentle Mode',
          description: 'A soft banner on your Home screen and calm reminders when tracking doomscrolls. No hard blocks.',
          icon: Icons.notifications_none_rounded,
        ),

        const SizedBox(height: AppSpacing.md),

        // Firm Style Button Card
        _buildStyleCard(
          mode: 'firm',
          title: 'Firm Mode',
          description: 'Forces mindfulness: opening Scroll Tracker shows a mandatory intent check-in gate. Confirmation friction is added during protected windows.',
          icon: Icons.gavel_rounded,
        ),
      ],
    );
  }

  // ─── Plant Seed Step ────────────────────────────────────
  Widget _buildPlantSeedStep() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.emerald, AppColors.recoveryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text('🌱', style: TextStyle(fontSize: 64)),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text('Plant your first seed', style: AppTypography.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(
          '10 minutes to focus, start deep work, and earn your first XP points.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Complete this first session to unlock your garden dashboard.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────
  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.emerald : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.emerald : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _protectionMode == mode;
    return InkWell(
      onTap: () => setState(() => _protectionMode = mode),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald.withValues(alpha: 0.08) : AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: isSelected ? AppColors.emerald : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.emerald : AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsStep() {
    final isAndroid = Platform.isAndroid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device Setup', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Allow FlowOS to read attention cost and manage focus blocks locally.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        
        if (isAndroid) ...[
          // Usage access permission card
          _buildPermissionCard(
            title: 'Usage Access (Required)',
            description: 'Required to read distraction app screen time and calculate your daily scores.',
            status: _usagePermissionActive,
            onTap: _requestUsagePermission,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Accessibility permission card
          _buildPermissionCard(
            title: 'Accessibility Blocker (Optional)',
            description: 'Required to automatically intercept and shield distraction apps during deep focus blocks.',
            status: _accessibilityPermissionActive,
            onTap: _requestAccessibilityPermission,
          ),
        ] else ...[
          _buildPermissionCard(
            title: 'iOS Screen Time Permissions',
            description: 'FlowOS uses Apple\'s Screen Time API to block distractions. Tapping below will verify permissions on the next screen.',
            status: false,
            onTap: () {},
          ),
        ]
      ],
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool status,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: status ? AppColors.emerald.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: status ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  status ? 'Granted' : 'Pending',
                  style: AppTypography.monoSmall.copyWith(
                    color: status ? AppColors.emerald : AppColors.warningAmber,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                side: BorderSide(
                  color: status ? AppColors.textTertiary.withValues(alpha: 0.2) : AppColors.emerald,
                ),
                foregroundColor: status ? AppColors.textPrimary : AppColors.emerald,
              ),
              child: Text(status ? 'Settings Configured' : 'Grant Permission'),
            ),
          ],
        ],
      ),
    );
  }
}

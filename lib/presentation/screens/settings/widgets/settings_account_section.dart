import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_section_card.dart';

class SettingsAccountSection extends StatelessWidget {
  final String? email;
  final bool isAuthenticated;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const SettingsAccountSection({
    super.key,
    this.email,
    required this.isAuthenticated,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Account & Profile',
      subtitle: isAuthenticated
          ? 'Signed in as $email'
          : 'Local profile active. Sign in to enable cloud sync.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isAuthenticated ? (email ?? 'User') : 'Local Mode',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          ElevatedButton(
            onPressed: isAuthenticated ? onSignOut : onSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAuthenticated
                  ? AppColors.background2
                  : AppColors.emerald,
              foregroundColor: isAuthenticated
                  ? AppColors.textSecondary
                  : Colors.white,
              elevation: 0,
            ),
            child: Text(isAuthenticated ? 'Sign Out' : 'Sign In'),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/services/auth_service.dart';

/// Auth screen — Apple (iOS) / Google (Android) + email fallback.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true; // vs sign-up
  bool _loading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _socialAuth(Future<bool> Function() authMethod) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();
    final success = await authMethod();

    if (success) {
      await completeOnboarding();
    }

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        context.go('/home');
      } else {
        setState(() => _error = 'Sign-in was cancelled or failed.');
      }
    }
  }

  Future<void> _emailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();
    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      await completeOnboarding();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('AuthException: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.emerald, const Color(0xFF26C6DA)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'FlowOS',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isLogin ? 'Welcome back' : 'Create your account',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ─── Social Auth ─────────────────────────────
              if (isIOS) ...[
                _socialButton(
                  onPressed: () {
                    final authService = ref.read(authServiceProvider);
                    _socialAuth(authService.signInWithApple);
                  },
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  color: Colors.white,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _socialButton(
                onPressed: () {
                  final authService = ref.read(authServiceProvider);
                  _socialAuth(authService.signInWithGoogle);
                },
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
                color: const Color(0xFF4285F4),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'or',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ─── Email Form ──────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.background2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.background2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.dangerCoral,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _emailAuth,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Toggle login/signup
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : 'Already have an account? ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    }),
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Sign In',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Forgot password
              if (_isLogin) ...[
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    if (_emailController.text.trim().isEmpty) {
                      setState(() => _error = 'Enter your email first');
                      return;
                    }
                    final authService = ref.read(authServiceProvider);
                    await authService.resetPassword(_emailController.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password reset email sent'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],

              // Skip (offline mode)
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () async {
                  await completeOnboarding();
                  if (context.mounted) context.go('/home');
                },
                child: Text(
                  'Use offline (no sync)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: Icon(icon, color: color, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        ),
      ),
    );
  }
}

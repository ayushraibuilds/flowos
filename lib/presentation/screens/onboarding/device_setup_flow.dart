import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import 'onboarding_connect_screen.dart';

class DeviceSetupFlow extends ConsumerWidget {
  const DeviceSetupFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: OnboardingConnectScreen(
        onComplete: () async {
          await ref.read(userProfileProvider.notifier).markDeviceSetupAcknowledged();
          if (context.mounted) {
            context.go('/home');
          }
        },
      ),
    );
  }
}

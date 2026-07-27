import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/services/auth_service.dart';
import '../services/ai_service.dart';

/// Global provider for authenticated AI service instance.
final aiServiceProvider = Provider<AiService>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authService = isLoggedIn ? ref.watch(authServiceProvider) : null;

  return AiService(
    tokenSupplier: () async {
      if (!SupabaseConfig.isConfigured || authService == null) return null;
      return await authService.getAccessToken();
    },
    refreshTokenSupplier: () async {
      if (!SupabaseConfig.isConfigured || authService == null) return null;
      await authService.refreshSession();
      return authService.session?.accessToken;
    },
  );
});

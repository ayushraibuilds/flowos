import 'package:supabase_flutter/supabase_flutter.dart';

enum AppSessionStatus { loading, localOnly, authenticated, unauthenticated }

class AppSessionState {
  final AppSessionStatus status;
  final User? user;
  final Session? session;
  final bool isOnboardingComplete;

  const AppSessionState({
    required this.status,
    this.user,
    this.session,
    required this.isOnboardingComplete,
  });

  factory AppSessionState.loading({bool isOnboardingComplete = false}) {
    return AppSessionState(
      status: AppSessionStatus.loading,
      isOnboardingComplete: isOnboardingComplete,
    );
  }

  factory AppSessionState.localOnly({required bool isOnboardingComplete}) {
    return AppSessionState(
      status: AppSessionStatus.localOnly,
      isOnboardingComplete: isOnboardingComplete,
    );
  }

  factory AppSessionState.authenticated({
    required User user,
    Session? session,
    required bool isOnboardingComplete,
  }) {
    return AppSessionState(
      status: AppSessionStatus.authenticated,
      user: user,
      session: session,
      isOnboardingComplete: isOnboardingComplete,
    );
  }

  factory AppSessionState.unauthenticated({
    required bool isOnboardingComplete,
  }) {
    return AppSessionState(
      status: AppSessionStatus.unauthenticated,
      isOnboardingComplete: isOnboardingComplete,
    );
  }

  bool get isLoading => status == AppSessionStatus.loading;
  bool get isLocalOnly => status == AppSessionStatus.localOnly;
  bool get isAuthenticated => status == AppSessionStatus.authenticated;
  bool get isUnauthenticated => status == AppSessionStatus.unauthenticated;

  AppSessionState copyWith({
    AppSessionStatus? status,
    User? user,
    Session? session,
    bool? isOnboardingComplete,
  }) {
    return AppSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSessionState &&
        other.status == status &&
        other.user?.id == user?.id &&
        other.session?.accessToken == session?.accessToken &&
        other.isOnboardingComplete == isOnboardingComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      user?.id,
      session?.accessToken,
      isOnboardingComplete,
    );
  }

  @override
  String toString() {
    return 'AppSessionState(status: $status, user: ${user?.id}, isOnboardingComplete: $isOnboardingComplete)';
  }
}

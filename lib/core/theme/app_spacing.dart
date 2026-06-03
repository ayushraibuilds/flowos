/// FlowOS Spacing System — 8px base grid.
/// All spacing is a multiple of 8. Consistent rhythm throughout the app.
abstract final class AppSpacing {
  /// 4px — Icon-to-text gap, tight inline spacing
  static const double xs = 4;

  /// 8px — Between related elements within a card
  static const double sm = 8;

  /// 12px — Between cards in a list
  static const double md = 12;

  /// 16px — Card internal padding
  static const double lg = 16;

  /// 20px — Screen edge padding
  static const double xl = 20;

  /// 24px — Between sections
  static const double xxl = 24;

  /// 32px — Major visual breaks
  static const double xxxl = 32;

  /// 72px — Bottom nav height (with safe area)
  static const double bottomNavHeight = 72;

  // ─── Border Radii ──────────────────────────────────────────────

  /// 16px — Cards
  static const double radiusCard = 16;

  /// 12px — Buttons
  static const double radiusButton = 12;

  /// 8px — Tags, badges
  static const double radiusTag = 8;

  /// 24px — Bottom sheet top corners
  static const double radiusSheet = 24;

  /// 999px — Full pill shape
  static const double radiusPill = 999;
}

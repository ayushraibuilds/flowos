/// Canonical mapping from user-facing distraction labels to Android package names.
/// Used by both the Scroll Tracker and the Settings → Shape Focus sheet.
class DistractionPackages {
  DistractionPackages._();

  /// Primary well-known packages for each distraction category.
  static const Map<String, List<String>> labelToPackages = {
    'instagram': ['com.instagram.android'],
    'youtube/shorts': ['com.google.android.youtube'],
    'youtube': ['com.google.android.youtube'],
    'tiktok': ['com.zhiliaoapp.musically'],
    'x/twitter': ['com.twitter.android'],
    'twitter': ['com.twitter.android'],
    'x': ['com.twitter.android'],
    'reddit': ['com.reddit.frontpage'],
  };

  /// Known browser packages — we check all of these when the user selects "Browser".
  static const List<String> browserPackages = [
    'com.android.chrome',
    'com.sec.android.app.sbrowser',    // Samsung Internet
    'org.mozilla.firefox',
    'com.brave.browser',
    'com.microsoft.emmx',              // Edge
    'com.opera.browser',
  ];

  /// Resolve a user-facing label to the primary package name.
  /// Returns null for 'Games' and 'Other' — these require the app picker.
  static String? primaryPackage(String label) {
    final key = label.toLowerCase();
    if (key == 'browser') return browserPackages.first;
    return labelToPackages[key]?.first;
  }

  /// Returns all known packages for a label (e.g., all browsers).
  static List<String> allPackages(String label) {
    final key = label.toLowerCase();
    if (key == 'browser') return browserPackages;
    return labelToPackages[key] ?? [];
  }

  /// The canonical list of distraction options shown in both
  /// the Shape Focus sheet and the Scroll Tracker.
  static const List<String> allOptions = [
    'Instagram',
    'YouTube/Shorts',
    'TikTok',
    'X/Twitter',
    'Reddit',
    'Browser',
    'Games',
    'Other',
  ];
}

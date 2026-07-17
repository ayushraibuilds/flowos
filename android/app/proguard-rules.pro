# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift/SQLite
-keep class org.sqlite.** { *; }

# Supabase / Kotlin serialization
-keepattributes *Annotation*
-keep class kotlinx.serialization.** { *; }

# FlowOS native services
-keep class com.flowos.flowos.FocusBlockerService { *; }
-keep class com.flowos.flowos.FocusSessionForegroundService { *; }
-keep class com.flowos.flowos.NotificationTrackerService { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite
# Keep the native SQLite library and Drift's runtime which generates row classes reflectively.
-keep class org.sqlite.** { *; }
-keep class io.github.moisesian.** { *; }
-keep class drift.** { *; }
-keep, allowobfuscation class drift.runtime.** { *; }

# Generated Dart data classes & json_serializable adapters.
# These are accessed via reflection by Drift's query/result serialization and
# the sync engine's fromJson/toJson on release builds. Stripping them causes a
# blank-screen crash on startup (first DB read / sync deserialization).
-keep class com.flowos.flowos.** { *; }
-keep class io.flutter.app.** { *; }
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault

# Supabase / Kotlin serialization
-keepattributes *Annotation*
-keep class kotlinx.serialization.** { *; }
-keepclassmembers class kotlinx.serialization.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# FlowOS native services (accessibility/notification/foreground services — must not be renamed)
-keep class com.flowos.flowos.FocusBlockerService { *; }
-keep class com.flowos.flowos.FocusSessionForegroundService { *; }
-keep class com.flowos.flowos.NotificationTrackerService { *; }

# Sentry (crash reporting — reflectively discovers native integration)
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Google/Supabase auth helpers (GMS / AppAuth / Safari-style controllers)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Ignore warnings about missing Play Core classes (used by Flutter deferred components if present)
-dontwarn com.google.android.play.core.**

# Keep Kotlin metadata so reflection-based serializers can read @Serializable
-keepattributes kotlin.Metadata


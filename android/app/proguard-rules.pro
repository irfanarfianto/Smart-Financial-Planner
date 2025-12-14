# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services & ML Kit (Essential for OCR)
-keep class com.google.android.gms.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Supabase & Networking (Prevent stripping data models if accessed reflectively)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.supabase.** { *; }
-dontwarn io.supabase.**

# General Safe Guards
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class androidx.** { *; }

# Google Play Core (Fix for Deferred Components / Split Install R8 errors)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

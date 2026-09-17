# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Cast Framework & MediaRouter
-keep class com.google.android.gms.cast.** { *; }
-keep class com.felnanuke.google_cast.** { *; }
-keep class androidx.mediarouter.** { *; }
-dontwarn com.google.android.gms.cast.**
-dontwarn com.felnanuke.google_cast.**

# Keep generic models / serialization if needed
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

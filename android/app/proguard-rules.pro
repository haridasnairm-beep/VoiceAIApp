# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep http package classes for metadata extraction
-keep class org.apache.http.** { *; }
-keep class android.net.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn android.net.http.**

# Keep HTML parser classes
-keep class org.jsoup.** { *; }
-dontwarn org.jsoup.**

# Keep Gson/JSON parsing (if used)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Hive database
-keep class hive.** { *; }
-keep class * extends hive.TypeAdapter { *; }

# Keep model classes that might be used with reflection
-keep class com.linkshare.app.** { *; }

# Don't warn about missing classes that are optional
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core (deferred components) - not used but referenced by Flutter
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

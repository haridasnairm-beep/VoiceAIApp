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

# Keep Gson/JSON parsing — required by flutter_local_notifications
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

# flutter_local_notifications — keep scheduled notification serialization
-keep class com.dexterous.** { *; }

# image_cropper — keep UCrop activity
-keep class com.yalantis.ucrop.** { *; }

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

# Sentry — keep native crash handler classes
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# media_kit
-keep class com.alexmercerind.media_kit_video.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# OkHttp (used by dio/http)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

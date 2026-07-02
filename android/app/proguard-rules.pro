# Suppress all R8 missing-class warnings.
# Flutter apps pull in many plugin transitive deps that aren't on the
# compile classpath; -dontwarn prevents R8 from failing on them.
-dontwarn **
-ignorewarnings

# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# media_kit / media_kit_video
-keep class com.alexmercerind.** { *; }
-keep class media_kit.** { *; }

# foreground service / downloads (used by flutter_downloader)
-keep class vn.hunghd.flutterdownloader.** { *; }

# wakelock_plus
-keep class com.hilal.wakelock.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep native methods across all classes
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serialization / Gson
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# OkHttp / Okio (used by dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# SQLite (sqflite local history/watchlist)
-keep class net.sqlcipher.** { *; }
-keep class io.flutter.plugins.sqflite.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

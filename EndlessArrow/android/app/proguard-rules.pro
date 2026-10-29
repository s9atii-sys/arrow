# Flutter / engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads / Play Services Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.libraries.ads.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**

# WorkManager — required with google_mobile_ads 9 + AGP 9 release
# (WorkDatabase / InitializationProvider crash)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.InputMerger {
    public <init>();
}
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}
-dontwarn androidx.work.impl.**

# AndroidX Startup
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer { *; }

# Play Billing / in_app_purchase
-keep class com.android.billingclient.** { *; }
-keep class com.google.android.gms.internal.play_billing.** { *; }
-dontwarn com.android.billingclient.**

# Keep Parcelables / enums used by plugins
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Audio / JNI helpers used by flame_audio / audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

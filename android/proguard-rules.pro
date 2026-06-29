# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# OkHttp / Dio networking
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Crashlytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# RevenueCat (purchases_flutter)
-keep class com.revenuecat.** { *; }
-dontwarn com.revenuecat.**

# TTS / Media
-keep class com.google.android.apps.tts.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keepclassmembers class kotlin.Metadata { public <methods>; }

# SQLite / sqflite
-keep class com.tekartik.sqflite.** { *; }

# Connectivity plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ML Kit (mobile_scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Share plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# UUID
-keep class com.fasterxml.uuid.** { *; }

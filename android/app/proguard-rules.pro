# Flutter generated rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Firebase - Keep necessary classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Firestore rules
-keep class com.google.firebase.firestore.** { *; }

# Stripe - Keep all SDK classes
-keep class com.stripe.android.** { *; }

# Avoid stripping annotations used by Firebase and Stripe
-keepattributes *Annotation*

# Optional: Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Prevent warnings for Firebase/Stripe
-dontwarn com.google.firebase.**
-dontwarn com.stripe.**
-dontwarn androidx.**
-dontwarn io.flutter.embedding.**

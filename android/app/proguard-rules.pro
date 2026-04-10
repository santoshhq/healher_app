# Keep Flutter embedding/plugin classes that may be referenced reflectively.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep JavaScript bridge methods used by WebView integrations.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep useful metadata for reflection/serialization.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

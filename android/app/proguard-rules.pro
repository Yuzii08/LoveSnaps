# Keep custom AppWidgetProvider classes from being obfuscated or removed in release builds
-keep class com.lovesnaps.app.LoveSnapWidgetProvider { *; }
-keep class com.lovesnaps.app.LoveMediumWidgetProvider { *; }

# Also keep all AppWidgetProviders generally
-keep public class * extends android.appwidget.AppWidgetProvider {
    *;
}

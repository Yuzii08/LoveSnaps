package com.lovesnaps.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Small LoveSnaps widget (2x1 or 4x1).
 * Displays: streak count + days together counter.
 * Tapping opens the app's home screen.
 */
class LoveSnapWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.love_snap_widget_small)

            // ── Read data from shared storage ──────────────────────────────
            val streakCount = widgetData.getInt("streak_count", 0)
            val daysCount   = widgetData.getInt("days_count", 0)
            val atRisk      = widgetData.getBoolean("streak_at_risk", false)

            // ── Bind data to views ─────────────────────────────────────────
            views.setTextViewText(R.id.widget_streak_count, "$streakCount")
            views.setTextViewText(R.id.widget_days_count, "Day $daysCount")

            // Streak icon: flame normally, warning when at risk
            val streakEmoji = if (atRisk) "⚠️" else "🔥"
            views.setTextViewText(R.id.widget_streak_icon, streakEmoji)

            // ── Tap action: open app to home screen ───────────────────────
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                uri = android.net.Uri.parse("lovesnaps://home")
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

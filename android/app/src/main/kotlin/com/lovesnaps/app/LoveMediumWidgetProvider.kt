package com.lovesnaps.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Medium LoveSnaps widget (4x2).
 * Displays: streak + days counter + distance + "Miss You" button.
 */
class LoveMediumWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.love_snap_widget_medium)

            // ── Read shared data ───────────────────────────────────────────
            val streakCount  = widgetData.getInt("streak_count", 0)
            val daysCount    = widgetData.getInt("days_count", 0)
            val distance     = widgetData.getString("distance", "—") ?: "—"
            val partnerName  = widgetData.getString("partner_name", "Partner") ?: "Partner"
            val atRisk       = widgetData.getBoolean("streak_at_risk", false)
            val missYouRx    = widgetData.getBoolean("miss_you_received", false)

            // ── Bind to views ──────────────────────────────────────────────
            views.setTextViewText(R.id.widget_streak_icon, if (atRisk) "⚠️" else "🔥")
            views.setTextViewText(R.id.widget_streak_count, "$streakCount day${if (streakCount == 1) "" else "s"}")
            views.setTextViewText(R.id.widget_days_count, "Day $daysCount")
            views.setTextViewText(R.id.widget_distance, distance)
            views.setTextViewText(
                R.id.widget_miss_you_btn,
                if (missYouRx) "💌 $partnerName misses you!" else "💕 Miss You"
            )

            // ── Tap entire widget → open app ──────────────────────────────
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                uri = android.net.Uri.parse("lovesnaps://home")
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            // ── Miss You button → background callback ─────────────────────
            // This triggers the widgetBackgroundCallback in main.dart
            val missYouIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                uri = android.net.Uri.parse("lovesnaps://missyou")
            )
            views.setOnClickPendingIntent(R.id.widget_miss_you_btn, missYouIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

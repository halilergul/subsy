package com.halilergul.subsy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Android App Widget for Subsy. A dumb renderer: it only reads the display-ready
 * strings written by the Flutter side (see widget_keys.dart) and toggles which
 * branch is visible by the `state` key. Tapping anywhere opens the app.
 *
 * NOTE: verified on a real device — this file is scaffolded but the build/render
 * is not exercised in the headless environment used to author it.
 */
class SubsyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.subsy_widget)

            val state = widgetData.getString("state", "empty") ?: "empty"
            val ready = state == "ready"
            val empty = state == "empty"
            val locked = state == "locked"

            views.setViewVisibility(R.id.ready_container, if (ready) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.empty_text, if (empty) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.locked_text, if (locked) View.VISIBLE else View.GONE)

            if (ready) {
                views.setTextViewText(R.id.next_title, widgetData.getString("next_title", ""))
                views.setTextViewText(R.id.next_when, widgetData.getString("next_when", ""))
                views.setTextViewText(R.id.next_amount, widgetData.getString("next_amount", ""))
                views.setTextViewText(R.id.total_line, widgetData.getString("total_line", ""))

                val unified = widgetData.getString("unified_line", "") ?: ""
                views.setTextViewText(R.id.unified_line, unified)
                views.setViewVisibility(
                    R.id.unified_line,
                    if (unified.isNotEmpty()) View.VISIBLE else View.GONE,
                )
            }

            // Tap anywhere opens the app (FR-010).
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

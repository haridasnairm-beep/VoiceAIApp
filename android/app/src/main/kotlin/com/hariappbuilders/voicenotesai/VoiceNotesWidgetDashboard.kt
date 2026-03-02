package com.hariappbuilders.voicenotesai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Dashboard widget (4×2).
 * Shows note count, open task count, and optionally a latest note preview.
 * Content displayed depends on App Lock + Widget Privacy settings
 * (written by HomeWidgetService via home_widget SharedPreferences).
 */
class VoiceNotesWidgetDashboard : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val noteCount = widgetData.getString("note_count", "0") ?: "0"
        val taskCount = widgetData.getString("task_count", "0") ?: "0"
        val latestNote = widgetData.getString("latest_note", "") ?: ""
        val showCounts = widgetData.getBoolean("show_counts", true)
        val showPreview = widgetData.getBoolean("show_preview", false)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_dashboard)

            // Note count (may be empty in 'minimal' privacy mode)
            views.setTextViewText(R.id.widget_note_count, if (showCounts) noteCount else "")
            views.setTextViewText(R.id.widget_task_count, if (showCounts) taskCount else "")

            // Latest note preview
            if (showPreview && latestNote.isNotEmpty()) {
                views.setTextViewText(R.id.widget_latest_note, latestNote)
                views.setViewVisibility(R.id.widget_latest_note, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_latest_note, View.GONE)
            }

            // Record button → Recording screen (bypasses App Lock in Full/Record-Only modes)
            val recordIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("voicenotesai://record"),
            )
            views.setOnClickPendingIntent(R.id.widget_record_btn, recordIntent)

            // Container tap → open app Home (App Lock will trigger if enabled)
            val homeIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(R.id.widget_dashboard_container, homeIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

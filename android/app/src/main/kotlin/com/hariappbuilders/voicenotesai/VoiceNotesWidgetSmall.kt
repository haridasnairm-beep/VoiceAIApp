package com.hariappbuilders.voicenotesai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Quick Record widget (2×1).
 * Tapping anywhere opens the Recording screen directly.
 * No note content is displayed — always safe regardless of App Lock state.
 */
class VoiceNotesWidgetSmall : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_small)

            // Tap → launch app directly into Recording screen
            val recordIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("voicenotesai://record"),
            )
            views.setOnClickPendingIntent(R.id.widget_small_container, recordIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

package com.wirdi.wirdi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WirdiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val packageName = context.packageName
        val layoutId = context.resources.getIdentifier("wirdi_widget_layout", "layout", packageName)
        
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(packageName, layoutId).apply {
                val nameId = context.resources.getIdentifier("widget_next_prayer_name", "id", packageName)
                val timeId = context.resources.getIdentifier("widget_next_prayer_time", "id", packageName)
                val hadithId = context.resources.getIdentifier("widget_hadith_arabic", "id", packageName)
                
                setTextViewText(nameId, widgetData.getString("next_prayer_name", "Next Prayer"))
                setTextViewText(timeId, widgetData.getString("next_prayer_time", "--:--"))
                setTextViewText(hadithId, widgetData.getString("hadith_arabic", "Wirdi"))
                val wirdId = context.resources.getIdentifier("widget_wird_progress", "id", packageName)
                val khatmaId = context.resources.getIdentifier("widget_khatma_percent", "id", packageName)
                setTextViewText(wirdId, widgetData.getString("wird_progress_text", "Wird: 0/5"))
                setTextViewText(khatmaId, widgetData.getString("khatma_percent_text", "Khatma: 0%"))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

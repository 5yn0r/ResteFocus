package com.example.restefocus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget écran d'accueil : affiche l'état de la session sans ouvrir l'app.
 * Un widget ne peut pas faire défiler un vrai chrono (coût batterie, et le
 * système impose updatePeriodMillis >= 30 min) — on affiche donc une heure
 * de fin fixe, rafraîchie immédiatement à chaque démarrage/arrêt de session
 * (voir SessionPrefs.startSession/stopSession) et périodiquement en secours.
 *
 * Taper le widget ouvre toujours l'app, jamais d'action directe dessus —
 * ça éviterait sinon une porte de contournement au mode strict.
 */
class FocusWidgetProvider : AppWidgetProvider() {

    companion object {
        private val timeFormat = SimpleDateFormat("HH:mm", Locale.FRANCE)

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, FocusWidgetProvider::class.java))
            if (ids.isNotEmpty()) onUpdateWidgets(context, manager, ids)
        }

        private fun onUpdateWidgets(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val views = RemoteViews(context.packageName, R.layout.widget_focus)
            val active = SessionPrefs.isSessionActive(context)

            views.setViewVisibility(R.id.widgetActiveGroup, if (active) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widgetIdleGroup, if (active) View.GONE else View.VISIBLE)

            if (active) {
                val endAt = Date(SessionPrefs.sessionEndAtMillis(context))
                views.setTextViewText(R.id.widgetEndTime, "Fin à ${timeFormat.format(endAt)}")
                val count = SessionPrefs.blockedPackages(context).size
                views.setTextViewText(
                    R.id.widgetBlockedCount,
                    "$count app${if (count > 1) "s" else ""} bloquée${if (count > 1) "s" else ""}",
                )
            } else {
                val streak = SessionPrefs.streakDays(context)
                if (streak > 0) {
                    views.setViewVisibility(R.id.widgetStreak, View.VISIBLE)
                    views.setTextViewText(R.id.widgetStreak, "🔥 $streak jour${if (streak > 1) "s" else ""}")
                } else {
                    views.setViewVisibility(R.id.widgetStreak, View.GONE)
                }
            }

            val openApp = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                openApp,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)

            for (id in ids) manager.updateAppWidget(id, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        onUpdateWidgets(context, appWidgetManager, appWidgetIds)
    }
}

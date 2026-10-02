package com.example.restefocus

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Détecte les changements de fenêtre au premier plan (cahier des charges §8.2,
 * étape ②). Si l'app qui passe au premier plan est dans la blocklist et
 * qu'une session est active, lance MathGateActivity par-dessus.
 */
class FocusAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return

        if (packageName == applicationContext.packageName) return
        if (!SessionPrefs.isSessionActive(applicationContext)) return
        if (!SessionPrefs.blockedPackages(applicationContext).contains(packageName)) return
        if (SessionPrefs.hasActiveGrant(applicationContext, packageName)) return

        val intent = Intent(applicationContext, MathGateActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(MathGateActivity.EXTRA_PACKAGE_NAME, packageName)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {}
}

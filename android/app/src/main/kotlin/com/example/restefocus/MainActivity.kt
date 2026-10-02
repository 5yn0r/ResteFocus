package com.example.restefocus

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.restefocus/blocker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityServiceEnabled" ->
                        result.success(isAccessibilityServiceEnabled())

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    "hasOverlayPermission" ->
                        result.success(Settings.canDrawOverlays(this))

                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                        result.success(null)
                    }

                    "startSession" -> {
                        val blockedPackages =
                            (call.argument<List<String>>("blockedPackages")) ?: emptyList()
                        val endAtMillis = call.argument<Number>("endAtMillis")?.toLong() ?: 0L
                        val difficultyIndex = call.argument<Int>("difficultyIndex") ?: 0
                        val subjects = call.argument<List<String>>("subjects") ?: emptyList()
                        SessionPrefs.startSession(
                            applicationContext,
                            blockedPackages,
                            endAtMillis,
                            difficultyIndex,
                            subjects,
                        )
                        result.success(null)
                    }

                    "stopSession" -> {
                        SessionPrefs.stopSession(applicationContext)
                        result.success(null)
                    }

                    "getSessionStats" -> {
                        val (solved, failed) = SessionPrefs.stats(applicationContext)
                        result.success(mapOf("solved" to solved, "failed" to failed))
                    }

                    "pullMissedProblems" ->
                        result.success(SessionPrefs.pullMissedProblems(applicationContext).toString())

                    "setWidgetStreak" -> {
                        val days = call.argument<Int>("days") ?: 0
                        SessionPrefs.setStreakDays(applicationContext, days)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = "$packageName/${FocusAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabledServices.split(":").any { it.equals(expectedComponent, ignoreCase = true) }
    }
}

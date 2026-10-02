package com.example.restefocus

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Source de vérité unique pour l'état de blocage, partagée entre
 * FocusAccessibilityService, MathGateActivity et le MethodChannel de
 * MainActivity. Volontairement indépendante du plugin shared_preferences
 * Flutter pour ne pas dépendre de son format de stockage interne.
 *
 * La session porte sa propre heure de fin : le blocage s'arrête tout seul
 * même si le processus Flutter a été tué entre-temps.
 */
object SessionPrefs {
    private const val FILE = "restefocus_session"
    private const val KEY_ACTIVE = "active"
    private const val KEY_END_AT = "end_at"
    private const val KEY_BLOCKED_PACKAGES = "blocked_packages"
    private const val KEY_DIFFICULTY = "difficulty_index"
    private const val KEY_SUBJECTS = "subjects"
    private const val KEY_SOLVED = "solved"
    private const val KEY_FAILED = "failed"
    private const val KEY_CONSECUTIVE_FAILS = "consecutive_fails"
    private const val KEY_COOLDOWN_UNTIL = "cooldown_until"
    private const val KEY_MISSED_PROBLEMS = "missed_problems"
    private const val KEY_STREAK_DAYS = "streak_days"
    private const val GRANT_PREFIX = "grant_"

    /** Nombre max de problèmes ratés gardés en attente d'un pull Flutter. */
    private const val MAX_MISSED_PROBLEMS = 50

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun startSession(
        context: Context,
        blockedPackages: List<String>,
        endAtMillis: Long,
        difficultyIndex: Int,
        subjects: List<String>,
    ) {
        // Une nouvelle session repart sur une ardoise propre : un accès
        // accordé lors d'une session précédente (même terminée depuis) ne
        // doit jamais dispenser l'utilisateur du Math Gate sur une nouvelle
        // session — sinon l'app reste "débloquée" indéfiniment de facto.
        val editor = prefs(context).edit()
        clearGrants(context, editor)
        editor
            .putBoolean(KEY_ACTIVE, true)
            .putLong(KEY_END_AT, endAtMillis)
            .putStringSet(KEY_BLOCKED_PACKAGES, blockedPackages.toSet())
            .putInt(KEY_DIFFICULTY, difficultyIndex)
            .putStringSet(KEY_SUBJECTS, subjects.toSet())
            .putInt(KEY_SOLVED, 0)
            .putInt(KEY_FAILED, 0)
            .putInt(KEY_CONSECUTIVE_FAILS, 0)
            .putLong(KEY_COOLDOWN_UNTIL, 0L)
            .apply()
        FocusWidgetProvider.refreshAll(context)
    }

    fun stopSession(context: Context) {
        val editor = prefs(context).edit()
        clearGrants(context, editor)
        editor
            .putBoolean(KEY_ACTIVE, false)
            .putInt(KEY_CONSECUTIVE_FAILS, 0)
            .putLong(KEY_COOLDOWN_UNTIL, 0L)
            .apply()
        FocusWidgetProvider.refreshAll(context)
    }

    private fun clearGrants(context: Context, editor: SharedPreferences.Editor) {
        prefs(context).all.keys
            .filter { it.startsWith(GRANT_PREFIX) }
            .forEach { editor.remove(it) }
    }

    /** Vrai tant que la session n'a été ni arrêtée ni dépassée. */
    fun isSessionActive(context: Context): Boolean {
        val p = prefs(context)
        return p.getBoolean(KEY_ACTIVE, false) &&
            System.currentTimeMillis() < p.getLong(KEY_END_AT, 0L)
    }

    /** Heure de fin de session en cours (millis epoch), pour le widget. */
    fun sessionEndAtMillis(context: Context): Long = prefs(context).getLong(KEY_END_AT, 0L)

    fun streakDays(context: Context): Int = prefs(context).getInt(KEY_STREAK_DAYS, 0)

    /** Poussé depuis Flutter (seul endroit qui calcule le streak). */
    fun setStreakDays(context: Context, days: Int) {
        prefs(context).edit().putInt(KEY_STREAK_DAYS, days).apply()
        FocusWidgetProvider.refreshAll(context)
    }

    fun blockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()

    fun difficultyIndex(context: Context): Int =
        prefs(context).getInt(KEY_DIFFICULTY, 0)

    fun subjects(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_SUBJECTS, null)?.takeIf { it.isNotEmpty() }
            ?: setOf("maths")

    fun grantAccess(context: Context, packageName: String, minutes: Int) {
        val until = System.currentTimeMillis() + minutes * 60_000L
        prefs(context).edit().putLong(GRANT_PREFIX + packageName, until).apply()
    }

    fun hasActiveGrant(context: Context, packageName: String): Boolean {
        val until = prefs(context).getLong(GRANT_PREFIX + packageName, 0L)
        return until > System.currentTimeMillis()
    }

    fun recordSolved(context: Context) {
        val p = prefs(context)
        p.edit()
            .putInt(KEY_SOLVED, p.getInt(KEY_SOLVED, 0) + 1)
            .putInt(KEY_CONSECUTIVE_FAILS, 0)
            .apply()
    }

    /**
     * Enregistre un échec. Les échecs consécutifs et la pause sont persistés :
     * quitter puis rouvrir le Math Gate ne remet pas le compteur à zéro.
     *
     * @return le nombre d'échecs consécutifs après celui-ci.
     */
    fun recordFailed(context: Context, maxFails: Int, cooldownMs: Long): Int {
        val p = prefs(context)
        val fails = p.getInt(KEY_CONSECUTIVE_FAILS, 0) + 1
        val editor = p.edit().putInt(KEY_FAILED, p.getInt(KEY_FAILED, 0) + 1)
        if (fails >= maxFails) {
            editor
                .putInt(KEY_CONSECUTIVE_FAILS, 0)
                .putLong(KEY_COOLDOWN_UNTIL, System.currentTimeMillis() + cooldownMs)
        } else {
            editor.putInt(KEY_CONSECUTIVE_FAILS, fails)
        }
        editor.apply()
        return fails
    }

    /** Millisecondes restantes de pause après trop d'échecs (0 si aucune). */
    fun cooldownRemainingMs(context: Context): Long {
        val until = prefs(context).getLong(KEY_COOLDOWN_UNTIL, 0L)
        return (until - System.currentTimeMillis()).coerceAtLeast(0L)
    }

    fun stats(context: Context): Pair<Int, Int> {
        val p = prefs(context)
        return Pair(p.getInt(KEY_SOLVED, 0), p.getInt(KEY_FAILED, 0))
    }

    /**
     * Garde un problème raté pour le carnet d'erreurs Flutter (écran de
     * révision). File plafonnée : les plus anciens tombent en premier.
     */
    fun recordMissedProblem(
        context: Context,
        question: String,
        answer: Int,
        subject: String,
        difficultyIndex: Int,
    ) {
        val p = prefs(context)
        val existing = JSONArray(p.getString(KEY_MISSED_PROBLEMS, "[]"))
        val entry = JSONObject()
            .put("question", question)
            .put("answer", answer)
            .put("subject", subject)
            .put("difficultyIndex", difficultyIndex)
            .put("failedAt", System.currentTimeMillis())
        val updated = JSONArray()
        val start = (existing.length() - MAX_MISSED_PROBLEMS + 1).coerceAtLeast(0)
        for (i in start until existing.length()) updated.put(existing.get(i))
        updated.put(entry)
        p.edit().putString(KEY_MISSED_PROBLEMS, updated.toString()).apply()
    }

    /** Retourne la file des problèmes ratés puis la vide (consommation atomique). */
    fun pullMissedProblems(context: Context): JSONArray {
        val p = prefs(context)
        val existing = JSONArray(p.getString(KEY_MISSED_PROBLEMS, "[]"))
        p.edit().remove(KEY_MISSED_PROBLEMS).apply()
        return existing
    }
}

package com.example.restefocus

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.window.OnBackInvokedDispatcher

/**
 * Overlay de blocage — le Math Gate (cahier des charges §9). Activité native
 * pure (pas de FlutterActivity) pour s'afficher instantanément dès que
 * FocusAccessibilityService détecte une app bloquée, sans dépendre d'un
 * second moteur Flutter.
 */
class MathGateActivity : Activity() {

    companion object {
        const val EXTRA_PACKAGE_NAME = "package_name"
        private const val GRANT_MINUTES = 10
        private const val MAX_FAILS = 3
        private const val COOLDOWN_MS = 120_000L
    }

    private lateinit var blockedPackage: String
    private var cooldownTimer: CountDownTimer? = null

    private lateinit var questionText: TextView
    private lateinit var subjectText: TextView
    private lateinit var answerInput: EditText
    private lateinit var submitButton: Button
    private lateinit var statusText: TextView
    private lateinit var appNameText: TextView
    private lateinit var subtitleText: TextView
    private lateinit var quoteText: TextView

    private var currentAnswer: Int = 0
    private var currentSubject: String = "maths"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_math_gate)

        questionText = findViewById(R.id.questionText)
        subjectText = findViewById(R.id.subjectText)
        answerInput = findViewById(R.id.answerInput)
        submitButton = findViewById(R.id.submitButton)
        statusText = findViewById(R.id.statusText)
        appNameText = findViewById(R.id.appNameText)
        subtitleText = findViewById(R.id.subtitleText)
        quoteText = findViewById(R.id.quoteText)

        submitButton.setOnClickListener { onSubmit() }
        answerInput.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                onSubmit()
                true
            } else {
                false
            }
        }
        findViewById<Button>(R.id.leaveButton).setOnClickListener { goHome() }

        // Empêche de contourner le Math Gate avec le bouton retour : on
        // renvoie simplement l'utilisateur à l'accueil (§10). Depuis Android
        // 16, onBackPressed n'est plus appelé pour les apps qui le ciblent.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            ) { goHome() }
        }

        if (!bindTo(intent)) return
        nextProblem()
    }

    /**
     * L'activité est en singleTask : si une autre app bloquée est ouverte
     * pendant que le Math Gate est affiché, on reçoit l'intent ici et il faut
     * basculer sur cette nouvelle app (sinon on débloquerait la mauvaise).
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (!bindTo(intent)) return
        nextProblem()
    }

    override fun onResume() {
        super.onResume()
        // La session a pu se terminer pendant que l'overlay était en arrière-plan.
        if (!SessionPrefs.isSessionActive(applicationContext)) {
            finish()
            return
        }
        resumeCooldownIfAny()
    }

    @Deprecated("Remplacé par OnBackInvokedDispatcher à partir d'Android 13")
    override fun onBackPressed() {
        goHome()
    }

    private fun bindTo(intent: Intent): Boolean {
        val pkg = intent.getStringExtra(EXTRA_PACKAGE_NAME)
        if (pkg == null) {
            finish()
            return false
        }
        blockedPackage = pkg
        appNameText.text = getString(R.string.math_gate_title, appLabel(pkg))
        subtitleText.text = getString(R.string.math_gate_subtitle, GRANT_MINUTES)
        return true
    }

    private fun appLabel(packageName: String): String {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun nextProblem() {
        val difficulty = SessionPrefs.difficultyIndex(applicationContext)
        val subject = SessionPrefs.subjects(applicationContext).random()
        val problem = NativeProblemGenerator.generate(difficulty, subject)
        currentAnswer = problem.answer
        currentSubject = subject
        subjectText.text = subjectLabel(subject)
        questionText.text = problem.question
        answerInput.text.clear()
        statusText.text = ""
        quoteText.text = MotivationalQuotes.random()
    }

    private fun subjectLabel(subject: String): String = when (subject) {
        "physique" -> "⚛️ Physique"
        "algo" -> "💻 Algorithmique"
        "electronique" -> "📡 Électronique"
        "stats" -> "📊 Stats & Proba"
        "reseaux" -> "🔌 Réseaux"
        "culture" -> "🌍 Culture Afrique"
        else -> "📐 Maths"
    }

    private fun onSubmit() {
        if (SessionPrefs.cooldownRemainingMs(applicationContext) > 0) return

        val value = answerInput.text.toString().trim().toIntOrNull()
        if (value == null) {
            statusText.text = getString(R.string.math_gate_invalid)
            return
        }

        if (value == currentAnswer) {
            SessionPrefs.recordSolved(applicationContext)
            SessionPrefs.grantAccess(applicationContext, blockedPackage, GRANT_MINUTES)
            reopenBlockedApp()
            finish()
            return
        }

        SessionPrefs.recordMissedProblem(
            applicationContext,
            questionText.text.toString(),
            currentAnswer,
            currentSubject,
            SessionPrefs.difficultyIndex(applicationContext),
        )
        val fails = SessionPrefs.recordFailed(applicationContext, MAX_FAILS, COOLDOWN_MS)
        if (fails >= MAX_FAILS) {
            resumeCooldownIfAny()
        } else {
            nextProblem()
            statusText.text = getString(R.string.math_gate_wrong, MAX_FAILS - fails)
        }
    }

    private fun resumeCooldownIfAny() {
        val remaining = SessionPrefs.cooldownRemainingMs(applicationContext)
        if (remaining <= 0) return

        cooldownTimer?.cancel()
        setInputEnabled(false)
        quoteText.text = MotivationalQuotes.random()
        cooldownTimer = object : CountDownTimer(remaining, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000).toInt()
                statusText.text = getString(
                    R.string.math_gate_cooldown,
                    seconds / 60,
                    seconds % 60,
                )
            }

            override fun onFinish() {
                setInputEnabled(true)
                nextProblem()
            }
        }.start()
    }

    private fun setInputEnabled(enabled: Boolean) {
        submitButton.isEnabled = enabled
        answerInput.isEnabled = enabled
    }

    private fun reopenBlockedApp() {
        packageManager.getLaunchIntentForPackage(blockedPackage)?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(it)
        }
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onDestroy() {
        cooldownTimer?.cancel()
        super.onDestroy()
    }
}

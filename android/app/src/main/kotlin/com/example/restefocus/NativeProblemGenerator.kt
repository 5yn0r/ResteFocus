package com.example.restefocus

import kotlin.math.roundToInt
import kotlin.random.Random

/**
 * Génération de problèmes purement native (Kotlin), utilisée par
 * MathGateActivity pendant le blocage d'une app tierce. Volontairement plus
 * simple que le générateur Dart (lib/services/math_problem_generator.dart) :
 * l'overlay doit s'afficher instantanément sans dépendre d'un moteur Flutter
 * additionnel. Les problèmes riches (LaTeX, QCM, banque Firestore) restent
 * l'expérience "Tester le Math Gate" dans l'app elle-même.
 *
 * Chaque palier demande un vrai effort de calcul (équation, triplet
 * pythagoricien, système à 2 inconnues...) plutôt qu'une simple addition —
 * un blocage qui se lève en 2 secondes de calcul mental n'a aucune valeur
 * de friction cognitive (cahier des charges §10). La matière change à
 * chaque problème parmi celles choisies à l'onboarding (§9.2). Chaque
 * cellule matière×difficulté pioche parmi plusieurs templates pour éviter
 * de revoir toujours la même forme de problème. Toutes les réponses sont
 * des entiers exacts (le clavier natif n'accepte que numberSigned).
 */
data class NativeProblem(val question: String, val answer: Int)

object NativeProblemGenerator {

    private val pythagoreanTriples = listOf(
        Triple(3, 4, 5),
        Triple(5, 12, 13),
        Triple(6, 8, 10),
        Triple(8, 15, 17),
        Triple(7, 24, 25),
        Triple(9, 12, 15),
        Triple(12, 16, 20),
        Triple(10, 24, 26),
    )

    private val parallelResistorPairs = listOf(
        Triple(2, 2, 1),
        Triple(4, 4, 2),
        Triple(3, 6, 2),
        Triple(4, 12, 3),
        Triple(6, 6, 3),
        Triple(8, 8, 4),
        Triple(5, 20, 4),
        Triple(6, 12, 4),
        Triple(9, 18, 6),
    )

    private val networkPrefixes = listOf(24, 25, 26, 27, 28)

    private val portServices = listOf(
        "HTTPS" to 443,
        "HTTP" to 80,
        "SSH" to 22,
        "FTP" to 21,
        "DNS" to 53,
        "SMTP" to 25,
    )

    fun generate(difficultyIndex: Int, subject: String): NativeProblem {
        return when (subject) {
            "maths" -> pick(mathsPool(difficultyIndex))
            "physique" -> pick(physiquePool(difficultyIndex))
            "stats" -> pick(statsPool(difficultyIndex))
            "electronique" -> pick(electroniquePool(difficultyIndex))
            "algo" -> pick(algoPool(difficultyIndex))
            "reseaux" -> pick(reseauxPool(difficultyIndex))
            "culture" -> pick(culturePool(difficultyIndex))
            else -> pick(mathsPool(difficultyIndex))
        }
    }

    private fun pick(pool: List<() -> NativeProblem>): NativeProblem = pool.random()()

    // ---- Maths : équation, hypoténuse, système à 2 inconnues ----

    private fun mathsPool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                // a·x + b = c (x entier garanti)
                val a = Random.nextInt(3, 9)
                val x = Random.nextInt(4, 20)
                val b = Random.nextInt(5, 40)
                NativeProblem("$a·x + $b = ${a * x + b}\nx = ?", x)
            },
            {
                // a·x + b = c·x + d (x des deux côtés)
                val a = Random.nextInt(3, 9)
                var c = Random.nextInt(2, 6)
                if (c == a) c += 1
                val x = Random.nextInt(4, 20)
                val b = Random.nextInt(5, 40)
                val d = (a - c) * x + b
                NativeProblem("$a·x + $b = $c·x + $d\nx = ?", x)
            },
        )
        1 -> listOf(
            {
                val (p, q, r) = pythagoreanTriples.random()
                val k = Random.nextInt(1, 4)
                NativeProblem(
                    "Triangle rectangle, côtés ${p * k} et ${q * k}.\nHypoténuse = ?",
                    r * k,
                )
            },
            {
                // x² + bx + c = 0, factorisée en (x-p)(x-q), demande la plus grande racine
                val p = nonZero(-9, 9)
                var q = nonZero(-9, 9)
                if (q == p) q += if (q > 0) 1 else -1
                val b = -(p + q)
                val c = p * q
                val larger = maxOf(p, q)
                val bStr = if (b < 0) "− ${-b}" else "+ $b"
                val cStr = if (c < 0) "− ${-c}" else "+ $c"
                NativeProblem(
                    "x² $bStr·x $cStr = 0\nPlus grande racine = ?",
                    larger,
                )
            },
        )
        else -> listOf(
            { systemOfEquations() },
            {
                // suite géométrique : somme des n premiers termes
                val a = Random.nextInt(1, 6)
                val r = Random.nextInt(2, 4)
                val n = Random.nextInt(3, 6)
                var sum = 0
                var term = a
                repeat(n) {
                    sum += term
                    term *= r
                }
                NativeProblem(
                    "Suite géométrique : premier terme $a, raison $r.\n" +
                        "Somme des $n premiers termes = ?",
                    sum,
                )
            },
        )
    }

    /**
     * a·x + b·y = e
     * c·x + d·y = f
     */
    private fun systemOfEquations(): NativeProblem {
        val a = Random.nextInt(1, 6)
        val b = Random.nextInt(1, 6)
        val c = Random.nextInt(1, 6)
        val d = Random.nextInt(1, 6)
        if (a * d - b * c == 0) return systemOfEquations()

        val x0 = Random.nextInt(-8, 9).let { if (it == 0) 1 else it }
        val y0 = Random.nextInt(-8, 9).let { if (it == 0) 1 else it }
        val e = a * x0 + b * y0
        val f = c * x0 + d * y0

        return NativeProblem("$a·x + $b·y = $e\n$c·x + $d·y = $f\nx = ?", x0)
    }

    private fun nonZero(min: Int, max: Int): Int {
        val value = Random.nextInt(min, max + 1)
        return if (value == 0) 1 else value
    }

    // ---- Physique : vitesse, énergie, chute libre, portée, rendement ----

    private fun physiquePool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                val t = Random.nextInt(2, 10)
                val v = Random.nextInt(2, 15)
                NativeProblem(
                    "Un mobile parcourt ${t * v}m en ${t}s à vitesse constante.\nVitesse (m/s) = ?",
                    v,
                )
            },
            {
                val v = Random.nextInt(20, 121)
                val t2 = Random.nextInt(1, 7)
                NativeProblem(
                    "Un mobile roule à $v km/h.\nDistance parcourue (km) en ${t2}h à cette vitesse = ?",
                    v * t2,
                )
            },
        )
        1 -> listOf(
            {
                val k = Random.nextInt(1, 10)
                val v = Random.nextInt(2, 8)
                NativeProblem(
                    "Masse de ${2 * k}kg à ${v}m/s.\nÉnergie cinétique (J) ? (Ec = ½mv²)",
                    k * v * v,
                )
            },
            {
                val m = Random.nextInt(2, 21)
                val h = Random.nextInt(2, 16)
                NativeProblem(
                    "Masse de ${m}kg soulevée à ${h}m (g = 10 m/s²).\nÉnergie potentielle (J) ? (Ep = m·g·h)",
                    m * 10 * h,
                )
            },
        )
        else -> listOf(
            {
                val t = Random.nextInt(2, 6)
                NativeProblem(
                    "Chute libre sans vitesse initiale (g = 10 m/s²).\n" +
                        "Distance parcourue après ${t}s (m) ? (d = ½gt²)",
                    5 * t * t,
                )
            },
            {
                val v0 = listOf(10, 20, 30, 40, 50).random()
                NativeProblem(
                    "Projectile lancé à $v0 m/s à 45° (g = 10 m/s²).\nPortée maximale (m) ? (R = v₀²⁄g)",
                    v0 * v0 / 10,
                )
            },
            {
                val efficiencyPct = listOf(60, 65, 70, 75, 80, 85, 90).random()
                val pIn = listOf(100, 200, 400, 500, 800, 1000).random()
                val pOut = pIn * efficiencyPct / 100
                NativeProblem(
                    "Un moteur consomme ${pIn}W et restitue ${pOut}W en sortie utile.\nRendement (%) = ?",
                    efficiencyPct,
                )
            },
        )
    }

    // ---- Stats : moyenne, étendue, combinaisons, arrangements, z-score, médiane ----

    private fun statsPool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                // On tire n-1 valeurs, puis une moyenne entière telle que la
                // dernière valeur reste dans [1, 99] (jamais négative).
                val n = Random.nextInt(4, 7)
                val values = MutableList(n - 1) { Random.nextInt(1, 80) }
                val sum = values.sum()
                val minMean = (sum + 1 + n - 1) / n
                val maxMean = (sum + 99) / n
                val mean = Random.nextInt(minMean, maxMean + 1)
                values.add(mean * n - sum)
                values.shuffle()
                NativeProblem("Moyenne de : ${values.joinToString(", ")} ?", mean)
            },
            {
                val values = List(6) { Random.nextInt(1, 100) }
                NativeProblem(
                    "Étendue (max − min) de : ${values.joinToString(", ")} ?",
                    values.max() - values.min(),
                )
            },
        )
        1 -> listOf(
            {
                val n = Random.nextInt(7, 12)
                val k = Random.nextInt(2, n - 1)
                var comb = 1.0
                for (i in 0 until k) comb = comb * (n - i) / (i + 1)
                NativeProblem("Combien de façons de choisir $k éléments parmi $n ? (C($n,$k))", comb.roundToInt())
            },
            {
                val n = Random.nextInt(5, 10)
                val k = Random.nextInt(2, n - 1)
                var perm = 1
                for (i in 0 until k) perm *= (n - i)
                NativeProblem("Combien d'arrangements ordonnés de $k éléments parmi $n ? (A($n,$k))", perm)
            },
        )
        else -> listOf(
            {
                val mu = Random.nextInt(50, 150)
                val sigma = Random.nextInt(4, 20)
                val m = Random.nextInt(2, 4) * (if (Random.nextBoolean()) 1 else -1)
                val x = mu + m * sigma
                NativeProblem("N(μ=$mu, σ=$sigma). Quel est le z-score de x=$x ?", m)
            },
            {
                val values = List(5) { Random.nextInt(1, 100) }
                NativeProblem(
                    "Quelle est la médiane de : ${values.joinToString(", ")} ?",
                    values.sorted()[2],
                )
            },
        )
    }

    // ---- Électronique : loi d'Ohm, puissance, série, charge, parallèle ----

    private fun electroniquePool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                val r = Random.nextInt(15, 250)
                val i = Random.nextInt(1, 9)
                NativeProblem("Loi d'Ohm : R = $r Ω, I = $i A.\nTension U (V) = ?", r * i)
            },
            {
                val u = Random.nextInt(5, 25)
                val i = Random.nextInt(1, 11)
                NativeProblem("Tension U = $u V, courant I = $i A.\nPuissance P (W) = ? (P = U × I)", u * i)
            },
        )
        1 -> listOf(
            {
                val r1 = Random.nextInt(10, 80)
                val r2 = Random.nextInt(10, 80)
                val r3 = Random.nextInt(10, 80)
                NativeProblem(
                    "Résistances ${r1}Ω, ${r2}Ω, ${r3}Ω en série.\nRésistance équivalente (Ω) = ?",
                    r1 + r2 + r3,
                )
            },
            {
                val i = Random.nextInt(1, 10)
                val t = Random.nextInt(2, 60)
                NativeProblem(
                    "Un courant de ${i}A traverse un circuit pendant ${t}s.\nCharge transportée (Coulombs) ? (Q = I × t)",
                    i * t,
                )
            },
        )
        else -> listOf(
            {
                val (p, q, req) = parallelResistorPairs.random()
                val k = Random.nextInt(1, 5)
                NativeProblem(
                    "Résistances ${p * k}Ω et ${q * k}Ω en parallèle.\nRésistance équivalente (Ω) = ?",
                    req * k,
                )
            },
            {
                val (p, q, req) = parallelResistorPairs.random()
                val k = Random.nextInt(1, 5)
                val r3 = Random.nextInt(5, 40)
                NativeProblem(
                    "R1=${p * k}Ω et R2=${q * k}Ω en parallèle, l'ensemble en série avec R3=${r3}Ω.\n" +
                        "Résistance totale (Ω) = ?",
                    req * k + r3,
                )
            },
        )
    }

    // ---- Algorithmique : boucles, récursivité, suites ----

    private fun algoPool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                val a = Random.nextInt(3, 7)
                val b = Random.nextInt(2, 6)
                NativeProblem(
                    "for i in range($a):\n  for j in range($b):\n    print(i, j)\n" +
                        "Combien de fois \"print\" est exécuté ?",
                    a * b,
                )
            },
            {
                val step = Random.nextInt(2, 6)
                val threshold = Random.nextInt(10, 30)
                var i = 0
                while (i < threshold) i += step
                NativeProblem(
                    "i = 0\nwhile i < $threshold:\n  i += $step\nprint(i)\nQuelle est la valeur affichée ?",
                    i,
                )
            },
        )
        1 -> listOf(
            {
                val n = Random.nextInt(4, 8)
                var fact = 1
                for (i in 2..n) fact *= i
                NativeProblem("f(n) = n × f(n-1), f(0) = 1.\nQuelle est la valeur de f($n) ?", fact)
            },
            {
                val limit = Random.nextInt(15, 41)
                val divisor = Random.nextInt(2, 5)
                val count = (1..limit).count { it % divisor == 0 }
                NativeProblem("Combien de multiples de $divisor entre 1 et $limit (inclus) ?", count)
            },
        )
        else -> listOf(
            {
                val n = Random.nextInt(3, 6)
                var u = 1
                repeat(n) { u = 2 * u + 1 }
                NativeProblem("u(0) = 1, u(n) = 2×u(n-1) + 1.\nQuelle est la valeur de u($n) ?", u)
            },
            {
                val n = Random.nextInt(7, 11)
                var a = 0
                var b = 1
                repeat(n) {
                    val next = a + b
                    a = b
                    b = next
                }
                NativeProblem(
                    "f(0)=0, f(1)=1, f(n)=f(n-1)+f(n-2).\nQuelle est la valeur de f($n) ?",
                    a,
                )
            },
        )
    }

    // ---- Réseaux : sous-réseaux, broadcast, ports ----

    private fun reseauxPool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                val prefix = networkPrefixes.random()
                NativeProblem(
                    "Combien d'adresses hôtes utilisables dans un réseau /$prefix ?",
                    (1 shl (32 - prefix)) - 2,
                )
            },
            {
                val prefix = listOf(20, 22).random()
                NativeProblem(
                    "Combien de sous-réseaux /24 peut-on créer à partir d'un bloc /$prefix ?",
                    1 shl (24 - prefix),
                )
            },
        )
        1 -> listOf(
            {
                val prefix = listOf(25, 26, 27, 28).random()
                NativeProblem(
                    "Réseau /$prefix commençant à x.x.x.0.\nDernier octet de l'adresse de broadcast ?",
                    (1 shl (32 - prefix)) - 1,
                )
            },
            {
                val divisions = listOf(2, 4, 8).random()
                val bitsAdded = when (divisions) {
                    2 -> 1
                    4 -> 2
                    else -> 3
                }
                NativeProblem(
                    "Un réseau /24 est divisé en $divisions sous-réseaux égaux.\nNouveau préfixe (/?) = ?",
                    24 + bitsAdded,
                )
            },
        )
        else -> listOf(
            {
                val (service, port) = portServices.random()
                NativeProblem("Quel port TCP standard utilise $service ?", port)
            },
            {
                val basePrefix = listOf(20, 21, 22, 23).random()
                val subPrefix = basePrefix + Random.nextInt(2, 5)
                NativeProblem(
                    "Combien de sous-réseaux /$subPrefix peut-on créer à partir d'un réseau /$basePrefix ?",
                    1 shl (subPrefix - basePrefix),
                )
            },
        )
    }

    // ---- Culture & Tech Afrique : calculs mis en situation (coût, énergie,
    // réseau, PND...). Jamais de dates/chiffres historiques inventés — la
    // friction cognitive vient du calcul, pas d'un pari sur un fait précis. ----

    private fun culturePool(difficultyIndex: Int): List<() -> NativeProblem> = when (difficultyIndex) {
        0 -> listOf(
            {
                val pricePerGo = listOf(250, 500).random()
                val n = Random.nextInt(3, 12)
                NativeProblem(
                    "Un forfait internet coûte $pricePerGo FCFA le Go.\n" +
                        "Combien de Go peux-tu acheter avec ${pricePerGo * n} FCFA ?",
                    n,
                )
            },
            {
                val amount = Random.nextInt(5, 51) * 1000
                NativeProblem(
                    "Un transfert Mobile Money coûte 1% du montant envoyé.\n" +
                        "Quel est le frais (FCFA) pour un envoi de $amount FCFA ?",
                    amount / 100,
                )
            },
        )
        1 -> listOf(
            {
                val power = Random.nextInt(50, 401)
                val hours = Random.nextInt(3, 9)
                NativeProblem(
                    "Un panneau solaire de ${power}W fonctionne ${hours}h/jour.\n" +
                        "Combien de Wh produit-il en une semaine (7 jours) ?",
                    power * hours * 7,
                )
            },
            {
                val g4 = Random.nextInt(50, 71)
                val g5 = Random.nextInt(10, 21)
                val both = Random.nextInt(5, g5 + 1)
                NativeProblem(
                    "La 4G couvre $g4% du territoire, la 5G $g5%, et $both% ont les deux.\n" +
                        "Pourcentage du territoire avec au moins l'un des deux réseaux ?",
                    g4 + g5 - both,
                )
            },
        )
        else -> listOf(
            {
                val rate = Random.nextInt(5, 13)
                val yearsNeeded = Random.nextInt(3, 8)
                val current = 100 - rate * yearsNeeded
                NativeProblem(
                    "Le plan national vise 100% de couverture fibre optique.\n" +
                        "Couverture actuelle : $current%. Progression : $rate points de % par an.\n" +
                        "Dans combien d'années la couverture sera-t-elle totale ?",
                    yearsNeeded,
                )
            },
            {
                val start = Random.nextInt(2, 21) * 1000
                val doublingMonths = listOf(3, 6).random()
                val periods = Random.nextInt(2, 5)
                var result = start
                repeat(periods) { result *= 2 }
                NativeProblem(
                    "Une fintech compte $start utilisateurs et double ses utilisateurs tous les $doublingMonths mois.\n" +
                        "Combien d'utilisateurs aura-t-elle après ${doublingMonths * periods} mois ?",
                    result,
                )
            },
        )
    }
}

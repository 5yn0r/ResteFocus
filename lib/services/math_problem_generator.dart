import 'dart:math';

import '../core/constants.dart';
import '../data/models/math_problem.dart';

/// Génère des problèmes algorithmiquement, en complément de la banque Firestore
/// à venir (voir cahier des charges §14.2 — mitigation "banque insuffisante").
///
/// Chaque palier doit demander un vrai effort de calcul : un Math Gate qui se
/// résout en 2 secondes de calcul mental n'a aucune valeur de friction
/// cognitive (cahier des charges §10 — anti-contournement). Chaque cellule
/// matière×difficulté pioche parmi plusieurs templates pour éviter de revoir
/// toujours la même forme de problème.
class MathProblemGenerator {
  MathProblemGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  MathProblem generate({
    required Subject subject,
    required Difficulty difficulty,
  }) {
    switch (subject) {
      case Subject.maths:
        return _maths(difficulty);
      case Subject.physique:
        return _physique(difficulty);
      case Subject.stats:
        return _stats(difficulty);
      case Subject.electronique:
        return _electronique(difficulty);
      case Subject.algo:
        return _algo(difficulty);
      case Subject.reseaux:
        return _reseaux(difficulty);
      case Subject.culture:
        return _culture(difficulty);
    }
  }

  int _rand(int min, int max) => min + _random.nextInt(max - min + 1);

  int _nonZero(int min, int max) {
    final value = _rand(min, max);
    return value == 0 ? 1 : value;
  }

  MathProblem _pick(List<MathProblem Function()> pool) =>
      pool[_random.nextInt(pool.length)]();

  /// Convertit un entier en exposant Unicode (ex: 2 -> "²"), pour écrire x²
  /// au lieu de x^2. Réservé aux exposants dont la valeur change à chaque
  /// génération ; les exposants fixes (x², x³...) sont écrits en dur.
  static const _superDigits = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '-': '⁻',
  };

  String _sup(int n) =>
      n.toString().split('').map((c) => _superDigits[c] ?? c).join();

  // ---- Maths ----

  MathProblem _maths(Difficulty d) => switch (d) {
    Difficulty.facile => _pick(_mathsFacilePool),
    Difficulty.moyen => _pick(_mathsMoyenPool),
    Difficulty.difficile => _pick(_mathsDifficilePool),
  };

  late final List<MathProblem Function()> _mathsFacilePool = [
    () {
      final a = _rand(4, 15);
      final x = _rand(5, 30);
      final b = _rand(10, 99);
      final c = a * x + b;
      return MathProblem(
        question: 'Résous : $a·x + $b = $c\nQuelle est la valeur de x ?',
        answer: x.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.facile,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint: 'Isole x : x = (c − b) ⁄ a',
      );
    },
    () {
      final a = _rand(3, 9);
      var c = _rand(2, 6);
      if (c == a) c += 1;
      final x = _rand(4, 20);
      final b = _rand(5, 40);
      final d = (a - c) * x + b;
      return MathProblem(
        question:
            'Résous : $a·x + $b = $c·x + $d\nQuelle est la valeur de x ?',
        answer: x.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.facile,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint: 'Regroupe les x d\'un côté : ($a − $c)·x = $d − $b',
      );
    },
  ];

  late final List<MathProblem Function()> _mathsMoyenPool = [
    () {
      final a = _rand(2, 6);
      final m = _rand(2, 9);
      final n = _rand(2, 4);
      final k = _rand(2, 3);
      // f(x) = a·x^n + m·x  ->  f'(x) = a·n·x^(n-1) + m, évaluée en x=k
      final result = a * n * pow(k, n - 1) + m;
      return MathProblem(
        question:
            "Soit f(x) = $a·x${_sup(n)} + $m·x. Quelle est la valeur de f'($k) ?",
        answer: result.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.moyen,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint: "f'(x) = $a·$n·x${_sup(n - 1)} + $m",
      );
    },
    () {
      final p = _nonZero(-9, 9);
      var q = _nonZero(-9, 9);
      if (q == p) q += q > 0 ? 1 : -1;
      final b = -(p + q);
      final c = p * q;
      final larger = max(p, q);
      return MathProblem(
        question:
            'Résous : x² ${b < 0 ? '−' : '+'} ${b.abs()}·x ${c < 0 ? '−' : '+'} ${c.abs()} = 0\n'
            'Quelle est la plus grande racine ?',
        answer: larger.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.moyen,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint: 'Cette équation se factorise en (x − $p)(x − $q) = 0',
      );
    },
  ];

  late final List<MathProblem Function()> _mathsDifficilePool = [
    () {
      final a = _rand(1, 6);
      final b = _nonZero(-8, 8);
      final c = _rand(1, 8);
      final upper = _rand(3, 6);
      // primitive de a·x² + b·x + c : a·x³/3 + b·x²/2 + c·x
      final result =
          a * pow(upper, 3) / 3 + b * pow(upper, 2) / 2 + c * upper;
      return MathProblem(
        question:
            'Calcule ∫₀${_sup(upper)} ($a·x² ${b < 0 ? '−' : '+'} ${b.abs()}·x + $c) dx',
        answer: result.toDouble(),
        tolerance: 0.1,
        difficulty: Difficulty.difficile,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint:
            'Primitive : $a·x³⁄3 + $b·x²⁄2 + $c·x, évaluée entre 0 et $upper',
      );
    },
    () {
      final a = _rand(1, 5);
      final r = _rand(2, 3);
      final n = _rand(3, 6);
      final s = (a * (pow(r, n) - 1) / (r - 1)).round();
      return MathProblem(
        question:
            'Suite géométrique de premier terme $a et de raison $r.\n'
            'Calcule la somme S des $n premiers termes.',
        answer: s.toDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.difficile,
        subject: Subject.maths,
        type: ProblemType.calcul,
        hint: 'S = a·(rⁿ − 1) ⁄ (r − 1)',
      );
    },
  ];

  // ---- Physique ----

  MathProblem _physique(Difficulty d) => switch (d) {
    Difficulty.facile => _pick(_physiqueFacilePool),
    Difficulty.moyen => _pick(_physiqueMoyenPool),
    Difficulty.difficile => _pick(_physiqueDifficilePool),
  };

  late final List<MathProblem Function()> _physiqueFacilePool = [
    () {
      final distanceM = _rand(500, 5000);
      final tempsMin = _rand(2, 20);
      final vitesseKmh = (distanceM / 1000) / (tempsMin / 60);
      return MathProblem(
        question:
            'Un mobile parcourt ${distanceM}m en $tempsMin minutes à vitesse constante.\n'
            'Quelle est sa vitesse en km/h ?',
        answer: vitesseKmh,
        tolerance: 0.1,
        difficulty: Difficulty.facile,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'Convertis en km et en heures avant de diviser',
      );
    },
    () {
      final v = _rand(20, 120);
      final t2 = _rand(1, 6);
      final d2 = v * t2;
      return MathProblem(
        question:
            'Un mobile roule à $v km/h. À cette vitesse, quelle distance (km) '
            'parcourt-il en ${t2}h ?',
        answer: d2.toDouble(),
        tolerance: 0.1,
        difficulty: Difficulty.facile,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'distance = vitesse × temps',
      );
    },
  ];

  late final List<MathProblem Function()> _physiqueMoyenPool = [
    () {
      final tSeconds = _rand(2, 6);
      const g = 9.8;
      final distance = 0.5 * g * tSeconds * tSeconds;
      return MathProblem(
        question:
            'Un objet est lâché en chute libre (sans vitesse initiale, g = 9.8 m/s²).\n'
            'Quelle distance a-t-il parcourue après $tSeconds secondes ? (d = ½gt², en mètres, arrondi à l\'entier)',
        answer: distance.roundToDouble(),
        tolerance: 1,
        difficulty: Difficulty.moyen,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'd = 0.5 × 9.8 × t²',
      );
    },
    () {
      final m = _rand(2, 20);
      final h = _rand(2, 15);
      const g = 9.8;
      final ep = m * g * h;
      return MathProblem(
        question:
            'Une masse de ${m}kg est soulevée à ${h}m de hauteur (g = 9.8 m/s²).\n'
            'Quelle est son énergie potentielle (J) ? (Ep = m·g·h, arrondie à l\'entier)',
        answer: ep.roundToDouble(),
        tolerance: 1,
        difficulty: Difficulty.moyen,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'Ep = m × g × h',
      );
    },
  ];

  late final List<MathProblem Function()> _physiqueDifficilePool = [
    () {
      final l = _rand(1, 8); // en mH
      final c = _rand(1, 8); // en µF
      final lH = l * 1e-3;
      final cF = c * 1e-6;
      final f = 1 / (2 * pi * sqrt(lH * cF));
      return MathProblem(
        question:
            'Circuit LC : L = $l mH, C = $c µF.\nQuelle est la fréquence de résonance en Hz ? (f = 1 ⁄ (2π√(LC))) — arrondis à l\'entier',
        answer: f.roundToDouble(),
        tolerance: max(1, f * 0.02),
        difficulty: Difficulty.difficile,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'Convertis L en Henry et C en Farad avant de calculer',
      );
    },
    () {
      final v0 = _rand(10, 40);
      const g = 9.8;
      final range = (v0 * v0) / g;
      return MathProblem(
        question:
            'Un projectile est lancé à $v0 m/s avec un angle de 45° (g = 9.8 m/s²).\n'
            'Quelle est sa portée maximale (m) ? (R = v₀²⁄g, arrondie à l\'entier)',
        answer: range.roundToDouble(),
        tolerance: 1,
        difficulty: Difficulty.difficile,
        subject: Subject.physique,
        type: ProblemType.calcul,
        hint: 'À 45°, R = v₀² ⁄ g',
      );
    },
  ];

  // ---- Stats ----

  MathProblem _stats(Difficulty d) => switch (d) {
    Difficulty.facile => _pick(_statsFacilePool),
    Difficulty.moyen => _pick(_statsMoyenPool),
    Difficulty.difficile => _pick(_statsDifficilePool),
  };

  late final List<MathProblem Function()> _statsFacilePool = [
    () {
      final values = List.generate(7, (_) => _rand(1, 99));
      final mean = values.reduce((a, b) => a + b) / values.length;
      return MathProblem(
        question:
            'Quelle est la moyenne de : ${values.join(', ')} ?\n(arrondie à 0.01 près)',
        answer: mean,
        tolerance: 0.02,
        difficulty: Difficulty.facile,
        subject: Subject.stats,
        type: ProblemType.calcul,
      );
    },
    () {
      final values = List.generate(6, (_) => _rand(1, 99));
      final range = values.reduce(max) - values.reduce(min);
      return MathProblem(
        question: 'Quelle est l\'étendue (max − min) de : ${values.join(', ')} ?',
        answer: range.toDouble(),
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.stats,
        type: ProblemType.calcul,
      );
    },
  ];

  late final List<MathProblem Function()> _statsMoyenPool = [
    () {
      final n = _rand(7, 12);
      final k = _rand(2, n - 2);
      double comb(int n, int k) {
        double res = 1;
        for (var i = 0; i < k; i++) {
          res = res * (n - i) / (i + 1);
        }
        return res;
      }

      return MathProblem(
        question:
            'Combien de façons de choisir $k éléments parmi $n ? (C($n,$k))',
        answer: comb(n, k).roundToDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.moyen,
        subject: Subject.stats,
        type: ProblemType.calcul,
        hint: 'C(n,k) = n! ⁄ (k!(n−k)!)',
      );
    },
    () {
      final n = _rand(5, 9);
      final k = _rand(2, n - 1);
      double perm = 1;
      for (var i = 0; i < k; i++) {
        perm *= (n - i);
      }
      return MathProblem(
        question:
            'Combien d\'arrangements ordonnés de $k éléments parmi $n ? (A($n,$k))',
        answer: perm.roundToDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.moyen,
        subject: Subject.stats,
        type: ProblemType.calcul,
        hint: 'A(n,k) = n! ⁄ (n−k)!',
      );
    },
  ];

  late final List<MathProblem Function()> _statsDifficilePool = [
    () {
      final mu = _rand(50, 150);
      final sigma = _rand(4, 20);
      final m = _rand(2, 4) * (_random.nextBool() ? 1 : -1);
      final x = mu + m * sigma;
      return MathProblem(
        question:
            'Une variable suit une loi normale N(μ=$mu, σ=$sigma).\nQuel est le z-score de x=$x ?',
        answer: m.toDouble(),
        tolerance: 0.05,
        difficulty: Difficulty.difficile,
        subject: Subject.stats,
        type: ProblemType.calcul,
        hint: 'z = (x − μ) ⁄ σ',
      );
    },
    () {
      final base = _rand(10, 30);
      final values = List.generate(5, (_) => base + _rand(-6, 6));
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
          values.length;
      final sd = sqrt(variance);
      return MathProblem(
        question:
            'Calcule l\'écart-type (population) de : ${values.join(', ')} ?\n(arrondi à 0.1 près)',
        answer: double.parse(sd.toStringAsFixed(1)),
        tolerance: 0.15,
        difficulty: Difficulty.difficile,
        subject: Subject.stats,
        type: ProblemType.calcul,
        hint: 'σ = √( Σ(xᵢ − μ)² ⁄ n )',
      );
    },
  ];

  // ---- Électronique ----

  MathProblem _electronique(Difficulty d) => switch (d) {
    Difficulty.facile => _pick(_electroniqueFacilePool),
    Difficulty.moyen => _pick(_electroniqueMoyenPool),
    Difficulty.difficile => _pick(_electroniqueDifficilePool),
  };

  late final List<MathProblem Function()> _electroniqueFacilePool = [
    () {
      final r = _rand(15, 250);
      final i = _rand(1, 9);
      return MathProblem(
        question:
            'Loi d\'Ohm : R = $r Ω, I = $i A.\nQuelle est la tension U en Volts ?',
        answer: (r * i).toDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.facile,
        subject: Subject.electronique,
        type: ProblemType.calcul,
        hint: 'U = R × I',
      );
    },
    () {
      final u = _rand(5, 24);
      final i = _rand(1, 10);
      return MathProblem(
        question:
            'Un circuit a une tension U = $u V et un courant I = $i A.\n'
            'Quelle est la puissance P en Watts ?',
        answer: (u * i).toDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.facile,
        subject: Subject.electronique,
        type: ProblemType.calcul,
        hint: 'P = U × I',
      );
    },
  ];

  late final List<MathProblem Function()> _electroniqueMoyenPool = [
    () {
      final r1 = _rand(10, 80);
      final r2 = _rand(10, 80);
      final r3 = _rand(10, 80);
      return MathProblem(
        question:
            'Trois résistances $r1Ω, $r2Ω et $r3Ω en série.\nQuelle est la résistance équivalente en Ω ?',
        answer: (r1 + r2 + r3).toDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.moyen,
        subject: Subject.electronique,
        type: ProblemType.calcul,
      );
    },
    () {
      final r1 = _rand(10, 100);
      final r2 = _rand(10, 100);
      final vs = _rand(5, 24);
      final v2 = vs * r2 / (r1 + r2);
      return MathProblem(
        question:
            'Pont diviseur : R1=$r1Ω, R2=$r2Ω, alimentés en $vs V.\n'
            'Quelle est la tension aux bornes de R2 (V) ? (arrondie à 0.1 près)',
        answer: double.parse(v2.toStringAsFixed(1)),
        tolerance: 0.2,
        difficulty: Difficulty.moyen,
        subject: Subject.electronique,
        type: ProblemType.calcul,
        hint: 'V2 = Vs × R2 ⁄ (R1 + R2)',
      );
    },
  ];

  late final List<MathProblem Function()> _electroniqueDifficilePool = [
    () {
      final r1 = _rand(20, 100);
      final r2 = _rand(20, 100);
      final r3 = _rand(20, 100);
      final req = 1 / (1 / r1 + 1 / r2 + 1 / r3);
      return MathProblem(
        question:
            'Trois résistances $r1 Ω, $r2 Ω et $r3 Ω en parallèle.\nQuelle est la résistance équivalente en Ω ? (arrondie à 0.1 près)',
        answer: double.parse(req.toStringAsFixed(1)),
        tolerance: 0.3,
        difficulty: Difficulty.difficile,
        subject: Subject.electronique,
        type: ProblemType.calcul,
        hint: '1 ⁄ Req = 1 ⁄ R1 + 1 ⁄ R2 + 1 ⁄ R3',
      );
    },
    () {
      final f = _rand(50, 500);
      final cUF = _rand(1, 20);
      final cF = cUF * 1e-6;
      final xc = 1 / (2 * pi * f * cF);
      return MathProblem(
        question:
            'Condensateur C = $cUF µF à f = $f Hz.\nQuelle est sa réactance Xc en Ω ? (Xc = 1 ⁄ (2πfC), arrondie à l\'entier)',
        answer: xc.roundToDouble(),
        tolerance: max(1, xc * 0.02),
        difficulty: Difficulty.difficile,
        subject: Subject.electronique,
        type: ProblemType.calcul,
        hint: 'Convertis C en Farad avant de calculer',
      );
    },
  ];

  // ---- Culture & Tech Afrique ----
  //
  // Toujours des calculs mis en situation (coût, énergie, réseau, PND...) et
  // jamais des dates/chiffres historiques inventés : la friction cognitive
  // vient du calcul, pas d'un pari sur l'exactitude d'un fait.

  MathProblem _culture(Difficulty d) => switch (d) {
    Difficulty.facile => _pick(_cultureFacilePool),
    Difficulty.moyen => _pick(_cultureMoyenPool),
    Difficulty.difficile => _pick(_cultureDifficilePool),
  };

  late final List<MathProblem Function()> _cultureFacilePool = [
    () {
      final pricePerGo = [250, 500][_random.nextInt(2)];
      final n = _rand(3, 12);
      final total = pricePerGo * n;
      return MathProblem(
        question:
            'Un forfait internet coûte $pricePerGo FCFA le Go.\n'
            'Combien de Go peux-tu acheter avec $total FCFA ?',
        answer: n.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.facile,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'Go = budget ⁄ prix par Go',
      );
    },
    () {
      final amount = _rand(5, 50) * 1000;
      const feePct = 1;
      final fee = amount * feePct / 100;
      return MathProblem(
        question:
            'Un transfert Mobile Money coûte $feePct% du montant envoyé.\n'
            'Quel est le frais (FCFA) pour un envoi de $amount FCFA ?',
        answer: fee.toDouble(),
        tolerance: 1,
        difficulty: Difficulty.facile,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'frais = montant × $feePct ⁄ 100',
      );
    },
  ];

  late final List<MathProblem Function()> _cultureMoyenPool = [
    () {
      final power = _rand(50, 400);
      final hours = _rand(3, 8);
      final weekly = power * hours * 7;
      return MathProblem(
        question:
            'Un panneau solaire de ${power}W fonctionne ${hours}h/jour.\n'
            'Combien de Wh produit-il en une semaine (7 jours) ?',
        answer: weekly.toDouble(),
        tolerance: 1,
        difficulty: Difficulty.moyen,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'Wh = puissance × heures × jours',
      );
    },
    () {
      final g4 = _rand(50, 70);
      final g5 = _rand(10, 20);
      final both = _rand(5, g5);
      final atLeastOne = g4 + g5 - both;
      return MathProblem(
        question:
            'La 4G couvre $g4% du territoire, la 5G $g5%, et $both% ont les deux.\n'
            'Quel pourcentage du territoire a au moins l\'un des deux réseaux ?',
        answer: atLeastOne.toDouble(),
        tolerance: 0.5,
        difficulty: Difficulty.moyen,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'Union = 4G + 5G − (les deux)',
      );
    },
  ];

  late final List<MathProblem Function()> _cultureDifficilePool = [
    () {
      final rate = _rand(5, 12);
      final yearsNeeded = _rand(3, 7);
      final current = 100 - rate * yearsNeeded;
      return MathProblem(
        question:
            'Le plan national vise 100% de couverture fibre optique.\n'
            'Couverture actuelle : $current%. Progression : $rate points de % par an.\n'
            'Dans combien d\'années la couverture sera-t-elle totale ?',
        answer: yearsNeeded.toDouble(),
        tolerance: 0.01,
        difficulty: Difficulty.difficile,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'années = (100 − couverture actuelle) ⁄ progression annuelle',
      );
    },
    () {
      final start = _rand(2, 20) * 1000;
      final doublingMonths = [3, 6][_random.nextInt(2)];
      final periods = _rand(2, 4);
      final months = doublingMonths * periods;
      final result = start * pow(2, periods);
      return MathProblem(
        question:
            'Une fintech compte $start utilisateurs et double ses utilisateurs tous les $doublingMonths mois.\n'
            'Combien d\'utilisateurs aura-t-elle après $months mois ?',
        answer: result.toDouble(),
        tolerance: 1,
        difficulty: Difficulty.difficile,
        subject: Subject.culture,
        type: ProblemType.calcul,
        hint: 'périodes = mois ⁄ $doublingMonths ; utilisateurs = début × 2ⁿ (n = périodes)',
      );
    },
  ];

  // ---- Algorithmique ----

  MathProblem _algo(Difficulty d) {
    final pool = _algoPool[d]!;
    final item = pool[_random.nextInt(pool.length)];
    return item;
  }

  MathProblem _reseaux(Difficulty d) {
    final pool = _reseauxPool[d]!;
    final item = pool[_random.nextInt(pool.length)];
    return item;
  }

  static final Map<Difficulty, List<MathProblem>> _algoPool = {
    Difficulty.facile: [
      MathProblem(
        question:
            'for i in range(5):\n  for j in range(3):\n    print(i, j)\nCombien de fois "print" est-il exécuté ?',
        answer: 15,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.algo,
        type: ProblemType.calcul,
      ),
      MathProblem(
        question:
            'Quelle est la complexité d\'une recherche dans un tableau non trié ?',
        answer: 2,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.algo,
        type: ProblemType.qcm,
        choices: const ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'],
      ),
      MathProblem(
        question:
            'i = 0\nwhile i < 12:\n  i += 3\nprint(i)\nQuelle est la valeur affichée ?',
        answer: 12,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.algo,
        type: ProblemType.calcul,
      ),
    ],
    Difficulty.moyen: [
      MathProblem(
        question:
            'Quelle est la complexité de la recherche dichotomique (binary search) ?',
        answer: 1,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.algo,
        type: ProblemType.qcm,
        choices: const ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
      ),
      MathProblem(
        question:
            'def f(n):\n  if n <= 1: return 1\n  return n * f(n - 1)\nQuelle est la valeur de f(6) ?',
        answer: 720,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.algo,
        type: ProblemType.calcul,
      ),
      MathProblem(
        question:
            'Un algorithme en O(n²) traite un tableau de 10 éléments en 5ms.\n'
            'Combien de ms (environ) pour un tableau de 20 éléments ?',
        answer: 20,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.algo,
        type: ProblemType.calcul,
        hint: '(20/10)² × 5',
      ),
      MathProblem(
        question:
            'Quelle est la complexité du tri fusion (merge sort) dans le pire cas ?',
        answer: 1,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.algo,
        type: ProblemType.qcm,
        choices: const ['O(n)', 'O(n log n)', 'O(n²)', 'O(2ⁿ)'],
      ),
    ],
    Difficulty.difficile: [
      MathProblem(
        question:
            'Quelle est la complexité moyenne du tri rapide (quicksort) ?',
        answer: 1,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.algo,
        type: ProblemType.qcm,
        choices: const ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'],
      ),
      MathProblem(
        question:
            'Suite définie par u(0)=1, u(n)=2·u(n-1)+1.\nQuelle est la valeur de u(4) ?',
        answer: 31,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.algo,
        type: ProblemType.calcul,
        hint: 'u(1)=3, u(2)=7, u(3)=15...',
      ),
      MathProblem(
        question:
            'def f(n):\n  if n <= 1: return n\n  return f(n-1) + f(n-2)\n'
            'Quelle est la valeur de f(9) ? (suite de Fibonacci)',
        answer: 34,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.algo,
        type: ProblemType.calcul,
        hint: 'f(0)=0, f(1)=1, f(2)=1, f(3)=2, f(4)=3...',
      ),
    ],
  };

  static final Map<Difficulty, List<MathProblem>> _reseauxPool = {
    Difficulty.facile: [
      MathProblem(
        question: 'Combien d\'adresses hôtes utilisables dans un réseau /24 ?',
        answer: 254,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁸ − 2',
      ),
      MathProblem(
        question: 'Combien d\'adresses hôtes utilisables dans un réseau /28 ?',
        answer: 14,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁴ − 2',
      ),
      MathProblem(
        question: 'Combien d\'adresses hôtes utilisables dans un réseau /26 ?',
        answer: 62,
        tolerance: 0,
        difficulty: Difficulty.facile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁶ − 2',
      ),
    ],
    Difficulty.moyen: [
      MathProblem(
        question: 'Combien d\'adresses hôtes utilisables dans un réseau /27 ?',
        answer: 30,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁵ − 2',
      ),
      MathProblem(
        question:
            'Un réseau /26 commence à 192.168.1.0.\nQuelle est l\'adresse de broadcast (dernier octet) ?',
        answer: 63,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: 'Bloc de 2⁶ = 64 adresses',
      ),
      MathProblem(
        question:
            'Un réseau /29 commence à 10.0.0.0.\nQuelle est l\'adresse de broadcast (dernier octet) ?',
        answer: 7,
        tolerance: 0,
        difficulty: Difficulty.moyen,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: 'Bloc de 2³ = 8 adresses',
      ),
    ],
    Difficulty.difficile: [
      MathProblem(
        question: 'Quel port TCP standard utilise HTTPS ?',
        answer: 443,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
      ),
      MathProblem(
        question:
            'Combien de sous-réseaux /28 peut-on créer à partir d\'un réseau /24 ?',
        answer: 16,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁴ (28-24=4)',
      ),
      MathProblem(
        question:
            'Combien de sous-réseaux /26 peut-on créer à partir d\'un réseau /22 ?',
        answer: 16,
        tolerance: 0,
        difficulty: Difficulty.difficile,
        subject: Subject.reseaux,
        type: ProblemType.calcul,
        hint: '2⁴ (26-22=4)',
      ),
    ],
  };
}

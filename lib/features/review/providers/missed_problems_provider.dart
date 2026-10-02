import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/math_problem.dart';
import '../../../data/models/missed_problem.dart';
import '../../../data/repositories/missed_problems_repository.dart';
import '../../session/providers/session_provider.dart';

final missedProblemsRepositoryProvider = Provider(
  (ref) => MissedProblemsRepository(),
);

/// Carnet d'erreurs : problèmes ratés au Math Gate (natif ou Flutter),
/// re-proposés jusqu'à être répondus correctement deux fois de suite.
class MissedProblemsNotifier extends AsyncNotifier<List<MissedProblem>> {
  @override
  Future<List<MissedProblem>> build() async {
    return ref.read(missedProblemsRepositoryProvider).load();
  }

  /// Repioche les échecs natifs en attente (MathGateActivity) et les
  /// fusionne au paquet. Le premier `build()` tombe forcément avant toute
  /// session (StatsScreen est construit dès le lancement par l'IndexedStack
  /// de HomeShell), donc c'est cette méthode — appelée à chaque visite de
  /// l'onglet Progrès — qui rattrape les échecs enregistrés entre-temps.
  Future<void> refresh() async {
    final fromNative = await _pullFromNative();
    if (fromNative.isEmpty) return;
    final current = List<MissedProblem>.from(state.value ?? []);
    await _save([...current, ...fromNative]);
  }

  Future<List<MissedProblem>> _pullFromNative() async {
    final raw = await ref.read(accessibilityBridgeProvider).pullMissedProblems();
    return raw.map((entry) {
      return MissedProblem(
        id: UniqueKey().toString(),
        question: entry['question'] as String,
        answer: (entry['answer'] as num).toDouble(),
        tolerance: 0,
        subject: Subject.values.byName(entry['subject'] as String),
        difficulty: Difficulty.values[entry['difficultyIndex'] as int],
        type: ProblemType.calcul,
        failedAt: DateTime.fromMillisecondsSinceEpoch(
          entry['failedAt'] as int,
        ),
      );
    }).toList();
  }

  Future<void> addMissed(MathProblem problem) async {
    final current = List<MissedProblem>.from(state.value ?? []);
    current.add(
      MissedProblem(
        id: UniqueKey().toString(),
        question: problem.question,
        answer: problem.answer,
        tolerance: problem.tolerance,
        subject: problem.subject,
        difficulty: problem.difficulty,
        type: problem.type,
        choices: problem.choices,
        failedAt: DateTime.now(),
      ),
    );
    await _save(current);
  }

  /// Retourne `true` si ce problème vient d'être maîtrisé (retiré du paquet).
  Future<bool> markCorrect(String id) async {
    final current = List<MissedProblem>.from(state.value ?? []);
    final index = current.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    final item = current.removeAt(index);
    final updated = item.copyWith(
      timesCorrectInARow: item.timesCorrectInARow + 1,
    );
    final mastered = updated.timesCorrectInARow >= MissedProblem.masteredThreshold;
    if (!mastered) current.add(updated);
    await _save(current);
    return mastered;
  }

  /// Remet le compteur à zéro et renvoie le problème en fin de paquet.
  Future<void> markWrong(String id) async {
    final current = List<MissedProblem>.from(state.value ?? []);
    final index = current.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final item = current.removeAt(index).copyWith(timesCorrectInARow: 0);
    current.add(item);
    await _save(current);
  }

  Future<void> _save(List<MissedProblem> problems) async {
    await ref.read(missedProblemsRepositoryProvider).save(problems);
    state = AsyncData(problems);
  }
}

final missedProblemsProvider =
    AsyncNotifierProvider<MissedProblemsNotifier, List<MissedProblem>>(
      MissedProblemsNotifier.new,
    );

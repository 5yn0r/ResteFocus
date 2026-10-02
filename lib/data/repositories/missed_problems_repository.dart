import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/missed_problem.dart';

class MissedProblemsRepository {
  static const _key = 'missed_problems';

  /// Nombre max d'entrées gardées ; les plus anciennes sont abandonnées.
  static const maxEntries = 100;

  Future<List<MissedProblem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => MissedProblem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<MissedProblem> problems) async {
    final trimmed = problems.length > maxEntries
        ? problems.sublist(problems.length - maxEntries)
        : problems;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );
  }
}

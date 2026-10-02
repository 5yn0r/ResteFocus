import 'dart:convert';

import 'package:flutter/services.dart';

/// Pont Flutter <-> Kotlin natif (FocusAccessibilityService, MathGateActivity).
///
/// Le service natif ne connaît que des package names et des entiers : toute la
/// logique de calibrage / niveau se décide côté Flutter avant d'appeler
/// [startSession].
class AccessibilityBridge {
  static const _channel = MethodChannel('com.restefocus/blocker');

  Future<bool> isAccessibilityServiceEnabled() async {
    final result = await _channel.invokeMethod<bool>(
      'isAccessibilityServiceEnabled',
    );
    return result ?? false;
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  /// endAt: heure de fin de la session — le natif lève le blocage tout seul
  /// passé cette heure, même si l'app Flutter a été tuée.
  /// difficultyIndex: 0=facile, 1=moyen, 2=difficile — utilisé par
  /// MathGateActivity côté Kotlin pour générer un problème du bon niveau.
  /// subjects: noms des matières choisies à l'onboarding (ex: 'maths',
  /// 'physique'...) — MathGateActivity en pioche une au hasard à chaque
  /// problème pour varier les domaines.
  Future<void> startSession({
    required List<String> blockedPackages,
    required DateTime endAt,
    required int difficultyIndex,
    required List<String> subjects,
  }) async {
    await _channel.invokeMethod('startSession', {
      'blockedPackages': blockedPackages,
      'endAtMillis': endAt.millisecondsSinceEpoch,
      'difficultyIndex': difficultyIndex,
      'subjects': subjects,
    });
  }

  Future<void> stopSession() async {
    await _channel.invokeMethod('stopSession');
  }

  /// Retourne {'solved': int, 'failed': int} comptabilisés côté natif depuis
  /// le début de la session active (remis à zéro par [startSession]).
  Future<Map<String, int>> getSessionStats() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getSessionStats',
    );
    return {
      'solved': (result?['solved'] as int?) ?? 0,
      'failed': (result?['failed'] as int?) ?? 0,
    };
  }

  /// Récupère puis vide la file des problèmes ratés au Math Gate natif
  /// (MathGateActivity) depuis la dernière consultation — chaque entrée
  /// contient question/answer/subject/difficultyIndex/failedAt.
  Future<List<Map<String, dynamic>>> pullMissedProblems() async {
    final result = await _channel.invokeMethod<String>('pullMissedProblems');
    if (result == null || result.isEmpty) return [];
    final list = jsonDecode(result) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Pousse le streak courant vers le widget écran d'accueil (le natif ne
  /// calcule pas le streak lui-même, seul Flutter le connaît).
  Future<void> setWidgetStreak(int days) async {
    await _channel.invokeMethod('setWidgetStreak', {'days': days});
  }
}

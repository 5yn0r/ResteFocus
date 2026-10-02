import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/focus_session.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../services/accessibility_bridge.dart';
import '../../onboarding/providers/user_provider.dart';

final sessionRepositoryProvider = Provider((ref) => SessionRepository());
final accessibilityBridgeProvider = Provider((ref) => AccessibilityBridge());

/// Dernière session terminée, pas encore célébrée par l'UI. Remise à null
/// par l'écran une fois le récapitulatif affiché.
class FinishedSessionNotifier extends Notifier<FocusSession?> {
  @override
  FocusSession? build() => null;

  void set(FocusSession? session) => state = session;
}

final finishedSessionProvider =
    NotifierProvider<FinishedSessionNotifier, FocusSession?>(
      FinishedSessionNotifier.new,
    );

/// XP gagnés : 1 par minute de focus + 5 par Math Gate résolu.
int xpForSession(FocusSession session) =>
    session.durationMinutes + session.mathGatesSolved * 5;

/// Session de focus en cours (null si aucune).
///
/// Le blocage lui-même est porté par le natif (SessionPrefs.kt), qui connaît
/// l'heure de fin. Ce notifier ne fait que tenir l'historique à jour et
/// clôturer la session quand elle arrive à échéance.
class SessionNotifier extends AsyncNotifier<FocusSession?> {
  Timer? _endTimer;

  @override
  Future<FocusSession?> build() async {
    ref.onDispose(() => _endTimer?.cancel());
    final active = await ref.read(sessionRepositoryProvider).loadActive();
    if (active == null || !active.isActive) return null;

    // L'app a pu être tuée pendant la session : si elle est déjà finie, on
    // l'archive directement (sa durée est plafonnée à la durée prévue).
    if (!DateTime.now().isBefore(active.plannedEnd)) {
      await _finish(active);
      return null;
    }
    _scheduleEnd(active);
    return active;
  }

  void _scheduleEnd(FocusSession session) {
    _endTimer?.cancel();
    _endTimer = Timer(session.remainingAt(DateTime.now()), stop);
  }

  Future<void> start({
    required List<String> blockedPackages,
    required int durationMinutes,
    required bool strictMode,
  }) async {
    final profile = ref.read(userProfileProvider).value;
    final difficulty =
        profile?.level.baseDifficulty ?? SchoolLevel.lycee.baseDifficulty;
    final subjects = profile?.subjects.isNotEmpty == true
        ? profile!.subjects.map((s) => s.name).toList()
        : [Subject.maths.name];

    final session = FocusSession(
      startTime: DateTime.now(),
      plannedDurationMinutes: durationMinutes,
      blockedPackages: blockedPackages,
      strictMode: strictMode,
    );

    await ref
        .read(accessibilityBridgeProvider)
        .startSession(
          blockedPackages: blockedPackages,
          endAt: session.plannedEnd,
          difficultyIndex: difficulty.index,
          subjects: subjects,
        );
    await ref.read(sessionRepositoryProvider).saveActive(session);

    state = AsyncData(session);
    _scheduleEnd(session);
  }

  /// Termine la session en cours (arrêt manuel ou échéance atteinte).
  Future<void> stop() async {
    final session = state.value;
    if (session == null) return;
    _endTimer?.cancel();
    await _finish(session);
    state = const AsyncData(null);
  }

  Future<void> _finish(FocusSession session) async {
    final bridge = ref.read(accessibilityBridgeProvider);
    final stats = await bridge.getSessionStats();
    await bridge.stopSession();

    final finished = session.copyWith(
      endTime: DateTime.now(),
      mathGatesSolved: stats['solved'],
      mathGatesFailed: stats['failed'],
    );
    await ref.read(sessionRepositoryProvider).archiveSession(finished);
    await ref.read(userProfileProvider.notifier).addXp(xpForSession(finished));
    ref.read(finishedSessionProvider.notifier).set(finished);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, FocusSession?>(
  SessionNotifier.new,
);

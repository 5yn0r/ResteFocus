import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/focus_session.dart';
import '../../session/providers/session_provider.dart';

class DayFocus {
  const DayFocus(this.day, this.minutes);

  final DateTime day;
  final int minutes;
}

class StatsSummary {
  const StatsSummary({
    required this.totalFocusMinutes,
    required this.todayMinutes,
    required this.sessionCount,
    required this.mathGatesSolved,
    required this.mathGatesFailed,
    required this.streakDays,
    required this.last7Days,
  });

  final int totalFocusMinutes;
  final int todayMinutes;
  final int sessionCount;
  final int mathGatesSolved;
  final int mathGatesFailed;
  final int streakDays;

  /// Minutes de focus par jour sur les 7 derniers jours, du plus ancien à
  /// aujourd'hui.
  final List<DayFocus> last7Days;

  double get successRate {
    final total = mathGatesSolved + mathGatesFailed;
    if (total == 0) return 0;
    return mathGatesSolved / total;
  }
}

/// Recalculé à chaque changement de session (démarrage / fin), pour que le
/// dashboard reste à jour sans action de l'utilisateur.
final statsProvider = FutureProvider<StatsSummary>((ref) async {
  ref.watch(sessionProvider);
  final history = await ref.read(sessionRepositoryProvider).loadHistory();
  return computeStats(history, DateTime.now());
});

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

StatsSummary computeStats(List<FocusSession> history, DateTime now) {
  var totalMinutes = 0;
  var solved = 0;
  var failed = 0;
  final byDay = <DateTime, int>{};

  for (final session in history) {
    totalMinutes += session.durationMinutes;
    solved += session.mathGatesSolved;
    failed += session.mathGatesFailed;
    final day = _dayOf(session.startTime);
    byDay[day] = (byDay[day] ?? 0) + session.durationMinutes;
  }

  final today = _dayOf(now);
  // DateTime(y, m, d - i) plutôt que subtract(Duration(days: i)) : reste
  // juste lors des changements d'heure été/hiver.
  DateTime daysAgo(int i) => DateTime(today.year, today.month, today.day - i);

  final last7 = List.generate(7, (i) {
    final day = daysAgo(6 - i);
    return DayFocus(day, byDay[day] ?? 0);
  });

  // Le streak ne se casse pas si la session du jour n'a pas encore eu lieu.
  var streak = 0;
  var i = (byDay[today] ?? 0) > 0 ? 0 : 1;
  while ((byDay[daysAgo(i)] ?? 0) > 0) {
    streak++;
    i++;
  }

  return StatsSummary(
    totalFocusMinutes: totalMinutes,
    todayMinutes: byDay[today] ?? 0,
    sessionCount: history.length,
    mathGatesSolved: solved,
    mathGatesFailed: failed,
    streakDays: streak,
    last7Days: last7,
  );
}

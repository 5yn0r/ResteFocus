import 'package:flutter_test/flutter_test.dart';
import 'package:restefocus/data/models/focus_session.dart';
import 'package:restefocus/features/stats/providers/stats_provider.dart';

FocusSession _session(DateTime start, int minutes, {int solved = 0}) =>
    FocusSession(
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      plannedDurationMinutes: minutes,
      blockedPackages: const [],
      mathGatesSolved: solved,
    );

void main() {
  final now = DateTime(2026, 9, 27, 18); // dimanche

  test('les 7 derniers jours se terminent aujourd\'hui', () {
    final stats = computeStats([_session(DateTime(2026, 9, 27, 9), 50)], now);
    expect(stats.last7Days.length, 7);
    expect(stats.last7Days.last.day, DateTime(2026, 9, 27));
    expect(stats.last7Days.last.minutes, 50);
    expect(stats.last7Days.first.day, DateTime(2026, 9, 21));
    expect(stats.todayMinutes, 50);
  });

  test(
    'streak : jours consécutifs, sans casser si rien encore aujourd\'hui',
    () {
      final history = [
        _session(DateTime(2026, 9, 24, 9), 25),
        _session(DateTime(2026, 9, 25, 9), 25),
        _session(DateTime(2026, 9, 26, 9), 25),
      ];
      expect(computeStats(history, now).streakDays, 3);

      final withGap = [
        _session(DateTime(2026, 9, 23, 9), 25),
        _session(DateTime(2026, 9, 26, 9), 25),
        _session(DateTime(2026, 9, 27, 9), 25),
      ];
      expect(computeStats(withGap, now).streakDays, 2);
    },
  );

  test('totaux et taux de réussite', () {
    final stats = computeStats([
      _session(DateTime(2026, 9, 27, 9), 30, solved: 3),
      _session(DateTime(2026, 9, 26, 9), 20, solved: 1),
    ], now);
    expect(stats.totalFocusMinutes, 50);
    expect(stats.sessionCount, 2);
    expect(stats.mathGatesSolved, 4);
    expect(stats.successRate, 1.0);
  });
}

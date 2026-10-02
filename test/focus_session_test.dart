import 'package:flutter_test/flutter_test.dart';
import 'package:restefocus/data/models/focus_session.dart';

void main() {
  final start = DateTime(2026, 9, 1, 8);

  FocusSession session({DateTime? endTime}) => FocusSession(
    startTime: start,
    endTime: endTime,
    plannedDurationMinutes: 90,
    blockedPackages: const ['com.instagram.android'],
  );

  test('la durée est plafonnée à la durée prévue', () {
    final finishedLate = session(endTime: start.add(const Duration(hours: 5)));
    expect(finishedLate.durationMinutes, 90);
  });

  test('un arrêt anticipé compte le temps réel', () {
    final stoppedEarly = session(
      endTime: start.add(const Duration(minutes: 30)),
    );
    expect(stoppedEarly.durationMinutes, 30);
  });

  test('le temps restant ne devient jamais négatif', () {
    final s = session();
    expect(
      s.remainingAt(start.add(const Duration(minutes: 60))),
      const Duration(minutes: 30),
    );
    expect(s.remainingAt(start.add(const Duration(hours: 3))), Duration.zero);
  });

  test('aller-retour JSON', () {
    final s = session(endTime: start.add(const Duration(minutes: 45)));
    final copy = FocusSession.fromJson(s.toJson());
    expect(copy.startTime, s.startTime);
    expect(copy.endTime, s.endTime);
    expect(copy.blockedPackages, s.blockedPackages);
  });
}

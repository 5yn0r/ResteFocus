class FocusSession {
  const FocusSession({
    required this.startTime,
    this.endTime,
    required this.plannedDurationMinutes,
    required this.blockedPackages,
    this.strictMode = false,
    this.mathGatesSolved = 0,
    this.mathGatesFailed = 0,
  });

  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDurationMinutes;
  final List<String> blockedPackages;
  final bool strictMode;
  final int mathGatesSolved;
  final int mathGatesFailed;

  bool get isActive => endTime == null;

  DateTime get plannedEnd =>
      startTime.add(Duration(minutes: plannedDurationMinutes));

  /// Temps restant à [now], jamais négatif.
  Duration remainingAt(DateTime now) {
    final remaining = plannedEnd.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Minutes réellement passées en focus. Plafonné à la durée prévue : si
  /// l'app est rouverte des heures après la fin, la session ne compte pas
  /// ces heures-là.
  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    final effectiveEnd = end.isAfter(plannedEnd) ? plannedEnd : end;
    return effectiveEnd.difference(startTime).inMinutes;
  }

  FocusSession copyWith({
    DateTime? endTime,
    int? mathGatesSolved,
    int? mathGatesFailed,
  }) {
    return FocusSession(
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      plannedDurationMinutes: plannedDurationMinutes,
      blockedPackages: blockedPackages,
      strictMode: strictMode,
      mathGatesSolved: mathGatesSolved ?? this.mathGatesSolved,
      mathGatesFailed: mathGatesFailed ?? this.mathGatesFailed,
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedDurationMinutes': plannedDurationMinutes,
    'blockedPackages': blockedPackages,
    'strictMode': strictMode,
    'mathGatesSolved': mathGatesSolved,
    'mathGatesFailed': mathGatesFailed,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null,
    plannedDurationMinutes: json['plannedDurationMinutes'] as int,
    blockedPackages: (json['blockedPackages'] as List)
        .map((e) => e as String)
        .toList(),
    strictMode: json['strictMode'] as bool? ?? false,
    mathGatesSolved: json['mathGatesSolved'] as int? ?? 0,
    mathGatesFailed: json['mathGatesFailed'] as int? ?? 0,
  );
}

import '../../core/constants.dart';

class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.level,
    required this.subjects,
    this.xpPoints = 0,
  });

  final String displayName;
  final SchoolLevel level;
  final List<Subject> subjects;
  final int xpPoints;

  UserProfile copyWith({
    String? displayName,
    SchoolLevel? level,
    List<Subject>? subjects,
    int? xpPoints,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      subjects: subjects ?? this.subjects,
      xpPoints: xpPoints ?? this.xpPoints,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'level': level.name,
    'subjects': subjects.map((s) => s.name).toList(),
    'xpPoints': xpPoints,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String,
      level: SchoolLevel.values.byName(json['level'] as String),
      subjects: (json['subjects'] as List)
          .map((s) => Subject.values.byName(s as String))
          .toList(),
      xpPoints: json['xpPoints'] as int? ?? 0,
    );
  }
}

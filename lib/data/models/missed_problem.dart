import '../../core/constants.dart';
import 'math_problem.dart';

/// Un problème raté au Math Gate (natif ou Flutter), gardé pour être
/// re-proposé plus tard dans le carnet d'erreurs. `timesCorrectInARow`
/// atteint 2 fait sortir le problème du paquet (considéré maîtrisé).
class MissedProblem {
  const MissedProblem({
    required this.id,
    required this.question,
    required this.answer,
    required this.tolerance,
    required this.subject,
    required this.difficulty,
    required this.type,
    this.choices = const [],
    required this.failedAt,
    this.timesCorrectInARow = 0,
  });

  final String id;
  final String question;
  final double answer;
  final double tolerance;
  final Subject subject;
  final Difficulty difficulty;
  final ProblemType type;
  final List<String> choices;
  final DateTime failedAt;
  final int timesCorrectInARow;

  static const masteredThreshold = 2;

  bool isCorrect(double givenAnswer) =>
      (givenAnswer - answer).abs() <= tolerance;

  MathProblem toMathProblem() => MathProblem(
    question: question,
    answer: answer,
    tolerance: tolerance,
    difficulty: difficulty,
    subject: subject,
    type: type,
    choices: choices,
  );

  MissedProblem copyWith({int? timesCorrectInARow}) => MissedProblem(
    id: id,
    question: question,
    answer: answer,
    tolerance: tolerance,
    subject: subject,
    difficulty: difficulty,
    type: type,
    choices: choices,
    failedAt: failedAt,
    timesCorrectInARow: timesCorrectInARow ?? this.timesCorrectInARow,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'tolerance': tolerance,
    'subject': subject.name,
    'difficulty': difficulty.name,
    'type': type.name,
    'choices': choices,
    'failedAt': failedAt.toIso8601String(),
    'timesCorrectInARow': timesCorrectInARow,
  };

  factory MissedProblem.fromJson(Map<String, dynamic> json) => MissedProblem(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: (json['answer'] as num).toDouble(),
    tolerance: (json['tolerance'] as num).toDouble(),
    subject: Subject.values.byName(json['subject'] as String),
    difficulty: Difficulty.values.byName(json['difficulty'] as String),
    type: ProblemType.values.byName(json['type'] as String),
    choices: (json['choices'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    failedAt: DateTime.parse(json['failedAt'] as String),
    timesCorrectInARow: json['timesCorrectInARow'] as int? ?? 0,
  );
}

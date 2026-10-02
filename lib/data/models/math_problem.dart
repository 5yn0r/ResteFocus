import '../../core/constants.dart';

enum ProblemType { calcul, qcm }

class MathProblem {
  const MathProblem({
    required this.question,
    required this.answer,
    required this.tolerance,
    required this.difficulty,
    required this.subject,
    required this.type,
    this.choices = const [],
    this.hint,
  });

  final String question;
  final double answer;
  final double tolerance;
  final Difficulty difficulty;
  final Subject subject;
  final ProblemType type;
  final List<String> choices;
  final String? hint;

  bool isCorrect(double givenAnswer) =>
      (givenAnswer - answer).abs() <= tolerance;
}

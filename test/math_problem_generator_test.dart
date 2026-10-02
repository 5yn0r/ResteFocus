import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restefocus/core/constants.dart';
import 'package:restefocus/data/models/math_problem.dart';
import 'package:restefocus/services/math_problem_generator.dart';

void main() {
  final generator = MathProblemGenerator(random: Random(42));

  test('chaque matière et difficulté produit un problème cohérent', () {
    for (final subject in Subject.values) {
      for (final difficulty in Difficulty.values) {
        for (var i = 0; i < 50; i++) {
          final p = generator.generate(
            subject: subject,
            difficulty: difficulty,
          );
          expect(p.subject, subject);
          expect(p.difficulty, difficulty);
          expect(p.answer.isFinite, isTrue);
          expect(p.isCorrect(p.answer), isTrue);
          if (p.type == ProblemType.qcm) {
            expect(p.choices.length, 4);
            expect(p.answer, inInclusiveRange(0, p.choices.length - 1));
            // Les choix sont affichés en boutons, pas dans l'énoncé.
            expect(p.question.contains('A)'), isFalse);
          }
        }
      }
    }
  });
}

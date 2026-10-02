import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/math_problem.dart';
import '../../../services/math_problem_generator.dart';
import '../../onboarding/providers/user_provider.dart';
import '../../review/providers/missed_problems_provider.dart';

/// Math Gate côté Flutter (cahier des charges §9) : exigé pour arrêter une
/// session en mode strict.
///
/// Le blocage des apps tierces passe, lui, par MathGateActivity.kt, qui
/// s'affiche sans démarrer de moteur Flutter.
///
/// Se ferme avec `true` quand un problème a été résolu, `null` sinon.
class MathGateScreen extends ConsumerStatefulWidget {
  const MathGateScreen({super.key});

  @override
  ConsumerState<MathGateScreen> createState() => _MathGateScreenState();
}

class _MathGateScreenState extends ConsumerState<MathGateScreen> {
  static const _maxFails = 3;
  static const _cooldown = Duration(minutes: 2);

  final _generator = MathProblemGenerator();
  final _answerController = TextEditingController();
  final _random = Random();

  late List<Subject> _subjects;
  late Subject _subject;
  late Difficulty _difficulty;
  late MathProblem _problem;
  late String _quote;

  int _consecutiveFails = 0;
  bool _showHint = false;
  String? _feedback;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _subjects = profile?.subjects.isNotEmpty == true
        ? profile!.subjects
        : [Subject.maths];
    _difficulty = profile?.level.baseDifficulty ?? Difficulty.facile;
    _generateProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Change de matière à chaque problème parmi celles choisies à
  /// l'onboarding, pour que le Math Gate ne porte pas toujours sur la même.
  void _generateProblem() {
    _subject = _subjects[_random.nextInt(_subjects.length)];
    _problem = _generator.generate(subject: _subject, difficulty: _difficulty);
    _answerController.clear();
    _showHint = false;
    _quote = mathGateQuotes[_random.nextInt(mathGateQuotes.length)];
  }

  /// Calibrage adaptatif simplifié (§9.1) : deux échecs d'affilée font
  /// descendre d'un niveau.
  void _easeDifficulty() {
    if (_consecutiveFails >= 2 && _difficulty.index > 0) {
      _difficulty = Difficulty.values[_difficulty.index - 1];
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = _cooldown.inSeconds;
      _quote = mathGateQuotes[_random.nextInt(mathGateQuotes.length)];
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
          _consecutiveFails = 0;
          _feedback = null;
          _generateProblem();
        }
      });
    });
  }

  void _submitTyped() {
    final value = double.tryParse(
      _answerController.text.trim().replaceAll(',', '.'),
    );
    if (value == null) {
      setState(() => _feedback = 'Entre un nombre valide.');
      return;
    }
    _check(value);
  }

  void _check(double answer) {
    if (_problem.isCorrect(answer)) {
      Navigator.of(context).pop(true);
      return;
    }

    ref.read(missedProblemsProvider.notifier).addMissed(_problem);
    _consecutiveFails++;
    if (_consecutiveFails >= _maxFails) {
      _feedback = null;
      _startCooldown();
      return;
    }
    setState(() {
      _easeDifficulty();
      _feedback =
          'Raté. Encore ${_maxFails - _consecutiveFails} essai(s) avant une pause.';
      _generateProblem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Math Gate')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _cooldownSeconds > 0 ? _buildCooldown() : _buildProblem(),
        ),
      ),
    );
  }

  Widget _buildCooldown() {
    final theme = Theme.of(context);
    final minutes = _cooldownSeconds ~/ 60;
    final seconds = _cooldownSeconds % 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_bottom_rounded,
            size: 56,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '$_maxFails échecs d\'affilée — petite pause',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 32),
          Text(
            _quote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblem() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final diffColor = switch (_difficulty) {
      Difficulty.facile => Colors.green,
      Difficulty.moyen => Colors.orange,
      Difficulty.difficile => Colors.redAccent,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Résous ce problème pour arrêter la session.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${_subject.emoji} ${_subject.label}')),
            Chip(
              label: Text(_difficulty.label),
              backgroundColor: diffColor.withValues(alpha: 0.16),
              labelStyle: TextStyle(
                color: diffColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: diffColor.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _problem.question,
              style: theme.textTheme.titleLarge?.copyWith(height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_problem.type == ProblemType.qcm)
          for (final (index, choice) in _problem.choices.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _check(index.toDouble()),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(choice),
                ),
              ),
            )
        else ...[
          TextField(
            controller: _answerController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Ta réponse'),
            onSubmitted: (_) => _submitTyped(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submitTyped, child: const Text('Valider')),
        ],
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Text(
            _feedback!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (_problem.hint != null && !_showHint)
          TextButton.icon(
            onPressed: () => setState(() => _showHint = true),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Voir un indice'),
          ),
        if (_showHint && _problem.hint != null)
          Text('💡 ${_problem.hint}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text(
          _quote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/math_problem.dart';
import '../../../data/models/missed_problem.dart';
import '../providers/missed_problems_provider.dart';

/// Carnet d'erreurs : reprend un par un les problèmes ratés au Math Gate,
/// sans pression de temps ni cooldown. Un problème sort du paquet dès qu'il
/// est répondu correctement deux fois de suite ; une mauvaise réponse le
/// renvoie en fin de paquet.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _answerController = TextEditingController();
  String? _lastProblemId;
  String? _feedback;
  bool _justMastered = false;
  int _reviewedCount = 0;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _check(MissedProblem problem, double answer) async {
    final notifier = ref.read(missedProblemsProvider.notifier);
    if (problem.isCorrect(answer)) {
      final mastered = await notifier.markCorrect(problem.id);
      setState(() {
        _reviewedCount++;
        _justMastered = mastered;
        _feedback = mastered
            ? 'Maîtrisé !'
            : 'Bien joué, encore une fois pour valider.';
        _answerController.clear();
      });
    } else {
      await notifier.markWrong(problem.id);
      setState(() {
        _justMastered = false;
        _feedback = 'Raté, on la reverra plus tard.';
        _answerController.clear();
      });
    }
  }

  void _submitTyped(MissedProblem problem) {
    final value = double.tryParse(
      _answerController.text.trim().replaceAll(',', '.'),
    );
    if (value == null) {
      setState(() => _feedback = 'Entre un nombre valide.');
      return;
    }
    _check(problem, value);
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(missedProblemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Carnet d\'erreurs')),
      body: SafeArea(
        child: problemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (problems) => problems.isEmpty
              ? _buildDone(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildProblem(context, problems.first, problems.length),
                ),
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _reviewedCount > 0
                  ? 'Paquet terminé, bravo !'
                  : 'Rien à réviser pour l\'instant.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Les prochains problèmes ratés au Math Gate apparaîtront ici.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblem(BuildContext context, MissedProblem problem, int remaining) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (problem.id != _lastProblemId) {
      _lastProblemId = problem.id;
      _feedback = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$remaining problème${remaining > 1 ? 's' : ''} à réviser',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${problem.subject.emoji} ${problem.subject.label}')),
            Chip(label: Text(problem.difficulty.label)),
            if (problem.timesCorrectInARow > 0)
              Chip(
                avatar: const Icon(Icons.check_rounded, size: 16),
                label: Text('${problem.timesCorrectInARow}/${MissedProblem.masteredThreshold}'),
                backgroundColor: scheme.primaryContainer,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              problem.question,
              style: theme.textTheme.titleLarge?.copyWith(height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (problem.type == ProblemType.qcm)
          for (final (index, choice) in problem.choices.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _check(problem, index.toDouble()),
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
            onSubmitted: (_) => _submitTyped(problem),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _submitTyped(problem),
            child: const Text('Vérifier'),
          ),
        ],
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Text(
            _feedback!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _justMastered ? scheme.primary : scheme.error,
              fontWeight: _justMastered ? FontWeight.w700 : null,
            ),
          ),
        ],
      ],
    );
  }
}

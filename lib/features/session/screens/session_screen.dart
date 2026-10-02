import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/xp.dart';
import '../../../data/models/focus_session.dart';
import '../../apps/providers/blocked_apps_provider.dart';
import '../../home/providers/home_tab_provider.dart';
import '../../math_gate/screens/math_gate_screen.dart';
import '../../onboarding/providers/user_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../../permissions/widgets/permissions_card.dart';
import '../../stats/providers/stats_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/duration_dial.dart';
import '../widgets/focus_ring.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  int _durationMinutes = 50;
  bool _strictMode = false;
  bool _busy = false;
  bool _celebrating = false;

  Future<void> _startSession() async {
    final blockedApps = ref.read(blockedAppsProvider).value ?? [];
    if (blockedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choisis d\'abord les apps à bloquer.'),
          action: SnackBarAction(
            label: 'Choisir',
            onPressed: () =>
                ref.read(homeTabProvider.notifier).select(HomeTab.apps),
          ),
        ),
      );
      return;
    }

    final permissions = ref.read(permissionsProvider).value;
    if (permissions != null && !permissions.allGranted) {
      final startAnyway = await _confirmMissingPermissions();
      if (startAnyway != true) return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .start(
            blockedPackages: blockedApps.map((a) => a.packageName).toList(),
            durationMinutes: _durationMinutes,
            strictMode: _strictMode,
          );
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmMissingPermissions() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Le blocage n\'est pas prêt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sans ces permissions, ResteFocus ne peut pas bloquer tes apps '
                'pendant la session.',
              ),
              const SizedBox(height: 16),
              const PermissionsCard(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Démarrer quand même'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _stopSession({required bool strict}) async {
    if (strict) {
      // Mode strict : il faut résoudre un Math Gate pour désactiver la
      // session. Quitter l'écran sans réussir ne l'arrête pas.
      final solved = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const MathGateScreen()));
      if (solved != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Arrêter la session ?'),
          content: const Text(
            'Tes apps seront débloquées. Le temps déjà passé est conservé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arrêter'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(sessionProvider.notifier).stop();
  }

  Future<void> _pickCustomDuration() async {
    var value = _durationMinutes;
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Durée personnalisée',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Fais tourner le cadran pour ajuster.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                DurationDial(
                  minutes: value,
                  onChanged: (v) => setSheetState(() => value = v),
                  size: 220,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final minutes in sessionDurationPresets)
                      ChoiceChip(
                        label: Text(formatDuration(minutes)),
                        selected: value == minutes,
                        onSelected: (_) =>
                            setSheetState(() => value = minutes),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(value),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _durationMinutes = picked);
  }

  void _celebrate(FocusSession finished) {
    _celebrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => _SessionSummarySheet(session: finished),
      );
      _celebrating = false;
      ref.read(finishedSessionProvider.notifier).set(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);
    final finished = ref.watch(finishedSessionProvider);
    if (finished != null && !_celebrating) _celebrate(finished);

    return Scaffold(
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (session) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: session != null && session.isActive
              ? _ActiveSessionView(
                  key: const ValueKey('active'),
                  session: session,
                  onStop: () => _stopSession(strict: session.strictMode),
                )
              : SafeArea(key: const ValueKey('form'), child: _buildStartForm()),
        ),
      ),
    );
  }

  Widget _buildStartForm() {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final stats = ref.watch(statsProvider).value;
    final blockedApps = ref.watch(blockedAppsProvider).value ?? [];
    final permissions = ref.watch(permissionsProvider).value;
    final level = XpLevel.fromXp(profile?.xpPoints ?? 0);
    final isCustom = !sessionDurationPresets.contains(_durationMinutes);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Salut ${profile?.displayName ?? ''}',
                                  style: theme.textTheme.headlineMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.waving_hand_rounded,
                                color: AppColors.streak,
                                size: 26,
                              ),
                            ],
                          ),
                          Text(
                            'Prêt à te concentrer ?',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _LevelBadge(level: level),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (permissions != null && !permissions.allGranted) ...[
                _PermissionsBanner(onTap: _confirmMissingPermissions),
                const SizedBox(height: 16),
              ],
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: _TodayCard(
                  todayMinutes: stats?.todayMinutes ?? 0,
                  streakDays: stats?.streakDays ?? 0,
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durée', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final minutes in sessionDurationPresets)
                          ChoiceChip(
                            label: Text(formatDuration(minutes)),
                            selected: _durationMinutes == minutes,
                            onSelected: (_) =>
                                setState(() => _durationMinutes = minutes),
                          ),
                        ChoiceChip(
                          avatar: isCustom
                              ? null
                              : const Icon(Icons.tune_rounded, size: 18),
                          label: Text(
                            isCustom
                                ? formatDuration(_durationMinutes)
                                : 'Autre',
                          ),
                          selected: isCustom,
                          onSelected: (_) => _pickCustomDuration(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apps bloquées', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => ref
                            .read(homeTabProvider.notifier)
                            .select(HomeTab.apps),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                child: const Icon(Icons.block_rounded),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blockedApps.isEmpty
                                          ? 'Aucune app sélectionnée'
                                          : '${blockedApps.length} app${blockedApps.length > 1 ? 's' : ''}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      blockedApps.isEmpty
                                          ? 'Touche pour choisir tes distractions'
                                          : blockedApps
                                                .map((a) => a.appName)
                                                .join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    secondary: Icon(
                      _strictMode
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: _strictMode ? AppColors.strict : null,
                    ),
                    value: _strictMode,
                    onChanged: (v) => setState(() => _strictMode = v),
                    title: const Text('Mode strict'),
                    subtitle: const Text(
                      'Un problème à résoudre pour arrêter avant la fin',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _startSession,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Démarrer · ${formatDuration(_durationMinutes)}'),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final XpLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          '${level.title} · ${level.xpIntoLevel}/${level.xpForNextLevel} XP',
      child: SizedBox.square(
        dimension: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: level.progress,
              strokeWidth: 4,
              backgroundColor: scheme.primaryContainer,
              strokeCap: StrokeCap.round,
            ),
            Text(
              'Niv.\n${level.level}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsBanner extends StatelessWidget {
  const _PermissionsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.streak;
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Active les permissions pour que le blocage fonctionne.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todayMinutes, required this.streakDays});

  final int todayMinutes;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aujourd'hui",
                  style: textTheme.labelLarge?.copyWith(
                    color: white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDuration(todayMinutes),
                  style: textTheme.headlineMedium?.copyWith(color: white),
                ),
                Text(
                  'de focus',
                  style: textTheme.bodyMedium?.copyWith(
                    color: white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: white,
                  size: 24,
                ),
                Text(
                  '$streakDays j',
                  style: textTheme.titleMedium?.copyWith(color: white),
                ),
                Text(
                  'streak',
                  style: textTheme.labelSmall?.copyWith(
                    color: white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue de la session en cours : se rafraîchit chaque seconde tant qu'elle
/// est affichée.
class _ActiveSessionView extends StatefulWidget {
  const _ActiveSessionView({
    super.key,
    required this.session,
    required this.onStop,
  });

  final FocusSession session;
  final VoidCallback onStop;

  @override
  State<_ActiveSessionView> createState() => _ActiveSessionViewState();
}

class _ActiveSessionViewState extends State<_ActiveSessionView> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final remaining = session.remainingAt(now);
    final total = session.plannedDurationMinutes * 60;
    final progress = total == 0 ? 0.0 : remaining.inSeconds / total;
    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final clock = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
    final elapsedMinutes = now.difference(session.startTime).inMinutes;
    final quote = focusQuotes[elapsedMinutes % focusQuotes.length];
    const white = Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: session.strictMode
            ? AppColors.strictGradient
            : AppColors.heroGradient,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Session en cours',
                    style: textTheme.titleMedium?.copyWith(color: white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fin à ${formatClock(session.plannedEnd)} · '
                    '${session.blockedPackages.length} app(s) bloquée(s)',
                    style: textTheme.bodyMedium?.copyWith(
                      color: white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FocusRing(
                    progress: progress,
                    size: 260,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          session.strictMode
                              ? Icons.lock_rounded
                              : Icons.shield_rounded,
                          color: white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          clock,
                          style: textTheme.displayMedium?.copyWith(
                            color: white,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'restantes',
                          style: textTheme.bodyMedium?.copyWith(
                            color: white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      '« $quote »',
                      key: ValueKey(quote),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: white,
                      side: BorderSide(color: white.withValues(alpha: 0.6)),
                    ),
                    onPressed: widget.onStop,
                    icon: Icon(
                      session.strictMode
                          ? Icons.calculate_rounded
                          : Icons.stop_rounded,
                    ),
                    label: Text(
                      session.strictMode
                          ? 'Résoudre un problème pour arrêter'
                          : 'Arrêter la session',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionSummarySheet extends StatelessWidget {
  const _SessionSummarySheet({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final completed = session.durationMinutes >= session.plannedDurationMinutes;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed ? Icons.celebration_rounded : Icons.thumb_up_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              completed ? 'Session terminée, bravo !' : 'Session arrêtée',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SummaryStat(
                  value: formatDuration(session.durationMinutes),
                  label: 'de focus',
                ),
                _SummaryStat(
                  value: '${session.mathGatesSolved}',
                  label: 'Math Gates',
                ),
                _SummaryStat(value: '+${xpForSession(session)}', label: 'XP'),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Super'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: textTheme.titleLarge),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

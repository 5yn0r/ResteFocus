import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/xp.dart';
import '../../onboarding/providers/user_provider.dart';
import '../../review/providers/missed_problems_provider.dart';
import '../../review/screens/review_screen.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final xp = ref.watch(userProfileProvider).value?.xpPoints ?? 0;
    final missedCount = ref.watch(missedProblemsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tes progrès')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _LevelCard(level: XpLevel.fromXp(xp), xp: xp),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _StatCard(
                  icon: Icons.timer_rounded,
                  color: AppColors.primary,
                  label: 'Focus total',
                  value: formatDuration(stats.totalFocusMinutes),
                ),
                _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.streak,
                  label: 'Streak',
                  value:
                      '${stats.streakDays} jour${stats.streakDays > 1 ? 's' : ''}',
                ),
                _StatCard(
                  icon: Icons.calculate_rounded,
                  color: AppColors.secondary,
                  label: 'Math Gates résolus',
                  value: '${stats.mathGatesSolved}',
                ),
                _StatCard(
                  icon: Icons.track_changes_rounded,
                  color: Colors.pinkAccent,
                  label: 'Taux de réussite',
                  value: stats.mathGatesSolved + stats.mathGatesFailed == 0
                      ? '—'
                      : '${(stats.successRate * 100).round()} %',
                ),
              ],
            ),
            if (missedCount > 0) ...[
              const SizedBox(height: 16),
              _ReviewBanner(count: missedCount),
            ],
            const SizedBox(height: 24),
            Text(
              '7 derniers jours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: stats.sessionCount == 0
                    ? const _EmptyChart()
                    : _WeekChart(days: stats.last7Days),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.xp});

  final XpLevel level;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau ${level.level}',
                      style: textTheme.headlineSmall?.copyWith(color: white),
                    ),
                    Text(
                      level.title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$xp XP',
                style: textTheme.titleLarge?.copyWith(color: white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 8,
              color: white,
              backgroundColor: white.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${level.xpForNextLevel - level.xpIntoLevel} XP avant le niveau ${level.level + 1}',
            style: textTheme.bodySmall?.copyWith(
              color: white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReviewScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.replay_rounded, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count problème${count > 1 ? 's' : ''} à réviser',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: textTheme.titleLarge),
                ),
                Text(label, style: textTheme.bodySmall, maxLines: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<DayFocus> days;

  static const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMinutes = days.fold<int>(
      1,
      (max, d) => d.minutes > max ? d.minutes : max,
    );

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: (maxMinutes * 1.2).clamp(10, double.infinity),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                formatDuration(rod.toY.round()),
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  final isToday = index == days.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[days[index].day.weekday - 1],
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                        color: isToday ? scheme.primary : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (final (i, day) in days.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: day.minutes.toDouble(),
                    width: 22,
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppColors.heroGradient,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (maxMinutes * 1.2).clamp(10, double.infinity),
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              'Termine ta première session pour voir tes progrès ici.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

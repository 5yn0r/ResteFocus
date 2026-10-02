import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../apps/screens/app_selection_screen.dart';
import '../../permissions/widgets/permissions_card.dart';
import '../../review/providers/missed_problems_provider.dart';
import '../../session/providers/session_provider.dart';
import '../../session/screens/session_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../stats/providers/stats_provider.dart';
import '../../stats/screens/stats_screen.dart';
import '../providers/home_tab_provider.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    SessionScreen(),
    AppSelectionScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    ref.listen(homeTabProvider, (previous, next) {
      if (next == HomeTab.stats) {
        ref.read(missedProblemsProvider.notifier).refresh();
      }
    });
    // Seul endroit qui connaît déjà le streak côté Dart (computeStats) : on
    // le pousse vers SessionPrefs pour que le widget écran d'accueil (natif,
    // sans accès aux providers Flutter) puisse l'afficher.
    ref.listen(statsProvider, (previous, next) {
      final days = next.value?.streakDays;
      if (days != null && days != previous?.value?.streakDays) {
        ref.read(accessibilityBridgeProvider).setWidgetStreak(days);
      }
    });

    return PermissionsRefresher(
      child: Scaffold(
        body: IndexedStack(index: tab.index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (i) =>
              ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded),
              label: 'Focus',
            ),
            NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps_rounded),
              label: 'Apps',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progrès',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

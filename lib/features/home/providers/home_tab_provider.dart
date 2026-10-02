import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { focus, apps, stats, settings }

/// Onglet affiché par HomeShell ; permet aux écrans de naviguer entre
/// onglets (ex : "Modifier" les apps depuis l'écran Focus).
class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.focus;

  void select(HomeTab tab) => state = tab;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

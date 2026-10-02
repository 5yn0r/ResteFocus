import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/home/screens/home_shell.dart';
import 'features/onboarding/providers/user_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: ResteFocusApp()));
}

class ResteFocusApp extends StatelessWidget {
  const ResteFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResteFocus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      child: profileAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Erreur de chargement du profil : $e')),
        ),
        data: (profile) => profile == null
            ? const OnboardingScreen(key: ValueKey('onboarding'))
            : const HomeShell(key: ValueKey('home')),
      ),
    );
  }
}

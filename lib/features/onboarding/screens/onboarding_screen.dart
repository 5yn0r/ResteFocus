import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../data/models/user_profile.dart';
import '../../permissions/widgets/permissions_card.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_fields.dart';

/// Onboarding en 4 étapes : bienvenue → profil → matières → permissions.
/// _RootGate (main.dart) bascule sur HomeShell dès que le profil est créé.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 4;

  final _pageController = PageController();
  final _nameController = TextEditingController();
  SchoolLevel _level = SchoolLevel.licence;
  final Set<Subject> _subjects = {Subject.maths};
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    1 => _nameController.text.trim().isNotEmpty,
    2 => _subjects.isNotEmpty,
    _ => true,
  };

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_step < _stepCount - 1) {
      _goTo(_step + 1);
      return;
    }
    await ref
        .read(userProfileProvider.notifier)
        .save(
          UserProfile(
            displayName: _nameController.text.trim(),
            level: _level,
            subjects: _subjects.toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionsRefresher(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _step == 0 ? null : () => _goTo(_step - 1),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: _step == 0 ? Colors.transparent : null,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (_step + 1) / _stepCount),
                          duration: const Duration(milliseconds: 350),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const _WelcomeStep(),
                    _ProfileStep(
                      nameController: _nameController,
                      level: _level,
                      onNameChanged: () => setState(() {}),
                      onLevelChanged: (l) => setState(() => _level = l),
                    ),
                    _SubjectsStep(
                      selected: _subjects,
                      onToggle: (s) => setState(() {
                        if (!_subjects.remove(s)) _subjects.add(s);
                      }),
                    ),
                    const _PermissionsStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: FilledButton(
                  onPressed: _canContinue ? _next : null,
                  child: Text(switch (_step) {
                    0 => 'C\'est parti',
                    3 => 'Terminer',
                    _ => 'Continuer',
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ...children,
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        FadeSlideIn(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Bienvenue sur ResteFocus',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Text(
            'Reste concentré. Débloque ton potentiel.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 36),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: const _Feature(
            icon: Icons.shield_rounded,
            title: 'Bloque tes distractions',
            text: 'TikTok, Instagram, YouTube… verrouillés pendant tes sessions.',
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 350),
          child: const _Feature(
            icon: Icons.calculate_rounded,
            title: 'Le Math Gate',
            text: 'Pour ouvrir une app bloquée, résous d\'abord un problème.',
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 450),
          child: const _Feature(
            icon: Icons.local_fire_department_rounded,
            title: 'Progresse chaque jour',
            text: 'Streak, XP et statistiques pour rester motivé.',
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.nameController,
    required this.level,
    required this.onNameChanged,
    required this.onLevelChanged,
  });

  final TextEditingController nameController;
  final SchoolLevel level;
  final VoidCallback onNameChanged;
  final ValueChanged<SchoolLevel> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Faisons connaissance',
      subtitle: 'Ton niveau sert à calibrer la difficulté des problèmes.',
      children: [
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ton prénom',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onChanged: (_) => onNameChanged(),
        ),
        const SizedBox(height: 28),
        Text('Ton niveau', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        LevelPicker(selected: level, onChanged: onLevelChanged),
      ],
    );
  }
}

class _SubjectsStep extends StatelessWidget {
  const _SubjectsStep({required this.selected, required this.onToggle});

  final Set<Subject> selected;
  final ValueChanged<Subject> onToggle;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Tes matières',
      subtitle:
          'Les problèmes du Math Gate seront tirés de ces matières. Choisis-en au moins une.',
      children: [SubjectGrid(selected: selected, onToggle: onToggle)],
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep();

  @override
  Widget build(BuildContext context) {
    return const _StepScaffold(
      title: 'Dernière étape',
      subtitle:
          'Pour bloquer tes apps, ResteFocus a besoin de deux autorisations Android. '
          'Tu pourras aussi les activer plus tard depuis ton profil.',
      children: [PermissionsCard(), SizedBox(height: 16), _PrivacyNote()],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'ResteFocus ne lit que le nom de l\'app ouverte. Rien ne quitte ton téléphone.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

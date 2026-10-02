import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/xp.dart';
import '../../../data/models/user_profile.dart';
import '../../onboarding/providers/user_provider.dart';
import '../../onboarding/widgets/profile_fields.dart';
import '../../permissions/widgets/permissions_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (profile != null) _ProfileCard(profile: profile),
          const SizedBox(height: 28),
          Text('Permissions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Indispensables pour que le blocage fonctionne.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const PermissionsCard(),
          const SizedBox(height: 28),
          Text('À propos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lightbulb_outline_rounded),
                  title: Text('Le principe'),
                  subtitle: Text(
                    'Chaque tentative de distraction devient un moment '
                    'd\'apprentissage : pour ouvrir une app bloquée, résous '
                    'd\'abord un problème.',
                  ),
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Tes données restent sur ton téléphone'),
                  subtitle: Text('Aucune donnée n\'est envoyée à des tiers.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = XpLevel.fromXp(profile.xpPoints);
    final initial = profile.displayName.isEmpty
        ? '?'
        : profile.displayName[0].toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        '${profile.level.label} · Niveau ${level.level} (${level.title})',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Modifier',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _EditProfileSheet(profile: profile),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final subject in profile.subjects)
                  Chip(
                    label: Text('${subject.emoji} ${subject.label}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  late SchoolLevel _level = widget.profile.level;
  late final Set<Subject> _subjects = widget.profile.subjects.toSet();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _nameController.text.trim().isNotEmpty && _subjects.isNotEmpty;

  Future<void> _save() async {
    await ref
        .read(userProfileProvider.notifier)
        .save(
          widget.profile.copyWith(
            displayName: _nameController.text.trim(),
            level: _level,
            subjects: _subjects.toList(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Modifier le profil', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Prénom'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text('Niveau', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              LevelPicker(
                selected: _level,
                onChanged: (l) => setState(() => _level = l),
              ),
              const SizedBox(height: 20),
              Text('Matières', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SubjectGrid(
                selected: _subjects,
                onToggle: (s) => setState(() {
                  if (!_subjects.remove(s)) _subjects.add(s);
                }),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _valid ? _save : null,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

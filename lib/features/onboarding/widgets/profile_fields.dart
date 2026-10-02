import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Choix du niveau scolaire, partagé avec l'édition du profil.
class LevelPicker extends StatelessWidget {
  const LevelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SchoolLevel selected;
  final ValueChanged<SchoolLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final level in SchoolLevel.values)
          ChoiceChip(
            label: Text(level.label),
            selected: selected == level,
            onSelected: (_) => onChanged(level),
          ),
      ],
    );
  }
}

/// Grille de sélection des matières, partagée avec l'édition du profil.
class SubjectGrid extends StatelessWidget {
  const SubjectGrid({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<Subject> selected;
  final ValueChanged<Subject> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final subject in Subject.values)
          Builder(
            builder: (context) {
              final isSelected = selected.contains(subject);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onToggle(subject),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            subject.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subject.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

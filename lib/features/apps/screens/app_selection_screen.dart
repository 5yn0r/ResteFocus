import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../core/constants.dart';
import '../../../data/models/blocked_app.dart';
import '../../session/providers/session_provider.dart';
import '../providers/blocked_apps_provider.dart';

enum _Filter { all, suggested, selected }

/// Catégories proposées d'office au blocage. La messagerie en est exclue :
/// on ne coupe pas les communications de l'utilisateur sans qu'il le décide.
const _suggestedCategories = {'Réseaux sociaux', 'Vidéo', 'Jeux'};

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  List<AppInfo> _apps = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isSuggested(AppInfo app) =>
      _suggestedCategories.contains(categoryOf(app.packageName));

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedAppsProvider).value ?? [];
    final blockedPackages = blocked.map((b) => b.packageName).toSet();
    final sessionActive = ref.watch(sessionProvider).value?.isActive ?? false;

    final query = _search.toLowerCase();
    final visible = _apps.where((a) {
      if (!a.name.toLowerCase().contains(query)) return false;
      return switch (_filter) {
        _Filter.all => true,
        _Filter.suggested => _isSuggested(a),
        _Filter.selected => blockedPackages.contains(a.packageName),
      };
    }).toList();
    final unblockedSuggestions = _apps
        .where(
          (a) => _isSuggested(a) && !blockedPackages.contains(a.packageName),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Apps à bloquer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Rechercher une app…',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (filter, label) in [
                  (_Filter.all, 'Toutes'),
                  (_Filter.suggested, 'Distractions'),
                  (_Filter.selected, 'Bloquées (${blocked.length})'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          if (sessionActive)
            const _InfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Session en cours : tes changements s\'appliqueront à la prochaine.',
            ),
          if (!_loading && unblockedSuggestions.isNotEmpty)
            _SuggestionBanner(
              count: unblockedSuggestions.length,
              onBlockAll: () => ref
                  .read(blockedAppsProvider.notifier)
                  .blockAll(
                    unblockedSuggestions.map(
                      (a) => BlockedApp(
                        packageName: a.packageName,
                        appName: a.name,
                      ),
                    ),
                  ),
            ),
          Expanded(child: _buildList(visible, blockedPackages)),
        ],
      ),
    );
  }

  Widget _buildList(List<AppInfo> visible, Set<String> blockedPackages) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        text: 'Impossible de lister les apps installées.\n$_error',
        action: TextButton(
          onPressed: _loadApps,
          child: const Text('Réessayer'),
        ),
      );
    }
    if (visible.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        text: switch (_filter) {
          _Filter.selected => 'Aucune app bloquée pour l\'instant.',
          _Filter.suggested => 'Aucune distraction connue installée. Bravo !',
          _Filter.all => 'Aucune app ne correspond à ta recherche.',
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final app = visible[index];
        final isBlocked = blockedPackages.contains(app.packageName);
        final category = categoryOf(app.packageName);
        final scheme = Theme.of(context).colorScheme;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isBlocked
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            value: isBlocked,
            secondary: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: app.icon != null
                  ? Image.memory(
                      app.icon!,
                      width: 40,
                      height: 40,
                      gaplessPlayback: true,
                    )
                  : const SizedBox.square(
                      dimension: 40,
                      child: Icon(Icons.android_rounded),
                    ),
            ),
            title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: category != null ? Text(category) : null,
            onChanged: (_) => ref
                .read(blockedAppsProvider.notifier)
                .toggle(
                  BlockedApp(packageName: app.packageName, appName: app.name),
                ),
          ),
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({required this.count, required this.onBlockAll});

  final int count;
  final VoidCallback onBlockAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count distraction${count > 1 ? 's' : ''} détectée${count > 1 ? 's' : ''}',
              style: TextStyle(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onBlockAll, child: const Text('Tout bloquer')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    );
  }
}

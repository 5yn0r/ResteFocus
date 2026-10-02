import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/providers/session_provider.dart';
import '../providers/permissions_provider.dart';

/// Relit l'état des permissions chaque fois que l'app revient au premier
/// plan (l'utilisateur les accorde dans les réglages Android).
class PermissionsRefresher extends ConsumerStatefulWidget {
  const PermissionsRefresher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PermissionsRefresher> createState() =>
      _PermissionsRefresherState();
}

class _PermissionsRefresherState extends ConsumerState<PermissionsRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Liste des permissions avec leur état et un bouton pour les accorder.
class PermissionsCard extends ConsumerWidget {
  const PermissionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(permissionsProvider).value;
    final bridge = ref.read(accessibilityBridgeProvider);

    return Card(
      child: Column(
        children: [
          _PermissionTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibilité',
            subtitle: 'Détecte l\'ouverture d\'une app bloquée.',
            granted: status?.accessibility ?? false,
            onGrant: bridge.openAccessibilitySettings,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PermissionTile(
            icon: Icons.layers_rounded,
            title: 'Superposition',
            subtitle: 'Affiche le Math Gate devant l\'app bloquée.',
            granted: status?.overlay ?? false,
            onGrant: bridge.requestOverlayPermission,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: granted
            ? Colors.green.withValues(alpha: 0.15)
            : scheme.errorContainer,
        foregroundColor: granted ? Colors.green : scheme.onErrorContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: granted
          ? const Icon(Icons.check_circle_rounded, color: Colors.green)
          : FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: onGrant,
              child: const Text('Activer'),
            ),
    );
  }
}

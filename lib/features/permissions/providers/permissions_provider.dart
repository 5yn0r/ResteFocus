import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/providers/session_provider.dart';

class PermissionsStatus {
  const PermissionsStatus({required this.accessibility, required this.overlay});

  /// Service d'accessibilité : détecte l'ouverture des apps bloquées.
  final bool accessibility;

  /// Affichage par-dessus les autres apps : nécessaire au Math Gate.
  final bool overlay;

  bool get allGranted => accessibility && overlay;
}

/// État des permissions Android. Relu via [PermissionsNotifier.refresh]
/// quand l'utilisateur revient des réglages (voir PermissionsRefresher).
class PermissionsNotifier extends AsyncNotifier<PermissionsStatus> {
  @override
  Future<PermissionsStatus> build() => _read();

  Future<PermissionsStatus> _read() async {
    final bridge = ref.read(accessibilityBridgeProvider);
    try {
      return PermissionsStatus(
        accessibility: await bridge.isAccessibilityServiceEnabled(),
        overlay: await bridge.hasOverlayPermission(),
      );
    } catch (_) {
      // Plateforme sans code natif (tests, desktop) : rien n'est accordé.
      return const PermissionsStatus(accessibility: false, overlay: false);
    }
  }

  Future<void> refresh() async {
    state = AsyncData(await _read());
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, PermissionsStatus>(
      PermissionsNotifier.new,
    );

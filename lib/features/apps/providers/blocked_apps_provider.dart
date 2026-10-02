import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/blocked_app.dart';
import '../../../data/repositories/blocked_apps_repository.dart';

final blockedAppsRepositoryProvider = Provider(
  (ref) => BlockedAppsRepository(),
);

class BlockedAppsNotifier extends AsyncNotifier<List<BlockedApp>> {
  @override
  Future<List<BlockedApp>> build() async {
    return ref.read(blockedAppsRepositoryProvider).load();
  }

  Future<void> toggle(BlockedApp app) async {
    final current = List<BlockedApp>.from(state.value ?? []);
    final index = current.indexWhere((a) => a.packageName == app.packageName);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(app);
    }
    await _save(current);
  }

  /// Ajoute toutes les apps données qui ne sont pas déjà bloquées.
  Future<void> blockAll(Iterable<BlockedApp> apps) async {
    final current = List<BlockedApp>.from(state.value ?? []);
    final known = current.map((a) => a.packageName).toSet();
    current.addAll(apps.where((a) => known.add(a.packageName)));
    await _save(current);
  }

  Future<void> _save(List<BlockedApp> apps) async {
    await ref.read(blockedAppsRepositoryProvider).save(apps);
    state = AsyncData(apps);
  }
}

final blockedAppsProvider =
    AsyncNotifierProvider<BlockedAppsNotifier, List<BlockedApp>>(
      BlockedAppsNotifier.new,
    );

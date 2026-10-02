import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return ref.read(userRepositoryProvider).load();
  }

  Future<void> save(UserProfile profile) async {
    await ref.read(userRepositoryProvider).save(profile);
    state = AsyncData(profile);
  }

  Future<void> addXp(int xp) async {
    // Peut être appelé avant la fin du chargement initial du profil.
    final current = await future;
    if (current == null || xp <= 0) return;
    await save(current.copyWith(xpPoints: current.xpPoints + xp));
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
      UserProfileNotifier.new,
    );

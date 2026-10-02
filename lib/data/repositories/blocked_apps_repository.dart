import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/blocked_app.dart';

class BlockedAppsRepository {
  static const _key = 'blocked_apps';

  Future<List<BlockedApp>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BlockedApp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<BlockedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(apps.map((a) => a.toJson()).toList()),
    );
  }
}

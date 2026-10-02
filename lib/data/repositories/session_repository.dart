import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_session.dart';

class SessionRepository {
  static const _historyKey = 'session_history';
  static const _activeKey = 'active_session';

  Future<List<FocusSession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveHistory(List<FocusSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> archiveSession(FocusSession session) async {
    final history = await loadHistory();
    history.add(session);
    await _saveHistory(history);
    await clearActive();
  }

  Future<FocusSession?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    return FocusSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveActive(FocusSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, jsonEncode(session.toJson()));
  }

  Future<void> clearActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
  }
}

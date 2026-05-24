import 'package:hive_flutter/hive_flutter.dart';
import 'models/settings_model.dart';
import 'models/lunch_log_model.dart';

class HiveHelper {
  static const String _settingsBoxName = 'settings_box';
  static const String _lunchLogsBoxName = 'lunch_logs_box';
  static const String _settingsKey = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_lunchLogsBoxName);
  }

  static Box get _settingsBox => Hive.box(_settingsBoxName);
  static Box get _lunchLogsBox => Hive.box(_lunchLogsBoxName);

  // Settings operations
  static AppSettings getSettings() {
    final rawSettings = _settingsBox.get(_settingsKey);
    if (rawSettings == null) {
      return AppSettings.defaultSettings();
    }
    try {
      final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(rawSettings as Map);
      return AppSettings.fromMap(map);
    } catch (_) {
      return AppSettings.defaultSettings();
    }
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, settings.toMap());
  }

  // LunchLog operations
  static Future<void> saveLunchLog(LunchLog log) async {
    await _lunchLogsBox.put(log.storageKey, log.toMap());
  }

  static Future<void> deleteLunchLog(String storageKey) async {
    await _lunchLogsBox.delete(storageKey);
  }

  static List<LunchLog> getAllLunchLogs() {
    final logs = <LunchLog>[];
    for (final key in _lunchLogsBox.keys) {
      final rawLog = _lunchLogsBox.get(key);
      if (rawLog != null) {
        try {
          final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(rawLog as Map);
          logs.add(LunchLog.fromMap(map));
        } catch (_) {
          // Skip malformed records
        }
      }
    }
    // Sort chronological: oldest first
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  static Future<void> importLunchLogs(List<LunchLog> newLogs) async {
    final entries = <String, Map<String, dynamic>>{};
    for (final log in newLogs) {
      entries[log.storageKey] = log.toMap();
    }
    if (entries.isNotEmpty) {
      await _lunchLogsBox.putAll(entries);
    }
  }

  static Future<void> clearAll() async {
    await _settingsBox.clear();
    await _lunchLogsBox.clear();
  }
}

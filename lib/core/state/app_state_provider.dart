import 'package:flutter/material.dart';
import '../storage/hive_helper.dart';
import '../storage/models/settings_model.dart';
import '../storage/models/lunch_log_model.dart';
import '../notifications/notification_helper.dart';

class AppStateProvider extends ChangeNotifier {
  late AppSettings _settings;
  List<LunchLog> _logs = [];

  AppSettings get settings => _settings;
  List<LunchLog> get logs => _logs;

  AppStateProvider() {
    _loadState();
  }

  void _loadState() {
    _settings = HiveHelper.getSettings();
    _logs = HiveHelper.getAllLunchLogs();
    notifyListeners();
  }

  // Update app settings, persist, and reschedule notifications
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await HiveHelper.saveSettings(newSettings);
    
    // Reschedule notifications based on new active days and time
    if (_settings.isOnboarded) {
      await NotificationHelper.scheduleNotifications(
        activeDays: _settings.activeDays,
        hour: _settings.notificationHour,
        minute: _settings.notificationMinute,
      );
    }
    
    notifyListeners();
  }

  // Log daily lunch spend. Date gets normalized to midnight to avoid duplicates
  Future<void> logSpend({
    required DateTime date,
    required double actualSpend,
    required bool wasBrought,
  }) async {
    // Normalize date to date-only (midnight)
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final log = LunchLog(
      date: dateOnly,
      actualSpend: wasBrought ? 0.00 : actualSpend,
      targetSpend: _settings.targetSpend, // Capture target spend at time of entry
      wasBrought: wasBrought || actualSpend == 0.00,
    );

    await HiveHelper.saveLunchLog(log);
    _logs = HiveHelper.getAllLunchLogs();
    notifyListeners();
  }

  // Delete a specific lunch log
  Future<void> deleteLog(String storageKey) async {
    await HiveHelper.deleteLunchLog(storageKey);
    _logs = HiveHelper.getAllLunchLogs();
    notifyListeners();
  }

  // Import JSON list of logs, merge/overwrite, and refresh state
  Future<void> importLogs(List<LunchLog> importedLogs) async {
    await HiveHelper.importLunchLogs(importedLogs);
    _logs = HiveHelper.getAllLunchLogs();
    notifyListeners();
  }

  // Clear entire database (useful for reset/testing)
  Future<void> clearDatabase() async {
    await HiveHelper.clearAll();
    _loadState();
  }

  // Reschedule current settings notifications (e.g. on permission grant)
  Future<void> rescheduleNotifications() async {
    if (_settings.isOnboarded) {
      await NotificationHelper.scheduleNotifications(
        activeDays: _settings.activeDays,
        hour: _settings.notificationHour,
        minute: _settings.notificationMinute,
      );
    }
  }

  // --- ANALYTICS & METRICS ---

  // This Week Metrics: Spent, Saved, Overspent
  // Sunday = 7, Monday = 1. "This Week" starts on Monday.
  Map<String, double> get thisWeekMetrics {
    final now = DateTime.now();
    // Monday of the current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    // Sunday of the current week (inclusive, up to end of day)
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    double totalSpent = 0.00;
    double totalSaved = 0.00;
    double totalOverspent = 0.00;

    for (final log in _logs) {
      if (log.date.isBefore(startOfWeek) || log.date.isAfter(endOfWeek.subtract(const Duration(milliseconds: 1)))) {
        continue;
      }
      totalSpent += log.actualSpend;

      if (log.actualSpend < log.targetSpend) {
        totalSaved += (log.targetSpend - log.actualSpend);
      } else if (log.actualSpend > log.targetSpend) {
        totalOverspent += (log.actualSpend - log.targetSpend);
      }
    }

    return {
      'spent': totalSpent,
      'saved': totalSaved,
      'overspent': totalOverspent,
    };
  }

  // Rolling 30-Day Average Comparison
  // "Average Bought: $X.XX vs. Average Brought: $Y.YY"
  Map<String, double> get rolling30DayAverages {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoffDate = today.subtract(const Duration(days: 30));

    double boughtSum = 0.00;
    int boughtCount = 0;

    double broughtSum = 0.00;
    int broughtCount = 0;

    for (final log in _logs) {
      if (log.date.isBefore(cutoffDate)) continue;

      if (log.wasBrought) {
        broughtSum += log.actualSpend;
        broughtCount++;
      } else {
        boughtSum += log.actualSpend;
        boughtCount++;
      }
    }

    return {
      'averageBought': boughtCount > 0 ? (boughtSum / boughtCount) : 0.00,
      'averageBrought': broughtCount > 0 ? (broughtSum / broughtCount) : 0.00,
    };
  }

  // Get logs grouped by Month (for Mid history list)
  // Returns: Map<String, List<LunchLog>> where key is "MMMM yyyy" (e.g. "May 2026")
  Map<String, List<LunchLog>> get logsByMonth {
    final grouped = <String, List<LunchLog>>{};
    // Iterate from newest to oldest for history display
    for (final log in _logs.reversed) {
      final monthKey = _formatMonthYear(log.date);
      grouped.putIfAbsent(monthKey, () => []).add(log);
    }
    return grouped;
  }

  String _formatMonthYear(DateTime date) {
    // Basic formatting: "May 2026"
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

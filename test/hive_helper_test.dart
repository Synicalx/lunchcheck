import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lunchcheck/core/storage/hive_helper.dart';
import 'package:lunchcheck/core/storage/models/settings_model.dart';
import 'package:lunchcheck/core/storage/models/lunch_log_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for Hive testing
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
    // Explicitly open boxes for the test as HiveHelper.init() uses Hive.initFlutter()
    await Hive.openBox('settings_box');
    await Hive.openBox('lunch_logs_box');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Default Settings', () {
    final settings = HiveHelper.getSettings();
    expect(settings.isOnboarded, isFalse);
    expect(settings.targetSpend, equals(10.0));
    expect(settings.activeDays, equals([1, 2, 3, 4, 5]));
    expect(settings.notificationHour, equals(12));
    expect(settings.notificationMinute, equals(30));
  });

  test('Save and Get Settings', () async {
    final settings = AppSettings(
      targetSpend: 15.50,
      activeDays: [1, 3, 5],
      notificationHour: 13,
      notificationMinute: 15,
      isOnboarded: true,
    );

    await HiveHelper.saveSettings(settings);

    final retrieved = HiveHelper.getSettings();
    expect(retrieved.isOnboarded, isTrue);
    expect(retrieved.targetSpend, equals(15.50));
    expect(retrieved.activeDays, equals([1, 3, 5]));
    expect(retrieved.notificationHour, equals(13));
    expect(retrieved.notificationMinute, equals(15));
  });

  test('Save and Get LunchLogs', () async {
    final now = DateTime(2026, 5, 24, 12, 0);
    final log = LunchLog(
      date: now,
      actualSpend: 8.50,
      targetSpend: 12.00,
      wasBrought: false,
    );

    await HiveHelper.saveLunchLog(log);

    final allLogs = HiveHelper.getAllLunchLogs();
    expect(allLogs.length, equals(1));
    expect(allLogs.first.storageKey, equals('2026-05-24'));
    expect(allLogs.first.actualSpend, equals(8.50));
    expect(allLogs.first.targetSpend, equals(12.00));
    expect(allLogs.first.wasBrought, isFalse);
  });

  test('Overwrite LunchLog on same date conflict', () async {
    final date = DateTime(2026, 5, 24, 12, 0);
    final log1 = LunchLog(
      date: date,
      actualSpend: 8.50,
      targetSpend: 12.00,
      wasBrought: false,
    );
    final log2 = LunchLog(
      date: date.add(const Duration(hours: 2)), // Same day, different time
      actualSpend: 0.00,
      targetSpend: 12.00,
      wasBrought: true,
    );

    await HiveHelper.saveLunchLog(log1);
    await HiveHelper.saveLunchLog(log2);

    final allLogs = HiveHelper.getAllLunchLogs();
    expect(allLogs.length, equals(1)); // Should overwrite, only 1 entry for 2026-05-24
    expect(allLogs.first.actualSpend, equals(0.00));
    expect(allLogs.first.wasBrought, isTrue);
  });

  test('Import and Clear LunchLogs', () async {
    final log1 = LunchLog(
      date: DateTime(2026, 5, 22),
      actualSpend: 5.0,
      targetSpend: 10.0,
      wasBrought: false,
    );
    final log2 = LunchLog(
      date: DateTime(2026, 5, 23),
      actualSpend: 0.0,
      targetSpend: 10.0,
      wasBrought: true,
    );

    await HiveHelper.importLunchLogs([log1, log2]);

    var allLogs = HiveHelper.getAllLunchLogs();
    expect(allLogs.length, equals(2));

    await HiveHelper.clearAll();
    allLogs = HiveHelper.getAllLunchLogs();
    expect(allLogs.length, equals(0));
  });
}

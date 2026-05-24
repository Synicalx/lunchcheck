import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lunchcheck/core/storage/models/settings_model.dart';
import 'package:lunchcheck/core/state/app_state_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    // Mock flutter_local_notifications method channels
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    const timezoneChannel = MethodChannel('flutter_timezone');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getLocalTimezone') {
        return 'America/New_York';
      }
      return null;
    });

    // Initialize timezones for local notification scheduling tests
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    tempDir = await Directory.systemTemp.createTemp('provider_test_dir');
    Hive.init(tempDir.path);
    await Hive.openBox('settings_box');
    await Hive.openBox('lunch_logs_box');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('AppStateProvider initialized with defaults', () {
    final provider = AppStateProvider();
    expect(provider.settings.isOnboarded, isFalse);
    expect(provider.logs.length, equals(0));
  });

  test('AppStateProvider logSpend and Week Metrics', () async {
    final provider = AppStateProvider();
    
    // Set targetSpend to $10.00
    await provider.updateSettings(AppSettings(
      targetSpend: 10.00,
      activeDays: [1, 2, 3, 4, 5],
      notificationHour: 12,
      notificationMinute: 30,
      isOnboarded: true,
    ));

    // Get current Monday to log days this week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    // Log $12.00 spend on Monday (Overspent by $2.00)
    await provider.logSpend(
      date: monday,
      actualSpend: 12.00,
      wasBrought: false,
    );

    // Log $7.00 spend on Tuesday (Saved $3.00)
    await provider.logSpend(
      date: monday.add(const Duration(days: 1)),
      actualSpend: 7.00,
      wasBrought: false,
    );

    // Log Brought Lunch ($0) on Wednesday (Saved $10.00)
    await provider.logSpend(
      date: monday.add(const Duration(days: 2)),
      actualSpend: 0.00,
      wasBrought: true,
    );

    expect(provider.logs.length, equals(3));

    final weekMetrics = provider.thisWeekMetrics;
    expect(weekMetrics['spent'], equals(19.00)); // 12 + 7 + 0
    expect(weekMetrics['saved'], equals(13.00)); // (10-7) on Tue + (10-0) on Wed
    expect(weekMetrics['overspent'], equals(2.00)); // (12-10) on Mon
  });

  test('AppStateProvider Rolling 30-Day Averages', () async {
    final provider = AppStateProvider();
    await provider.updateSettings(AppSettings(
      targetSpend: 10.00,
      activeDays: [1, 2, 3, 4, 5],
      notificationHour: 12,
      notificationMinute: 30,
      isOnboarded: true,
    ));

    final today = DateTime.now();

    // Log a Bought lunch of $15.00
    await provider.logSpend(
      date: today,
      actualSpend: 15.00,
      wasBrought: false,
    );

    // Log a Bought lunch of $5.00
    await provider.logSpend(
      date: today.subtract(const Duration(days: 2)),
      actualSpend: 5.00,
      wasBrought: false,
    );

    // Log a Brought lunch of $0
    await provider.logSpend(
      date: today.subtract(const Duration(days: 4)),
      actualSpend: 0.00,
      wasBrought: true,
    );

    // Log an old entry outside 30-day window (32 days ago)
    await provider.logSpend(
      date: today.subtract(const Duration(days: 32)),
      actualSpend: 20.00,
      wasBrought: false,
    );

    final averages = provider.rolling30DayAverages;
    expect(averages['averageBought'], equals(10.00)); // (15 + 5) / 2
    expect(averages['averageBrought'], equals(0.00)); // 0 / 1
  });
}

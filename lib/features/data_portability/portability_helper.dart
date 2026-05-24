import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/hive_helper.dart';
import '../../core/storage/models/lunch_log_model.dart';

class PortabilityHelper {
  // Export all database records to a JSON file and trigger share sheet
  static Future<void> exportData() async {
    try {
      final logs = HiveHelper.getAllLunchLogs();
      final jsonList = logs.map((log) => log.toMap()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'lunchcheck_export_$dateStr.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Trigger share sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LunchCheck Data Export',
      );
      
      debugPrint('Exported ${logs.length} logs successfully to ${file.path}');
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  // Import JSON file, validate schema, merge into local DB, and return logs list
  static Future<List<LunchLog>?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled
        return null;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException('Import failed: JSON must be a list of records.');
      }

      final List<LunchLog> importedLogs = [];
      for (final item in decoded) {
        if (item is! Map) {
          throw const FormatException('Import failed: Item in JSON list is not a valid object.');
        }

        // Schema validation
        if (!item.containsKey('date') ||
            !item.containsKey('actualSpend') ||
            !item.containsKey('targetSpend') ||
            !item.containsKey('wasBrought')) {
          throw const FormatException('Import failed: Missing required fields in JSON schema.');
        }

        try {
          final log = LunchLog.fromMap(Map<String, dynamic>.from(item));
          importedLogs.add(log);
        } catch (e) {
          throw FormatException('Import failed: Malformed record format - $e');
        }
      }

      return importedLogs;
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }
}

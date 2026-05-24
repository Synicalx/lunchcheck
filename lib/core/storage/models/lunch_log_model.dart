import 'package:intl/intl.dart';

class LunchLog {
  final DateTime date;
  final double actualSpend;
  final double targetSpend;
  final bool wasBrought;

  LunchLog({
    required this.date,
    required this.actualSpend,
    required this.targetSpend,
    required this.wasBrought,
  });

  // Unique key for storage per day
  String get storageKey => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'actualSpend': actualSpend,
      'targetSpend': targetSpend,
      'wasBrought': wasBrought,
    };
  }

  factory LunchLog.fromMap(Map<dynamic, dynamic> map) {
    return LunchLog(
      date: DateTime.parse(map['date'] as String),
      actualSpend: (map['actualSpend'] as num).toDouble(),
      targetSpend: (map['targetSpend'] as num).toDouble(),
      wasBrought: map['wasBrought'] as bool,
    );
  }

  LunchLog copyWith({
    DateTime? date,
    double? actualSpend,
    double? targetSpend,
    bool? wasBrought,
  }) {
    return LunchLog(
      date: date ?? this.date,
      actualSpend: actualSpend ?? this.actualSpend,
      targetSpend: targetSpend ?? this.targetSpend,
      wasBrought: wasBrought ?? this.wasBrought,
    );
  }
}

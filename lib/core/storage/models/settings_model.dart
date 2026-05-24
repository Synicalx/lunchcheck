class AppSettings {
  final double targetSpend;
  final List<int> activeDays; // 1 = Monday, 7 = Sunday
  final int notificationHour;
  final int notificationMinute;
  final bool isOnboarded;

  AppSettings({
    required this.targetSpend,
    required this.activeDays,
    required this.notificationHour,
    required this.notificationMinute,
    required this.isOnboarded,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      targetSpend: 10.00,
      activeDays: [1, 2, 3, 4, 5], // Mon to Fri
      notificationHour: 12,
      notificationMinute: 30,
      isOnboarded: false,
    );
  }

  AppSettings copyWith({
    double? targetSpend,
    List<int>? activeDays,
    int? notificationHour,
    int? notificationMinute,
    bool? isOnboarded,
  }) {
    return AppSettings(
      targetSpend: targetSpend ?? this.targetSpend,
      activeDays: activeDays ?? this.activeDays,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetSpend': targetSpend,
      'activeDays': activeDays,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
      'isOnboarded': isOnboarded,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      targetSpend: (map['targetSpend'] as num?)?.toDouble() ?? 10.00,
      activeDays: List<int>.from(map['activeDays'] ?? [1, 2, 3, 4, 5]),
      notificationHour: map['notificationHour'] as int? ?? 12,
      notificationMinute: map['notificationMinute'] as int? ?? 30,
      isOnboarded: map['isOnboarded'] as bool? ?? false,
    );
  }
}

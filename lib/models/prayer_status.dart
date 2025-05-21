class PrayerStatus {
  final String prayerName;
  final DateTime prayerTime;
  final bool isCompleted;
  final bool isMissed;
  final DateTime? completedAt;

  PrayerStatus({
    required this.prayerName,
    required this.prayerTime,
    this.isCompleted = false,
    this.isMissed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'prayerName': prayerName,
      'prayerTime': prayerTime.toIso8601String(),
      'isCompleted': isCompleted,
      'isMissed': isMissed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PrayerStatus.fromJson(Map<String, dynamic> json) {
    return PrayerStatus(
      prayerName: json['prayerName'] as String,
      prayerTime: DateTime.parse(json['prayerTime'] as String),
      isCompleted: json['isCompleted'] as bool,
      isMissed: json['isMissed'] as bool,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  PrayerStatus copyWith({
    String? prayerName,
    DateTime? prayerTime,
    bool? isCompleted,
    bool? isMissed,
    DateTime? completedAt,
  }) {
    return PrayerStatus(
      prayerName: prayerName ?? this.prayerName,
      prayerTime: prayerTime ?? this.prayerTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
} 
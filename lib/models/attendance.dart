/// Attendance data model for tracking employee clock in/out times
class Attendance {
  final String id;
  final String employeeId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final String? location;
  final bool isManualEntry;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.clockInTime,
    this.clockOutTime,
    this.location,
    required this.isManualEntry,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if attendance record is currently active (clocked in but not out)
  bool get isActive => clockOutTime == null;

  /// Calculate duration in hours (if clocked out)
  double? get durationInHours {
    if (clockOutTime == null) return null;
    return clockOutTime!.difference(clockInTime).inMinutes / 60.0;
  }

  /// Factory constructor to create Attendance from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      clockInTime: DateTime.parse(json['clockInTime'] as String),
      clockOutTime: json['clockOutTime'] != null
          ? DateTime.parse(json['clockOutTime'] as String)
          : null,
      location: json['location'] as String?,
      isManualEntry: json['isManualEntry'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Attendance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'clockInTime': clockInTime.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'location': location,
      'isManualEntry': isManualEntry,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Attendance with updated fields
  Attendance copyWith({
    String? id,
    String? employeeId,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? location,
    bool? isManualEntry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      location: location ?? this.location,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Attendance(id: $id, employeeId: $employeeId, clockInTime: $clockInTime, clockOutTime: $clockOutTime)';
  }
}
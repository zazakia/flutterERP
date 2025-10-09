/// Leave request data model
class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String reason;
  final String status; // pending, approved, rejected
  final String? approverId;
  final String? approverName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    this.approverId,
    this.approverName,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if leave request is pending approval
  bool get isPending => status == 'pending';

  /// Check if leave request is approved
  bool get isApproved => status == 'approved';

  /// Check if leave request is rejected
  bool get isRejected => status == 'rejected';

  /// Factory constructor to create LeaveRequest from JSON
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      leaveType: json['leaveType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      numberOfDays: json['numberOfDays'] as int,
      reason: json['reason'] as String,
      status: json['status'] as String,
      approverId: json['approverId'] as String?,
      approverName: json['approverName'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert LeaveRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfDays': numberOfDays,
      'reason': reason,
      'status': status,
      'approverId': approverId,
      'approverName': approverName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of LeaveRequest with updated fields
  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfDays,
    String? reason,
    String? status,
    String? approverId,
    String? approverName,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LeaveRequest(id: $id, employeeId: $employeeId, leaveType: $leaveType, status: $status)';
  }
}

/// Leave type enum
enum LeaveType {
  vacation('Vacation'),
  sick('Sick Leave'),
  personal('Personal Leave'),
  maternity('Maternity Leave'),
  paternity('Paternity Leave'),
  bereavement('Bereavement Leave');

  const LeaveType(this.displayName);
  final String displayName;

  static LeaveType fromString(String value) {
    return LeaveType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => LeaveType.vacation,
    );
  }
}
/// Payroll data model for employee compensation
class Payroll {
  final String id;
  final String employeeId;
  final String employeeName;
  final double grossPay;
  final double netPay;
  final double taxDeductions;
  final double otherDeductions;
  final double bonus;
  final double overtimePay;
  final double hourlyRate;
  final double hoursWorked;
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final DateTime payDate;
  final String status; // pending, processed, paid
  final String? payslipUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payroll({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.grossPay,
    required this.netPay,
    required this.taxDeductions,
    required this.otherDeductions,
    required this.bonus,
    required this.overtimePay,
    required this.hourlyRate,
    required this.hoursWorked,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.payDate,
    required this.status,
    this.payslipUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create Payroll from JSON
  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      grossPay: (json['grossPay'] as num).toDouble(),
      netPay: (json['netPay'] as num).toDouble(),
      taxDeductions: (json['taxDeductions'] as num).toDouble(),
      otherDeductions: (json['otherDeductions'] as num).toDouble(),
      bonus: (json['bonus'] as num).toDouble(),
      overtimePay: (json['overtimePay'] as num).toDouble(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      payPeriodStart: DateTime.parse(json['payPeriodStart'] as String),
      payPeriodEnd: DateTime.parse(json['payPeriodEnd'] as String),
      payDate: DateTime.parse(json['payDate'] as String),
      status: json['status'] as String,
      payslipUrl: json['payslipUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Payroll to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'grossPay': grossPay,
      'netPay': netPay,
      'taxDeductions': taxDeductions,
      'otherDeductions': otherDeductions,
      'bonus': bonus,
      'overtimePay': overtimePay,
      'hourlyRate': hourlyRate,
      'hoursWorked': hoursWorked,
      'payPeriodStart': payPeriodStart.toIso8601String(),
      'payPeriodEnd': payPeriodEnd.toIso8601String(),
      'payDate': payDate.toIso8601String(),
      'status': status,
      'payslipUrl': payslipUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Payroll with updated fields
  Payroll copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? grossPay,
    double? netPay,
    double? taxDeductions,
    double? otherDeductions,
    double? bonus,
    double? overtimePay,
    double? hourlyRate,
    double? hoursWorked,
    DateTime? payPeriodStart,
    DateTime? payPeriodEnd,
    DateTime? payDate,
    String? status,
    String? payslipUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payroll(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      grossPay: grossPay ?? this.grossPay,
      netPay: netPay ?? this.netPay,
      taxDeductions: taxDeductions ?? this.taxDeductions,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      bonus: bonus ?? this.bonus,
      overtimePay: overtimePay ?? this.overtimePay,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      payPeriodStart: payPeriodStart ?? this.payPeriodStart,
      payPeriodEnd: payPeriodEnd ?? this.payPeriodEnd,
      payDate: payDate ?? this.payDate,
      status: status ?? this.status,
      payslipUrl: payslipUrl ?? this.payslipUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payroll && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payroll(id: $id, employeeId: $employeeId, grossPay: $grossPay, netPay: $netPay, payDate: $payDate)';
  }
}
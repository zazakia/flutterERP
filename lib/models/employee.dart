/// Employee data model for the payroll system
class Employee {
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String employmentType;
  final double salaryRate;
  final String payType;
  final String taxId;
  final String? accountNumber;
  final String? routingNumber;
  final String? bankName;
  final bool status;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.employmentType,
    required this.salaryRate,
    required this.payType,
    required this.taxId,
    this.accountNumber,
    this.routingNumber,
    this.bankName,
    required this.status,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Full name getter
  String get fullName => '$firstName $lastName';

  /// Display name with role
  String get displayName => '$fullName ($role)';

  /// Factory constructor to create Employee from JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employeeId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      employmentType: json['employmentType'] as String,
      salaryRate: (json['salaryRate'] as num).toDouble(),
      payType: json['payType'] as String,
      taxId: json['taxId'] as String,
      accountNumber: json['accountNumber'] as String?,
      routingNumber: json['routingNumber'] as String?,
      bankName: json['bankName'] as String?,
      status: json['status'] as bool,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Employee to JSON
  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'employmentType': employmentType,
      'salaryRate': salaryRate,
      'payType': payType,
      'taxId': taxId,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'bankName': bankName,
      'status': status,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Employee with updated fields
  Employee copyWith({
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? employmentType,
    double? salaryRate,
    String? payType,
    String? taxId,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
    bool? status,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      employmentType: employmentType ?? this.employmentType,
      salaryRate: salaryRate ?? this.salaryRate,
      payType: payType ?? this.payType,
      taxId: taxId ?? this.taxId,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      bankName: bankName ?? this.bankName,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.employeeId == employeeId;
  }

  @override
  int get hashCode => employeeId.hashCode;

  @override
  String toString() {
    return 'Employee(employeeId: $employeeId, fullName: $fullName, email: $email, role: $role)';
  }
}

/// Employee role enum
enum EmployeeRole {
  admin('Admin'),
  payroll('Payroll'),
  hr('HR'),
  employee('Employee');

  const EmployeeRole(this.displayName);
  final String displayName;

  static EmployeeRole fromString(String value) {
    return EmployeeRole.values.firstWhere(
      (role) => role.name == value.toLowerCase(),
      orElse: () => EmployeeRole.employee,
    );
  }
}

/// Employment type enum
enum EmploymentType {
  fullTime('Full-time'),
  partTime('Part-time');

  const EmploymentType(this.displayName);
  final String displayName;

  static EmploymentType fromString(String value) {
    final lowerValue = value.toLowerCase();
    final cleanValue = lowerValue.replaceAll('-', '');
    
    return EmploymentType.values.firstWhere(
      (type) => type.name == cleanValue || type.name == lowerValue,
      orElse: () {
        // Handle special cases
        if (cleanValue == 'parttime') return EmploymentType.partTime;
        if (cleanValue == 'fulltime') return EmploymentType.fullTime;
        return EmploymentType.fullTime;
      },
    );
  }
}

/// Pay type enum
enum PayType {
  hourly('Hourly'),
  salary('Salary');

  const PayType(this.displayName);
  final String displayName;

  static PayType fromString(String value) {
    return PayType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => PayType.hourly,
    );
  }
}
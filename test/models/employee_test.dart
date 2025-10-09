import 'package:flutter_test/flutter_test.dart';
import 'package:item_manager/models/employee.dart';

void main() {
  group('Employee Model', () {
    final testEmployee = Employee(
      employeeId: 'EMP001',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      role: 'Employee',
      employmentType: 'Full-time',
      salaryRate: 25.0,
      payType: 'Hourly',
      taxId: '123-45-6789',
      accountNumber: '123456789',
      routingNumber: '021000021',
      bankName: 'Test Bank',
      status: true,
      avatar: null,
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );

    test('should create Employee with correct properties', () {
      expect(testEmployee.employeeId, 'EMP001');
      expect(testEmployee.firstName, 'John');
      expect(testEmployee.lastName, 'Doe');
      expect(testEmployee.fullName, 'John Doe');
      expect(testEmployee.email, 'john.doe@example.com');
      expect(testEmployee.role, 'Employee');
      expect(testEmployee.employmentType, 'Full-time');
      expect(testEmployee.salaryRate, 25.0);
      expect(testEmployee.payType, 'Hourly');
      expect(testEmployee.taxId, '123-45-6789');
      expect(testEmployee.accountNumber, '123456789');
      expect(testEmployee.routingNumber, '021000021');
      expect(testEmployee.bankName, 'Test Bank');
      expect(testEmployee.status, true);
      expect(testEmployee.avatar, null);
    });

    test('should serialize to JSON correctly', () {
      final json = testEmployee.toJson();

      expect(json['employeeId'], 'EMP001');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['role'], 'Employee');
      expect(json['employmentType'], 'Full-time');
      expect(json['salaryRate'], 25.0);
      expect(json['payType'], 'Hourly');
      expect(json['taxId'], '123-45-6789');
      expect(json['accountNumber'], '123456789');
      expect(json['routingNumber'], '021000021');
      expect(json['bankName'], 'Test Bank');
      expect(json['status'], true);
      expect(json['avatar'], null);
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2024-01-01T00:00:00.000Z');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'employeeId': 'EMP002',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'email': 'jane.smith@example.com',
        'role': 'Admin',
        'employmentType': 'Part-time',
        'salaryRate': 30.0,
        'payType': 'Salary',
        'taxId': '987-65-4321',
        'accountNumber': '987654321',
        'routingNumber': '021000022',
        'bankName': 'Another Bank',
        'status': false,
        'avatar': 'avatar_url',
        'createdAt': '2024-01-02T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      };

      final employee = Employee.fromJson(json);

      expect(employee.employeeId, 'EMP002');
      expect(employee.firstName, 'Jane');
      expect(employee.lastName, 'Smith');
      expect(employee.fullName, 'Jane Smith');
      expect(employee.email, 'jane.smith@example.com');
      expect(employee.role, 'Admin');
      expect(employee.employmentType, 'Part-time');
      expect(employee.salaryRate, 30.0);
      expect(employee.payType, 'Salary');
      expect(employee.taxId, '987-65-4321');
      expect(employee.accountNumber, '987654321');
      expect(employee.routingNumber, '021000022');
      expect(employee.bankName, 'Another Bank');
      expect(employee.status, false);
      expect(employee.avatar, 'avatar_url');
      expect(employee.createdAt, DateTime.parse('2024-01-02T00:00:00Z'));
      expect(employee.updatedAt, DateTime.parse('2024-01-02T00:00:00Z'));
    });

    test('should create copy with updated fields', () {
      final updatedEmployee = testEmployee.copyWith(
        firstName: 'Johnny',
        status: false,
        salaryRate: 30.0,
      );

      expect(updatedEmployee.employeeId, 'EMP001'); // Unchanged
      expect(updatedEmployee.firstName, 'Johnny'); // Changed
      expect(updatedEmployee.lastName, 'Doe'); // Unchanged
      expect(updatedEmployee.status, false); // Changed
      expect(updatedEmployee.salaryRate, 30.0); // Changed
    });

    test('should implement equality correctly', () {
      final employee1 = testEmployee;
      final employee2 = testEmployee.copyWith();
      final employee3 = testEmployee.copyWith(employeeId: 'EMP002');

      expect(employee1 == employee2, true);
      expect(employee1 == employee3, false);
    });

    test('should have correct hashCode', () {
      final employee1 = testEmployee;
      final employee2 = testEmployee.copyWith();
      final employee3 = testEmployee.copyWith(employeeId: 'EMP002');

      expect(employee1.hashCode == employee2.hashCode, true);
      expect(employee1.hashCode == employee3.hashCode, false);
    });

    test('should have correct toString', () {
      expect(
        testEmployee.toString(),
        'Employee(employeeId: EMP001, fullName: John Doe, email: john.doe@example.com, role: Employee)',
      );
    });
  });

  group('EmployeeRole Enum', () {
    test('should convert from string correctly', () {
      expect(EmployeeRole.fromString('admin'), EmployeeRole.admin);
      expect(EmployeeRole.fromString('Admin'), EmployeeRole.admin);
      expect(EmployeeRole.fromString('ADMIN'), EmployeeRole.admin);
      expect(EmployeeRole.fromString('payroll'), EmployeeRole.payroll);
      expect(EmployeeRole.fromString('hr'), EmployeeRole.hr);
      expect(EmployeeRole.fromString('employee'), EmployeeRole.employee);
      expect(EmployeeRole.fromString('unknown'), EmployeeRole.employee); // Default
    });

    test('should have correct display names', () {
      expect(EmployeeRole.admin.displayName, 'Admin');
      expect(EmployeeRole.payroll.displayName, 'Payroll');
      expect(EmployeeRole.hr.displayName, 'HR');
      expect(EmployeeRole.employee.displayName, 'Employee');
    });
  });

  group('EmploymentType Enum', () {
    test('should convert from string correctly', () {
      expect(EmploymentType.fromString('full-time'), EmploymentType.fullTime);
      expect(EmploymentType.fromString('Full-time'), EmploymentType.fullTime);
      expect(EmploymentType.fromString('fulltime'), EmploymentType.fullTime);
      expect(EmploymentType.fromString('part-time'), EmploymentType.partTime);
      expect(EmploymentType.fromString('Part-time'), EmploymentType.partTime);
      expect(EmploymentType.fromString('parttime'), EmploymentType.partTime);
      expect(EmploymentType.fromString('unknown'), EmploymentType.fullTime); // Default
    });

    test('should have correct display names', () {
      expect(EmploymentType.fullTime.displayName, 'Full-time');
      expect(EmploymentType.partTime.displayName, 'Part-time');
    });
  });

  group('PayType Enum', () {
    test('should convert from string correctly', () {
      expect(PayType.fromString('hourly'), PayType.hourly);
      expect(PayType.fromString('Hourly'), PayType.hourly);
      expect(PayType.fromString('salary'), PayType.salary);
      expect(PayType.fromString('Salary'), PayType.salary);
      expect(PayType.fromString('unknown'), PayType.hourly); // Default
    });

    test('should have correct display names', () {
      expect(PayType.hourly.displayName, 'Hourly');
      expect(PayType.salary.displayName, 'Salary');
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:item_manager/models/payroll.dart';
import 'package:item_manager/services/payroll_service.dart';
import 'package:item_manager/services/secure_storage_service.dart';
import 'package:item_manager/services/auth_api_service.dart';
import 'package:http/http.dart' as http;

// Generate mocks
@GenerateMocks([SecureStorageService, http.Client])
import 'payroll_service_test.mocks.dart';

void main() {
  group('PayrollService', () {
    late PayrollService payrollService;
    late MockSecureStorageService mockSecureStorage;
    late MockClient mockHttpClient;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockHttpClient = MockClient();
      payrollService = PayrollService(mockSecureStorage);
    });

    test('initializes correctly', () {
      expect(payrollService, isNotNull);
    });

    test('gets payroll records successfully', () async {
      // Arrange
      const testToken = 'test-token';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testPayroll = Payroll(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        grossPay: 5000.0,
        netPay: 4000.0,
        taxDeductions: 800.0,
        otherDeductions: 200.0,
        bonus: 0.0,
        overtimePay: 0.0,
        hourlyRate: 25.0,
        hoursWorked: 160.0,
        payPeriodStart: DateTime.now().subtract(const Duration(days: 30)),
        payPeriodEnd: DateTime.now(),
        payDate: DateTime.now(),
        status: 'processed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'payrolls': [
          {
            'id': testPayroll.id,
            'employeeId': testPayroll.employeeId,
            'employeeName': testPayroll.employeeName,
            'grossPay': testPayroll.grossPay,
            'netPay': testPayroll.netPay,
            'taxDeductions': testPayroll.taxDeductions,
            'otherDeductions': testPayroll.otherDeductions,
            'bonus': testPayroll.bonus,
            'overtimePay': testPayroll.overtimePay,
            'hourlyRate': testPayroll.hourlyRate,
            'hoursWorked': testPayroll.hoursWorked,
            'payPeriodStart': testPayroll.payPeriodStart.toIso8601String(),
            'payPeriodEnd': testPayroll.payPeriodEnd.toIso8601String(),
            'payDate': testPayroll.payDate.toIso8601String(),
            'status': testPayroll.status,
            'payslipUrl': null,
            'createdAt': testPayroll.createdAt.toIso8601String(),
            'updatedAt': testPayroll.updatedAt.toIso8601String(),
          }
        ]
      };

      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 200));

      // Act
      final result = await payrollService.getPayrollRecords();

      // Assert
      expect(result, isA<ApiResult<List<Payroll>>>());
      result.fold(
        (payrolls) {
          expect(payrolls, isNotEmpty);
          expect(payrolls.first.id, equals(testPayroll.id));
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('gets a specific payroll record successfully', () async {
      // Arrange
      const testToken = 'test-token';
      const testPayrollId = 'test-id';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testPayroll = Payroll(
        id: testPayrollId,
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        grossPay: 5000.0,
        netPay: 4000.0,
        taxDeductions: 800.0,
        otherDeductions: 200.0,
        bonus: 0.0,
        overtimePay: 0.0,
        hourlyRate: 25.0,
        hoursWorked: 160.0,
        payPeriodStart: DateTime.now().subtract(const Duration(days: 30)),
        payPeriodEnd: DateTime.now(),
        payDate: DateTime.now(),
        status: 'processed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'payroll': {
          'id': testPayroll.id,
          'employeeId': testPayroll.employeeId,
          'employeeName': testPayroll.employeeName,
          'grossPay': testPayroll.grossPay,
          'netPay': testPayroll.netPay,
          'taxDeductions': testPayroll.taxDeductions,
          'otherDeductions': testPayroll.otherDeductions,
          'bonus': testPayroll.bonus,
          'overtimePay': testPayroll.overtimePay,
          'hourlyRate': testPayroll.hourlyRate,
          'hoursWorked': testPayroll.hoursWorked,
          'payPeriodStart': testPayroll.payPeriodStart.toIso8601String(),
          'payPeriodEnd': testPayroll.payPeriodEnd.toIso8601String(),
          'payDate': testPayroll.payDate.toIso8601String(),
          'status': testPayroll.status,
          'payslipUrl': null,
          'createdAt': testPayroll.createdAt.toIso8601String(),
          'updatedAt': testPayroll.updatedAt.toIso8601String(),
        }
      };

      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 200));

      // Act
      final result = await payrollService.getPayrollRecord(testPayrollId);

      // Assert
      expect(result, isA<ApiResult<Payroll>>());
      result.fold(
        (payroll) {
          expect(payroll.id, equals(testPayroll.id));
          expect(payroll.employeeName, equals(testPayroll.employeeName));
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('generates payroll successfully', () async {
      // Arrange
      const testToken = 'test-token';
      const testEmployeeId = 'test-employee';
      final testPeriodStart = DateTime.now().subtract(const Duration(days: 30));
      final testPeriodEnd = DateTime.now();
      
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testPayroll = Payroll(
        id: 'generated-id',
        employeeId: testEmployeeId,
        employeeName: 'Test Employee',
        grossPay: 5000.0,
        netPay: 4000.0,
        taxDeductions: 800.0,
        otherDeductions: 200.0,
        bonus: 0.0,
        overtimePay: 0.0,
        hourlyRate: 25.0,
        hoursWorked: 160.0,
        payPeriodStart: testPeriodStart,
        payPeriodEnd: testPeriodEnd,
        payDate: DateTime.now(),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'payroll': {
          'id': testPayroll.id,
          'employeeId': testPayroll.employeeId,
          'employeeName': testPayroll.employeeName,
          'grossPay': testPayroll.grossPay,
          'netPay': testPayroll.netPay,
          'taxDeductions': testPayroll.taxDeductions,
          'otherDeductions': testPayroll.otherDeductions,
          'bonus': testPayroll.bonus,
          'overtimePay': testPayroll.overtimePay,
          'hourlyRate': testPayroll.hourlyRate,
          'hoursWorked': testPayroll.hoursWorked,
          'payPeriodStart': testPayroll.payPeriodStart.toIso8601String(),
          'payPeriodEnd': testPayroll.payPeriodEnd.toIso8601String(),
          'payDate': testPayroll.payDate.toIso8601String(),
          'status': testPayroll.status,
          'payslipUrl': null,
          'createdAt': testPayroll.createdAt.toIso8601String(),
          'updatedAt': testPayroll.updatedAt.toIso8601String(),
        }
      };

      when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 201));

      // Act
      final result = await payrollService.generatePayroll(
        employeeId: testEmployeeId,
        payPeriodStart: testPeriodStart,
        payPeriodEnd: testPeriodEnd,
      );

      // Assert
      expect(result, isA<ApiResult<Payroll>>());
      result.fold(
        (payroll) {
          expect(payroll.id, equals(testPayroll.id));
          expect(payroll.status, equals('pending'));
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('handles network error during payroll generation', () async {
      // Arrange
      const testToken = 'test-token';
      const testEmployeeId = 'test-employee';
      final testPeriodStart = DateTime.now().subtract(const Duration(days: 30));
      final testPeriodEnd = DateTime.now();
      
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await payrollService.generatePayroll(
        employeeId: testEmployeeId,
        payPeriodStart: testPeriodStart,
        payPeriodEnd: testPeriodEnd,
      );

      // Assert
      expect(result, isA<ApiResult<Payroll>>());
      result.fold(
        (payroll) => fail('Expected error but got success'),
        (error) {
          expect(error.code, equals('NETWORK_ERROR'));
          expect(error.message, contains('Network error'));
        },
      );
    });

    test('disposes correctly', () {
      // Act
      payrollService.dispose();

      // Assert
      // If no exception is thrown, dispose worked correctly
      expect(true, isTrue);
    });
  });
}
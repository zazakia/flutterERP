import 'package:flutter_test/flutter_test.dart';
import 'package:item_manager/models/payroll.dart';

void main() {
  group('Payroll Model', () {
    test('initializes correctly', () {
      final now = DateTime.now();
      final payroll = Payroll(
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
        payPeriodStart: now.subtract(const Duration(days: 30)),
        payPeriodEnd: now,
        payDate: now,
        status: 'processed',
        createdAt: now,
        updatedAt: now,
      );

      expect(payroll.id, equals('test-id'));
      expect(payroll.employeeId, equals('test-employee'));
      expect(payroll.employeeName, equals('Test Employee'));
      expect(payroll.grossPay, equals(5000.0));
      expect(payroll.netPay, equals(4000.0));
      expect(payroll.taxDeductions, equals(800.0));
      expect(payroll.otherDeductions, equals(200.0));
      expect(payroll.bonus, equals(0.0));
      expect(payroll.overtimePay, equals(0.0));
      expect(payroll.hourlyRate, equals(25.0));
      expect(payroll.hoursWorked, equals(160.0));
      expect(payroll.status, equals('processed'));
    });

    test('converts to and from JSON correctly', () {
      final now = DateTime.now();
      final payroll = Payroll(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        grossPay: 5000.0,
        netPay: 4000.0,
        taxDeductions: 800.0,
        otherDeductions: 200.0,
        bonus: 500.0,
        overtimePay: 200.0,
        hourlyRate: 25.0,
        hoursWorked: 160.0,
        payPeriodStart: now.subtract(const Duration(days: 30)),
        payPeriodEnd: now,
        payDate: now,
        status: 'processed',
        payslipUrl: 'https://example.com/payslip.pdf',
        createdAt: now,
        updatedAt: now,
      );

      final json = payroll.toJson();
      final fromJson = Payroll.fromJson(json);

      expect(fromJson.id, equals(payroll.id));
      expect(fromJson.employeeId, equals(payroll.employeeId));
      expect(fromJson.employeeName, equals(payroll.employeeName));
      expect(fromJson.grossPay, equals(payroll.grossPay));
      expect(fromJson.netPay, equals(payroll.netPay));
      expect(fromJson.taxDeductions, equals(payroll.taxDeductions));
      expect(fromJson.otherDeductions, equals(payroll.otherDeductions));
      expect(fromJson.bonus, equals(payroll.bonus));
      expect(fromJson.overtimePay, equals(payroll.overtimePay));
      expect(fromJson.hourlyRate, equals(payroll.hourlyRate));
      expect(fromJson.hoursWorked, equals(payroll.hoursWorked));
      expect(fromJson.payPeriodStart, equals(payroll.payPeriodStart));
      expect(fromJson.payPeriodEnd, equals(payroll.payPeriodEnd));
      expect(fromJson.payDate, equals(payroll.payDate));
      expect(fromJson.status, equals(payroll.status));
      expect(fromJson.payslipUrl, equals(payroll.payslipUrl));
      expect(fromJson.createdAt, equals(payroll.createdAt));
      expect(fromJson.updatedAt, equals(payroll.updatedAt));
    });

    test('copies with updated fields correctly', () {
      final now = DateTime.now();
      final payroll = Payroll(
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
        payPeriodStart: now.subtract(const Duration(days: 30)),
        payPeriodEnd: now,
        payDate: now,
        status: 'processed',
        createdAt: now,
        updatedAt: now,
      );

      final updated = payroll.copyWith(
        status: 'paid',
        bonus: 500.0,
        payslipUrl: 'https://example.com/payslip.pdf',
      );

      expect(updated.id, equals(payroll.id));
      expect(updated.employeeId, equals(payroll.employeeId));
      expect(updated.employeeName, equals(payroll.employeeName));
      expect(updated.grossPay, equals(payroll.grossPay));
      expect(updated.netPay, equals(payroll.netPay));
      expect(updated.taxDeductions, equals(payroll.taxDeductions));
      expect(updated.otherDeductions, equals(payroll.otherDeductions));
      expect(updated.bonus, equals(500.0));
      expect(updated.overtimePay, equals(payroll.overtimePay));
      expect(updated.hourlyRate, equals(payroll.hourlyRate));
      expect(updated.hoursWorked, equals(payroll.hoursWorked));
      expect(updated.payPeriodStart, equals(payroll.payPeriodStart));
      expect(updated.payPeriodEnd, equals(payroll.payPeriodEnd));
      expect(updated.payDate, equals(payroll.payDate));
      expect(updated.status, equals('paid'));
      expect(updated.payslipUrl, equals('https://example.com/payslip.pdf'));
      expect(updated.createdAt, equals(payroll.createdAt));
      expect(updated.updatedAt, equals(payroll.updatedAt));
    });
  });
}
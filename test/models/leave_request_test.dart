import 'package:flutter_test/flutter_test.dart';
import 'package:item_manager/models/leave_request.dart';

void main() {
  group('LeaveRequest Model', () {
    test('initializes correctly', () {
      final now = DateTime.now();
      final leaveRequest = LeaveRequest(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        leaveType: 'vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        numberOfDays: 5,
        reason: 'Vacation time',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      expect(leaveRequest.id, equals('test-id'));
      expect(leaveRequest.employeeId, equals('test-employee'));
      expect(leaveRequest.employeeName, equals('Test Employee'));
      expect(leaveRequest.leaveType, equals('vacation'));
      expect(leaveRequest.startDate, equals(now));
      expect(leaveRequest.endDate, equals(now.add(const Duration(days: 5))));
      expect(leaveRequest.numberOfDays, equals(5));
      expect(leaveRequest.reason, equals('Vacation time'));
      expect(leaveRequest.status, equals('pending'));
      expect(leaveRequest.isPending, isTrue);
      expect(leaveRequest.isApproved, isFalse);
      expect(leaveRequest.isRejected, isFalse);
      expect(leaveRequest.createdAt, equals(now));
      expect(leaveRequest.updatedAt, equals(now));
    });

    test('handles approved status correctly', () {
      final now = DateTime.now();
      final leaveRequest = LeaveRequest(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        leaveType: 'vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        numberOfDays: 5,
        reason: 'Vacation time',
        status: 'approved',
        approverId: 'approver-123',
        approverName: 'Manager',
        approvedAt: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      expect(leaveRequest.isPending, isFalse);
      expect(leaveRequest.isApproved, isTrue);
      expect(leaveRequest.isRejected, isFalse);
      expect(leaveRequest.approverId, equals('approver-123'));
      expect(leaveRequest.approverName, equals('Manager'));
      expect(leaveRequest.approvedAt, equals(now.add(const Duration(hours: 1))));
    });

    test('handles rejected status correctly', () {
      final now = DateTime.now();
      final leaveRequest = LeaveRequest(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        leaveType: 'vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        numberOfDays: 5,
        reason: 'Vacation time',
        status: 'rejected',
        rejectionReason: 'Not enough notice',
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      expect(leaveRequest.isPending, isFalse);
      expect(leaveRequest.isApproved, isFalse);
      expect(leaveRequest.isRejected, isTrue);
      expect(leaveRequest.rejectionReason, equals('Not enough notice'));
    });

    test('converts to and from JSON correctly', () {
      final now = DateTime.now();
      final approvedAt = now.add(const Duration(hours: 1));
      final leaveRequest = LeaveRequest(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        leaveType: 'vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        numberOfDays: 5,
        reason: 'Vacation time',
        status: 'approved',
        approverId: 'approver-123',
        approverName: 'Manager',
        approvedAt: approvedAt,
        createdAt: now,
        updatedAt: approvedAt,
      );

      final json = leaveRequest.toJson();
      final fromJson = LeaveRequest.fromJson(json);

      expect(fromJson.id, equals(leaveRequest.id));
      expect(fromJson.employeeId, equals(leaveRequest.employeeId));
      expect(fromJson.employeeName, equals(leaveRequest.employeeName));
      expect(fromJson.leaveType, equals(leaveRequest.leaveType));
      expect(fromJson.startDate, equals(leaveRequest.startDate));
      expect(fromJson.endDate, equals(leaveRequest.endDate));
      expect(fromJson.numberOfDays, equals(leaveRequest.numberOfDays));
      expect(fromJson.reason, equals(leaveRequest.reason));
      expect(fromJson.status, equals(leaveRequest.status));
      expect(fromJson.approverId, equals(leaveRequest.approverId));
      expect(fromJson.approverName, equals(leaveRequest.approverName));
      expect(fromJson.approvedAt, equals(leaveRequest.approvedAt));
      expect(fromJson.createdAt, equals(leaveRequest.createdAt));
      expect(fromJson.updatedAt, equals(leaveRequest.updatedAt));
    });

    test('copies with updated fields correctly', () {
      final now = DateTime.now();
      final leaveRequest = LeaveRequest(
        id: 'test-id',
        employeeId: 'test-employee',
        employeeName: 'Test Employee',
        leaveType: 'vacation',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        numberOfDays: 5,
        reason: 'Vacation time',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final updated = leaveRequest.copyWith(
        status: 'approved',
        approverId: 'manager-123',
        approverName: 'Manager Name',
        approvedAt: now.add(const Duration(hours: 1)),
      );

      expect(updated.id, equals(leaveRequest.id));
      expect(updated.employeeId, equals(leaveRequest.employeeId));
      expect(updated.employeeName, equals(leaveRequest.employeeName));
      expect(updated.leaveType, equals(leaveRequest.leaveType));
      expect(updated.startDate, equals(leaveRequest.startDate));
      expect(updated.endDate, equals(leaveRequest.endDate));
      expect(updated.numberOfDays, equals(leaveRequest.numberOfDays));
      expect(updated.reason, equals(leaveRequest.reason));
      expect(updated.status, equals('approved'));
      expect(updated.approverId, equals('manager-123'));
      expect(updated.approverName, equals('Manager Name'));
      expect(updated.approvedAt, equals(now.add(const Duration(hours: 1))));
      expect(updated.createdAt, equals(leaveRequest.createdAt));
      expect(updated.updatedAt, equals(leaveRequest.updatedAt));
    });
  });

  group('LeaveType Enum', () {
    test('should convert from string correctly', () {
      expect(LeaveType.fromString('vacation'), LeaveType.vacation);
      expect(LeaveType.fromString('VACATION'), LeaveType.vacation);
      expect(LeaveType.fromString('sick'), LeaveType.sick);
      expect(LeaveType.fromString('SICK'), LeaveType.sick);
      expect(LeaveType.fromString('personal'), LeaveType.personal);
      expect(LeaveType.fromString('PERSONAL'), LeaveType.personal);
      expect(LeaveType.fromString('maternity'), LeaveType.maternity);
      expect(LeaveType.fromString('MATERNITY'), LeaveType.maternity);
      expect(LeaveType.fromString('paternity'), LeaveType.paternity);
      expect(LeaveType.fromString('PATERNITY'), LeaveType.paternity);
      expect(LeaveType.fromString('bereavement'), LeaveType.bereavement);
      expect(LeaveType.fromString('BEREAVEMENT'), LeaveType.bereavement);
      expect(LeaveType.fromString('unknown'), LeaveType.vacation); // Default
    });

    test('should have correct display names', () {
      expect(LeaveType.vacation.displayName, 'Vacation');
      expect(LeaveType.sick.displayName, 'Sick Leave');
      expect(LeaveType.personal.displayName, 'Personal Leave');
      expect(LeaveType.maternity.displayName, 'Maternity Leave');
      expect(LeaveType.paternity.displayName, 'Paternity Leave');
      expect(LeaveType.bereavement.displayName, 'Bereavement Leave');
    });
  });
}
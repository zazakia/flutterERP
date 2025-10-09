import 'package:flutter_test/flutter_test.dart';
import 'package:item_manager/models/attendance.dart';

void main() {
  group('Attendance Model', () {
    test('initializes correctly', () {
      final now = DateTime.now();
      final attendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: now,
        isManualEntry: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(attendance.id, equals('test-id'));
      expect(attendance.employeeId, equals('test-employee'));
      expect(attendance.clockInTime, equals(now));
      expect(attendance.isManualEntry, isFalse);
      expect(attendance.isActive, isTrue);
      expect(attendance.durationInHours, isNull);
    });

    test('handles clock out correctly', () {
      final clockInTime = DateTime.now().subtract(const Duration(hours: 8));
      final clockOutTime = DateTime.now();
      
      final attendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: clockInTime,
        clockOutTime: clockOutTime,
        isManualEntry: false,
        createdAt: clockInTime,
        updatedAt: clockOutTime,
      );

      expect(attendance.isActive, isFalse);
      expect(attendance.durationInHours, closeTo(8.0, 0.01));
    });

    test('converts to and from JSON correctly', () {
      final now = DateTime.now();
      final attendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: now,
        clockOutTime: now.add(const Duration(hours: 8)),
        location: 'Office',
        isManualEntry: true,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 8)),
      );

      final json = attendance.toJson();
      final fromJson = Attendance.fromJson(json);

      expect(fromJson.id, equals(attendance.id));
      expect(fromJson.employeeId, equals(attendance.employeeId));
      expect(fromJson.clockInTime, equals(attendance.clockInTime));
      expect(fromJson.clockOutTime, equals(attendance.clockOutTime));
      expect(fromJson.location, equals(attendance.location));
      expect(fromJson.isManualEntry, equals(attendance.isManualEntry));
      expect(fromJson.createdAt, equals(attendance.createdAt));
      expect(fromJson.updatedAt, equals(attendance.updatedAt));
    });

    test('copies with updated fields correctly', () {
      final now = DateTime.now();
      final attendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: now,
        isManualEntry: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = attendance.copyWith(
        location: 'Remote',
        clockOutTime: now.add(const Duration(hours: 8)),
      );

      expect(updated.id, equals(attendance.id));
      expect(updated.employeeId, equals(attendance.employeeId));
      expect(updated.clockInTime, equals(attendance.clockInTime));
      expect(updated.location, equals('Remote'));
      expect(updated.clockOutTime, equals(now.add(const Duration(hours: 8))));
      expect(updated.isManualEntry, equals(attendance.isManualEntry));
    });
  });
}
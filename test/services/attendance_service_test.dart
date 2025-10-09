import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:item_manager/models/attendance.dart';
import 'package:item_manager/services/attendance_service.dart';
import 'package:item_manager/services/secure_storage_service.dart';
import 'package:item_manager/services/auth_api_service.dart';
import 'package:http/http.dart' as http;

// Generate mocks
@GenerateMocks([SecureStorageService, http.Client])
import 'attendance_service_test.mocks.dart';

void main() {
  group('AttendanceService', () {
    late AttendanceService attendanceService;
    late MockSecureStorageService mockSecureStorage;
    late MockClient mockHttpClient;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockHttpClient = MockClient();
      attendanceService = AttendanceService(mockSecureStorage);
    });

    test('initializes correctly', () {
      expect(attendanceService, isNotNull);
    });

    test('clocks in successfully', () async {
      // Arrange
      const testToken = 'test-token';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testAttendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: DateTime.now(),
        isManualEntry: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'attendance': {
          'id': testAttendance.id,
          'employeeId': testAttendance.employeeId,
          'clockInTime': testAttendance.clockInTime.toIso8601String(),
          'clockOutTime': null,
          'location': null,
          'isManualEntry': testAttendance.isManualEntry,
          'createdAt': testAttendance.createdAt.toIso8601String(),
          'updatedAt': testAttendance.updatedAt.toIso8601String(),
        }
      };

      when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 201));

      // Act
      final result = await attendanceService.clockIn();

      // Assert
      expect(result, isA<ApiResult<Attendance>>());
      result.fold(
        (attendance) {
          expect(attendance.id, equals(testAttendance.id));
          expect(attendance.employeeId, equals(testAttendance.employeeId));
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('clocks out successfully', () async {
      // Arrange
      const testToken = 'test-token';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testAttendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: DateTime.now().subtract(const Duration(hours: 8)),
        clockOutTime: DateTime.now(),
        isManualEntry: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'attendance': {
          'id': testAttendance.id,
          'employeeId': testAttendance.employeeId,
          'clockInTime': testAttendance.clockInTime.toIso8601String(),
          'clockOutTime': testAttendance.clockOutTime?.toIso8601String(),
          'location': null,
          'isManualEntry': testAttendance.isManualEntry,
          'createdAt': testAttendance.createdAt.toIso8601String(),
          'updatedAt': testAttendance.updatedAt.toIso8601String(),
        }
      };

      when(mockHttpClient.put(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 200));

      // Act
      final result = await attendanceService.clockOut();

      // Assert
      expect(result, isA<ApiResult<Attendance>>());
      result.fold(
        (attendance) {
          expect(attendance.id, equals(testAttendance.id));
          expect(attendance.clockOutTime, isNotNull);
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('gets active attendance successfully', () async {
      // Arrange
      const testToken = 'test-token';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      final testAttendance = Attendance(
        id: 'test-id',
        employeeId: 'test-employee',
        clockInTime: DateTime.now(),
        isManualEntry: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final responseJson = {
        'attendance': {
          'id': testAttendance.id,
          'employeeId': testAttendance.employeeId,
          'clockInTime': testAttendance.clockInTime.toIso8601String(),
          'clockOutTime': null,
          'location': null,
          'isManualEntry': testAttendance.isManualEntry,
          'createdAt': testAttendance.createdAt.toIso8601String(),
          'updatedAt': testAttendance.updatedAt.toIso8601String(),
        }
      };

      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseJson), 200));

      // Act
      final result = await attendanceService.getActiveAttendance();

      // Assert
      expect(result, isA<ApiResult<Attendance?>>());
      result.fold(
        (attendance) {
          expect(attendance, isNotNull);
          expect(attendance!.id, equals(testAttendance.id));
        },
        (error) => fail('Expected success but got error: ${error.message}'),
      );
    });

    test('handles network error during clock in', () async {
      // Arrange
      const testToken = 'test-token';
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => testToken);

      when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await attendanceService.clockIn();

      // Assert
      expect(result, isA<ApiResult<Attendance>>());
      result.fold(
        (attendance) => fail('Expected error but got success'),
        (error) {
          expect(error.code, equals('NETWORK_ERROR'));
          expect(error.message, contains('Network error'));
        },
      );
    });

    test('disposes correctly', () {
      // Act
      attendanceService.dispose();

      // Assert
      // If no exception is thrown, dispose worked correctly
      expect(true, isTrue);
    });
  });
}
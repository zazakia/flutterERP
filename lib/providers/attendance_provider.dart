import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for attendance tracking state management
class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;

  AttendanceProvider(SecureStorageService secureStorage)
      : _attendanceService = AttendanceService(secureStorage);

  // State
  Attendance? _activeAttendance;
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Attendance? get activeAttendance => _activeAttendance;
  List<Attendance> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isClockedIn => _activeAttendance != null;

  /// Clock in for the current user
  Future<bool> clockIn({String? location}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.clockIn(location: location);

      return result.fold(
        (attendance) {
          _activeAttendance = attendance;
          // Add to records list at the beginning
          _attendanceRecords.insert(0, attendance);
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to clock in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clock out for the current user
  Future<bool> clockOut({String? location}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.clockOut(location: location);

      return result.fold(
        (attendance) {
          _activeAttendance = null;
          // Update the record in the list
          final index = _attendanceRecords.indexWhere((a) => a.id == attendance.id);
          if (index != -1) {
            _attendanceRecords[index] = attendance;
          }
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to clock out: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load current user's active attendance record
  Future<void> loadActiveAttendance() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.getActiveAttendance();

      result.fold(
        (attendance) {
          _activeAttendance = attendance;
          notifyListeners();
        },
        (error) {
          _setError(error.message);
        },
      );
    } catch (e) {
      _setError('Failed to load active attendance: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load attendance records for current user
  Future<void> loadAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.getAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );

      result.fold(
        (attendances) {
          if (page == 1) {
            _attendanceRecords = attendances;
          } else {
            _attendanceRecords.addAll(attendances);
          }
          notifyListeners();
        },
        (error) {
          _setError(error.message);
        },
      );
    } catch (e) {
      _setError('Failed to load attendance records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Manually add attendance record (admin/HR only)
  Future<bool> addManualAttendance(Attendance attendance) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.addManualAttendance(attendance);

      return result.fold(
        (createdAttendance) {
          _attendanceRecords.insert(0, createdAttendance);
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to add manual attendance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update attendance record (admin/HR only)
  Future<bool> updateAttendance(String attendanceId, Attendance updatedAttendance) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.updateAttendance(attendanceId, updatedAttendance);

      return result.fold(
        (attendance) {
          final index = _attendanceRecords.indexWhere((a) => a.id == attendanceId);
          if (index != -1) {
            _attendanceRecords[index] = attendance;
            // If this was the active attendance, update it too
            if (_activeAttendance?.id == attendanceId) {
              _activeAttendance = attendance;
            }
          }
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to update attendance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete attendance record (admin/HR only)
  Future<bool> deleteAttendance(String attendanceId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _attendanceService.deleteAttendance(attendanceId);

      return result.fold(
        (_) {
          _attendanceRecords.removeWhere((a) => a.id == attendanceId);
          // If this was the active attendance, clear it
          if (_activeAttendance?.id == attendanceId) {
            _activeAttendance = null;
          }
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to delete attendance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Calculate total hours worked in a given period
  double calculateTotalHoursWorked(DateTime startDate, DateTime endDate) {
    double totalHours = 0.0;
    
    for (final attendance in _attendanceRecords) {
      // Check if attendance record falls within the date range
      if (attendance.clockInTime.isAfter(startDate) && 
          attendance.clockInTime.isBefore(endDate)) {
        final hours = attendance.durationInHours;
        if (hours != null) {
          totalHours += hours;
        }
      }
    }
    
    return totalHours;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }
}
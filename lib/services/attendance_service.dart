import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';
import 'auth_api_service.dart';
import 'secure_storage_service.dart';

/// API service for attendance tracking endpoints
class AttendanceService {
  static const String _baseUrl = 'https://api.brayanlee-payroll.com'; // Replace with actual API URL
  static const String _attendanceEndpoint = '/attendance';

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  AttendanceService(this._secureStorage) : _httpClient = http.Client();

  /// Get authorization headers with access token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Clock in for the current user
  Future<ApiResult<Attendance>> clockIn({String? location}) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/clock-in');

      final body = <String, dynamic>{
        'location': location,
        'isManualEntry': false,
      };

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final attendance = Attendance.fromJson(data['attendance']);
        return ApiResult.success(attendance);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while clocking in: $e',
        ),
      );
    }
  }

  /// Clock out for the current user
  Future<ApiResult<Attendance>> clockOut({String? location}) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/clock-in');

      final body = <String, dynamic>{
        'location': location,
        'isManualEntry': false,
      };

      final response = await _httpClient.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final attendance = Attendance.fromJson(data['attendance']);
        return ApiResult.success(attendance);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while clocking out: $e',
        ),
      );
    }
  }

  /// Get current user's active attendance record (if clocked in)
  Future<ApiResult<Attendance?>> getActiveAttendance() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/active');

      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['attendance'] == null) {
          return ApiResult.success(null);
        }
        final attendance = Attendance.fromJson(data['attendance']);
        return ApiResult.success(attendance);
      } else if (response.statusCode == 404) {
        // No active attendance record
        return ApiResult.success(null);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching active attendance: $e',
        ),
      );
    }
  }

  /// Get attendance records for current user with pagination
  Future<ApiResult<List<Attendance>>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$_baseUrl$_attendanceEndpoint').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final attendances = (data['attendances'] as List)
            .map((json) => Attendance.fromJson(json))
            .toList();
        return ApiResult.success(attendances);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching attendance records: $e',
        ),
      );
    }
  }

  /// Manually add attendance record (admin/HR only)
  Future<ApiResult<Attendance>> addManualAttendance(Attendance attendance) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/manual');

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(attendance.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdAttendance = Attendance.fromJson(data['attendance']);
        return ApiResult.success(createdAttendance);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while adding manual attendance: $e',
        ),
      );
    }
  }

  /// Update attendance record (admin/HR only)
  Future<ApiResult<Attendance>> updateAttendance(String attendanceId, Attendance attendance) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/$attendanceId');

      final response = await _httpClient.put(
        url,
        headers: headers,
        body: jsonEncode(attendance.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedAttendance = Attendance.fromJson(data['attendance']);
        return ApiResult.success(updatedAttendance);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while updating attendance: $e',
        ),
      );
    }
  }

  /// Delete attendance record (admin/HR only)
  Future<ApiResult<void>> deleteAttendance(String attendanceId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_attendanceEndpoint/$attendanceId');

      final response = await _httpClient.delete(url, headers: headers);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResult.success(null);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while deleting attendance: $e',
        ),
      );
    }
  }

  /// Parse error from HTTP response
  ApiError _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return ApiError(
        code: data['code'] ?? 'UNKNOWN_ERROR',
        message: data['message'] ?? 'An unknown error occurred',
      );
    } catch (e) {
      return ApiError(
        code: 'HTTP_${response.statusCode}',
        message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  /// Dispose of HTTP client
  void dispose() {
    _httpClient.close();
  }
}
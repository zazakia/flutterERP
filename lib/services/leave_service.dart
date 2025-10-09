import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_request.dart';
import 'auth_api_service.dart';
import 'secure_storage_service.dart';

/// API service for leave management endpoints
class LeaveService {
  static const String _baseUrl = 'https://api.brayanlee-payroll.com'; // Replace with actual API URL
  static const String _leaveEndpoint = '/leave-requests';

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  LeaveService(this._secureStorage) : _httpClient = http.Client();

  /// Get authorization headers with access token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get leave requests for current user with pagination
  Future<ApiResult<List<LeaveRequest>>> getMyLeaveRequests({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl$_leaveEndpoint').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaveRequests = (data['leaveRequests'] as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
        return ApiResult.success(leaveRequests);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching leave requests: $e',
        ),
      );
    }
  }

  /// Get all leave requests (for managers/admins) with pagination and filters
  Future<ApiResult<List<LeaveRequest>>> getAllLeaveRequests({
    int page = 1,
    int limit = 50,
    String? status,
    String? employeeId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employeeId'] = employeeId;
      }

      final uri = Uri.parse('$_baseUrl$_leaveEndpoint/all').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaveRequests = (data['leaveRequests'] as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
        return ApiResult.success(leaveRequests);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching leave requests: $e',
        ),
      );
    }
  }

  /// Create a new leave request
  Future<ApiResult<LeaveRequest>> createLeaveRequest(LeaveRequest leaveRequest) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_leaveEndpoint');

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(leaveRequest.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdLeaveRequest = LeaveRequest.fromJson(data['leaveRequest']);
        return ApiResult.success(createdLeaveRequest);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while creating leave request: $e',
        ),
      );
    }
  }

  /// Approve a leave request (for managers/admins)
  Future<ApiResult<LeaveRequest>> approveLeaveRequest(String leaveId, {String? approverId}) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_leaveEndpoint/$leaveId/approve');

      final body = <String, dynamic>{
        if (approverId != null) 'approverId': approverId,
      };

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final approvedLeaveRequest = LeaveRequest.fromJson(data['leaveRequest']);
        return ApiResult.success(approvedLeaveRequest);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while approving leave request: $e',
        ),
      );
    }
  }

  /// Reject a leave request (for managers/admins)
  Future<ApiResult<LeaveRequest>> rejectLeaveRequest(String leaveId, String reason, {String? approverId}) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_leaveEndpoint/$leaveId/reject');

      final body = <String, dynamic>{
        'reason': reason,
        if (approverId != null) 'approverId': approverId,
      };

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rejectedLeaveRequest = LeaveRequest.fromJson(data['leaveRequest']);
        return ApiResult.success(rejectedLeaveRequest);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while rejecting leave request: $e',
        ),
      );
    }
  }

  /// Cancel a leave request (for requester)
  Future<ApiResult<LeaveRequest>> cancelLeaveRequest(String leaveId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_leaveEndpoint/$leaveId/cancel');

      final response = await _httpClient.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cancelledLeaveRequest = LeaveRequest.fromJson(data['leaveRequest']);
        return ApiResult.success(cancelledLeaveRequest);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while cancelling leave request: $e',
        ),
      );
    }
  }

  /// Get leave balance for current user
  Future<ApiResult<Map<String, dynamic>>> getLeaveBalance() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_leaveEndpoint/balance');

      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success(data['balance']);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching leave balance: $e',
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
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payroll.dart';
import 'auth_api_service.dart';
import 'secure_storage_service.dart';

/// API service for payroll management endpoints
class PayrollService {
  static const String _baseUrl = 'https://api.brayanlee-payroll.com'; // Replace with actual API URL
  static const String _payrollEndpoint = '/payroll';

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  PayrollService(this._secureStorage) : _httpClient = http.Client();

  /// Get authorization headers with access token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get payroll records for current user with pagination
  Future<ApiResult<List<Payroll>>> getPayrollRecords({
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

      final uri = Uri.parse('$_baseUrl$_payrollEndpoint').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payrolls = (data['payrolls'] as List)
            .map((json) => Payroll.fromJson(json))
            .toList();
        return ApiResult.success(payrolls);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching payroll records: $e',
        ),
      );
    }
  }

  /// Get a specific payroll record by ID
  Future<ApiResult<Payroll>> getPayrollRecord(String payrollId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_payrollEndpoint/$payrollId');

      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payroll = Payroll.fromJson(data['payroll']);
        return ApiResult.success(payroll);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching payroll record: $e',
        ),
      );
    }
  }

  /// Generate payroll for an employee (admin/payroll only)
  Future<ApiResult<Payroll>> generatePayroll({
    required String employeeId,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    double? bonus,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_payrollEndpoint/generate');

      final body = <String, dynamic>{
        'employeeId': employeeId,
        'payPeriodStart': payPeriodStart.toIso8601String(),
        'payPeriodEnd': payPeriodEnd.toIso8601String(),
        if (bonus != null) 'bonus': bonus,
        if (notes != null) 'notes': notes,
      };

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final payroll = Payroll.fromJson(data['payroll']);
        return ApiResult.success(payroll);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while generating payroll: $e',
        ),
      );
    }
  }

  /// Update payroll record status (admin/payroll only)
  Future<ApiResult<Payroll>> updatePayrollStatus(String payrollId, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_payrollEndpoint/$payrollId/status');

      final body = <String, dynamic>{
        'status': status,
      };

      final response = await _httpClient.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payroll = Payroll.fromJson(data['payroll']);
        return ApiResult.success(payroll);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while updating payroll status: $e',
        ),
      );
    }
  }

  /// Get payroll summary for dashboard
  Future<ApiResult<Map<String, dynamic>>> getPayrollSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_payrollEndpoint/summary');

      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success(data['summary']);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching payroll summary: $e',
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
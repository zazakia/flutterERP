import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import 'auth_api_service.dart'; // For ApiResult and ApiError
import 'secure_storage_service.dart';

/// API service for employee management endpoints
class EmployeeApiService {
  static const String _baseUrl = 'https://api.brayanlee-payroll.com'; // Replace with actual API URL
  static const String _employeesEndpoint = '/employees';
  static const String _bulkActivateEndpoint = '/employees/bulk-activate';
  static const String _bulkDeactivateEndpoint = '/employees/bulk-deactivate';
  static const String _importCsvEndpoint = '/employees/import-csv';

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  EmployeeApiService(this._secureStorage) : _httpClient = http.Client();

  /// Get authorization headers with access token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all employees with pagination
  Future<ApiResult<List<Employee>>> getEmployees({
    int page = 1,
    int limit = 50,
    String? search,
    String? role,
    bool? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final uri = Uri.parse('$_baseUrl$_employeesEndpoint').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employees = (data['employees'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
        return ApiResult.success(employees);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while fetching employees: $e',
        ),
      );
    }
  }

  /// Create a new employee
  Future<ApiResult<Employee>> createEmployee(Employee employee) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_employeesEndpoint');

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(employee.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdEmployee = Employee.fromJson(data['employee']);
        return ApiResult.success(createdEmployee);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while creating employee: $e',
        ),
      );
    }
  }

  /// Update an existing employee
  Future<ApiResult<Employee>> updateEmployee(String employeeId, Employee employee) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_employeesEndpoint/$employeeId');

      final response = await _httpClient.put(
        url,
        headers: headers,
        body: jsonEncode(employee.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedEmployee = Employee.fromJson(data['employee']);
        return ApiResult.success(updatedEmployee);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error while updating employee: $e',
        ),
      );
    }
  }

  /// Delete an employee
  Future<ApiResult<void>> deleteEmployee(String employeeId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_employeesEndpoint/$employeeId');

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
          message: 'Network error while deleting employee: $e',
        ),
      );
    }
  }

  /// Bulk activate employees
  Future<ApiResult<BulkOperationResult>> bulkActivateEmployees(List<String> employeeIds) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_bulkActivateEndpoint');

      final body = jsonEncode({'employeeIds': employeeIds});

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = BulkOperationResult.fromJson(data);
        return ApiResult.success(result);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during bulk activation: $e',
        ),
      );
    }
  }

  /// Bulk deactivate employees
  Future<ApiResult<BulkOperationResult>> bulkDeactivateEmployees(List<String> employeeIds) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_bulkDeactivateEndpoint');

      final body = jsonEncode({'employeeIds': employeeIds});

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = BulkOperationResult.fromJson(data);
        return ApiResult.success(result);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during bulk deactivation: $e',
        ),
      );
    }
  }

  /// Import employees from CSV
  Future<ApiResult<ImportResult>> importEmployeesFromCsv(String csvData) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$_baseUrl$_importCsvEndpoint');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      request.files.add(
        http.MultipartFile.fromString(
          'csv',
          csvData,
          filename: 'employees.csv',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = ImportResult.fromJson(data);
        return ApiResult.success(result);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during CSV import: $e',
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

/// Bulk operation result model
class BulkOperationResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  BulkOperationResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  factory BulkOperationResult.fromJson(Map<String, dynamic> json) {
    return BulkOperationResult(
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'successCount': successCount,
      'failureCount': failureCount,
      'errors': errors,
    };
  }
}

/// CSV import result model
class ImportResult {
  final int importedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;
  final List<String> warnings;

  ImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.errors,
    required this.warnings,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      importedCount: json['importedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      errorCount: json['errorCount'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importedCount': importedCount,
      'skippedCount': skippedCount,
      'errorCount': errorCount,
      'errors': errors,
      'warnings': warnings,
    };
  }
}
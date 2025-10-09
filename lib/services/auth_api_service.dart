import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'secure_storage_service.dart';

/// API service for authentication-related endpoints
class AuthApiService {
  static const String _baseUrl = 'https://api.brayanlee-payroll.com'; // Replace with actual API URL
  static const String _enrollEndpoint = '/auth/enroll';
  static const String _loginEndpoint = '/auth/login';
  static const String _refreshEndpoint = '/auth/refresh';
  static const String _pinLoginEndpoint = '/auth/pin';

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  AuthApiService(this._secureStorage) : _httpClient = http.Client();

  /// Enroll biometric authentication for user
  Future<ApiResult<AuthTokens>> enrollBiometric({
    required String userId,
    required String deviceId,
    required String biometricSignature,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_enrollEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

      final body = jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
        'biometricSignature': biometricSignature,
      });

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(data);

        // Store tokens securely
        await _secureStorage.storeTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userId: userId,
        );

        return ApiResult.success(tokens);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during enrollment: $e',
        ),
      );
    }
  }

  /// Login with biometric authentication
  Future<ApiResult<AuthTokens>> loginWithBiometric({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_loginEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

      final body = jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
        'authType': 'biometric',
      });

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(data);

        // Store tokens securely
        await _secureStorage.storeTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userId: userId,
        );

        return ApiResult.success(tokens);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during login: $e',
        ),
      );
    }
  }

  /// Login with PIN authentication
  Future<ApiResult<AuthTokens>> loginWithPin({
    required String userId,
    required String pin,
    required String deviceId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_pinLoginEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

      final body = jsonEncode({
        'userId': userId,
        'pin': pin,
        'deviceId': deviceId,
      });

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(data);

        // Store tokens securely
        await _secureStorage.storeTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userId: userId,
        );

        return ApiResult.success(tokens);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during PIN login: $e',
        ),
      );
    }
  }

  /// Refresh access token using refresh token
  Future<ApiResult<AuthTokens>> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return ApiResult.failure(
          ApiError(
            code: 'NO_REFRESH_TOKEN',
            message: 'No refresh token available',
          ),
        );
      }

      final url = Uri.parse('$_baseUrl$_refreshEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      };

      final response = await _httpClient.post(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(data);

        // Update stored tokens
        final userId = await _secureStorage.getUserId();
        if (userId != null) {
          await _secureStorage.storeTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            userId: userId,
          );
        }

        return ApiResult.success(tokens);
      } else {
        final error = _parseError(response);
        return ApiResult.failure(error);
      }
    } catch (e) {
      return ApiResult.failure(
        ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error during token refresh: $e',
        ),
      );
    }
  }

  /// Validate if access token is expired
  Future<bool> isTokenExpired() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null) return true;

      return JwtDecoder.isExpired(token);
    } catch (e) {
      print('Error checking token expiration: $e');
      return true;
    }
  }

  /// Get user information from JWT token
  Future<Map<String, dynamic>?> getUserFromToken() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null) return null;

      return JwtDecoder.decode(token);
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  /// Logout user and clear all stored data
  Future<void> logout() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        // Call logout endpoint if needed
        final url = Uri.parse('$_baseUrl/auth/logout');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        try {
          await _httpClient.post(url, headers: headers);
        } catch (e) {
          // Ignore logout API errors
          print('Logout API call failed: $e');
        }
      }
    } finally {
      // Always clear local data
      await _secureStorage.clearAllData();
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

/// Authentication tokens model
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String role;
  final DateTime expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      role: json['role'] ?? 'employee',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        json['expiresAt'] ?? (DateTime.now().millisecondsSinceEpoch + 3600000), // Default 1 hour
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'role': role,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }
}

/// API result wrapper
class ApiResult<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(success: true, data: data);
  }

  factory ApiResult.failure(ApiError error) {
    return ApiResult._(success: false, error: error);
  }

  /// Fold the result into a single value
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(ApiError error) onFailure,
  ) {
    if (success) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }
}

/// API error model
class ApiError {
  final String code;
  final String message;

  ApiError({
    required this.code,
    required this.message,
  });
}
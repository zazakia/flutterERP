import 'dart:async';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import 'biometric_auth_service.dart';
import 'pin_auth_service.dart';
import 'auth_api_service.dart';

/// Main authentication service that orchestrates all authentication methods
class AuthenticationService {
  final SecureStorageService _secureStorage;
  final BiometricAuthService _biometricAuth;
  final PinAuthService _pinAuth;
  final AuthApiService _apiService;

  Timer? _tokenRefreshTimer;
  bool _isRefreshing = false;

  AuthenticationService(
    this._secureStorage,
    this._biometricAuth,
    this._pinAuth,
    this._apiService,
  ) {
    _startTokenRefreshTimer();
  }

  /// Initialize all services
  static Future<AuthenticationService> initialize() async {
    final secureStorage = await SecureStorageService.initialize();
    final biometricAuth = BiometricAuthService(secureStorage);
    final pinAuth = PinAuthService(secureStorage);
    final apiService = AuthApiService(secureStorage);

    return AuthenticationService(
      secureStorage,
      biometricAuth,
      pinAuth,
      apiService,
    );
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    // Check if we have stored tokens
    if (!await _secureStorage.isAuthenticated()) {
      return false;
    }

    // Check if token is expired
    if (await _apiService.isTokenExpired()) {
      // Try to refresh token
      final refreshResult = await _apiService.refreshToken();
      return refreshResult.success;
    }

    return true;
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _secureStorage.getUserId();
  }

  /// Get current user information
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _apiService.getUserFromToken();
  }

  /// Authenticate with biometrics
  Future<AuthResult> authenticateWithBiometrics() async {
    try {
      // Check if biometric is enrolled
      if (!await _biometricAuth.isBiometricEnrolled()) {
        return AuthResult(
          success: false,
          needsEnrollment: true,
          message: 'Biometric authentication is not enrolled',
        );
      }

      // Get current user and device info
      final userId = await _secureStorage.getUserId();
      final deviceId = await _secureStorage.getDeviceId();

      if (userId == null || deviceId == null) {
        return AuthResult(
          success: false,
          error: AuthError.noStoredCredentials,
          message: 'No stored credentials found',
        );
      }

      // Perform biometric authentication
      final biometricResult = await _biometricAuth.authenticateWithBiometrics();

      if (!biometricResult.success) {
        return AuthResult(
          success: false,
          error: _mapBiometricError(biometricResult.error),
          message: biometricResult.message,
        );
      }

      // Call API to get tokens
      final apiResult = await _apiService.loginWithBiometric(
        userId: userId,
        deviceId: deviceId,
      );

      if (apiResult.success) {
        return AuthResult(
          success: true,
          message: 'Biometric authentication successful',
        );
      } else {
        return AuthResult(
          success: false,
          error: AuthError.apiError,
          message: apiResult.error?.message ?? 'API authentication failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: AuthError.unknown,
        message: 'Biometric authentication failed: $e',
      );
    }
  }

  /// Authenticate with PIN
  Future<AuthResult> authenticateWithPin(String pin) async {
    try {
      // Get current user and device info
      final userId = await _secureStorage.getUserId();
      final deviceId = await _secureStorage.getDeviceId();

      if (userId == null || deviceId == null) {
        return AuthResult(
          success: false,
          error: AuthError.noStoredCredentials,
          message: 'No stored credentials found',
        );
      }

      // Verify PIN locally first
      final pinResult = await _pinAuth.verifyPin(pin);

      if (!pinResult.success) {
        return AuthResult(
          success: false,
          error: _mapPinError(pinResult.error),
          message: pinResult.message,
        );
      }

      // Call API to get tokens
      final apiResult = await _apiService.loginWithPin(
        userId: userId,
        pin: pin,
        deviceId: deviceId,
      );

      if (apiResult.success) {
        return AuthResult(
          success: true,
          message: 'PIN authentication successful',
        );
      } else {
        return AuthResult(
          success: false,
          error: AuthError.apiError,
          message: apiResult.error?.message ?? 'API authentication failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: AuthError.unknown,
        message: 'PIN authentication failed: $e',
      );
    }
  }

  /// Enroll biometric authentication
  Future<AuthResult> enrollBiometric() async {
    try {
      // Get current user and device info
      final userId = await _secureStorage.getUserId();
      final deviceId = await _secureStorage.getDeviceId();

      if (userId == null || deviceId == null) {
        return AuthResult(
          success: false,
          error: AuthError.noStoredCredentials,
          message: 'No stored credentials found',
        );
      }

      // Check if already enrolled
      if (await _biometricAuth.isBiometricEnrolled()) {
        return AuthResult(
          success: false,
          error: AuthError.alreadyEnrolled,
          message: 'Biometric authentication is already enrolled',
        );
      }

      // Generate biometric signature (placeholder - in real implementation,
      // this would be obtained from the biometric sensor)
      final biometricSignature = _generateBiometricSignature(userId, deviceId);

      // Call API to enroll
      final apiResult = await _apiService.enrollBiometric(
        userId: userId,
        deviceId: deviceId,
        biometricSignature: biometricSignature,
      );

      if (apiResult.success) {
        // Mark as enrolled locally
        await _secureStorage.setBiometricEnrolled(true);

        return AuthResult(
          success: true,
          message: 'Biometric authentication enrolled successfully',
        );
      } else {
        return AuthResult(
          success: false,
          error: AuthError.apiError,
          message: apiResult.error?.message ?? 'Biometric enrollment failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: AuthError.unknown,
        message: 'Biometric enrollment failed: $e',
      );
    }
  }


  /// Check if biometric authentication is available and enrolled
  Future<bool> canUseBiometricAuth() async {
    return await _biometricAuth.isBiometricAvailable() &&
           await _biometricAuth.isBiometricEnrolled();
  }

  /// Check if PIN authentication is available
  Future<bool> canUsePinAuth() async {
    return await _pinAuth.isPinSet();
  }

  /// Get available authentication methods
  Future<List<AuthMethod>> getAvailableAuthMethods() async {
    final methods = <AuthMethod>[];

    if (await canUseBiometricAuth()) {
      final biometricTypes = await _biometricAuth.getAvailableBiometricTypes();
      if (biometricTypes.isNotEmpty) {
        methods.add(AuthMethod.biometric);
      }
    }

    if (await canUsePinAuth()) {
      methods.add(AuthMethod.pin);
    }

    return methods;
  }

  /// Check if account is locked due to failed attempts
  Future<bool> isLockedOut() async {
    return await _secureStorage.isLockedOut();
  }

  /// Get remaining lockout time in seconds
  Future<int> getRemainingLockoutTime() async {
    return await _secureStorage.getRemainingLockoutTime();
  }

  /// Logout user
  Future<void> logout() async {
    _stopTokenRefreshTimer();
    await _apiService.logout();
  }

  /// Generate a mock biometric signature (in real implementation,
  /// this would come from the actual biometric sensor)
  String _generateBiometricSignature(String userId, String deviceId) {
    // This is a placeholder implementation
    // In a real app, this would be obtained from the biometric sensor
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'biometric_signature_${userId}_${deviceId}_${timestamp}';
  }

  /// Map biometric errors to auth errors
  AuthError _mapBiometricError(BiometricAuthError? error) {
    if (error == null) return AuthError.unknown;

    switch (error) {
      case BiometricAuthError.notAvailable:
        return AuthError.biometricNotAvailable;
      case BiometricAuthError.notEnrolled:
        return AuthError.biometricNotEnrolled;
      case BiometricAuthError.lockedOut:
        return AuthError.lockedOut;
      case BiometricAuthError.authenticationFailed:
        return AuthError.authenticationFailed;
      default:
        return AuthError.unknown;
    }
  }

  /// Map PIN errors to auth errors
  AuthError _mapPinError(PinAuthError? error) {
    if (error == null) return AuthError.unknown;

    switch (error) {
      case PinAuthError.notSet:
        return AuthError.pinNotSet;
      case PinAuthError.invalidPin:
        return AuthError.invalidPin;
      case PinAuthError.lockedOut:
        return AuthError.lockedOut;
      default:
        return AuthError.unknown;
    }
  }

  /// Start automatic token refresh timer
  void _startTokenRefreshTimer() {
    // Refresh token every 50 minutes (tokens typically expire after 1 hour)
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 50),
      (timer) async {
        if (_isRefreshing || !await isAuthenticated()) return;

        _isRefreshing = true;
        try {
          await _apiService.refreshToken();
        } catch (e) {
          print('Token refresh failed: $e');
        } finally {
          _isRefreshing = false;
        }
      },
    );
  }

  /// Stop token refresh timer
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Dispose of the service
  void dispose() {
    _stopTokenRefreshTimer();
    _apiService.dispose();
    _pinAuth.dispose();
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final AuthError? error;
  final bool needsEnrollment;
  final String message;

  AuthResult({
    required this.success,
    this.error,
    this.needsEnrollment = false,
    required this.message,
  });
}

/// Authentication error types
enum AuthError {
  noStoredCredentials,
  biometricNotAvailable,
  biometricNotEnrolled,
  pinNotSet,
  invalidPin,
  authenticationFailed,
  lockedOut,
  alreadyEnrolled,
  apiError,
  unknown,
}

/// Available authentication methods
enum AuthMethod {
  biometric,
  pin,
}
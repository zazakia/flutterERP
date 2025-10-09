import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'secure_storage_service.dart';

/// Biometric authentication service using OS-level biometric APIs
class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _secureStorage;

  BiometricAuthService(this._secureStorage) : _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Authenticate user with biometrics
  Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Authenticate to access your account',
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
  }) async {
    try {
      // Check if biometrics are available
      if (!await isBiometricAvailable()) {
        return BiometricAuthResult(
          success: false,
          error: BiometricAuthError.notAvailable,
          message: 'Biometric authentication is not available on this device',
        );
      }

      // Check if account is locked out
      if (await _secureStorage.isLockedOut()) {
        final remainingTime = await _secureStorage.getRemainingLockoutTime();
        return BiometricAuthResult(
          success: false,
          error: BiometricAuthError.lockedOut,
          message: 'Account is temporarily locked. Try again in $remainingTime seconds',
        );
      }

      final availableTypes = await getAvailableBiometricTypes();
      if (availableTypes.isEmpty) {
        return BiometricAuthResult(
          success: false,
          error: BiometricAuthError.notEnrolled,
          message: 'No biometric credentials enrolled on this device',
        );
      }

      // Perform biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Reset failed attempts on successful authentication
        return BiometricAuthResult(
          success: true,
          message: 'Authentication successful',
        );
      } else {
        // Record failed attempt
        await _secureStorage.recordFailedAttempt();

        final failedAttempts = await _secureStorage.getFailedAttempts();
        if (failedAttempts >= 5) {
          return BiometricAuthResult(
            success: false,
            error: BiometricAuthError.lockedOut,
            message: 'Too many failed attempts. Account locked for 15 minutes',
          );
        }

        return BiometricAuthResult(
          success: false,
          error: BiometricAuthError.authenticationFailed,
          message: 'Authentication failed. $failedAttempts of 5 attempts used',
        );
      }
    } on PlatformException catch (e) {
      BiometricAuthError error;
      String message;

      switch (e.code) {
        case auth_error.notAvailable:
          error = BiometricAuthError.notAvailable;
          message = 'Biometric authentication is not available';
          break;
        case auth_error.notEnrolled:
          error = BiometricAuthError.notEnrolled;
          message = 'No biometric credentials enrolled';
          break;
        case auth_error.lockedOut:
          error = BiometricAuthError.lockedOut;
          message = 'Too many failed attempts. Biometric authentication disabled';
          break;
        case auth_error.permanentlyLockedOut:
          error = BiometricAuthError.permanentlyLockedOut;
          message = 'Biometric authentication permanently locked. Please contact support';
          break;
        case auth_error.otherOperatingSystem:
          error = BiometricAuthError.otherOperatingSystem;
          message = 'Biometric authentication not supported on this OS';
          break;
        default:
          error = BiometricAuthError.unknown;
          message = 'Unknown biometric authentication error: ${e.message}';
      }

      return BiometricAuthResult(
        success: false,
        error: error,
        message: message,
      );
    }
  }

  /// Enroll biometric authentication for user
  Future<BiometricAuthResult> enrollBiometric({
    required String userId,
    required String deviceId,
  }) async {
    try {
      // First authenticate to ensure user has access
      final authResult = await authenticateWithBiometrics(
        reason: 'Authenticate to enroll biometric credentials',
      );

      if (!authResult.success) {
        return authResult;
      }

      // Mark biometric as enrolled in secure storage
      await _secureStorage.setBiometricEnrolled(true);

      return BiometricAuthResult(
        success: true,
        message: 'Biometric authentication enrolled successfully',
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: BiometricAuthError.unknown,
        message: 'Failed to enroll biometric authentication: $e',
      );
    }
  }

  /// Check if biometric is enrolled for current user
  Future<bool> isBiometricEnrolled() async {
    return await _secureStorage.isBiometricEnrolled();
  }

  /// Get user-friendly biometric type names
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Biometric';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }

  /// Get user-friendly error messages
  String getErrorMessage(BiometricAuthError error) {
    switch (error) {
      case BiometricAuthError.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricAuthError.notEnrolled:
        return 'No biometric credentials are enrolled on this device';
      case BiometricAuthError.lockedOut:
        return 'Biometric authentication is temporarily disabled due to too many failed attempts';
      case BiometricAuthError.permanentlyLockedOut:
        return 'Biometric authentication is permanently locked. Please contact support';
      case BiometricAuthError.authenticationFailed:
        return 'Authentication failed. Please try again';
      case BiometricAuthError.otherOperatingSystem:
        return 'Biometric authentication is not supported on this operating system';
      case BiometricAuthError.unknown:
        return 'An unknown error occurred during biometric authentication';
    }
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool success;
  final BiometricAuthError? error;
  final String message;

  BiometricAuthResult({
    required this.success,
    this.error,
    required this.message,
  });
}

/// Biometric authentication error types
enum BiometricAuthError {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  authenticationFailed,
  otherOperatingSystem,
  unknown,
}
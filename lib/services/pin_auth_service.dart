import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// PIN authentication service as fallback when biometrics are unavailable
class PinAuthService {
  final SecureStorageService _secureStorage;
  Timer? _lockoutTimer;

  PinAuthService(this._secureStorage);

  /// Verify PIN against stored hash
  Future<PinAuthResult> verifyPin(String pin) async {
    try {
      // Check if PIN is set up
      if (!await _secureStorage.isPinSet()) {
        return PinAuthResult(
          success: false,
          error: PinAuthError.notSet,
          message: 'PIN is not set up on this device',
        );
      }

      // Check if account is locked out
      if (await _secureStorage.isLockedOut()) {
        final remainingTime = await _secureStorage.getRemainingLockoutTime();
        return PinAuthResult(
          success: false,
          error: PinAuthError.lockedOut,
          message: 'Account is temporarily locked. Try again in $remainingTime seconds',
        );
      }

      // Verify PIN
      final isValid = await _secureStorage.verifyPin(pin);

      if (isValid) {
        // Reset failed attempts on successful authentication
        return PinAuthResult(
          success: true,
          message: 'PIN authentication successful',
        );
      } else {
        // Record failed attempt
        await _secureStorage.recordFailedAttempt();

        final failedAttempts = await _secureStorage.getFailedAttempts();
        if (failedAttempts >= 5) {
          return PinAuthResult(
            success: false,
            error: PinAuthError.lockedOut,
            message: 'Too many failed attempts. Account locked for 15 minutes',
          );
        }

        return PinAuthResult(
          success: false,
          error: PinAuthError.invalidPin,
          message: 'Invalid PIN. $failedAttempts of 5 attempts used',
        );
      }
    } catch (e) {
      return PinAuthResult(
        success: false,
        error: PinAuthError.unknown,
        message: 'PIN verification failed: $e',
      );
    }
  }


  /// Change existing PIN
  Future<PinAuthResult> changePin(String currentPin, String newPin) async {
    try {
      // First verify current PIN
      final currentResult = await verifyPin(currentPin);
      if (!currentResult.success) {
        return currentResult;
      }

      // Validate new PIN format
      if (!_isValidPin(newPin)) {
        return PinAuthResult(
          success: false,
          error: PinAuthError.invalidFormat,
          message: 'New PIN must be 4-6 digits',
        );
      }

      // Hash and store new PIN
      final newPinHash = _hashPin(newPin);
      await _secureStorage.storePinHash(newPinHash);

      return PinAuthResult(
        success: true,
        message: 'PIN changed successfully',
      );
    } catch (e) {
      return PinAuthResult(
        success: false,
        error: PinAuthError.unknown,
        message: 'PIN change failed: $e',
      );
    }
  }

  /// Check if PIN is set up
  Future<bool> isPinSet() async {
    return await _secureStorage.isPinSet();
  }

  /// Get current failed attempts count
  Future<int> getFailedAttempts() async {
    return await _secureStorage.getFailedAttempts();
  }

  /// Check if account is locked out
  Future<bool> isLockedOut() async {
    return await _secureStorage.isLockedOut();
  }

  /// Get remaining lockout time
  Future<int> getRemainingLockoutTime() async {
    return await _secureStorage.getRemainingLockoutTime();
  }

  /// Hash PIN using SHA-256 (same as SecureStorageService)
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate PIN format (4-6 digits)
  bool _isValidPin(String pin) {
    final regex = RegExp(r'^\d{4,6}$');
    return regex.hasMatch(pin);
  }

  /// Get user-friendly error messages
  String getErrorMessage(PinAuthError error) {
    switch (error) {
      case PinAuthError.notSet:
        return 'PIN is not set up on this device';
      case PinAuthError.invalidPin:
        return 'Invalid PIN entered';
      case PinAuthError.invalidFormat:
        return 'PIN must be 4-6 digits';
      case PinAuthError.lockedOut:
        return 'Account is temporarily locked due to too many failed attempts';
      case PinAuthError.unknown:
        return 'An unknown error occurred during PIN authentication';
    }
  }

  /// Dispose of any active timers
  void dispose() {
    _lockoutTimer?.cancel();
  }
}

/// PIN authentication result
class PinAuthResult {
  final bool success;
  final PinAuthError? error;
  final String message;

  PinAuthResult({
    required this.success,
    this.error,
    required this.message,
  });
}

/// PIN authentication error types
enum PinAuthError {
  notSet,
  invalidPin,
  invalidFormat,
  lockedOut,
  unknown,
}
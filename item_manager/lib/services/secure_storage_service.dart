import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Secure storage service for handling sensitive authentication data
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';
  static const String _biometricEnrolledKey = 'biometric_enrolled';
  static const String _pinSetKey = 'pin_set';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lastFailedAttemptKey = 'last_failed_attempt';
  static const String _lockoutUntilKey = 'lockout_until';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  final Uuid _uuid;

  SecureStorageService(this._secureStorage, this._prefs)
      : _uuid = const Uuid();

  /// Initialize the secure storage service
  static Future<SecureStorageService> initialize() async {
    const secureStorage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Generate and store device ID if not exists
    String? deviceId = await secureStorage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await secureStorage.write(key: _deviceIdKey, value: deviceId);
    }

    return SecureStorageService(secureStorage, prefs);
  }

  /// Store authentication tokens securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: _userIdKey, value: userId);

    // Reset failed attempts on successful login
    await _prefs.remove(_failedAttemptsKey);
    await _prefs.remove(_lastFailedAttemptKey);
    await _prefs.remove(_lockoutUntilKey);
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Retrieve device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  /// Check if biometric is enrolled
  Future<bool> isBiometricEnrolled() async {
    final enrolled = await _secureStorage.read(key: _biometricEnrolledKey);
    return enrolled == 'true';
  }

  /// Set biometric enrollment status
  Future<void> setBiometricEnrolled(bool enrolled) async {
    await _secureStorage.write(
      key: _biometricEnrolledKey,
      value: enrolled.toString(),
    );
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final pinSet = await _secureStorage.read(key: _pinSetKey);
    return pinSet == 'true';
  }

  /// Set PIN status
  Future<void> setPinSet(bool set) async {
    await _secureStorage.write(key: _pinSetKey, value: set.toString());
  }

  /// Store PIN hash securely
  Future<void> storePinHash(String pinHash) async {
    await _secureStorage.write(key: _pinSetKey, value: pinHash);
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinSetKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if account is locked due to failed attempts
  Future<bool> isLockedOut() async {
    final lockoutUntil = await _prefs.getString(_lockoutUntilKey);
    if (lockoutUntil == null) return false;

    final lockoutTime = DateTime.parse(lockoutUntil);
    return DateTime.now().isBefore(lockoutTime);
  }

  /// Get remaining lockout time in seconds
  Future<int> getRemainingLockoutTime() async {
    final lockoutUntil = await _prefs.getString(_lockoutUntilKey);
    if (lockoutUntil == null) return 0;

    final lockoutTime = DateTime.parse(lockoutUntil);
    final now = DateTime.now();
    if (now.isAfter(lockoutTime)) return 0;

    return lockoutTime.difference(now).inSeconds;
  }

  /// Record failed authentication attempt
  Future<void> recordFailedAttempt() async {
    final now = DateTime.now();
    final failedAttempts = await _prefs.getInt(_failedAttemptsKey) ?? 0;
    final lastFailed = await _prefs.getString(_lastFailedAttemptKey);

    // Reset counter if it's been more than 5 minutes since last failure
    if (lastFailed != null) {
      final lastFailureTime = DateTime.parse(lastFailed);
      if (now.difference(lastFailureTime).inMinutes > 5) {
        await _prefs.setInt(_failedAttemptsKey, 1);
      } else {
        await _prefs.setInt(_failedAttemptsKey, failedAttempts + 1);
      }
    } else {
      await _prefs.setInt(_failedAttemptsKey, 1);
    }

    await _prefs.setString(_lastFailedAttemptKey, now.toIso8601String());

    // Lock account after 5 failed attempts
    if (failedAttempts >= 4) {
      final lockoutUntil = now.add(const Duration(minutes: 15));
      await _prefs.setString(_lockoutUntilKey, lockoutUntil.toIso8601String());
    }
  }

  /// Get current failed attempts count
  Future<int> getFailedAttempts() async {
    return await _prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Clear all stored authentication data
  Future<void> clearAllData() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _biometricEnrolledKey);
    await _secureStorage.delete(key: _pinSetKey);

    await _prefs.remove(_failedAttemptsKey);
    await _prefs.remove(_lastFailedAttemptKey);
    await _prefs.remove(_lockoutUntilKey);
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    final userId = await getUserId();
    return token != null && userId != null;
  }
}
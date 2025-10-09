import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  AuthenticationService? _authService;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _currentUserId;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  // Getters
  AuthenticationService? get authService => _authService;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  /// Initialize the authentication service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      _authService = await AuthenticationService.initialize();
      _isAuthenticated = await _authService!.isAuthenticated();
      _currentUserId = await _authService!.getCurrentUserId();
      _currentUser = await _authService!.getCurrentUser();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Failed to initialize authentication: $e');
      throw Exception('Authentication initialization failed');
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate with biometrics
  Future<AuthResult> authenticateWithBiometrics() async {
    if (_authService == null) {
      throw Exception('Authentication service not initialized');
    }

    _setLoading(true);

    try {
      final result = await _authService!.authenticateWithBiometrics();

      if (result.success) {
        await _refreshAuthState();
      }

      notifyListeners();
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate with PIN
  Future<AuthResult> authenticateWithPin(String pin) async {
    if (_authService == null) {
      throw Exception('Authentication service not initialized');
    }

    _setLoading(true);

    try {
      final result = await _authService!.authenticateWithPin(pin);

      if (result.success) {
        await _refreshAuthState();
      }

      notifyListeners();
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Enroll biometric authentication
  Future<AuthResult> enrollBiometric() async {
    if (_authService == null) {
      throw Exception('Authentication service not initialized');
    }

    _setLoading(true);

    try {
      final result = await _authService!.enrollBiometric();
      notifyListeners();
      return result;
    } finally {
      _setLoading(false);
    }
  }


  /// Check if biometric authentication is available
  Future<bool> canUseBiometricAuth() async {
    if (_authService == null) return false;
    return await _authService!.canUseBiometricAuth();
  }

  /// Check if PIN authentication is available
  Future<bool> canUsePinAuth() async {
    if (_authService == null) return false;
    return await _authService!.canUsePinAuth();
  }

  /// Get available authentication methods
  Future<List<AuthMethod>> getAvailableAuthMethods() async {
    if (_authService == null) return [];
    return await _authService!.getAvailableAuthMethods();
  }

  /// Logout user
  Future<void> logout() async {
    if (_authService == null) return;

    _setLoading(true);

    try {
      await _authService!.logout();
      await _refreshAuthState();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh authentication state
  Future<void> _refreshAuthState() async {
    if (_authService == null) return;

    _isAuthenticated = await _authService!.isAuthenticated();
    _currentUserId = await _authService!.getCurrentUserId();
    _currentUser = await _authService!.getCurrentUser();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Dispose of the provider
  @override
  void dispose() {
    _authService?.dispose();
    super.dispose();
  }
}
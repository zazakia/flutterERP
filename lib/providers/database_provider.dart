import 'package:flutter/foundation.dart';
import '../database/simple_database.dart';
import '../repositories/simple_employee_repository.dart';
import '../services/employee_api_service.dart';
import '../services/connectivity_service.dart';
import '../services/secure_storage_service.dart';

class DatabaseProvider extends ChangeNotifier {
  late SimpleEmployeeRepository _employeeRepository;
  late ConnectivityService _connectivityService;
  
  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _lastSyncError;
  DateTime? _lastSyncTime;

  SimpleEmployeeRepository get employeeRepository => _employeeRepository;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize database and repositories
  Future<void> initialize(SecureStorageService secureStorage) async {
    try {
      _connectivityService = ConnectivityService();
      
      final apiService = EmployeeApiService(secureStorage);
      _employeeRepository = SimpleEmployeeRepository(
        apiService,
        _connectivityService,
      );

      _isInitialized = true;
      notifyListeners();

      // Perform initial sync if connected
      await _performInitialSync();
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Perform initial sync with server
  Future<void> _performInitialSync() async {
    if (!await _connectivityService.isConnected()) {
      return; // Skip if offline
    }

    try {
      _isSyncing = true;
      _lastSyncError = null;
      notifyListeners();

      await _employeeRepository.syncWithServer();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manual sync trigger
  Future<void> syncWithServer() async {
    if (_isSyncing) return; // Prevent multiple simultaneous syncs

    try {
      _isSyncing = true;
      _lastSyncError = null;
      notifyListeners();

      await _employeeRepository.syncWithServer();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastSyncError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_isInitialized) {
      return {
        'pendingSync': 0,
        'isConnected': false,
        'lastSync': null,
      };
    }

    return await _employeeRepository.getSyncStatus();
  }

  /// Check connectivity status
  Future<bool> isConnected() async {
    return await _connectivityService.isConnected();
  }

  /// Clear all local data (useful for logout)
  Future<void> clearAllData() async {
    if (!_isInitialized) return;

    await SimpleDatabase.clearAllData();
    notifyListeners();
  }

  /// Close database connection
  @override
  Future<void> dispose() async {
    if (_isInitialized) {
      await SimpleDatabase.close();
    }
    super.dispose();
  }
}
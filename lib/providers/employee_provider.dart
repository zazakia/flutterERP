import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_api_service.dart';
import '../services/bulk_operations_service.dart';
import '../services/secure_storage_service.dart';
import '../repositories/simple_employee_repository.dart';
import '../providers/database_provider.dart';

/// Provider for employee management state
class EmployeeProvider extends ChangeNotifier {
  final EmployeeApiService _employeeApiService;
  final BulkOperationsService _bulkOperationsService;
  SimpleEmployeeRepository? _employeeRepository;
  final DatabaseProvider? _databaseProvider;

  EmployeeProvider(SecureStorageService secureStorage, [this._databaseProvider])
      : _employeeApiService = EmployeeApiService(secureStorage),
        _bulkOperationsService = BulkOperationsService(EmployeeApiService(secureStorage)) {
    
    // Initialize repository if database provider is available
    if (_databaseProvider?.isInitialized == true) {
      _employeeRepository = _databaseProvider!.employeeRepository;
    }
  }

  // State
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = true;

  // Search and filter state
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _employmentTypeFilter = 'All';

  // Getters
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;
  String get statusFilter => _statusFilter;
  String get employmentTypeFilter => _employmentTypeFilter;

  /// Load employees with pagination and filters (offline-first)
  Future<void> loadEmployees({
    bool refresh = false,
    int? page,
    String? search,
    String? role,
    bool? status,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _employees.clear();
      _hasMorePages = true;
    }

    if (page != null) {
      _currentPage = page;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Use repository if available (offline-first), otherwise fallback to API
      if (_employeeRepository != null) {
        final employees = await _employeeRepository!.getEmployees(
          search: search ?? (_searchQuery.isNotEmpty ? _searchQuery : null),
          role: role ?? (_roleFilter != 'All' ? _roleFilter : null),
          status: status ?? (_statusFilter != 'All'
              ? (_statusFilter == 'Active' ? true : false)
              : null),
        );

        if (refresh || _currentPage == 1) {
          _employees = employees;
        } else {
          _employees.addAll(employees);
        }

        // For local data, we don't have pagination, so set hasMorePages to false
        _hasMorePages = false;
      } else {
        // Fallback to API service
        final result = await _employeeApiService.getEmployees(
          page: _currentPage,
          limit: 50,
          search: search ?? (_searchQuery.isNotEmpty ? _searchQuery : null),
          role: role ?? (_roleFilter != 'All' ? _roleFilter : null),
          status: status ?? (_statusFilter != 'All'
              ? (_statusFilter == 'Active' ? true : false)
              : null),
        );

        result.fold(
          (employees) {
            if (refresh || _currentPage == 1) {
              _employees = employees;
            } else {
              _employees.addAll(employees);
            }

            // Check if there are more pages
            _hasMorePages = employees.length == 50;
            if (_hasMorePages) {
              _currentPage++;
            }
          },
          (error) => _setError(error.message),
        );
      }
    } catch (e) {
      _setError('Failed to load employees: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new employee (offline-first)
  Future<bool> createEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_employeeRepository != null) {
        // Use repository (offline-first)
        final createdEmployee = await _employeeRepository!.createEmployee(employee);
        _employees.insert(0, createdEmployee);
        notifyListeners();
        return true;
      } else {
        // Fallback to API service
        final result = await _employeeApiService.createEmployee(employee);

        return result.fold(
          (createdEmployee) {
            _employees.insert(0, createdEmployee);
            notifyListeners();
            return true;
          },
          (error) {
            _setError(error.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError('Failed to create employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing employee (offline-first)
  Future<bool> updateEmployee(String employeeId, Employee updatedEmployee) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_employeeRepository != null) {
        // Use repository (offline-first)
        final employee = await _employeeRepository!.updateEmployee(employeeId, updatedEmployee);
        final index = _employees.indexWhere((e) => e.employeeId == employeeId);
        if (index != -1) {
          _employees[index] = employee;
          notifyListeners();
        }
        return true;
      } else {
        // Fallback to API service
        final result = await _employeeApiService.updateEmployee(employeeId, updatedEmployee);

        return result.fold(
          (employee) {
            final index = _employees.indexWhere((e) => e.employeeId == employeeId);
            if (index != -1) {
              _employees[index] = employee;
              notifyListeners();
            }
            return true;
          },
          (error) {
            _setError(error.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError('Failed to update employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an employee (offline-first)
  Future<bool> deleteEmployee(String employeeId) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_employeeRepository != null) {
        // Use repository (offline-first)
        await _employeeRepository!.deleteEmployee(employeeId);
        _employees.removeWhere((e) => e.employeeId == employeeId);
        notifyListeners();
        return true;
      } else {
        // Fallback to API service
        final result = await _employeeApiService.deleteEmployee(employeeId);

        return result.fold(
          (_) {
            _employees.removeWhere((e) => e.employeeId == employeeId);
            notifyListeners();
            return true;
          },
          (error) {
            _setError(error.message);
            return false;
          },
        );
      }
    } catch (e) {
      _setError('Failed to delete employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bulk activate employees
  Future<BulkOperationResult?> bulkActivateEmployees(
    BuildContext context,
    List<String> employeeIds,
  ) async {
    try {
      final result = await _bulkOperationsService.bulkActivateEmployees(context, employeeIds);

      // Update local state
      for (final employeeId in employeeIds) {
        final index = _employees.indexWhere((e) => e.employeeId == employeeId);
        if (index != -1) {
          _employees[index] = _employees[index].copyWith(status: true);
        }
      }
      notifyListeners();

      return result;
    } catch (e) {
      _setError('Bulk activation failed: $e');
      return null;
    }
  }

  /// Bulk deactivate employees
  Future<BulkOperationResult?> bulkDeactivateEmployees(
    BuildContext context,
    List<String> employeeIds,
  ) async {
    try {
      final result = await _bulkOperationsService.bulkDeactivateEmployees(context, employeeIds);

      // Update local state
      for (final employeeId in employeeIds) {
        final index = _employees.indexWhere((e) => e.employeeId == employeeId);
        if (index != -1) {
          _employees[index] = _employees[index].copyWith(status: false);
        }
      }
      notifyListeners();

      return result;
    } catch (e) {
      _setError('Bulk deactivation failed: $e');
      return null;
    }
  }

  /// Import employees from CSV
  Future<ImportResult?> importEmployeesFromCsv(BuildContext context) async {
    try {
      final result = await _bulkOperationsService.importEmployeesFromCsv(context);

      // Refresh the employee list after import
      await loadEmployees(refresh: true);

      return result;
    } catch (e) {
      _setError('CSV import failed: $e');
      return null;
    }
  }

  /// Export employees to CSV
  Future<String?> exportEmployeesToCsv() async {
    try {
      return await _bulkOperationsService.exportEmployeesToCsv(_employees);
    } catch (e) {
      _setError('CSV export failed: $e');
      return null;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update role filter
  void updateRoleFilter(String role) {
    _roleFilter = role;
    notifyListeners();
  }

  /// Update status filter
  void updateStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Update employment type filter
  void updateEmploymentTypeFilter(String type) {
    _employmentTypeFilter = type;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _roleFilter = 'All';
    _statusFilter = 'All';
    _employmentTypeFilter = 'All';
    notifyListeners();
  }

  /// Get filtered employees (for local filtering)
  List<Employee> getFilteredEmployees() {
    return _employees.where((employee) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          employee.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee.role.toLowerCase().contains(_searchQuery.toLowerCase());

      // Role filter
      final matchesRole = _roleFilter == 'All' || employee.role == _roleFilter;

      // Status filter
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && employee.status) ||
          (_statusFilter == 'Inactive' && !employee.status);

      // Employment type filter
      final matchesEmploymentType = _employmentTypeFilter == 'All' ||
          employee.employmentType == _employmentTypeFilter;

      return matchesSearch && matchesRole && matchesStatus && matchesEmploymentType;
    }).toList();
  }

  /// Find employee by ID
  Employee? findEmployeeById(String employeeId) {
    return _employees.cast<Employee?>().firstWhere(
      (employee) => employee?.employeeId == employeeId,
      orElse: () => null,
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sync with server (manual trigger)
  Future<bool> syncWithServer() async {
    if (_employeeRepository == null) {
      _setError('Offline mode not available');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _employeeRepository!.syncWithServer();
      // Reload employees after sync
      await loadEmployees(refresh: true);
      return true;
    } catch (e) {
      _setError('Sync failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    if (_employeeRepository == null) return null;
    return await _employeeRepository!.getSyncStatus();
  }

  /// Check if offline mode is available
  bool get isOfflineModeAvailable => _employeeRepository != null;

  /// Dispose of resources
  @override
  void dispose() {
    _employeeApiService.dispose();
    super.dispose();
  }
}
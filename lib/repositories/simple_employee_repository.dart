import 'dart:convert';
import '../database/simple_database.dart';
import '../services/employee_api_service.dart';
import '../services/connectivity_service.dart';
import '../models/employee.dart';
import 'package:uuid/uuid.dart';

class SimpleEmployeeRepository {
  final EmployeeApiService _apiService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  SimpleEmployeeRepository(this._apiService, this._connectivityService);

  /// Get all employees (offline-first approach)
  Future<List<Employee>> getEmployees({
    String? search,
    String? role,
    bool? status,
  }) async {
    try {
      List<Map<String, dynamic>> dbEmployees;
      
      if (search != null && search.isNotEmpty) {
        dbEmployees = await SimpleDatabase.searchEmployees(search);
      } else {
        dbEmployees = await SimpleDatabase.getAllEmployees();
      }

      // Filter by role and status if specified
      if (role != null || status != null) {
        dbEmployees = dbEmployees.where((emp) {
          bool matchesRole = role == null || emp['role'] == role;
          bool matchesStatus = status == null || (emp['status'] == 1) == status;
          return matchesRole && matchesStatus;
        }).toList();
      }

      // Try to sync with server if online
      if (await _connectivityService.isConnected()) {
        _syncEmployeesInBackground();
      }

      return dbEmployees.map((map) => SimpleDatabase.mapToEmployee(map)).toList();
    } catch (e) {
      throw Exception('Failed to get employees: $e');
    }
  }

  /// Get employee by ID
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final dbEmployee = await SimpleDatabase.getEmployeeById(id);
      if (dbEmployee == null) return null;

      return SimpleDatabase.mapToEmployee(dbEmployee);
    } catch (e) {
      throw Exception('Failed to get employee: $e');
    }
  }

  /// Create new employee
  Future<Employee> createEmployee(Employee employee) async {
    try {
      final id = _uuid.v4();
      final employeeMap = SimpleDatabase.employeeToMap(employee, id);

      await SimpleDatabase.insertEmployee(employeeMap);

      // Add to sync queue
      await _addToSyncQueue('employees', id, 'insert', employee.toJson());

      // Try to sync immediately if online
      if (await _connectivityService.isConnected()) {
        await _syncEmployee(id);
      }

      return employee;
    } catch (e) {
      throw Exception('Failed to create employee: $e');
    }
  }

  /// Update employee
  Future<Employee> updateEmployee(String id, Employee employee) async {
    try {
      final employeeMap = SimpleDatabase.employeeToMap(employee, id);
      employeeMap['updatedAt'] = DateTime.now().toIso8601String();

      await SimpleDatabase.updateEmployee(id, employeeMap);

      // Add to sync queue
      await _addToSyncQueue('employees', id, 'update', employee.toJson());

      // Try to sync immediately if online
      if (await _connectivityService.isConnected()) {
        await _syncEmployee(id);
      }

      return employee;
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  /// Delete employee
  Future<void> deleteEmployee(String id) async {
    try {
      await SimpleDatabase.deleteEmployee(id);

      // Add to sync queue
      await _addToSyncQueue('employees', id, 'delete', null);

      // Try to sync immediately if online
      if (await _connectivityService.isConnected()) {
        await _syncEmployeeDeletion(id);
      }
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  /// Sync all pending changes with server
  Future<void> syncWithServer() async {
    if (!await _connectivityService.isConnected()) {
      throw Exception('No internet connection');
    }

    try {
      final pendingItems = await SimpleDatabase.getPendingSyncItems();
      
      for (final item in pendingItems) {
        if (item['tableName'] == 'employees') {
          switch (item['operation']) {
            case 'insert':
            case 'update':
              await _syncEmployee(item['recordId']);
              break;
            case 'delete':
              await _syncEmployeeDeletion(item['recordId']);
              break;
          }
        }
      }

      // Fetch latest data from server
      await _fetchEmployeesFromServer();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  /// Fetch employees from server and update local database
  Future<void> _fetchEmployeesFromServer() async {
    try {
      final result = await _apiService.getEmployees();
      
      result.fold(
        (serverEmployees) async {
          // Clear existing data and insert fresh data
          await SimpleDatabase.clearAllData();
          
          for (final emp in serverEmployees) {
            final id = _uuid.v4();
            final employeeMap = SimpleDatabase.employeeToMap(emp, id);
            employeeMap['needsSync'] = 0; // Mark as synced
            await SimpleDatabase.insertEmployee(employeeMap);
          }
        },
        (error) {
          // Log error but don't throw - offline data is still available
          print('Failed to fetch from server: ${error.message}');
        },
      );
    } catch (e) {
      // Log error but don't throw - offline data is still available
      print('Failed to fetch from server: $e');
    }
  }

  /// Sync individual employee with server
  Future<void> _syncEmployee(String id) async {
    try {
      final dbEmployee = await SimpleDatabase.getEmployeeById(id);
      if (dbEmployee == null) return;

      final modelEmployee = SimpleDatabase.mapToEmployee(dbEmployee);
      
      if (dbEmployee['needsSync'] == 1) {
        // Try to update first
        final result = await _apiService.updateEmployee(modelEmployee.employeeId, modelEmployee);
        
        result.fold(
          (updatedEmployee) async {
            // Mark as synced
            await SimpleDatabase.updateEmployee(id, {'needsSync': 0});
          },
          (error) async {
            if (error.code == 'NOT_FOUND') {
              // Employee doesn't exist on server, create it
              final createResult = await _apiService.createEmployee(modelEmployee);
              createResult.fold(
                (createdEmployee) async {
                  await SimpleDatabase.updateEmployee(id, {'needsSync': 0});
                },
                (createError) {
                  print('Failed to create employee on server: ${createError.message}');
                },
              );
            } else {
              print('Failed to sync employee: ${error.message}');
            }
          },
        );
      }
    } catch (e) {
      print('Failed to sync employee $id: $e');
    }
  }

  /// Sync employee deletion with server
  Future<void> _syncEmployeeDeletion(String id) async {
    try {
      // For deletion, we need to get the employeeId from sync queue data
      final pendingItems = await SimpleDatabase.getPendingSyncItems();
      final deleteItem = pendingItems.firstWhere(
        (item) => item['recordId'] == id && item['operation'] == 'delete',
        orElse: () => <String, dynamic>{},
      );

      if (deleteItem.isNotEmpty && deleteItem['data'] != null) {
        final employeeData = jsonDecode(deleteItem['data']);
        final result = await _apiService.deleteEmployee(employeeData['employeeId']);
        
        result.fold(
          (_) async {
            await SimpleDatabase.markAsSynced(deleteItem['id']);
          },
          (error) {
            print('Failed to delete employee on server: ${error.message}');
          },
        );
      }
    } catch (e) {
      print('Failed to sync employee deletion $id: $e');
    }
  }

  /// Sync employees in background
  Future<void> _syncEmployeesInBackground() async {
    try {
      await _fetchEmployeesFromServer();
      await syncWithServer();
    } catch (e) {
      // Silent fail for background sync
      print('Background sync failed: $e');
    }
  }

  /// Add item to sync queue
  Future<void> _addToSyncQueue(String tableName, String recordId, String operation, Map<String, dynamic>? data) async {
    final syncItem = {
      'id': _uuid.v4(),
      'tableName': tableName,
      'recordId': recordId,
      'operation': operation,
      'data': data != null ? jsonEncode(data) : null,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
      'retryCount': 0,
      'lastRetry': null,
    };

    await SimpleDatabase.addToSyncQueue(syncItem);
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingItems = await SimpleDatabase.getPendingSyncItems();
    final isConnected = await _connectivityService.isConnected();
    
    return {
      'pendingSync': pendingItems.length,
      'isConnected': isConnected,
      'lastSync': DateTime.now().toIso8601String(),
    };
  }
}
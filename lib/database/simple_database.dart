import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/employee.dart';

class SimpleDatabase {
  static Database? _database;
  static const String _databaseName = 'flutter_erp.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String employeesTable = 'employees';
  static const String syncQueueTable = 'sync_queue';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create employees table
    await db.execute('''
      CREATE TABLE $employeesTable (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        employmentType TEXT NOT NULL,
        salaryRate REAL NOT NULL,
        payType TEXT NOT NULL,
        taxId TEXT NOT NULL,
        accountNumber TEXT,
        routingNumber TEXT,
        bankName TEXT,
        status INTEGER NOT NULL DEFAULT 1,
        avatar TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        needsSync INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create sync queue table
    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id TEXT PRIMARY KEY,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        createdAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        retryCount INTEGER NOT NULL DEFAULT 0,
        lastRetry TEXT
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_employees_email ON $employeesTable(email)');
    await db.execute('CREATE INDEX idx_employees_status ON $employeesTable(status)');
    await db.execute('CREATE INDEX idx_sync_queue_synced ON $syncQueueTable(synced)');
  }

  // Employee operations
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final db = await database;
    return await db.query(employeesTable, orderBy: 'createdAt DESC');
  }

  static Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    final db = await database;
    final results = await db.query(
      employeesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final db = await database;
    return await db.query(
      employeesTable,
      where: 'firstName LIKE ? OR lastName LIKE ? OR email LIKE ? OR employeeId LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
  }

  static Future<int> insertEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    return await db.insert(employeesTable, employee);
  }

  static Future<int> updateEmployee(String id, Map<String, dynamic> employee) async {
    final db = await database;
    return await db.update(
      employeesTable,
      employee,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteEmployee(String id) async {
    final db = await database;
    return await db.delete(
      employeesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync queue operations
  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      syncQueueTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  static Future<int> addToSyncQueue(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(syncQueueTable, item);
  }

  static Future<int> markAsSynced(String id) async {
    final db = await database;
    return await db.update(
      syncQueueTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> clearSyncedItems() async {
    final db = await database;
    return await db.delete(
      syncQueueTable,
      where: 'synced = ?',
      whereArgs: [1],
    );
  }

  // Utility methods
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(employeesTable);
    await db.delete(syncQueueTable);
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Helper methods to convert between Employee model and database
  static Map<String, dynamic> employeeToMap(Employee employee, String id) {
    return {
      'id': id,
      'employeeId': employee.employeeId,
      'firstName': employee.firstName,
      'lastName': employee.lastName,
      'email': employee.email,
      'role': employee.role,
      'employmentType': employee.employmentType,
      'salaryRate': employee.salaryRate,
      'payType': employee.payType,
      'taxId': employee.taxId,
      'accountNumber': employee.accountNumber,
      'routingNumber': employee.routingNumber,
      'bankName': employee.bankName,
      'status': employee.status ? 1 : 0,
      'avatar': employee.avatar,
      'createdAt': employee.createdAt.toIso8601String(),
      'updatedAt': employee.updatedAt.toIso8601String(),
      'needsSync': 1,
    };
  }

  static Employee mapToEmployee(Map<String, dynamic> map) {
    return Employee(
      employeeId: map['employeeId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      role: map['role'],
      employmentType: map['employmentType'],
      salaryRate: map['salaryRate'],
      payType: map['payType'],
      taxId: map['taxId'],
      accountNumber: map['accountNumber'],
      routingNumber: map['routingNumber'],
      bankName: map['bankName'],
      status: map['status'] == 1,
      avatar: map['avatar'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
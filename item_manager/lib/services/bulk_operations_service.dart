import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/employee.dart';
import 'employee_api_service.dart';

/// Service for handling bulk employee operations
class BulkOperationsService {
  final EmployeeApiService _employeeApiService;

  BulkOperationsService(this._employeeApiService);

  /// Bulk activate employees
  Future<BulkOperationResult> bulkActivateEmployees(
    BuildContext context,
    List<String> employeeIds,
  ) async {
    try {
      final result = await _employeeApiService.bulkActivateEmployees(employeeIds);

      return result.fold(
        (success) => success,
        (error) => throw Exception(error.message),
      );
    } catch (e) {
      throw Exception('Failed to activate employees: $e');
    }
  }

  /// Bulk deactivate employees
  Future<BulkOperationResult> bulkDeactivateEmployees(
    BuildContext context,
    List<String> employeeIds,
  ) async {
    try {
      final result = await _employeeApiService.bulkDeactivateEmployees(employeeIds);

      return result.fold(
        (success) => success,
        (error) => throw Exception(error.message),
      );
    } catch (e) {
      throw Exception('Failed to deactivate employees: $e');
    }
  }

  /// Import employees from CSV file
  Future<ImportResult> importEmployeesFromCsv(BuildContext context) async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.first.path!);
      final csvData = await file.readAsString();

      // Validate CSV format
      final validationResult = _validateCsvFormat(csvData);
      if (!validationResult.isValid) {
        throw Exception('Invalid CSV format: ${validationResult.error}');
      }

      // Import via API
      final importResult = await _employeeApiService.importEmployeesFromCsv(csvData);

      return importResult.fold(
        (success) => success,
        (error) => throw Exception(error.message),
      );
    } catch (e) {
      throw Exception('Failed to import employees: $e');
    }
  }

  /// Export employees to CSV
  Future<String> exportEmployeesToCsv(List<Employee> employees) async {
    try {
      final csvData = _generateCsvFromEmployees(employees);

      // For now, return the CSV data
      // In a real app, you might want to save to file or share
      return csvData;
    } catch (e) {
      throw Exception('Failed to export employees: $e');
    }
  }

  /// Validate CSV format and content
  CsvValidationResult _validateCsvFormat(String csvData) {
    try {
      final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        return CsvValidationResult(false, 'CSV file is empty');
      }

      // Check header
      final header = lines[0].toLowerCase().split(',');
      final requiredHeaders = [
        'employeeid', 'firstname', 'lastname', 'email', 'role',
        'employmenttype', 'salaryrate', 'paytype', 'taxid'
      ];

      for (final required in requiredHeaders) {
        if (!header.contains(required)) {
          return CsvValidationResult(false, 'Missing required column: $required');
        }
      }

      // Validate data rows
      for (var i = 1; i < lines.length; i++) {
        final row = lines[i].split(',');
        if (row.length < requiredHeaders.length) {
          return CsvValidationResult(false, 'Row ${i + 1} has insufficient columns');
        }

        // Basic validation
        final employeeId = row[header.indexOf('employeeid')].trim();
        final firstName = row[header.indexOf('firstname')].trim();
        final lastName = row[header.indexOf('lastname')].trim();
        final email = row[header.indexOf('email')].trim();
        final salaryRate = row[header.indexOf('salaryrate')].trim();

        if (employeeId.isEmpty || firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
          return CsvValidationResult(false, 'Row ${i + 1} has empty required fields');
        }

        if (double.tryParse(salaryRate) == null) {
          return CsvValidationResult(false, 'Row ${i + 1} has invalid salary rate');
        }
      }

      return CsvValidationResult(true, '');
    } catch (e) {
      return CsvValidationResult(false, 'Error parsing CSV: $e');
    }
  }

  /// Generate CSV from employee list
  String _generateCsvFromEmployees(List<Employee> employees) {
    final headers = [
      'EmployeeID',
      'FirstName',
      'LastName',
      'Email',
      'Role',
      'EmploymentType',
      'SalaryRate',
      'PayType',
      'TaxID',
      'AccountNumber',
      'RoutingNumber',
      'BankName',
      'Status',
      'CreatedAt',
      'UpdatedAt'
    ];

    final csvRows = [headers.join(',')];

    for (final employee in employees) {
      final row = [
        employee.employeeId,
        employee.firstName,
        employee.lastName,
        employee.email,
        employee.role,
        employee.employmentType,
        employee.salaryRate.toString(),
        employee.payType,
        employee.taxId,
        employee.accountNumber ?? '',
        employee.routingNumber ?? '',
        employee.bankName ?? '',
        employee.status.toString(),
        employee.createdAt.toIso8601String(),
        employee.updatedAt.toIso8601String(),
      ];

      // Escape commas and quotes in fields
      final escapedRow = row.map((field) {
        if (field.contains(',') || field.contains('"') || field.contains('\n')) {
          return '"${field.replaceAll('"', '""')}"';
        }
        return field;
      });

      csvRows.add(escapedRow.join(','));
    }

    return csvRows.join('\n');
  }

  /// Show bulk operation confirmation dialog
  static Future<bool?> showBulkOperationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show bulk operation result dialog
  static Future<void> showBulkOperationResult(
    BuildContext context,
    BulkOperationResult result, {
    required String operation,
  }) {
    final successMessage = result.successCount > 0
        ? '${result.successCount} employee${result.successCount == 1 ? '' : 's'} $operation successfully.'
        : null;

    final failureMessage = result.failureCount > 0
        ? '${result.failureCount} employee${result.failureCount == 1 ? '' : 's'} failed to $operation.'
        : null;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk $operation Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (successMessage != null)
              Text(
                successMessage,
                style: const TextStyle(color: Colors.green),
              ),
            if (failureMessage != null)
              Text(
                failureMessage,
                style: const TextStyle(color: Colors.red),
              ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.errors.map((error) => Text(
                '• $error',
                style: const TextStyle(fontSize: 12),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show CSV import result dialog
  static Future<void> showImportResult(
    BuildContext context,
    ImportResult result,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Import Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.importedCount} employee${result.importedCount == 1 ? '' : 's'} imported successfully.',
              style: const TextStyle(color: Colors.green),
            ),
            if (result.skippedCount > 0)
              Text(
                '${result.skippedCount} employee${result.skippedCount == 1 ? '' : 's'} skipped.',
                style: const TextStyle(color: Colors.orange),
              ),
            if (result.errorCount > 0)
              Text(
                '${result.errorCount} employee${result.errorCount == 1 ? '' : 's'} failed to import.',
                style: const TextStyle(color: Colors.red),
              ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.errors.map((error) => Text(
                '• $error',
                style: const TextStyle(fontSize: 12),
              )),
            ],
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Warnings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.warnings.map((warning) => Text(
                '• $warning',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// CSV validation result
class CsvValidationResult {
  final bool isValid;
  final String error;

  CsvValidationResult(this.isValid, this.error);
}
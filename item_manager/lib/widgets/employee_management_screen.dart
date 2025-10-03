import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../providers/auth_provider.dart';
import 'employee_list_widget.dart';
import 'employee_form_widget.dart';
import 'employee_profile_widget.dart';

/// Screen for managing employees - list, add, edit, view
class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load employees when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          // Bulk operations menu
          PopupMenuButton<String>(
            onSelected: _handleBulkOperation,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_activate',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Bulk Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_deactivate',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Bulk Deactivate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Import CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, employeeProvider, child) {
          if (employeeProvider.isLoading && employeeProvider.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employeeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${employeeProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => employeeProvider.loadEmployees(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return EmployeeListWidget(
            employees: employeeProvider.getFilteredEmployees(),
            userRole: _getCurrentUserRole(),
            onEmployeeTap: _viewEmployeeProfile,
            onAddEmployee: _addEmployee,
            onEditEmployee: _editEmployee,
            onDeleteEmployee: _deleteEmployee,
          );
        },
      ),
    );
  }

  String? _getCurrentUserRole() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    return user?['role'] as String?;
  }

  void _viewEmployeeProfile(Employee employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeProfileWidget(
          employee: employee,
          userRole: _getCurrentUserRole(),
          isCurrentUser: employee.employeeId == context.read<AuthProvider>().currentUserId,
          onEdit: () => _editEmployee(employee),
          onDelete: () => _deleteEmployee(employee),
        ),
      ),
    );
  }

  void _addEmployee() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeFormWidget(
          onSave: (employee) async {
            final success = await context.read<EmployeeProvider>().createEmployee(employee);
            if (success && mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee created successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  void _editEmployee(Employee employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeFormWidget(
          employee: employee,
          onSave: (updatedEmployee) async {
            final success = await context.read<EmployeeProvider>().updateEmployee(
              employee.employeeId,
              updatedEmployee,
            );
            if (success && mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee updated successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<EmployeeProvider>().deleteEmployee(employee.employeeId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted successfully')),
        );
      }
    }
  }

  void _handleBulkOperation(String operation) async {
    final employeeProvider = context.read<EmployeeProvider>();
    final selectedEmployees = employeeProvider.getFilteredEmployees();

    if (selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees to perform bulk operation on')),
      );
      return;
    }

    // For now, show a simple selection dialog
    // In a real app, you'd have a multi-select interface
    final employeeIds = selectedEmployees.map((e) => e.employeeId).toList();

    switch (operation) {
      case 'bulk_activate':
        final confirmed = await _showBulkConfirmationDialog(
          'Bulk Activate',
          'Activate ${employeeIds.length} employee${employeeIds.length == 1 ? '' : 's'}?',
          Colors.green,
        );
        if (confirmed == true) {
          final result = await employeeProvider.bulkActivateEmployees(context, employeeIds);
          if (result != null && mounted) {
            await _showBulkResultDialog('Bulk Activate', result);
          }
        }
        break;

      case 'bulk_deactivate':
        final confirmed = await _showBulkConfirmationDialog(
          'Bulk Deactivate',
          'Deactivate ${employeeIds.length} employee${employeeIds.length == 1 ? '' : 's'}?',
          Colors.red,
        );
        if (confirmed == true) {
          final result = await employeeProvider.bulkDeactivateEmployees(context, employeeIds);
          if (result != null && mounted) {
            await _showBulkResultDialog('Bulk Deactivate', result);
          }
        }
        break;

      case 'import_csv':
        final result = await employeeProvider.importEmployeesFromCsv(context);
        if (result != null && mounted) {
          await _showImportResultDialog(result);
        }
        break;

      case 'export_csv':
        final csvData = await employeeProvider.exportEmployeesToCsv();
        if (csvData != null && mounted) {
          // In a real app, you'd save this to a file or share it
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV export completed')),
          );
        }
        break;
    }
  }

  Future<bool?> _showBulkConfirmationDialog(String title, String message, Color color) {
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
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(title.split(' ')[1]), // Extract action word
          ),
        ],
      ),
    );
  }

  Future<void> _showBulkResultDialog(String operation, BulkOperationResult result) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.successCount} successful'),
            Text('${result.failureCount} failed'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error')),
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

  Future<void> _showImportResultDialog(ImportResult result) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Import Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.importedCount} imported'),
            Text('${result.skippedCount} skipped'),
            Text('${result.errorCount} errors'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error')),
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
import 'package:flutter/material.dart';
import '../models/payroll.dart';
import '../services/payroll_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for payroll management state
class PayrollProvider extends ChangeNotifier {
  final PayrollService _payrollService;

  PayrollProvider(SecureStorageService secureStorage)
      : _payrollService = PayrollService(secureStorage);

  // State
  List<Payroll> _payrollRecords = [];
  Payroll? _currentPayroll;
  Map<String, dynamic>? _payrollSummary;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Getters
  List<Payroll> get payrollRecords => _payrollRecords;
  Payroll? get currentPayroll => _currentPayroll;
  Map<String, dynamic>? get payrollSummary => _payrollSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;

  /// Load payroll records for current user
  Future<void> loadPayrollRecords({
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
    int? page,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _payrollRecords.clear();
      _hasMorePages = true;
    }

    if (page != null) {
      _currentPage = page;
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _payrollService.getPayrollRecords(
        startDate: startDate,
        endDate: endDate,
        page: _currentPage,
        limit: 50,
      );

      result.fold(
        (payrolls) {
          if (refresh || _currentPage == 1) {
            _payrollRecords = payrolls;
          } else {
            _payrollRecords.addAll(payrolls);
          }

          // Check if there are more pages
          _hasMorePages = payrolls.length == 50;
          if (_hasMorePages) {
            _currentPage++;
          }
          notifyListeners();
        },
        (error) {
          _setError(error.message);
        },
      );
    } catch (e) {
      _setError('Failed to load payroll records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load a specific payroll record
  Future<bool> loadPayrollRecord(String payrollId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _payrollService.getPayrollRecord(payrollId);

      return result.fold(
        (payroll) {
          _currentPayroll = payroll;
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to load payroll record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate payroll for an employee (admin/payroll only)
  Future<bool> generatePayroll({
    required String employeeId,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    double? bonus,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _payrollService.generatePayroll(
        employeeId: employeeId,
        payPeriodStart: payPeriodStart,
        payPeriodEnd: payPeriodEnd,
        bonus: bonus,
        notes: notes,
      );

      return result.fold(
        (payroll) {
          _payrollRecords.insert(0, payroll);
          // If we're viewing this employee's payroll, update current
          if (_currentPayroll?.employeeId == employeeId) {
            _currentPayroll = payroll;
          }
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to generate payroll: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update payroll record status (admin/payroll only)
  Future<bool> updatePayrollStatus(String payrollId, String status) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _payrollService.updatePayrollStatus(payrollId, status);

      return result.fold(
        (payroll) {
          // Update in the list
          final index = _payrollRecords.indexWhere((p) => p.id == payrollId);
          if (index != -1) {
            _payrollRecords[index] = payroll;
          }
          // Update current if it's the same
          if (_currentPayroll?.id == payrollId) {
            _currentPayroll = payroll;
          }
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to update payroll status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load payroll summary for dashboard
  Future<void> loadPayrollSummary() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _payrollService.getPayrollSummary();

      result.fold(
        (summary) {
          _payrollSummary = summary;
          notifyListeners();
        },
        (error) {
          _setError(error.message);
        },
      );
    } catch (e) {
      _setError('Failed to load payroll summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Calculate total earnings for a list of payrolls
  double calculateTotalEarnings(List<Payroll> payrolls) {
    return payrolls.fold(0.0, (sum, payroll) => sum + payroll.netPay);
  }

  /// Calculate average earnings
  double calculateAverageEarnings(List<Payroll> payrolls) {
    if (payrolls.isEmpty) return 0.0;
    return calculateTotalEarnings(payrolls) / payrolls.length;
  }

  /// Filter payrolls by status
  List<Payroll> filterPayrollsByStatus(List<Payroll> payrolls, String status) {
    return payrolls.where((payroll) => payroll.status == status).toList();
  }

  /// Filter payrolls by date range
  List<Payroll> filterPayrollsByDateRange(
      List<Payroll> payrolls, DateTime startDate, DateTime endDate) {
    return payrolls
        .where((payroll) =>
            payroll.payDate.isAfter(startDate) && payroll.payDate.isBefore(endDate))
        .toList();
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

  /// Dispose of resources
  @override
  void dispose() {
    _payrollService.dispose();
    super.dispose();
  }
}
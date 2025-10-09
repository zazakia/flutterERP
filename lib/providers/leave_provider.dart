import 'package:flutter/material.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for leave management state
class LeaveProvider extends ChangeNotifier {
  final LeaveService _leaveService;

  LeaveProvider(SecureStorageService secureStorage)
      : _leaveService = LeaveService(secureStorage);

  // State
  List<LeaveRequest> _myLeaveRequests = [];
  List<LeaveRequest> _allLeaveRequests = [];
  Map<String, dynamic>? _leaveBalance;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = true;

  // Getters
  List<LeaveRequest> get myLeaveRequests => _myLeaveRequests;
  List<LeaveRequest> get allLeaveRequests => _allLeaveRequests;
  Map<String, dynamic>? get leaveBalance => _leaveBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;

  /// Load current user's leave requests
  Future<void> loadMyLeaveRequests({
    bool refresh = false,
    int? page,
    String? status,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _myLeaveRequests.clear();
      _hasMorePages = true;
    }

    if (page != null) {
      _currentPage = page;
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.getMyLeaveRequests(
        page: _currentPage,
        limit: 50,
        status: status,
      );

      result.fold(
        (leaveRequests) {
          if (refresh || _currentPage == 1) {
            _myLeaveRequests = leaveRequests;
          } else {
            _myLeaveRequests.addAll(leaveRequests);
          }

          // Check if there are more pages
          _hasMorePages = leaveRequests.length == 50;
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
      _setError('Failed to load leave requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all leave requests (for managers/admins)
  Future<void> loadAllLeaveRequests({
    bool refresh = false,
    int? page,
    String? status,
    String? employeeId,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _allLeaveRequests.clear();
      _hasMorePages = true;
    }

    if (page != null) {
      _currentPage = page;
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.getAllLeaveRequests(
        page: _currentPage,
        limit: 50,
        status: status,
        employeeId: employeeId,
      );

      result.fold(
        (leaveRequests) {
          if (refresh || _currentPage == 1) {
            _allLeaveRequests = leaveRequests;
          } else {
            _allLeaveRequests.addAll(leaveRequests);
          }

          // Check if there are more pages
          _hasMorePages = leaveRequests.length == 50;
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
      _setError('Failed to load leave requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new leave request
  Future<bool> createLeaveRequest(LeaveRequest leaveRequest) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.createLeaveRequest(leaveRequest);

      return result.fold(
        (createdLeaveRequest) {
          _myLeaveRequests.insert(0, createdLeaveRequest);
          // If we're viewing all requests, add to that list too
          _allLeaveRequests.insert(0, createdLeaveRequest);
          notifyListeners();
          return true;
        },
        (error) {
          _setError(error.message);
          return false;
        },
      );
    } catch (e) {
      _setError('Failed to create leave request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Approve a leave request
  Future<bool> approveLeaveRequest(String leaveId, {String? approverId}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.approveLeaveRequest(leaveId, approverId: approverId);

      return result.fold(
        (approvedLeaveRequest) {
          // Update in both lists
          final myIndex = _myLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (myIndex != -1) {
            _myLeaveRequests[myIndex] = approvedLeaveRequest;
          }

          final allIndex = _allLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (allIndex != -1) {
            _allLeaveRequests[allIndex] = approvedLeaveRequest;
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
      _setError('Failed to approve leave request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reject a leave request
  Future<bool> rejectLeaveRequest(String leaveId, String reason, {String? approverId}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.rejectLeaveRequest(leaveId, reason, approverId: approverId);

      return result.fold(
        (rejectedLeaveRequest) {
          // Update in both lists
          final myIndex = _myLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (myIndex != -1) {
            _myLeaveRequests[myIndex] = rejectedLeaveRequest;
          }

          final allIndex = _allLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (allIndex != -1) {
            _allLeaveRequests[allIndex] = rejectedLeaveRequest;
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
      _setError('Failed to reject leave request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a leave request
  Future<bool> cancelLeaveRequest(String leaveId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.cancelLeaveRequest(leaveId);

      return result.fold(
        (cancelledLeaveRequest) {
          // Update in both lists
          final myIndex = _myLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (myIndex != -1) {
            _myLeaveRequests[myIndex] = cancelledLeaveRequest;
          }

          final allIndex = _allLeaveRequests.indexWhere((lr) => lr.id == leaveId);
          if (allIndex != -1) {
            _allLeaveRequests[allIndex] = cancelledLeaveRequest;
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
      _setError('Failed to cancel leave request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load leave balance for current user
  Future<void> loadLeaveBalance() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _leaveService.getLeaveBalance();

      result.fold(
        (balance) {
          _leaveBalance = balance;
          notifyListeners();
        },
        (error) {
          _setError(error.message);
        },
      );
    } catch (e) {
      _setError('Failed to load leave balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter leave requests by status
  List<LeaveRequest> filterLeaveRequestsByStatus(List<LeaveRequest> requests, String status) {
    if (status == 'all') return requests;
    return requests.where((request) => request.status == status).toList();
  }

  /// Filter leave requests by date range
  List<LeaveRequest> filterLeaveRequestsByDateRange(
      List<LeaveRequest> requests, DateTime startDate, DateTime endDate) {
    return requests
        .where((request) =>
            (request.startDate.isAfter(startDate) || request.startDate.isAtSameMomentAs(startDate)) &&
            (request.endDate.isBefore(endDate) || request.endDate.isAtSameMomentAs(endDate)))
        .toList();
  }

  /// Calculate total leave days taken
  int calculateTotalLeaveDaysTaken(List<LeaveRequest> requests) {
    return requests
        .where((request) => request.isApproved)
        .fold(0, (sum, request) => sum + request.numberOfDays);
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
    _leaveService.dispose();
    super.dispose();
  }
}
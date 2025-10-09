import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request.dart';
import '../providers/leave_provider.dart';
import '../providers/auth_provider.dart';
import 'leave_request_form.dart';
import 'leave_request_list.dart';

/// Screen for managing leave requests
class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final leaveProvider = context.read<LeaveProvider>();
      leaveProvider.loadMyLeaveRequests(refresh: true);
      leaveProvider.loadLeaveBalance();
      
      // If user is admin or HR, also load all leave requests
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.currentUser?['role'] as String?;
      if (role == 'Admin' || role == 'HR') {
        leaveProvider.loadAllLeaveRequests(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leave Management'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Requests'),
              Tab(text: 'Team Requests'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showNewLeaveRequestForm,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              children: [
                // My Requests Tab
                _buildMyRequestsTab(),
                
                // Team Requests Tab
                _buildTeamRequestsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return Consumer2<LeaveProvider, AuthProvider>(
      builder: (context, leaveProvider, authProvider, child) {
        if (leaveProvider.isLoading && leaveProvider.myLeaveRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leaveProvider.error != null) {
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
                  'Error: ${leaveProvider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => leaveProvider.loadMyLeaveRequests(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await leaveProvider.loadMyLeaveRequests(refresh: true);
            await leaveProvider.loadLeaveBalance();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leave Balance Card
                if (leaveProvider.leaveBalance != null)
                  _buildLeaveBalanceCard(leaveProvider.leaveBalance!),
                
                const SizedBox(height: 24),

                // Leave Requests List
                LeaveRequestList(
                  leaveRequests: leaveProvider.myLeaveRequests,
                  onTap: _viewLeaveRequestDetails,
                  onCancel: _cancelLeaveRequest,
                  currentUserId: authProvider.currentUserId,
                  currentUserRole: authProvider.currentUser?['role'] as String?,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamRequestsTab() {
    return Consumer2<LeaveProvider, AuthProvider>(
      builder: (context, leaveProvider, authProvider, child) {
        final role = authProvider.currentUser?['role'] as String?;
        final isManager = role == 'Admin' || role == 'HR';

        if (!isManager) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Access restricted to managers only',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (leaveProvider.isLoading && leaveProvider.allLeaveRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leaveProvider.error != null) {
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
                  'Error: ${leaveProvider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => leaveProvider.loadAllLeaveRequests(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await leaveProvider.loadAllLeaveRequests(refresh: true);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LeaveRequestList(
              leaveRequests: leaveProvider.allLeaveRequests,
              onApprove: _approveLeaveRequest,
              onReject: _rejectLeaveRequest,
              onTap: _viewLeaveRequestDetails,
              showActions: true,
              currentUserRole: authProvider.currentUser?['role'] as String?,
              currentUserId: authProvider.currentUserId,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveBalanceCard(Map<String, dynamic> balance) {
    final total = balance['total'] as int? ?? 0;
    final used = balance['used'] as int? ?? 0;
    final remaining = total - used;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Balance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBalanceItem('Total', '$total', Colors.white),
              _buildBalanceItem('Used', '$used', Colors.red.shade200),
              _buildBalanceItem('Remaining', '$remaining', Colors.green.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _showNewLeaveRequestForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaveRequestForm(
          onSave: _handleCreateLeaveRequest,
        ),
      ),
    );
  }

  Future<void> _handleCreateLeaveRequest(LeaveRequest leaveRequest) async {
    final leaveProvider = context.read<LeaveProvider>();
    final success = await leaveProvider.createLeaveRequest(leaveRequest);
    
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            leaveProvider.error ?? 'Failed to submit leave request',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewLeaveRequestDetails(LeaveRequest request) {
    // For now, we'll just show a dialog with details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getLeaveTypeDisplayName(request.leaveType)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${request.employeeName}'),
            const SizedBox(height: 8),
            Text('Dates: ${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}'),
            const SizedBox(height: 8),
            Text('Days: ${request.numberOfDays}'),
            const SizedBox(height: 8),
            Text('Status: ${request.status.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Reason: ${request.reason}'),
            if (request.isApproved && request.approverName != null) ...[
              const SizedBox(height: 8),
              Text('Approved by: ${request.approverName}'),
            ] else if (request.isRejected && request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text('Rejection reason: ${request.rejectionReason}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveLeaveRequest(LeaveRequest request) async {
    final leaveProvider = context.read<LeaveProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final success = await leaveProvider.approveLeaveRequest(
      request.id,
      approverId: authProvider.currentUserId,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request approved'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            leaveProvider.error ?? 'Failed to approve leave request',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectLeaveRequest(LeaveRequest request) async {
    // Show dialog to get rejection reason
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (reason != null && reason.isNotEmpty && mounted) {
      final leaveProvider = context.read<LeaveProvider>();
      final authProvider = context.read<AuthProvider>();
      
      final success = await leaveProvider.rejectLeaveRequest(
        request.id,
        reason,
        approverId: authProvider.currentUserId,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request rejected'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              leaveProvider.error ?? 'Failed to reject leave request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelLeaveRequest(LeaveRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave Request'),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final leaveProvider = context.read<LeaveProvider>();
      final success = await leaveProvider.cancelLeaveRequest(request.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              leaveProvider.error ?? 'Failed to cancel leave request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLeaveTypeDisplayName(String leaveType) {
    switch (leaveType) {
      case 'vacation':
        return 'Vacation';
      case 'sick':
        return 'Sick Leave';
      case 'personal':
        return 'Personal Leave';
      case 'maternity':
        return 'Maternity Leave';
      case 'paternity':
        return 'Paternity Leave';
      case 'bereavement':
        return 'Bereavement Leave';
      default:
        return leaveType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
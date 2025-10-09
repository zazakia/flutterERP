import 'package:flutter/material.dart';
import '../models/leave_request.dart';

/// Widget for displaying a list of leave requests
class LeaveRequestList extends StatefulWidget {
  final List<LeaveRequest> leaveRequests;
  final Function(LeaveRequest)? onApprove;
  final Function(LeaveRequest)? onReject;
  final Function(LeaveRequest)? onCancel;
  final Function(LeaveRequest)? onTap;
  final bool showActions;
  final String? currentUserRole;
  final String? currentUserId;

  const LeaveRequestList({
    super.key,
    required this.leaveRequests,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onTap,
    this.showActions = true,
    this.currentUserRole,
    this.currentUserId,
  });

  @override
  State<LeaveRequestList> createState() => _LeaveRequestListState();
}

class _LeaveRequestListState extends State<LeaveRequestList> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _getFilteredRequests();

    return Column(
      children: [
        // Filter Bar
        _buildFilterBar(),

        const SizedBox(height: 16),

        // Leave Requests List
        if (filteredRequests.isEmpty)
          _buildEmptyState()
        else
          _buildLeaveRequestsList(filteredRequests),
      ],
    );
  }

  Widget _buildFilterBar() {
    final statuses = [
      {'value': 'all', 'label': 'All'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'approved', 'label': 'Approved'},
      {'value': 'rejected', 'label': 'Rejected'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status['label'] as String),
                      selected: _filterStatus == status['value'],
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = selected ? status['value'] as String : 'all';
                        });
                      },
                      selectedColor: const Color(0xFF1E3A8A),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all'
                ? 'No leave requests found'
                : 'No ${_filterStatus} leave requests found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsList(List<LeaveRequest> requests) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildLeaveRequestCard(request);
      },
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    final statusColor = _getStatusColor(request.status);
    final statusIcon = _getStatusIcon(request.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap != null ? () => widget.onTap!(request) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with employee info and status
              Row(
                children: [
                  // Employee info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLeaveTypeDisplayName(request.leaveType),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date range
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${request.numberOfDays} day${request.numberOfDays != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Reason
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.reason,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons (if applicable)
              if (widget.showActions && _canShowActions(request)) ...[
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildActionButtons(request),
              ],

              // Approval info (if applicable)
              if (request.isApproved && request.approverName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Approved by ${request.approverName}',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ] else if (request.isRejected && request.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rejected: ${request.rejectionReason}',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LeaveRequest request) {
    return Row(
      children: [
        if (request.isPending && _canApproveOrReject(request)) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onApprove != null ? () => widget.onApprove!(request) : null,
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Approve'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onReject != null ? () => widget.onReject!(request) : null,
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ] else if (request.isPending && _canCancel(request)) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onCancel != null ? () => widget.onCancel!(request) : null,
              icon: const Icon(Icons.cancel, color: Colors.orange),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<LeaveRequest> _getFilteredRequests() {
    if (_filterStatus == 'all') {
      return widget.leaveRequests;
    }
    return widget.leaveRequests.where((request) => request.status == _filterStatus).toList();
  }

  bool _canShowActions(LeaveRequest request) {
    return _canApproveOrReject(request) || _canCancel(request);
  }

  bool _canApproveOrReject(LeaveRequest request) {
    final role = widget.currentUserRole;
    return (role == 'Admin' || role == 'HR') && request.isPending;
  }

  bool _canCancel(LeaveRequest request) {
    return request.employeeId == widget.currentUserId && request.isPending;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
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
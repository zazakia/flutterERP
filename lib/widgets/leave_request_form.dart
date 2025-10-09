import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request.dart';
import '../providers/leave_provider.dart';
import '../providers/auth_provider.dart';

/// Widget for creating and editing leave requests
class LeaveRequestForm extends StatefulWidget {
  final LeaveRequest? leaveRequest;
  final Function(LeaveRequest) onSave;

  const LeaveRequestForm({
    super.key,
    this.leaveRequest,
    required this.onSave,
  });

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  late String _leaveType;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _reason;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.leaveRequest != null) {
      _leaveType = widget.leaveRequest!.leaveType;
      _startDate = widget.leaveRequest!.startDate;
      _endDate = widget.leaveRequest!.endDate;
      _reason = widget.leaveRequest!.reason;
      _reasonController.text = _reason;
    } else {
      _leaveType = 'vacation';
      _startDate = DateTime.now().add(const Duration(days: 1));
      _endDate = DateTime.now().add(const Duration(days: 2));
      _reason = '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leaveRequest == null ? 'Request Leave' : 'Edit Leave Request'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Type Selector
                  _buildLeaveTypeSelector(),

                  const SizedBox(height: 24),

                  // Date Pickers
                  _buildDatePickers(),

                  const SizedBox(height: 24),

                  // Number of Days
                  _buildNumberOfDaysDisplay(),

                  const SizedBox(height: 24),

                  // Reason Field
                  _buildReasonField(),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSelector() {
    final leaveTypes = [
      {'value': 'vacation', 'label': 'Vacation', 'icon': Icons.beach_access},
      {'value': 'sick', 'label': 'Sick Leave', 'icon': Icons.local_hospital},
      {'value': 'personal', 'label': 'Personal Leave', 'icon': Icons.person},
      {'value': 'maternity', 'label': 'Maternity Leave', 'icon': Icons.pregnant_woman},
      {'value': 'paternity', 'label': 'Paternity Leave', 'icon': Icons.family_restroom},
      {'value': 'bereavement', 'label': 'Bereavement Leave', 'icon': Icons.sentiment_very_dissatisfied},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: leaveTypes.map((type) {
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(type['icon'] as IconData, color: const Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(type['label'] as String),
                  ],
                ),
                value: type['value'] as String,
                groupValue: _leaveType,
                onChanged: (value) {
                  setState(() {
                    _leaveType = value!;
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave Dates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              // Start Date
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_formatDate(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectStartDate(context),
              ),
              const Divider(),
              // End Date
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(_formatDate(_endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectEndDate(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberOfDaysDisplay() {
    final numberOfDays = _calculateNumberOfDays();
    
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$numberOfDays days',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for Leave',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please provide a reason for your leave request...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a reason for your leave request';
            }
            if (value.trim().length < 10) {
              return 'Reason must be at least 10 characters long';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _reason = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(widget.leaveRequest == null ? 'Submit Request' : 'Update Request'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  int _calculateNumberOfDays() {
    // Calculate business days (Monday to Friday) between start and end dates
    final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    int days = 0;
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Only count weekdays (Monday=1 to Friday=5)
      if (current.weekday >= 1 && current.weekday <= 5) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      final leaveRequest = LeaveRequest(
        id: widget.leaveRequest?.id ?? '', // Will be generated by backend
        employeeId: authProvider.currentUserId ?? '',
        employeeName: currentUser?['name'] ?? 'Current User',
        leaveType: _leaveType,
        startDate: _startDate,
        endDate: _endDate,
        numberOfDays: _calculateNumberOfDays(),
        reason: _reason,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(leaveRequest);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
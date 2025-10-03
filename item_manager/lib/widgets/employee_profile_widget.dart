import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import 'avatar_generator_widget.dart';

/// Widget for displaying detailed employee profile information
class EmployeeProfileWidget extends StatelessWidget {
  final Employee employee;
  final Function()? onEdit;
  final Function()? onDelete;
  final String? userRole;
  final bool isCurrentUser;

  const EmployeeProfileWidget({
    super.key,
    required this.employee,
    this.onEdit,
    this.onDelete,
    this.userRole,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profile'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          if (_canEdit())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
          if (_canDelete())
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),

            // Details Sections
            _buildBasicInfoSection(),
            _buildEmploymentInfoSection(),
            _buildBankingInfoSection(),
            _buildTimestampsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          AvatarGeneratorWidget(
            firstName: employee.firstName,
            lastName: employee.lastName,
            employeeId: employee.employeeId,
            size: 100,
            avatarUrl: employee.avatar,
          ),

          const SizedBox(height: 16),

          // Name and Status
          Text(
            employee.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Role and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  employee.role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: employee.status
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  employee.status ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: employee.status ? Colors.green.shade100 : Colors.red.shade100,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (isCurrentUser)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Your Profile',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildInfoSection(
      title: 'Basic Information',
      icon: Icons.person,
      children: [
        _buildInfoRow('Employee ID', employee.employeeId),
        _buildInfoRow('First Name', employee.firstName),
        _buildInfoRow('Last Name', employee.lastName),
        _buildInfoRow('Email', employee.email),
      ],
    );
  }

  Widget _buildEmploymentInfoSection() {
    return _buildInfoSection(
      title: 'Employment Information',
      icon: Icons.work,
      children: [
        _buildInfoRow('Role', employee.role),
        _buildInfoRow('Employment Type', employee.employmentType),
        _buildInfoRow('Pay Type', employee.payType),
        _buildInfoRow('Salary Rate', _formatSalaryRate()),
        _buildInfoRow('Tax ID', _maskTaxId(employee.taxId)),
      ],
    );
  }

  Widget _buildBankingInfoSection() {
    return _buildInfoSection(
      title: 'Banking Information',
      icon: Icons.account_balance,
      children: [
        if (employee.accountNumber != null)
          _buildInfoRow('Account Number', _maskAccountNumber(employee.accountNumber!)),
        if (employee.routingNumber != null)
          _buildInfoRow('Routing Number', employee.routingNumber!),
        if (employee.bankName != null)
          _buildInfoRow('Bank Name', employee.bankName!),
      ],
    );
  }

  Widget _buildTimestampsSection() {
    return _buildInfoSection(
      title: 'Timestamps',
      icon: Icons.schedule,
      children: [
        _buildInfoRow('Created', _formatDateTime(employee.createdAt)),
        _buildInfoRow('Last Updated', _formatDateTime(employee.updatedAt)),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSalaryRate() {
    final formatter = NumberFormat.currency(symbol: '\$');
    return '${formatter.format(employee.salaryRate)} per ${employee.payType.toLowerCase()}';
  }

  String _maskTaxId(String taxId) {
    // Mask all but last 4 digits for security
    if (taxId.length <= 4) return taxId;
    final masked = '*' * (taxId.length - 4);
    return '$masked${taxId.substring(taxId.length - 4)}';
  }

  String _maskAccountNumber(String accountNumber) {
    // Mask all but last 4 digits for security
    if (accountNumber.length <= 4) return accountNumber;
    final masked = '*' * (accountNumber.length - 4);
    return '$masked${accountNumber.substring(accountNumber.length - 4)}';
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy \'at\' hh:mm a');
    return formatter.format(dateTime);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Permission checks
  bool _canEdit() {
    if (isCurrentUser) return true; // Users can edit their own profile
    final role = userRole;
    return role == 'Admin' || role == 'HR';
  }

  bool _canDelete() {
    final role = userRole;
    return role == 'Admin' || role == 'HR';
  }
}
import 'package:flutter/material.dart';
import '../models/employee.dart';
import 'avatar_generator_widget.dart';

/// Widget for displaying a list of employees with search and filter functionality
class EmployeeListWidget extends StatefulWidget {
  final List<Employee> employees;
  final Function(Employee)? onEmployeeTap;
  final Function()? onAddEmployee;
  final Function(Employee)? onEditEmployee;
  final Function(Employee)? onDeleteEmployee;
  final bool showActions;
  final String? userRole;

  const EmployeeListWidget({
    super.key,
    required this.employees,
    this.onEmployeeTap,
    this.onAddEmployee,
    this.onEditEmployee,
    this.onDeleteEmployee,
    this.showActions = true,
    this.userRole,
  });

  @override
  State<EmployeeListWidget> createState() => _EmployeeListWidgetState();
}

class _EmployeeListWidgetState extends State<EmployeeListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _selectedEmploymentTypeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _getFilteredEmployees();

    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchAndFilterBar(),

        // Employee Count
        _buildEmployeeCount(filteredEmployees.length),

        // Employee List
        Expanded(
          child: filteredEmployees.isEmpty
              ? _buildEmptyState()
              : _buildEmployeeList(filteredEmployees),
        ),

        // Add Employee Button (if actions enabled)
        if (widget.showActions && _canAddEmployee())
          _buildAddEmployeeButton(),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
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
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search employees...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),

          const SizedBox(height: 12),

          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  label: 'Role',
                  value: _selectedRoleFilter,
                  items: ['All', 'Admin', 'Payroll', 'HR', 'Employee'],
                  onChanged: (value) => setState(() => _selectedRoleFilter = value!),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatusFilter,
                  items: ['All', 'Active', 'Inactive'],
                  onChanged: (value) => setState(() => _selectedStatusFilter = value!),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  label: 'Type',
                  value: _selectedEmploymentTypeFilter,
                  items: ['All', 'Full-time', 'Part-time'],
                  onChanged: (value) => setState(() => _selectedEmploymentTypeFilter = value!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '$count employee${count != 1 ? 's' : ''} found',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _hasActiveFilters()
                ? 'No employees match your search criteria'
                : 'No employees found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _hasActiveFilters())
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<Employee> employees) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => widget.onEmployeeTap?.call(employee),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              AvatarGeneratorWidget(
                firstName: employee.firstName,
                lastName: employee.lastName,
                employeeId: employee.employeeId,
                size: 50,
                avatarUrl: employee.avatar,
              ),

              const SizedBox(width: 16),

              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${employee.role} • ${employee.employmentType}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: employee.status
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  employee.status ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: employee.status
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Actions Menu
              if (widget.showActions && _canEditEmployee(employee))
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, employee),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (_canEditEmployee(employee))
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (_canDeleteEmployee(employee))
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddEmployeeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: widget.onAddEmployee,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  List<Employee> _getFilteredEmployees() {
    return widget.employees.where((employee) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          employee.fullName.toLowerCase().contains(_searchQuery) ||
          employee.email.toLowerCase().contains(_searchQuery) ||
          employee.employeeId.toLowerCase().contains(_searchQuery) ||
          employee.role.toLowerCase().contains(_searchQuery);

      // Role filter
      final matchesRole = _selectedRoleFilter == 'All' ||
          employee.role == _selectedRoleFilter;

      // Status filter
      final matchesStatus = _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Active' && employee.status) ||
          (_selectedStatusFilter == 'Inactive' && !employee.status);

      // Employment type filter
      final matchesEmploymentType = _selectedEmploymentTypeFilter == 'All' ||
          employee.employmentType == _selectedEmploymentTypeFilter;

      return matchesSearch && matchesRole && matchesStatus && matchesEmploymentType;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _selectedRoleFilter != 'All' ||
        _selectedStatusFilter != 'All' ||
        _selectedEmploymentTypeFilter != 'All';
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedRoleFilter = 'All';
      _selectedStatusFilter = 'All';
      _selectedEmploymentTypeFilter = 'All';
    });
  }

  void _handleMenuAction(String action, Employee employee) {
    switch (action) {
      case 'view':
        widget.onEmployeeTap?.call(employee);
        break;
      case 'edit':
        widget.onEditEmployee?.call(employee);
        break;
      case 'delete':
        _confirmDelete(employee);
        break;
    }
  }

  void _confirmDelete(Employee employee) {
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
              widget.onDeleteEmployee?.call(employee);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Permission checks based on user role
  bool _canAddEmployee() {
    final role = widget.userRole;
    return role == 'Admin' || role == 'HR';
  }

  bool _canEditEmployee(Employee employee) {
    final role = widget.userRole;
    if (role == 'Admin' || role == 'HR') return true;
    if (role == 'Payroll') return false; // Payroll can only view
    return false;
  }

  bool _canDeleteEmployee(Employee employee) {
    final role = widget.userRole;
    return role == 'Admin' || role == 'HR';
  }
}
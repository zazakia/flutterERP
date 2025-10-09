import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import 'avatar_generator_widget.dart';

/// Form widget for creating and editing employees
class EmployeeFormWidget extends StatefulWidget {
  final Employee? employee;
  final Function(Employee) onSave;
  final VoidCallback? onCancel;

  const EmployeeFormWidget({
    super.key,
    this.employee,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<EmployeeFormWidget> createState() => _EmployeeFormWidgetState();
}

class _EmployeeFormWidgetState extends State<EmployeeFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  late final TextEditingController _employeeIdController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _salaryRateController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _routingNumberController;
  late final TextEditingController _bankNameController;

  // Form values
  String _selectedRole = 'Employee';
  String _selectedEmploymentType = 'Full-time';
  String _selectedPayType = 'Hourly';
  bool _isActive = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _employeeIdController = TextEditingController(text: widget.employee?.employeeId ?? '');
    _firstNameController = TextEditingController(text: widget.employee?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.employee?.lastName ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _salaryRateController = TextEditingController(text: widget.employee?.salaryRate.toString() ?? '');
    _taxIdController = TextEditingController(text: widget.employee?.taxId ?? '');
    _accountNumberController = TextEditingController(text: widget.employee?.accountNumber ?? '');
    _routingNumberController = TextEditingController(text: widget.employee?.routingNumber ?? '');
    _bankNameController = TextEditingController(text: widget.employee?.bankName ?? '');

    // Initialize form values
    if (widget.employee != null) {
      _selectedRole = widget.employee!.role;
      _selectedEmploymentType = widget.employee!.employmentType;
      _selectedPayType = widget.employee!.payType;
      _isActive = widget.employee!.status;
      _avatarUrl = widget.employee!.avatar;
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _salaryRateController.dispose();
    _taxIdController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              _buildAvatarSection(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
                validator: _validateEmployeeId,
                enabled: widget.employee == null, // Can't edit employee ID
              ),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                validator: _validateRequired,
              ),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                validator: _validateRequired,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),

              const SizedBox(height: 24),

              // Employment Details
              _buildSectionHeader('Employment Details'),
              _buildDropdownField(
                label: 'Role',
                value: _selectedRole,
                items: ['Admin', 'Payroll', 'HR', 'Employee'],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              _buildDropdownField(
                label: 'Employment Type',
                value: _selectedEmploymentType,
                items: ['Full-time', 'Part-time'],
                onChanged: (value) => setState(() => _selectedEmploymentType = value!),
              ),
              _buildDropdownField(
                label: 'Pay Type',
                value: _selectedPayType,
                items: ['Hourly', 'Salary'],
                onChanged: (value) => setState(() => _selectedPayType = value!),
              ),
              _buildTextField(
                controller: _salaryRateController,
                label: 'Salary Rate',
                keyboardType: TextInputType.number,
                validator: _validateSalaryRate,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),

              const SizedBox(height: 24),

              // Banking Information
              _buildSectionHeader('Banking Information'),
              _buildTextField(
                controller: _taxIdController,
                label: 'Tax ID',
                validator: _validateTaxId,
              ),
              _buildTextField(
                controller: _accountNumberController,
                label: 'Account Number (Optional)',
                keyboardType: TextInputType.number,
                validator: _validateAccountNumber,
              ),
              _buildTextField(
                controller: _routingNumberController,
                label: 'Routing Number (Optional)',
                keyboardType: TextInputType.number,
                validator: _validateRoutingNumber,
              ),
              _buildTextField(
                controller: _bankNameController,
                label: 'Bank Name (Optional)',
              ),

              const SizedBox(height: 24),

              // Status
              _buildSectionHeader('Status'),
              SwitchListTile(
                title: const Text('Active Employee'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: const Color(0xFF1E3A8A),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.employee == null ? 'Create Employee' : 'Update Employee',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          AvatarGeneratorWidget(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            employeeId: _employeeIdController.text,
            size: 100,
            avatarUrl: _avatarUrl,
            showUploadOption: true,
            onAvatarTap: _showAvatarDialog,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAvatarDialog,
            child: const Text('Change Avatar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF1E3A8A)),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        enabled: enabled,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF1E3A8A)),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  // Validation methods
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmployeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (value.length < 3) {
      return 'Employee ID must be at least 3 characters';
    }
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return 'Employee ID can only contain letters, numbers, hyphens, and underscores';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateSalaryRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Salary rate is required';
    }
    final rate = double.tryParse(value);
    if (rate == null || rate <= 0) {
      return 'Please enter a valid positive number';
    }
    return null;
  }

  String? _validateTaxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tax ID is required';
    }
    // Basic validation for SSN or EIN format
    final taxIdRegex = RegExp(r'^\d{3}-?\d{2}-?\d{4}$|^\d{2}-?\d{7}$');
    if (!taxIdRegex.hasMatch(value.replaceAll('-', ''))) {
      return 'Please enter a valid Tax ID (SSN: XXX-XX-XXXX or EIN: XX-XXXXXXX)';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 8 || value.length > 17) {
        return 'Account number must be between 8-17 digits';
      }
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        return 'Account number must contain only digits';
      }
    }
    return null;
  }

  String? _validateRoutingNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 9) {
        return 'Routing number must be 9 digits';
      }
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        return 'Routing number must contain only digits';
      }
    }
    return null;
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) => AvatarUploadDialog(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        employeeId: _employeeIdController.text,
        onAvatarSelected: (avatarUrl) {
          setState(() {
            _avatarUrl = avatarUrl;
          });
        },
      ),
    );
  }

  void _saveEmployee() {
    if (_formKey.currentState?.validate() ?? false) {
      final employee = Employee(
        employeeId: _employeeIdController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        employmentType: _selectedEmploymentType,
        salaryRate: double.parse(_salaryRateController.text),
        payType: _selectedPayType,
        taxId: _taxIdController.text.trim(),
        accountNumber: _accountNumberController.text.isNotEmpty ? _accountNumberController.text : null,
        routingNumber: _routingNumberController.text.isNotEmpty ? _routingNumberController.text : null,
        bankName: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
        status: _isActive,
        avatar: _avatarUrl,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(employee);
    }
  }
}
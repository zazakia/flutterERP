import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payroll.dart';
import '../providers/payroll_provider.dart';
import '../providers/auth_provider.dart';

/// Widget for viewing payslip details
class PayslipWidget extends StatefulWidget {
  final Payroll? payroll;

  const PayslipWidget({super.key, this.payroll});

  @override
  State<PayslipWidget> createState() => _PayslipWidgetState();
}

class _PayslipWidgetState extends State<PayslipWidget> {
  @override
  void initState() {
    super.initState();
    // If no payroll provided, load the most recent one
    if (widget.payroll == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadMostRecentPayslip();
      });
    }
  }

  Future<void> _loadMostRecentPayslip() async {
    final payrollProvider = context.read<PayrollProvider>();
    await payrollProvider.loadPayrollRecords();
    
    if (payrollProvider.payrollRecords.isNotEmpty && mounted) {
      final latestPayroll = payrollProvider.payrollRecords.first;
      await payrollProvider.loadPayrollRecord(latestPayroll.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayrollProvider, AuthProvider>(
      builder: (context, payrollProvider, authProvider, child) {
        final payroll = widget.payroll ?? payrollProvider.currentPayroll;

        if (payrollProvider.isLoading && payroll == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (payroll == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Payslip'),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'No payslip available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Payslip'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadPayslip(payroll),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePayslip(payroll),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x1A1E3A8A),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Company Header
                    _buildCompanyHeader(),

                    const SizedBox(height: 24),

                    // Employee Info
                    _buildEmployeeInfo(payroll, authProvider),

                    const SizedBox(height: 24),

                    // Pay Period
                    _buildPayPeriod(payroll),

                    const SizedBox(height: 24),

                    // Earnings Section
                    _buildEarningsSection(payroll),

                    const SizedBox(height: 16),

                    // Deductions Section
                    _buildDeductionsSection(payroll),

                    const SizedBox(height: 16),

                    // Net Pay
                    _buildNetPaySection(payroll),

                    const SizedBox(height: 24),

                    // Payment Info
                    _buildPaymentInfo(payroll),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(payroll),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A808080),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance,
            size: 40,
            color: Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Brayan Lee\'s Payroll System',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official Payslip',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo(Payroll payroll, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A808080),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  payroll.employeeName,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.badge, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  payroll.employeeId,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pay Date: ${_formatDate(payroll.payDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayPeriod(Payroll payroll) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x1A1E3A8A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Pay Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(payroll.payPeriodStart)} to ${_formatDate(payroll.payPeriodEnd)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection(Payroll payroll) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A808080),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          _buildEarningsRow('Regular Hours', '${payroll.hoursWorked.toStringAsFixed(2)} hrs', '\$${payroll.grossPay.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildEarningsRow('Overtime', '0.00 hrs', '\$${payroll.overtimePay.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildEarningsRow('Bonus', '', '\$${payroll.bonus.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildEarningsRow('Gross Pay', '', '\$${payroll.grossPay.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildDeductionsSection(Payroll payroll) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A808080),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deductions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          _buildEarningsRow('Federal Tax', '', '\$${payroll.taxDeductions.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildEarningsRow('Other Deductions', '', '\$${payroll.otherDeductions.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildEarningsRow('Total Deductions', '', '\$${(payroll.taxDeductions + payroll.otherDeductions).toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildNetPaySection(Payroll payroll) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Net Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${payroll.netPay.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Payroll payroll) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A808080),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.grey),
              SizedBox(width: 12),
              Text(
                'Direct Deposit',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text(
                'Processed',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String hours, String amount, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (hours.isNotEmpty)
          Text(
            hours,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        if (hours.isNotEmpty)
          const SizedBox(width: 16),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Payroll payroll) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadPayslip(payroll),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sharePayslip(payroll),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadPayslip(Payroll payroll) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payslip downloaded successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sharePayslip(Payroll payroll) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing payslip...'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
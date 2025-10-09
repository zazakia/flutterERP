import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../services/secure_storage_service.dart';
import 'employee_management_screen.dart';
import 'clock_widget.dart';
import 'payslip_widget.dart';
import 'leave_management_screen.dart';

/// Employee dashboard widget shown after successful authentication
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              // User info dropdown
              PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(_getUserDisplayName(authProvider)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: _buildNavigationDrawer(authProvider),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3A8A).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(authProvider),

                    const SizedBox(height: 32),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildQuickActionsGrid(),

                    const SizedBox(height: 32),

                    // Payroll Information
                    const Text(
                      'Payroll Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildPayrollCards(),

                    const SizedBox(height: 32),

                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildRecentActivityList(),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showSupportDialog,
            backgroundColor: const Color(0xFF1E3A8A),
            child: const Icon(Icons.support),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
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
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_getUserDisplayName(authProvider)}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUserRole(authProvider),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getCurrentDateTime(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'icon': Icons.access_time,
        'label': 'Clock In/Out',
        'color': Colors.green,
        'onTap': _handleClockInOut,
      },
      {
        'icon': Icons.receipt,
        'label': 'View Payslip',
        'color': Colors.blue,
        'onTap': _handleViewPayslip,
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Time Off',
        'color': Colors.orange,
        'onTap': _handleTimeOff,
      },
      {
        'icon': Icons.analytics,
        'label': 'Reports',
        'color': Colors.purple,
        'onTap': _handleReports,
      },
      {
        'icon': Icons.people,
        'label': 'Manage Employees',
        'color': Colors.teal,
        'onTap': _handleManageEmployees,
      },
      {
        'icon': Icons.payments,
        'label': 'Payroll',
        'color': Colors.indigo,
        'onTap': _handlePayroll,
      },
      {
        'icon': Icons.time_to_leave,
        'label': 'Leave Requests',
        'color': Colors.purple,
        'onTap': _handleLeaveRequests,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: action['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayrollCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPayrollCard(
                title: 'This Month',
                amount: '\$3,450.00',
                subtitle: 'Gross Pay',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPayrollCard(
                title: 'Next Payday',
                amount: 'Dec 15',
                subtitle: '2024',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPayrollCard(
                title: 'Hours Worked',
                amount: '160.5',
                subtitle: 'This Month',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPayrollCard(
                title: 'PTO Balance',
                amount: '24.5',
                subtitle: 'Days',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayrollCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final activities = [
      {
        'type': 'Clock In',
        'time': '9:00 AM',
        'date': 'Today',
        'icon': Icons.login,
        'color': Colors.green,
      },
      {
        'type': 'Break Start',
        'time': '12:00 PM',
        'date': 'Today',
        'icon': Icons.pause,
        'color': Colors.orange,
      },
      {
        'type': 'Break End',
        'time': '1:00 PM',
        'date': 'Today',
        'icon': Icons.play_arrow,
        'color': Colors.blue,
      },
      {
        'type': 'Payslip Generated',
        'time': 'Yesterday',
        'date': 'Nov 30, 2024',
        'icon': Icons.receipt,
        'color': Colors.purple,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (activity['color'] as Color).withOpacity(0.1),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
              ),
            ),
            title: Text(
              activity['type'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(activity['date'] as String),
            trailing: Text(
              activity['time'] as String,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getUserDisplayName(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user != null && user.containsKey('name')) {
      return user['name'] as String;
    }
    return 'Employee';
  }

  String _getUserRole(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user != null && user.containsKey('role')) {
      return (user['role'] as String).toUpperCase();
    }
    return 'EMPLOYEE';
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${_getMonthName(now.month)} ${now.day}, ${now.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        _showProfileDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleClockInOut() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ClockWidget(),
      ),
    );
  }

  void _handleViewPayslip() {
    _showSnackBar('Payslip view feature coming soon!');
  }

  void _handleReports() {
    _showSnackBar('Reports feature coming soon!');
  }

  void _handleManageEmployees() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmployeeManagementScreen(),
      ),
    );
  }
  void _handleTimeOff() {
    _showSnackBar('Time off request feature coming soon!');
  }

  void _handlePayroll() {
    _showSnackBar('Payroll management feature coming soon!');
  }

  void _handleLeaveRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeaveManagementScreen(),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final auth = context.read<AuthProvider>();
              await auth.logout();

              // If logout did nothing (no service), fall back to clearing storage and notifying user
              if (auth.authService == null) {
                final storage = await SecureStorageService.initialize();
                await storage.clearAllData();
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out and cleared local credentials.')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_getUserDisplayName(context.read<AuthProvider>())}'),
            const SizedBox(height: 8),
            Text('Role: ${_getUserRole(context.read<AuthProvider>())}'),
            const SizedBox(height: 8),
            Text('Employee ID: ${context.read<AuthProvider>().currentUserId ?? 'N/A'}'),
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Biometric Settings'),
              subtitle: Text('Manage fingerprint/face authentication'),
            ),
            ListTile(
              leading: Icon(Icons.pin),
              title: Text('PIN Settings'),
              subtitle: Text('Change your PIN'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              subtitle: Text('Manage notification preferences'),
            ),
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

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Need help? Contact support:'),
            SizedBox(height: 16),
            SelectableText(
              'Email: support@brayanlee-payroll.com\nPhone: +1 (555) 123-4567',
              style: TextStyle(fontFamily: 'monospace'),
            ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildNavigationDrawer(AuthProvider authProvider) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E3A8A),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome, ${_getUserDisplayName(authProvider)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getUserRole(authProvider),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () => _navigateToSection('dashboard'),
                      isSelected: true,
                    ),
                    _buildDrawerItem(
                      icon: Icons.access_time,
                      title: 'Clock In/Out',
                      onTap: () => _navigateToSection('clock'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.receipt,
                      title: 'View Payslip',
                      onTap: () => _navigateToSection('payslip'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.calendar_today,
                      title: 'Time Off',
                      onTap: () => _navigateToSection('timeoff'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.analytics,
                      title: 'Reports',
                      onTap: () => _navigateToSection('reports'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.people,
                      title: 'Manage Employees',
                      onTap: () => _navigateToSection('employees'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.payments,
                      title: 'Payroll',
                      onTap: () => _navigateToSection('payroll'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.time_to_leave,
                      title: 'Leave Requests',
                      onTap: () => _navigateToSection('leave'),
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => _navigateToSection('settings'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.support,
                      title: 'Support',
                      onTap: () => _navigateToSection('support'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        onTap();
      },
      tileColor: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.1) : null,
    );
  }

  void _navigateToSection(String section) {
    switch (section) {
      case 'dashboard':
        // Already on dashboard
        break;
      case 'clock':
        _handleClockInOut();
        break;
      case 'payslip':
        _handleViewPayslip();
        break;
      case 'timeoff':
        _handleTimeOff();
        break;
      case 'reports':
        _handleReports();
        break;
      case 'employees':
        _handleManageEmployees();
        break;
      case 'payroll':
        _handlePayroll();
        break;
      case 'leave':
        _handleLeaveRequests();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'support':
        _showSupportDialog();
        break;
    }
  }
}
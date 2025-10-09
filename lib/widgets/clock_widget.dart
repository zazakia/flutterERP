import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

/// Widget for clocking in and out
class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  @override
  void initState() {
    super.initState();
    // Load active attendance when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AttendanceProvider>().loadActiveAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AttendanceProvider, AuthProvider>(
      builder: (context, attendanceProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Clock In/Out'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Time Display
                    _buildCurrentTimeDisplay(),

                    const SizedBox(height: 32),

                    // Clock Status Card
                    _buildClockStatusCard(attendanceProvider),

                    const SizedBox(height: 32),

                    // Action Button
                    _buildActionButton(attendanceProvider),

                    const SizedBox(height: 32),

                    // Recent Activity
                    _buildRecentActivity(attendanceProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTimeDisplay() {
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
          const Text(
            'Current Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<DateTime>(
            stream: Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now()),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              return Text(
                '${_formatTime(now)}\n${_formatDate(now)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClockStatusCard(AttendanceProvider attendanceProvider) {
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
            'Clock Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (attendanceProvider.isClockedIn) ...[
            const Icon(
              Icons.login,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'You are currently clocked in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clocked in at: ${_formatTime(attendanceProvider.activeAttendance!.clockInTime)}',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ] else ...[
            const Icon(
              Icons.logout,
              size: 40,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'You are currently clocked out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ready to start your shift',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(AttendanceProvider attendanceProvider) {
    final isClockedIn = attendanceProvider.isClockedIn;
    
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: FloatingActionButton(
          onPressed: attendanceProvider.isLoading 
            ? null 
            : () => _handleClockAction(attendanceProvider),
          backgroundColor: isClockedIn ? Colors.red : Colors.green,
          shape: const CircleBorder(),
          child: Icon(
            isClockedIn ? Icons.logout : Icons.login,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AttendanceProvider attendanceProvider) {
    if (attendanceProvider.attendanceRecords.isEmpty) {
      return const Center(
        child: Text(
          'No recent activity',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final recentRecords = attendanceProvider.attendanceRecords.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentRecords.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = recentRecords[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: record.isActive ? Colors.green : Colors.red,
                  child: Icon(
                    record.isActive ? Icons.login : Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  record.isActive ? 'Clocked In' : 'Clocked Out',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _formatDateTime(record.clockInTime),
                ),
                trailing: record.durationInHours != null
                    ? Text(
                        '${record.durationInHours!.toStringAsFixed(2)} hrs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleClockAction(AttendanceProvider attendanceProvider) async {
    if (attendanceProvider.isClockedIn) {
      // Clock out
      final success = await attendanceProvider.clockOut();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked out'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attendanceProvider.error ?? 'Failed to clock out',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Clock in
      final success = await attendanceProvider.clockIn();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked in'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attendanceProvider.error ?? 'Failed to clock in',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
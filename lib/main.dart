// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/payroll_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/database_provider.dart';
import 'services/secure_storage_service.dart';
import 'widgets/employee_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final secureStorage = await SecureStorageService.initialize();
  runApp(BiometricPayrollApp(secureStorage: secureStorage));
}

class BiometricPayrollApp extends StatelessWidget {
  final SecureStorageService secureStorage;

  const BiometricPayrollApp({super.key, required this.secureStorage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final dbProvider = DatabaseProvider();
            dbProvider.initialize(secureStorage);
            return dbProvider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, DatabaseProvider, EmployeeProvider>(
          create: (context) => EmployeeProvider(secureStorage),
          update: (context, authProvider, dbProvider, previous) => 
            previous ?? EmployeeProvider(secureStorage, dbProvider),
        ),
        ChangeNotifierProvider(create: (context) => AttendanceProvider(secureStorage)),
        ChangeNotifierProvider(create: (context) => PayrollProvider(secureStorage)),
        ChangeNotifierProvider(create: (context) => LeaveProvider(secureStorage)),
      ],
      child: MaterialApp(
        title: 'Brayan Lee\'s Payroll System',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const PayrollHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class PayrollHomePage extends StatefulWidget {
  const PayrollHomePage({super.key});

  @override
  State<PayrollHomePage> createState() => _PayrollHomePageState();
}

class _PayrollHomePageState extends State<PayrollHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const EmployeeDashboard();
  }
}

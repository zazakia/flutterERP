// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
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
        ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
          create: (context) => EmployeeProvider(secureStorage),
          update: (context, authProvider, previous) => previous ?? EmployeeProvider(secureStorage),
        ),
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

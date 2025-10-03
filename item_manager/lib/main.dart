// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'services/secure_storage_service.dart';
import 'widgets/auth_flow_widget.dart';
import 'widgets/employee_dashboard.dart';

void main() {
  runApp(const BiometricPayrollApp());
}

class BiometricPayrollApp extends StatelessWidget {
  const BiometricPayrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
          create: (context) => EmployeeProvider(SecureStorageService()),
          update: (context, authProvider, previous) => previous ?? EmployeeProvider(SecureStorageService()),
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

class PayrollHomePage extends StatelessWidget {
  const PayrollHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFlowWidget(
      authenticatedWidget: const EmployeeDashboard(),
    );
  }
}

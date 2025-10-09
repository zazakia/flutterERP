import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:item_manager/widgets/clock_widget.dart';
import 'package:item_manager/providers/attendance_provider.dart';
import 'package:item_manager/providers/auth_provider.dart';
import 'package:item_manager/services/secure_storage_service.dart';

void main() {
  group('ClockWidget', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      // Create a simple secure storage mock
      final secureStorage = await SecureStorageService.initialize();
      
      // Create providers
      final authProvider = AuthProvider();
      final attendanceProvider = AttendanceProvider(secureStorage);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: attendanceProvider),
            ],
            child: const ClockWidget(),
          ),
        ),
      );
      
      // Verify that the widget renders correctly
      expect(find.text('Clock In/Out'), findsOneWidget);
      expect(find.text('Current Time'), findsOneWidget);
    });
  });
}
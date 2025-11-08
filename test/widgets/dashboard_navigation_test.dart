import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:item_manager/widgets/employee_dashboard.dart';
import 'package:item_manager/providers/auth_provider.dart';
import 'package:item_manager/services/secure_storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([SecureStorageService])
import 'dashboard_navigation_test.mocks.dart';

void main() {
  group('Dashboard Navigation', () {
    late MockSecureStorageService mockSecureStorage;
    late AuthProvider authProvider;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => 'fake-token');
      
      authProvider = AuthProvider();
    });

    testWidgets('Dashboard loads with clock action button', (WidgetTester tester) async {
      // Build the dashboard widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: const EmployeeDashboard(),
          ),
        ),
      );

      // Verify dashboard loads
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      
      // Find the Clock In/Out button in the quick actions grid
      expect(find.text('Clock In/Out'), findsOneWidget);
    });
  });
}
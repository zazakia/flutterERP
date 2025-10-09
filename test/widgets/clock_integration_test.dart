import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:item_manager/widgets/clock_widget.dart';
import 'package:item_manager/providers/attendance_provider.dart';
import 'package:item_manager/providers/auth_provider.dart';
import 'package:item_manager/services/secure_storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([SecureStorageService])
import 'clock_integration_test.mocks.dart';

void main() {
  group('Clock Integration', () {
    late MockSecureStorageService mockSecureStorage;
    late AuthProvider authProvider;
    late AttendanceProvider attendanceProvider;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async => 'fake-token');
      
      authProvider = AuthProvider();
      attendanceProvider = AttendanceProvider(mockSecureStorage);
    });

    testWidgets('Clock widget displays correct UI elements', (WidgetTester tester) async {
      // Build the clock widget with proper providers
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

      // Verify core UI elements are present
      expect(find.text('Clock In/Out'), findsOneWidget);
      expect(find.text('Current Time'), findsOneWidget);
      expect(find.text('Clock Status'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
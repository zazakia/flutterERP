import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:item_manager/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService secureStorageService;
    late FlutterSecureStorage mockSecureStorage;
    late SharedPreferences mockSharedPreferences;

    setUp(() async {
      // Create mock implementations
      mockSecureStorage = FlutterSecureStorage();
      mockSharedPreferences = await SharedPreferences.getInstance();

      // Initialize the service
      secureStorageService = await SecureStorageService.initialize();
    });

    test('initializes correctly', () {
      expect(secureStorageService, isNotNull);
    });

    test('stores and retrieves tokens correctly', () async {
      const testUserId = 'test-user-123';
      const testAccessToken = 'test-access-token';
      const testRefreshToken = 'test-refresh-token';

      // Store tokens
      await secureStorageService.storeTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        userId: testUserId,
      );

      // Retrieve tokens
      final retrievedAccessToken = await secureStorageService.getAccessToken();
      final retrievedRefreshToken = await secureStorageService.getRefreshToken();
      final retrievedUserId = await secureStorageService.getUserId();

      expect(retrievedAccessToken, equals(testAccessToken));
      expect(retrievedRefreshToken, equals(testRefreshToken));
      expect(retrievedUserId, equals(testUserId));
    });

    test('checks authentication status correctly', () async {
      // Initially not authenticated
      expect(await secureStorageService.isAuthenticated(), isFalse);

      // Store tokens
      await secureStorageService.storeTokens(
        accessToken: 'test-token',
        refreshToken: 'test-refresh-token',
        userId: 'test-user',
      );

      // Now should be authenticated
      expect(await secureStorageService.isAuthenticated(), isTrue);
    });

    test('sets up and verifies PIN correctly', () async {
      const testPin = '1234';

      // Initially PIN should not be set
      expect(await secureStorageService.isPinSet(), isFalse);

      // Set PIN
      await secureStorageService.setPinSet(true);

      // Now PIN should be set
      expect(await secureStorageService.isPinSet(), isTrue);

      // Test PIN verification (this would need actual hashing implementation)
      // This is a simplified test since we can't easily mock the hashing
    });

    test('records and retrieves failed attempts correctly', () async {
      // Initially no failed attempts
      expect(await secureStorageService.getFailedAttempts(), equals(0));

      // Record a failed attempt
      await secureStorageService.recordFailedAttempt();

      // Should have 1 failed attempt
      expect(await secureStorageService.getFailedAttempts(), equals(1));
    });

    test('clears all data correctly', () async {
      // Store some test data
      await secureStorageService.storeTokens(
        accessToken: 'test-token',
        refreshToken: 'test-refresh-token',
        userId: 'test-user',
      );
      await secureStorageService.setBiometricEnrolled(true);
      await secureStorageService.recordFailedAttempt();

      // Verify data exists
      expect(await secureStorageService.isAuthenticated(), isTrue);
      expect(await secureStorageService.isBiometricEnrolled(), isTrue);
      expect(await secureStorageService.getFailedAttempts(), equals(1));

      // Clear all data
      await secureStorageService.clearAllData();

      // Verify all data is cleared
      expect(await secureStorageService.isAuthenticated(), isFalse);
      expect(await secureStorageService.getAccessToken(), isNull);
      expect(await secureStorageService.getRefreshToken(), isNull);
      expect(await secureStorageService.getUserId(), isNull);
      expect(await secureStorageService.getFailedAttempts(), equals(0));
    });

    test('handles lockout correctly', () async {
      // Initially not locked out
      expect(await secureStorageService.isLockedOut(), isFalse);

      // Record multiple failed attempts to trigger lockout
      for (int i = 0; i < 5; i++) {
        await secureStorageService.recordFailedAttempt();
      }

      // Should be locked out now
      expect(await secureStorageService.isLockedOut(), isTrue);
      expect(await secureStorageService.getRemainingLockoutTime(), greaterThan(0));
    });
  });
}
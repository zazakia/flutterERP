import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:item_manager/services/biometric_auth_service.dart';
import 'package:item_manager/services/secure_storage_service.dart';

// Generate mocks
@GenerateMocks([LocalAuthentication, SecureStorageService])
import 'biometric_auth_service_test.mocks.dart';

void main() {
  group('BiometricAuthService', () {
    late BiometricAuthService biometricAuthService;
    late MockLocalAuthentication mockLocalAuth;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockSecureStorage = MockSecureStorageService();
      biometricAuthService = BiometricAuthService(mockSecureStorage);
    });

    test('checks biometric availability correctly', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

      // Act
      final result = await biometricAuthService.isBiometricAvailable();

      // Assert
      expect(result, isTrue);
      verify(mockLocalAuth.canCheckBiometrics).called(1);
    });

    test('gets available biometric types correctly', () async {
      // Arrange
      final expectedTypes = [BiometricType.fingerprint, BiometricType.face];
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => expectedTypes);

      // Act
      final result = await biometricAuthService.getAvailableBiometricTypes();

      // Assert
      expect(result, equals(expectedTypes));
      verify(mockLocalAuth.getAvailableBiometrics()).called(1);
    });

    test('checks device support correctly', () async {
      // Arrange
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

      // Act
      final result = await biometricAuthService.isDeviceSupported();

      // Assert
      expect(result, isTrue);
      verify(mockLocalAuth.isDeviceSupported()).called(1);
    });

    test('handles successful biometric authentication', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      // Act
      final result = await biometricAuthService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, contains('successful'));
    });

    test('handles failed biometric authentication', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => false);

      // Act
      final result = await biometricAuthService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(BiometricAuthError.authenticationFailed));
      expect(result.message, contains('failed'));
    });

    test('handles biometric not available error', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

      // Act
      final result = await biometricAuthService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(BiometricAuthError.notAvailable));
      expect(result.message, contains('not available'));
    });

    test('handles account lockout', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => true);
      when(mockSecureStorage.getRemainingLockoutTime()).thenAnswer((_) async => 300);

      // Act
      final result = await biometricAuthService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(BiometricAuthError.lockedOut));
      expect(result.message, contains('locked'));
    });

    test('enrolls biometric successfully', () async {
      // Arrange
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'test-user');
      when(mockSecureStorage.getDeviceId()).thenAnswer((_) async => 'test-device');
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      // Act
      final result = await biometricAuthService.enrollBiometric(
        userId: 'test-user',
        deviceId: 'test-device',
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.message, contains('enrolled successfully'));
    });

    test('checks biometric enrollment status', () async {
      // Arrange
      when(mockSecureStorage.isBiometricEnrolled()).thenAnswer((_) async => true);

      // Act
      final result = await biometricAuthService.isBiometricEnrolled();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.isBiometricEnrolled()).called(1);
    });

    test('gets correct biometric type names', () {
      // Act & Assert
      expect(
        biometricAuthService.getBiometricTypeName(BiometricType.face),
        equals('Face ID'),
      );
      expect(
        biometricAuthService.getBiometricTypeName(BiometricType.fingerprint),
        equals('Fingerprint'),
      );
      expect(
        biometricAuthService.getBiometricTypeName(BiometricType.iris),
        equals('Iris'),
      );
    });

    test('gets correct error messages', () {
      // Act & Assert
      expect(
        biometricAuthService.getErrorMessage(BiometricAuthError.notAvailable),
        contains('not available'),
      );
      expect(
        biometricAuthService.getErrorMessage(BiometricAuthError.notEnrolled),
        contains('not enrolled'),
      );
      expect(
        biometricAuthService.getErrorMessage(BiometricAuthError.lockedOut),
        contains('locked'),
      );
    });
  });
}
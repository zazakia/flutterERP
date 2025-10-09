import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:item_manager/services/authentication_service.dart';
import 'package:item_manager/services/secure_storage_service.dart';
import 'package:item_manager/services/biometric_auth_service.dart';
import 'package:item_manager/services/pin_auth_service.dart';
import 'package:item_manager/services/auth_api_service.dart';

// Generate mocks
@GenerateMocks([
  SecureStorageService,
  BiometricAuthService,
  PinAuthService,
  AuthApiService,
])
import 'authentication_service_test.mocks.dart';

void main() {
  group('AuthenticationService', () {
    late AuthenticationService authenticationService;
    late MockSecureStorageService mockSecureStorage;
    late MockBiometricAuthService mockBiometricAuth;
    late MockPinAuthService mockPinAuth;
    late MockAuthApiService mockApiService;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockBiometricAuth = MockBiometricAuthService();
      mockPinAuth = MockPinAuthService();
      mockApiService = MockAuthApiService();

      authenticationService = AuthenticationService(
        mockSecureStorage,
        mockBiometricAuth,
        mockPinAuth,
        mockApiService,
      );
    });

    test('initializes correctly', () {
      expect(authenticationService, isNotNull);
    });

    test('checks authentication status correctly when authenticated', () async {
      // Arrange
      when(mockSecureStorage.isAuthenticated()).thenAnswer((_) async => true);
      when(mockApiService.isTokenExpired()).thenAnswer((_) async => false);

      // Act
      final result = await authenticationService.isAuthenticated();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.isAuthenticated()).called(1);
      verify(mockApiService.isTokenExpired()).called(1);
    });

    test('checks authentication status correctly when not authenticated', () async {
      // Arrange
      when(mockSecureStorage.isAuthenticated()).thenAnswer((_) async => false);

      // Act
      final result = await authenticationService.isAuthenticated();

      // Assert
      expect(result, false);
      verify(mockSecureStorage.isAuthenticated()).called(1);
      verifyNever(mockApiService.isTokenExpired());
    });

    test('authenticates with biometrics successfully', () async {
      // Arrange
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => true);
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'test-user');
      when(mockSecureStorage.getDeviceId()).thenAnswer((_) async => 'test-device');

      final mockBiometricResult = BiometricAuthResult(
        success: true,
        message: 'Biometric authentication successful',
      );
      when(mockBiometricAuth.authenticateWithBiometrics()).thenAnswer((_) async => mockBiometricResult);

      final mockApiResult = ApiResult.success(AuthTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        role: 'employee',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
      when(mockApiService.loginWithBiometric(
        userId: 'test-user',
        deviceId: 'test-device',
      )).thenAnswer((_) async => mockApiResult);

      // Act
      final result = await authenticationService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isTrue);
      expect(result.message, contains('successful'));
    });

    test('handles biometric authentication when not enrolled', () async {
      // Arrange
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => false);

      // Act
      final result = await authenticationService.authenticateWithBiometrics();

      // Assert
      expect(result.success, isFalse);
      expect(result.needsEnrollment, isTrue);
      expect(result.message, contains('not enrolled'));
    });

    test('authenticates with PIN successfully', () async {
      // Arrange
      const testPin = '1234';
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'test-user');
      when(mockSecureStorage.getDeviceId()).thenAnswer((_) async => 'test-device');

      final mockPinResult = PinAuthResult(
        success: true,
        message: 'PIN authentication successful',
      );
      when(mockPinAuth.verifyPin(testPin)).thenAnswer((_) async => mockPinResult);

      final mockApiResult = ApiResult.success(AuthTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        role: 'employee',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
      when(mockApiService.loginWithPin(
        userId: 'test-user',
        pin: testPin,
        deviceId: 'test-device',
      )).thenAnswer((_) async => mockApiResult);

      // Act
      final result = await authenticationService.authenticateWithPin(testPin);

      // Assert
      expect(result.success, isTrue);
      expect(result.message, contains('successful'));
    });

    test('handles PIN authentication failure', () async {
      // Arrange
      const testPin = '1234';
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'test-user');
      when(mockSecureStorage.getDeviceId()).thenAnswer((_) async => 'test-device');

      final mockPinResult = PinAuthResult(
        success: false,
        error: PinAuthError.invalidPin,
        message: 'Invalid PIN',
      );
      when(mockPinAuth.verifyPin(testPin)).thenAnswer((_) async => mockPinResult);

      // Act
      final result = await authenticationService.authenticateWithPin(testPin);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(AuthError.invalidPin));
      expect(result.message, contains('Invalid PIN'));
    });

    test('enrolls biometric successfully', () async {
      // Arrange
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'test-user');
      when(mockSecureStorage.getDeviceId()).thenAnswer((_) async => 'test-device');
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => false);

      final mockBiometricResult = BiometricAuthResult(
        success: true,
        message: 'Biometric authentication successful',
      );
      when(mockBiometricAuth.authenticateWithBiometrics()).thenAnswer((_) async => mockBiometricResult);

      final mockApiResult = ApiResult.success(AuthTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        role: 'employee',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
      when(mockApiService.enrollBiometric(
        userId: 'test-user',
        deviceId: 'test-device',
        biometricSignature: anyNamed('biometricSignature'),
      )).thenAnswer((_) async => mockApiResult);

      // Act
      final result = await authenticationService.enrollBiometric();

      // Assert
      expect(result.success, isTrue);
      expect(result.message, contains('enrolled successfully'));
    });

    test('handles biometric enrollment when already enrolled', () async {
      // Arrange
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => true);

      // Act
      final result = await authenticationService.enrollBiometric();

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(AuthError.alreadyEnrolled));
      expect(result.message, contains('already enrolled'));
    });

    test('sets up PIN successfully', () async {
      // Arrange
      const testPin = '1234';

      final mockPinResult = PinAuthResult(
        success: true,
        message: 'PIN set up successfully',
      );
      when(mockPinAuth.setupPin(testPin)).thenAnswer((_) async => mockPinResult);

      // Act
      final result = await authenticationService.setupPin(testPin);

      // Assert
      expect(result.success, isTrue);
      expect(result.message, contains('successfully'));
    });

    test('checks biometric availability correctly', () async {
      // Arrange
      when(mockBiometricAuth.isBiometricAvailable()).thenAnswer((_) async => true);
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => true);

      // Act
      final result = await authenticationService.canUseBiometricAuth();

      // Assert
      expect(result, isTrue);
    });

    test('checks PIN availability correctly', () async {
      // Arrange
      when(mockPinAuth.isPinSet()).thenAnswer((_) async => true);

      // Act
      final result = await authenticationService.canUsePinAuth();

      // Assert
      expect(result, isTrue);
    });

    test('gets available auth methods correctly', () async {
      // Arrange
      when(mockBiometricAuth.isBiometricAvailable()).thenAnswer((_) async => true);
      when(mockBiometricAuth.isBiometricEnrolled()).thenAnswer((_) async => true);
      when(mockPinAuth.isPinSet()).thenAnswer((_) async => true);

      // Act
      final result = await authenticationService.getAvailableAuthMethods();

      // Assert
      expect(result, contains(AuthMethod.biometric));
      expect(result, contains(AuthMethod.pin));
    });

    test('logs out correctly', () async {
      // Arrange
      when(mockApiService.logout()).thenAnswer((_) async {});

      // Act
      await authenticationService.logout();

      // Assert
      verify(mockApiService.logout()).called(1);
    });

    test('gets current user ID correctly', () async {
      // Arrange
      const testUserId = 'test-user-123';
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => testUserId);

      // Act
      final result = await authenticationService.getCurrentUserId();

      // Assert
      expect(result, equals(testUserId));
      verify(mockSecureStorage.getUserId()).called(1);
    });

    test('gets current user correctly', () async {
      // Arrange
      const testUser = {'name': 'Test User', 'role': 'employee'};
      when(mockApiService.getUserFromToken()).thenAnswer((_) async => testUser);

      // Act
      final result = await authenticationService.getCurrentUser();

      // Assert
      expect(result, equals(testUser));
      verify(mockApiService.getUserFromToken()).called(1);
    });

    test('disposes correctly', () {
      // Act
      authenticationService.dispose();

      // Assert
      verify(mockApiService.dispose()).called(1);
      verify(mockPinAuth.dispose()).called(1);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:item_manager/services/pin_auth_service.dart';
import 'package:item_manager/services/secure_storage_service.dart';

// Generate mocks
@GenerateMocks([SecureStorageService])
import 'pin_auth_service_test.mocks.dart';

void main() {
  group('PinAuthService', () {
    late PinAuthService pinAuthService;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      pinAuthService = PinAuthService(mockSecureStorage);
    });

    test('verifies PIN correctly when PIN is set', () async {
      // Arrange
      const testPin = '1234';
      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockSecureStorage.verifyPin(testPin)).thenAnswer((_) async => true);

      // Act
      final result = await pinAuthService.verifyPin(testPin);

      // Assert
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, contains('successful'));
    });

    test('handles PIN not set error', () async {
      // Arrange
      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => false);

      // Act
      final result = await pinAuthService.verifyPin('1234');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(PinAuthError.notSet));
      expect(result.message, contains('not set up'));
    });

    test('handles invalid PIN error', () async {
      // Arrange
      const testPin = '1234';
      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockSecureStorage.verifyPin(testPin)).thenAnswer((_) async => false);
      when(mockSecureStorage.recordFailedAttempt()).thenAnswer((_) async {});
      when(mockSecureStorage.getFailedAttempts()).thenAnswer((_) async => 1);

      // Act
      final result = await pinAuthService.verifyPin(testPin);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(PinAuthError.invalidPin));
      expect(result.message, contains('Invalid PIN'));
    });

    test('handles account lockout', () async {
      // Arrange
      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => true);
      when(mockSecureStorage.getRemainingLockoutTime()).thenAnswer((_) async => 300);

      // Act
      final result = await pinAuthService.verifyPin('1234');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(PinAuthError.lockedOut));
      expect(result.message, contains('locked'));
    });

    test('sets up PIN with valid format', () async {
      // Arrange
      const testPin = '1234';
      when(mockSecureStorage.storePinHash(any)).thenAnswer((_) async {});
      when(mockSecureStorage.setPinSet(true)).thenAnswer((_) async {});

      // Act
      final result = await pinAuthService.setupPin(testPin);

      // Assert
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, contains('successfully'));
    });

    test('rejects PIN with invalid format', () async {
      // Arrange
      const invalidPin = '12'; // Too short

      // Act
      final result = await pinAuthService.setupPin(invalidPin);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(PinAuthError.invalidFormat));
      expect(result.message, contains('4-6 digits'));
    });

    test('changes PIN successfully', () async {
      // Arrange
      const currentPin = '1234';
      const newPin = '5678';

      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockSecureStorage.verifyPin(currentPin)).thenAnswer((_) async => true);
      when(mockSecureStorage.storePinHash(any)).thenAnswer((_) async {});

      // Act
      final result = await pinAuthService.changePin(currentPin, newPin);

      // Assert
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, contains('successfully'));
    });

    test('rejects PIN change with wrong current PIN', () async {
      // Arrange
      const currentPin = '1234';
      const newPin = '5678';

      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);
      when(mockSecureStorage.isLockedOut()).thenAnswer((_) async => false);
      when(mockSecureStorage.verifyPin(currentPin)).thenAnswer((_) async => false);

      // Act
      final result = await pinAuthService.changePin(currentPin, newPin);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, equals(PinAuthError.invalidPin));
      expect(result.message, contains('Invalid PIN'));
    });

    test('checks PIN setup status correctly', () async {
      // Arrange
      when(mockSecureStorage.isPinSet()).thenAnswer((_) async => true);

      // Act
      final result = await pinAuthService.isPinSet();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.isPinSet()).called(1);
    });

    test('gets failed attempts count correctly', () async {
      // Arrange
      when(mockSecureStorage.getFailedAttempts()).thenAnswer((_) async => 3);

      // Act
      final result = await pinAuthService.getFailedAttempts();

      // Assert
      expect(result, equals(3));
      verify(mockSecureStorage.getFailedAttempts()).called(1);
    });

    test('validates PIN format correctly', () {
      // Test valid PINs
      expect(pinAuthService._isValidPin('1234'), isTrue);
      expect(pinAuthService._isValidPin('12345'), isTrue);
      expect(pinAuthService._isValidPin('123456'), isTrue);

      // Test invalid PINs
      expect(pinAuthService._isValidPin('123'), isFalse); // Too short
      expect(pinAuthService._isValidPin('1234567'), isFalse); // Too long
      expect(pinAuthService._isValidPin('12a4'), isFalse); // Contains letters
      expect(pinAuthService._isValidPin('12 4'), isFalse); // Contains space
      expect(pinAuthService._isValidPin(''), isFalse); // Empty
    });

    test('gets correct error messages', () {
      // Act & Assert
      expect(
        pinAuthService.getErrorMessage(PinAuthError.notSet),
        contains('not set up'),
      );
      expect(
        pinAuthService.getErrorMessage(PinAuthError.invalidPin),
        contains('Invalid PIN'),
      );
      expect(
        pinAuthService.getErrorMessage(PinAuthError.invalidFormat),
        contains('4-6 digits'),
      );
      expect(
        pinAuthService.getErrorMessage(PinAuthError.lockedOut),
        contains('locked'),
      );
    });
  });
}

// Extension to access private method for testing
extension PinAuthServiceTest on PinAuthService {
  bool _isValidPin(String pin) {
    final regex = RegExp(r'^\d{4,6}$');
    return regex.hasMatch(pin);
  }
}
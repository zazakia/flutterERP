# Technology Stack

## Framework & Language
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language (SDK ^3.9.2)
- **Material Design 3**: UI design system

## Key Dependencies
- **State Management**: Provider pattern
- **Authentication**: local_auth (biometric), JWT tokens
- **Storage**: SQLite (sqflite), flutter_secure_storage, shared_preferences
- **Networking**: HTTP client with offline-first approach
- **Security**: crypto, jwt_decoder
- **File Operations**: file_picker, path_provider
- **Testing**: flutter_test, mockito, build_runner

## Architecture Patterns
- **Provider Pattern**: For state management across the app
- **Repository Pattern**: Data access abstraction layer
- **Service Layer**: Business logic separation
- **Offline-First**: Local SQLite with sync capabilities

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload during development (automatic)
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/employee_test.dart

# Generate mocks (when needed)
flutter packages pub run build_runner build
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build iOS
flutter build ios

# Build for web
flutter build web

# Analyze code
flutter analyze
```

### Code Quality
- Uses `flutter_lints` for code analysis
- Follow Material Design guidelines
- Implement proper error handling
- Use secure storage for sensitive data
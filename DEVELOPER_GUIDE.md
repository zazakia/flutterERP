# Developer Guide for Flutter ERP Application

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio or VS Code
- Android/iOS device or emulator

### Installation

1. Clone or download the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate mock files for testing:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Project Structure

```
lib/
├── models/              # Data models (Employee, Attendance, Payroll)
├── providers/           # State management providers
├── services/            # Business logic and API services
├── widgets/             # UI components
└── main.dart           # Application entry point

test/
├── models/             # Model tests
├── services/           # Service tests
└── widget_test.dart    # Widget tests

assets/
└── images/             # Image assets
```

## Running the Application

### Development Mode
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk
```

#### iOS
```bash
flutter build ios
```

#### Web
```bash
flutter build web
```

## Testing

### Running All Tests
```bash
flutter test
```

### Running Specific Tests
```bash
# Run model tests
flutter test test/models/

# Run a specific test file
flutter test test/models/attendance_test.dart

# Run service tests
flutter test test/services/
```

### Generating Mock Files
When you add new tests that use Mockito annotations, you need to regenerate the mock files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Adding New Features

### 1. Create a New Model
1. Create a new file in `lib/models/`
2. Define your data model with:
   - Fields with appropriate types
   - Constructor
   - Factory method for JSON deserialization
   - Method for JSON serialization
   - CopyWith method for immutability
   - Equality and hash code methods
   - toString method for debugging

### 2. Create a New Service
1. Create a new file in `lib/services/`
2. Implement your business logic
3. Add API communication if needed
4. Handle errors appropriately
5. Include proper documentation

### 3. Create a New Provider
1. Create a new file in `lib/providers/`
2. Extend `ChangeNotifier`
3. Implement state management logic
4. Add methods for data manipulation
5. Notify listeners when state changes

### 4. Create New Widgets
1. Create a new file in `lib/widgets/`
2. Implement your UI components
3. Use providers for state management
4. Follow Material Design guidelines
5. Add proper error handling

### 5. Add Tests
1. Create a new test file in `test/` directory
2. Add unit tests for models
3. Add unit tests for services
4. Add widget tests for UI components

## Code Quality

### Linting
The project uses `flutter_lints` for code quality checks:
```bash
flutter analyze
```

### Formatting
Format your code with:
```bash
flutter format .
```

## Architecture Patterns

### Provider Pattern
The application uses the Provider pattern for state management:
- Providers manage application state
- Services handle business logic
- Models represent data structures
- Widgets display UI and interact with providers

### Separation of Concerns
- **Models**: Data structures and business entities
- **Providers**: State management and UI logic coordination
- **Services**: Business logic and API communication
- **Widgets**: UI components and user interaction

## Security Best Practices

### Data Storage
- Use `flutter_secure_storage` for sensitive data
- Never store passwords or tokens in plain text
- Use proper encryption for sensitive information

### Authentication
- Implement proper session management
- Use secure token storage
- Handle authentication errors gracefully

### Network Security
- Use HTTPS for all API communications
- Validate and sanitize all input data
- Implement proper error handling

## Performance Optimization

### Efficient State Management
- Use `ChangeNotifierProvider` for simple state
- Use `Consumer` widgets to minimize rebuilds
- Dispose of resources properly

### Memory Management
- Dispose of controllers and listeners
- Use proper image caching
- Avoid memory leaks

### UI Performance
- Use `const` constructors where possible
- Minimize widget rebuilds
- Use appropriate loading indicators

## Extending the Application

### Adding New Authentication Methods
1. Create a new service in `lib/services/`
2. Add the authentication method to `AuthenticationService`
3. Update the UI to support the new method

### Adding New Employee Fields
1. Update the `Employee` model
2. Update the database schema (if applicable)
3. Update the API service
4. Update the UI forms
5. Add tests for the new fields

### Adding New Reports
1. Create a new service for report generation
2. Add report models if needed
3. Create UI components for displaying reports
4. Add navigation to access reports

## Troubleshooting

### Common Issues

#### Missing Dependencies
If you see import errors, make sure to run:
```bash
flutter pub get
```

#### Test Failures
If tests are failing due to missing mocks, regenerate them:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Build Issues
If you encounter build issues, try:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Contributing

### Code Style
- Follow the existing code style
- Use meaningful variable and function names
- Add documentation to public APIs
- Write comprehensive tests

### Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## Deployment

### Preparing for Release
1. Update version numbers in `pubspec.yaml`
2. Update app icons and splash screens
3. Test on all target platforms
4. Run performance analysis
5. Ensure all tests pass

### Publishing
- Follow platform-specific guidelines for publishing
- Ensure compliance with app store requirements
- Monitor app performance and user feedback

## Support

For issues, questions, or contributions, please:
1. Check existing issues on the repository
2. Create a new issue with detailed information
3. Include steps to reproduce for bug reports
4. Provide screenshots or code examples when helpful
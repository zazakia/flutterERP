# Project Structure

## Root Directory Organization
```
lib/                    # Main application code
├── database/          # Database schema and setup
├── models/            # Data models and entities
├── providers/         # State management (Provider pattern)
├── repositories/      # Data access layer
├── services/          # Business logic and API services
├── widgets/           # UI components and screens
└── main.dart         # Application entry point

test/                  # Test files
├── models/           # Model unit tests
├── services/         # Service unit tests
├── widgets/          # Widget tests
└── widget_test.dart  # Main widget test

android/              # Android-specific configuration
ios/                  # iOS-specific configuration
web/                  # Web-specific assets
windows/              # Windows-specific configuration
linux/                # Linux-specific configuration
macos/                # macOS-specific configuration
```

## Architecture Layers

### Models (`lib/models/`)
- Data classes representing business entities
- Examples: `Employee`, `Attendance`, `Payroll`, `LeaveRequest`
- Should be immutable where possible
- Include JSON serialization methods

### Providers (`lib/providers/`)
- State management using Provider pattern
- Handle UI state and business logic coordination
- Examples: `AuthProvider`, `EmployeeProvider`, `AttendanceProvider`
- Extend `ChangeNotifier` for reactive updates

### Services (`lib/services/`)
- Business logic and external integrations
- API communication, authentication, storage
- Examples: `AuthenticationService`, `BiometricAuthService`, `EmployeeApiService`
- Keep services stateless and focused

### Repositories (`lib/repositories/`)
- Data access abstraction layer
- Handle local and remote data sources
- Implement offline-first patterns
- Example: `SimpleEmployeeRepository`

### Widgets (`lib/widgets/`)
- UI components and screens
- Follow Material Design principles
- Keep widgets focused and reusable
- Examples: `EmployeeDashboard`, `BiometricLoginWidget`

### Database (`lib/database/`)
- SQLite database setup and migrations
- Local storage for offline capabilities
- Example: `simple_database.dart`

## Naming Conventions
- **Files**: snake_case (e.g., `employee_provider.dart`)
- **Classes**: PascalCase (e.g., `EmployeeProvider`)
- **Variables/Methods**: camelCase (e.g., `getCurrentUser`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)

## File Organization Rules
- One class per file (with same name)
- Group related functionality in same directory
- Keep widgets in separate files for reusability
- Use barrel exports for clean imports when needed
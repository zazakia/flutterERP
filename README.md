# Flutter ERP Application

A comprehensive Employee Management System built with Flutter that includes biometric authentication, employee management, attendance tracking, payroll processing, and more.

## Features

### Authentication
- Biometric authentication (fingerprint, face recognition)
- PIN-based authentication
- Secure token storage
- Automatic token refresh
- User session management

### Employee Management
- Create, read, update, and delete employee records
- Search and filter employees
- Bulk operations (activate/deactivate)
- CSV import/export functionality
- Employee profiles with detailed information

### Attendance Tracking
- Clock in/out functionality
- Time tracking with geolocation
- Attendance history
- Manual attendance entry (admin only)
- Attendance reports

### Payroll Management
- Automated payroll calculation
- Payslip generation and viewing
- Payroll history
- Tax and deduction calculations
- Bonus and overtime support

### Offline Capabilities
- **Offline-First Architecture**: All operations work without internet
- **Local SQLite Database**: Fast, reliable local data storage
- **Automatic Sync**: Changes sync automatically when online
- **Conflict Resolution**: Smart handling of data conflicts
- **Sync Status**: Real-time sync status and pending changes indicator
- **Background Sync**: Seamless data synchronization

### User Interface
- Modern Material Design
- Responsive layout for all device sizes
- Intuitive navigation
- Dark mode support
- Customizable dashboard
- Offline/Online status indicators
- Automatic background sync

## Technical Architecture

### Frontend
- **Framework**: Flutter
- **State Management**: Provider
- **Authentication**: Local authentication (biometric/PIN)
- **Storage**: SQLite (Drift), Secure storage, Shared preferences
- **Networking**: HTTP client with offline-first approach
- **UI**: Material Design
- **Offline Support**: Full CRUD operations with automatic sync

### Backend (Conceptual)
- **API**: RESTful API
- **Authentication**: JWT Bearer tokens
- **Database**: Relational (PostgreSQL/MySQL)
- **Cloud Storage**: For document storage

### Data Models
1. Employee
2. Attendance
3. Payroll
4. Authentication tokens
5. Leave requests (planned)
6. Performance reviews (planned)

## Project Structure

```
lib/
├── models/              # Data models
├── providers/           # State management providers
├── services/            # API services and business logic
├── widgets/             # UI components
└── main.dart           # Application entry point

test/
├── models/             # Model tests
├── services/           # Service tests
└── widget_test.dart    # Widget tests

assets/
└── images/             # Image assets
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio or VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```bash
   cd flutter_erp
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Testing

The project includes comprehensive tests:

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

## Deployment

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the Flutter team for the amazing framework
- Inspired by modern ERP systems
- Built with security and user experience in mind

## Roadmap

### Phase 1: Core Features (Completed)
- [x] Authentication system
- [x] Employee management
- [x] Attendance tracking
- [x] Payroll processing

### Phase 2: Enhanced Features (In Progress)
- [ ] Leave management system
- [ ] Performance review system
- [ ] Reporting dashboard
- [ ] Advanced analytics

### Phase 3: Advanced Features (Planned)
- [ ] Mobile-specific features
- [ ] Third-party integrations
- [ ] Multi-language support
- [ ] Offline mode
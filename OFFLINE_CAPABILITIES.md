# FlutterERP Offline Capabilities

## Overview

FlutterERP now includes comprehensive offline capabilities using SQLite + Drift database, enabling full functionality without internet connectivity.

## Architecture

### Offline-First Approach
- **Local Database**: SQLite database stores all employee data locally
- **Automatic Sync**: Changes sync automatically when internet is available
- **Conflict Resolution**: Smart handling of data conflicts between local and remote
- **Background Sync**: Seamless synchronization without user intervention

### Database Structure

#### Tables
1. **Employees** - Complete employee records
2. **AttendanceRecords** - Clock in/out data
3. **PayrollRecords** - Payroll calculations and history
4. **LeaveRequests** - Leave request management
5. **SyncQueue** - Tracks pending synchronization items

### Key Features

#### 1. Offline Operations
- ✅ Create employees
- ✅ Update employee information
- ✅ Delete employees
- ✅ Search and filter employees
- ✅ View employee details

#### 2. Sync Management
- **Automatic Sync**: Happens in background when online
- **Manual Sync**: Users can trigger sync manually
- **Sync Status**: Real-time indicators show sync status
- **Pending Changes**: Visual indicators for unsynchronized data

#### 3. User Experience
- **Offline Banner**: Shows when device is offline
- **Sync Status Widget**: Displays connection status and pending changes
- **Error Handling**: Graceful handling of sync failures
- **Performance**: Fast local operations

## Implementation Details

### Repository Pattern
```dart
class EmployeeRepository {
  // Offline-first data access
  Future<List<Employee>> getEmployees() async {
    // 1. Get data from local database
    // 2. Try to sync with server if online
    // 3. Return local data (always available)
  }
}
```

### Sync Queue System
- All changes are queued for synchronization
- Retry mechanism for failed sync attempts
- Conflict resolution strategies
- Batch synchronization for efficiency

### Database Provider
```dart
class DatabaseProvider extends ChangeNotifier {
  // Manages database lifecycle
  // Handles sync operations
  // Provides sync status updates
}
```

## Usage

### Basic Operations
```dart
// All operations work offline
final employees = await employeeRepository.getEmployees();
await employeeRepository.createEmployee(newEmployee);
await employeeRepository.updateEmployee(employee);
await employeeRepository.deleteEmployee(employeeId);
```

### Sync Management
```dart
// Manual sync trigger
await databaseProvider.syncWithServer();

// Check sync status
final status = await employeeRepository.getSyncStatus();
```

### UI Components
- `SyncStatusWidget` - Shows sync status and pending changes
- `OfflineBanner` - Displays when offline
- Manual sync button in dashboard

## Benefits

### For Users
1. **Always Available**: App works without internet
2. **Fast Performance**: Local database operations are instant
3. **Seamless Experience**: Automatic sync when online
4. **Data Safety**: Local backup of all data

### For Business
1. **Reliability**: No downtime due to connectivity issues
2. **Productivity**: Employees can work anywhere
3. **Data Integrity**: Conflict resolution prevents data loss
4. **Scalability**: Reduces server load

## Technical Specifications

### Dependencies
```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.9
```

### Database File Location
- **Android**: `/data/data/com.example.app/documents/flutter_erp.db`
- **iOS**: `Documents/flutter_erp.db`
- **Windows**: `Documents/flutter_erp.db`

### Sync Strategy
1. **Create**: Add to local DB → Queue for sync → Sync when online
2. **Update**: Update local DB → Queue for sync → Sync when online
3. **Delete**: Remove from local DB → Queue for sync → Sync when online
4. **Fetch**: Get from local DB → Background sync from server

## Future Enhancements

### Planned Features
- [ ] Attendance offline tracking
- [ ] Payroll offline calculations
- [ ] Leave requests offline management
- [ ] File attachments offline storage
- [ ] Advanced conflict resolution UI
- [ ] Selective sync options
- [ ] Data export/import capabilities

### Performance Optimizations
- [ ] Database indexing optimization
- [ ] Lazy loading for large datasets
- [ ] Background sync scheduling
- [ ] Compression for sync data
- [ ] Incremental sync strategies

## Troubleshooting

### Common Issues

#### Sync Failures
- Check internet connectivity
- Verify server availability
- Review sync error messages
- Try manual sync

#### Database Issues
- Clear app data (last resort)
- Check available storage space
- Verify database permissions

#### Performance Issues
- Monitor database size
- Check for large sync queues
- Review indexing strategies

### Debug Information
- Sync status in dashboard
- Error logs in sync status widget
- Database size in app settings
- Pending sync count display

## Security Considerations

### Data Protection
- Local database encryption (planned)
- Secure sync protocols (HTTPS)
- Authentication token management
- Data validation on sync

### Privacy
- Local data stays on device
- Sync only when authenticated
- No data transmission without consent
- Audit trail for sync operations
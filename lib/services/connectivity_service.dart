import 'dart:io';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static const String _testUrl = 'https://www.google.com';
  static const Duration _timeout = Duration(seconds: 5);

  /// Check if device has internet connectivity
  Future<bool> isConnected() async {
    try {
      final response = await http.head(
        Uri.parse(_testUrl),
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check connectivity with custom URL (useful for checking API server)
  Future<bool> canReachServer(String serverUrl) async {
    try {
      final response = await http.head(
        Uri.parse(serverUrl),
      ).timeout(_timeout);
      
      return response.statusCode == 200 || response.statusCode == 404; // 404 is ok, means server is reachable
    } catch (e) {
      return false;
    }
  }

  /// Get network status details
  Future<Map<String, dynamic>> getNetworkStatus() async {
    final isConnected = await this.isConnected();
    
    return {
      'isConnected': isConnected,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
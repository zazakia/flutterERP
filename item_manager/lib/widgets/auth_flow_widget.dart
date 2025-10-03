import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'biometric_login_widget.dart';
import 'pin_login_widget.dart';

/// Main authentication flow widget that manages login state and navigation
class AuthFlowWidget extends StatefulWidget {
  final Widget authenticatedWidget;

  const AuthFlowWidget({
    super.key,
    required this.authenticatedWidget,
  });

  @override
  State<AuthFlowWidget> createState() => _AuthFlowWidgetState();
}

class _AuthFlowWidgetState extends State<AuthFlowWidget> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await context.read<AuthProvider>().initialize();
    } catch (e) {
      _showErrorSnackBar('Failed to initialize authentication: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen during initialization
        if (!authProvider.isInitialized) {
          return _buildLoadingScreen();
        }

        // Show authenticated widget if user is logged in
        if (authProvider.isAuthenticated) {
          return widget.authenticatedWidget;
        }

        // Show authentication screens if not logged in
        return _buildAuthScreens();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthScreens() {
    return FutureBuilder<List<AuthMethod>>(
      future: context.read<AuthProvider>().getAvailableAuthMethods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final availableMethods = snapshot.data ?? [];

        // If no authentication methods are available, show setup screen
        if (availableMethods.isEmpty) {
          return _buildSetupScreen();
        }

        // Default to biometric if available, otherwise PIN
        final defaultMethod = availableMethods.contains(AuthMethod.biometric)
            ? AuthMethod.biometric
            : AuthMethod.pin;

        return _buildLoginScreen(defaultMethod);
      },
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                const Icon(
                  Icons.security,
                  size: 80,
                  color: Colors.white,
                ),

                const SizedBox(height: 32),

                const Text(
                  'Welcome to\nBrayan Lee\'s Payroll System',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Text(
                  'To get started, please set up your preferred authentication method.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Setup PIN Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setupPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Set Up PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Setup Biometric Button (if available)
                FutureBuilder<bool>(
                  future: context.read<AuthProvider>().canUseBiometricAuth(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _setupBiometric,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Set Up Biometric',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginScreen(AuthMethod defaultMethod) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Brayan Lee\'s Payroll System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              const Spacer(),

              // Authentication method buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Biometric login button
                    FutureBuilder<bool>(
                      future: context.read<AuthProvider>().canUseBiometricAuth(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return _buildAuthButton(
                            icon: Icons.fingerprint,
                            label: 'Biometric Login',
                            onPressed: _showBiometricLogin,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    if (defaultMethod == AuthMethod.biometric) const SizedBox(height: 16),

                    // PIN login button
                    FutureBuilder<bool>(
                      future: context.read<AuthProvider>().canUsePinAuth(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return _buildAuthButton(
                            icon: Icons.pin,
                            label: 'PIN Login',
                            onPressed: _showPinLogin,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Setup button for missing methods
                    TextButton(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild to show setup screen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Set up authentication method',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3A8A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showBiometricLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BiometricLoginWidget(
          onSuccess: _handleAuthSuccess,
          onFailure: _handleAuthFailure,
          onUsePinFallback: _showPinLogin,
        ),
      ),
    );
  }

  void _showPinLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinLoginWidget(
          onSuccess: _handleAuthSuccess,
          onFailure: _handleAuthFailure,
          onUseBiometric: _showBiometricLogin,
        ),
      ),
    );
  }

  void _setupPin() {
    _showPinSetupDialog();
  }

  void _setupBiometric() {
    _showBiometricSetupDialog();
  }

  Future<void> _showPinSetupDialog() async {
    String? pin;
    String? confirmPin;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set Up PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a 4-6 digit PIN for authentication.'),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => pin = value,
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => confirmPin = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (pin != null && confirmPin != null && pin == confirmPin) {
                Navigator.of(context).pop();
                final result = await context.read<AuthProvider>().setupPin(pin!);

                if (result.success) {
                  _showSuccessSnackBar('PIN set up successfully');
                  setState(() {}); // Refresh to show login options
                } else {
                  _showErrorSnackBar(result.message);
                }
              } else {
                _showErrorSnackBar('PINs do not match');
              }
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBiometricSetupDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Up Biometric'),
        content: const Text(
          'You will be prompted to authenticate with your device\'s biometric sensor to enroll it for this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await context.read<AuthProvider>().enrollBiometric();

              if (result.success) {
                _showSuccessSnackBar('Biometric authentication enrolled successfully');
                setState(() {}); // Refresh to show login options
              } else {
                _showErrorSnackBar(result.message);
              }
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  void _handleAuthSuccess() {
    Navigator.of(context).pop(); // Close login dialog
    _showSuccessSnackBar('Authentication successful');
  }

  void _handleAuthFailure() {
    // Error message is shown within the login widgets
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
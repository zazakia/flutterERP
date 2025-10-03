import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../services/biometric_auth_service.dart';
import '../providers/auth_provider.dart';

/// Animated biometric login widget with fingerprint scanning UI
class BiometricLoginWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onUsePinFallback;

  const BiometricLoginWidget({
    super.key,
    required this.onSuccess,
    required this.onFailure,
    required this.onUsePinFallback,
  });

  @override
  State<BiometricLoginWidget> createState() => _BiometricLoginWidgetState();
}

class _BiometricLoginWidgetState extends State<BiometricLoginWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _errorController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _errorAnimation;

  Timer? _authenticationTimer;
  bool _isAuthenticating = false;
  String _statusMessage = 'Place your finger on the sensor';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAuthentication();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _errorController.dispose();
    _authenticationTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Pulse animation for fingerprint icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    // Error animation
    _errorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startAuthentication() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final authService = context.read<AuthProvider>().authService;
      final result = await authService.authenticateWithBiometrics();

      if (result.success) {
        await _showSuccessAnimation();
        widget.onSuccess();
      } else {
        if (result.needsEnrollment) {
          await _showEnrollmentPrompt();
        } else {
          await _showErrorAnimation(result.message);
          widget.onFailure();
        }
      }
    } catch (e) {
      await _showErrorAnimation('Authentication failed: $e');
      widget.onFailure();
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _showSuccessAnimation() async {
    setState(() {
      _statusMessage = 'Success!';
    });

    _pulseController.stop();
    await _successController.forward();

    // Keep success state visible briefly
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _showErrorAnimation(String message) async {
    setState(() {
      _statusMessage = message;
    });

    await _errorController.forward();

    // Reset error animation after delay
    await Future.delayed(const Duration(seconds: 2));
    await _errorController.reverse();

    setState(() {
      _statusMessage = 'Place your finger on the sensor';
    });
  }

  Future<void> _showEnrollmentPrompt() async {
    setState(() {
      _statusMessage = 'Biometric not enrolled. Please enroll first.';
    });

    await Future.delayed(const Duration(seconds: 2));

    // Navigate to enrollment or PIN fallback
    widget.onUsePinFallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Blue
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

              // Header
              const Text(
                'Biometric Login',
                style: TextStyle(
                  fontSize: 28,
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

              // Animated Fingerprint Icon
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseAnimation,
                  _scaleAnimation,
                  _errorAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isAuthenticating
                        ? _pulseAnimation.value
                        : _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getFingerprintColor(),
                        boxShadow: [
                          BoxShadow(
                            color: _getFingerprintColor().withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _getFingerprintIcon(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Status Message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey<String>(_statusMessage),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Progress Indicator
              if (_isAuthenticating)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Use PIN button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAuthenticating ? null : widget.onUsePinFallback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Use PIN Instead',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isAuthenticating
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFingerprintColor() {
    if (_errorController.isAnimating) {
      return Colors.red;
    } else if (_successController.isCompleted) {
      return Colors.green;
    } else if (_isAuthenticating) {
      return Colors.blue;
    } else {
      return Colors.white;
    }
  }

  Widget _getFingerprintIcon() {
    if (_errorController.isAnimating) {
      return const Icon(
        Icons.error_outline,
        size: 60,
        color: Colors.white,
      );
    } else if (_successController.isCompleted) {
      return const Icon(
        Icons.check_circle_outline,
        size: 60,
        color: Colors.white,
      );
    } else {
      return const Icon(
        Icons.fingerprint,
        size: 60,
        color: Color(0xFF1E3A8A),
      );
    }
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../providers/auth_provider.dart';

/// PIN login widget with numeric keypad
class PinLoginWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onUseBiometric;

  const PinLoginWidget({
    super.key,
    required this.onSuccess,
    required this.onFailure,
    required this.onUseBiometric,
  });

  @override
  State<PinLoginWidget> createState() => _PinLoginWidgetState();
}

class _PinLoginWidgetState extends State<PinLoginWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String _pin = '';
  String _displayPin = '';
  bool _isAuthenticating = false;
  String _errorMessage = '';
  Timer? _lockoutTimer;
  int _remainingLockoutTime = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkLockoutStatus() async {
    final authService = context.read<AuthProvider>().authService;

    if (await authService.isLockedOut()) {
      _remainingLockoutTime = await authService.getRemainingLockoutTime();

      _lockoutTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) async {
          final remaining = await authService.getRemainingLockoutTime();
          setState(() {
            _remainingLockoutTime = remaining;
          });

          if (remaining <= 0) {
            timer.cancel();
            setState(() {
              _errorMessage = '';
            });
          }
        },
      );

      setState(() {
        _errorMessage = 'Account locked. Try again in $_remainingLockoutTime seconds';
      });
    }
  }

  void _addDigit(String digit) {
    if (_pin.length < 6 && _remainingLockoutTime <= 0) {
      setState(() {
        _pin += digit;
        _displayPin = '*' * _pin.length;
        _errorMessage = '';
      });

      // Auto-submit when PIN is complete
      if (_pin.length == 6) {
        _authenticate();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty && !_isAuthenticating) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _displayPin = '*' * _pin.length;
        _errorMessage = '';
      });
    }
  }

  Future<void> _authenticate() async {
    if (_pin.length < 4 || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final authService = context.read<AuthProvider>().authService;
      final result = await authService.authenticateWithPin(_pin);

      if (result.success) {
        widget.onSuccess();
      } else {
        await _showError(result.message);

        if (result.error == AuthError.lockedOut) {
          await _checkLockoutStatus();
        }

        widget.onFailure();
      }
    } catch (e) {
      await _showError('Authentication failed: $e');
      widget.onFailure();
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _showError(String message) async {
    setState(() {
      _errorMessage = message;
      _pin = '';
      _displayPin = '';
    });

    await _shakeController.forward();
    await Future.delayed(const Duration(seconds: 2));
    await _shakeController.reverse();
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
                'PIN Login',
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

              // PIN Display
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeAnimation.value * (8 * (1 - _shakeAnimation.value)),
                      0,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _errorMessage.isNotEmpty
                              ? Colors.red.withOpacity(0.5)
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _displayPin.isEmpty ? 'Enter PIN' : _displayPin,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),

                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          if (_remainingLockoutTime > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Locked for $_remainingLockoutTime seconds',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Numeric Keypad
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Row 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('1'),
                        _buildNumberButton('2'),
                        _buildNumberButton('3'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Row 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('4'),
                        _buildNumberButton('5'),
                        _buildNumberButton('6'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Row 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('7'),
                        _buildNumberButton('8'),
                        _buildNumberButton('9'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Row 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 80), // Spacer for empty button
                        _buildNumberButton('0'),
                        _buildBackspaceButton(),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Use Biometric button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAuthenticating || _remainingLockoutTime > 0
                            ? null
                            : widget.onUseBiometric,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Use Biometric',
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

  Widget _buildNumberButton(String number) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextButton(
        onPressed: _isAuthenticating || _remainingLockoutTime > 0
            ? null
            : () => _addDigit(number),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextButton(
        onPressed: _isAuthenticating || _remainingLockoutTime > 0
            ? null
            : _removeDigit,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(
          Icons.backspace_outlined,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dashboard.dart';
import 'security/pin_security_service.dart';
import 'security/secure_storage_service.dart';

class QuickAccessSetupScreen extends StatefulWidget {
  const QuickAccessSetupScreen({super.key});

  @override
  State<QuickAccessSetupScreen> createState() => _QuickAccessSetupScreenState();
}

class _QuickAccessSetupScreenState extends State<QuickAccessSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final PinSecurityService _pinSecurity = PinSecurityService();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _isBiometricSelected = false;
  String _pin = '';
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await _secureStorage.read(
      SecureStorageService.biometricEnabledKey,
    );
    if (mounted && enabled == 'true') {
      setState(() {
        _isBiometricSelected = true;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    bool canCheck = await _localAuth.canCheckBiometrics;
    List<BiometricType> available = await _localAuth.getAvailableBiometrics();

    setState(() {
      _canCheckBiometrics = canCheck;
      _availableBiometrics = available;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to set up biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(
          SecureStorageService.biometricEnabledKey,
          'true',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  Future<void> _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == 4) {
        final pin = _pin;
        final enrolled = await _pinSecurity.enrollPin(pin);
        if (mounted) {
          setState(() {
            _pin = '';
          });
        }
        if (!enrolled || !mounted) return;

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        });
      }
    }
  }

  void _onBackPressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF1A5E38),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Quick Access Setup',
                      style: TextStyle(
                        color: Color(0xFF1A5E38),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    const Text(
                      'Choose a faster login method for future sessions.',
                      style: TextStyle(color: Color(0xFF1A5E38), fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    // Biometric and PIN buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBiometricSelected = true;
                              });
                              if (_canCheckBiometrics &&
                                  _availableBiometrics.isNotEmpty) {
                                _authenticateWithBiometrics();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No biometric sensors available',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isBiometricSelected
                                    ? const Color(0xFF1A5E38)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1A5E38),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fingerprint,
                                    color: _isBiometricSelected
                                        ? Colors.white
                                        : const Color(0xFF1A5E38),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Biometric',
                                    style: TextStyle(
                                      color: _isBiometricSelected
                                          ? Colors.white
                                          : const Color(0xFF1A5E38),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBiometricSelected = false;
                              });
                              _secureStorage.write(
                                SecureStorageService.biometricEnabledKey,
                                'false',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: !_isBiometricSelected
                                    ? const Color(0xFF1A5E38)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1A5E38),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: !_isBiometricSelected
                                        ? Colors.white
                                        : const Color(0xFF1A5E38),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PIN',
                                    style: TextStyle(
                                      color: !_isBiometricSelected
                                          ? Colors.white
                                          : const Color(0xFF1A5E38),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (!_isBiometricSelected) ...[
                      // PIN entry prompt
                      const Text(
                        'ENTER 4-DIGIT PIN',
                        style: TextStyle(
                          color: Color(0xFF1A5E38),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // PIN circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _pin.length
                                    ? const Color(0xFF1A5E38)
                                    : const Color(0xFFBDBDBD),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      // Numeric keypad
                      _buildKeypad(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonSize = (constraints.maxWidth / 5).clamp(56.0, 80.0);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('1', buttonSize),
                _buildKeypadButton('2', buttonSize),
                _buildKeypadButton('3', buttonSize),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('4', buttonSize),
                _buildKeypadButton('5', buttonSize),
                _buildKeypadButton('6', buttonSize),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('7', buttonSize),
                _buildKeypadButton('8', buttonSize),
                _buildKeypadButton('9', buttonSize),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: buttonSize),
                _buildKeypadButton('0', buttonSize),
                GestureDetector(
                  onTap: _onBackPressed,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A5E38)),
                    ),
                    child: const Icon(
                      Icons.backspace,
                      color: Color(0xFF1A5E38),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKeypadButton(String number, double size) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A5E38)),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF1A5E38),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

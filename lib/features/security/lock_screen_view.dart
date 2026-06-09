import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/services/security_service.dart';
import 'package:nexus/features/main_navigation.dart';

class LockScreenView extends StatefulWidget {
  const LockScreenView({super.key});

  @override
  State<LockScreenView> createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<LockScreenView> {
  final TextEditingController _pinController = TextEditingController();
  bool _isConfigured = true;
  bool _isSetupMode = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    final configured = await SecurityService.isAppConfigured();
    setState(() {
      _isConfigured = configured;
      _isSetupMode = !configured;
    });

    if (configured) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final password = await SecurityService.getDatabasePasswordWithBiometrics();
    if (password != null) {
      _unlockAndGoHome(password);
    } else {
      setState(() {
        _errorMessage = 'Biometric authentication failed or canceled. Use PIN.';
      });
    }
  }

  Future<void> _handlePinSubmit() async {
    final input = _pinController.text;
    if (input.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits.');
      return;
    }

    if (_isSetupMode) {
      await SecurityService.initializeSecurity(input);
      final password = await SecurityService.getDatabasePasswordWithPin(input);
      if (password != null) _unlockAndGoHome(password);
    } else {
      final password = await SecurityService.getDatabasePasswordWithPin(input);
      if (password != null) {
        _unlockAndGoHome(password);
      } else {
        setState(() {
          _pinController.clear();
          _errorMessage = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  void _unlockAndGoHome(String dbPassword) async {
    await DatabaseHelper.instance.databaseWithPassword(dbPassword);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSetupMode ? Icons.security : Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isSetupMode ? 'Secure Your Data' : 'App Locked',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSetupMode
                    ? 'Create a backup PIN to encrypt your local database.'
                    : 'Unlock Mike\'s Admin to manage your space.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 16),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: TextStyle(letterSpacing: 16),
                ),
                onChanged: (val) {
                  if (val.length >= 4) _handlePinSubmit();
                },
              ),

              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),

              if (!_isSetupMode)
                TextButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text(
                    'Use Biometrics',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

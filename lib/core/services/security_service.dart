import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();
  static const _keyDbPassword = 'sql_cipher_db_password';
  static const _keyUserPin = 'user_backup_pin';

  /// Random key of 64 char
  static String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static Future<bool> isAppConfigured() async {
    final pin = await _storage.read(key: _keyUserPin);
    return pin != null;
  }

  static Future<void> initializeSecurity(String pin) async {
    await _storage.write(key: _keyUserPin, value: pin);

    final dbPassword = _generateRandomKey();
    await _storage.write(key: _keyDbPassword, value: dbPassword);
  }

  static Future<String?> getDatabasePasswordWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics || !isDeviceSupported) return null;

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Nexus',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        return await _storage.read(key: _keyDbPassword);
      }
    } catch (e) {
      // print('Error en autenticación biométrica: $e');
    }
    return null;
  }

  static Future<String?> getDatabasePasswordWithPin(String inputPin) async {
    final savedPin = await _storage.read(key: _keyUserPin);
    if (savedPin == inputPin) {
      return await _storage.read(key: _keyDbPassword);
    }
    return null;
  }

  static Future<bool> changePin(String oldPin, String newPin) async {
    final savedPin = await _storage.read(key: _keyUserPin);
    if (savedPin == oldPin) {
      await _storage.write(key: _keyUserPin, value: newPin);
      return true;
    }
    return false;
  }
}

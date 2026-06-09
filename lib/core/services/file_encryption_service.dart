import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FileEncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyDbPassword = 'sql_cipher_db_password';

  /// app master password -> 32 bytes key
  static Future<enc.Key> _getEncryptionKey() async {
    final masterKey = await _storage.read(key: _keyDbPassword);
    if (masterKey == null) throw Exception('Master key not found.');

    // AES-256
    final keyBytes = masterKey.padRight(32).substring(0, 32);
    return enc.Key.fromUtf8(keyBytes);
  }

  static Future<String> encryptAndSaveFile(File sourceFile) async {
    // AES-256 + IV (Init vector)
    final key = await _getEncryptionKey();
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final Uint8List fileBytes = await sourceFile.readAsBytes();

    final encryptedData = encrypter.encryptBytes(fileBytes, iv: iv);

    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDocDir.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourceFile.path)}.enc';
    final String targetPath = p.join(vaultDir.path, fileName);

    final File encryptedFile = File(targetPath);
    await encryptedFile.writeAsBytes(encryptedData.bytes);

    return targetPath;
  }

  static Future<File> decryptFile(String encryptedFilePath) async {
    final key = await _getEncryptionKey();
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final File encryptedFile = File(encryptedFilePath);
    if (!await encryptedFile.exists()) {
      throw Exception('Encrypted file not found on disk.');
    }

    final Uint8List encryptedBytes = await encryptedFile.readAsBytes();

    final decryptedBytes = encrypter.decryptBytes(
      enc.Encrypted(encryptedBytes),
      iv: iv,
    );

    final tempDir = await getTemporaryDirectory();
    final originalName = p
        .basename(encryptedFilePath)
        .replaceFirst(RegExp(r'^\d+_'), '')
        .replaceAll('.enc', '');
    final String tempPath = p.join(tempDir.path, originalName);

    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(decryptedBytes);

    return tempFile;
  }
}

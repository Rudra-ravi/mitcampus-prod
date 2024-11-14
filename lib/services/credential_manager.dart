import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialManager {
  static const _storage = FlutterSecureStorage();
  static const _hodPasswordKey = 'hod_password';

  static Future<void> saveHODPassword(String password) async {
    await _storage.write(key: _hodPasswordKey, value: password);
  }

  static Future<String?> getHODPassword() async {
    return await _storage.read(key: _hodPasswordKey);
  }
} 
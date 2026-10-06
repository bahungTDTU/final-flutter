import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class ProtectedVaultLease {
  ProtectedVaultLease(this.key, this.salt, this.data);
  final SecretKey key;
  final List<int> salt;
  final Map<String, dynamic> data;
}

/// Password-bound cache inside the existing device/account encrypted vault.
/// No password or derived key is persisted. AAD prevents swapping accounts/notes.
class ProtectedNoteVault {
  ProtectedNoteVault(this.account, this.noteId, {this.workFactor = iterations});
  final String account, noteId;
  static const iterations = 600000;
  final cipher = AesGcm.with256bits();
  final int workFactor;
  Pbkdf2 get kdf =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: workFactor, bits: 256);
  List<int> get aad =>
      utf8.encode('NoteTogether:protected:v1:$account:$noteId');

  Future<ProtectedVaultLease> create(
    String password,
    Map<String, dynamic> data,
  ) async {
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    final key = await kdf.deriveKeyFromPassword(
      password: password,
      nonce: [...salt, ...aad],
    );
    return ProtectedVaultLease(key, salt, data);
  }

  Future<ProtectedVaultLease> open(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    try {
      if (envelope['version'] != 1 || envelope['iterations'] != workFactor) {
        throw const FormatException();
      }
      final salt = base64Decode(envelope['salt'] as String);
      if (salt.length != 32) throw const FormatException();
      final key = await kdf.deriveKeyFromPassword(
        password: password,
        nonce: [...salt, ...aad],
      );
      final plain = await cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: key,
        aad: aad,
      );
      final data = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(plain)) as Map,
      );
      return ProtectedVaultLease(key, salt, data);
    } catch (_) {
      throw StateError(
        'Mật khẩu cục bộ chưa đúng hoặc bản mã bị hỏng. Bản nháp mã hóa vẫn được giữ.',
      );
    }
  }

  Future<Map<String, dynamic>> seal(
    ProtectedVaultLease lease,
    Map<String, dynamic> payload,
  ) async {
    final box = await cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: lease.key,
      aad: aad,
    );
    return {
      'version': 1,
      'iterations': workFactor,
      'salt': base64Encode(lease.salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
      'dirty': payload['draft'] != null || payload['operation'] != null,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

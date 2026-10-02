import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'local_store.dart';

abstract class RecoveryKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class DeviceRecoveryKeys implements RecoveryKeyStore {
  const DeviceRecoveryKeys();
  static const storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);
}

class VaultException implements Exception {
  const VaultException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Encrypts account snapshots, including drafts, outbox and recoveries.
/// Session metadata is outside this envelope. Keys are never stored in Sembast.
class EncryptedAccountStore implements LocalStore {
  EncryptedAccountStore(this.records, this.keys);
  final LocalStore records;
  final RecoveryKeyStore keys;
  final cipher = AesGcm.with256bits();
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.catchError((_) {}).then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  List<int> _aad(String account) =>
      utf8.encode('NoteTogether:account:v1:$account');
  String _keyName(String account, String id) =>
      'notetogether.vault.v1:$account:$id';

  Future<SecretKey> _key(String account, String id) async {
    final encoded = await keys.read(_keyName(account, id));
    if (encoded == null) {
      throw const VaultException(
        'Thiếu khóa phục hồi của thiết bị. Dữ liệu mã hóa vẫn được giữ.',
      );
    }
    List<int> bytes;
    try {
      bytes = base64Decode(encoded);
    } catch (_) {
      throw const VaultException('Khóa phục hồi không hợp lệ.');
    }
    if (bytes.length != 32) {
      throw const VaultException('Khóa phục hồi không hợp lệ.');
    }
    return SecretKey(bytes);
  }

  Future<Map<String, dynamic>> _decrypt(
    String account,
    Map<String, dynamic> raw,
  ) async {
    try {
      if (raw['vault_version'] != 1) throw const FormatException();
      final secret = await _key(account, raw['key_id'] as String);
      final plain = await cipher.decrypt(
        SecretBox(
          base64Decode(raw['ciphertext'] as String),
          nonce: base64Decode(raw['nonce'] as String),
          mac: Mac(base64Decode(raw['mac'] as String)),
        ),
        secretKey: secret,
        aad: _aad(account),
      );
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(plain)) as Map);
    } on VaultException {
      rethrow;
    } catch (_) {
      throw const VaultException(
        'Không đọc được kho phục hồi mã hóa. Dữ liệu gốc vẫn được giữ.',
      );
    }
  }

  Future<void> _encrypt(
    String account,
    Map<String, dynamic> value, {
    bool rotate = false,
  }) async {
    final existing = await records.read(account);
    String id;
    SecretKey secret;
    if (!rotate && existing != null && existing.containsKey('vault_version')) {
      if (existing['vault_version'] != 1) {
        throw const VaultException('Phiên bản kho mã hóa chưa được hỗ trợ.');
      }
      id = existing['key_id'] as String;
      secret = await _key(account, id);
    } else {
      id = const Uuid().v4();
      secret = await cipher.newSecretKey();
      final encoded = base64Encode(await secret.extractBytes());
      await keys.write(_keyName(account, id), encoded);
      // Publish ciphertext only after the platform can read the durable key back.
      if (await keys.read(_keyName(account, id)) != encoded) {
        throw const VaultException(
          'Chưa lưu được khóa phục hồi. Dữ liệu gốc vẫn được giữ.',
        );
      }
    }
    final box = await cipher.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: secret,
      aad: _aad(account),
    );
    final compactLegacy =
        records is SembastLocalStore &&
        existing != null &&
        (!existing.containsKey('vault_version') ||
            existing['needs_compaction'] == true);
    final envelope = <String, dynamic>{
      'vault_version': 1,
      'key_id': id,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
      if (compactLegacy) 'needs_compaction': true,
    };
    await records.write(account, envelope);
    await _finishMigration(account, envelope);
  }

  Future<void> _finishMigration(
    String account,
    Map<String, dynamic> envelope,
  ) async {
    if (envelope['needs_compaction'] != true) return;
    if (records is! SembastLocalStore) {
      throw const VaultException('Kho cần hoàn tất chuyển đổi dữ liệu cũ.');
    }
    // A durable marker retries compaction after crash/failure, before exposing data.
    await (records as SembastLocalStore).compact();
    await records.write(
      account,
      Map<String, dynamic>.from(envelope)..remove('needs_compaction'),
    );
  }

  @override
  Future<Map<String, dynamic>?> read(String key) => _serial(() async {
    final raw = await records.read(key);
    if (raw == null || !key.startsWith('account:')) return raw;
    if (raw.containsKey('vault_version')) {
      final value = await _decrypt(key, raw);
      await _finishMigration(key, raw);
      return value;
    }
    // Transactional migration: never expose a legacy snapshot if encryption fails.
    await _encrypt(key, raw);
    return raw;
  });

  @override
  Future<void> write(String key, Map<String, dynamic> value) {
    // Freeze nested payloads before asynchronous key/storage work.
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map,
    );
    return _serial(
      () => key.startsWith('account:')
          ? _encrypt(key, snapshot)
          : records.write(key, snapshot),
    );
  }

  @override
  Future<void> remove(String key) => _serial(() => records.remove(key));

  /// Atomic envelope rotation; old keys remain for backups/in-flight readers.
  /// Never rotate automatically on logout or account/note password changes.
  Future<void> rotateAccount(String account) => _serial(() async {
    if (!account.startsWith('account:')) throw ArgumentError('Not an account');
    final raw = await records.read(account);
    if (raw == null) return;
    final value = raw.containsKey('vault_version')
        ? await _decrypt(account, raw)
        : raw;
    await _encrypt(account, value, rotate: true);
  });
}

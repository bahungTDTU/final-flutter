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
/// Session/profile use a separate device-key envelope. Keys never enter Sembast.
class EncryptedAccountStore implements DraftLocalStore {
  EncryptedAccountStore(this.records, this.keys);
  final LocalStore records;
  final RecoveryKeyStore keys;
  final cipher = AesGcm.with256bits();
  Future<void> _tail = Future.value();
  @override
  bool get supportsDraftWrites => records is AtomicLocalStore;
  String _draftKey(String account) => 'drafts:$account';

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.catchError((_) {}).then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  List<int> _aad(String account) =>
      utf8.encode('NoteTogether:account:v1:$account');
  String _keyName(String account, String id) =>
      'notetogether.vault.v1:$account:$id';

  void _validateSession(Map<String, dynamic> value) {
    final user = value['user'], token = value['token'];
    if (user is! Map ||
        user['id'] is! String ||
        (user['id'] as String).isEmpty ||
        token is! String ||
        token.isEmpty) {
      throw const VaultException(
        'Phiên đăng nhập đã lưu không hợp lệ. Dữ liệu gốc vẫn được giữ.',
      );
    }
  }

  Future<void> _finishSessionRemoval() async {
    // A tombstone makes logout durable even if compaction is interrupted.
    if (records is SembastLocalStore) {
      await (records as SembastLocalStore).compact();
    }
    await records.remove('session');
  }

  Future<void> _encryptSession(Map<String, dynamic> value) async {
    _validateSession(value);
    var existing = await records.read('session');
    if (existing?['session_removed'] == true) {
      await _finishSessionRemoval();
      existing = null;
    }
    const id = 'device';
    if (existing?.containsKey('vault_version') == true) {
      if (existing!['key_id'] != id) {
        throw const VaultException(
          'Kho phiên đăng nhập không hợp lệ. Dữ liệu gốc vẫn được giữ.',
        );
      }
      // Never overwrite unreadable credentials, even during another login.
      _validateSession(await _decrypt('session', existing));
    } else if (existing != null) {
      _validateSession(existing);
    }
    final keyName = _keyName('session', id);
    var encoded = await keys.read(keyName);
    if (encoded == null && existing?.containsKey('vault_version') != true) {
      encoded = base64Encode(
        await (await cipher.newSecretKey()).extractBytes(),
      );
      await keys.write(keyName, encoded);
      if (await keys.read(keyName) != encoded) {
        throw const VaultException(
          'Chưa lưu được khóa phiên đăng nhập. Phiên cũ vẫn được giữ.',
        );
      }
    }
    final box = await cipher.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: await _key('session', id),
      aad: _aad('session'),
    );
    final needsCompaction =
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
      if (needsCompaction) 'needs_compaction': true,
    };
    await records.write('session', envelope);
    await _finishMigration('session', envelope);
  }

  Future<Map<String, dynamic>?> _readSession(Map<String, dynamic>? raw) async {
    if (raw == null) return null;
    if (raw['session_removed'] == true) {
      await _finishSessionRemoval();
      return null;
    }
    if (!raw.containsKey('vault_version')) {
      _validateSession(raw);
      await _encryptSession(raw);
      return raw;
    }
    if (raw['key_id'] != 'device') {
      throw const VaultException(
        'Kho phiên đăng nhập không hợp lệ. Dữ liệu gốc vẫn được giữ.',
      );
    }
    final value = await _decrypt('session', raw);
    _validateSession(value);
    await _finishMigration('session', raw);
    return value;
  }

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
    Map<String, dynamic> raw, {
    String? aadKey,
  }) async {
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
        aad: _aad(aadKey ?? account),
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
    if ((existing == null || !existing.containsKey('vault_version')) &&
        await records.read(_draftKey(account)) != null) {
      throw const VaultException(
        'Thiếu snapshot mã hóa gốc; bản nháp mã hóa vẫn được giữ.',
      );
    }
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
    if (records is AtomicLocalStore) {
      // Folding a draft projection and retiring it is one durable publish.
      await (records as AtomicLocalStore).writeBatch(
        {account: envelope},
        {_draftKey(account)},
      );
    } else {
      if (await records.read(_draftKey(account)) != null) {
        throw const VaultException(
          'Kho cần hỗ trợ transaction để gộp bản nháp.',
        );
      }
      await records.write(account, envelope);
    }
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

  Future<Map<String, dynamic>?> _read(String key) async {
    final raw = await records.read(key);
    if (key == 'session') return _readSession(raw);
    if (!key.startsWith('account:')) return raw;
    if (raw == null) {
      if (await records.read(_draftKey(key)) != null) {
        throw const VaultException(
          'Thiếu snapshot gốc; bản nháp mã hóa vẫn được giữ.',
        );
      }
      return null;
    }
    Map<String, dynamic> value;
    if (raw.containsKey('vault_version')) {
      value = await _decrypt(key, raw);
      await _finishMigration(key, raw);
    } else {
      // Transactional migration before releasing any legacy plaintext.
      await _encrypt(key, raw);
      value = raw;
    }
    final projection = await records.read(_draftKey(key));
    if (projection != null) {
      if (projection['key_id'] != raw['key_id']) {
        throw const VaultException(
          'Bản nháp và snapshot khác phiên khóa. Dữ liệu vẫn được giữ.',
        );
      }
      final patch = await _decrypt(key, projection, aadKey: _draftKey(key));
      if (patch['drafts'] is! Map) {
        throw const VaultException(
          'Kho bản nháp không hợp lệ. Dữ liệu vẫn được giữ.',
        );
      }
      value['drafts'] = Map<String, dynamic>.from(patch['drafts'] as Map);
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>?> read(String key) => _serial(() => _read(key));

  @override
  Future<void> writeDrafts(String account, Map<String, dynamic> drafts) {
    if (!account.startsWith('account:')) throw ArgumentError('Not an account');
    if (!supportsDraftWrites) {
      throw const VaultException('Kho không hỗ trợ ghi bản nháp nguyên tử.');
    }
    // Freeze only the small draft projection before asynchronous key/IO work.
    final snapshot = jsonDecode(jsonEncode({'drafts': drafts})) as Map;
    return _serial(() async {
      final root = await records.read(account);
      if (root?['vault_version'] != 1 || root?['needs_compaction'] == true) {
        throw const VaultException(
          'Snapshot gốc chưa sẵn sàng; giữ bản nháp và thử lại.',
        );
      }
      final id = root!['key_id'] as String;
      final key = await _key(account, id);
      final box = await cipher.encrypt(
        utf8.encode(jsonEncode(snapshot)),
        secretKey: key,
        aad: _aad(_draftKey(account)),
      );
      await (records as AtomicLocalStore).writeBatch({
        _draftKey(account): {
          'vault_version': 1,
          'key_id': id,
          'nonce': base64Encode(box.nonce),
          'ciphertext': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        },
      }, {});
    });
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) {
    // Freeze nested payloads before asynchronous key/storage work.
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map,
    );
    return _serial(
      () => key == 'session'
          ? _encryptSession(snapshot)
          : key.startsWith('account:')
          ? _encrypt(key, snapshot)
          : records.write(key, snapshot),
    );
  }

  @override
  Future<void> remove(String key) => _serial(() async {
    if (key == 'session' && records is SembastLocalStore) {
      await records.write('session', {
        'session_removed': true,
        'needs_compaction': true,
      });
      await _finishSessionRemoval();
    } else if (key.startsWith('account:') && records is AtomicLocalStore) {
      await (records as AtomicLocalStore).writeBatch({}, {key, _draftKey(key)});
    } else {
      await records.remove(key);
    }
  });

  /// Atomic envelope rotation; old keys remain for backups/in-flight readers.
  /// Never rotate automatically on logout or account/note password changes.
  Future<void> rotateAccount(String account) => _serial(() async {
    if (!account.startsWith('account:')) throw ArgumentError('Not an account');
    final value = await _read(account);
    if (value == null) return;
    await _encrypt(account, value, rotate: true);
  });
}

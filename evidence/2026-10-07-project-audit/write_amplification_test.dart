import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';

import '../../test/support.dart';

class AuditRecords extends MemoryStore {
  int writes = 0, encodedBytes = 0;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key.startsWith('account:')) {
      writes++;
      encodedBytes += utf8.encode(jsonEncode(value)).length;
    }
    await super.write(key, value);
  }
}

class AuditKeys implements RecoveryKeyStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('Audit records whole-account encrypted write volume during typing', () async {
    final records = AuditRecords();
    final api = Api('http://unused.invalid');
    final controller = AppController(api, EncryptedAccountStore(records, AuditKeys()));
    controller.user = {'id': 'audit-fixture'};
    controller.token = 'audit-unused';
    controller.notes = List.generate(500, (i) => Note(
      id: 'note-$i', title: 'Fixture $i', content: List.filled(1000, 'x').join(),
      revision: 1, updatedAt: '2026-10-07T00:00:00Z'));
    await controller.draft('note-0', 'Fixture 0', 'warm-up');
    records.writes = 0;
    records.encodedBytes = 0;
    await Future.wait(List.generate(20, (i) =>
      controller.draft('note-0', 'Fixture 0', 'Typing ${List.filled(i + 1, 'x').join()}')));
    final result = {
      'measured_at_utc': DateTime.now().toUtc().toIso8601String(),
      'target': 'Flutter host / real EncryptedAccountStore AES-GCM / in-memory records and keys',
      'notes': 500, 'content_chars_per_note': 1000, 'draft_updates': 20,
      'account_envelope_writes': records.writes, 'total_encoded_envelope_bytes': records.encodedBytes,
      'bytes_per_write': records.encodedBytes ~/ records.writes,
      'disk_latency_or_fps_measured': false, 'network_requests': 0,
    };
    expect(records.writes, 20);
    expect(records.values['account:audit-fixture']!['vault_version'], 1);
    final decoded = await controller.local.read('account:audit-fixture');
    expect((decoded!['drafts'] as Map)['note-0']['content'], 'Typing ${List.filled(20, 'x').join()}');
    File('evidence/2026-10-07-project-audit/write-volume.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(result)}\n');
    print(const JsonEncoder.withIndent('  ').convert(result));
    controller.dispose();
    api.client.close();
  });
}

// QA entrypoint; excluded from production builds.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:uuid/uuid.dart';

import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:note_together/state/app_controller.dart';

const run = String.fromEnvironment('QA_RUN_ID');
const url = String.fromEnvironment('API_URL');
const title = 'OS relaunch QA';
final rich = storeDocumentDelta([
  {
    'insert': 'Tiếng Việt: ghi chú bền vững',
    'attributes': {'bold': true},
  },
  {'insert': '\nDòng thứ hai sau khi mất kết nối.\n'},
]);
final draftRich = storeDocumentDelta([
  {
    'insert': 'Bản nháp chưa autosave',
    'attributes': {'italic': true},
  },
  {'insert': '\n'},
]);

void require(bool condition, String label) {
  if (!condition) throw StateError(label);
}

Future<String> fingerprint(Map<String, dynamic> operation) async =>
    (await Sha256().hash(utf8.encode(jsonEncode(operation)))).bytes.join(',');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(home: Scaffold(body: Text('Native OS relaunch QA'))),
  );
  if (!RegExp(r'^[a-zA-Z0-9-]{1,64}$').hasMatch(run)) return;
  final directory = await getApplicationSupportDirectory();
  final report = File(path.join(directory.path, 'qa-os-$run.json'));
  Future<void> result(Map<String, dynamic> value) async {
    // Synthetic metadata only; no secrets.
    await report.writeAsString(jsonEncode(value), flush: true);
  }

  try {
    final origin = Uri.parse(url);
    require(
      origin.scheme == 'http' &&
          {'127.0.0.1', '10.0.2.2', 'localhost'}.contains(origin.host) &&
          origin.userInfo.isEmpty &&
          origin.path.isEmpty &&
          !origin.hasQuery &&
          !origin.hasFragment,
      'Disposable local API required',
    );
    final filename = path.join(directory.path, 'qa-os-$run.db');
    final api = Api(url);
    final failedSocket = Api(
      'http://127.0.0.1:65530',
      requestTimeout: const Duration(seconds: 2),
    );
    Future<AppController> controller(Api backend) async {
      final db = await databaseFactoryIo.openDatabase(filename);
      final c = AppController(
        backend,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      )..setForeground(false);
      await c.initialize();
      return c;
    }

    Future<void> close(AppController c) async {
      c.dispose();
      final local = c.local as EncryptedAccountStore;
      await (local.records as SembastLocalStore).database.close();
    }

    if (!await report.exists()) {
      final c = await controller(api);
      require(c.user == null, 'Run ID must use a new QA database');
      require(
        await c.authenticate(
          register: true,
          email: 'os-$run@example.test',
          name: 'OS QA',
          password: 'Disposable-OS-2026!',
          confirmation: 'Disposable-OS-2026!',
        ),
        'QA registration',
      );
      final id = const Uuid().v4();
      await c.save(id, title, 'Server baseline');
      for (var i = 0; i < 60 && (c.syncing || c.pending.isNotEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!c.syncing) await c.synchronize();
      }
      require(c.pending.isEmpty, 'Baseline must be acknowledged');
      await close(c);
      final offline = await controller(failedSocket);
      await offline.save(id, title, rich);
      for (var i = 0; i < 50 && offline.syncing; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      require(!offline.online, 'Real failed socket required');
      require(offline.pending.length == 1, 'Exactly one pending edit');
      final draftId = const Uuid().v4();
      await offline.draft(draftId, ' ', draftRich);
      require(offline.drafts[draftId]['content'] == draftRich, 'Durable draft');
      await result({
        'stage': 'ready_for_force_stop',
        'note_id': id,
        'draft_id': draftId,
        'op_id': offline.pending.single['op_id'],
        'base_revision': offline.pending.single['base_revision'],
        'operation_fingerprint': await fingerprint(offline.pending.single),
        'pid': pid,
      });
      // Leave the database open for the host force-stop.
      return;
    }
    final before = jsonDecode(await report.readAsString()) as Map;
    require(before['stage'] == 'ready_for_force_stop', 'Unexpected QA stage');
    require(before['pid'] != pid, 'A different OS process must resume');
    final offline = await controller(failedSocket);
    require(offline.token != null, 'Encrypted session survived');
    final noteId = before['note_id'] as String;
    final draftId = before['draft_id'] as String;
    require(offline.notes.single.id == noteId, 'Stable note UUID');
    require(offline.notes.single.content == rich, 'Exact rich Delta survived');
    require(offline.drafts[draftId]['content'] == draftRich, 'Draft survived');
    require(offline.pending.length == 1, 'Pending operation survived');
    require(
      offline.pending.single['op_id'] == before['op_id'] &&
          offline.pending.single['base_revision'] == before['base_revision'] &&
          offline.pending.single['content'] == rich,
      'Immutable pending identity/base/payload',
    );
    require(
      await fingerprint(offline.pending.single) ==
          before['operation_fingerprint'],
      'Complete pending payload fingerprint unchanged',
    );
    final raw = await File(filename).readAsString();
    require(
      !raw.contains('Tiếng Việt:') &&
          !raw.contains('Bản nháp chưa autosave') &&
          !raw.contains(offline.token!),
      'No QA content/session plaintext in Sembast file',
    );
    await close(offline);
    final reconnect = await controller(api);
    for (var i = 0; i < 60; i++) {
      if (!reconnect.syncing) await reconnect.synchronize();
      if (reconnect.pending.isEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    require(reconnect.pending.isEmpty, 'Reconnect acknowledged operation');
    final remote =
        await api.call('GET', '/notes', token: reconnect.token) as List;
    require(
      remote.length == 1 && remote.single['id'] == noteId,
      'No duplicate',
    );
    require(remote.single['content'] == rich, 'Exact backend rich content');
    require(
      reconnect.drafts[draftId]['content'] == draftRich,
      'Draft retained',
    );
    await close(reconnect);
    api.client.close();
    failedSocket.client.close();
    await result({
      'stage': 'pass',
      'pid_before': before['pid'],
      'pid_after': pid,
      'stable_uuid': true,
      'exact_delta': true,
      'invalid_draft_retained': true,
      'immutable_operation': true,
      'encrypted_file': true,
      'backend_exactly_one': true,
      'scope':
          'Native core with real force-stop; controller input, not IME/UI QA',
    });
  } catch (error) {
    await result({'stage': 'fail', 'error_type': error.runtimeType.toString()});
    // Log assertion labels only.
    if (error is StateError) debugPrint('OS QA assertion: ${error.message}');
  }
}

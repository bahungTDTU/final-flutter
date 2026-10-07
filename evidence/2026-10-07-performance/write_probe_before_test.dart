// Baseline compatibility helper prepared after QA; use base Git5b82996.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';

class ProbeKeys implements RecoveryKeyStore {
  final values = <String,String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key]=value; }
}
class ProbeStore extends SembastLocalStore {
  ProbeStore(super.database);
  int bytes=0, publishes=0, roots=0;
  void count(Map<String,Map<String,dynamic>> values) {
    publishes++;
    for(final item in values.entries) {
      bytes+=utf8.encode(jsonEncode(item.value)).length;
      if(item.key=='account:measure') roots++;
    }
  }
  @override
  Future<void> write(String key, Map<String,dynamic> value) async {
    count({key:value});
    await super.write(key,value);
  }
}
void main() {
  test('Real encrypted Sembast write-volume probe; not an FPS test', () async {
    final folder=await Directory.systemTemp.createTemp('notetogether-write-probe-');
    final result=<Map<String,dynamic>>[];
    try {
      for(var repetition=0;repetition<5;repetition++) {
        final databasePath='${folder.path}/run-$repetition.db';
        var db=await databaseFactoryIo.openDatabase(databasePath);
        final records=ProbeStore(db), keys=ProbeKeys();
        final local=EncryptedAccountStore(records,keys);
        final api=Api('http://unused.invalid');
        final controller=AppController(api,local)..user={'id':'measure'}..token='fixture-unused';
        controller.notes=List.generate(500,(i)=>Note(id:'note-$i',title:'Fixture $i',
          content:'x'*1000,revision:1,updatedAt:'2026-10-07T00:00:00Z'));
        await local.write('account:measure',{'notes':controller.notes.map((n)=>n.toListingJson()).toList(),
          'pending':[],'drafts':{},'protected_vaults':{},'preferences':{'grid':true,'dark':false,'font_size':16}});
        await local.write('session',{'user':{'id':'measure'},'token':'fixture-unused'});
        controller.setForeground(false);
        await controller.initialize();
        records.bytes=records.publishes=records.roots=0;
        final clock=Stopwatch()..start();
        await Future.wait(List.generate(20,(i)=>controller.draft('note-0','Fixture 0','Typing ${'x'*(i+1)}')));
        clock.stop();
        result.add({'encoded_write_bytes':records.bytes,'publish_transactions':records.publishes,
          'full_account_writes':records.roots,'elapsed_ms':clock.elapsedMicroseconds/1000});
        controller.dispose(); api.client.close(); await db.close();
        db=await databaseFactoryIo.openDatabase(databasePath);
        final restored=await EncryptedAccountStore(SembastLocalStore(db),keys).read('account:measure');
        expect((restored!['notes'] as List),hasLength(500));
        expect((restored['drafts'] as Map)['note-0']['content'],'Typing ${'x'*20}');
        await db.close();
      }
      final destination=Platform.environment['PERF_OUTPUT']!;
      File(destination)..createSync(recursive:true)..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert({
        'measured_at_utc':DateTime.now().toUtc().toIso8601String(),
        'target':'Windows Flutter host / real AES-GCM / file Sembast / memory key provider',
        'notes':500,'chars_per_note':1000,'draft_updates':20,'repetitions':5,
        'seed_excluded':true,'reopen_latest_draft':true,'fps_or_native_latency_measured':false,'runs':result})}\n');
    } finally {
      final parent=await Directory.systemTemp.resolveSymbolicLinks();
      if(!folder.absolute.path.startsWith('$parent${Platform.pathSeparator}notetogether-write-probe-')) {
        throw StateError('Unexpected temporary cleanup path');
      }
      await folder.delete(recursive:true);
    }
  });
}

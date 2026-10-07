import 'package:sembast/sembast.dart';

abstract class LocalStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> remove(String key);
}

/// All writes/deletes commit together, or leave the previous records intact.
abstract class AtomicLocalStore implements LocalStore {
  Future<void> writeBatch(
    Map<String, Map<String, dynamic>> values,
    Set<String> removed,
  );
}

/// Optional small draft projection; other stores retain full-snapshot behavior.
abstract class DraftLocalStore implements LocalStore {
  bool get supportsDraftWrites;
  Future<void> writeDrafts(String account, Map<String, dynamic> drafts);
}

class SembastLocalStore implements AtomicLocalStore {
  SembastLocalStore(this.database);
  final Database database;
  final store = stringMapStoreFactory.store('accounts');
  Future<void> compact() => database.compact();
  @override
  Future<Map<String, dynamic>?> read(String key) =>
      store.record(key).get(database);
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await database.transaction((txn) => store.record(key).put(txn, value));
  }

  @override
  Future<void> remove(String key) async {
    await store.record(key).delete(database);
  }

  @override
  Future<void> writeBatch(
    Map<String, Map<String, dynamic>> values,
    Set<String> removed,
  ) async {
    await database.transaction((txn) async {
      for (final entry in values.entries) {
        await store.record(entry.key).put(txn, entry.value);
      }
      for (final key in removed) {
        await store.record(key).delete(txn);
      }
    });
  }
}

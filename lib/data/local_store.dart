import 'package:sembast/sembast.dart';

abstract class LocalStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> remove(String key);
}

class SembastLocalStore implements LocalStore {
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
}

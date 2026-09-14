import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'cache_store.g.dart';

class CacheEntry {
  const CacheEntry({required this.payload, required this.fetchedAt});

  final Map<String, dynamic> payload;
  final DateTime fetchedAt;

  Duration get age => DateTime.now().difference(fetchedAt);
}

class CacheStore {
  const CacheStore(this._db);

  final AppDatabase _db;

  Future<CacheEntry?> read(String key) async {
    try {
      final row = await (_db.select(
        _db.cachedDocuments,
      )..where((t) => t.key.equals(key))).getSingleOrNull();

      if (row == null) return null;

      final decoded = jsonDecode(row.payload);
      if (decoded is! Map<String, dynamic>) return null;

      return CacheEntry(payload: decoded, fetchedAt: row.fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> payload) async {
    try {
      await _db
          .into(_db.cachedDocuments)
          .insertOnConflictUpdate(
            CachedDocument(
              key: key,
              payload: jsonEncode(payload),
              fetchedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      //
    }
  }

  Future<void> remove(String key) async {
    try {
      await (_db.delete(
        _db.cachedDocuments,
      )..where((t) => t.key.equals(key))).go();
    } catch (_) {
      //
    }
  }

  Future<void> clear() async {
    try {
      await _db.delete(_db.cachedDocuments).go();
    } catch (_) {
      //
    }
  }
}

@Riverpod(keepAlive: true)
CacheStore cacheStore(Ref ref) => CacheStore(ref.watch(appDatabaseProvider));

abstract final class CacheKeys {
  static const dashboard = 'dashboard';

  static String course(String id) => 'course:$id';

  static String material(String id) => 'material:$id';
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_store.dart';

part 'todo_seen_store.g.dart';

class TodoSeenStore {
  const TodoSeenStore(this._cache);

  final CacheStore _cache;

  Future<Set<String>?> read() async {
    final keys = (await _cache.read(CacheKeys.todoSeen))?.payload['keys'];
    if (keys is! List) return null;

    return {
      for (final key in keys)
        if (key is String) key,
    };
  }

  Future<void> write(Set<String> keys) =>
      _cache.write(CacheKeys.todoSeen, {'keys': keys.toList()});
}

@Riverpod(keepAlive: true)
TodoSeenStore todoSeenStore(Ref ref) =>
    TodoSeenStore(ref.watch(cacheStoreProvider));

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/stale_while_revalidate.dart';
import '../domain/todo_list.dart';
import 'todo_api.dart';

part 'todo_repository.g.dart';

class TodoRepository {
  const TodoRepository(this._api, this._cache);

  final TodoApi _api;
  final CacheStore _cache;

  Stream<Cached<TodoList>> watch() => staleWhileRevalidate(
    cache: _cache,
    key: CacheKeys.todo,
    fetch: _api.fetch,
    decode: TodoList.fromJson,
  );
}

@Riverpod(keepAlive: true)
TodoRepository todoRepository(Ref ref) =>
    TodoRepository(ref.watch(todoApiProvider), ref.watch(cacheStoreProvider));

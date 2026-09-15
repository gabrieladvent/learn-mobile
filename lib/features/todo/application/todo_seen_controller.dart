import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/todo_seen_store.dart';
import '../domain/todo_list.dart';
import '../domain/todo_seen.dart';

part 'todo_seen_controller.g.dart';

@riverpod
class TodoSeenController extends _$TodoSeenController {
  @override
  Future<TodoSeen> build() async {
    final keys = await ref.watch(todoSeenStoreProvider).read();

    return TodoSeen(seen: keys);
  }

  Future<void> observe(
    TodoList list, {
    required bool viewing,
    bool newVisit = false,
  }) async {
    await future;
    if (!ref.mounted) return;

    final current = state.requireValue;
    final next = current.observe(list, viewing: viewing, newVisit: newVisit);
    state = AsyncData(next);

    if (!setEquals(next.seen, current.seen)) {
      await ref.read(todoSeenStoreProvider).write(next.seen!);
    }
  }
}

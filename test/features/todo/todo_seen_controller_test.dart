import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/todo/application/todo_seen_controller.dart';
import 'package:learn_mobile/features/todo/data/todo_seen_store.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';

class _MemoryStore implements TodoSeenStore {
  _MemoryStore([this.keys]);

  Set<String>? keys;
  int writes = 0;

  @override
  Future<Set<String>?> read() async => keys;

  @override
  Future<void> write(Set<String> keys) async {
    writes++;
    this.keys = keys;
  }
}

TodoList listOf(List<String> ids) => TodoList(
  later: [
    for (final id in ids)
      TodoItem(id: id, kind: TodoKind.assignment, state: TodoState.pending),
  ],
);

ProviderContainer _containerWith(_MemoryStore store) {
  final container = ProviderContainer(
    overrides: [todoSeenStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  container.listen(todoSeenControllerProvider, (_, _) {});

  return container;
}

void main() {
  // Catatan harus bertahan setelah aplikasi ditutup. Kalau hanya di memori,
  // setiap kali aplikasi dibuka semua item dijadikan patokan ulang — dan item
  // yang benar-benar baru tidak akan pernah terhitung.
  test(
    'yang sudah dilihat masih diingat setelah aplikasi dibuka ulang',
    () async {
      final store = _MemoryStore({'assignment:a'});

      final first = _containerWith(store);
      await first
          .read(todoSeenControllerProvider.notifier)
          .observe(listOf(['a', 'b']), viewing: true, newVisit: true);

      final reopened = _containerWith(store);
      final seen = await reopened.read(todoSeenControllerProvider.future);

      expect(seen.unseenIn(listOf(['a', 'b'])), 0);
    },
  );

  test('tidak menulis ke database kalau tidak ada yang berubah', () async {
    final store = _MemoryStore({'assignment:a'});
    final container = _containerWith(store);
    final controller = container.read(todoSeenControllerProvider.notifier);

    await controller.observe(listOf(['a']), viewing: true, newVisit: true);
    await controller.observe(listOf(['a', 'b']), viewing: false);

    expect(store.writes, 0);
  });
}

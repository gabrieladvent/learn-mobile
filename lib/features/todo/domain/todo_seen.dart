import 'package:flutter/foundation.dart';

import 'todo_list.dart';

@immutable
class TodoSeen {
  const TodoSeen({this.seen, this.highlighted = const {}});

  final Set<String>? seen;
  final Set<String> highlighted;

  int unseenIn(TodoList list) {
    final seen = this.seen;
    if (seen == null) return 0;

    return list.allKeys.where((key) => !seen.contains(key)).length;
  }

  TodoSeen observe(
    TodoList list, {
    required bool viewing,
    bool newVisit = false,
  }) {
    final current = list.allKeys;
    final seen = this.seen;

    if (seen == null) return TodoSeen(seen: current);
    if (!viewing) return this;

    final kept = newVisit
        ? const <String>{}
        : highlighted.intersection(current);

    return TodoSeen(
      seen: current,
      highlighted: {...kept, ...current.difference(seen)},
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/todo/application/todo_controller.dart';
import '../features/todo/application/todo_seen_controller.dart';

const _todoBranch = 1;

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool get _onTodoTab => widget.navigationShell.currentIndex == _todoBranch;

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final enteredTodo =
        _onTodoTab && oldWidget.navigationShell.currentIndex != _todoBranch;
    if (enteredTodo) _observeTodo(newVisit: true);
  }

  void _observeTodo({bool newVisit = false}) {
    final list = ref.read(todoProvider).value?.value;
    if (list == null) return;

    ref
        .read(todoSeenControllerProvider.notifier)
        .observe(list, viewing: _onTodoTab, newVisit: newVisit);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todoProvider, (_, next) {
      if (next.hasValue) _observeTodo();
    });

    final list = ref.watch(todoProvider).value?.value;
    final seen = ref.watch(todoSeenControllerProvider).value;
    final unseen = _onTodoTab || list == null || seen == null
        ? 0
        : seen.unseenIn(list);

    final shell = widget.navigationShell;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: unseen,
              isLabelVisible: unseen > 0,
              child: const Icon(Icons.checklist_rounded),
            ),
            label: 'To-do',
          ),
        ],
      ),
    );
  }
}

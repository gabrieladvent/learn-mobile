import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cached.dart';
import '../data/todo_repository.dart';
import '../domain/todo_list.dart';

part 'todo_controller.g.dart';

@riverpod
Stream<Cached<TodoList>> todo(Ref ref) =>
    ref.watch(todoRepositoryProvider).watch();

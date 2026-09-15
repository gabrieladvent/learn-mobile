import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_list.freezed.dart';
part 'todo_list.g.dart';

enum TodoKind { assignment, exam, unknown }

enum TodoState { pending, available, upcoming, unknown }

@freezed
abstract class TodoList with _$TodoList {
  const TodoList._();

  const factory TodoList({
    @Default(<TodoItem>[]) List<TodoItem> today,
    @JsonKey(name: 'this_week') @Default(<TodoItem>[]) List<TodoItem> thisWeek,
    @Default(<TodoItem>[]) List<TodoItem> later,
    @JsonKey(name: 'count_this_week') @Default(0) int countThisWeek,
  }) = _TodoList;

  factory TodoList.fromJson(Map<String, dynamic> json) =>
      _$TodoListFromJson(json);

  List<TodoItem> get restOfWeek {
    final shownToday = {for (final item in today) item.key};

    return [
      for (final item in thisWeek)
        if (!shownToday.contains(item.key)) item,
    ];
  }

  bool get isEmpty => today.isEmpty && thisWeek.isEmpty && later.isEmpty;

  Set<String> get allKeys => {
    for (final item in [...today, ...thisWeek, ...later]) item.key,
  };
}

@freezed
abstract class TodoItem with _$TodoItem {
  const TodoItem._();

  const factory TodoItem({
    required String id,
    @JsonKey(unknownEnumValue: TodoKind.unknown)
    @Default(TodoKind.unknown)
    TodoKind kind,
    @JsonKey(unknownEnumValue: TodoState.unknown)
    @Default(TodoState.unknown)
    TodoState state,
    String? title,
    @JsonKey(name: 'subject_name') String? subjectName,
    DateTime? deadline,
    @JsonKey(name: 'starts_at') DateTime? startsAt,
    @JsonKey(name: 'available_from') DateTime? availableFrom,
    @JsonKey(name: 'available_until') DateTime? availableUntil,
    @JsonKey(name: 'is_today') @Default(false) bool isToday,
    @JsonKey(name: 'is_within_week') @Default(false) bool isWithinWeek,
    @JsonKey(name: 'material_id') String? materialId,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);

  String get key => '${kind.name}:$id';

  bool get isLocked => kind == TodoKind.exam && state == TodoState.upcoming;
}

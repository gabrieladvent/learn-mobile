import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';

Map<String, dynamic> item(
  String id, {
  String kind = 'assignment',
  String state = 'pending',
  bool isToday = false,
  bool isWithinWeek = false,
}) => <String, dynamic>{
  'kind': kind,
  'state': state,
  'id': id,
  'title': 'Item $id',
  'subject_name': 'Matematika',
  'deadline': '2026-09-14T23:59:00+07:00',
  'starts_at': null,
  'available_from': null,
  'available_until': null,
  'is_today': isToday,
  'is_within_week': isWithinWeek,
  'material_id': 'material-$id',
};

void main() {
  group('TodoList.fromJson', () {
    test('membaca payload sesuai kontrak', () {
      final todayItem = item('a', isToday: true, isWithinWeek: true);

      final list = TodoList.fromJson(<String, dynamic>{
        'today': [todayItem],
        'this_week': [todayItem],
        'later': <dynamic>[],
        'count_this_week': 1,
      });

      final first = list.today.single;
      expect(first.kind, TodoKind.assignment);
      expect(first.state, TodoState.pending);
      expect(first.subjectName, 'Matematika');
      expect(first.materialId, 'material-a');
      expect(first.deadline, DateTime.parse('2026-09-14T23:59:00+07:00'));
      expect(first.isToday, isTrue);
      expect(list.countThisWeek, 1);
    });

    test('payload kosong berarti daftar kosong, bukan crash', () {
      expect(TodoList.fromJson(<String, dynamic>{}).isEmpty, isTrue);
    });

    // Backend boleh menambah jenis baru kapan saja. Aplikasi lama yang masih
    // terpasang di HP siswa tidak boleh gagal membaca SELURUH daftar hanya
    // karena satu item berjenis asing.
    test('jenis dan status yang belum dikenal tidak membuatnya gagal', () {
      final parsed = TodoItem.fromJson(item('x', kind: 'project', state: 'x'));

      expect(parsed.kind, TodoKind.unknown);
      expect(parsed.state, TodoState.unknown);
    });
  });

  group('TodoList.restOfWeek', () {
    // Server memasukkan item hari ini ke `this_week` juga. Kalau dirender apa
    // adanya, tugas hari ini muncul dua kali di layar.
    test('tidak mengulang item yang sudah ada di Hari ini', () {
      final list = TodoList.fromJson(<String, dynamic>{
        'today': [item('a', isToday: true, isWithinWeek: true)],
        'this_week': [
          item('a', isToday: true, isWithinWeek: true),
          item('b', isWithinWeek: true),
        ],
      });

      expect(list.restOfWeek.map((i) => i.id), ['b']);
    });

    test('tugas dan ujian dengan id sama tetap dua item berbeda', () {
      final list = TodoList.fromJson(<String, dynamic>{
        'today': [item('x', isToday: true, isWithinWeek: true)],
        'this_week': [
          item('x', isToday: true, isWithinWeek: true),
          item('x', kind: 'exam', state: 'upcoming', isWithinWeek: true),
        ],
      });

      expect(list.restOfWeek.single.kind, TodoKind.exam);
    });
  });

  test('hanya ujian yang belum dibuka yang terkunci', () {
    TodoItem parse(String kind, String state) =>
        TodoItem.fromJson(item('i', kind: kind, state: state));

    expect(parse('exam', 'upcoming').isLocked, isTrue);
    expect(parse('exam', 'available').isLocked, isFalse);
    expect(parse('assignment', 'pending').isLocked, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';
import 'package:learn_mobile/features/todo/presentation/widgets/todo_item_tile.dart';

void main() {
  // Senin, 14 September 2026, 08.00.
  final now = DateTime(2026, 9, 14, 8);

  String describe(TodoItem item) => describeTodoSchedule(item, now: now);

  group('describeTodoSchedule', () {
    test('tugas menyebut tenggatnya', () {
      expect(
        describe(
          TodoItem(
            id: 'a',
            kind: TodoKind.assignment,
            deadline: DateTime(2026, 9, 14, 23, 59),
          ),
        ),
        'Tenggat hari ini 23.59',
      );
    });

    test('tugas tanpa tenggat tidak dikarang tanggalnya', () {
      expect(
        describe(const TodoItem(id: 'a', kind: TodoKind.assignment)),
        'Tanpa tenggat',
      );
    });

    test('ujian yang belum dibuka menyebut kapan mulai', () {
      expect(
        describe(
          TodoItem(
            id: 'e',
            kind: TodoKind.exam,
            state: TodoState.upcoming,
            startsAt: DateTime(2026, 9, 15, 7),
          ),
        ),
        'Mulai besok 07.00',
      );
      expect(
        describe(
          const TodoItem(
            id: 'e',
            kind: TodoKind.exam,
            state: TodoState.upcoming,
          ),
        ),
        'Jadwal menyusul',
      );
    });

    // Untuk ujian yang sedang dibuka, yang penting bagi siswa adalah kapan
    // kesempatannya habis — bukan kapan ia dibuka.
    test('ujian yang sedang dibuka menyebut kapan ditutup', () {
      expect(
        describe(
          TodoItem(
            id: 'e',
            kind: TodoKind.exam,
            state: TodoState.available,
            availableFrom: DateTime(2026, 9, 14, 7),
            availableUntil: DateTime(2026, 9, 14, 12),
          ),
        ),
        'Dibuka sampai hari ini 12.00',
      );
    });

    test('jenis yang belum dikenal tidak diberi keterangan', () {
      expect(describe(const TodoItem(id: 'x')), isEmpty);
    });
  });
}

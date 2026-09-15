import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';
import 'package:learn_mobile/features/todo/domain/todo_seen.dart';

TodoItem assignment(String id) =>
    TodoItem(id: id, kind: TodoKind.assignment, state: TodoState.pending);

TodoList listOf(List<String> ids) =>
    TodoList(later: [for (final id in ids) assignment(id)]);

void main() {
  group('TodoSeen', () {
    // Siswa yang baru memasang aplikasi tidak "melewatkan" apa pun. Menandai
    // seluruh daftarnya sebagai baru hanya membuat badge dan label "Baru"
    // tidak berarti apa-apa sejak hari pertama.
    test(
      'pertama kali: semua yang ada dijadikan patokan, bukan dianggap baru',
      () {
        final seen = const TodoSeen().observe(
          listOf(['a', 'b']),
          viewing: false,
        );

        expect(seen.unseenIn(listOf(['a', 'b'])), 0);
        expect(seen.highlighted, isEmpty);
      },
    );

    test('sebelum ada patokan, badge tidak menghitung apa pun', () {
      expect(const TodoSeen().unseenIn(listOf(['a'])), 0);
    });

    test('item yang muncul setelah patokan dihitung sebagai baru', () {
      const seen = TodoSeen(seen: {'assignment:a'});

      expect(seen.unseenIn(listOf(['a', 'b', 'c'])), 2);
    });

    // Data baru bisa datang saat siswa sedang di Beranda. Itu belum dilihat —
    // badge harus tetap menunjukkannya.
    test('data yang datang saat tab tidak dibuka tidak menandai apa pun', () {
      const seen = TodoSeen(seen: {'assignment:a'});

      final next = seen.observe(listOf(['a', 'b']), viewing: false);

      expect(next.unseenIn(listOf(['a', 'b'])), 1);
    });

    test('membuka tab: badge habis dan item baru diberi label', () {
      const seen = TodoSeen(seen: {'assignment:a'});

      final next = seen.observe(
        listOf(['a', 'b']),
        viewing: true,
        newVisit: true,
      );

      expect(next.unseenIn(listOf(['a', 'b'])), 0);
      expect(next.highlighted, {'assignment:b'});
    });

    // Label "Baru" menjawab "apa yang berubah sejak terakhir aku buka". Pada
    // kunjungan berikutnya, item kemarin sudah bukan jawaban.
    test('kunjungan berikutnya membuang label dari kunjungan sebelumnya', () {
      const seen = TodoSeen(
        seen: {'assignment:a', 'assignment:b'},
        highlighted: {'assignment:b'},
      );

      final next = seen.observe(
        listOf(['a', 'b']),
        viewing: true,
        newVisit: true,
      );

      expect(next.highlighted, isEmpty);
    });

    // Tarik-untuk-segarkan saat masih di tab tidak boleh menghapus label yang
    // baru saja dilihat siswa beberapa detik lalu.
    test('segar ulang di tab yang sama menambah label, tidak menggantinya', () {
      const seen = TodoSeen(
        seen: {'assignment:a', 'assignment:b'},
        highlighted: {'assignment:b'},
      );

      final next = seen.observe(listOf(['a', 'b', 'c']), viewing: true);

      expect(next.highlighted, {'assignment:b', 'assignment:c'});
    });

    // Tanpa ini catatannya membengkak selamanya: setiap tugas yang pernah ada
    // tetap tersimpan walau sudah lama dikerjakan.
    test('item yang sudah tidak ada dibuang dari catatan', () {
      const seen = TodoSeen(
        seen: {'assignment:lama', 'assignment:a'},
        highlighted: {'assignment:lama'},
      );

      final next = seen.observe(listOf(['a']), viewing: true);

      expect(next.seen, {'assignment:a'});
      expect(next.highlighted, isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/cached.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/todo/application/todo_seen_controller.dart';
import 'package:learn_mobile/features/todo/data/todo_repository.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';
import 'package:learn_mobile/features/todo/domain/todo_seen.dart';
import 'package:learn_mobile/features/todo/presentation/todo_screen.dart';

class _FakeRepository implements TodoRepository {
  _FakeRepository(
    this._result, {
    this.refreshFailed = false,
    this.age = Duration.zero,
  });

  final Object _result;
  final bool refreshFailed;
  final Duration age;

  @override
  Stream<Cached<TodoList>> watch() async* {
    final result = _result;

    if (result is! TodoList) throw result;

    yield Cached(
      value: result,
      fetchedAt: DateTime.now().subtract(age),
      isFresh: !refreshFailed,
      refreshFailed: refreshFailed,
    );
  }
}

class _FakeSeen extends TodoSeenController {
  _FakeSeen(this._initial);

  final TodoSeen _initial;

  @override
  Future<TodoSeen> build() async => _initial;
}

final _now = DateTime.now();

final _dueToday = TodoItem(
  id: 'a1',
  kind: TodoKind.assignment,
  state: TodoState.pending,
  title: 'Latihan Soal Bab 2',
  subjectName: 'Matematika',
  deadline: DateTime(_now.year, _now.month, _now.day, 23, 59),
  isToday: true,
  isWithinWeek: true,
);

final _examThisWeek = TodoItem(
  id: 'e1',
  kind: TodoKind.exam,
  state: TodoState.upcoming,
  title: 'UH Bab 3',
  subjectName: 'Biologi',
  startsAt: _now.add(const Duration(days: 3)),
  isWithinWeek: true,
);

final _later = TodoItem(
  id: 'a2',
  kind: TodoKind.assignment,
  state: TodoState.pending,
  title: 'Proyek Akhir Semester',
  subjectName: 'Seni Budaya',
  deadline: _now.add(const Duration(days: 20)),
);

final _list = TodoList(
  today: [_dueToday],
  thisWeek: [_dueToday, _examThisWeek],
  later: [_later],
  countThisWeek: 2,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    TodoRepository repository, {
    TodoSeen seen = const TodoSeen(seen: {}),
  }) async {
    // Layar test bawaan hanya 600px, dan ListView tidak membangun anak yang
    // jauh di luar layar — `find` akan gagal menemukannya tanpa error apa pun.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repository),
          todoSeenControllerProvider.overrideWith(() => _FakeSeen(seen)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const TodoScreen()),
      ),
    );

    // Bukan `pumpAndSettle`: latar AppBackground beranimasi tanpa henti.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('tiga seksi dengan isinya masing-masing', (tester) async {
    await pump(tester, _FakeRepository(_list));

    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Minggu ini'), findsOneWidget);
    expect(find.text('Nanti'), findsOneWidget);
    expect(find.text('UH Bab 3'), findsOneWidget);
    expect(find.text('Proyek Akhir Semester'), findsOneWidget);
    expect(find.text('Tugas · Matematika'), findsOneWidget);
  });

  // Server mengirim tugas hari ini di `today` DAN `this_week`.
  testWidgets('tugas hari ini hanya muncul sekali', (tester) async {
    await pump(tester, _FakeRepository(_list));

    expect(find.text('Latihan Soal Bab 2'), findsOneWidget);
  });

  testWidgets('seksi tanpa isi tidak ditampilkan', (tester) async {
    await pump(
      tester,
      _FakeRepository(TodoList(thisWeek: [_examThisWeek], countThisWeek: 1)),
    );

    expect(find.text('Hari ini'), findsNothing);
    expect(find.text('Minggu ini'), findsOneWidget);
    expect(find.text('Nanti'), findsNothing);
  });

  // docs/05: ujian `upcoming` belum bisa dibuka — siswa perlu tahu itu
  // SEBELUM mengetuk, bukan setelahnya.
  testWidgets('ujian yang belum dibuka ditandai terkunci', (tester) async {
    await pump(tester, _FakeRepository(_list));

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.textContaining('Mulai '), findsOneWidget);
  });

  testWidgets('daftar kosong diberi keterangan, bukan layar kosong', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(const TodoList()));

    expect(find.text('Tidak ada yang menunggu'), findsOneWidget);
  });

  testWidgets('gagal tanpa salinan menampilkan tombol coba lagi', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(const NetworkFailure()));

    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('salinan tersimpan tampil dengan penanda, bukan layar error', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRepository(
        _list,
        refreshFailed: true,
        age: const Duration(hours: 2),
      ),
    );

    expect(find.text('UH Bab 3'), findsOneWidget);
    expect(find.text('Terakhir diperbarui 2 jam lalu'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('hanya item yang baru sejak kunjungan lalu yang diberi label', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRepository(_list),
      seen: TodoSeen(seen: _list.allKeys, highlighted: {_examThisWeek.key}),
    );

    expect(find.text('Baru'), findsOneWidget);
    expect(
      find.descendant(
        of: find
            .ancestor(of: find.text('UH Bab 3'), matching: find.byType(Column))
            .first,
        matching: find.text('Baru'),
      ),
      findsOneWidget,
    );
  });
}

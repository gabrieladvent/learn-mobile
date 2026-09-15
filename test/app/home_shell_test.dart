import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_mobile/app/router.dart';
import 'package:learn_mobile/core/cache/cached.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/auth/application/auth_controller.dart';
import 'package:learn_mobile/features/auth/domain/auth_session.dart';
import 'package:learn_mobile/features/auth/domain/student.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';
import 'package:learn_mobile/features/todo/data/todo_repository.dart';
import 'package:learn_mobile/features/todo/data/todo_seen_store.dart';
import 'package:learn_mobile/features/todo/domain/todo_list.dart';

class _FakeAuth extends AuthController {
  @override
  Future<AuthSession?> build() async => const AuthSession(
    token: 't',
    student: Student(
      id: 'siswa-1',
      fullName: 'Budi Santoso',
      nisn: null,
      className: 'X IPA 1',
    ),
    mustChangePassword: false,
  );
}

class _FakeDashboard implements DashboardRepository {
  @override
  Stream<Cached<Dashboard>> watch() => Stream.value(
    Cached(value: const Dashboard(), fetchedAt: DateTime.now(), isFresh: true),
  );

  @override
  Future<void> setPinned(String courseId, {required bool pinned}) async {}
}

class _FakeTodo implements TodoRepository {
  _FakeTodo(this.list);

  final TodoList list;

  @override
  Stream<Cached<TodoList>> watch() => Stream.value(
    Cached(value: list, fetchedAt: DateTime.now(), isFresh: true),
  );
}

/// Pengganti database: cukup menyimpan di memori, dan bisa diperiksa test.
class _MemoryStore implements TodoSeenStore {
  _MemoryStore([this.keys]);

  Set<String>? keys;

  @override
  Future<Set<String>?> read() async => keys;

  @override
  Future<void> write(Set<String> keys) async => this.keys = keys;
}

final _twoAssignments = TodoList(
  later: [
    for (final (id, title) in [
      ('a1', 'Latihan Bab 1'),
      ('a2', 'Latihan Bab 2'),
    ])
      TodoItem(
        id: id,
        kind: TodoKind.assignment,
        state: TodoState.pending,
        title: title,
      ),
  ],
);

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    required TodoList list,
    required _MemoryStore store,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    // Memakai rute shell yang SAMA dengan aplikasi, bukan salinan — supaya
    // test ini ikut rusak kalau susunan tab di router berubah.
    final router = GoRouter(
      initialLocation: '/home',
      routes: [homeShellRoute()],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuth.new),
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboard()),
          todoRepositoryProvider.overrideWithValue(_FakeTodo(list)),
          todoSeenStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    await settle(tester);
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Finder badgeLabel(String text) =>
      find.descendant(of: find.byType(Badge), matching: find.text(text));

  // Siswa yang baru login tidak melewatkan apa pun — badge "2" di hari
  // pertama hanya mengajarinya bahwa badge ini tidak berarti apa-apa.
  testWidgets('pertama kali: tanpa badge, daftar yang ada dijadikan patokan', (
    tester,
  ) async {
    final store = _MemoryStore();
    await pump(tester, list: _twoAssignments, store: store);

    expect(badgeLabel('2'), findsNothing);
    expect(store.keys, {'assignment:a1', 'assignment:a2'});
  });

  testWidgets('item yang belum pernah dilihat muncul di badge', (tester) async {
    await pump(
      tester,
      list: _twoAssignments,
      store: _MemoryStore({'assignment:a1'}),
    );

    expect(badgeLabel('1'), findsOneWidget);
  });

  testWidgets('membuka tab menghabiskan badge dan menandai yang baru', (
    tester,
  ) async {
    final store = _MemoryStore({'assignment:a1'});
    await pump(tester, list: _twoAssignments, store: store);

    await tester.tap(tab('To-do'));
    await settle(tester);

    expect(badgeLabel('1'), findsNothing);
    expect(find.text('Baru'), findsOneWidget);
    expect(store.keys, {'assignment:a1', 'assignment:a2'});

    // Kembali ke beranda: yang sudah dilihat tidak dihitung lagi.
    await tester.tap(tab('Beranda'));
    await settle(tester);

    expect(badgeLabel('1'), findsNothing);
  });

  testWidgets('mengetuk tab To-do membuka daftarnya', (tester) async {
    await pump(tester, list: const TodoList(), store: _MemoryStore({}));

    await tester.tap(tab('To-do'));
    await settle(tester);

    expect(find.text('Tidak ada yang menunggu'), findsOneWidget);
  });
}

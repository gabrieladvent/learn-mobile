import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/auth/application/auth_controller.dart';
import 'package:learn_mobile/features/auth/domain/auth_session.dart';
import 'package:learn_mobile/features/auth/domain/student.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';
import 'package:learn_mobile/features/dashboard/presentation/home_screen.dart';

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

/// Repository tiruan: menentukan apa yang dilihat layar tanpa jaringan.
class _FakeRepository implements DashboardRepository {
  _FakeRepository(this._result);

  final Object _result;

  @override
  Future<Dashboard> load() async {
    if (_result is Dashboard) return _result;

    throw _result;
  }
}

/// Tidak pernah selesai — dipakai untuk menahan layar di keadaan memuat.
class _PendingRepository implements DashboardRepository {
  @override
  Future<Dashboard> load() => Completer<Dashboard>().future;
}

const _dashboard = Dashboard(
  courses: [
    CourseSummary(
      id: 'c1',
      subjectName: 'Matematika',
      subjectCode: 'MTK',
      teacherName: 'Ibu Sari',
      isPinned: true,
    ),
    CourseSummary(id: 'c2', subjectName: 'Biologi', subjectCode: 'BIO'),
  ],
  stats: DashboardStats(
    assignmentsPending: 3,
    assignmentsCompleted: 12,
    examsCompleted: 2,
    avgScore: 84.5,
  ),
  meta: DashboardMeta(classroomName: 'X IPA 1', academicYear: '2025/2026'),
);

void main() {
  Future<void> pump(WidgetTester tester, DashboardRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuth.new),
          dashboardRepositoryProvider.overrideWithValue(repository),
        ],
        // Tema aplikasi wajib: `context.accents` membaca ThemeExtension
        // milik AppTheme, dan MaterialApp polos tidak punya itu.
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );

    // `pumpAndSettle` TIDAK bisa dipakai di layar mana pun yang memakai
    // [AppBackground]: orb latarnya beranimasi berulang tanpa henti, jadi
    // tidak akan pernah ada frame yang "tenang". Dua `pump` cukup — satu untuk
    // frame pertama, satu lagi setelah provider selesai.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('menampilkan statistik dan daftar mata pelajaran', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(_dashboard));

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Biologi'), findsOneWidget);
    expect(find.text('Ibu Sari'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // tugas belum selesai
    expect(find.text('84,5'), findsOneWidget); // rata-rata, koma bukan titik
  });

  testWidgets('menandai mata pelajaran yang disematkan', (tester) async {
    await pump(tester, _FakeRepository(_dashboard));

    // Hanya satu dari dua course yang di-pin.
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
  });

  testWidgets('kelas dan tahun ajaran muncul dari meta', (tester) async {
    await pump(tester, _FakeRepository(_dashboard));

    expect(find.text('X IPA 1 · 2025/2026'), findsOneWidget);
  });

  testWidgets('menunggu data tanpa membuat layar kosong', (tester) async {
    await pump(tester, _PendingRepository());

    expect(find.bySemanticsLabel('Memuat'), findsWidgets);
    // Nama siswa datang dari sesi, bukan dari beranda — jadi ia sudah terlihat
    // sebelum permintaan selesai.
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  // Siswa di WiFi sekolah akan sering melihat layar ini. Ia harus menjelaskan
  // apa yang terjadi DAN memberi jalan keluar.
  testWidgets('kegagalan jaringan menampilkan pesan dan tombol coba lagi', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(const NetworkFailure()));

    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('pesan kegagalan diambil dari server, bukan dikarang', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(const ServerFailure('Server sibuk.')));

    expect(find.text('Server sibuk.'), findsOneWidget);
  });

  testWidgets('siswa tanpa mata pelajaran diberi tahu ke mana bertanya', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(const Dashboard()));

    expect(find.text('Belum ada mata pelajaran'), findsOneWidget);
    expect(
      find.text('Hubungi wali kelasmu kalau ini terasa keliru.'),
      findsOneWidget,
    );
  });

  testWidgets('rata-rata kosong ditampilkan sebagai —, bukan 0', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRepository(const Dashboard(stats: DashboardStats())),
    );

    expect(find.text('—'), findsOneWidget);
  });
}

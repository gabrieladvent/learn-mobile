import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/cached.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/theme/app_theme.dart';
import 'package:learn_mobile/features/auth/application/auth_controller.dart';
import 'package:learn_mobile/features/auth/domain/auth_session.dart';
import 'package:learn_mobile/features/auth/domain/student.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';
import 'package:learn_mobile/features/dashboard/presentation/home_screen.dart';

class _FakeAuth extends AuthController {
  bool loggedOut = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

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
  _FakeRepository(
    this._result, {
    this.isFresh = true,
    this.refreshFailed = false,
    this.age = Duration.zero,
    this.pinResult,
  });

  final Object _result;
  final bool isFresh;
  final bool refreshFailed;
  final Duration age;

  /// Null = permintaan pin tidak pernah selesai (menahan keadaan optimistis).
  final Object? pinResult;

  @override
  Stream<Cached<Dashboard>> watch() async* {
    final result = _result;

    if (result is! Dashboard) throw result;

    yield Cached(
      value: result,
      fetchedAt: DateTime.now().subtract(age),
      isFresh: isFresh,
      refreshFailed: refreshFailed,
    );
  }

  @override
  Future<void> setPinned(String courseId, {required bool pinned}) {
    final result = pinResult;

    if (result == null) return Completer<void>().future;

    return Future<void>.error(result);
  }
}

/// Tidak pernah selesai — dipakai untuk menahan layar di keadaan memuat.
class _PendingRepository implements DashboardRepository {
  @override
  Stream<Cached<Dashboard>> watch() =>
      Stream.fromFuture(Completer<Cached<Dashboard>>().future);

  @override
  Future<void> setPinned(String courseId, {required bool pinned}) async {}
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

  // Inti stale-while-revalidate: siswa bersinyal buruk melihat DATANYA, bukan
  // layar error — hanya dengan keterangan kapan terakhir diperbarui.
  testWidgets('salinan tersimpan tampil dengan penanda, bukan layar error', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRepository(
        _dashboard,
        isFresh: false,
        refreshFailed: true,
        age: const Duration(hours: 2),
      ),
    );

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Terakhir diperbarui 2 jam lalu'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('data segar tidak memunculkan penanda apa pun', (tester) async {
    await pump(tester, _FakeRepository(_dashboard));

    expect(find.textContaining('Terakhir diperbarui'), findsNothing);
  });

  // Salinan yang tampil sesaat sebelum jaringan menjawab hidup kurang dari
  // sedetik. Memberinya penanda membuat seluruh isi beranda melompat begitu
  // data segar datang — untuk keterangan yang tidak sempat dibaca siapa pun.
  testWidgets('salinan sementara sebelum jaringan menjawab tidak diberi '
      'penanda', (tester) async {
    await pump(
      tester,
      _FakeRepository(
        _dashboard,
        isFresh: false,
        age: const Duration(hours: 2),
      ),
    );

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.textContaining('Terakhir diperbarui'), findsNothing);
  });

  // Inti optimistis: ikon berubah SEBELUM server menjawab. Repository tiruan
  // di sini sengaja tidak pernah menyelesaikan permintaannya.
  testWidgets('mengetuk pin mengubah ikon seketika, tanpa menunggu server', (
    tester,
  ) async {
    await pump(tester, _FakeRepository(_dashboard));
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);

    // Layar test bawaan hanya 600px; kartu kedua ada di luar layar, dan tap
    // ke luar layar diam-diam meleset tanpa error.
    await tester.ensureVisible(find.byTooltip('Sematkan'));
    await tester.pump();
    await tester.tap(find.byTooltip('Sematkan'));
    await tester.pump();

    expect(find.byIcon(Icons.push_pin_rounded), findsNWidgets(2));
  });

  // Gagal tidak boleh meninggalkan keadaan setengah jadi: ikon kembali ke
  // nilai server, dan siswa diberi tahu kenapa.
  testWidgets('pin yang ditolak mengembalikan ikon dan memberi tahu', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRepository(_dashboard, pinResult: const NetworkFailure()),
    );

    // Layar test bawaan hanya 600px; kartu kedua ada di luar layar, dan tap
    // ke luar layar diam-diam meleset tanpa error.
    await tester.ensureVisible(find.byTooltip('Sematkan'));
    await tester.pump();
    await tester.tap(find.byTooltip('Sematkan'));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    expect(
      find.text('Belum tersimpan — periksa koneksimu, lalu coba lagi.'),
      findsOneWidget,
    );

    // Membiarkan pesan sekilas menutup sendiri, supaya tidak ada timer yang
    // masih berjalan saat test selesai.
    await tester.pump(const Duration(seconds: 4));
  });

  // Salah tekan tidak boleh langsung mengeluarkan siswa.
  testWidgets('keluar meminta konfirmasi dulu', (tester) async {
    await pump(tester, _FakeRepository(_dashboard));
    final auth = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(authControllerProvider.notifier) as _FakeAuth;

    Future<void> settleRoute() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.tap(find.byTooltip('Keluar'));
    await settleRoute();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await settleRoute();
    expect(auth.loggedOut, isFalse);

    await tester.tap(find.byTooltip('Keluar'));
    await settleRoute();
    await tester.tap(find.text('Keluar'));
    await settleRoute();
    expect(auth.loggedOut, isTrue);
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

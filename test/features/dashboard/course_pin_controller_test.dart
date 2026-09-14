import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/cached.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/features/dashboard/application/course_pin_controller.dart';
import 'package:learn_mobile/features/dashboard/application/dashboard_controller.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';

class _FakeRepository implements DashboardRepository {
  _FakeRepository({required this.serverPinned});

  bool serverPinned;

  final sent = <bool>[];
  final _pending = <Completer<void>>[];
  int watchCalls = 0;

  @override
  Stream<Cached<Dashboard>> watch() async* {
    watchCalls++;
    yield Cached(
      value: Dashboard(
        courses: [CourseSummary(id: 'c1', isPinned: serverPinned)],
      ),
      fetchedAt: DateTime.now(),
      isFresh: true,
    );
  }

  @override
  Future<void> setPinned(String courseId, {required bool pinned}) {
    sent.add(pinned);
    final completer = Completer<void>();
    _pending.add(completer);

    return completer.future.then((_) => serverPinned = pinned);
  }

  void answerNext() => _pending.removeAt(0).complete();

  void failNext(Object error) => _pending.removeAt(0).completeError(error);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRepository(serverPinned: false);
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );

    container.listen(dashboardProvider, (_, _) {});
    container.listen(coursePinControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  CoursePinController controller() =>
      container.read(coursePinControllerProvider.notifier);

  Map<String, bool> overrides() => container.read(coursePinControllerProvider);

  // Course yang sudah bukan milik siswa dibalas 404. Beranda harus dimuat ulang
  // supaya kartunya hilang — bukan bisa diketuk terus dan terus ditolak.
  test('404: beranda dimuat ulang dan lapisan dibuang', () async {
    await container.read(dashboardProvider.future);
    final before = repository.watchCalls;

    final call = controller().toggle('c1', pinned: true);
    await settle();
    repository.failNext(const NotFoundFailure());

    await expectLater(call, throwsA(isA<NotFoundFailure>()));
    await container.read(dashboardProvider.future);
    await settle();

    expect(overrides(), isEmpty);
    expect(repository.watchCalls, greaterThan(before));
  });

  test('keadaan optimistis terpasang sebelum server menjawab', () async {
    unawaited(controller().toggle('c1', pinned: true));

    expect(overrides(), {'c1': true});
    expect(repository.sent, [true]);
  });

  test('begitu server mencerminkannya, lapisan optimistis dibuang', () async {
    unawaited(controller().toggle('c1', pinned: true));
    await settle();

    repository.answerNext();
    await settle();
    // Penyegaran beranda setelah sukses membawa `is_pinned: true` dari server.
    await container.read(dashboardProvider.future);
    await settle();

    expect(overrides(), isEmpty);
  });

  // Gagal tidak boleh meninggalkan ikon di keadaan yang tidak pernah diterima
  // server — dan pemanggil harus tahu supaya bisa menampilkan pesannya.
  test('gagal: lapisan dibuang dan kegagalannya dilempar', () async {
    final call = controller().toggle('c1', pinned: true);
    await settle();

    repository.failNext(const NetworkFailure());

    await expectLater(call, throwsA(isA<NetworkFailure>()));
    expect(overrides(), isEmpty);
  });

  // Tiga permintaan paralel bisa diproses server dalam urutan berbeda dari
  // urutan ketukan. Yang dijaga di sini: per course hanya satu yang berjalan,
  // dan berikutnya selalu membawa niat TERAKHIR.
  test(
    'pin lalu lepas saat masih berjalan: yang terakhir yang dikirim',
    () async {
      unawaited(controller().toggle('c1', pinned: true));
      await settle();
      unawaited(controller().toggle('c1', pinned: false));
      await settle();

      // Belum ada permintaan kedua selama yang pertama belum dijawab.
      expect(repository.sent, [true]);

      repository.answerNext();
      await settle();

      expect(repository.sent, [true, false]);

      repository.answerNext();
      await settle();

      expect(repository.serverPinned, isFalse);
    },
  );

  test(
    'ketukan yang kembali ke niat yang sudah terkirim tidak dikirim ulang',
    () async {
      unawaited(controller().toggle('c1', pinned: true));
      await settle();
      unawaited(controller().toggle('c1', pinned: false));
      unawaited(controller().toggle('c1', pinned: true));
      await settle();

      repository.answerNext();
      await settle();

      // Niat akhirnya `true` — sama dengan yang sudah terkirim. Tidak perlu
      // permintaan kedua.
      expect(repository.sent, [true]);
      expect(overrides(), {'c1': true});
    },
  );

  // Salinan cache yang tampil sebelum jaringan menjawab bisa kebetulan sama
  // dengan niat siswa tanpa server pernah tahu. Hanya data segar yang boleh
  // membuang lapisan.
  test('data dari cache tidak membuang lapisan optimistis', () async {
    final stale = ProviderContainer(
      overrides: [
        dashboardProvider.overrideWith(
          (ref) => Stream.value(
            Cached(
              value: const Dashboard(
                courses: [CourseSummary(id: 'c1', isPinned: true)],
              ),
              fetchedAt: DateTime.now(),
              isFresh: false,
            ),
          ),
        ),
        dashboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(stale.dispose);
    stale.listen(dashboardProvider, (_, _) {});
    stale.listen(coursePinControllerProvider, (_, _) {});

    unawaited(
      stale
          .read(coursePinControllerProvider.notifier)
          .toggle('c1', pinned: true),
    );
    await settle();
    await stale.read(dashboardProvider.future);
    await settle();

    expect(stale.read(coursePinControllerProvider), {'c1': true});
  });
}

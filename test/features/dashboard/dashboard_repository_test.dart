import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_api.dart';
import 'package:learn_mobile/features/dashboard/data/dashboard_repository.dart';

/// API tiruan: bisa menjawab, bisa gagal, dan mencatat berapa kali dipanggil.
class _FakeApi implements DashboardApi {
  _FakeApi({this.payload, this.failure});

  final Map<String, dynamic>? payload;
  final Object? failure;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetch() async {
    calls++;

    final error = failure;
    if (error != null) throw error;

    return payload!;
  }

  @override
  Future<void> setPinned(String courseId, {required bool pinned}) async {}
}

Map<String, dynamic> payloadWith(String subject) => {
  'courses': [
    {'id': 'c1', 'subject_name': subject, 'is_pinned': false},
  ],
};

void main() {
  late AppDatabase db;
  late CacheStore cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheStore(db);
  });

  tearDown(() => db.close());

  group('DashboardRepository.watch', () {
    test('tanpa cache: satu emisi, langsung dari jaringan', () async {
      final api = _FakeApi(payload: payloadWith('Matematika'));

      final emissions = await DashboardRepository(api, cache).watch().toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.value.courses.single.subjectName, 'Matematika');
      expect(emissions.single.isFresh, isTrue);
    });

    test('jaringan yang berhasil ikut menyimpan ke cache', () async {
      final api = _FakeApi(payload: payloadWith('Matematika'));

      await DashboardRepository(api, cache).watch().drain<void>();

      expect(await cache.read(CacheKeys.dashboard), isNotNull);
    });

    // Inti stale-while-revalidate: yang tersimpan keluar DULU, tanpa menunggu
    // jaringan. Siswa yang membuka aplikasi di gerbang sekolah langsung
    // melihat isinya.
    test('dengan cache: salinan lama dulu, lalu yang segar', () async {
      await cache.write(CacheKeys.dashboard, payloadWith('Lama'));
      final api = _FakeApi(payload: payloadWith('Baru'));

      final emissions = await DashboardRepository(api, cache).watch().toList();

      expect(emissions.map((e) => e.value.courses.single.subjectName), [
        'Lama',
        'Baru',
      ]);
      expect(emissions.first.isFresh, isFalse);
      expect(emissions.last.isFresh, isTrue);
    });

    // Yang TIDAK boleh terjadi menurut docs/06: layar error padahal datanya
    // ada. Siswa bersinyal buruk akan melihatnya terus-menerus.
    test('jaringan gagal tapi cache ada: tidak melempar', () async {
      await cache.write(CacheKeys.dashboard, payloadWith('Lama'));
      final api = _FakeApi(failure: const NetworkFailure());

      final emissions = await DashboardRepository(api, cache).watch().toList();

      expect(emissions, hasLength(2));
      expect(emissions.last.value.courses.single.subjectName, 'Lama');
      expect(emissions.last.refreshFailed, isTrue);
      expect(emissions.last.isFresh, isFalse);
    });

    test('emisi setelah gagal tetap membawa waktu ambil yang lama', () async {
      await cache.write(CacheKeys.dashboard, payloadWith('Lama'));
      final api = _FakeApi(failure: const NetworkFailure());

      final emissions = await DashboardRepository(api, cache).watch().toList();

      // Bukan `DateTime.now()` — kalau tertimpa, penanda "terakhir diperbarui"
      // akan berbohong bahwa datanya baru saja disegarkan.
      expect(emissions.last.fetchedAt, emissions.first.fetchedAt);
    });

    // Di sini layar error justru jawaban yang benar: tidak ada apa pun untuk
    // ditampilkan, dan menyembunyikan kegagalan hanya menyisakan layar kosong.
    test('jaringan gagal dan cache kosong: melempar apa adanya', () async {
      final api = _FakeApi(failure: const NetworkFailure());

      await expectLater(
        DashboardRepository(api, cache).watch().toList(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('cache rusak diperlakukan seperti belum ada', () async {
      // Payload yang tidak bisa dibaca — misalnya sisa versi aplikasi lama.
      await db
          .into(db.cachedDocuments)
          .insert(
            CachedDocument(
              key: CacheKeys.dashboard,
              payload: 'bukan json',
              fetchedAt: DateTime.now(),
            ),
          );
      final api = _FakeApi(payload: payloadWith('Baru'));

      final emissions = await DashboardRepository(api, cache).watch().toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.isFresh, isTrue);
    });

    test('jaringan tetap dipanggil sekali walau cache ada', () async {
      await cache.write(CacheKeys.dashboard, payloadWith('Lama'));
      final api = _FakeApi(payload: payloadWith('Baru'));

      await DashboardRepository(api, cache).watch().drain<void>();

      expect(api.calls, 1);
    });
  });
}

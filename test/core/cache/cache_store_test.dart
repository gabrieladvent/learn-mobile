import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';

void main() {
  late AppDatabase db;
  late CacheStore store;

  setUp(() {
    // Database di memori: cepat, dan tiap test mulai dari keadaan bersih.
    db = AppDatabase(NativeDatabase.memory());
    store = CacheStore(db);
  });

  tearDown(() => db.close());

  group('CacheStore', () {
    test('kunci yang belum pernah diisi mengembalikan null', () async {
      expect(await store.read(CacheKeys.dashboard), isNull);
    });

    test('menyimpan lalu membaca kembali payload yang sama', () async {
      await store.write(CacheKeys.dashboard, {
        'courses': [
          {'id': 'c1', 'subject_name': 'Matematika'},
        ],
      });

      final entry = await store.read(CacheKeys.dashboard);

      expect((entry!.payload['courses'] as List).single, {
        'id': 'c1',
        'subject_name': 'Matematika',
      });
    });

    test('mencatat kapan payload diambil', () async {
      await store.write(CacheKeys.dashboard, const {'courses': []});

      final entry = await store.read(CacheKeys.dashboard);

      expect(entry!.age.inSeconds, lessThan(5));
    });

    // Ini yang mencegah jebakan di docs/06: entri yang sudah dicabut guru tidak
    // boleh bertahan di layar siswa hanya karena respons baru tidak lagi
    // menyebutnya.
    test('menulis ulang MENIMPA, bukan menggabung', () async {
      await store.write(CacheKeys.dashboard, {
        'courses': [
          {'id': 'lama'},
        ],
        'meta': {'inspire': 'kutipan lama'},
      });
      await store.write(CacheKeys.dashboard, {
        'courses': [
          {'id': 'baru'},
        ],
      });

      final entry = await store.read(CacheKeys.dashboard);

      expect((entry!.payload['courses'] as List).single, {'id': 'baru'});
      expect(entry.payload.containsKey('meta'), isFalse);
    });

    test('kunci berbeda tidak saling menimpa', () async {
      await store.write(CacheKeys.dashboard, const {'a': 1});
      await store.write(CacheKeys.course('c1'), const {'b': 2});

      expect((await store.read(CacheKeys.dashboard))!.payload, {'a': 1});
      expect((await store.read(CacheKeys.course('c1')))!.payload, {'b': 2});
    });

    test('remove menghapus satu kunci saja', () async {
      await store.write(CacheKeys.dashboard, const {'a': 1});
      await store.write(CacheKeys.course('c1'), const {'b': 2});

      await store.remove(CacheKeys.dashboard);

      expect(await store.read(CacheKeys.dashboard), isNull);
      expect(await store.read(CacheKeys.course('c1')), isNotNull);
    });

    // Dipanggil saat logout: cache siswa sebelumnya tidak boleh terlihat oleh
    // siswa berikutnya yang memakai HP yang sama.
    test('clear mengosongkan semuanya', () async {
      await store.write(CacheKeys.dashboard, const {'a': 1});
      await store.write(CacheKeys.course('c1'), const {'b': 2});

      await store.clear();

      expect(await store.read(CacheKeys.dashboard), isNull);
      expect(await store.read(CacheKeys.course('c1')), isNull);
    });

    // Cache adalah kenyamanan, bukan kebenaran. Database yang sudah ditutup
    // meniru keadaan rusak/tidak bisa diakses — dan itu tidak boleh membuat
    // siswa gagal membuka aplikasinya.
    test('database bermasalah diperlakukan sebagai cache kosong', () async {
      await db.close();

      expect(await store.read(CacheKeys.dashboard), isNull);
      await expectLater(store.write(CacheKeys.dashboard, const {}), completes);
      await expectLater(store.remove(CacheKeys.dashboard), completes);
      await expectLater(store.clear(), completes);
    });
  });
}

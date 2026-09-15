import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';
import 'package:learn_mobile/features/todo/data/todo_seen_store.dart';

void main() {
  late AppDatabase db;
  late CacheStore cache;
  late TodoSeenStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheStore(db);
    store = TodoSeenStore(cache);
  });

  tearDown(() => db.close());

  // "Belum pernah dicatat" dan "tercatat kosong" artinya berbeda: yang pertama
  // memicu patokan awal, yang kedua berarti semua item nanti adalah baru.
  test(
    'belum pernah dicatat dibaca sebagai null, bukan himpunan kosong',
    () async {
      expect(await store.read(), isNull);

      await store.write({});

      expect(await store.read(), isEmpty);
    },
  );

  test('yang ditulis terbaca kembali', () async {
    await store.write({'assignment:a', 'exam:b'});

    expect(await store.read(), {'assignment:a', 'exam:b'});
  });

  // Satu HP bisa dipakai bergantian. Siswa berikutnya tidak boleh mewarisi
  // status "sudah dilihat" milik siswa sebelumnya.
  test('ikut terhapus saat cache dibersihkan waktu logout', () async {
    await store.write({'assignment:a'});

    await cache.clear();

    expect(await store.read(), isNull);
  });

  test('tidak bercampur dengan salinan daftar to-do', () async {
    await cache.write(CacheKeys.todo, {'count_this_week': 1});
    await store.write({'assignment:a'});

    expect((await cache.read(CacheKeys.todo))!.payload, {'count_this_week': 1});
  });
}

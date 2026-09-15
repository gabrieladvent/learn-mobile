import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';
import 'package:learn_mobile/core/cache/stale_while_revalidate.dart';

class _Note {
  const _Note(this.text);

  factory _Note.fromJson(Map<String, dynamic> json) =>
      _Note(json['text'] as String);

  final String text;
}

void main() {
  late AppDatabase db;
  late CacheStore cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheStore(db);
  });

  tearDown(() => db.close());

  Stream<String> watch(Future<Map<String, dynamic>> Function() fetch) =>
      staleWhileRevalidate(
        cache: cache,
        key: 'note',
        fetch: fetch,
        decode: _Note.fromJson,
      ).map((cached) => cached.value.text);

  // Alur utamanya (salinan dulu, lalu segar; gagal tanpa cache melempar) sudah
  // diuji lewat DashboardRepository. Di sini hanya dua hal yang tidak terlihat
  // dari sana.

  // Contoh nyata: aplikasi diperbarui dan bentuk modelnya berubah. JSON
  // tersimpan masih sah, tapi model baru tidak bisa membacanya. Tanpa
  // penjagaan ini, layar langsung error — padahal jaringan siap menjawab.
  test(
    'salinan yang tidak bisa dibaca model diabaikan, bukan melempar',
    () async {
      await cache.write('note', {'text': 42});

      final emissions = await watch(() async => {'text': 'baru'}).toList();

      expect(emissions, ['baru']);
    },
  );

  test('payload rusak dari server tidak menimpa salinan yang baik', () async {
    await cache.write('note', {'text': 'lama'});

    final emissions = await watch(() async => {'text': 42}).toList();

    expect(emissions, ['lama', 'lama']);
    expect((await cache.read('note'))!.payload['text'], 'lama');
  });
}

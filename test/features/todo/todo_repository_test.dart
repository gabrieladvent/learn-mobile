import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';
import 'package:learn_mobile/core/network/api_client.dart';
import 'package:learn_mobile/core/network/error_interceptor.dart';
import 'package:learn_mobile/features/todo/data/todo_api.dart';
import 'package:learn_mobile/features/todo/data/todo_repository.dart';

class _FakeApi implements TodoApi {
  _FakeApi(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> fetch() async => payload;
}

class _StubAdapter implements HttpClientAdapter {
  String? lastPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;

    return ResponseBody.fromString(
      jsonEncode({
        'response_code': 'success',
        'response_message': 'Berhasil',
        'response_data': {'count_this_week': 3},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('TodoApi memanggil /todo dan membuka envelope', () async {
    final adapter = _StubAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://lms.test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ErrorInterceptor());

    final payload = await TodoApi(ApiClient(dio)).fetch();

    expect(adapter.lastPath, '/todo');
    expect(payload, {'count_this_week': 3});
  });

  group('TodoRepository.watch', () {
    late AppDatabase db;
    late CacheStore cache;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = CacheStore(db);
    });

    tearDown(() => db.close());

    // Dua layar, satu tabel cache. Salah kunci berarti membuka to-do diam-diam
    // menimpa salinan beranda — dan beranda offline berubah jadi layar error.
    test('menyimpan di kuncinya sendiri, tidak menimpa beranda', () async {
      await cache.write(CacheKeys.dashboard, {'courses': <dynamic>[]});

      await TodoRepository(
        _FakeApi({'count_this_week': 2}),
        cache,
      ).watch().drain<void>();

      expect((await cache.read(CacheKeys.todo))!.payload, {
        'count_this_week': 2,
      });
      expect((await cache.read(CacheKeys.dashboard))!.payload, {
        'courses': <dynamic>[],
      });
    });

    test('salinan to-do tampil dulu, lalu yang segar', () async {
      await cache.write(CacheKeys.todo, {'count_this_week': 1});

      final emissions = await TodoRepository(
        _FakeApi({'count_this_week': 2}),
        cache,
      ).watch().toList();

      expect(emissions.map((e) => e.value.countThisWeek), [1, 2]);
    });
  });
}

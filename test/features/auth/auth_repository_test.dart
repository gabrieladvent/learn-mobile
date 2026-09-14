import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/cache/app_database.dart';
import 'package:learn_mobile/core/cache/cache_store.dart';
import 'package:learn_mobile/core/error/app_failure.dart';
import 'package:learn_mobile/core/storage/token_storage.dart';
import 'package:learn_mobile/features/auth/data/auth_api.dart';
import 'package:learn_mobile/features/auth/data/auth_repository.dart';

class _FakeApi implements AuthApi {
  _FakeApi({this.logoutFailure});

  final Object? logoutFailure;

  @override
  Future<void> logout() async {
    final error = logoutFailure;
    if (error != null) throw error;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String nisn,
    required String password,
    required String deviceName,
  }) async => const {};

  @override
  Future<Map<String, dynamic>> me() async => const {};

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class _FakeTokens implements TokenStorage {
  String? token = 'token-lama';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  late AppDatabase db;
  late CacheStore cache;
  late _FakeTokens tokens;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheStore(db);
    tokens = _FakeTokens();

    await cache.write(CacheKeys.dashboard, const {'courses': []});
  });

  tearDown(() => db.close());

  group('AuthRepository.logout', () {
    // Satu HP di rumah bisa dipakai bergantian kakak-adik yang sama-sama siswa.
    // Beranda milik siswa sebelumnya tidak boleh sempat terlihat sedetik pun
    // oleh yang login berikutnya.
    test('menghapus token DAN mengosongkan cache', () async {
      await AuthRepository(_FakeApi(), tokens, cache).logout();

      expect(tokens.token, isNull);
      expect(await cache.read(CacheKeys.dashboard), isNull);
    });

    // Siswa yang menekan "keluar" di tempat tanpa sinyal harus tetap keluar.
    // Kalau jejak lokalnya tertinggal karena servernya tidak terjangkau, data
    // siswa sebelumnya justru bertahan persis di keadaan yang paling rawan.
    test('tetap membersihkan walau server tidak terjangkau', () async {
      await AuthRepository(
        _FakeApi(logoutFailure: const NetworkFailure()),
        tokens,
        cache,
      ).logout();

      expect(tokens.token, isNull);
      expect(await cache.read(CacheKeys.dashboard), isNull);
    });
  });
}

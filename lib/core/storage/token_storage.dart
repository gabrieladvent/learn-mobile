import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// Penyimpanan token Sanctum.
///
/// HANYA di secure storage (Android Keystore / iOS Keychain) — tidak pernah di
/// SharedPreferences dan tidak pernah di database aplikasi. Token adalah
/// kredensial: kalau bocor, orang lain bisa bertindak sebagai siswa itu.
class TokenStorage {
  const TokenStorage(this._storage);

  static const _key = 'student_api_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}

/// `@riverpod` + `part` di atas = provider-nya dibuatkan oleh code generation.
/// Jalankan: `dart run build_runner build --delete-conflicting-outputs`
///
/// `keepAlive: true` artinya objek ini dibuat sekali dan tidak dibuang saat
/// tidak dipakai. Default Riverpod adalah membuang provider yang tak ada
/// pendengarnya — bagus untuk data layar, buruk untuk objek infrastruktur.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return const TokenStorage(
    FlutterSecureStorage(
      // Sejak flutter_secure_storage 11, penyimpanan Android sudah terenkripsi
      // secara default — tidak perlu (dan tidak bisa) diminta lewat parameter.
      //
      // `first_unlock` di iOS: token baru bisa dibaca setelah perangkat sekali
      // dibuka sejak dinyalakan. Bukan `always`, supaya isinya tidak terbaca
      // saat HP dalam keadaan terkunci.
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
}

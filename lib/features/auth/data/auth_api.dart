import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';

part 'auth_api.g.dart';

/// Lapisan `data` paling bawah: hanya bicara HTTP.
///
/// Tugasnya cuma memanggil endpoint dan mengembalikan isi `response_data`.
/// Tidak menyimpan apa pun, tidak memutuskan apa pun. Pemisahan ini membuat
/// [AuthRepository] bisa dites dengan API tiruan.
class AuthApi {
  const AuthApi(this._client);

  /// [ApiClient], bukan Dio — supaya kegagalan sampai ke sini sudah berupa
  /// [AppFailure], bukan DioException yang membungkusnya.
  final ApiClient _client;

  /// `POST /auth/login`
  ///
  /// Kegagalan kredensial datang sebagai `ValidationFailure` dari
  /// [ErrorInterceptor], bukan sebagai nilai balik — jadi di sini tidak perlu
  /// ada pengecekan sukses/gagal.
  Future<Map<String, dynamic>> login({
    required String nisn,
    required String password,
    required String deviceName,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'nisn': nisn, 'password': password, 'device_name': deviceName},
    );

    return ApiEnvelope.fromJson(res.data!).data!;
  }

  /// `GET /auth/me` — dipakai saat aplikasi dibuka untuk memastikan token
  /// masih berlaku sebelum menampilkan data.
  Future<Map<String, dynamic>> me() async {
    final res = await _client.get<Map<String, dynamic>>('/auth/me');

    return ApiEnvelope.fromJson(res.data!).data!;
  }

  /// `POST /auth/logout` — mencabut token perangkat ini saja.
  Future<void> logout() => _client.post<void>('/auth/logout');

  /// `PATCH /profile/password`
  ///
  /// Endpoint ini SATU-SATUNYA yang tetap boleh diakses siswa yang masih
  /// memakai password default — semua endpoint konten menolaknya sampai
  /// password diganti.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch<Map<String, dynamic>>(
      '/profile/password',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        // Server memakai aturan `confirmed`, jadi field ini wajib ada dan
        // sama persis. Kesalahan ketik sudah dicegat di layar sebelum sampai
        // ke sini, tapi servernya tetap memeriksa ulang.
        'password_confirmation': newPassword,
      },
    );
  }
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(apiClientProvider));

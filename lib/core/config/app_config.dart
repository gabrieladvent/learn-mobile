/// Konfigurasi yang berbeda per environment (dev / staging / prod).
///
/// Nilainya masuk lewat `--dart-define` saat build, BUKAN dari file yang
/// ikut ter-commit. Jadi tidak ada URL server atau kunci rahasia yang
/// tersimpan di repo.
///
/// Menjalankan:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.flavor});

  final String apiBaseUrl;
  final String flavor;

  /// `10.0.2.2` adalah alamat khusus emulator Android untuk menunjuk
  /// `localhost` komputer kita. Kalau pakai perangkat fisik, ganti dengan
  /// IP laptop di jaringan yang sama.
  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    ),
    flavor: String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
  );

  bool get isProduction => flavor == 'prod';
}

class AppReleaseInfo {
  const AppReleaseInfo({this.minVersion, this.latestVersion, this.storeUrl});

  final String? minVersion;

  final String? latestVersion;

  final String? storeUrl;

  static AppReleaseInfo fromJson(Map<String, dynamic>? data) {
    String? stringOf(String key) {
      final value = data?[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return AppReleaseInfo(
      minVersion: stringOf('min_version'),
      latestVersion: stringOf('latest_version'),
      storeUrl: stringOf('store_url'),
    );
  }
}

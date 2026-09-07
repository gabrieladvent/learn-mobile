class ForceUpdateInfo {
  const ForceUpdateInfo({
    required this.message,
    this.minVersion,
    this.storeUrl,
  });

  final String message;

  final String? minVersion;

  final String? storeUrl;

  static ForceUpdateInfo fromResponse(
    String message,
    Map<String, dynamic>? data,
  ) {
    String? stringOf(String key) {
      final value = data?[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return ForceUpdateInfo(
      message: message,
      minVersion: stringOf('min_version'),
      storeUrl: stringOf('store_url'),
    );
  }
}

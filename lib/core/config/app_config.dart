class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.flavor,
    this.sentryDsn = '',
  });

  final String apiBaseUrl;
  final String flavor;
  final String sentryDsn;

  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    ),
    flavor: String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );

  bool get isProduction => flavor == 'prod';
}

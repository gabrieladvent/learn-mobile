import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version.g.dart';

@Riverpod(keepAlive: true)
String appVersion(Ref ref) {
  throw UnimplementedError(
    'appVersionProvider harus di-override di ProviderScope. '
    'Lihat main.dart.',
  );
}

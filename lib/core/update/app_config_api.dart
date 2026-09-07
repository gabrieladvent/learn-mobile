import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/api_client.dart';
import '../network/api_envelope.dart';
import 'app_release_info.dart';

part 'app_config_api.g.dart';

class AppConfigApi {
  const AppConfigApi(this._client);

  final ApiClient _client;

  Future<AppReleaseInfo> fetch() async {
    final res = await _client.get<Map<String, dynamic>>('/app-config');

    return AppReleaseInfo.fromJson(ApiEnvelope.fromJson(res.data!).data);
  }
}

@Riverpod(keepAlive: true)
AppConfigApi appConfigApi(Ref ref) =>
    AppConfigApi(ref.watch(apiClientProvider));

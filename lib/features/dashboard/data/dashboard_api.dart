import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/dashboard.dart';

part 'dashboard_api.g.dart';

class DashboardApi {
  const DashboardApi(this._client);

  final ApiClient _client;

  Future<Dashboard> fetch() async {
    final res = await _client.get<Map<String, dynamic>>('/dashboard');

    return Dashboard.fromJson(ApiEnvelope.fromJson(res.data!).data ?? const {});
  }
}

@Riverpod(keepAlive: true)
DashboardApi dashboardApi(Ref ref) => DashboardApi(ref.watch(apiClientProvider));

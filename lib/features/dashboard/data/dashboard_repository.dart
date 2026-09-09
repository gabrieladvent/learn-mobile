import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/dashboard.dart';
import 'dashboard_api.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  const DashboardRepository(this._api);

  final DashboardApi _api;

  Future<Dashboard> load() => _api.fetch();
}

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(ref.watch(dashboardApiProvider));

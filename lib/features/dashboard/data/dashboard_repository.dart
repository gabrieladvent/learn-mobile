import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/stale_while_revalidate.dart';
import '../domain/dashboard.dart';
import 'dashboard_api.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  const DashboardRepository(this._api, this._cache);

  final DashboardApi _api;
  final CacheStore _cache;

  Stream<Cached<Dashboard>> watch() => staleWhileRevalidate(
    cache: _cache,
    key: CacheKeys.dashboard,
    fetch: _api.fetch,
    decode: Dashboard.fromJson,
  );

  Future<void> setPinned(String courseId, {required bool pinned}) =>
      _api.setPinned(courseId, pinned: pinned);
}

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) => DashboardRepository(
  ref.watch(dashboardApiProvider),
  ref.watch(cacheStoreProvider),
);

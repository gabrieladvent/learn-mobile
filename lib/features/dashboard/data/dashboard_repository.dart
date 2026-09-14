import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/cached.dart';
import '../domain/dashboard.dart';
import 'dashboard_api.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  const DashboardRepository(this._api, this._cache);

  final DashboardApi _api;
  final CacheStore _cache;

  Stream<Cached<Dashboard>> watch() async* {
    final cached = await _cache.read(CacheKeys.dashboard);

    if (cached != null) {
      yield Cached(
        value: Dashboard.fromJson(cached.payload),
        fetchedAt: cached.fetchedAt,
        isFresh: false,
      );
    }

    try {
      final payload = await _api.fetch();
      await _cache.write(CacheKeys.dashboard, payload);

      yield Cached(
        value: Dashboard.fromJson(payload),
        fetchedAt: DateTime.now(),
        isFresh: true,
      );
    } catch (_) {
      if (cached == null) rethrow;

      yield Cached(
        value: Dashboard.fromJson(cached.payload),
        fetchedAt: cached.fetchedAt,
        isFresh: false,
        refreshFailed: true,
      );
    }
  }
}

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) => DashboardRepository(
  ref.watch(dashboardApiProvider),
  ref.watch(cacheStoreProvider),
);

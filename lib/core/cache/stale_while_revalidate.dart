import 'cache_store.dart';
import 'cached.dart';

Stream<Cached<T>> staleWhileRevalidate<T>({
  required CacheStore cache,
  required String key,
  required Future<Map<String, dynamic>> Function() fetch,
  required T Function(Map<String, dynamic> json) decode,
}) async* {
  final stored = _decodeStored(await cache.read(key), decode);

  if (stored != null) yield stored;

  try {
    final payload = await fetch();
    final value = decode(payload);
    await cache.write(key, payload);

    yield Cached(value: value, fetchedAt: DateTime.now(), isFresh: true);
  } catch (_) {
    if (stored == null) rethrow;

    yield Cached(
      value: stored.value,
      fetchedAt: stored.fetchedAt,
      isFresh: false,
      refreshFailed: true,
    );
  }
}

Cached<T>? _decodeStored<T>(
  CacheEntry? entry,
  T Function(Map<String, dynamic> json) decode,
) {
  if (entry == null) return null;

  try {
    return Cached(
      value: decode(entry.payload),
      fetchedAt: entry.fetchedAt,
      isFresh: false,
    );
  } catch (_) {
    return null;
  }
}

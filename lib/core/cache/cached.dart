import 'package:flutter/foundation.dart';

@immutable
class Cached<T> {
  const Cached({
    required this.value,
    required this.fetchedAt,
    required this.isFresh,
    this.refreshFailed = false,
  });

  final T value;
  final DateTime fetchedAt;
  final bool isFresh;
  final bool refreshFailed;

  Duration get age => DateTime.now().difference(fetchedAt);
}

String formatLastUpdated(Duration age) {
  if (age.inMinutes < 1) return 'baru saja';
  if (age.inMinutes < 60) return '${age.inMinutes} menit lalu';
  if (age.inHours < 24) return '${age.inHours} jam lalu';
  if (age.inDays == 1) return 'kemarin';

  return '${age.inDays} hari lalu';
}

import 'package:sentry_flutter/sentry_flutter.dart';

void scrubEventExtra(SentryEvent event, Object? Function(Object?) scrub) {
  event.extra = scrub(event.extra) as Map<String, dynamic>?;
}

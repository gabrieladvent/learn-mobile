library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/app_config.dart';

Future<void> runWithCrashReporting(
  Future<void> Function() appRunner, {
  required String release,
  AppConfig config = AppConfig.current,
}) async {
  if (config.sentryDsn.isEmpty) return appRunner();

  await SentryFlutter.init((options) {
    options.dsn = config.sentryDsn;
    options.environment = config.flavor;
    options.release = release;
    options.sendDefaultPii = false;
    options.beforeSend = (event, hint) => scrubEvent(event);
    options.beforeBreadcrumb = (breadcrumb, hint) => scrubBreadcrumb(breadcrumb);
  }, appRunner: appRunner);
}

Future<void> setCrashReportUser(
  String? studentId, {
  ScopeConfigurator configureScope = Sentry.configureScope,
}) async {
  await configureScope(
    (scope) =>
        scope.setUser(studentId == null ? null : SentryUser(id: studentId)),
  );
}

typedef ScopeConfigurator = FutureOr<void> Function(ScopeCallback callback);

SentryEvent? scrubEvent(SentryEvent event) {
  event.request = _scrubRequest(event.request);
  event.user = _scrubUser(event.user);
  // JANGAN HAPUS baris `ignore` di bawah: itu direktif untuk analyzer, bukan
  // komentar penjelas. Tanpanya `flutter analyze` gagal dan CI merah.
  //
  // `extra` memang sudah usang, tapi selama field-nya masih ada ia masih bisa
  // mengangkut data — dan field yang tidak lagi diperhatikan siapa pun justru
  // tempat paling mungkin sebuah kebocoran menetap.
  // ignore: deprecated_member_use
  event.extra = _scrubValue(event.extra) as Map<String, dynamic>?;

  for (final key in event.contexts.keys.toList()) {
    final value = event.contexts[key];

    if (value is Map || value is List) {
      event.contexts[key] = _scrubValue(value);
    }
  }

  event.tags = _scrubTags(event.tags);
  event.breadcrumbs = event.breadcrumbs
      ?.map(scrubBreadcrumb)
      .whereType<Breadcrumb>()
      .toList();

  return event;
}

Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb) {
  if (breadcrumb == null) return null;

  breadcrumb.data = _scrubValue(breadcrumb.data) as Map<String, dynamic>?;

  return breadcrumb;
}

SentryRequest? _scrubRequest(SentryRequest? request) {
  if (request == null) return null;

  final url = request.url;
  final sensitive = url != null && isSensitiveEndpoint(url);

  return SentryRequest(
    url: url,
    method: request.method,
    queryString: sensitive ? null : request.queryString,
    fragment: request.fragment,
    apiTarget: request.apiTarget,
    headers: _scrubHeaders(request.headers),
    env: request.env,
    data: sensitive ? null : _scrubValue(request.data),
  );
}

SentryUser? _scrubUser(SentryUser? user) {
  if (user == null) return null;

  return SentryUser(id: user.id);
}

Map<String, String> _scrubHeaders(Map<String, String> headers) {
  final scrubbed = <String, String>{};

  for (final entry in headers.entries) {
    if (_sensitiveHeaders.contains(entry.key.toLowerCase())) continue;

    scrubbed[entry.key] = entry.value;
  }

  return scrubbed;
}

Map<String, String>? _scrubTags(Map<String, String>? tags) {
  if (tags == null) return null;

  return {
    for (final entry in tags.entries)
      if (!_isSensitiveKey(entry.key)) entry.key: entry.value,
  };
}

Object? _scrubValue(Object? value, [int depth = 0]) {
  if (depth > 8) return _redacted;

  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _isSensitiveKey(entry.key.toString())
            ? _redacted
            : _scrubValue(entry.value, depth + 1),
    };
  }

  if (value is List) {
    return value.map((item) => _scrubValue(item, depth + 1)).toList();
  }

  return value;
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  return _sensitiveFields.contains(normalized);
}

@visibleForTesting
bool isSensitiveEndpoint(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();

  return _sensitivePaths.any(path.contains);
}

const _redacted = '[disaring]';

const _sensitiveHeaders = {'authorization', 'cookie', 'set-cookie'};

const _sensitiveFields = {
  'password',
  'passwordconfirmation',
  'currentpassword',
  'newpassword',
  'token',
  'accesstoken',
  'authorization',
  'nisn',
};

const _sensitivePaths = {'/auth', '/exam', '/ujian'};

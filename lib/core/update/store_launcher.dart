import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openStoreUrl(
  String url, {
  @visibleForTesting UrlLauncher launcher = launchUrl,
}) async {
  final target = Uri.tryParse(url);

  if (target == null || !_allowedSchemes.contains(target.scheme)) return false;

  try {
    return await launcher(target, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}

typedef UrlLauncher = Future<bool> Function(Uri url, {LaunchMode mode});

const _allowedSchemes = {'https', 'market', 'itms-apps'};

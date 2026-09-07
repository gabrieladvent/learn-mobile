import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'force_update_info.dart';

part 'force_update_controller.g.dart';

@Riverpod(keepAlive: true)
class ForceUpdateController extends _$ForceUpdateController {
  @override
  ForceUpdateInfo? build() => null;

  void reportRejected(ForceUpdateInfo info) {
    if (state != null) return;

    state = info;
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/app_preferences.dart';

part 'intro_controller.g.dart';

@Riverpod(keepAlive: true)
class IntroController extends _$IntroController {
  @override
  Future<bool> build() {
    return ref.watch(appPreferencesProvider).hasSeenIntro();
  }

  Future<void> complete() async {
    state = const AsyncValue.data(true);

    await ref.read(appPreferencesProvider).markIntroSeen();
  }
}

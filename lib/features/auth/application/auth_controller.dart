import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  static const _minimumSplash = Duration(milliseconds: 700);

  @override
  Future<AuthSession?> build() async {
    final restoring = ref.watch(authRepositoryProvider).restore();
    final minimum = Future<void>.delayed(_minimumSplash);

    final session = await restoring;
    await minimum;

    return session;
  }

  Future<void> login({required String nisn, required String password}) async {
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(
            nisn: nisn,
            password: password,
            deviceName: 'mobile',
          );
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    markPasswordChanged();
  }

  void markPasswordChanged() {
    final session = state.value;
    if (session == null) return;

    state = AsyncValue.data(session.copyWith(mustChangePassword: false));
  }
}

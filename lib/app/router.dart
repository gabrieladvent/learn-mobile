import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/ui/app_background.dart';
import '../core/update/force_update_controller.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/onboarding/application/intro_controller.dart';
import '../features/onboarding/presentation/intro_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/app_update/presentation/force_update_screen.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final intro = ref.read(introControllerProvider);
      final auth = ref.read(authControllerProvider);

      return resolveRedirect(
        rejectedByServer: ref.read(forceUpdateControllerProvider) != null,
        stillLoading:
            (intro.isLoading && !intro.hasValue) ||
            (auth.isLoading && !auth.hasValue),
        introSeen: intro.value,
        session: auth.value,
        here: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/', pageBuilder: _page(const _SplashScreen())),
      GoRoute(path: '/intro', pageBuilder: _page(const IntroScreen())),
      GoRoute(path: '/login', pageBuilder: _page(const LoginScreen())),
      GoRoute(
        path: '/change-password',
        pageBuilder: _page(const ChangePasswordScreen()),
      ),
      GoRoute(path: '/home', pageBuilder: _page(const HomeScreen())),
      GoRoute(
        path: '/force-update',
        pageBuilder: _page(const ForceUpdateScreen()),
      ),
    ],
  );
}

const _entryPoints = {'/', '/login', '/intro', '/change-password'};

@visibleForTesting
String? resolveRedirect({
  required bool rejectedByServer,
  required bool stillLoading,
  required bool? introSeen,
  required AuthSession? session,
  required String here,
}) {
  if (rejectedByServer) {
    return here == '/force-update' ? null : '/force-update';
  }

  if (stillLoading) return here == '/' ? null : '/';

  if (introSeen == false) {
    return here == '/intro' ? null : '/intro';
  }

  if (session == null) {
    return here == '/login' ? null : '/login';
  }

  if (session.mustChangePassword) {
    return here == '/change-password' ? null : '/change-password';
  }

  if (_entryPoints.contains(here)) return '/home';

  return null;
}

GoRouterPageBuilder _page(Widget child) {
  return (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1, curve: AppMotion.enter),
        ),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.94,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
          child: child,
        ),
      );
    },
  );
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(introControllerProvider, (_, _) => notifyListeners());
    ref.listen(forceUpdateControllerProvider, (_, _) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.slow,
                curve: AppMotion.enter,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: child,
                  ),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

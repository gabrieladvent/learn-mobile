import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';

part 'router.g.dart';

/// Seluruh aturan "siapa boleh membuka layar apa" ada di SATU tempat.
///
/// Kenapa terpusat: kalau tiap layar mengecek sendiri di `initState`, cepat
/// atau lambat ada satu layar yang lupa — dan siswa yang belum ganti password
/// akan menabrak error 403 di layar itu tanpa tahu jalan keluarnya.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    // `refreshListenable` membuat router mengevaluasi ulang `redirect` setiap
    // kali state auth berubah — jadi logout langsung melempar ke /login tanpa
    // perlu navigasi manual dari mana pun.
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // Masih memeriksa token tersimpan saat aplikasi baru dibuka → tahan di
      // splash. `!auth.hasValue` membatasi ini pada pemuatan PERTAMA saja:
      // begitu state pernah terisi, loading berikutnya tidak lagi menendang
      // siswa ke splash.
      if (auth.isLoading && !auth.hasValue) {
        return state.matchedLocation == '/' ? null : '/';
      }

      final session = auth.value;
      final goingToLogin = state.matchedLocation == '/login';

      // URUTAN GUARD DI BAWAH INI PENTING. Membaliknya membuat siswa yang
      // belum ganti password bisa lolos ke layar konten.

      // 1. Belum login → hanya boleh ke /login.
      if (session == null) {
        return goingToLogin ? null : '/login';
      }

      // 2. Sudah login tapi password masih default → kunci di layar ganti
      //    password. Ini mencerminkan middleware backend; tanpa ini, aplikasi
      //    akan menabrak `password_change_required` di setiap layar konten.
      if (session.mustChangePassword) {
        return state.matchedLocation == '/change-password'
            ? null
            : '/change-password';
      }

      // 3. Sudah login penuh, tapi masih di splash/login → lempar ke beranda.
      if (goingToLogin || state.matchedLocation == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/change-password', builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    ],
  );
}

/// Jembatan dari Riverpod ke `refreshListenable` milik go_router, yang
/// mengharapkan sebuah [Listenable].
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

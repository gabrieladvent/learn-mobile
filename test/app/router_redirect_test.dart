import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/app/router.dart';
import 'package:learn_mobile/features/auth/domain/auth_session.dart';
import 'package:learn_mobile/features/auth/domain/student.dart';

AuthSession _session({bool mustChangePassword = false}) => AuthSession(
      token: 'token',
      student: const Student(
        id: 'id',
        fullName: 'Budi Santoso',
        nisn: '1234567890',
        className: 'X IPA 1',
      ),
      mustChangePassword: mustChangePassword,
    );

String? redirect({
  bool rejectedByServer = false,
  bool stillLoading = false,
  bool? introSeen = true,
  AuthSession? session,
  required String here,
}) =>
    resolveRedirect(
      rejectedByServer: rejectedByServer,
      stillLoading: stillLoading,
      introSeen: introSeen,
      session: session,
      here: here,
    );

void main() {
  group('resolveRedirect', () {
    test('versi yang ditolak server mengunci di layar force update', () {
      // ADR-0013: 426 ditangani global. Kalau guard ini longgar, siswa dengan
      // versi lama masih bisa masuk ke layar yang seluruh datanya ditolak
      // server — termasuk layar ujian, tempat kegagalannya merusak nilai.
      expect(redirect(rejectedByServer: true, here: '/'), '/force-update');
      expect(redirect(rejectedByServer: true, here: '/login'), '/force-update');
      expect(
        redirect(rejectedByServer: true, session: _session(), here: '/home'),
        '/force-update',
      );
      expect(
        redirect(rejectedByServer: true, introSeen: false, here: '/intro'),
        '/force-update',
        reason: 'Force update menang di atas intro.',
      );
      expect(
        redirect(rejectedByServer: true, stillLoading: true, here: '/login'),
        '/force-update',
        reason: 'Tidak perlu menunggu penyimpanan dibaca untuk mengunci.',
      );
      expect(redirect(rejectedByServer: true, here: '/force-update'), isNull);
    });

    test('tanpa penolakan server, layar force update tidak pernah muncul', () {
      expect(redirect(session: _session(), here: '/home'), isNull);
      expect(
        redirect(session: _session(), here: '/force-update'),
        isNull,
        reason:
            'Rute ini tidak terdaftar sebagai pintu masuk, jadi tidak ada '
            'lemparan otomatis ke beranda — tapi juga tidak ada yang '
            'mengantar ke sini selain guard di atas.',
      );
    });

    test('menahan di splash selama penyimpanan masih dibaca', () {
      expect(redirect(stillLoading: true, here: '/login'), '/');
      expect(redirect(stillLoading: true, here: '/'), isNull);
    });

    test('intro belum pernah dilihat menang di atas segalanya', () {
      expect(redirect(introSeen: false, here: '/'), '/intro');
      expect(redirect(introSeen: false, here: '/login'), '/intro');
      expect(
        redirect(introSeen: false, session: _session(), here: '/home'),
        '/intro',
        reason: 'Sudah login pun, intro tetap ditampilkan lebih dulu.',
      );
      expect(redirect(introSeen: false, here: '/intro'), isNull);
    });

    test('belum login diarahkan ke login', () {
      expect(redirect(here: '/home'), '/login');
      expect(redirect(here: '/login'), isNull);
    });

    test('password default mengunci di layar ganti password', () {
      final session = _session(mustChangePassword: true);

      expect(redirect(session: session, here: '/home'), '/change-password');
      expect(redirect(session: session, here: '/change-password'), isNull);
    });

    test('setelah password diganti, siswa dipindahkan ke beranda', () {
      // REGRESI. `/change-password` sempat tidak terdaftar sebagai pintu masuk:
      // guard melepaskannya, tapi tidak ada yang memindahkannya. Siswa berhasil
      // ganti password lalu diam di layar yang sama tanpa tahu harus apa.
      expect(
        redirect(session: _session(), here: '/change-password'),
        '/home',
      );
    });

    test('setelah intro selesai, siswa tidak tertinggal di sana', () {
      // REGRESI dengan sebab yang sama seperti di atas.
      expect(redirect(session: _session(), here: '/intro'), '/home');
    });

    test('sudah login penuh dan sudah di beranda → dibiarkan', () {
      expect(redirect(session: _session(), here: '/home'), isNull);
    });

    test('splash dan login ikut melempar ke beranda kalau sudah lengkap', () {
      expect(redirect(session: _session(), here: '/'), '/home');
      expect(redirect(session: _session(), here: '/login'), '/home');
    });
  });
}

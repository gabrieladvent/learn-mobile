import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../application/auth_controller.dart';

/// Ganti password default — WAJIB, tidak bisa dilewati.
///
/// Password awal siswa adalah tanggal lahirnya, yang mudah ditebak siapa pun
/// yang mengenalnya. Backend menolak semua endpoint konten selama password itu
/// belum diganti, jadi tidak ada gunanya menyediakan tombol "nanti saja".
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;

  /// Kegagalan terakhir. Disimpan lokal, bukan di AuthController: yang gagal
  /// adalah satu pengiriman formulir, bukan status login siswa.
  AppFailure? _failure;

  /// Ketidakcocokan konfirmasi dicek di klien supaya siswa tidak perlu
  /// menunggu perjalanan ke server untuk kesalahan yang sudah kelihatan.
  String? _confirmError;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _confirmError = 'Konfirmasi tidak sama dengan password baru.');
      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
      _confirmError = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _current.text,
            newPassword: _password.text,
          );
      // Berhasil: markPasswordChanged() di controller sudah memicu router
      // memindahkan siswa ke beranda. Tidak ada navigasi manual di sini.
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      // Kalau berhasil, widget ini sudah dibuang router — maka cek `mounted`.
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Pesan galat per-field datang dari `response_data.fields` milik server,
  /// bukan ditebak di klien. Aturan panjang minimum dan "tidak boleh sama
  /// dengan password lama" ditegakkan di satu tempat: backend.
  String? _serverErrorFor(String field) {
    final failure = _failure;

    return failure is ValidationFailure ? failure.firstFor(field) : null;
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Password'),
        actions: [
          // Satu-satunya jalan keluar selain mengganti password. Tanpa tombol
          // ini, siswa yang salah masuk sebagai orang lain akan terkunci:
          // guard router menahannya di layar ini selama sesinya masih ada.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _submitting
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Password awalmu adalah tanggal lahir dan mudah ditebak.\n'
                'Ganti dulu sebelum melanjutkan.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _current,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password saat ini',
                  helperText: 'Tanggal lahirmu, format 2008-05-10',
                  border: const OutlineInputBorder(),
                  errorText: _serverErrorFor('current_password'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password baru',
                  helperText: 'Minimal 8 karakter',
                  border: const OutlineInputBorder(),
                  errorText: _serverErrorFor('password'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirm,
                obscureText: true,
                onSubmitted: (_) => _submitting ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Ulangi password baru',
                  border: const OutlineInputBorder(),
                  errorText: _confirmError,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Password Baru'),
              ),
              // Galat non-validasi (jaringan, server) tampil di bawah tombol,
              // bukan menempel di salah satu input.
              if (failure != null && failure is! ValidationFailure) ...[
                const SizedBox(height: 16),
                Text(
                  failure.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

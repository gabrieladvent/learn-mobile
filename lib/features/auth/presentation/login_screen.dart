import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../application/auth_controller.dart';

/// Layar masuk: NISN + password.
///
/// `ConsumerStatefulWidget` = StatefulWidget yang bisa membaca provider.
/// Yang biasa (`StatefulWidget`) tidak punya `ref`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nisn = TextEditingController();
  final _password = TextEditingController();

  /// Keadaan milik layar ini saja: sedang mengirim formulir atau tidak.
  /// Tidak ditaruh di AuthController karena router memakai `isLoading` di sana
  /// untuk arti yang berbeda — lihat komentar di AuthController.login().
  bool _submitting = false;

  @override
  void dispose() {
    _nisn.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            nisn: _nisn.text.trim(),
            password: _password.text,
          );
    } finally {
      // `mounted` wajib dicek: kalau login berhasil, router sudah memindahkan
      // siswa ke layar lain dan widget ini sudah dibuang.
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // `ref.watch` = ikut rebuild saat nilainya berubah.
    // (`ref.read` dipakai di dalam callback seperti _submit, karena di sana
    //  kita cuma mau memicu aksi, bukan berlangganan perubahan.)
    final auth = ref.watch(authControllerProvider);

    final failure = auth.error;
    final isLoading = _submitting;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Masuk', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _nisn,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NISN',
                    border: const OutlineInputBorder(),
                    // Pesan galat per input diambil dari `response_data.fields`
                    // milik server — bukan ditebak di klien.
                    errorText: failure is ValidationFailure
                        ? failure.firstFor('nisn')
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: failure is ValidationFailure
                        ? failure.firstFor('password')
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Masuk'),
                ),
                // Galat non-validasi (jaringan, rate limit) tampil di bawah
                // tombol, bukan menempel di salah satu input.
                if (failure is AppFailure && failure is! ValidationFailure) ...[
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
      ),
    );
  }
}

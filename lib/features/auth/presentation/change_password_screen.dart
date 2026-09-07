import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_submit_button.dart';
import '../../../core/ui/failure_banner.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../../core/ui/form_layout.dart';
import '../../../core/ui/password_field.dart';
import '../application/auth_controller.dart';

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
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _submitting = false;

  AppFailure? _failure;
  
  String? _confirmError;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_password.text != _confirm.text) {
      setState(
        () => _confirmError = 'Konfirmasi tidak sama dengan password baru.',
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

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

      messenger.showSuccess('Password berhasil diganti.');
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);

    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _serverErrorFor(String field) {
    final failure = _failure;

    return failure is ValidationFailure ? failure.firstFor(field) : null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accents[2];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Password'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _submitting
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: FormLayout(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.container,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: accent.onContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Password awalmu adalah tanggal lahir dan mudah ditebak '
                    'siapa pun yang mengenalmu. Ganti dulu sebelum melanjutkan.',
                    style: TextStyle(color: accent.onContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PasswordField(
            controller: _current,
            label: 'Password saat ini',
            hint: 'Masukan password saat ini',
            onSubmitted: _passwordFocus.requestFocus,
            errorText: _serverErrorFor('current_password'),
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            label: 'Password baru',
            hint: 'Masukan password baru',
            onSubmitted: _confirmFocus.requestFocus,
            errorText: _serverErrorFor('password'),
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            controller: _confirm,
            focusNode: _confirmFocus,
            label: 'Ulangi password baru',
            hint: 'Ketik ulang password baru',
            textInputAction: TextInputAction.done,
            onSubmitted: _submitting ? null : _submit,
            errorText: _confirmError,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSubmitButton(
            label: 'Simpan Password Baru',
            loading: _submitting,
            onPressed: _submit,
          ),
          FailureBanner(failure: _failure),
        ],
      ),
    );
  }
}

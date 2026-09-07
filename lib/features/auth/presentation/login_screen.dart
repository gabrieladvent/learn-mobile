import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_field.dart';
import '../../../core/ui/app_submit_button.dart';
import '../../../core/ui/failure_banner.dart';
import '../../../core/ui/form_layout.dart';
import '../../../core/ui/password_field.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nisn = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _submitting = false;

  @override
  void dispose() {
    _nisn.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(nisn: _nisn.text.trim(), password: _password.text);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final accent = context.accents[0];

    final failure = auth.error is AppFailure ? auth.error! as AppFailure : null;

    return Scaffold(
      body: AppBackground(
        child: FormLayout(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: accent.container,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 44,
                  color: accent.onContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Masuk',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Masuk untuk akses materi dan tugasmu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppField(
              controller: _nisn,
              label: 'NISN',
              hint: 'Masukan NISN',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: _passwordFocus.requestFocus,
              errorText: failure is ValidationFailure
                  ? failure.firstFor('nisn')
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Masukan password',
              textInputAction: TextInputAction.done,
              onSubmitted: _submitting ? null : _submit,
              errorText: failure is ValidationFailure
                  ? failure.firstFor('password')
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSubmitButton(
              label: 'Masuk',
              loading: _submitting,
              onPressed: _submit,
            ),
            FailureBanner(failure: failure),
          ],
        ),
      ),
    );
  }
}

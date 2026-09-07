import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_semantic.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_background.dart';
import '../../../core/ui/app_field.dart';
import '../../../core/ui/app_orb.dart';
import '../../../core/ui/app_submit_button.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/form_layout.dart';
import '../../../core/ui/glass_surface.dart';
import '../../../core/ui/reveal.dart';
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

    final failure = auth.error is AppFailure ? auth.error! as AppFailure : null;

    ref.listen(authControllerProvider, (previous, next) {
      final error = next.error;

      if (error is AppFailure && error is! ValidationFailure) {
        AppToast.of(context).showFailure(error.message);
      }
    });

    return Scaffold(
      body: AppBackground(
        child: FormLayout(
          children: [
            Reveal.at(
              0,
              child: Center(
                child: const AppOrb(
                  icon: Icons.auto_stories_rounded,
                  colors: AppGradients.brand,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Reveal.at(
              1,
              child: GradientTitle(
                'Selamat datang',
                colors: AppGradients.brand,
                style: theme.textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Reveal.at(
              2,
              child: Text(
                'Materi, tugas, dan ujianmu — semuanya di sini.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Reveal.at(
              3,
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      colors: AppGradients.brand,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

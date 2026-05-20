import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AuthShell(
      title: 'Welcome Back!',
      subtitle: 'Login to continue. Only for LNU students.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authController.errorMessage != null) ...[
              AuthErrorBanner(
                message: authController.errorMessage!,
                onDismissed: authController.clearError,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: AuthValidators.lnuEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authController.isBusy
                    ? null
                    : () => context.go('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: authController.isBusy ? null : _submit,
              child: authController.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: authController.isBusy
                  ? null
                  : () => context.go('/register'),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final authController = context.read<AuthController>();
    if (!authController.useStaticLogin && !_formKey.currentState!.validate()) {
      return;
    }

    await authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}

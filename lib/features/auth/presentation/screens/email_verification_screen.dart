import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final email = authController.currentUser?.email ?? 'your LNU email';

    return AuthShell(
      title: 'Verify your LNU email',
      subtitle: 'We sent a verification link to $email.',
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verification link has been sent to $email.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Open your LNU inbox, tap the verification link, then return here.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: authController.isBusy
                ? null
                : authController.reloadCurrentUser,
            icon: authController.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('I verified my email'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: authController.isBusy
                ? null
                : authController.sendEmailVerification,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Resend verification email'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: authController.isBusy ? null : authController.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Use another account'),
          ),
        ],
      ),
    );
  }
}

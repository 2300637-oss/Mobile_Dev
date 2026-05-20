import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shell.dart';

class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final errorCode =
        uri.queryParameters['error_code'] ??
        _fragmentParameters(uri)['error_code'];
    final errorDescription =
        uri.queryParameters['error_description'] ??
        _fragmentParameters(uri)['error_description'];
    final hasError = errorCode != null || errorDescription != null;

    if (!hasError) {
      return AuthShell(
        title: 'Your email is now verified!',
        subtitle: 'You can now continue to login.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      Icons.verified_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can now sign in and use LNU Student Skills Commission.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Continue to login'),
            ),
          ],
        ),
      );
    }

    final expired = errorCode == 'otp_expired';
    return AuthShell(
      title: expired ? 'Verification link expired' : 'Verification failed',
      subtitle: expired
          ? 'This email link is invalid or has already expired.'
          : (errorDescription ?? 'Supabase could not verify this email link.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                expired
                    ? 'Open the newest verification email only. If this keeps happening, go back to login and request a fresh verification email.'
                    : (errorDescription ?? 'Please request a new link.'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }

  Map<String, String> _fragmentParameters(Uri uri) {
    if (uri.fragment.isEmpty) {
      return const {};
    }
    return Uri.splitQueryString(uri.fragment);
  }
}

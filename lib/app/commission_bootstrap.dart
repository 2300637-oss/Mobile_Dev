import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../features/auth/data/firebase_auth_repository.dart';
import '../firebase_options.dart';
import 'app.dart';

class CommissionBootstrap extends StatefulWidget {
  const CommissionBootstrap({super.key});

  @override
  State<CommissionBootstrap> createState() => _CommissionBootstrapState();
}

class _CommissionBootstrapState extends State<CommissionBootstrap> {
  late final Future<void> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization =
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firebase initialization timed out.');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return CommissionApp(
            authRepository: FirebaseAuthRepository(
              firebaseAuth: FirebaseAuth.instance,
              firestore: FirebaseFirestore.instance,
            ),
          );
        }

        if (snapshot.hasError) {
          return FirebaseSetupRequiredScreen(error: snapshot.error);
        }

        return const _BootstrapLoadingApp();
      },
    );
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class FirebaseSetupRequiredScreen extends StatelessWidget {
  const FirebaseSetupRequiredScreen({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003566)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.settings_outlined, size: 56),
                    const SizedBox(height: 24),
                    Text(
                      'Firebase setup required',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The app installed correctly, but Firebase credentials are not configured yet. Run flutterfire configure from the project root, then rebuild the app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    const SelectableText(
                      'flutterfire configure',
                      textAlign: TextAlign.center,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 24),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Technical details'),
                        children: [
                          SelectableText(
                            error.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Missing FirebaseOptions resource.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

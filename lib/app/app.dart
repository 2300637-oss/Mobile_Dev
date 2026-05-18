import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import '../features/admin/admin_dashboard_page.dart';
import '../features/admin/admin_guard.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/controllers/profile_controller.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/shared/presentation/screens/module_placeholder_screen.dart';

class CommissionApp extends StatefulWidget {
  const CommissionApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<CommissionApp> createState() => _CommissionAppState();
}

class _CommissionAppState extends State<CommissionApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(widget.authRepository)..start();
    _router = _buildRouter(_authController);
  }

  @override
  void dispose() {
    _router.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authController,
      child: MaterialApp.router(
        title: 'LNU SkillHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.midnightBlue,
            primary: AppColors.midnightBlue,
            secondary: AppColors.schoolBusYellow,
            error: AppColors.mahoganyRed,
            surface: AppColors.white,
          ),
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.inkBlack,
            surfaceTintColor: AppColors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.inkBlack,
            displayColor: AppColors.inkBlack,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

GoRouter _buildRouter(AuthController authController) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final isInitializing = authController.isInitializing;
      final user = authController.currentUser;
      final isSignedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;
      final location = state.matchedLocation;
      final isAdminRoute = location.startsWith('/admin/');
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isVerificationRoute = location == '/verify-email';

      if (isAdminRoute) {
        return null;
      }

      if (isInitializing) {
        return location == '/splash' ? null : '/splash';
      }

      if (!isSignedIn && !isAuthRoute) {
        return '/login';
      }

      if (isSignedIn && !isEmailVerified && !isVerificationRoute) {
        return '/verify-email';
      }

      if (isSignedIn &&
          isEmailVerified &&
          (isAuthRoute || isVerificationRoute || location == '/splash')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) =>
            const AdminGuard(child: AdminDashboardPage()),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const ModulePlaceholderScreen(
          title: 'Create Post',
          icon: Icons.add_photo_alternate_outlined,
          message:
              'Post composer for artwork, commission updates, and announcements.',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final user = authController.currentUser;
          if (user == null) {
            return const SplashScreen();
          }

          return ChangeNotifierProvider(
            create: (_) => ProfileController(
              profileRepository: ProfileRepository(
                firestore: FirebaseFirestore.instance,
              ),
              uid: user.id,
            )..start(),
            child: const ProfileScreen(),
          );
        },
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ModulePlaceholderScreen(
          title: 'Services',
          icon: Icons.design_services_outlined,
          message:
              'Profile services will show commission offers and sample work.',
        ),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ModulePlaceholderScreen(
          title: 'Chat',
          icon: Icons.chat_bubble_outline,
          message: 'One-to-one real-time messaging will live here.',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const ModulePlaceholderScreen(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          message: 'Message alerts, reactions, shares, and commission updates.',
        ),
      ),
      GoRoute(
        path: '/commission-requests',
        builder: (context, state) => const ModulePlaceholderScreen(
          title: 'Commission Requests',
          icon: Icons.assignment_outlined,
          message:
              'Requests, statuses, progress, and deadlines will be tracked here.',
        ),
      ),
    ],
  );
}

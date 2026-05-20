import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/registration_complete_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/posts/data/supabase_public_post_repository.dart';
import '../features/posts/presentation/controllers/create_post_controller.dart';
import '../features/posts/presentation/screens/create_post_screen.dart';
import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/data/supabase_profile_repository.dart';
import '../features/profile/presentation/controllers/profile_controller.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/profile/presentation/screens/shared_posts_screen.dart';
import '../features/shared/presentation/screens/module_placeholder_screen.dart';

class CommissionApp extends StatefulWidget {
  const CommissionApp({
    super.key,
    required this.authRepository,
    this.useStaticLogin = true,
    this.requireEmailVerification = false,
  });

  final AuthRepository authRepository;
  final bool useStaticLogin;
  final bool requireEmailVerification;

  @override
  State<CommissionApp> createState() => _CommissionAppState();
}

class _CommissionAppState extends State<CommissionApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      widget.authRepository,
      useStaticLogin: widget.useStaticLogin,
      requireEmailVerification: widget.requireEmailVerification,
    )..start();
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
        title: 'LNU Skills Commission',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.navy,
            primary: AppColors.navy,
            secondary: AppColors.schoolBusYellow,
            error: AppColors.cinnabar,
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
      final requiresEmailVerification = authController.requireEmailVerification;
      final isEmailVerified =
          !requiresEmailVerification || (user?.emailVerified ?? false);
      final location = state.matchedLocation;
      final isEmailCallback =
          state.uri.queryParameters.containsKey('code') ||
          state.uri.fragment.contains('access_token');
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isVerificationRoute = location == '/verify-email';
      final isRegistrationCompleteRoute = location == '/registration-complete';

      if (isInitializing) {
        return (location == '/splash' || isEmailCallback) ? null : '/splash';
      }

      if (isEmailCallback && isSignedIn && isEmailVerified) {
        return '/registration-complete';
      }

      if (!isSignedIn &&
          !isAuthRoute &&
          !isRegistrationCompleteRoute &&
          !isEmailCallback) {
        return '/login';
      }

      if (isSignedIn &&
          requiresEmailVerification &&
          !isEmailVerified &&
          !isVerificationRoute &&
          !isRegistrationCompleteRoute) {
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
      GoRoute(
        path: '/registration-complete',
        builder: (context, state) => const RegistrationCompleteScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CreatePostController(
            repository: SupabasePublicPostRepository(
              client: Supabase.instance.client,
            ),
          ),
          child: const CreatePostScreen(),
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
              profileRepository: authController.useStaticLogin
                  ? LocalProfileRepository(
                      initialProfile: authController.staticProfile,
                    )
                  : SupabaseProfileRepository(client: Supabase.instance.client),
              uid: user.id,
            )..start(),
            child: const ProfileScreen(),
          );
        },
      ),
      GoRoute(
        path: '/users/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          if (uid.isEmpty) {
            return const SplashScreen();
          }

          final supabaseClient = Supabase.instance.client;
          return ChangeNotifierProvider(
            create: (_) => ProfileController(
              profileRepository: SupabaseProfileRepository(
                client: supabaseClient,
              ),
              uid: uid,
            )..start(),
            child: PublicProfileScreen(
              postsRepository: SupabasePublicPostRepository(
                client: supabaseClient,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/users/:uid/shared-posts',
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          if (uid.isEmpty) {
            return const SplashScreen();
          }

          return SharedPostsScreen(
            userId: uid,
            postsRepository: SupabasePublicPostRepository(
              client: Supabase.instance.client,
            ),
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

// lib/core/router/app_router.dart
//
// AppRouter — go_router configuration with authentication guard.

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/forgot_password_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/bloc/sign_up_bloc.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/home/presentation/screens/shell_screen.dart';
import '../../features/posts/domain/repositories/posts_repository.dart';
import '../../features/posts/presentation/bloc/create_post_bloc.dart';
import '../../features/posts/presentation/screens/create_post_screen.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/user_profile_bloc.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/user_profile_view_screen.dart';
import 'go_router_refresh_stream.dart';

/// Creates the application [GoRouter] with an auth-aware redirect guard.
///
/// - Unauthenticated users are always redirected to `/login`.
/// - Authenticated users are always redirected to `/home`.
GoRouter createAppRouter(AuthBloc authBloc, AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/forgot-password';

      if (authState is AuthInitial) return null;

      if (authState is Unauthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (authState is Authenticated) {
        return isAuthRoute ? '/home' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(
            repository: context.read<AuthRepository>(),
          ),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => BlocProvider<SignUpBloc>(
          create: (_) => SignUpBloc(
            repository: context.read<AuthRepository>(),
          ),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => BlocProvider<ForgotPasswordBloc>(
          create: (_) => ForgotPasswordBloc(
            repository: context.read<AuthRepository>(),
          ),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ShellScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => BlocProvider<CreatePostBloc>(
          create: (_) => CreatePostBloc(
            repository: context.read<PostsRepository>(),
          ),
          child: const CreatePostScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return BlocProvider<UserProfileBloc>(
            create: (_) => UserProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            )..add(UserProfileLoadRequested(uid: uid)),
            child: const UserProfileViewScreen(),
          );
        },
      ),
    ],
  );
}

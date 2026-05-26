// lib/main.dart
//
// Application entry point — Firebase initialisation, DI, and routing.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_firebase_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/data/datasources/chat_firebase_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/unread_count_cubit.dart';
import 'features/notifications/data/datasources/notifications_firebase_data_source.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/presentation/bloc/unread_notifications_count_cubit.dart';
import 'features/follows/data/datasources/follows_firebase_data_source.dart';
import 'features/follows/data/repositories/follows_repository_impl.dart';
import 'features/follows/domain/repositories/follows_repository.dart';
import 'features/posts/data/datasources/posts_firebase_data_source.dart';
import 'features/search/data/datasources/search_firebase_data_source.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/domain/repositories/search_repository.dart';
import 'features/posts/data/repositories/posts_repository_impl.dart';
import 'features/posts/domain/repositories/posts_repository.dart';
import 'features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'features/profile/data/datasources/profile_firebase_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_posts_bloc.dart';
import 'firebase_options.dart';

/// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authDataSource = AuthFirebaseDataSource(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
  final authRepository = AuthRepositoryImpl(dataSource: authDataSource);
  final authBloc = AuthBloc(repository: authRepository)
    ..add(const AuthStarted());
  final router = createAppRouter(authBloc, authRepository);

  runApp(
    PulseApp(
      authBloc: authBloc,
      authRepository: authRepository,
      router: router,
    ),
  );
}

/// Root application widget.
///
/// Provides [AuthRepository], [ProfileRepository], [AuthBloc], and
/// [ProfileBloc] to the entire widget tree.
class PulseApp extends StatelessWidget {
  /// Creates a [PulseApp].
  const PulseApp({
    super.key,
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    required GoRouter router,
  })  : _authBloc = authBloc,
        _authRepository = authRepository,
        _router = router;

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepositoryImpl(
            dataSource: ProfileFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
              storage: FirebaseStorage.instance,
              firebaseAuth: FirebaseAuth.instance,
            ),
          ),
        ),
        RepositoryProvider<PostsRepository>(
          create: (context) => PostsRepositoryImpl(
            dataSource: PostsFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
              storage: FirebaseStorage.instance,
            ),
          ),
        ),
        RepositoryProvider<FollowsRepository>(
          create: (context) => FollowsRepositoryImpl(
            dataSource: FollowsFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        ),
        RepositoryProvider<SearchRepository>(
          create: (context) => SearchRepositoryImpl(
            dataSource: SearchFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        ),
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepositoryImpl(
            dataSource: ChatFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (context) => NotificationsRepositoryImpl(
            dataSource: NotificationsFirebaseDataSource(
              firestore: FirebaseFirestore.instance,
            ),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<PostsFeedBloc>(
            create: (context) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId =
                  authState is Authenticated ? authState.user.uid : '';
              return PostsFeedBloc(
                repository: context.read<PostsRepository>(),
                followsRepository: context.read<FollowsRepository>(),
                currentUserId: currentUserId,
              )..add(const PostsFeedSubscriptionRequested());
            },
          ),
          BlocProvider<ProfilePostsBloc>(
            create: (context) => ProfilePostsBloc(
              postsRepository: context.read<PostsRepository>(),
            ),
          ),
          BlocProvider<UnreadCountCubit>(
            create: (context) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId =
                  authState is Authenticated ? authState.user.uid : '';
              return UnreadCountCubit(
                repository: context.read<ChatRepository>(),
                currentUserId: currentUserId,
              )..watchUnreadCount();
            },
          ),
          BlocProvider<UnreadNotificationsCountCubit>(
            create: (context) {
              final authState = context.read<AuthBloc>().state;
              final currentUserId =
                  authState is Authenticated ? authState.user.uid : '';
              return UnreadNotificationsCountCubit(
                repository: context.read<NotificationsRepository>(),
                userId: currentUserId,
              )..watchUnreadCount();
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Pulse',
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}

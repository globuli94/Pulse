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
import 'features/profile/data/datasources/profile_firebase_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
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

  final profileDataSource = ProfileFirebaseDataSource(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
  final profileRepository = ProfileRepositoryImpl(dataSource: profileDataSource);

  final router = createAppRouter(authBloc, authRepository);

  runApp(
    PulseApp(
      authBloc: authBloc,
      authRepository: authRepository,
      profileRepository: profileRepository,
      router: router,
    ),
  );
}

/// Root application widget.
///
/// Provides [AuthRepository] and [AuthBloc] to the entire widget tree via
/// [MultiRepositoryProvider] and [MultiBlocProvider].
class PulseApp extends StatelessWidget {
  /// Creates a [PulseApp].
  const PulseApp({
    super.key,
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required GoRouter router,
  })  : _authBloc = authBloc,
        _authRepository = authRepository,
        _profileRepository = profileRepository,
        _router = router;

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ProfileRepository>.value(
          value: _profileRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<ProfileBloc>(
            create: (ctx) =>
                ProfileBloc(repository: ctx.read<ProfileRepository>()),
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

import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/presentation/blocs/auth/auth_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  const googleWebClientId =
      '68837437433-qd5n2abfr8r9mc6onopl6oqcodka750u.apps.googleusercontent.com';
  const googleIosClientId =
      '68837437433-di5l5nafvclclv25gn07l5f6sicv8u6g.apps.googleusercontent.com';

  // Externos
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(
      clientId: Platform.isIOS ? googleIosClientId : null,
      serverClientId: googleWebClientId,
      scopes: const ['email', 'profile'],
    ),
  );

  // Auth — Data
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      supabase: sl<SupabaseClient>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthProvider>()),
  );

  // Auth — Use Cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));

  // Auth — BLoC (global)
  sl.registerFactory(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signOut: sl<SignOut>(),
    ),
  );
}

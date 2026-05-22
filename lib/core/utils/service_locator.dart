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
import '../../features/profile/data/providers/profile_provider.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/pets/data/providers/pet_provider.dart';
import '../../features/pets/data/repositories/pet_repository_impl.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';
import '../../features/pets/domain/usecases/create_pet.dart';
import '../../features/pets/domain/usecases/delete_pet.dart';
import '../../features/pets/domain/usecases/get_my_pets.dart';
import '../../features/pets/domain/usecases/update_pet.dart';
import '../../features/pets/presentation/blocs/pet_cubit.dart';
import '../../features/reports/data/providers/report_provider.dart';
import '../../features/reports/data/repositories/report_repository_impl.dart';
import '../../features/reports/domain/repositories/report_repository.dart';
import '../../features/reports/domain/usecases/create_lost_report.dart';
import '../../features/reports/domain/usecases/get_recent_reports.dart';
import '../../features/reports/presentation/blocs/report_form/report_form_cubit.dart';
import '../../features/profile/presentation/blocs/profile_cubit.dart';

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

  // Profile — Data
  sl.registerLazySingleton<ProfileProvider>(
    () => ProfileProvider(supabase: sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileProvider>()),
  );

  // Profile — Use Cases
  sl.registerLazySingleton(() => GetProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<ProfileRepository>()));

  // Profile — Cubit (singleton global: controla el flujo del router)
  sl.registerLazySingleton(
    () => ProfileCubit(
      getProfile: sl<GetProfile>(),
      updateProfile: sl<UpdateProfile>(),
    ),
  );

  // Pets — Data
  sl.registerLazySingleton<PetProvider>(
    () => PetProvider(supabase: sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<PetRepository>(
    () => PetRepositoryImpl(sl<PetProvider>()),
  );

  // Pets — Use Cases
  sl.registerLazySingleton(() => GetMyPets(sl<PetRepository>()));
  sl.registerLazySingleton(() => CreatePet(sl<PetRepository>()));
  sl.registerLazySingleton(() => UpdatePet(sl<PetRepository>()));
  sl.registerLazySingleton(() => DeletePet(sl<PetRepository>()));

  // Pets — Cubit (singleton: compartido entre PetsPage y PetFormScreen)
  sl.registerLazySingleton(
    () => PetCubit(
      getMyPets: sl<GetMyPets>(),
      createPet: sl<CreatePet>(),
      updatePet: sl<UpdatePet>(),
      deletePet: sl<DeletePet>(),
      repository: sl<PetRepository>(),
    ),
  );

  // Reports — Data
  sl.registerLazySingleton<ReportProvider>(
    () => ReportProvider(supabase: sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl<ReportProvider>()),
  );

  // Reports — Use Cases
  sl.registerLazySingleton(() => CreateLostReport(sl<ReportRepository>()));
  sl.registerLazySingleton(() => GetRecentReports(sl<ReportRepository>()));

  // Reports — Cubit (local al formulario de reporte)
  sl.registerFactory(
    () => ReportFormCubit(
      getMyPets: sl<GetMyPets>(),
      createLostReport: sl<CreateLostReport>(),
    ),
  );
}

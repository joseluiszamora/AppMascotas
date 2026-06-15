import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/service_locator.dart';
import 'features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'features/auth/presentation/blocs/auth/auth_event.dart';
import 'features/auth/presentation/blocs/auth/auth_state.dart';
import 'features/pets/presentation/blocs/pet_cubit.dart';
import 'features/profile/presentation/blocs/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  AppConstants.validateEnvironment();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await setupServiceLocator();

  runApp(const AppMascotas());
}

class AppMascotas extends StatelessWidget {
  const AppMascotas({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthStarted()),
        ),
        BlocProvider<ProfileCubit>(create: (_) => sl<ProfileCubit>()),
        BlocProvider<PetCubit>(create: (_) => sl<PetCubit>()),
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.routerOf(context);
          return BlocListener<AuthBloc, AuthState>(
            listenWhen: (_, current) =>
                current is AuthAuthenticated || current is AuthUnauthenticated,
            listener: (context, state) {
              context.read<ThemeCubit>().loadPreferenceForCurrentUser();
            },
            child: BlocBuilder<ThemeCubit, AppThemePreference>(
              builder: (context, themePreference) => MaterialApp.router(
                title: AppConstants.appName,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themePreference.themeMode,
                routerConfig: router,
                debugShowCheckedModeBanner: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

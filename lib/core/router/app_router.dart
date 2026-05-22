import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../utils/service_locator.dart';
import '../../features/auth/presentation/blocs/auth/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth/auth_state.dart';
import '../../features/notifications/presentation/blocs/notification_cubit.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/map/presentation/pages/home_page.dart';
import '../../features/pets/domain/entities/pet_entity.dart';
import '../../features/pets/presentation/screens/pet_form_screen.dart';
import '../../features/profile/domain/entities/profile_entity.dart';
import '../../features/profile/presentation/blocs/profile_cubit.dart';
import '../../features/profile/presentation/blocs/profile_state.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/reports/presentation/blocs/report_form/report_form_cubit.dart';
import '../../features/reports/presentation/screens/found_report_form_screen.dart';
import '../../features/reports/presentation/screens/lost_report_form_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const profileSetup = '/profile-setup';
  static const profileEdit = '/profile-edit';
  static const petForm = '/pets/form';
  static const lostReportForm = '/reports/lost/form';
  static const foundReportForm = '/reports/found/form';
  static const notifications = '/notifications';

  static String reportDetail(String reportId) => '/reports/$reportId';
}

class AppRouter {
  AppRouter._();

  static GoRouter routerOf(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final profileCubit = context.read<ProfileCubit>();

    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: _RouterNotifier(authBloc, profileCubit),
      redirect: (ctx, state) {
        final authState = authBloc.state;
        final profileState = profileCubit.state;

        final isLoggedIn = authState is AuthAuthenticated;
        final isInitialAuth =
            authState is AuthInitial || authState is AuthLoading;
        final loc = state.matchedLocation;
        final isOnLogin = loc == AppRoutes.login;
        final isOnSetup = loc == AppRoutes.profileSetup;
        final isOnEdit = loc == AppRoutes.profileEdit;

        // Esperando que se resuelva el estado de autenticación
        if (isInitialAuth) return null;

        // No autenticado → login
        if (!isLoggedIn && !isOnLogin) return AppRoutes.login;

        // Autenticado en la pantalla de login → home (el check de perfil ocurrirá desde ahí)
        if (isLoggedIn && isOnLogin) return AppRoutes.home;

        // La pantalla de edición de perfil es siempre accesible
        if (isOnEdit) return null;

        // ── Verificación de completitud del perfil ──
        if (isLoggedIn && !isOnSetup) {
          // Perfil aún no cargado: esperar
          if (profileState is ProfileInitial ||
              profileState is ProfileLoading) {
            return null;
          }
          // Perfil cargado e incompleto → pantalla de setup
          if (profileState is ProfileLoaded &&
              !profileState.profile.isComplete) {
            return AppRoutes.profileSetup;
          }
        }

        // Si ya completó el perfil y sigue en setup → home
        if (isOnSetup) {
          final isComplete = switch (profileState) {
            ProfileLoaded(:final profile) => profile.isComplete,
            ProfileUpdateSuccess(:final profile) => profile.isComplete,
            _ => false,
          };
          if (isComplete) return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, _) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, _) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          // El ProfileCubit global ya tiene el perfil cargado
          builder: (context, _) => const ProfileSetupPage(),
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          builder: (context, state) {
            final profile =
                (state.extra as ProfileEntity?) ??
                switch (profileCubit.state) {
                  ProfileLoaded(:final profile) => profile,
                  ProfileUpdating(:final profile) => profile,
                  ProfileUpdateSuccess(:final profile) => profile,
                  _ => null,
                };

            if (profile == null) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return EditProfilePage(profile: profile);
          },
        ),
        GoRoute(
          path: AppRoutes.petForm,
          builder: (context, state) {
            final pet = state.extra as PetEntity?;
            return PetFormScreen(pet: pet);
          },
        ),
        GoRoute(
          path: AppRoutes.lostReportForm,
          builder: (context, state) {
            final initialPetId = state.extra as String?;
            return BlocProvider<ReportFormCubit>(
              create: (_) => sl<ReportFormCubit>(),
              child: LostReportFormScreen(initialPetId: initialPetId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.foundReportForm,
          builder: (context, state) => BlocProvider<ReportFormCubit>(
            create: (_) => sl<ReportFormCubit>(),
            child: const FoundReportFormScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => BlocProvider<NotificationCubit>(
            create: (_) => sl<NotificationCubit>(),
            child: const NotificationsPage(),
          ),
        ),
        GoRoute(
          path: '/reports/:reportId',
          builder: (context, state) =>
              ReportDetailScreen(reportId: state.pathParameters['reportId']!),
        ),
      ],
    );
  }
}

/// Escucha [AuthBloc] y [ProfileCubit] para refrescar el router.
/// Cuando el usuario se autentica, dispara la carga del perfil.
/// Cuando cierra sesión, reinicia el estado del perfil.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(AuthBloc authBloc, ProfileCubit profileCubit) {
    _authSub = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        profileCubit.loadProfile(authState.user.id);
      } else if (authState is AuthUnauthenticated) {
        profileCubit.resetProfile();
      }
      notifyListeners();
    });
    _profileSub = profileCubit.stream.listen((_) => notifyListeners());
  }

  late final dynamic _authSub;
  late final dynamic _profileSub;

  @override
  void dispose() {
    _authSub.cancel();
    _profileSub.cancel();
    super.dispose();
  }
}

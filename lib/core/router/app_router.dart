import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/blocs/auth/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/map/presentation/pages/home_page.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/';
}

class AppRouter {
  AppRouter._();

  static GoRouter routerOf(BuildContext context) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: _AuthNotifier(context.read<AuthBloc>()),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isLoggedIn = authState is AuthAuthenticated;
        final isInitial = authState is AuthInitial || authState is AuthLoading;
        final isOnLogin = state.matchedLocation == AppRoutes.login;

        if (isInitial) return null;
        if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
        if (isLoggedIn && isOnLogin) return AppRoutes.home;
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
      ],
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

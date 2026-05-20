import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // TODO: agregar rutas por feature (auth, pets, reports, map)
    ],
  );
}

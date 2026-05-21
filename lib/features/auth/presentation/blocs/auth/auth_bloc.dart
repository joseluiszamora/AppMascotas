import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/exceptions/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/sign_in_with_google.dart';
import '../../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;

  StreamSubscription<dynamic>? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
  }) : _authRepository = authRepository,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      emit(AuthAuthenticated(currentUser));
    } else {
      emit(const AuthUnauthenticated());
    }

    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user?.id)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.userId != null) {
      final user = _authRepository.currentUser;
      if (user != null) emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_mapErrorMessage(e)));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_mapErrorMessage(e)));
    }
  }

  String _mapErrorMessage(Object e) {
    if (e is AuthFailure) return e.message;

    final message = e.toString().toLowerCase();
    if (message.contains('cancelado') || message.contains('cancelled')) {
      return 'Inicio de sesión cancelado.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'Ocurrió un error. Por favor intenta de nuevo.';
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

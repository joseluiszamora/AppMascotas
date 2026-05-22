import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/auth_failure.dart';
import '../models/user_model.dart';

class AuthProvider {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthProvider({
    required SupabaseClient supabase,
    required GoogleSignIn googleSignIn,
  }) : _supabase = supabase,
       _googleSignIn = googleSignIn;

  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? UserModel.fromSupabaseUser(user) : null;
    });
  }

  UserModel? get currentUser {
    final user = _supabase.auth.currentUser;
    return user != null ? UserModel.fromSupabaseUser(user) : null;
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthFailure('Inicio de sesión con Google cancelado.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthFailure(
          'No se pudo obtener el token de Google. Revisa el cliente OAuth web.',
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw const AuthFailure('No se pudo autenticar con Supabase.');
      }

      return UserModel.fromAuthData(
        user: response.user!,
        fallbackEmail: googleUser.email,
        fallbackName: googleUser.displayName,
        fallbackAvatarUrl: googleUser.photoUrl,
      );
    } on AuthFailure {
      rethrow;
    } on PlatformException catch (e) {
      throw AuthFailure(_mapGoogleError(e));
    } on AuthException catch (e) {
      throw AuthFailure(_mapSupabaseError(e));
    } catch (_) {
      throw const AuthFailure(
        'Ocurrió un error al iniciar sesión con Google. Intenta de nuevo.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } finally {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
    }
  }

  String _mapGoogleError(PlatformException e) {
    final details = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    if (e.code == GoogleSignIn.kSignInCanceledError) {
      return 'Inicio de sesión con Google cancelado.';
    }
    if (e.code == GoogleSignIn.kNetworkError) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    if (details.contains('10') || details.contains('developer_error')) {
      return 'Google Sign-In no está bien configurado. Revisa el SHA de Android en Firebase/Google Cloud.';
    }
    return 'No se pudo iniciar sesión con Google. Código: ${e.code}.';
  }

  String _mapSupabaseError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('provider') && message.contains('enabled')) {
      return 'Google no está habilitado en Supabase Auth.';
    }
    if (message.contains('audience') ||
        message.contains('invalid id token') ||
        message.contains('id token')) {
      return 'Supabase rechazó el token de Google. Revisa que use el mismo cliente OAuth web.';
    }
    return 'Supabase no pudo completar el inicio de sesión con Google.';
  }
}

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthProvider _provider;

  const AuthRepositoryImpl(this._provider);

  @override
  Stream<UserEntity?> get authStateChanges => _provider.authStateChanges;

  @override
  UserEntity? get currentUser => _provider.currentUser;

  @override
  Future<UserEntity> signInWithGoogle() => _provider.signInWithGoogle();

  @override
  Future<void> signOut() => _provider.signOut();
}

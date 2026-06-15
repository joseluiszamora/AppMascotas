import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  Future<void> call() => _repository.signOut();
}

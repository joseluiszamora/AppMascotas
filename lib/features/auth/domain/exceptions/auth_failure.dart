class AuthFailure implements Exception {
  final String message;

  AuthFailure(this.message);

  @override
  String toString() => message;
}

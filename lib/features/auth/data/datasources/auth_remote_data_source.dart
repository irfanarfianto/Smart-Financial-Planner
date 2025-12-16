abstract class AuthRemoteDataSource {
  Future<void> loginWithEmail(String email, String password);
  Future<void> registerWithEmail(
    String email,
    String password,
    String fullName,
  );
  Future<void> logout();
  Future<bool> hasActiveModel(String userId);
  String? getCurrentUserId();
}

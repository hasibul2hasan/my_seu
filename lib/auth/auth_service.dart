class AuthService {
  // Firebase removed: return null for current user.
  dynamic getCurrentUser() {
    return null;
  }

  // Stubbed Google sign-in method without Firebase linkage.
  Future<void> signInWithGoogle() async {
    // No-op: Firebase removed from project.
  }
}

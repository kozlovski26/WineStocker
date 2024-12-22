class AuthException implements Exception {
  final String message;
  final String code;

  AuthException({
    required this.message,
    required this.code,
  });

  factory AuthException.fromCode(String code) {
    switch (code) {
      // Sign In Errors
      case 'user-not-found':
        return AuthException(
          code: code,
          message: 'No user found with this email.',
        );
      case 'wrong-password':
        return AuthException(
          code: code,
          message: 'Wrong password provided.',
        );
      case 'user-disabled':
        return AuthException(
          code: code,
          message: 'This account has been disabled.',
        );
      case 'too-many-requests':
        return AuthException(
          code: code,
          message: 'Too many attempts. Please try again later.',
        );

      // Sign Up Errors
      case 'email-already-in-use':
        return AuthException(
          code: code,
          message: 'An account already exists with this email.',
        );
      case 'invalid-email':
        return AuthException(
          code: code,
          message: 'Please enter a valid email address.',
        );
      case 'weak-password':
        return AuthException(
          code: code,
          message: 'The password provided is too weak.',
        );
      case 'operation-not-allowed':
        return AuthException(
          code: code,
          message: 'Email/password accounts are not enabled.',
        );

      // Password Reset Errors
      case 'expired-action-code':
        return AuthException(
          code: code,
          message: 'The password reset code has expired.',
        );
      case 'invalid-action-code':
        return AuthException(
          code: code,
          message: 'The password reset code is invalid.',
        );

      // Update Profile Errors
      case 'requires-recent-login':
        return AuthException(
          code: code,
          message: 'Please sign in again to complete this action.',
        );

      // Network Errors
      case 'network-request-failed':
        return AuthException(
          code: code,
          message: 'Network error. Please check your connection.',
        );

      // Default Error
      default:
        return AuthException(
          code: code,
          message: 'An error occurred. Please try again.',
        );
    }
  }

  @override
  String toString() => message;
}
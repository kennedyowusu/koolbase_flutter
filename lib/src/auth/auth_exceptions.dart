class KoolbaseAuthException implements Exception {
  final String message;
  final String? code;

  const KoolbaseAuthException(this.message, {this.code});

  @override
  String toString() => 'KoolbaseAuthException($code): $message';
}

class InvalidCredentialsException extends KoolbaseAuthException {
  const InvalidCredentialsException()
      : super('Invalid email or password', code: 'invalid_credentials');
}

class EmailAlreadyInUseException extends KoolbaseAuthException {
  const EmailAlreadyInUseException()
      : super('Email is already in use', code: 'email_taken');
}

class SessionExpiredException extends KoolbaseAuthException {
  const SessionExpiredException()
      : super('Session expired, please log in again', code: 'session_expired');
}

class UserDisabledException extends KoolbaseAuthException {
  const UserDisabledException()
      : super('This account has been disabled', code: 'user_disabled');
}

class WeakPasswordException extends KoolbaseAuthException {
  const WeakPasswordException()
      : super('Password must be at least 8 characters', code: 'weak_password');
}

class NetworkException extends KoolbaseAuthException {
  const NetworkException()
      : super('Network error, please check your connection', code: 'network_error');
}

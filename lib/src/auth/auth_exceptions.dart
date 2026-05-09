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

class InvalidPhoneNumberException extends KoolbaseAuthException {
  const InvalidPhoneNumberException()
      : super('Phone number must be in E.164 format (e.g. +233XXXXXXXXX)',
            code: 'invalid_phone');
}

class OtpExpiredException extends KoolbaseAuthException {
  const OtpExpiredException()
      : super('OTP has expired, please request a new code',
            code: 'otp_expired');
}

class OtpInvalidException extends KoolbaseAuthException {
  const OtpInvalidException()
      : super('Invalid OTP code', code: 'otp_invalid');
}

class OtpMaxAttemptsException extends KoolbaseAuthException {
  const OtpMaxAttemptsException()
      : super('Too many incorrect attempts, please request a new code',
            code: 'otp_max_attempts');
}

class OtpRateLimitException extends KoolbaseAuthException {
  const OtpRateLimitException()
      : super('Too many OTP requests, please wait before trying again',
            code: 'otp_rate_limit');
}

class PhoneAlreadyLinkedException extends KoolbaseAuthException {
  const PhoneAlreadyLinkedException()
      : super('Phone number is already associated with another account',
            code: 'phone_taken');
}

class SmsConfigMissingException extends KoolbaseAuthException {
  const SmsConfigMissingException()
      : super('SMS provider not configured for this project',
            code: 'sms_config_missing');
}

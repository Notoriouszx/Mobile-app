class AppConstants {
  static const String baseUrl = 'https://project-9g6if.vercel.app';

  // ─── Better Auth Endpoints ───────────────────────────────────────
  // Better Auth handles all auth routes through /api/auth/[...all]
  // These are the standard Better Auth endpoints
  static const String signInEndpoint = '/api/auth/sign-in/email';
  static const String signUpEndpoint = '/api/auth/sign-up';
  static const String signOutEndpoint = '/api/auth/sign-out';
  static const String sessionEndpoint = '/api/auth/get-session';
  static const String verifyEmailEndpoint = '/api/auth/verify-email';

  // ─── Patient API Endpoints ───────────────────────────────────────
  static const String recordsEndpoint = '/api/patient/medical-records';
  static const String uploadRecordEndpoint = '/api/patient/medical-records/upload';
  static const String appointmentsEndpoint = '/api/patient/appointments';
  static const String createAppointmentEndpoint = '/api/patient/appointments/request';
  static const String availableProvidersEndpoint = '/api/patient/available-providers';

  // ─── Access Grants & Doctors ─────────────────────────────────────
  static const String grantsEndpoint = '/api/patient/access-grants';
  static const String doctorsEndpoint = '/api/patient/doctors';

  // ─── User & Session ─────────────────────────────────────────────
  static const String userProfileEndpoint = '/api/user/profile';
}

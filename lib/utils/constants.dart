class AppConstants {
  static const String baseUrl = 'https://project-9g6if.vercel.app';

  // ─── Better Auth Endpoints (API) ─────────────────────────────────
  static const String signInEndpoint = '/api/auth/sign-in/email';
  static const String signUpEndpoint = '/api/auth/sign-up';
  static const String signOutEndpoint = '/api/auth/sign-out';
  static const String sessionEndpoint = '/api/auth/get-session';

  // ─── Medical Records API ─────────────────────────────────────────
  static const String medicalRecordsEndpoint = '/api/medical-records';

  // ─── Access Grants API (Appointments) ────────────────────────────
  static const String accessGrantsEndpoint = '/api/access-grants';

  // ─── Patient Providers API (Available Doctors/Nurses) ────────────
  static const String availableProvidersEndpoint = '/api/patient/available-providers';
}

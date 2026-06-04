class AppConstants {
  static const String baseUrl = 'https://project-9g6if.vercel.app';

  // ─── Better Auth Endpoints ────────────────────────────────────────
  static const String signInEndpoint = '/api/auth/sign-in/email';
  static const String signUpEndpoint = '/api/auth/sign-up/email';
  static const String signOutEndpoint = '/api/auth/sign-out';
  static const String sessionEndpoint = '/api/auth/get-session';

  // ─── Medical Records ──────────────────────────────────────────────
  // Used as: AppConstants.medicalRecordsEndpoint  (in records_screen / records_service)
  static const String blobReadWriteToken = 'vercel_blob_rw_wXSi5ePSeFgreV59_dGypR5AWuIQmDnaug8cJ2OvzLyORae'; // your actual token
  static const String medicalRecordsEndpoint = '/api/medical-records';
  static const String recordsEndpoint = medicalRecordsEndpoint; // alias used by RecordsService

  // ─── Access Grants (Appointments) ────────────────────────────────
  // Used as: AppConstants.accessGrantsEndpoint  AND  AppConstants.grantsEndpoint
  static const String accessGrantsEndpoint = '/api/access-grants';
  static const String grantsEndpoint = accessGrantsEndpoint; // alias used by GrantsService

  // ─── Doctors / Available Providers ───────────────────────────────
  // Used as: AppConstants.availableProvidersEndpoint  AND  AppConstants.doctorsEndpoint
  static const String availableProvidersEndpoint = '/api/patient/available-providers';
  static const String doctorsEndpoint = availableProvidersEndpoint; // alias used by GrantsService
}

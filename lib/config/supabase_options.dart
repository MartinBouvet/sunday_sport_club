/// Configuration des options Supabase pour l'application
class SupabaseOptions {
  // Valeurs par défaut pour le développement local
  static const String supabaseUrl = 'https://ekxqwrhultufzhtoxyzk.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVreHF3cmh1bHR1ZnpodG94eXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDIxNzAsImV4cCI6MjA1ODQ3ODE3MH0.4Mmo4gaR_vbRCkbEBadUL0NdX0teX01rGavQAymp8Kg';

  // Tables de la base de données
  static const String profilesTable = 'profiles';
  static const String membershipCardsTable = 'membership_cards';
  static const String coursesTable = 'courses';
  static const String bookingsTable = 'bookings';
  static const String exercisesTable = 'exercises';
  static const String routinesTable = 'routines';
  static const String userRoutinesTable = 'user_routines';
  static const String dailyChallengesTable = 'daily_challenges';
  static const String userChallengesTable = 'user_challenges';
  static const String progressTrackingTable = 'progress_tracking';
  static const String paymentsTable = 'payments';
}

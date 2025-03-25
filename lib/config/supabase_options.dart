import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration des options Supabase pour l'application
class SupabaseOptions {
  // Valeurs par défaut pour le développement local, remplacées par les variables d'environnement en production
  static final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://ekxqwrhultufzhtoxyzk.supabase.co';
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVreHF3cmh1bHR1ZnpodG94eXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDIxNzAsImV4cCI6MjA1ODQ3ODE3MH0.4Mmo4gaR_vbRCkbEBadUL0NdX0teX01rGavQAymp8Kg';
  
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
  
  // Buckets de stockage
  static const String avatarsBucket = 'avatars';
  static const String exerciseMediaBucket = 'exercise_media';
  static const String receiptsBucket = 'receipts';
  
  // Fonctions RPC (procédures stockées)
  static const String rpcAddExperience = 'add_user_experience';
  static const String rpcDecrementCardSessions = 'decrement_card_sessions';
  static const String rpcIncrementCourseParticipants = 'increment_course_participants';
  static const String rpcDecrementCourseParticipants = 'decrement_course_participants';
  
  // Timeout pour les requêtes (en millisecondes)
  static const int defaultRequestTimeout = 10000; // 10 secondes
  static const int uploadTimeout = 30000; // 30 secondes
  
  // Limites
  static const int maxFileUploadSize = 5 * 1024 * 1024; // 5 MB
}
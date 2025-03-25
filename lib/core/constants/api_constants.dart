/// Classe contenant les constantes liées aux API et endpoints
/// utilisés par l'application Sunday Sport Club.
///
/// Cette classe centralise toutes les URLs, endpoints, et paramètres
/// pour faciliter la maintenance et éviter les chaînes codées en dur.
class APIConstants {
  // Constructeur privé pour empêcher l'instanciation
  APIConstants._();

  // Configuration de base de l'API
  static const int apiVersion = 1;
  static const String apiPrefix = '/api/v$apiVersion';
  
  // Timeout pour les requêtes API (en millisecondes)
  static const int defaultTimeout = 20000; // 20 secondes
  static const int uploadTimeout = 60000;  // 60 secondes pour les uploads
  static const int longPollTimeout = 30000; // 30 secondes pour le long polling
  
  // Format de réponse par défaut
  static const String defaultResponseFormat = 'json';
  
  // Taille maximale des uploads (en octets)
  static const int maxUploadSize = 10 * 1024 * 1024; // 10 MB
  
  // Types MIME acceptés pour les uploads
  static const List<String> acceptedImageTypes = [
    'image/jpeg', 
    'image/png', 
    'image/gif'
  ];
  
  // Pagination par défaut
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Noms des tables Supabase (pour RLS et requêtes directes)
  static const String usersTable = 'users';
  static const String coursesTable = 'courses';
  static const String bookingsTable = 'bookings';
  static const String membershipCardsTable = 'membership_cards';
  static const String routinesTable = 'routines';
  static const String challengesTable = 'daily_challenges';
  static const String userChallengesTable = 'user_challenges';
  static const String progressTrackingTable = 'progress_tracking';
  static const String paymentsTable = 'payments';
  
  // Noms des buckets de stockage Supabase
  static const String avatarsBucket = 'avatars';
  static const String challengeImagesBucket = 'challenge_images';
  static const String exerciseMediaBucket = 'exercise_media';
  static const String profilePhotosBucket = 'profile_photos';
  
  // Endpoints d'authentification
  static const String authEndpoint = '/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String signupEndpoint = '$authEndpoint/signup';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String refreshTokenEndpoint = '$authEndpoint/refresh';
  static const String forgotPasswordEndpoint = '$authEndpoint/forgot-password';
  static const String resetPasswordEndpoint = '$authEndpoint/reset-password';
  
  // Endpoints des utilisateurs
  static const String usersEndpoint = '/users';
  static const String userProfileEndpoint = '$usersEndpoint/profile';
  static const String userStatsEndpoint = '$usersEndpoint/stats';
  static const String userProgressEndpoint = '$usersEndpoint/progress';
  static const String userAvatarEndpoint = '$usersEndpoint/avatar';
  
  // Endpoints des cours
  static const String coursesEndpoint = '/courses';
  static const String courseDetailEndpoint = '$coursesEndpoint/{id}';
  static const String bookCourseEndpoint = '$coursesEndpoint/{id}/book';
  static const String cancelBookingEndpoint = '$coursesEndpoint/bookings/{id}/cancel';
  
  // Endpoints des carnets d'abonnement
  static const String membershipEndpoint = '/membership';
  static const String purchaseMembershipEndpoint = '$membershipEndpoint/purchase';
  static const String membershipHistoryEndpoint = '$membershipEndpoint/history';
  
  // Endpoints des routines
  static const String routinesEndpoint = '/routines';
  static const String routineDetailEndpoint = '$routinesEndpoint/{id}';
  static const String userRoutinesEndpoint = '/user-routines';
  static const String validateRoutineEndpoint = '$userRoutinesEndpoint/{id}/validate';
  static const String completeRoutineEndpoint = '$userRoutinesEndpoint/{id}/complete';
  
  // Endpoints des défis
  static const String challengesEndpoint = '/challenges';
  static const String dailyChallengeEndpoint = '$challengesEndpoint/daily';
  static const String completeChallengeEndpoint = '$challengesEndpoint/{id}/complete';
  static const String userChallengesEndpoint = '/user-challenges';
  
  // Endpoints de paiement
  static const String paymentsEndpoint = '/payments';
  static const String createPaymentIntentEndpoint = '$paymentsEndpoint/create-intent';
  static const String paymentMethodsEndpoint = '$paymentsEndpoint/methods';
  static const String paymentHistoryEndpoint = '$paymentsEndpoint/history';
  
  // Endpoints admin
  static const String adminEndpoint = '/admin';
  static const String adminUsersEndpoint = '$adminEndpoint/users';
  static const String adminCoursesEndpoint = '$adminEndpoint/courses';
  static const String adminMembershipEndpoint = '$adminEndpoint/membership';
  static const String adminPaymentsEndpoint = '$adminEndpoint/payments';
  static const String adminChallengesEndpoint = '$adminEndpoint/challenges';
  
  // Endpoints de notifications
  static const String notificationsEndpoint = '/notifications';
  static const String notificationSettingsEndpoint = '$notificationsEndpoint/settings';
  static const String markNotificationReadEndpoint = '$notificationsEndpoint/{id}/read';
  
  // Headers requis pour l'authentification
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String jsonContentType = 'application/json';
  static const String acceptHeader = 'Accept';
  
  // Paramètres de requête courants
  static const String pageParam = 'page';
  static const String pageSizeParam = 'pageSize';
  static const String sortByParam = 'sortBy';
  static const String orderParam = 'order';
  static const String searchParam = 'search';
  static const String filterParam = 'filter';
  static const String includeParam = 'include';
  static const String fromDateParam = 'fromDate';
  static const String toDateParam = 'toDate';
  
  // Valeurs pour les paramètres de tri
  static const String orderAsc = 'asc';
  static const String orderDesc = 'desc';
  
  // Codes de statut HTTP
  static const int statusOK = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusConflict = 409;
  static const int statusInternalError = 500;
  
  // Formats de date pour l'API
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
  
  // Constantes pour les fonctions RPC Supabase
  static const String rpcSearchUsers = 'search_users';
  static const String rpcGetUserRoutines = 'get_user_routines';
  static const String rpcGetUserStats = 'get_user_stats';
  static const String rpcGetAvailableSlots = 'get_available_slots';
  static const String rpcUpdateUserExperience = 'update_user_experience';
  
  // Endpoints pour les fonctionnalités de gamification
  static const String leaderboardEndpoint = '/leaderboard';
  static const String userLevelDataEndpoint = '/users/{id}/level-data';
  static const String badgesEndpoint = '/badges';
  static const String userBadgesEndpoint = '/users/{id}/badges';
  
  // Paramètres pour la génération d'URL d'avatar
  static String generateAvatarUrl({
    required String gender,
    required String skinColor,
    required String stage,
  }) {
    return '/assets/avatars/${gender}_${skinColor}_${stage}.png';
  }
  
  // Récupère l'URL complète pour un endpoint en remplaçant les paramètres
  /// Exemple: getEndpointUrl(courseDetailEndpoint, {'id': '123'}) => '/courses/123'
  static String getEndpointUrl(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
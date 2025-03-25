import 'package:intl/intl.dart';

/// Utilitaires pour la manipulation et le formatage des dates
/// 
/// Cette classe fournit des méthodes statiques pour simplifier le travail avec
/// les dates et heures dans toute l'application.
class DateUtils {
  // Constructeur privé pour empêcher l'instanciation
  DateUtils._();
  
  // Formats de date courants
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE', 'fr_FR');
  static final DateFormat _compactDateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  
  /// Formate une date en chaîne (jj/mm/aaaa)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  /// Formate une heure en chaîne (hh:mm)
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }
  
  /// Formate une date et heure en chaîne (jj/mm/aaaa hh:mm)
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  /// Formate une date en format court (jj/mm)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
  
  /// Formate une date au format "Mois Année" (Janvier 2023)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }
  
  /// Formate le jour de la semaine (Lundi, Mardi, etc.)
  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date).capitalize();
  }
  
  /// Formate une date en format compact (12 Jan 2023)
  static String formatCompactDate(DateTime date) {
    return _compactDateFormat.format(date);
  }
  
  /// Formate une date relative (Aujourd'hui, Hier, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final inputDate = DateTime(date.year, date.month, date.day);
    
    if (inputDate == today) {
      return 'Aujourd\'hui';
    } else if (inputDate == yesterday) {
      return 'Hier';
    } else if (inputDate == tomorrow) {
      return 'Demain';
    } else {
      return formatDate(date);
    }
  }
  
  /// Convertit une chaîne en date (format jj/mm/aaaa)
  static DateTime? parseDate(String dateStr) {
    try {
      return _dateFormat.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
  
  /// Convertit une chaîne en heure (format hh:mm)
  static DateTime? parseTime(String timeStr) {
    try {
      return _timeFormat.parse(timeStr);
    } catch (e) {
      return null;
    }
  }
  
  /// Vérifie si deux dates sont le même jour
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  /// Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }
  
  /// Vérifie si une date est dans le passé (avant aujourd'hui)
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }
  
  /// Vérifie si une date est dans le futur (après aujourd'hui)
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }
  
  /// Calcule l'âge en années à partir d'une date de naissance
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final birthdayThisYear = DateTime(today.year, birthDate.month, birthDate.day);
    
    if (birthdayThisYear.isAfter(today)) {
      age--;
    }
    
    return age;
  }
  
  /// Obtient le premier jour de la semaine contenant la date donnée
  static DateTime getFirstDayOfWeek(DateTime date) {
    // En France, la semaine commence le lundi (1) et se termine le dimanche (7)
    final day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }
  
  /// Obtient le dernier jour de la semaine contenant la date donnée
  static DateTime getLastDayOfWeek(DateTime date) {
    final firstDay = getFirstDayOfWeek(date);
    return firstDay.add(const Duration(days: 6));
  }
  
  /// Obtient le premier jour du mois contenant la date donnée
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Obtient le dernier jour du mois contenant la date donnée
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// Formate une durée en texte lisible (2h 30m, 45m, etc.)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }
  
  /// Formate une durée longue en texte descriptif
  static String formatLongDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    final List<String> parts = [];
    
    if (days > 0) {
      parts.add('$days jour${days > 1 ? 's' : ''}');
    }
    
    if (hours > 0) {
      parts.add('$hours heure${hours > 1 ? 's' : ''}');
    }
    
    if (minutes > 0) {
      parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
    }
    
    return parts.join(' et ');
  }
  
  /// Obtient les jours dans un intervalle de dates (inclus)
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      days.add(start.add(Duration(days: i)));
    }
    
    return days;
  }
  
  /// Calcule la différence entre deux dates en texte lisible
  static String getTimeDifference(DateTime date1, DateTime date2) {
    final difference = date1.difference(date2).abs();
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }
}

/// Extension sur String pour capitaliser
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
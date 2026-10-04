/// Utility for formatting relative time strings (e.g. "5 mins ago", "2 hours ago", "Just now").
class TimeUtils {
  const TimeUtils._();

  /// Formats a [DateTime] into a friendly relative time string compared to [clock] (defaults to `DateTime.now()`).
  static String formatRelativeTime(DateTime dateTime, {DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  /// Formats a [DateTime] into a friendly time-of-day string (e.g. "08:15 AM").
  static String formatTimeString(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour.toString().padLeft(2, '0');
    return '$formattedHour:$minute $period';
  }

  /// Formats a [DateTime] into a user-facing date string (e.g. "Today, Sep 30, 2026").
  static String formatDateString(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[dateTime.month - 1];
    final prefix = isToday ? 'Today, ' : '';
    return '$prefix$monthName ${dateTime.day}, ${dateTime.year}';
  }

  /// Parses a time-of-day string (e.g. "08:15 AM", "14:30") relative to [baseDate].
  static DateTime parseTimeStringToDateTime(String timeStr, DateTime baseDate) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPm = trimmed.contains('PM');
      final isAm = trimmed.contains('AM');

      final cleanTime = trimmed
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      final parts = cleanTime.split(':');
      if (parts.length < 2) return baseDate;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return baseDate;
    }
  }

  /// Calculates delay string between scheduled and actual arrival time (e.g. "Running 3 min late", "On time").
  static String formatDelayStatus(DateTime scheduled, DateTime? actual) {
    if (actual == null) return 'Scheduled';
    final diffMins = actual.difference(scheduled).inMinutes;
    if (diffMins > 1) {
      return 'Running $diffMins min late';
    } else if (diffMins < -1) {
      return 'Running ${diffMins.abs()} min early';
    }
    return 'On time';
  }
}

/// Utility class for formatting time-related values
class TimeFormatter {
  /// Format duration in seconds to a human-readable string
  /// Examples:
  /// - 3661 seconds -> "1h 1m 1s"
  /// - 3600 seconds -> "1h"
  /// - 60 seconds -> "1m"
  /// - -90 seconds -> "-1m 30s"
  static String formatSeconds(int seconds) {
    final isNegative = seconds < 0;
    final absSeconds = seconds.abs();
    
    final h = absSeconds ~/ 3600;
    final m = (absSeconds % 3600) ~/ 60;
    final s = absSeconds % 60;
    
    final sign = isNegative ? '-' : '';
    
    if (h == 0) {
      if (s == 0) {
        return '$sign${m}m';
      }
      return '$sign${m}m ${s}s';
    }
    if (m == 0) {
      if (s == 0) {
        return '$sign${h}h';
      }
      return '$sign${h}h ${s}s';
    }
    if (s == 0) {
      return '$sign${h}h ${m}m';
    }
    return '$sign${h}h ${m}m ${s}s';
  }

  /// Format hours (as double) to a human-readable string
  /// Examples:
  /// - 1.5 hours -> "1h 30m"
  /// - 2.0 hours -> "2h"
  /// - 0.25 hours -> "0h 15m"
  /// - -1.5 hours -> "-1h 30m"
  static String formatHours(double hours) {
    final isNegative = hours < 0;
    final absHours = hours.abs();
    
    final h = absHours.truncate();
    final m = ((absHours - h) * 60).round();
    
    final sign = isNegative ? '-' : '';
    
    if (m == 0) {
      return '$sign${h}h';
    }
    return '$sign${h}h ${m}m';
  }
}
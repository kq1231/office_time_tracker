/// Utility class for formatting time-related values
class TimeFormatter {
  /// Format duration in seconds to a human-readable string
  /// Examples:
  /// - 3661 seconds -> "1h 1m 1s"
  /// - 3600 seconds -> "1h"
  /// - 60 seconds -> "1m"
  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h == 0) {
      return '${m}m';
    }
    if (m == 0) {
      return '${h}h';
    }
    if (s == 0) {
      return '${h}h ${m}m';
    }
    return '${h}h ${m}m ${s}s';
  }

  /// Format hours (as double) to a human-readable string
  /// Examples:
  /// - 1.5 hours -> "1h 30m"
  /// - 2.0 hours -> "2h"
  /// - 0.25 hours -> "0h 15m"
  static String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }
}

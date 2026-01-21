import 'package:flutter/foundation.dart';

/// App logger for logging messages with colored output
class AppLogger {
  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';

  // Bold variants
  static const String _boldRed = '\x1B[1;31m';
  static const String _boldYellow = '\x1B[1;33m';
  static const String _boldBlue = '\x1B[1;34m';
  static const String _boldGreen = '\x1B[1;32m';

  /// Log an error message (red)
  static void error(String message) {
    if (kDebugMode) {
      print('$_boldRed❌ Error: $message$_reset');
    }
  }

  /// Log a warning message (yellow)
  static void warning(String message) {
    if (kDebugMode) {
      print('$_boldYellow⚠️  Warning: $message$_reset');
    }
  }

  /// Log an info message (blue)
  static void info(String message) {
    if (kDebugMode) {
      print('$_boldBlue ℹ️  Info: $message$_reset');
    }
  }

  /// Log a success message (green)
  static void success(String message) {
    if (kDebugMode) {
      print('$_boldGreen✅ Success: $message$_reset');
    }
  }

  /// Log a debug message (cyan)
  static void debug(String message) {
    if (kDebugMode) {
      print('$_cyan🔍 Debug: $message$_reset');
    }
  }
}

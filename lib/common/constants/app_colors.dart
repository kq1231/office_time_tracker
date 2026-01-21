import 'package:flutter/material.dart';

/// App color constants that are theme-aware
class AppColors {
  AppColors._();

  // Status colors for light and dark mode
  static Color getSuccessColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;
  }

  static Color getSuccessBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.green.shade900.withOpacity(0.3)
        : Colors.green.shade50;
  }

  static Color getErrorColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade700;
  }

  static Color getErrorBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.red.shade900.withOpacity(0.3)
        : Colors.red.shade50;
  }

  static Color getInfoColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue.shade400
        : Colors.blue.shade700;
  }

  static Color getInfoBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue.shade900.withOpacity(0.3)
        : Colors.blue.shade50;
  }

  static Color getNeutralColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade700;
  }

  static Color getNeutralBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade800.withOpacity(0.3)
        : Colors.grey.shade50;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
  }

  static Color getProgressBarBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;
  }

  // Balance colors
  static Color getPositiveBalanceColor(BuildContext context) =>
      getSuccessColor(context);

  static Color getPositiveBalanceBackgroundColor(BuildContext context) =>
      getSuccessBackgroundColor(context);

  static Color getNegativeBalanceColor(BuildContext context) =>
      getErrorColor(context);

  static Color getNegativeBalanceBackgroundColor(BuildContext context) =>
      getErrorBackgroundColor(context);

  // Badge colors
  static Color getBadgePositiveColor(BuildContext context) =>
      getSuccessColor(context);

  static Color getBadgePositiveBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.green.shade800.withOpacity(0.5)
        : Colors.green.shade100;
  }

  static Color getBadgeNegativeColor(BuildContext context) =>
      getErrorColor(context);

  static Color getBadgeNegativeBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.red.shade800.withOpacity(0.5)
        : Colors.red.shade100;
  }
}

// NotifierProvider for the theme mode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  int _currentThemeModeIndex = 0;

  void toggleThemeMode() {
    // Switch between light, dark
    state = [ThemeMode.light, ThemeMode.dark][_currentThemeModeIndex];
    _currentThemeModeIndex = (_currentThemeModeIndex + 1) % 2;
  }
}

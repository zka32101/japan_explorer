import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────────
const _keyThemeMode = 'settings_theme_mode'; // 'system' | 'light' | 'dark'
const _keyNotifStreak = 'settings_notif_streak';
const _keyNotifChallenge = 'settings_notif_challenge';
const _keyNotifMeetup = 'settings_notif_meetup';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppSettings {
  final ThemeMode themeMode;
  final bool notifStreak;
  final bool notifChallenge;
  final bool notifMeetup;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notifStreak = true,
    this.notifChallenge = true,
    this.notifMeetup = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notifStreak,
    bool? notifChallenge,
    bool? notifMeetup,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        notifStreak: notifStreak ?? this.notifStreak,
        notifChallenge: notifChallenge ?? this.notifChallenge,
        notifMeetup: notifMeetup ?? this.notifMeetup,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString(_keyThemeMode) ?? 'system';
    final themeMode = _themeModeFromString(themeModeStr);

    state = AppSettings(
      themeMode: themeMode,
      notifStreak: prefs.getBool(_keyNotifStreak) ?? true,
      notifChallenge: prefs.getBool(_keyNotifChallenge) ?? true,
      notifMeetup: prefs.getBool(_keyNotifMeetup) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeModeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> toggleNotifStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !state.notifStreak;
    await prefs.setBool(_keyNotifStreak, newVal);
    state = state.copyWith(notifStreak: newVal);
  }

  Future<void> toggleNotifChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !state.notifChallenge;
    await prefs.setBool(_keyNotifChallenge, newVal);
    state = state.copyWith(notifChallenge: newVal);
  }

  Future<void> toggleNotifMeetup() async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !state.notifMeetup;
    await prefs.setBool(_keyNotifMeetup, newVal);
    state = state.copyWith(notifMeetup: newVal);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

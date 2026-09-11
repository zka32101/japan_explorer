import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingCompleted = 'onboarding_completed_v1';

// ─── Status flag ──────────────────────────────────────────────────────────────
/// Initialized from SharedPreferences before runApp via ProviderScope.overrides.
/// Flipped to true when the wizard completes — triggers GoRouter redirect.
final onboardingStatusProvider = StateProvider<bool>((ref) => false);

// ─── Wizard state ─────────────────────────────────────────────────────────────

class OnboardingState {
  final int step;
  final String language;
  final Set<String> interests;
  final String travelStyle;
  final String tripDuration;
  final bool isSaving;

  const OnboardingState({
    this.step = 0,
    this.language = 'en',
    this.interests = const {},
    this.travelStyle = '',
    this.tripDuration = '',
    this.isSaving = false,
  });

  bool get canProceedFromStep1 => interests.isNotEmpty;
  bool get canProceedFromStep2 => travelStyle.isNotEmpty;

  OnboardingState copyWith({
    int? step,
    String? language,
    Set<String>? interests,
    String? travelStyle,
    String? tripDuration,
    bool? isSaving,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        language: language ?? this.language,
        interests: interests ?? this.interests,
        travelStyle: travelStyle ?? this.travelStyle,
        tripDuration: tripDuration ?? this.tripDuration,
        isSaving: isSaving ?? this.isSaving,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState());

  void nextStep() {
    if (state.step < 4) state = state.copyWith(step: state.step + 1);
  }

  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void setLanguage(String code) => state = state.copyWith(language: code);

  void toggleInterest(String category) {
    final s = Set<String>.from(state.interests);
    s.contains(category) ? s.remove(category) : s.add(category);
    state = state.copyWith(interests: s);
  }

  void setTravelStyle(String style) =>
      state = state.copyWith(travelStyle: style);

  void setTripDuration(String dur) =>
      state = state.copyWith(tripDuration: dur);

  /// Saves interests to Firestore, marks onboarding done in SharedPreferences,
  /// and flips [onboardingStatusProvider] to trigger GoRouter redirect.
  Future<void> complete({
    required Future<void> Function(List<String> interests) savePreferences,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await savePreferences(state.interests.toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompleted, true);
      _ref.read(onboardingStatusProvider.notifier).state = true;
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  /// Read onboarding completion from SharedPreferences (called in main.dart).
  static Future<bool> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompleted) ?? false;
  }

  /// For testing / account-deletion reset flows.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboardingCompleted);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref),
);

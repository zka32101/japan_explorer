import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_itinerary.dart';
import '../services/ai_planner_service.dart';

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');

final aiPlannerServiceProvider = Provider<AiPlannerService>((ref) {
  return AiPlannerService(
    geminiKey: _geminiApiKey,
    claudeKey: _claudeApiKey,
  );
});

class PlannerState {
  final TripPreferences? preferences;
  final AiItinerary? itinerary;
  final bool isGenerating;
  final String? error;

  const PlannerState({
    this.preferences,
    this.itinerary,
    this.isGenerating = false,
    this.error,
  });

  PlannerState copyWith({
    TripPreferences? preferences,
    AiItinerary? itinerary,
    bool? isGenerating,
    String? error,
  }) =>
      PlannerState(
        preferences: preferences ?? this.preferences,
        itinerary: itinerary ?? this.itinerary,
        isGenerating: isGenerating ?? this.isGenerating,
        error: error,
      );

  PlannerState reset() => const PlannerState();
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final AiPlannerService _service;

  PlannerNotifier(this._service) : super(const PlannerState());

  Future<void> generate(TripPreferences prefs) async {
    state = state.copyWith(
      preferences: prefs,
      isGenerating: true,
      error: null,
      itinerary: null,
    );
    try {
      final itinerary = await _service.generateItinerary(prefs);
      state = state.copyWith(isGenerating: false, itinerary: itinerary);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate itinerary. Please try again.\n$e',
      );
    }
  }

  void reset() => state = const PlannerState();
}

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(ref.read(aiPlannerServiceProvider));
});

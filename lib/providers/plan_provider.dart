import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final userPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final user = ref.watch(appUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.read(firebaseServiceProvider).getUserPlans(user.uid);
});

class PlanNotifier extends StateNotifier<AsyncValue<List<Plan>>> {
  final FirebaseService _service;
  final String _userId;

  PlanNotifier(this._service, this._userId) : super(const AsyncValue.loading()) {
    if (_userId.isEmpty) {
      state = const AsyncValue.data([]);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final plans = await _service.getUserPlans(_userId);
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPlan(String title, {String? description}) async {
    final plan = Plan(
      id: '',
      userId: _userId,
      title: title,
      description: description,
      spots: [],
      isPublic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _service.createPlan(plan);
    await _load();
  }

  Future<void> deletePlan(String planId) async {
    await _service.deletePlan(planId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((p) => p.id != planId).toList());
  }

  Future<void> addSpotToPlan(String planId, PlanSpot spot) async {
    final plans = state.valueOrNull ?? [];
    final plan = plans.firstWhere((p) => p.id == planId);
    final updated = Plan(
      id: plan.id,
      userId: plan.userId,
      title: plan.title,
      description: plan.description,
      spots: [...plan.spots, spot.copyWith(order: plan.spots.length)],
      startDate: plan.startDate,
      endDate: plan.endDate,
      isPublic: plan.isPublic,
      createdAt: plan.createdAt,
      updatedAt: DateTime.now(),
    );
    await _service.updatePlan(updated);
    await _load();
  }

  Future<void> refresh() => _load();
}

final planNotifierProvider =
    StateNotifierProvider<PlanNotifier, AsyncValue<List<Plan>>>((ref) {
  final user = ref.watch(appUserProvider).valueOrNull;
  if (user == null) {
    return PlanNotifier(ref.read(firebaseServiceProvider), '');
  }
  return PlanNotifier(ref.read(firebaseServiceProvider), user.uid);
});

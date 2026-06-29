import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/purchase_service.dart';

// ── Free-tier usage limits ────────────────────────────────────────────────────

/// Max audio guides a free user may generate per calendar day
const kFreeAudioGuideDaily = 3;

/// Max AI itineraries a free user may generate per ISO week
const kFreeAiPlannerWeekly = 2;

const _kAudioGuideUsageKey = 'usage_audio_guide_v1';
const _kAiPlannerUsageKey  = 'usage_ai_planner_v1';

// ── Premium status providers ──────────────────────────────────────────────────

/// Live CustomerInfo stream — emits on every entitlement change.
final customerInfoStreamProvider = StreamProvider<CustomerInfo?>((ref) {
  return purchaseService.customerInfoStream.handleError((_) => null);
});

/// Reactive premium flag — rebuilds widgets instantly when subscription changes.
final isPremiumProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoStreamProvider).valueOrNull;
  if (info == null) return false;
  return purchaseService.isPremium(info);
});

/// One-shot check (e.g. on first load before the stream emits).
final premiumCheckProvider = FutureProvider<bool>((ref) async {
  try {
    final info = await purchaseService.getCustomerInfo();
    return purchaseService.isPremium(info);
  } catch (_) {
    return false;
  }
});

/// Available RevenueCat packages (monthly / annual / …).
final packagesProvider = FutureProvider<List<Package>>((ref) async {
  return purchaseService.getPackages();
});

// ── Paywall state ─────────────────────────────────────────────────────────────

enum PaywallStatus { idle, loading, success, error }

class PaywallState {
  final List<Package> packages;
  final String? selectedId;
  final PaywallStatus status;
  final String? error;

  const PaywallState({
    this.packages = const [],
    this.selectedId,
    this.status = PaywallStatus.idle,
    this.error,
  });

  bool get isLoading => status == PaywallStatus.loading;
  bool get isSuccess => status == PaywallStatus.success;

  Package? get selectedPackage =>
      packages.where((p) => p.identifier == selectedId).firstOrNull;

  PaywallState copyWith({
    List<Package>? packages,
    String? selectedId,
    PaywallStatus? status,
    String? error,
  }) =>
      PaywallState(
        packages: packages ?? this.packages,
        selectedId: selectedId ?? this.selectedId,
        status: status ?? this.status,
        error: error,                      // explicit null clears the error
      );
}

class PaywallNotifier extends StateNotifier<PaywallState> {
  PaywallNotifier() : super(const PaywallState()) {
    _load();
  }

  Future<void> _load() async {
    final pkgs = await purchaseService.getPackages();
    // Default to annual package for better conversion
    final annualId = pkgs
        .where((p) => p.packageType == PackageType.annual)
        .firstOrNull
        ?.identifier;
    state = state.copyWith(
      packages: pkgs,
      selectedId: annualId ?? pkgs.firstOrNull?.identifier,
    );
  }

  void selectPackage(String id) => state = state.copyWith(selectedId: id);

  /// Returns true if the purchase succeeded and the user is now premium.
  Future<bool> purchase() async {
    final pkg = state.selectedPackage;
    if (pkg == null) return false;

    state = state.copyWith(status: PaywallStatus.loading);
    try {
      final info = await purchaseService.purchase(pkg);
      if (info == null) {
        // User cancelled — no error message
        state = state.copyWith(status: PaywallStatus.idle);
        return false;
      }
      final nowPremium = purchaseService.isPremium(info);
      state = state.copyWith(
        status: nowPremium ? PaywallStatus.success : PaywallStatus.idle,
      );
      return nowPremium;
    } on PurchasesError catch (e) {
      state = state.copyWith(status: PaywallStatus.error, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          status: PaywallStatus.error, error: e.toString());
      return false;
    }
  }

  /// Restore previous purchases (required by store guidelines).
  Future<bool> restore() async {
    state = state.copyWith(status: PaywallStatus.loading);
    try {
      final info = await purchaseService.restorePurchases();
      final nowPremium = purchaseService.isPremium(info);
      state = state.copyWith(
        status: nowPremium ? PaywallStatus.success : PaywallStatus.idle,
        error: nowPremium ? null : 'No previous purchases found',
      );
      return nowPremium;
    } catch (e) {
      state = state.copyWith(
          status: PaywallStatus.error, error: e.toString());
      return false;
    }
  }
}

final paywallProvider =
    StateNotifierProvider.autoDispose<PaywallNotifier, PaywallState>(
  (ref) => PaywallNotifier(),
);

// ── Usage limit service ───────────────────────────────────────────────────────

class UsageLimitService {
  // ── Audio Guide ─────────────────────────────────────────────────────────────

  static Future<int> audioGuideUsesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAudioGuideUsageKey);
    if (raw == null) return 0;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['date'] != _dateKey(DateTime.now())) return 0;
      return (data['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> canUseAudioGuide({required bool isPremium}) async {
    if (isPremium) return true;
    return (await audioGuideUsesToday()) < kFreeAudioGuideDaily;
  }

  static Future<void> recordAudioGuideUse() async {
    final prefs = await SharedPreferences.getInstance();
    final used = await audioGuideUsesToday();
    await prefs.setString(
      _kAudioGuideUsageKey,
      jsonEncode({'date': _dateKey(DateTime.now()), 'count': used + 1}),
    );
  }

  // ── AI Planner ──────────────────────────────────────────────────────────────

  static Future<int> aiPlannerUsesThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAiPlannerUsageKey);
    if (raw == null) return 0;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['week'] != _weekKey(DateTime.now())) return 0;
      return (data['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> canUseAiPlanner({required bool isPremium}) async {
    if (isPremium) return true;
    return (await aiPlannerUsesThisWeek()) < kFreeAiPlannerWeekly;
  }

  static Future<void> recordAiPlannerUse() async {
    final prefs = await SharedPreferences.getInstance();
    final used = await aiPlannerUsesThisWeek();
    await prefs.setString(
      _kAiPlannerUsageKey,
      jsonEncode({'week': _weekKey(DateTime.now()), 'count': used + 1}),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _weekKey(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year)).inDays + 1;
    final week = ((dayOfYear - 1) / 7).floor() + 1;
    return '${d.year}-W${week.toString().padLeft(2, '0')}';
  }
}

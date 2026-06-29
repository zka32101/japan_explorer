import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/host_profile.dart';
import '../services/host_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final hostServiceProvider = Provider<HostService>((ref) => HostService());

// ── Host filter state ─────────────────────────────────────────────────────────

class HostFilter {
  final String? city;
  final String? interest;
  final String? language;

  const HostFilter({this.city, this.interest, this.language});

  HostFilter copyWith({
    String? city,
    String? interest,
    String? language,
    bool clearCity = false,
    bool clearInterest = false,
    bool clearLanguage = false,
  }) =>
      HostFilter(
        city: clearCity ? null : city ?? this.city,
        interest:
            clearInterest ? null : interest ?? this.interest,
        language:
            clearLanguage ? null : language ?? this.language,
      );
}

final hostFilterProvider =
    StateProvider<HostFilter>((ref) => const HostFilter());

// ── Host list ─────────────────────────────────────────────────────────────────

final hostsProvider = FutureProvider.autoDispose
    .family<List<HostProfile>, HostFilter>((ref, filter) async {
  final service = ref.read(hostServiceProvider);
  return service.getHosts(
    city: filter.city,
    interest: filter.interest,
    language: filter.language,
  );
});

// ── Single host ───────────────────────────────────────────────────────────────

final hostDetailProvider = FutureProvider.family<HostProfile?, String>(
  (ref, uid) => ref.read(hostServiceProvider).getHost(uid),
);

// ── Is registered host ─────────────────────────────────────────────────────────

final isRegisteredHostProvider =
    FutureProvider.family<bool, String>((ref, uid) async {
  return ref.read(hostServiceProvider).isRegisteredHost(uid);
});

// ── Registration notifier ─────────────────────────────────────────────────────

class HostRegistrationState {
  final bool isSaving;
  final bool success;
  final String? error;
  const HostRegistrationState(
      {this.isSaving = false, this.success = false, this.error});
}

class HostRegistrationNotifier
    extends StateNotifier<HostRegistrationState> {
  final HostService _service;
  final Ref _ref;

  HostRegistrationNotifier(this._service, this._ref)
      : super(const HostRegistrationState());

  Future<void> register(HostProfile profile) async {
    state = const HostRegistrationState(isSaving: true);
    try {
      await _service.registerHost(profile);
      state = const HostRegistrationState(success: true);
      // Invalidate the isRegistered provider so the UI updates
      _ref.invalidate(isRegisteredHostProvider(profile.uid));
    } catch (e) {
      state = HostRegistrationState(error: e.toString());
    }
  }

  Future<void> update(HostProfile profile) async {
    state = const HostRegistrationState(isSaving: true);
    try {
      await _service.updateHost(profile);
      state = const HostRegistrationState(success: true);
    } catch (e) {
      state = HostRegistrationState(error: e.toString());
    }
  }
}

final hostRegistrationProvider = StateNotifierProvider<
    HostRegistrationNotifier, HostRegistrationState>((ref) {
  return HostRegistrationNotifier(ref.read(hostServiceProvider), ref);
});

// ── My requests (as guest) ────────────────────────────────────────────────────

final myRequestsProvider =
    StreamProvider.family<List<HostRequest>, String>((ref, guestUid) {
  return ref.read(hostServiceProvider).streamMyRequests(guestUid);
});

// ── Incoming requests (as host) ───────────────────────────────────────────────

final incomingRequestsProvider =
    StreamProvider.family<List<HostRequest>, String>((ref, hostUid) {
  return ref.read(hostServiceProvider).streamIncomingRequests(hostUid);
});

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/curation.dart';
import '../services/firebase_service.dart';
import '../services/geofence_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

// ── Singleton plugin instance (shared with NotificationService) ──────────────
final _localNotifications = FlutterLocalNotificationsPlugin();

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return GeofenceService(_localNotifications);
});

// ── NearbySpotNotifier ────────────────────────────────────────────────────────

class NearbySpotNotifier extends StateNotifier<NearbySpotState> {
  final GeofenceService _service;
  final FirebaseService _firebase;
  StreamSubscription<NearbySpotState>? _sub;
  bool _started = false;

  NearbySpotNotifier(this._service, this._firebase)
      : super(const NearbySpotState());

  /// Call once after location permission is granted.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final hasPermission = await LocationService.requestPermission();
    if (!hasPermission) return;

    // Load first batch of curations for geofence targets
    try {
      final curations = await _firebase.getCurations(limit: 50);
      final targets =
          curations.map(GeofenceTarget.fromCuration).toList();

      final stream = _service.start(targets: targets);
      _sub = stream.listen((nearby) {
        if (nearby != state) state = nearby;
      });
    } catch (_) {
      // Location or Firestore unavailable — silently no-op
    }
  }

  /// Refresh target curations (call after category change or more curations loaded).
  Future<void> refreshTargets() async {
    try {
      final curations = await _firebase.getCurations(limit: 50);
      _service.updateTargets(
          curations.map(GeofenceTarget.fromCuration).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.stop();
    super.dispose();
  }
}

final nearbySpotProvider =
    StateNotifierProvider<NearbySpotNotifier, NearbySpotState>((ref) {
  final notifier = NearbySpotNotifier(
    ref.read(geofenceServiceProvider),
    ref.read(firebaseServiceProvider),
  );

  // Auto-start when user is logged in
  final authState = ref.watch(firebaseAuthStateProvider);
  authState.whenData((user) {
    if (user != null) notifier.start();
  });

  return notifier;
});

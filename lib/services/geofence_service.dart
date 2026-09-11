import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../models/curation.dart';

/// Lightweight target for geofence checking.
class GeofenceTarget {
  final String curationId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const GeofenceTarget({
    required this.curationId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
  });

  factory GeofenceTarget.fromCuration(Curation c) => GeofenceTarget(
        curationId: c.id,
        name: c.title,
        latitude: c.location.latitude,
        longitude: c.location.longitude,
      );
}

/// The nearest spot that is currently within radius, or null if none.
class NearbySpotState {
  final String? curationId;
  final String? spotName;
  final double? distanceMeters;

  const NearbySpotState({
    this.curationId,
    this.spotName,
    this.distanceMeters,
  });

  bool get isNearby => curationId != null;

  @override
  bool operator ==(Object other) =>
      other is NearbySpotState && other.curationId == curationId;

  @override
  int get hashCode => curationId.hashCode;
}

/// Streams the nearest known spot within geofence radius.
/// Uses a position stream at medium accuracy with a 50 m distance filter.
class GeofenceService {
  static const _notifChannelId = 'geofence';
  static const _notifChannelName = 'Nearby Spots';

  final FlutterLocalNotificationsPlugin _localNotifications;
  final _logger = Logger();

  StreamSubscription<Position>? _positionSub;
  StreamController<NearbySpotState>? _controller;
  List<GeofenceTarget> _targets = [];
  String? _lastNotifiedCurationId;

  GeofenceService(this._localNotifications);

  /// Start monitoring. Call [updateTargets] first (or pass targets here).
  Stream<NearbySpotState> start({List<GeofenceTarget> targets = const []}) {
    _targets = targets;
    _controller?.close();
    _controller = StreamController<NearbySpotState>.broadcast();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // only fire when moved 50m
    );

    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_onPosition, onError: _onError);

    return _controller!.stream;
  }

  void updateTargets(List<GeofenceTarget> targets) {
    _targets = targets;
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _controller?.close();
    _controller = null;
  }

  void _onPosition(Position position) {
    NearbySpotState nearest = const NearbySpotState();
    double? nearestDist;

    for (final target in _targets) {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        target.latitude,
        target.longitude,
      );

      if (dist <= target.radiusMeters) {
        if (nearestDist == null || dist < nearestDist) {
          nearestDist = dist;
          nearest = NearbySpotState(
            curationId: target.curationId,
            spotName: target.name,
            distanceMeters: dist,
          );
        }
      }
    }

    _controller?.add(nearest);

    // Fire a local notification once per new curation entry
    if (nearest.isNearby &&
        nearest.curationId != _lastNotifiedCurationId) {
      _lastNotifiedCurationId = nearest.curationId;
      _sendNotification(nearest.spotName!);
    } else if (!nearest.isNearby) {
      _lastNotifiedCurationId = null;
    }
  }

  void _onError(Object e) {
    _logger.w('Geofence position error: $e');
    _controller?.add(const NearbySpotState());
  }

  Future<void> _sendNotification(String spotName) async {
    try {
      await _localNotifications.show(
        spotName.hashCode,
        '📍 You\'re near $spotName',
        'Tap AI Lens to identify and learn about this spot!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notifChannelId,
            _notifChannelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      _logger.w('Geofence notification failed: $e');
    }
  }
}

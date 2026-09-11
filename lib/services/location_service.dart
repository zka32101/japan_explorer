import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class LocationService {
  static final _logger = Logger();

  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      _logger.w('Failed to get position: $e');
      return null;
    }
  }

  static double distanceInMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // ジオフェンス判定（Camera AI自動起動用 Week 13-16）
  static bool isWithinGeofence({
    required Position current,
    required double targetLat,
    required double targetLng,
    double radiusMeters = 200,
  }) {
    final dist = distanceInMeters(
      startLat: current.latitude,
      startLng: current.longitude,
      endLat: targetLat,
      endLng: targetLng,
    );
    return dist <= radiusMeters;
  }

  // Google Maps URL生成
  static String mapsNavigateUrl(double lat, double lng, String name) =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(name)}&travelmode=transit';

  static String mapsViewUrl(double lat, double lng) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

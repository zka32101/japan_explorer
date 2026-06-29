import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../models/curation.dart';
import '../models/rating.dart';

class SpotMapWidget extends StatefulWidget {
  final List<Curation> curations;
  final List<PlanSpot>? planSpots;
  final Function(Curation)? onMarkerTap;
  final double height;

  const SpotMapWidget({
    super.key,
    this.curations = const [],
    this.planSpots,
    this.onMarkerTap,
    this.height = 300,
  });

  @override
  State<SpotMapWidget> createState() => _SpotMapWidgetState();
}

class _SpotMapWidgetState extends State<SpotMapWidget> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const _japanCenter = CameraPosition(
    target: LatLng(36.2048, 138.2529),
    zoom: 5.5,
  );

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(SpotMapWidget old) {
    super.didUpdateWidget(old);
    if (old.curations != widget.curations ||
        old.planSpots != widget.planSpots) {
      _buildMarkers();
    }
  }

  void _buildMarkers() {
    _markers.clear();
    _polylines.clear();

    for (final c in widget.curations) {
      final pos = LatLng(c.location.latitude, c.location.longitude);
      _markers.add(Marker(
        markerId: MarkerId(c.id),
        position: pos,
        infoWindow: InfoWindow(
          title: c.title,
          snippet:
              '⭐ ${c.averageWantToGo.toStringAsFixed(1)} · ${c.prefecture}',
          onTap: () => widget.onMarkerTap?.call(c),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _categoryHue(c.category),
        ),
      ));
    }

    // プランルート（折れ線）
    if (widget.planSpots != null && widget.planSpots!.length >= 2) {
      // planSpotsにはlocation情報が別途必要のため、curationsから検索
      final ordered = widget.planSpots!
        ..sort((a, b) => a.order.compareTo(b.order));
      final points = <LatLng>[];
      for (final spot in ordered) {
        final match = widget.curations
            .where((c) => c.id == spot.curationId)
            .firstOrNull;
        if (match != null) {
          points.add(LatLng(match.location.latitude, match.location.longitude));
        }
      }
      if (points.length >= 2) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('plan_route'),
          points: points,
          color: AppColors.primary,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }

    if (mounted) setState(() {});
  }

  double _categoryHue(String category) {
    switch (category) {
      case CurationCategory.shrine:
      case CurationCategory.temple:
        return BitmapDescriptor.hueOrange;
      case CurationCategory.nature:
        return BitmapDescriptor.hueGreen;
      case CurationCategory.food:
        return BitmapDescriptor.hueYellow;
      case CurationCategory.culture:
        return BitmapDescriptor.hueMagenta;
      case CurationCategory.modern:
        return BitmapDescriptor.hueCyan;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty || _controller == null) return;
    final lats = _markers.map((m) => m.position.latitude).toList();
    final lngs = _markers.map((m) => m.position.longitude).toList();
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(lats.reduce((a, b) => a < b ? a : b),
              lngs.reduce((a, b) => a < b ? a : b)),
          northeast: LatLng(lats.reduce((a, b) => a > b ? a : b),
              lngs.reduce((a, b) => a > b ? a : b)),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: _japanCenter,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            if (_markers.isNotEmpty) _fitBounds();
          },
        ),
      ),
    );
  }
}

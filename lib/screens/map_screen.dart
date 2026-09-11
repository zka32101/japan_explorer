import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/curation.dart';
import '../providers/curations_provider.dart';
import '../services/location_service.dart';
import '../config/theme.dart';
import '../widgets/map_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Position? _position;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (mounted) setState(() => _position = pos);
  }

  @override
  Widget build(BuildContext context) {
    final curationsAsync = ref.watch(curationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: curationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (curations) {
                final filtered = _selectedCategory == null
                    ? curations
                    : curations.where((c) => c.category == _selectedCategory).toList();
                return SpotMapWidget(
                  curations: filtered,
                  height: double.infinity,
                  onMarkerTap: (c) => context.go('/home/detail/${c.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: CurationCategory.all.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = i == 0 ? null : CurationCategory.all[i - 1];
          final label = cat == null
              ? 'All'
              : '${CurationCategory.emoji(cat)} ${CurationCategory.label(cat)}';
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: AppColors.primary,
            labelStyle:
                TextStyle(color: isSelected ? Colors.white : AppColors.onSurface),
          );
        },
      ),
    );
  }
}

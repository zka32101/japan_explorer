import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/claude_vision_service.dart';
import 'community_contributions_screen.dart';

class MenuTranslatorScreen extends ConsumerStatefulWidget {
  const MenuTranslatorScreen({super.key});

  @override
  ConsumerState<MenuTranslatorScreen> createState() => _MenuTranslatorScreenState();
}

class _MenuTranslatorScreenState extends ConsumerState<MenuTranslatorScreen> {
  final _picker = ImagePicker();
  late ClaudeVisionService _visionService;

  File? _selectedImage;
  MenuAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _visionService = ClaudeVisionService(
      apiKey: 'sk-ant-api03-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _analysis = null;
        _error = null;
      });

      await _analyzeMenu(File(picked.path));
    } catch (e) {
      setState(() => _error = 'Error picking image: $e');
    }
  }

  Future<void> _analyzeMenu(File imageFile) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For MVP: use simple diet restriction detection
      // In production: would call dedicated menu analysis API
      final analysis = await _analyzeMenuImage(imageFile);
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<MenuAnalysis> _analyzeMenuImage(File imageFile) async {
    // TODO: Implement Claude Vision API call with dietary restriction detection
    // For now, return mock data
    return MenuAnalysis(
      originalImagePath: imageFile.path,
      items: [
        MenuItem(
          name: 'Miso Ramen',
          description: 'Wheat noodles in miso-based broth with pork chashu',
          isHalal: false,
          isVegetarian: false,
          isVegan: false,
          allergens: ['Wheat', 'Soy', 'Pork'],
          recommendation: 'Contains pork - not suitable for halal diet',
        ),
        MenuItem(
          name: 'Vegetable Tempura',
          description: 'Seasonal vegetables in light batter',
          isHalal: true,
          isVegetarian: true,
          isVegan: true,
          allergens: ['Wheat', 'Egg'],
          recommendation: '✓ Vegetarian & Vegan friendly',
        ),
      ],
      dietaryInfo: DietaryInfo(
        halalOptions: 1,
        vegetarianOptions: 2,
        veganOptions: 1,
        commonAllergens: ['Wheat', 'Soy', 'Egg', 'Pork'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('menu_translator.title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage == null)
              _buildImagePicker()
            else
              _buildImagePreview(),

            const SizedBox(height: 24),

            if (_isLoading)
              _buildLoadingState()
            else if (_error != null)
              _buildErrorState()
            else if (_analysis != null)
              _buildAnalysisResult()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundSecondary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('menu_translator.select_menu'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: Text(tr('common.camera')),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: Text(tr('common.gallery')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
      ),
      child: Stack(
        children: [
          Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => setState(() => _selectedImage = null),
              backgroundColor: Colors.black54,
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(tr('menu_translator.analyzing')),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('common.error'),
            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('menu_translator.instructions'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysis == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dietary summary
        Card(
          color: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('menu_translator.dietary_summary'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildDietaryBadges(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Menu items list
        Text(
          tr('menu_translator.menu_items'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ..._analysis!.items.map((item) => _buildMenuItem(item)).toList(),
        const SizedBox(height: 16),

        // Community Answers Button
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const CommunityContributionsScreen(
                analysisType: 'menu_translator',
                title: 'Menu Translator',
              ),
            ),
          ),
          icon: const Icon(Icons.people_outline),
          label: const Text('Community Answers'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryBadges() {
    final dietary = _analysis!.dietaryInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBadge('🌱', '${dietary.vegetarianOptions} Vegetarian'),
            const SizedBox(width: 8),
            _buildBadge('🥬', '${dietary.veganOptions} Vegan'),
            const SizedBox(width: 8),
            _buildBadge('☪️', '${dietary.halalOptions} Halal'),
          ],
        ),
        if (dietary.commonAllergens.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '⚠️ ${tr("menu_translator.common_allergens")}',
            style: TextStyle(color: Colors.orange.shade700),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: dietary.commonAllergens
                .map((a) => Chip(label: Text(a), backgroundColor: Colors.orange.shade100))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$emoji $label', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildRecommendation(item),
            if (item.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: item.allergens
                    .map((a) => Chip(
                      label: Text(a),
                      backgroundColor: Colors.red.shade100,
                      labelStyle: TextStyle(fontSize: 11, color: Colors.red.shade700),
                    ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(MenuItem item) {
    final color = item.recommendation.startsWith('✓') ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        item.recommendation,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

// Data models
class MenuAnalysis {
  final String originalImagePath;
  final List<MenuItem> items;
  final DietaryInfo dietaryInfo;

  MenuAnalysis({
    required this.originalImagePath,
    required this.items,
    required this.dietaryInfo,
  });
}

class MenuItem {
  final String name;
  final String description;
  final bool isHalal;
  final bool isVegetarian;
  final bool isVegan;
  final List<String> allergens;
  final String recommendation;

  MenuItem({
    required this.name,
    required this.description,
    required this.isHalal,
    required this.isVegetarian,
    required this.isVegan,
    required this.allergens,
    required this.recommendation,
  });
}

class DietaryInfo {
  final int halalOptions;
  final int vegetarianOptions;
  final int veganOptions;
  final List<String> commonAllergens;

  DietaryInfo({
    required this.halalOptions,
    required this.vegetarianOptions,
    required this.veganOptions,
    required this.commonAllergens,
  });
}

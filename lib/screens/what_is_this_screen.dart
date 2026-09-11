import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/vision_cache_provider.dart';
import '../services/claude_vision_service.dart';
import '../services/vision_cache_service.dart';
import '../widgets/badge_widget.dart';
import 'community_contributions_screen.dart';

class WhatIsThisScreen extends ConsumerStatefulWidget {
  const WhatIsThisScreen({super.key});

  @override
  ConsumerState<WhatIsThisScreen> createState() => _WhatIsThisScreenState();
}

class _WhatIsThisScreenState extends ConsumerState<WhatIsThisScreen> {
  final _picker = ImagePicker();
  late ClaudeVisionService _visionService;

  File? _selectedImage;
  CameraExplanation? _explanation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _visionService = ClaudeVisionService(
      apiKey: 'sk-ant-api03-${DateTime.now().millisecondsSinceEpoch}', // プレースホルダー
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _explanation = null;
        _error = null;
      });

      await _analyzeImage(File(picked.path));
    } catch (e) {
      setState(() => _error = 'Error picking image: $e');
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final explanation = await _visionService.explainImage(imageFile: imageFile);
      setState(() {
        _explanation = explanation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToJournal() async {
    if (_selectedImage == null || _explanation == null) return;

    try {
      await ref.read(journalProvider.notifier).createEntry(
        curationId: 'what-is-this-${DateTime.now().millisecondsSinceEpoch}',
        curationTitle: _explanation!.name,
        content: '${_explanation!.description}\n\n${_explanation!.historicalBackground}',
        mood: JournalMood.amazing,
        visitDate: DateTime.now(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('common.saved'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('what_is_this.title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview or picker
            if (_selectedImage == null)
              _buildImagePicker()
            else
              _buildImagePreview(),

            const SizedBox(height: 24),

            // Loading or Results
            if (_isLoading)
              _buildLoadingState()
            else if (_error != null)
              _buildErrorState()
            else if (_explanation != null)
              _buildResultCard()
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
          Icon(Icons.camera_alt, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('what_is_this.select_image'),
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
          Text(tr('what_is_this.analyzing')),
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
            tr('what_is_this.instructions'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_explanation == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _explanation!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              tr('what_is_this.description'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(_explanation!.description),
            const SizedBox(height: 16),

            // Historical Background
            Text(
              tr('what_is_this.history'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(_explanation!.historicalBackground),
            const SizedBox(height: 16),

            // How to Experience
            Text(
              tr('what_is_this.how_to_experience'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(_explanation!.howToExperience),
            const SizedBox(height: 16),

            // Japanese Phrase
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _explanation!.phrase.japanese,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _explanation!.phrase.romaji,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _explanation!.phrase.english,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveToJournal,
                    icon: const Icon(Icons.bookmark),
                    label: Text(tr('common.save')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement share
                    },
                    icon: const Icon(Icons.share),
                    label: Text(tr('common.share')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Community Answers Button
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => CommunityContributionsScreen(
                    analysisType: 'what_is_this',
                    title: _explanation!.name,
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
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../providers/post_provider.dart';

class PostScreen extends ConsumerStatefulWidget {
  final String curationId;
  final String curationTitle;

  const PostScreen({
    super.key,
    required this.curationId,
    required this.curationTitle,
  });

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  final _commentCtrl = TextEditingController();
  double _rating = 3.0;
  File? _imageFile;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  static const _availableTags = [
    '🌸 Sakura',
    '🍜 Food',
    '⛩️ Shrine',
    '🏔️ Nature',
    '🛍️ Shopping',
    '🎌 Culture',
    '🌙 Nightlife',
    '📸 Photo Spot',
    '👶 Family Friendly',
    '♿ Accessible',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success =
        await ref.read(postNotifierProvider.notifier).submitPost(
              curationId: widget.curationId,
              curationTitle: widget.curationTitle,
              caption: _commentCtrl.text.trim(),
              imageFile: _imageFile,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Post submitted! It will appear after review.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Experience'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spot banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.curationTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating
            _Section(
              title: 'Overall Rating',
              child: Row(
                children: List.generate(5, (i) {
                  final star = (i + 1).toDouble();
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= _rating
                            ? Icons.star
                            : Icons.star_outline,
                        color: AppColors.accent,
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Photo picker
            _Section(
              title: 'Photo (optional)',
              child: GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              _imageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _imageFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.textSecondary),
                            SizedBox(height: 8),
                            Text('Add Photo',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Comment
            _Section(
              title: 'Your Experience',
              child: TextField(
                controller: _commentCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Share what made this spot special for you...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tags
            _Section(
              title: 'Tags',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      v
                          ? _selectedTags.add(tag)
                          : _selectedTags.remove(tag);
                    }),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Share Experience',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Posts are reviewed before being published',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

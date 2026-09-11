import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/posts_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  File? _imageFile;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('community.no_image'))));
      return;
    }
    if (_captionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('community.no_caption'))));
      return;
    }

    setState(() => _isPosting = true);
    try {
      final post = await postService.createPost(
        imageFile: _imageFile!,
        caption: _captionCtrl.text.trim(),
      );
      // Prepend to feed without full reload
      ref.read(postFeedProvider.notifier).loadInitial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('community.post_shared'))));
        context.pop();
      }
      // post created successfully
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('errors.generic'))));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('community.create_post')),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submit,
            child: _isPosting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(tr('common.share'),
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(tr('community.tap_to_add_photo'),
                              style: TextStyle(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                              padding: EdgeInsets.zero,
                              onPressed: _showImageSourceDialog,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Caption
            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              maxLength: 280,
              decoration: InputDecoration(
                labelText: tr('community.caption'),
                hintText: tr('community.caption_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 8),

            Text(tr('community.photo_guidelines'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr('common.camera')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('common.gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

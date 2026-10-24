import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/claude_vision_service.dart';
import 'share_card_frame.dart';

/// Share card for an AI-lens result: the photo, the name, a short description
/// and the useful Japanese phrase.
class LensShareCard extends StatelessWidget {
  const LensShareCard({
    super.key,
    required this.style,
    required this.explanation,
    required this.photo,
  });

  final CardFrameStyle style;
  final CameraExplanation explanation;
  final File photo;

  @override
  Widget build(BuildContext context) {
    final phrase = explanation.phrase;
    return ShareCardFrame(
      style: style,
      title: explanation.name,
      subtitle: 'AI Lens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.file(photo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              explanation.description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.onSurface,
              ),
            ),
          ),
          if (phrase.japanese.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: style.gradient.last.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.japanese,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (phrase.english.isNotEmpty)
                    Text(
                      phrase.english,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: kMinFontSize,
                          color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

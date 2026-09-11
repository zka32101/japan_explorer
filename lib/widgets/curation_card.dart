import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/curation.dart';
import '../config/theme.dart';

class CurationCard extends StatelessWidget {
  final Curation curation;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  const CurationCard({
    super.key,
    required this.curation,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(
              imageUrl: curation.imageUrls.isNotEmpty
                  ? curation.imageUrls.first
                  : null,
              rank: curation.overallRank > 0 ? curation.overallRank : null,
              isSaved: isSaved,
              onSave: onSave,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CurationCategory.emoji(curation.category),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        CurationCategory.label(curation.category),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        curation.prefecture,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    curation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _RatingChip(
                        label: 'Want to Go',
                        value: curation.averageWantToGo,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _RatingChip(
                        label: 'Recommend',
                        value: curation.averageRecommend,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final int? rank;
  final bool isSaved;
  final VoidCallback? onSave;

  const _HeroImage({
    this.imageUrl,
    this.rank,
    required this.isSaved,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.divider,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => _PlaceholderImage(),
                )
              : _PlaceholderImage(),
        ),
        if (rank != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (onSave != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: onSave,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: isSaved ? AppColors.primary : Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.divider,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _RatingChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

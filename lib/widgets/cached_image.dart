import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Lightweight wrapper around [CachedNetworkImage] with built-in
/// loading shimmer and error placeholder. Optimized for memory efficiency.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// Bundled illustration assets use a local `assets/...` path instead of a
  /// network URL — route those through [Image.asset] instead of the network
  /// cache.
  bool get _isLocalAsset => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    Widget image = _isLocalAsset
        ? Image.asset(
            url,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            width: width,
            height: height,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 200),
            memCacheHeight: height?.toInt(),
            memCacheWidth: width?.toInt(),
            placeholder: (_, _) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

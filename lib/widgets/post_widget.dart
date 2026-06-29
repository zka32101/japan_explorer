import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/post.dart';

/// Card widget for displaying a single user post (used on detail/curation pages).
class PostCard extends StatelessWidget {
  final Post post;
  final bool showSpotName;

  const PostCard({super.key, required this.post, this.showSpotName = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (showSpotName && post.curationTitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(post.curationTitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (post.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppColors.divider,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(post.caption,
                style: const TextStyle(height: 1.55, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.likeCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.commentCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: post.authorAvatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(post.authorAvatarUrl)
              : null,
          child: post.authorAvatarUrl.isEmpty
              ? Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    }
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

/// Section of posts for a curation detail page.
class PostsSection extends StatelessWidget {
  final List<Post> posts;
  final String curationId;
  final String curationTitle;
  final VoidCallback? onAddPost;

  const PostsSection({
    super.key,
    required this.posts,
    required this.curationId,
    required this.curationTitle,
    this.onAddPost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Visitor Posts (${posts.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (onAddPost != null)
              TextButton.icon(
                onPressed: onAddPost,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Share'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Be the first to share your experience!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...posts.map((p) => PostCard(post: p)),
      ],
    );
  }
}

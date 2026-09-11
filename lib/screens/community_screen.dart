import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/router.dart';
import '../models/post.dart';
import '../utils/constants.dart';
import '../providers/posts_provider.dart';
import '../widgets/cached_image.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(postFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(postFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('community.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: tr('community.create_post'),
            onPressed: () => context.push(AppRoutes.createPost),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(postFeedProvider.notifier).loadInitial(),
        child: feedState.isLoading && feedState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : feedState.posts.isEmpty
                ? _EmptyFeed(onTap: () => context.push(AppRoutes.createPost))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount:
                        feedState.posts.length + (feedState.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == feedState.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _PostCard(post: feedState.posts[i]);
                    },
                  ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(post.createdAt, context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: post.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(post.authorAvatarUrl)
                      : null,
                  child: post.authorAvatarUrl.isEmpty
                      ? Text(
                          post.authorName.isNotEmpty
                              ? post.authorName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: theme.textTheme.titleSmall),
                      if (post.curationTitle.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                post.curationTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(timeAgo,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),

          // Image
          if (post.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => context.push(
                  '${AppRoutes.postDetail}/${post.id}'),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedImage(
                  url: post.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(post.caption, maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),

          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              children: [
                _LikeButton(post: post),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => context.push(
                      '${AppRoutes.postDetail}/${post.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('${post.commentCount}'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600]),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: Colors.grey[600],
                  onPressed: () => _sharePost(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    // Handled by share_service
  }

  String _formatTimeAgo(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return tr('common.just_now');
    if (diff.inHours < 1) return tr('common.minutes_ago', args: ['${diff.inMinutes}']);
    if (diff.inDays < 1) return tr('common.hours_ago', args: ['${diff.inHours}']);
    if (diff.inDays < 7) return tr('common.days_ago', args: ['${diff.inDays}']);
    return DateFormat.yMd(context.locale.toLanguageTag()).format(dt);
  }
}

// ── Like button (optimistic) ──────────────────────────────────────────────────

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () =>
          ref.read(postFeedProvider.notifier).toggleLike(post.id),
      icon: Icon(
        post.likedByMe ? Icons.favorite : Icons.favorite_border,
        size: 18,
        color: post.likedByMe ? Colors.red : Colors.grey[600],
      ),
      label: Text(
        '${post.likeCount}',
        style: TextStyle(
            color: post.likedByMe ? Colors.red : Colors.grey[600]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined,
              size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(tr('community.empty_title'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(tr('community.empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(tr('community.create_post')),
          ),
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import '../providers/posts_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/cached_image.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await postService.addComment(postId: widget.postId, text: text);
      analyticsService.logCommentAdded(widget.postId);
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(postFeedProvider);
    final Post? post =
        feedState.posts.where((p) => p.id == widget.postId).firstOrNull;
    final commentsAsync =
        ref.watch(postCommentsProvider(widget.postId));
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('community.post')),
        actions: [
          if (post != null && post.authorId == uid)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, post),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                // Image
                if (post != null && post.imageUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CachedImage(url: post.imageUrl, fit: BoxFit.cover),
                  ),

                // Post info
                if (post != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  post.authorAvatarUrl.isNotEmpty
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
                            Text(post.authorName,
                                style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),

                        if (post.curationTitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(post.curationTitle,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ],
                          ),
                        ],

                        if (post.caption.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(post.caption),
                        ],

                        const SizedBox(height: 12),

                        // Like row
                        Row(
                          children: [
                            _LikeButton(post: post),
                            const SizedBox(width: 8),
                            Icon(Icons.chat_bubble_outline,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${post.commentCount}',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],

                // Comments
                commentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(tr('errors.generic')),
                  ),
                  data: (comments) => comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(tr('community.no_comments'),
                                style:
                                    TextStyle(color: Colors.grey[500])),
                          ),
                        )
                      : Column(
                          children: comments
                              .map((c) => _CommentTile(comment: c))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),

          // Comment input bar
          _CommentInputBar(
            controller: _commentCtrl,
            isSending: _isSending,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('community.delete_post')),
        content: Text(tr('community.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await postService.deletePost(post);
              ref.read(postFeedProvider.notifier).loadInitial();
              if (context.mounted) context.pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: comment.authorAvatarUrl.isNotEmpty
                ? NetworkImage(comment.authorAvatarUrl)
                : null,
            child: comment.authorAvatarUrl.isEmpty
                ? Text(comment.authorName.isNotEmpty
                    ? comment.authorName[0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName,
                    style: Theme.of(context).textTheme.labelMedium),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment input bar ─────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 1,
                maxLength: 200,
                buildCounter: (_, {required currentLength,
                    required isFocused, required maxLength}) =>
                    null,
                decoration: InputDecoration(
                  hintText: tr('community.add_comment'),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.send,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(postFeedProvider.notifier).toggleLike(post.id),
      child: Row(
        children: [
          Icon(
            post.likedByMe ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: post.likedByMe ? Colors.red : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${post.likeCount}',
            style: TextStyle(
                color: post.likedByMe ? Colors.red : Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

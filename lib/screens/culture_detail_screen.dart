import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';
import '../models/culture_content.dart';
import '../providers/culture_content_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/premium_gate.dart';
import '../utils/firestore_instance.dart';

class CultureDetailScreen extends ConsumerWidget {
  final String contentId;

  const CultureDetailScreen({
    super.key,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return FutureBuilder<CultureContent?>(
      future: _fetchContent(contentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(tr('culture_detail.content_not_found'))),
          );
        }

        final content = snapshot.data!;
        final isLocked = content.isPremium && !isPremium;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      content.imageUrl.isNotEmpty
                          ? Image.network(
                              content.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surface,
                                child: const Center(
                                    child: Icon(Icons.image_not_supported)),
                              ),
                            )
                          : Container(color: AppColors.surface),
                      // Premium shimmer overlay on image
                      if (isLocked)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & level row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.localizedTitle(context.locale.languageCode),
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  content.localizedSubtitle(context.locale.languageCode),
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(content.level),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  content.getLevelLabel(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ),
                              if (content.isPremium) ...[
                                const SizedBox(height: 6),
                                const PremiumBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Meta info
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                              tr('culture_hub.min_read',
                                  args: [content.readTime.toString()]),
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(_formatDate(content.createdAt),
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (content.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: content.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag,
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.primary)),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Quick Facts
                      if (content.localizedKeyFacts(context.locale.languageCode).isNotEmpty) ...[
                        _QuickFactsSection(
                            facts: content.localizedKeyFacts(context.locale.languageCode)),
                        const SizedBox(height: 24),
                      ],

                      // Overview section — gated for premium content
                      Text(tr('culture_hub.overview'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),

                      if (isLocked)
                        _buildPremiumPaywallBlock(context, content)
                      else
                        Text(
                          content.localizedDescription(context.locale.languageCode),
                          style:
                              const TextStyle(height: 1.6, fontSize: 15),
                        ),

                      const SizedBox(height: 24),

                      // Did You Know
                      if (!isLocked &&
                          content.localizedDidYouKnow(context.locale.languageCode) != null) ...[
                        _DidYouKnowCard(
                            text: content.localizedDidYouKnow(context.locale.languageCode)!),
                        const SizedBox(height: 24),
                      ],

                      // Video section
                      if (!isLocked &&
                          content.videoUrl != null &&
                          content.videoUrl!.isNotEmpty)
                        _VideoSection(videoUrl: content.videoUrl!),

                      // Source
                      if (!isLocked)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('culture_hub.source'),
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      content.sourceUrl,
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Related content
                      _RelatedContentSection(content: content),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.pop(),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: Text(tr('common.back'), style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildPremiumPaywallBlock(
      BuildContext context, CultureContent content) {
    // Show first ~200 chars as teaser, then paywall
    final localizedDesc = content.localizedDescription(context.locale.languageCode);
    final teaser = localizedDesc.length > 200
        ? '${localizedDesc.substring(0, 200)}...'
        : localizedDesc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Teaser text fading out
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.transparent],
            stops: [0.4, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: Text(
            teaser,
            style: const TextStyle(height: 1.6, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),

        // Paywall card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('✨', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                tr('culture_detail.premium_article_title'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('culture_detail.premium_article_desc', args: ['18']),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => showPremiumPaywall(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE63946),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    tr('culture_detail.unlock_premium_cta'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  tr('culture_detail.maybe_later'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<CultureContent?> _fetchContent(String contentId) async {
    try {
      final doc = await db
          .collection('culture_content')
          .doc(contentId)
          .get();

      if (doc.exists) {
        return CultureContent.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ── Quick Facts section ────────────────────────────────────────────────────────
class _QuickFactsSection extends StatelessWidget {
  final List<String> facts;
  const _QuickFactsSection({required this.facts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                tr('culture_detail.quick_facts'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...facts.map((fact) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(fact, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Did You Know card ──────────────────────────────────────────────────────────
class _DidYouKnowCard extends StatelessWidget {
  final String text;
  const _DidYouKnowCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('culture_detail.did_you_know'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Related content section ────────────────────────────────────────────────────
class _RelatedContentSection extends ConsumerWidget {
  final CultureContent content;
  const _RelatedContentSection({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = RelatedContentParams(
      contentId: content.id,
      tags: content.tags,
      categoryId: content.categoryId,
      seeAlso: content.seeAlso,
    );
    final relatedAsync = ref.watch(relatedCultureContentProvider(params));

    return relatedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(tr('culture_detail.related_content'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map((item) => _RelatedCard(item: item)),
          ],
        );
      },
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final CultureContent item;
  const _RelatedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/culture/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primary.withOpacity(0.15),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.localizedTitle(context.locale.languageCode),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.localizedSubtitle(context.locale.languageCode),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                          tr('culture_detail.min_short',
                              args: [item.readTime.toString()]),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── YouTube video player (stateful to manage controller lifecycle) ─────────────
class _VideoSection extends StatefulWidget {
  final String videoUrl;
  const _VideoSection({required this.videoUrl});

  @override
  State<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<_VideoSection> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('culture_hub.video'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressColors: ProgressBarColors(
              playedColor: AppColors.primary,
              handleColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

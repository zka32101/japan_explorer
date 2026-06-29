import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/curations_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/post_provider.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/review_service.dart';
import '../services/share_service.dart';
import '../models/rating.dart';
import '../config/theme.dart';
import '../screens/post_screen.dart';
import '../screens/audio_guide_screen.dart';
import '../screens/journal_entry_screen.dart';
import '../widgets/post_widget.dart';
import '../utils/constants.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String curationId;
  const DetailScreen({super.key, required this.curationId});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  double _wantToGo = 0;
  double _recommend = 0;
  bool _isSubmitting = false;
  int _currentImageIndex = 0;

  Future<void> _submitRating() async {
    if (_wantToGo == 0 || _recommend == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('detail.rate_required'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user == null) return;
      await ref.read(firebaseServiceProvider).submitRating(
            curationId: widget.curationId,
            userId: user.uid,
            wantToGo: _wantToGo,
            recommend: _recommend,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('detail.rating_submitted')),
            backgroundColor: Colors.green,
          ),
        );
        // Reward engagement → may trigger in-app review
        reviewService.addEngagement(ReviewService.ptDetailViewed);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final curationAsync = ref.watch(curationDetailProvider(widget.curationId));

    return Scaffold(
      body: curationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (curation) {
          if (curation == null) {
            return const Center(child: Text('Spot not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: tr('detail.share'),
                    onPressed: () => shareService.shareCuration(curation),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 320,
                          viewportFraction: 1,
                          onPageChanged: (index, _) =>
                              setState(() => _currentImageIndex = index),
                        ),
                        items: curation.imageUrls.isNotEmpty
                            ? curation.imageUrls
                                .map(
                                  (url) => CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                                .toList()
                            : [
                                Container(
                                  color: AppColors.divider,
                                  child: const Icon(Icons.image, size: 80),
                                )
                              ],
                      ),
                      if (curation.imageUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: curation.imageUrls.asMap().entries.map((e) {
                              return Container(
                                width: _currentImageIndex == e.key ? 16 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == e.key
                                      ? AppColors.primary
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(curation),
                    const SizedBox(height: 20),
                    _buildRatingSection(),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(curation.description),
                    const SizedBox(height: 20),
                    _buildPracticalInfo(curation.practicalInfo),
                    const SizedBox(height: 20),
                    _buildPostsSection(curation),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(curation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                curation.category,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
            const Spacer(),
            if (curation.overallRank > 0)
              Text(
                '#${curation.overallRank} Overall',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          curation.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${curation.city}, ${curation.prefecture}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatChip(
              label: 'Want to Go',
              value: curation.averageWantToGo,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _StatChip(
              label: 'Recommend',
              value: curation.averageRecommend,
              color: AppColors.secondary,
            ),
            const Spacer(),
            Text(
              '${curation.totalRatings} ratings',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate this spot',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RatingRow(
              label: 'Want to Go',
              value: _wantToGo,
              onChanged: (v) => setState(() => _wantToGo = v),
            ),
            const SizedBox(height: 8),
            _RatingRow(
              label: 'Recommend',
              value: _recommend,
              onChanged: (v) => setState(() => _recommend = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(height: 1.6)),
      ],
    );
  }

  Widget _buildPostsSection(curation) {
    final postsAsync =
        ref.watch(curationPostsProvider(widget.curationId));
    return postsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (posts) => PostsSection(
        posts: posts,
        curationId: widget.curationId,
        curationTitle: curation.title,
        onAddPost: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostScreen(
              curationId: widget.curationId,
              curationTitle: curation.title,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticalInfo(Map<String, dynamic> info) {
    if (info.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practical Info',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...info.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final curation =
        ref.watch(curationDetailProvider(widget.curationId)).valueOrNull;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio guide full-width button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: curation == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioGuideScreen(
                              curationId: curation.id),
                        ),
                      ),
              icon: const Text('🎧', style: TextStyle(fontSize: 16)),
              label: const Text('Audio Guide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: curation == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WriteJournalScreen(
                                curationId: curation.id,
                                curationTitle: curation.title,
                              ),
                            ),
                          ),
                  icon: const Text('📖', style: TextStyle(fontSize: 14)),
                  label: Text(tr('journal.write_btn')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: curation == null
                      ? null
                      : () => _showAddToPlan(curation.id, curation.title,
                          curation.imageUrls.firstOrNull),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Plan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: curation == null
                      ? null
                      : () => _navigate(
                          curation.location.latitude,
                          curation.location.longitude,
                          curation.title),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Go'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddToPlan(
      String curationId, String title, String? imageUrl) async {
    final plans = ref.read(planNotifierProvider).valueOrNull ?? [];
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No plans yet. Create one first!'),
          action: SnackBarAction(
            label: 'My Plans',
            onPressed: () => context.go('/my-plan'),
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add to Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...plans.map((p) => ListTile(
                  leading: const Icon(Icons.map, color: AppColors.primary),
                  title: Text(p.title),
                  subtitle: Text('${p.spots.length} spots'),
                  onTap: () => Navigator.pop(context, p.id),
                )),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await ref.read(planNotifierProvider.notifier).addSpotToPlan(
          selected,
          PlanSpot(
            curationId: curationId,
            curationTitle: title,
            imageUrl: imageUrl,
            order: 0,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to plan!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _navigate(double lat, double lng, String name) async {
    final url = LocationService.mapsNavigateUrl(lat, lng, name);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Row(
          children: [
            Icon(Icons.star, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        ...List.generate(5, (i) {
          final star = i + 1.0;
          return GestureDetector(
            onTap: () => onChanged(star),
            child: Icon(
              star <= value ? Icons.star : Icons.star_outline,
              color: AppColors.accent,
              size: 28,
            ),
          );
        }),
      ],
    );
  }
}

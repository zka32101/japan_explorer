import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/culture_content.dart';
import '../providers/culture_content_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/premium_gate.dart';

class CultureHubScreen extends ConsumerStatefulWidget {
  const CultureHubScreen({super.key});

  @override
  ConsumerState<CultureHubScreen> createState() => _CultureHubScreenState();
}

class _CultureHubScreenState extends ConsumerState<CultureHubScreen> {
  String _selectedCategory = 'culture';
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCultureCategoriesProvider);
    final contentAsync = ref.watch(cultureContentProvider(_selectedCategory));
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Japanese Culture'),
        elevation: 0,
        actions: [
          if (!isPremium)
            TextButton.icon(
              onPressed: () => showPremiumPaywall(context),
              icon: const Text('✨', style: TextStyle(fontSize: 14)),
              label: const Text(
                'Premium',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          categoriesAsync.when(
            data: (categories) => _buildCategoryTabs(categories),
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, st) => const SizedBox(height: 48),
          ),

          // Premium banner for free users
          if (!isPremium) _buildPremiumBanner(context),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: InputDecoration(
                hintText: 'Search culture...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Content list
          Expanded(
            child: contentAsync.when(
              data: (contents) {
                final filtered = _searchTerm.isEmpty
                    ? contents
                    : contents
                        .where((c) =>
                            c.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                            c.tags.any((tag) =>
                                tag.toLowerCase().contains(_searchTerm.toLowerCase())))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('No content found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildContentCard(filtered[index], context, isPremium),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => showPremiumPaywall(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock 18 premium deep-dive articles',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Geisha, Bunraku, Irezumi, advanced language & more',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<CultureCategory> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${cat.emoji} ${cat.name}'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat.id),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentCard(
      CultureContent content, BuildContext context, bool isPremium) {
    final isLocked = content.isPremium && !isPremium;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLocked
            ? () => showPremiumPaywall(context)
            : () => context.push('/culture/${content.id}'),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (content.imageUrl.isNotEmpty)
                  Stack(
                    children: [
                      Image.network(
                        content.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: AppColors.surface,
                          child: const Center(child: Icon(Icons.image_not_supported)),
                        ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            child: const Center(
                              child: Icon(Icons.lock_outline,
                                  color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                    ],
                  ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  content.subtitle,
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(content.level),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  content.getLevelLabel(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (content.isPremium) ...[
                                const SizedBox(height: 4),
                                const PremiumBadge(mini: true),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${content.readTime} min read',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          const Spacer(),
                          ...content.tags.take(2).map((tag) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(tag,
                                      style: TextStyle(
                                          fontSize: 10, color: AppColors.primary)),
                                ),
                              )),
                        ],
                      ),

                      // Teaser for locked content
                      if (isLocked) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('✨',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(width: 4),
                              Text(
                                'Unlock with Premium',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }
}

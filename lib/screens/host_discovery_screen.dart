import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/host_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/host_provider.dart';
import 'host_profile_screen.dart';
import 'host_register_screen.dart';

// ── Filter options ────────────────────────────────────────────────────────────
const _cities = ['Tokyo', 'Kyoto', 'Osaka', 'Nara', 'Hiroshima', 'Fukuoka'];
const _interests = [
  ('culture', '⛩️'),
  ('food', '🍜'),
  ('nature', '🌿'),
  ('history', '🏯'),
  ('modern', '🏙️'),
  ('shopping', '🛍️'),
];
const _languages = {
  'en': '🇬🇧',
  'ja': '🇯🇵',
  'zh': '🇨🇳',
  'ko': '🇰🇷',
  'fr': '🇫🇷',
};

class HostDiscoveryScreen extends ConsumerWidget {
  const HostDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(hostFilterProvider);
    final hostsAsync = ref.watch(hostsProvider(filter));
    final user = ref.watch(appUserProvider).valueOrNull;
    final isHostAsync =
        user != null ? ref.watch(isRegisteredHostProvider(user.uid)) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤝', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('Meet a Local'),
          ],
        ),
        actions: [
          // Register / My Profile toggle
          if (user != null)
            isHostAsync?.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (isHost) => TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HostRegisterScreen(
                                existingUid: isHost ? user.uid : null,
                              )),
                    ),
                    icon: Icon(
                        isHost ? Icons.manage_accounts : Icons.add_circle_outline,
                        size: 18),
                    label: Text(isHost ? 'My Host' : 'Become a Host'),
                  ),
                ) ??
                const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, filter),
          Expanded(
            child: hostsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load hosts'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(hostsProvider(filter)),
                    child: const Text('Retry'),
                  ),
                ],
              )),
              data: (hosts) => hosts.isEmpty
                  ? _buildEmpty(context)
                  : _buildHostGrid(context, hosts),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, WidgetRef ref, HostFilter filter) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Cities',
                  selected: filter.city == null,
                  onTap: () => ref
                      .read(hostFilterProvider.notifier)
                      .state = filter.copyWith(clearCity: true),
                ),
                ..._cities.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FilterChip(
                        label: c,
                        selected: filter.city == c,
                        onTap: () => ref
                            .read(hostFilterProvider.notifier)
                            .state = filter.copyWith(city: c),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Interest + language row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _interests.map((item) {
                      final (id, emoji) = item;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: '$emoji ${id[0].toUpperCase()}${id.substring(1)}',
                          selected: filter.interest == id,
                          onTap: () => ref
                              .read(hostFilterProvider.notifier)
                              .state = filter.interest == id
                              ? filter.copyWith(clearInterest: true)
                              : filter.copyWith(interest: id),
                          compact: true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Language filter button
              PopupMenuButton<String>(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        filter.language != null
                            ? (_languages[filter.language] ?? '🌐')
                            : '🌐',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: '',
                    child: const Text('All Languages'),
                    onTap: () => ref
                        .read(hostFilterProvider.notifier)
                        .state = filter.copyWith(clearLanguage: true),
                  ),
                  ..._languages.entries.map((e) => PopupMenuItem(
                        value: e.key,
                        child: Text('${e.value} ${e.key.toUpperCase()}'),
                        onTap: () => ref
                            .read(hostFilterProvider.notifier)
                            .state = filter.copyWith(language: e.key),
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('No hosts found',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters or come back later',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHostGrid(BuildContext context, List<HostProfile> hosts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: hosts.length,
      itemBuilder: (_, i) => _HostCard(
        host: hosts[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HostProfileScreen(hostUid: hosts[i].uid)),
        ),
      ),
    );
  }
}

// ── Host Card ─────────────────────────────────────────────────────────────────

class _HostCard extends StatelessWidget {
  final HostProfile host;
  final VoidCallback onTap;

  const _HostCard({required this.host, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              height: 100,
              color: AppColors.primary.withValues(alpha: 0.1),
              width: double.infinity,
              child: host.photoUrl != null
                  ? Image.network(host.photoUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        host.displayName.isNotEmpty
                            ? host.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(host.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(host.city,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Languages
                    Text(
                      host.languageDisplay,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        if (host.reviewCount > 0) ...[
                          const Icon(Icons.star,
                              color: AppColors.accent, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            host.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text('(${host.reviewCount})',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ] else
                          const Text('New host',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        const Spacer(),
                        if (host.meetupsCompleted > 0)
                          Text('${host.meetupsCompleted}✓',
                              style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                      ],
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
}

// ── Filter chip helper ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 5 : 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onSurface,
            fontSize: compact ? 12 : 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

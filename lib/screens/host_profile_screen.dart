import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/host_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/host_provider.dart';
import '../services/host_service.dart';

class HostProfileScreen extends ConsumerWidget {
  final String hostUid;
  const HostProfileScreen({super.key, required this.hostUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostAsync = ref.watch(hostDetailProvider(hostUid));
    final user = ref.watch(appUserProvider).valueOrNull;
    final isOwnProfile = user?.uid == hostUid;

    return Scaffold(
      body: hostAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (host) {
          if (host == null) {
            return const Center(child: Text('Host not found'));
          }
          return CustomScrollView(
            slivers: [
              _buildHeroAppBar(context, host, isOwnProfile),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStats(host),
                    const SizedBox(height: 20),
                    _buildBio(host),
                    const SizedBox(height: 20),
                    _buildChips(
                        '📍 Areas',
                        host.areas,
                        AppColors.primary),
                    const SizedBox(height: 16),
                    _buildChips(
                        '⚡ Interests',
                        host.interests
                            .map((i) =>
                                '${_interestEmoji(i)} ${i[0].toUpperCase()}${i.substring(1)}')
                            .toList(),
                        AppColors.secondary),
                    const SizedBox(height: 16),
                    _buildLanguages(host.languages),
                    const SizedBox(height: 32),
                    if (!isOwnProfile && user != null)
                      _RequestButton(host: host, guestUser: user),
                    if (isOwnProfile)
                      _ActiveToggle(host: host),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildHeroAppBar(
      BuildContext context, HostProfile host, bool isOwnProfile) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            host.photoUrl != null
                ? Image.network(host.photoUrl!, fit: BoxFit.cover)
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    child: Center(
                      child: Text(
                        host.displayName.isNotEmpty
                            ? host.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
            // Gradient for readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(host.city,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      if (!host.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Inactive',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ],
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

  Widget _buildStats(HostProfile host) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatCol(
              value: host.reviewCount > 0
                  ? host.rating.toStringAsFixed(1)
                  : '--',
              label: 'Rating',
              icon: '⭐',
            ),
            _divider(),
            _StatCol(
              value: '${host.reviewCount}',
              label: 'Reviews',
              icon: '💬',
            ),
            _divider(),
            _StatCol(
              value: '${host.meetupsCompleted}',
              label: 'Meetups',
              icon: '✅',
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: AppColors.divider,
          margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildBio(HostProfile host) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(host.bio,
            style: const TextStyle(height: 1.6, fontSize: 14)),
      ],
    );
  }

  Widget _buildChips(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(item,
                  style:
                      TextStyle(color: color, fontSize: 13)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguages(List<String> langs) {
    const labels = {
      'en': '🇬🇧 English',
      'ja': '🇯🇵 Japanese',
      'zh': '🇨🇳 Chinese',
      'ko': '🇰🇷 Korean',
      'fr': '🇫🇷 French',
      'es': '🇪🇸 Spanish',
      'de': '🇩🇪 German',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🗣️ Languages',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: langs.map((l) {
            final label = labels[l] ?? l.toUpperCase();
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.secondary
                        .withValues(alpha: 0.3)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.secondary, fontSize: 13)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _interestEmoji(String interest) {
    const map = {
      'culture': '⛩️',
      'food': '🍜',
      'nature': '🌿',
      'history': '🏯',
      'modern': '🏙️',
      'shopping': '🛍️',
      'nightlife': '🌃',
    };
    return map[interest] ?? '✨';
  }
}

// ── Request button ────────────────────────────────────────────────────────────

class _RequestButton extends ConsumerStatefulWidget {
  final HostProfile host;
  final dynamic guestUser;

  const _RequestButton({required this.host, required this.guestUser});

  @override
  ConsumerState<_RequestButton> createState() => _RequestButtonState();
}

class _RequestButtonState extends ConsumerState<_RequestButton> {
  bool _sending = false;

  void _showRequestSheet(BuildContext context) {
    final messageCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request a meetup with ${widget.host.displayName}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText:
                    'Tell them about yourself and what you\'d like to explore…',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (messageCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _sendRequest(messageCtrl.text.trim());
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(String message) async {
    setState(() => _sending = true);
    try {
      final request = HostRequest(
        id: '',
        guestUid: widget.guestUser.uid,
        guestName: widget.guestUser.displayName,
        hostUid: widget.host.uid,
        hostName: widget.host.displayName,
        city: widget.host.city,
        message: message,
        createdAt: DateTime.now(),
      );
      await ref.read(hostServiceProvider).sendRequest(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Request sent to ${widget.host.displayName}! 🎉'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed:
          _sending || !widget.host.isActive
              ? null
              : () => _showRequestSheet(context),
      icon: _sending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text('🤝', style: TextStyle(fontSize: 18)),
      label: Text(widget.host.isActive
          ? 'Request a Meetup'
          : 'Currently Unavailable'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }
}

// ── Active toggle (host view) ────────────────────────────────────────────────

class _ActiveToggle extends ConsumerWidget {
  final HostProfile host;
  const _ActiveToggle({required this.host});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: SwitchListTile(
        title: const Text('Accept new meetup requests',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            host.isActive
                ? 'Guests can request a meetup with you'
                : 'You are currently not accepting requests',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        value: host.isActive,
        activeColor: AppColors.primary,
        onChanged: (v) async {
          await ref
              .read(hostServiceProvider)
              .setHostActive(host.uid, v);
          ref.invalidate(hostDetailProvider(host.uid));
        },
      ),
    );
  }
}

// ── Stat column ───────────────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _StatCol({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

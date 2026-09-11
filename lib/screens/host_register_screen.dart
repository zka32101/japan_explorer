import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/host_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/host_provider.dart';

const _availableCities = ['Tokyo', 'Kyoto', 'Osaka', 'Nara', 'Hiroshima', 'Fukuoka', 'Hakone', 'Kanazawa', 'Nikko', 'Hokkaido'];
const _allInterests = ['culture', 'food', 'history', 'nature', 'modern', 'shopping', 'nightlife', 'arts'];
const _allLanguages = {'en': '🇬🇧 English', 'ja': '🇯🇵 Japanese', 'zh': '🇨🇳 Chinese', 'ko': '🇰🇷 Korean', 'fr': '🇫🇷 French', 'es': '🇪🇸 Spanish', 'de': '🇩🇪 German'};

class HostRegisterScreen extends ConsumerStatefulWidget {
  /// Pass an existing uid to edit rather than create.
  final String? existingUid;
  const HostRegisterScreen({super.key, this.existingUid});

  @override
  ConsumerState<HostRegisterScreen> createState() =>
      _HostRegisterScreenState();
}

class _HostRegisterScreenState extends ConsumerState<HostRegisterScreen> {
  final _bioCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();
  String _city = 'Tokyo';
  final Set<String> _interests = {'culture', 'food'};
  final Set<String> _languages = {'en'};
  int _step = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingUid != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final host =
        await ref.read(hostServiceProvider).getHost(widget.existingUid!);
    if (host != null && mounted) {
      setState(() {
        _bioCtrl.text = host.bio;
        _areasCtrl.text = host.areas.join(', ');
        _city = host.city;
        _interests.clear();
        _interests.addAll(host.interests);
        _languages.clear();
        _languages.addAll(host.languages);
      });
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _areasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(hostRegistrationProvider);

    // Navigate on success
    if (regState.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingUid != null ? 'Edit Host Profile' : 'Become a Local Host'),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(current: _step, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: [
                _buildStep0(),
                _buildStep1(),
                _buildStep2(regState),
              ][_step],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: City + Bio ────────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(emoji: '🗾', title: 'Your Base City'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCities.map((c) {
            final sel = _city == c;
            return _SelectChip(
              label: c,
              selected: sel,
              onTap: () => setState(() => _city = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(emoji: '💬', title: 'Tell guests about yourself'),
        const SizedBox(height: 12),
        TextField(
          controller: _bioCtrl,
          maxLines: 5,
          maxLength: 400,
          decoration: const InputDecoration(
            hintText:
                'e.g. Born and raised in Kyoto, I love sharing hidden temples and local food. I speak Japanese and English fluently…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(emoji: '📍', title: 'Areas you can guide in'),
        const SizedBox(height: 8),
        TextField(
          controller: _areasCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Gion, Arashiyama, Fushimi',
            helperText: 'Separate with commas',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 32),
        _NavButtons(
          onNext: _bioCtrl.text.trim().length >= 20
              ? () => setState(() => _step = 1)
              : null,
          canGoBack: false,
        ),
        if (_bioCtrl.text.isNotEmpty && _bioCtrl.text.trim().length < 20)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Bio must be at least 20 characters',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  // ── Step 1: Interests + Languages ─────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(emoji: '⚡', title: 'Your interests & expertise'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allInterests.map((id) {
            final sel = _interests.contains(id);
            return _SelectChip(
              label:
                  '${_interestEmoji(id)} ${id[0].toUpperCase()}${id.substring(1)}',
              selected: sel,
              onTap: () => setState(() {
                if (sel && _interests.length > 1) {
                  _interests.remove(id);
                } else {
                  _interests.add(id);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(emoji: '🗣️', title: 'Languages you speak'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allLanguages.entries.map((e) {
            final sel = _languages.contains(e.key);
            return _SelectChip(
              label: e.value,
              selected: sel,
              onTap: () => setState(() {
                if (sel && _languages.length > 1) {
                  _languages.remove(e.key);
                } else {
                  _languages.add(e.key);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _NavButtons(
          onBack: () => setState(() => _step = 0),
          onNext: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // ── Step 2: Review + Submit ───────────────────────────────────────────────

  Widget _buildStep2(HostRegistrationState regState) {
    final areas = _areasCtrl.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(emoji: '✅', title: 'Review your profile'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(label: 'City', value: _city),
                _ReviewRow(
                    label: 'Areas',
                    value: areas.isEmpty ? '—' : areas.join(', ')),
                _ReviewRow(
                    label: 'Interests',
                    value: _interests
                        .map((i) =>
                            '${_interestEmoji(i)} ${i[0].toUpperCase()}${i.substring(1)}')
                        .join(', ')),
                _ReviewRow(
                    label: 'Languages',
                    value: _languages
                        .map((l) => _allLanguages[l] ?? l)
                        .join(', ')),
                const Divider(),
                const Text('Bio:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_bioCtrl.text,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ),
        if (regState.error != null) ...[
          const SizedBox(height: 12),
          Text(regState.error!,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        _NavButtons(
          onBack: () => setState(() => _step = 1),
          onNext: regState.isSaving ? null : () => _submit(areas),
          nextLabel: regState.isSaving
              ? 'Saving…'
              : widget.existingUid != null
                  ? 'Save Changes'
                  : 'Create Host Profile',
          nextLoading: regState.isSaving,
        ),
      ],
    );
  }

  Future<void> _submit(List<String> areas) async {
    final user = ref.read(appUserProvider).valueOrNull;
    if (user == null) return;

    final profile = HostProfile(
      uid: user.uid,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      bio: _bioCtrl.text.trim(),
      city: _city,
      areas: areas,
      interests: _interests.toList(),
      languages: _languages.toList(),
      createdAt: DateTime.now(),
    );

    if (widget.existingUid != null) {
      await ref
          .read(hostRegistrationProvider.notifier)
          .update(profile);
    } else {
      await ref
          .read(hostRegistrationProvider.notifier)
          .register(profile);
    }
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
      'arts': '🎨',
    };
    return map[interest] ?? '✨';
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done || active
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.primary
                        : active
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.divider,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active || done
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  const _SectionTitle({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool nextLoading;
  final bool canGoBack;

  const _NavButtons({
    this.onBack,
    this.onNext,
    this.nextLabel = 'Continue',
    this.nextLoading = false,
    this.canGoBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack && onBack != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ),
        if (canGoBack && onBack != null) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onNext,
            child: nextLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(nextLabel),
          ),
        ),
      ],
    );
  }
}

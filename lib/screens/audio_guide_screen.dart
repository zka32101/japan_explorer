import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/curation.dart';
import '../providers/audio_guide_provider.dart';
import '../providers/curations_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/premium_gate.dart';

// Supported guide languages
const _guideLanguages = <String, String>{
  'en': '🇬🇧 EN',
  'ja': '🇯🇵 JA',
  'zh': '🇨🇳 ZH',
  'ko': '🇰🇷 KO',
  'fr': '🇫🇷 FR',
};

class AudioGuideScreen extends ConsumerStatefulWidget {
  final String curationId;
  const AudioGuideScreen({super.key, required this.curationId});

  @override
  ConsumerState<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends ConsumerState<AudioGuideScreen> {
  final _scrollController = ScrollController();
  final List<GlobalKey> _paraKeys = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndGenerate(Curation curation) async {
    final isPremium = ref.read(isPremiumProvider);
    final canUse =
        await UsageLimitService.canUseAudioGuide(isPremium: isPremium);
    if (!canUse) {
      if (mounted) await showPremiumPaywall(context);
      return;
    }
    await UsageLimitService.recordAudioGuideUse();
    ref.read(audioGuideProvider(curation.id).notifier).generate(
          title: curation.title,
          description: curation.description,
          city: curation.city,
          category: curation.category,
        );
  }

  void _scrollToParagraph(int index) {
    if (index >= _paraKeys.length) return;
    final ctx = _paraKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.25);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideState =
        ref.watch(audioGuideProvider(widget.curationId));
    final curationAsync =
        ref.watch(curationDetailProvider(widget.curationId));

    // Auto-scroll to highlighted paragraph
    ref.listen(audioGuideProvider(widget.curationId), (_, next) {
      if (next.isPlaying) {
        _scrollToParagraph(next.highlightParagraph);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: curationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (curation) {
          if (curation == null) {
            return const Center(child: Text('Spot not found'));
          }
          // Rebuild paragraph keys when guide is loaded
          if (guideState.guide != null) {
            final paraCount = guideState.guide!.paragraphs.length;
            if (_paraKeys.length != paraCount) {
              _paraKeys
                ..clear()
                ..addAll(List.generate(paraCount, (_) => GlobalKey()));
            }
          }
          return _buildContent(context, curation, guideState);
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Curation curation, AudioGuideState guideState) {
    return Stack(
      children: [
        // ── Background image ─────────────────────────────────────────
        if (curation.imageUrls.isNotEmpty)
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: curation.imageUrls.first,
              fit: BoxFit.cover,
            ),
          ),
        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
        // ── Content ──────────────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, curation, guideState),
              Expanded(
                child: guideState.guide == null
                    ? _buildGeneratePrompt(context, curation, guideState)
                    : _buildPlayer(context, curation, guideState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(
      BuildContext context, Curation curation, AudioGuideState guideState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              ref.read(audioGuideProvider(widget.curationId).notifier).stop();
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('🎧 Audio Guide',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          // Language selector
          _LanguageButton(
            current: guideState.language,
            onChanged: (lang) {
              ref
                  .read(audioGuideProvider(widget.curationId).notifier)
                  .setLanguage(lang);
            },
          ),
        ],
      ),
    );
  }

  // ── Generate prompt ───────────────────────────────────────────────────────

  Widget _buildGeneratePrompt(
      BuildContext context, Curation curation, AudioGuideState guideState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎧', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            curation.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${curation.city}, Japan',
            style:
                const TextStyle(color: Colors.white54, fontSize: 15),
          ),
          const SizedBox(height: 32),
          if (guideState.isGenerating)
            Column(
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Crafting your audio guide…',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This takes about 10 seconds',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            )
          else ...[
            if (guideState.error != null) ...[
              Text(guideState.error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () => _checkAndGenerate(curation),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Audio Guide'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 52),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI-generated narration • ${_guideLanguages[guideState.language]} • ~2 min',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Player ────────────────────────────────────────────────────────────────

  Widget _buildPlayer(
      BuildContext context, Curation curation, AudioGuideState guideState) {
    final guide = guideState.guide!;
    return Column(
      children: [
        // Header
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Text(
                curation.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text('${curation.city}, Japan',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.timer_outlined,
                      size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                      '~${(guide.estimatedDurationSeconds / 60).round()} min',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  if (guideState.isCached) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Cached',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Script transcript
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 16),
            itemCount: guide.paragraphs.length,
            itemBuilder: (_, i) {
              final isHighlighted =
                  guideState.isPlaying &&
                      guideState.highlightParagraph == i;
              return _ParagraphTile(
                key: i < _paraKeys.length ? _paraKeys[i] : null,
                text: guide.paragraphs[i],
                isHighlighted: isHighlighted,
              );
            },
          ),
        ),
        // Controls
        _buildControls(guideState, curation),
      ],
    );
  }

  Widget _buildControls(AudioGuideState guideState, Curation curation) {
    final notifier =
        ref.read(audioGuideProvider(widget.curationId).notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Speed slider
          Row(
            children: [
              const Icon(Icons.slow_motion_video,
                  color: Colors.white54, size: 16),
              Expanded(
                child: Slider(
                  value: guideState.speechRate.clamp(0.4, 1.6),
                  min: 0.4,
                  max: 1.6,
                  divisions: 6,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => notifier.setSpeechRate(v),
                ),
              ),
              const Icon(Icons.fast_forward,
                  color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                '${guideState.speechRate.toStringAsFixed(2)}x',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop
              _ControlButton(
                icon: Icons.stop_rounded,
                size: 28,
                onTap: notifier.stop,
                color: Colors.white54,
              ),
              const SizedBox(width: 24),
              // Play / Pause
              _PlayButton(
                isPlaying: guideState.isPlaying,
                onPlay: notifier.play,
                onPause: notifier.pause,
              ),
              const SizedBox(width: 24),
              // Regenerate
              _ControlButton(
                icon: Icons.refresh,
                size: 24,
                onTap: () => notifier.regenerate(
                  title: curation.title,
                  description: curation.description,
                  city: curation.city,
                  category: curation.category,
                ),
                color: Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('✨ AI-generated narration',
              style:
                  TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ParagraphTile extends StatelessWidget {
  final String text;
  final bool isHighlighted;

  const _ParagraphTile({
    super.key,
    required this.text,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: isHighlighted
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isHighlighted ? Colors.white : Colors.white70,
          fontSize: isHighlighted ? 16 : 14,
          height: 1.7,
          fontWeight:
              isHighlighted ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  const _PlayButton({
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlaying ? onPause : onPlay,
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AppColors.primary,
          size: 40,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _LanguageButton({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: onChanged,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          _guideLanguages[current] ?? '🌐',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      itemBuilder: (_) => _guideLanguages.entries
          .map((e) => PopupMenuItem<String>(
                value: e.key,
                child: Text(e.value,
                    style: TextStyle(
                        color: e.key == current
                            ? AppColors.primary
                            : Colors.white)),
              ))
          .toList(),
    );
  }
}

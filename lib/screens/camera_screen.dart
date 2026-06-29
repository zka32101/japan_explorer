import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../models/rating.dart';
import '../providers/camera_provider.dart';
import '../providers/geofence_provider.dart';
import '../providers/plan_provider.dart';
import '../services/ai_vision_service.dart';
import '../services/claude_vision_service.dart';
import 'camera_history_screen.dart';
import '../widgets/badge_widget.dart';
import '../widgets/level_up_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  final _tts = FlutterTts();
  final _followUpController = TextEditingController();
  bool _isSpeaking = false;
  bool _showFollowUp = false;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.9);
  }

  @override
  void dispose() {
    _tts.stop();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final nearby = ref.read(nearbySpotProvider);
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(cameraNotifierProvider.notifier).analyzeImage(
          File(picked.path),
          nearbyCurationId: nearby.curationId,
          nearbyCurationName: nearby.spotName,
        );
  }

  Future<void> _toggleSpeech(CameraExplanation explanation) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    // Use the response language for TTS
    final lang = ref.read(cameraNotifierProvider).language;
    final ttsLang = switch (lang) {
      'ja' => 'ja-JP',
      'zh' => 'zh-CN',
      'ko' => 'ko-KR',
      'fr' => 'fr-FR',
      _ => 'en-US',
    };
    await _tts.setLanguage(ttsLang);

    final text = '''
${explanation.name}.
${explanation.description}
${explanation.historicalBackground}
${explanation.howToExperience}
''';
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraNotifierProvider);
    final nearby = ref.watch(nearbySpotProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
            SizedBox(width: 8),
            Text('AI Culture Lens'),
          ],
        ),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Scan History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CameraHistoryScreen()),
            ),
          ),
          if (cameraState.explanation != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(cameraNotifierProvider.notifier).reset();
                setState(() {
                  _showFollowUp = false;
                  _isSpeaking = false;
                });
                _tts.stop();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Language selector ──────────────────────────────────
              _buildLanguageSelector(cameraState),

              // ── Nearby spot banner ─────────────────────────────────
              if (nearby.isNearby && cameraState.explanation == null)
                _NearbyBanner(spotName: nearby.spotName!, distanceMeters: nearby.distanceMeters!),

              // ── Main content ───────────────────────────────────────
              Expanded(
                child: cameraState.isAnalyzing
                    ? _buildLoadingView(cameraState)
                    : cameraState.explanation != null
                        ? _buildResultView(cameraState)
                        : _buildCaptureView(cameraState),
              ),
            ],
          ),
          // ── Level-up overlay ────────────────────────────────────────
          if (cameraState.leveledUp && cameraState.newLevel != null)
            LevelUpOverlay(
              newLevel: cameraState.newLevel!,
              onDismiss: () =>
                  ref.read(cameraNotifierProvider.notifier).clearFeedback(),
            ),
          // ── Badge unlock overlay ─────────────────────────────────────
          if (!cameraState.leveledUp && cameraState.newBadgeIds.isNotEmpty)
            NewBadgeAnimation(
              badgeId: cameraState.newBadgeIds.first,
              onDismiss: () =>
                  ref.read(cameraNotifierProvider.notifier).clearFeedback(),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(CameraState cameraState) {
    return Container(
      height: 40,
      color: const Color(0xFF111111),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Text('Lang:',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: cameraLanguages.entries.map((e) {
                final isSelected = cameraState.language == e.key;
                return GestureDetector(
                  onTap: () =>
                      ref.read(cameraNotifierProvider.notifier).setLanguage(e.key),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white24,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(CameraState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            state.usedFallback
                ? 'Analyzing with Claude AI...'
                : 'Analyzing with Gemini AI...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Identifying cultural context',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureView(CameraState state) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (state.capturedImage != null)
                Positioned.fill(
                  child: Image.file(state.capturedImage!, fit: BoxFit.contain),
                )
              else
                _buildEmptyCameraView(),
              if (state.error != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildCaptureControls(),
      ],
    );
  }

  Widget _buildEmptyCameraView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.camera_alt, size: 64, color: Colors.white24),
        ),
        const SizedBox(height: 24),
        const Text(
          'Point at anything in Japan',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Shrines • Food • Signs • Art • Architecture',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCaptureControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.tips_and_updates_outlined,
            label: 'Tips',
            onTap: () => _showTipsDialog(context),
          ),
        ],
      ),
    );
  }

  void _showTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('AI Lens Tips',
            style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipRow('📸', 'Take clear, well-lit photos'),
            _TipRow('🎯', 'Focus on the main subject'),
            _TipRow('🗺️', 'Works on signs, food, architecture, art'),
            _TipRow('💬', 'Ask follow-up questions after scan'),
            _TipRow('📍', 'Walk near spots for auto-hints'),
            _TipRow('🌐', 'Change language in the top bar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(CameraState state) {
    final explanation = state.explanation!;
    return Column(
      children: [
        if (state.capturedImage != null)
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.file(state.capturedImage!, fit: BoxFit.cover),
          ),
        Expanded(
          child: Container(
            color: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameHeader(explanation, state),
                  const SizedBox(height: 16),
                  _buildAudioControls(explanation),
                  const SizedBox(height: 16),
                  _buildSection('About', explanation.description),
                  _buildSection('History', explanation.historicalBackground),
                  _buildSection('How to Experience', explanation.howToExperience),
                  _buildPhraseCard(explanation.phrase),
                  if (_showFollowUp) _buildFollowUpInput(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        _buildBottomActions(state),
      ],
    );
  }

  Widget _buildNameHeader(CameraExplanation explanation, CameraState state) {
    final isGemini = state.lastProvider == AiProvider.gemini;
    final badgeColor = isGemini ? const Color(0xFF4285F4) : AppColors.accent;
    final badgeLabel = isGemini ? 'Gemini Flash' : 'Claude AI';
    final badgeIcon = isGemini ? Icons.bolt : Icons.auto_awesome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                explanation.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(badgeLabel,
                      style: TextStyle(color: badgeColor, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        if (state.usedFallback)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Gemini unavailable — used Claude',
              style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.7), fontSize: 11),
            ),
          ),
        if (state.xpAwarded)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+50 XP earned',
                  style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.8),
                      fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAudioControls(CameraExplanation explanation) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleSpeech(explanation),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isSpeaking
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSpeaking ? AppColors.primary : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSpeaking ? Icons.stop : Icons.play_arrow,
                    color: _isSpeaking ? AppColors.primary : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSpeaking ? 'Stop Audio' : 'Play Audio',
                    style: TextStyle(
                        color: _isSpeaking ? AppColors.primary : Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _showFollowUp = !_showFollowUp),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _showFollowUp
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showFollowUp ? AppColors.secondary : Colors.white24,
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: _showFollowUp ? AppColors.secondary : Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(content,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.6)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhraseCard(JapanesePhrase phrase) {
    if (phrase.japanese.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.indigo.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🗣️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('Useful Japanese',
                  style: TextStyle(
                      color: AppColors.sakura,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(phrase.japanese,
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          Text(phrase.romaji,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(phrase.english,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFollowUpInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask AI a question',
              style: TextStyle(color: AppColors.secondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _followUpController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. When was this built?',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_followUpController.text.trim().isEmpty) return;
                  ref
                      .read(cameraNotifierProvider.notifier)
                      .askFollowUp(_followUpController.text.trim());
                  _followUpController.clear();
                },
                child: const Icon(Icons.send, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CameraState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(cameraNotifierProvider.notifier).reset();
                setState(() => _showFollowUp = false);
                _tts.stop();
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white70),
              label: const Text('New Photo',
                  style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddToPlanSheet(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Add to Plan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToPlanSheet(BuildContext context, CameraState cameraState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddToPlanSheet(
        landmarkName: cameraState.explanation?.name ?? '',
        imageUrl: cameraState.capturedImage?.path,
        onAdded: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to plan! 🗺️')),
        ),
      ),
    );
  }
}

// ── Add to Plan Bottom Sheet ─────────────────────────────────────────────────

class _AddToPlanSheet extends ConsumerWidget {
  final String landmarkName;
  final String? imageUrl;
  final VoidCallback? onAdded;

  const _AddToPlanSheet({
    required this.landmarkName,
    this.imageUrl,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planNotifierProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add "$landmarkName" to plan',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
            error: (_, __) => const Text('Failed to load plans',
                style: TextStyle(color: Colors.white54)),
            data: (plans) => Column(
              children: [
                // Existing plans
                ...plans.map(
                  (plan) => ListTile(
                    leading:
                        const Icon(Icons.map_outlined, color: AppColors.accent),
                    title: Text(plan.title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${plan.spots.length} spots',
                        style: const TextStyle(color: Colors.white54)),
                    onTap: () async {
                      final spot = PlanSpot(
                        curationId: '',
                        curationTitle: landmarkName,
                        imageUrl: imageUrl,
                        order: plan.spots.length,
                      );
                      await ref
                          .read(planNotifierProvider.notifier)
                          .addSpotToPlan(plan.id, spot);
                      if (context.mounted) Navigator.pop(context);
                      onAdded?.call();
                    },
                  ),
                ),
                const Divider(color: Colors.white12),
                // Create new plan
                ListTile(
                  leading:
                      const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                  title: const Text('Create new plan',
                      style: TextStyle(color: AppColors.secondary)),
                  onTap: () => _createAndAdd(context, ref, plans.length),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAndAdd(
      BuildContext context, WidgetRef ref, int planCount) async {
    final controller = TextEditingController(
        text: 'Trip Plan ${planCount + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Plan name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    // createPlan awaits its own _load(), so state is current when it returns
    await ref.read(planNotifierProvider.notifier).createPlan(name);
    final plans = ref.read(planNotifierProvider).valueOrNull ?? [];
    if (plans.isEmpty) return;
    // Newest plan is first (Firestore orders by updated_at DESC)
    final newPlan = plans.first;
    final spot = PlanSpot(
      curationId: '',
      curationTitle: landmarkName,
      imageUrl: imageUrl,
      order: 0,
    );
    await ref
        .read(planNotifierProvider.notifier)
        .addSpotToPlan(newPlan.id, spot);

    if (context.mounted) Navigator.pop(context);
    onAdded?.call();
  }
}

// ── Nearby Spot Banner ───────────────────────────────────────────────────────

class _NearbyBanner extends StatelessWidget {
  final String spotName;
  final double distanceMeters;

  const _NearbyBanner({required this.spotName, required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '📍 ${distanceMeters.round()}m away: $spotName',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.camera_alt, color: AppColors.accent, size: 14),
        ],
      ),
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _TipRow(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

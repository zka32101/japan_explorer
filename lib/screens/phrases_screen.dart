import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../config/theme.dart';
import '../models/phrase_category.dart';

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen>
    with SingleTickerProviderStateMixin {
  final _tts = FlutterTts();
  final _searchController = TextEditingController();
  late final TabController _tabController;

  String _searchQuery = '';
  String? _speakingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TravelPhrases.categories.length,
      vsync: this,
    );
    _tts.setLanguage('ja-JP');
    _tts.setSpeechRate(0.7);
    _tts.setCompletionHandler(() => setState(() => _speakingId = null));
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _speak(TravelPhrase phrase) async {
    if (_speakingId == phrase.id) {
      await _tts.stop();
      setState(() => _speakingId = null);
      return;
    }
    setState(() => _speakingId = phrase.id);
    await _tts.speak(phrase.japanese);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🇯🇵', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('Japanese Phrasebook'),
          ],
        ),
        bottom: isSearching
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: TravelPhrases.categories
                    .map((c) => Tab(text: '${c.emoji} ${c.title}'))
                    .toList(),
              ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search phrases...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: isSearching
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: TravelPhrases.categories
                        .map((cat) => _PhraseList(
                              phrases: cat.phrases,
                              speakingId: _speakingId,
                              onSpeak: _speak,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = TravelPhrases.search(_searchQuery);
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No phrases found for "$_searchQuery"',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return _PhraseList(
      phrases: results,
      speakingId: _speakingId,
      onSpeak: _speak,
    );
  }
}

class _PhraseList extends StatelessWidget {
  final List<TravelPhrase> phrases;
  final String? speakingId;
  final Future<void> Function(TravelPhrase) onSpeak;

  const _PhraseList({
    required this.phrases,
    required this.speakingId,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: phrases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PhraseCard(
        phrase: phrases[i],
        isSpeaking: speakingId == phrases[i].id,
        onSpeak: () => onSpeak(phrases[i]),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final TravelPhrase phrase;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  const _PhraseCard({
    required this.phrase,
    required this.isSpeaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSpeaking
            ? AppColors.primary.withValues(alpha: 0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpeaking
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.transparent,
          width: isSpeaking ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Japanese + romaji
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase.japanese,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phrase.romaji,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // TTS button
                GestureDetector(
                  onTap: onSpeak,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSpeaking
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSpeaking ? Icons.stop : Icons.volume_up,
                      color: isSpeaking ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              phrase.english,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            if (phrase.usageNote != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      phrase.usageNote!,
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

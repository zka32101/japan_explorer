import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../utils/constants.dart';
import '../widgets/cached_image.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('journal.title')),
      ),
      body: journalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : journalState.entries.isEmpty
              ? _EmptyJournal()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(journalProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: journalState.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _JournalCard(
                      entry: journalState.entries[i],
                    ),
                  ),
                ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyJournal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text(tr('journal.empty_title'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(tr('journal.empty_body'),
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.explore_outlined),
              label: Text(tr('journal.explore_cta')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journal card ──────────────────────────────────────────────────────────────

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '${AppRoutes.journalEntry}/${entry.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: CachedImage(
                  url: entry.imageUrl,
                  height: 160,
                  width: double.infinity,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.mood.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.curationTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(entry.visitDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12),
                      ),
                    ],
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          height: 1.5,
                          color: AppColors.textSecondary,
                          fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

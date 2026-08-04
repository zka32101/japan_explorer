import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/user_contribution.dart';
import '../providers/community_contributions_provider.dart';

class CommunityContributionsScreen extends ConsumerWidget {
  const CommunityContributionsScreen({
    super.key,
    required this.analysisType,
    required this.title,
  });

  final String analysisType;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CommunityContributionsParams(
      analysisType: analysisType,
      title: title,
    );
    final state = ref.watch(communityContributionsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('community_contributions.title')),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(communityContributionsProvider(params).notifier).load(),
        child: state.isLoading && state.contributions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.contributions.isEmpty
                ? _EmptyState(title: title)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    itemCount: state.contributions.length,
                    itemBuilder: (ctx, i) => _ContributionCard(
                      contribution: state.contributions[i],
                      hasVoted:
                          state.votedIds.contains(state.contributions[i].id),
                      onVote: () => ref
                          .read(communityContributionsProvider(params)
                              .notifier)
                          .toggleVote(state.contributions[i].id),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShareAnswerSheet(context, ref, params),
        icon: const Icon(Icons.add),
        label: Text(tr('community_contributions.share_answer')),
      ),
    );
  }

  void _showShareAnswerSheet(
    BuildContext context,
    WidgetRef ref,
    CommunityContributionsParams params,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ShareAnswerSheet(params: params),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              tr('community_contributions.no_answers'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr('community_contributions.be_first'),
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contribution card ────────────────────────────────────────────────────────

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.contribution,
    required this.hasVoted,
    required this.onVote,
  });

  final UserContribution contribution;
  final bool hasVoted;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: contribution.userAvatarUrl.isNotEmpty
                      ? NetworkImage(contribution.userAvatarUrl)
                      : null,
                  child: contribution.userAvatarUrl.isEmpty
                      ? Text(contribution.userName.isNotEmpty
                          ? contribution.userName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contribution.userName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (contribution.creatorRevenueUsd != null)
                  Text(
                    tr('community_contributions.creator_earned',
                        args: [
                          contribution.creatorRevenueUsd!
                              .toStringAsFixed(2)
                        ]),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (contribution.answerTitle.isNotEmpty) ...[
              Text(
                contribution.answerTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            Text(contribution.description),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onVote,
              icon: Icon(
                hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
                color: hasVoted ? AppColors.primary : AppColors.textSecondary,
              ),
              label: Text(
                '${hasVoted ? tr('community_contributions.you_voted') : tr('community_contributions.helpful')} · '
                '${tr('community_contributions.vote_count', args: ['${contribution.voteCount}'])}',
                style: TextStyle(
                    color:
                        hasVoted ? AppColors.primary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share answer bottom sheet ───────────────────────────────────────────────

class _ShareAnswerSheet extends ConsumerStatefulWidget {
  const _ShareAnswerSheet({required this.params});
  final CommunityContributionsParams params;

  @override
  ConsumerState<_ShareAnswerSheet> createState() => _ShareAnswerSheetState();
}

class _ShareAnswerSheetState extends ConsumerState<_ShareAnswerSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('community_contributions.fill_all_fields'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(communityContributionsProvider(widget.params).notifier)
        .submit(title: _titleCtrl.text, description: _descCtrl.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('community_contributions.thank_you'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('community_contributions.share_answer'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: tr('community_contributions.title_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: tr('community_contributions.description_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('community_contributions.submit')),
          ),
        ],
      ),
    );
  }
}

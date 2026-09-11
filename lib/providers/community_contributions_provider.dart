import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_contribution.dart';
import '../utils/firestore_instance.dart';

class CommunityContributionsParams {
  const CommunityContributionsParams({
    required this.analysisType,
    required this.title,
  });

  final String analysisType;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is CommunityContributionsParams &&
      other.analysisType == analysisType &&
      other.title == title;

  @override
  int get hashCode => Object.hash(analysisType, title);
}

class CommunityContributionsState {
  const CommunityContributionsState({
    this.contributions = const [],
    this.votedIds = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<UserContribution> contributions;
  final Set<String> votedIds;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  CommunityContributionsState copyWith({
    List<UserContribution>? contributions,
    Set<String>? votedIds,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) =>
      CommunityContributionsState(
        contributions: contributions ?? this.contributions,
        votedIds: votedIds ?? this.votedIds,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );
}

class CommunityContributionsNotifier
    extends StateNotifier<CommunityContributionsState> {
  CommunityContributionsNotifier(this._params)
      : super(const CommunityContributionsState()) {
    load();
  }

  final CommunityContributionsParams _params;
  final _col = db.collection('user_contributions');

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snap = await _col
          .where('analysisType', isEqualTo: _params.analysisType)
          .where('title', isEqualTo: _params.title)
          .orderBy('voteCount', descending: true)
          .get();

      final contributions = snap.docs
          .map((d) => UserContribution.fromMap({...d.data(), 'id': d.id}))
          .toList();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final votedIds = <String>{};
      if (uid != null && contributions.isNotEmpty) {
        final futures = contributions
            .map((c) => db
                .collection('contribution_votes')
                .doc('${uid}_${c.id}')
                .get());
        final results = await Future.wait(futures);
        for (var i = 0; i < contributions.length; i++) {
          if (results[i].exists) votedIds.add(contributions[i].id);
        }
      }

      state = state.copyWith(
        contributions: contributions,
        votedIds: votedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submit({
    required String title,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (title.trim().isEmpty || description.trim().isEmpty) return false;

    state = state.copyWith(isSubmitting: true);
    try {
      final docRef = _col.doc();
      final contribution = UserContribution(
        id: docRef.id,
        userId: user.uid,
        userName: user.displayName ?? 'Explorer',
        userAvatarUrl: user.photoURL ?? '',
        imageHash: '',
        analysisType: _params.analysisType,
        // `title` is the grouping key the load() query filters on — it must
        // stay equal to _params.title. The user's own headline goes in
        // `answerTitle` so their submission still matches on reload.
        title: _params.title,
        answerTitle: title.trim(),
        description: description.trim(),
        imageUrl: '',
        voteCount: 0,
        isBeingEditedByUser: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(contribution.toMap());

      state = state.copyWith(
        contributions: [contribution, ...state.contributions],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<void> toggleVote(String contributionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final idx = state.contributions.indexWhere((c) => c.id == contributionId);
    if (idx == -1) return;
    final alreadyVoted = state.votedIds.contains(contributionId);

    // Optimistic update
    final updated = List<UserContribution>.from(state.contributions);
    final target = updated[idx];
    updated[idx] = UserContribution(
      id: target.id,
      userId: target.userId,
      userName: target.userName,
      userAvatarUrl: target.userAvatarUrl,
      imageHash: target.imageHash,
      analysisType: target.analysisType,
      title: target.title,
      answerTitle: target.answerTitle,
      description: target.description,
      imageUrl: target.imageUrl,
      voteCount: target.voteCount + (alreadyVoted ? -1 : 1),
      isBeingEditedByUser: target.isBeingEditedByUser,
      createdAt: target.createdAt,
      creatorRevenueUsd: target.creatorRevenueUsd,
    );
    final updatedVotedIds = Set<String>.from(state.votedIds);
    if (alreadyVoted) {
      updatedVotedIds.remove(contributionId);
    } else {
      updatedVotedIds.add(contributionId);
    }
    state = state.copyWith(contributions: updated, votedIds: updatedVotedIds);

    try {
      // Only the vote document is written client-side. user_contributions is
      // immutable to clients; voteCount is recomputed server-side by the
      // aggregateContributionVotes Cloud Function. The local voteCount above
      // is an optimistic estimate that reconciles on the next load().
      final voteRef =
          db.collection('contribution_votes').doc('${uid}_$contributionId');

      if (alreadyVoted) {
        await voteRef.delete();
      } else {
        await voteRef.set({
          'contributionId': contributionId,
          'userId': uid,
          'voteValue': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Rollback on error
      state = state.copyWith(
        contributions: state.contributions
            .map((c) => c.id == contributionId ? target : c)
            .toList(),
        votedIds: Set<String>.from(state.votedIds)
          ..removeWhere((id) => id == contributionId)
          ..addAll(alreadyVoted ? {contributionId} : {}),
      );
    }
  }
}

final communityContributionsProvider = StateNotifierProvider.family<
    CommunityContributionsNotifier,
    CommunityContributionsState,
    CommunityContributionsParams>(
  (ref, params) => CommunityContributionsNotifier(params),
);

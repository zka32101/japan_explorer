const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Recomputes user_contributions.voteCount whenever a vote is added or removed.
// Clients can only write their own contribution_votes doc (rules-enforced);
// the authoritative count is derived here with Admin privileges, since
// user_contributions is immutable to clients.
exports.aggregateContributionVotes = onDocumentWritten(
  { document: 'contribution_votes/{voteId}', region: 'asia-northeast1' },
  async (event) => {
    const data = event.data.after.exists ? event.data.after.data() : event.data.before.data();
    if (!data || !data.contributionId) return;

    const contributionId = data.contributionId;
    const votesSnap = await db
      .collection('contribution_votes')
      .where('contributionId', '==', contributionId)
      .get();

    // The contribution may have been deleted — ignore the failed update.
    await db
      .collection('user_contributions')
      .doc(contributionId)
      .update({ voteCount: votesSnap.size })
      .catch(() => {});
  }
);

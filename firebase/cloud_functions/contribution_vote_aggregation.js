const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

if (!admin.apps.length) admin.initializeApp();
// This app hosts multiple projects on one Firebase project (app1-6c108) —
// Japan Explorer uses its own named database, not "(default)".
const db = getFirestore(admin.app(), 'japanexplorer');

// Recomputes user_contributions.voteCount whenever a vote is added or removed.
// Clients can only write their own contribution_votes doc (rules-enforced);
// the authoritative count is derived here with Admin privileges, since
// user_contributions is immutable to clients.
exports.aggregateContributionVotes = onDocumentWritten(
  { document: 'contribution_votes/{voteId}', database: 'japanexplorer', region: 'asia-northeast1' },
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

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

if (!admin.apps.length) admin.initializeApp();
// This app hosts multiple projects on one Firebase project (app1-6c108) —
// Japan Explorer uses its own named database, not "(default)".
const db = getFirestore(admin.app(), 'japanexplorer');

const REFERRAL_XP_BONUS = 200;
const AMBASSADOR_BADGE = 'ambassador';

// Grants the referral XP bonus to both inviter and invitee, and unlocks the
// inviter's "ambassador" badge on their first successful referral.
// Runs with Admin privileges so it can write to the inviter's user
// document — a client can only ever write its own.
exports.grantReferralReward = onDocumentCreated(
  { document: 'referrals/{referralId}', database: 'japanexplorer', region: 'asia-northeast1' },
  async (event) => {
    const snap = event.data;
    const { inviter_uid: inviterUid, invitee_uid: inviteeUid } = snap.data();
    if (!inviterUid || !inviteeUid || inviterUid === inviteeUid) return;

    const inviteeRef = db.collection('users').doc(inviteeUid);
    const inviterRef = db.collection('users').doc(inviterUid);

    await db.runTransaction(async (tx) => {
      const [inviteeSnap, inviterSnap] = await Promise.all([
        tx.get(inviteeRef),
        tx.get(inviterRef),
      ]);

      // Idempotency / anti-abuse: only the invitee's first redeemed code counts.
      if (inviteeSnap.exists && inviteeSnap.data().referred_by) return;

      // set(..., {merge:true}) rather than update() so a reward is never
      // silently dropped when a user doc hasn't been created yet (e.g. redeem
      // immediately after sign-up).
      tx.set(
        inviteeRef,
        {
          referred_by: inviterUid,
          xp: admin.firestore.FieldValue.increment(REFERRAL_XP_BONUS),
        },
        { merge: true },
      );

      const inviterUpdate = {
        xp: admin.firestore.FieldValue.increment(REFERRAL_XP_BONUS),
        badges: admin.firestore.FieldValue.arrayUnion(AMBASSADOR_BADGE),
      };
      tx.set(inviterRef, inviterUpdate, { merge: true });
    });
  }
);

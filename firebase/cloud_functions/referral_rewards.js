const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const REFERRAL_XP_BONUS = 200;
const AMBASSADOR_BADGE = 'ambassador';

// Grants the referral XP bonus to both inviter and invitee, and unlocks the
// inviter's "ambassador" badge on their first successful referral.
// Runs with Admin privileges so it can write to the inviter's user
// document — a client can only ever write its own.
exports.grantReferralReward = functions.firestore
  .document('referrals/{referralId}')
  .onCreate(async (snap) => {
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
  });

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const BATCH = 400;
// A deletion is only accepted shortly after the user signed in again, so a
// stolen/old session cannot wipe an account.
const MAX_AUTH_AGE_SECONDS = 300;

/** Deletes every document matching [query] in batches; returns the count. */
async function deleteWhere(query) {
  let total = 0;
  for (;;) {
    const snap = await query.limit(BATCH).get();
    if (snap.empty) return total;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < BATCH) return total;
  }
}

/** Deletes matching docs together with their subcollections (e.g. post comments). */
async function recursiveDeleteWhere(query) {
  let total = 0;
  for (;;) {
    const snap = await query.limit(BATCH).get();
    if (snap.empty) return total;
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
    total += snap.size;
    if (snap.size < BATCH) return total;
  }
}

/** Decrements a counter on the parent posts, ignoring posts that are already gone. */
async function decrementPostCounters(countsByPost, field) {
  await Promise.all(
    Object.entries(countsByPost).map(async ([postId, n]) => {
      try {
        await db
          .collection('posts')
          .doc(postId)
          .update({ [field]: admin.firestore.FieldValue.increment(-n) });
      } catch (_) {
        // Parent post deleted in the meantime.
      }
    }),
  );
}

async function deleteLikes(uid) {
  const counts = {};
  const snap = await db.collection('post_likes').where('uid', '==', uid).get();
  const batch = db.batch();
  snap.docs.forEach((d) => {
    const postId = d.get('post_id');
    if (postId) counts[postId] = (counts[postId] || 0) + 1;
    batch.delete(d.ref);
  });
  if (!snap.empty) await batch.commit();
  await decrementPostCounters(counts, 'like_count');
  return snap.size;
}

// Needs the collection-group index on comments.author_id (firestore.indexes.json).
async function deleteComments(uid) {
  const counts = {};
  const snap = await db.collectionGroup('comments').where('author_id', '==', uid).get();
  const batch = db.batch();
  snap.docs.forEach((d) => {
    const postId = d.ref.parent.parent && d.ref.parent.parent.id;
    if (postId) counts[postId] = (counts[postId] || 0) + 1;
    batch.delete(d.ref);
  });
  if (!snap.empty) await batch.commit();
  await decrementPostCounters(counts, 'comment_count');
  return snap.size;
}

async function deleteStorage(uid) {
  const bucket = admin.storage().bucket();
  for (const prefix of ['users', 'hosts', 'posts', 'avatars', 'journal']) {
    await bucket.deleteFiles({ prefix: `${prefix}/${uid}/`, force: true });
  }
}

/**
 * Deletes the signed-in user's account and everything tied to it: Firestore
 * data (profile, posts, ratings, plans, host profile & requests, referral
 * records, contributions & votes, journal), Storage files and the Auth user.
 * Idempotent: if it fails half-way, calling it again finishes the job.
 */
exports.deleteAccount = onCall({ region: 'asia-northeast1', timeoutSeconds: 300 }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'sign-in-required');
  const uid = request.auth.uid;

  const authTime = request.auth.token.auth_time;
  if (!authTime || Date.now() / 1000 - authTime > MAX_AUTH_AGE_SECONDS) {
    throw new HttpsError('failed-precondition', 'recent-login-required');
  }

  const warnings = [];
  const step = async (name, fn) => {
    try {
      await fn();
    } catch (e) {
      console.error(`deleteAccount ${name} failed for ${uid}`, e);
      warnings.push(name);
    }
  };

  await step('post_likes', () => deleteLikes(uid));
  await step('comments', () => deleteComments(uid));
  await step('posts', async () => {
    await recursiveDeleteWhere(db.collection('posts').where('author_id', '==', uid));
    await recursiveDeleteWhere(db.collection('posts').where('user_id', '==', uid));
  });
  await step('ratings', () => deleteWhere(db.collection('ratings').where('user_id', '==', uid)));
  await step('plans', () => deleteWhere(db.collection('plans').where('user_id', '==', uid)));
  await step('user_contributions', () =>
    deleteWhere(db.collection('user_contributions').where('userId', '==', uid)));
  await step('contribution_votes', () =>
    deleteWhere(db.collection('contribution_votes').where('userId', '==', uid)));
  await step('host_requests', async () => {
    await deleteWhere(db.collection('host_requests').where('guest_uid', '==', uid));
    await deleteWhere(db.collection('host_requests').where('host_uid', '==', uid));
  });
  await step('hosts', () => db.recursiveDelete(db.collection('hosts').doc(uid)));
  await step('referral_codes', () => deleteWhere(db.collection('referral_codes').where('uid', '==', uid)));
  await step('referrals', async () => {
    await db.collection('referrals').doc(uid).delete();
    // Keep other users' redemption records, but drop the link to this account.
    const asInviter = await db.collection('referrals').where('inviter_uid', '==', uid).get();
    const batch = db.batch();
    asInviter.docs.forEach((d) => batch.update(d.ref, { inviter_uid: 'deleted_user' }));
    if (!asInviter.empty) await batch.commit();
  });
  await step('storage', () => deleteStorage(uid));
  await step('user', () => db.recursiveDelete(db.collection('users').doc(uid)));

  // Only remove the Auth user once the profile is gone; otherwise the user
  // could not sign in again to retry.
  if (warnings.includes('user')) throw new HttpsError('internal', 'partial-failure');
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') {
      console.error(`deleteAccount auth failed for ${uid}`, e);
      throw new HttpsError('internal', 'auth-delete-failed');
    }
  }
  return { ok: true, warnings };
});

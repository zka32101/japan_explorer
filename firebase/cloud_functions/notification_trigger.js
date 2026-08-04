const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

const db = admin.firestore();
const messaging = admin.messaging();

exports.sendDailyPhrase = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async () => {
    const phrasesSnapshot = await db.collection('phrases')
      .orderBy('created_at')
      .limit(1)
      .get();

    if (phrasesSnapshot.empty) return;
    const phrase = phrasesSnapshot.docs[0].data();

    const message = {
      notification: {
        title: 'Daily Japanese Phrase',
        body: `${phrase.japanese} — ${phrase.english}`,
      },
      topic: 'daily_phrase',
    };

    await messaging.send(message);
  });

// NOTE: Streak calculation is now handled entirely by StreakNotifier
// (streak_provider.dart) on the client side, including recovery logic.
// This Cloud Function acts only as a safety-net to reset streak_days
// when the app hasn't been opened for 3+ days (e.g. user reinstalled,
// or direct Firestore writes from admin tools).
// It deliberately does NOT interfere with normal 1-day gaps, which
// streak_provider handles with optional recovery.
exports.updateStreak = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only act when last_active_date actually changed
    if (before.last_active_date?.toMillis() === after.last_active_date?.toMillis()) return;

    // If streak_days was just written by the client, trust it
    if (before.streak_days !== after.streak_days) return;

    const lastActive = after.last_active_date?.toDate();
    if (!lastActive) return;

    const now = new Date();
    const diffDays = Math.floor((now - lastActive) / (1000 * 60 * 60 * 24));

    // Safety-net: reset only after a 3+ day absence (not 1-day gaps)
    if (diffDays >= 3) {
      await change.after.ref.update({ streak_days: 1 });
      console.log(`Streak reset for user ${context.params.userId} after ${diffDays}-day absence`);
    }
  });

/**
 * badge_notifications.js
 * Triggered when a user document is updated — sends a push notification
 * when new badges are unlocked (new_badges field is set).
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin only once across all functions
if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Firestore trigger: users/{userId}
 * Fires when new_badges field appears, sends FCM to the user's device.
 */
exports.onBadgeUnlock = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    const newBadges = after.new_badges;
    if (!newBadges || !newBadges.length) return null;

    // Clear the ephemeral field so it doesn't re-trigger
    await change.after.ref.update({ new_badges: admin.firestore.FieldValue.delete() });

    const fcmToken = after.fcm_token;
    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return null;
    }

    const badgeLabels = newBadges.map(getBadgeLabel).join(', ');
    const count = newBadges.length;
    const title = count === 1
      ? `🏅 Badge Unlocked: ${getBadgeLabel(newBadges[0])}!`
      : `🏅 ${count} Badges Unlocked!`;
    const body = count === 1
      ? getBadgeDescription(newBadges[0])
      : `You earned: ${badgeLabels}`;

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        type: 'badge_unlock',
        badge_ids: newBadges.join(','),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          channelId: 'badges',
          icon: 'ic_notification',
          color: '#E63946',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'badge_unlock.caf',
          },
        },
      },
    };

    try {
      const response = await messaging.send(message);
      console.log(`Badge notification sent to ${userId}: ${response}`);
    } catch (err) {
      console.error(`Failed to send badge notification to ${userId}:`, err.message);
    }

    return null;
  });

// ── Daily streak reminder ────────────────────────────────────────────
/**
 * Scheduled: every day at 18:00 JST (09:00 UTC)
 * Sends a reminder to users who haven't opened the app today.
 */
exports.dailyStreakReminder = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async (_context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    // Find users whose last_activity_date is exactly yesterday
    const yesterdayStart = new Date(yesterday);
    yesterdayStart.setHours(0, 0, 0, 0);
    const yesterdayEnd = new Date(yesterday);
    yesterdayEnd.setHours(23, 59, 59, 999);

    const snapshot = await db.collection('users')
      .where('last_activity_date', '>=', admin.firestore.Timestamp.fromDate(yesterdayStart))
      .where('last_activity_date', '<=', admin.firestore.Timestamp.fromDate(yesterdayEnd))
      .where('streak_days', '>=', 1)
      .get();

    if (snapshot.empty) {
      console.log('No streak reminders to send today');
      return null;
    }

    const messages = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      if (!data.fcm_token) return;

      const streak = data.streak_days || 0;
      const msg = {
        token: data.fcm_token,
        notification: {
          title: `🔥 Keep your ${streak}-day streak alive!`,
          body: "Open Japan Explorer today to continue your streak.",
        },
        data: {
          type: 'streak_reminder',
          streak_days: String(streak),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };
      messages.push(msg);
    });

    if (!messages.length) return null;

    // Send in batches of 500 (FCM limit)
    const batchSize = 500;
    for (let i = 0; i < messages.length; i += batchSize) {
      const batch = messages.slice(i, i + batchSize);
      const result = await messaging.sendEach(batch);
      console.log(
        `Streak reminders: ${result.successCount} sent, ${result.failureCount} failed`
      );
    }

    return null;
  });

// ── Badge label helpers ──────────────────────────────────────────────

function getBadgeLabel(id) {
  const labels = {
    first_visit: 'First Visit',
    photo_lover: 'Photo Lover',
    streak_7: '7-Day Streak',
    streak_30: '30-Day Streak',
    rater_10: 'Super Rater',
    planner: 'Trip Planner',
    culture_fan: 'Culture Fan',
    foodie: 'Foodie',
    ai_explorer: 'AI Explorer',
    level_5: 'Level 5',
    level_7: 'Level 7',
    japan_master: 'Japan Master',
  };
  return labels[id] || id;
}

function getBadgeDescription(id) {
  const desc = {
    first_visit: 'You explored your first Japan spot!',
    photo_lover: 'You\'ve shared 5 photos of Japan!',
    streak_7: 'You\'ve used Japan Explorer 7 days in a row!',
    streak_30: 'Incredible! 30-day streak achieved!',
    rater_10: 'You\'ve rated 10 spots — great contributions!',
    planner: 'You created your first travel plan!',
    culture_fan: 'A true fan of Japanese culture!',
    foodie: 'You\'ve explored Japan\'s culinary scene!',
    ai_explorer: 'You\'ve used Camera AI to discover Japan!',
    level_5: 'You reached Level 5 — keep going!',
    level_7: 'Level 7 achieved — you\'re almost a Japan Master!',
    japan_master: '🎌 Japan Master — the highest honor!',
  };
  return desc[id] || 'You unlocked a new achievement!';
}

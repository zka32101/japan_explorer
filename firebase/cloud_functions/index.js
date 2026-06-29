const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();

const { aggregateRatings } = require('./rating_aggregation');
const { moderatePost } = require('./content_moderation');
const { sendDailyPhrase, updateStreak } = require('./notification_trigger');
const { onBadgeUnlock, dailyStreakReminder } = require('./badge_notifications');

exports.aggregateRatings = aggregateRatings;
exports.moderatePost = moderatePost;
exports.sendDailyPhrase = sendDailyPhrase;
exports.updateStreak = updateStreak;
exports.onBadgeUnlock = onBadgeUnlock;
exports.dailyStreakReminder = dailyStreakReminder;

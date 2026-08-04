const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Anthropic = require('@anthropic-ai/sdk');

const db = admin.firestore();
const gemini = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const claude = new Anthropic.Anthropic({ apiKey: process.env.CLAUDE_API_KEY });

const MODERATION_PROMPT = `Moderate this user post for a Japan travel community app.
Check for: spam, hate speech, adult content, violence, off-topic content.
Respond ONLY in JSON (no markdown): {"status": "approved"|"flagged"|"rejected", "score": 0.0-1.0, "reason": "brief reason"}`;

exports.moderatePost = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const postId = context.params.postId;

    try {
      const result = await moderateWithFallback(post.text);

      await snap.ref.update({
        moderation_status: result.status,
        moderation_reason: result.reason,
        moderation_score: result.score,
        moderation_provider: result.provider,
        moderated_at: admin.firestore.FieldValue.serverTimestamp(),
        is_visible: result.status === 'approved',
      });

      if (result.status === 'rejected') {
        await notifyUser(post.user_id, postId, result.reason);
      }
    } catch (error) {
      console.error('Moderation failed entirely:', error);
      await snap.ref.update({ moderation_status: 'pending' });
    }
  });

async function moderateWithFallback(text) {
  // 1st: Gemini Flash（廉価）
  try {
    const result = await moderateWithGemini(text);
    console.log('Moderation by Gemini Flash');
    return { ...result, provider: 'gemini' };
  } catch (e) {
    if (!isFallbackRequired(e)) throw e;
    console.warn(`Gemini failed (${e.message}), falling back to Claude...`);
  }

  // 2nd: Claude Haiku（フォールバック）
  const result = await moderateWithClaude(text);
  console.log('Moderation by Claude (fallback)');
  return { ...result, provider: 'claude' };
}

async function moderateWithGemini(text) {
  const model = gemini.getGenerativeModel({ model: 'gemini-3.1-flash-lite' });
  const prompt = `${MODERATION_PROMPT}\n\nPost: "${text}"`;
  const response = await model.generateContent(prompt);
  return parseJson(response.response.text());
}

async function moderateWithClaude(text) {
  const response = await claude.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 150,
    system: MODERATION_PROMPT,
    messages: [{ role: 'user', content: `Post: "${text}"` }],
  });
  return parseJson(response.content[0].text);
}

function parseJson(raw) {
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) return { status: 'flagged', score: 0.5, reason: 'parse error' };
  try {
    return JSON.parse(match[0]);
  } catch {
    return { status: 'flagged', score: 0.5, reason: 'parse error' };
  }
}

function isFallbackRequired(error) {
  // HTTP 429 (rate limit), 5xx (server error), 403 (quota/key) → fallback
  const status = error?.status || error?.httpErrorCode?.status;
  if (!status) return true;
  return status === 429 || status === 403 || status >= 500;
}

async function notifyUser(userId, postId, reason) {
  const userDoc = await db.collection('users').doc(userId).get();
  const token = userDoc.data()?.fcm_token;
  if (!token) return;

  await admin.messaging().send({
    token,
    notification: {
      title: 'Post removed',
      body: `Your post was removed: ${reason}`,
    },
    data: { post_id: postId, type: 'moderation' },
  });
}

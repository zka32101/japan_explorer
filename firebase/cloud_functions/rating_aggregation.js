const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.aggregateRatings = onDocumentWritten(
  { document: 'ratings/{ratingId}', region: 'asia-northeast1' },
  async (event) => {
    const data = event.data.after.exists ? event.data.after.data() : null;
    if (!data) return;

    const curationId = data.curation_id;
    const ratingsSnapshot = await db.collection('ratings')
      .where('curation_id', '==', curationId)
      .get();

    const ratings = ratingsSnapshot.docs.map(doc => doc.data());
    const wantToGoValues = ratings.map(r => r.want_to_go);
    const recommendValues = ratings.map(r => r.recommend);

    const filteredWantToGo = removeOutliers(wantToGoValues);
    const filteredRecommend = removeOutliers(recommendValues);

    const avgWantToGo = average(filteredWantToGo);
    const avgRecommend = average(filteredRecommend);

    await db.collection('curations').doc(curationId).update({
      avg_want_to_go: avgWantToGo,
      avg_recommend: avgRecommend,
      total_ratings: ratings.length,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

function removeOutliers(values) {
  if (values.length < 5) return values;

  const mean = average(values);
  const stdDev = standardDeviation(values, mean);
  return values.filter(v => Math.abs(v - mean) <= 2 * stdDev);
}

function average(values) {
  if (values.length === 0) return 0;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

function standardDeviation(values, mean) {
  const variance = values.reduce((acc, v) => acc + Math.pow(v - mean, 2), 0) / values.length;
  return Math.sqrt(variance);
}

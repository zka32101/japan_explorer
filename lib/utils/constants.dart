class AppConstants {
  static const appName = 'Japan Explorer';
  static const appVersion = '1.0.0';

  static const pageSize = 20;
  static const searchDebounceMs = 500;
  static const geofenceRadiusMeters = 200.0;
  static const imageMaxSizeBytes = 1024 * 1024; // 1MB

  static const streakRecoveryPerMonth = 1;

  static const xpPhraseLearn = 10;
  static const xpSpotVisit = 50;
  static const xpReviewPost = 20;
  static const xpPhotoUpload = 30;
  static const xpStreakWeek = 100;
  static const xpQuizCorrect = 15;
  static const xpLevelUpBonus = 300;
  static const xpCultureRead = 20;
  static const xpReferralBonus = 200;

  // Badge IDs (kept here for reference)
  static const badgeFirstVisit = 'first_visit';
  static const badgePhotoLover = 'photo_lover';
  static const badgeStreak7 = 'streak_7';
  static const badgeStreak30 = 'streak_30';
  static const badgeRater10 = 'rater_10';
  static const badgePlanner = 'planner';
  static const badgeCultureFan = 'culture_fan';
  static const badgeCultureScholar = 'culture_scholar';
  static const badgeCultureMaster = 'culture_master';
  static const badgeFoodie = 'foodie';
  static const badgeAiExplorer = 'ai_explorer';
  static const badgeLevel5 = 'level_5';
  static const badgeLevel7 = 'level_7';
  static const badgeJapanMaster = 'japan_master';
  static const badgeAmbassador = 'ambassador';
}

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const detail = '/detail/:id';
  static const search = '/search';
  static const myPlan = '/my-plan';
  static const profile = '/profile';
  static const settings = '/settings';
  static const camera = '/camera';
  static const cameraHistory = '/camera/history';
  static const ranking = '/ranking';
  static const map = '/map';
  static const phrases = '/phrases';
  static const challenge = '/challenge';
  static const aiPlanner = '/ai-planner';
  static const progress = '/progress';
  static const hosts = '/hosts';
  static const hostProfile = '/hosts/:uid';
  static const premium = '/premium';
  static const community = '/community';
  static const createPost = '/post/create';
  static const postDetail = '/post';
  static const seasonEvents = '/seasons';
  static const offlineContent = '/offline';
  static const journal = '/journal';
  static const journalEntry = '/journal/entry';
  static const whatIsThis = '/what-is-this';
  static const menuTranslator = '/menu-translator';
  static const visionCacheHistory = '/vision-cache-history';
  static const cultureHub = '/culture';
  static const cultureDetail = '/culture/:id';
  static const collection = '/collection';
  static const inviteFriends = '/invite';
}

class FirestoreCollections {
  static const users = 'users';
  static const curations = 'curations';
  static const ratings = 'ratings';
  static const plans = 'plans';
  static const posts = 'posts';
  static const phrases = 'phrases';
  static const rankings = 'rankings';
  static const hosts = 'hosts';
  static const hostRequests = 'host_requests';
  static const referralCodes = 'referral_codes';
  static const referrals = 'referrals';
  static const userContributions = 'user_contributions';
  static const contributionVotes = 'contribution_votes';
}

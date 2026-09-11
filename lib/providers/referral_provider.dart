import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/firestore_instance.dart';

/// Crockford Base32 alphabet — uppercase, digits, excludes I/L/O/U to avoid
/// confusion when a user reads/types a code.
const _codeAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// 32-bit FNV-1a over the full string. Every op stays < 2^53 so the result is
/// identical on native (mobile) and JS (web) — important because both the
/// inviter (ensureCode) and any regenerating device must derive the same code.
int _fnv1a32(String s, int seed) {
  var hash = seed;
  for (final unit in s.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Deterministic, case-safe 8-char referral code derived from the FULL uid.
/// Hashing the whole uid (not `substring(0, 8).toUpperCase()`) avoids both the
/// case-collision bug — Firebase uids are case-sensitive — and a RangeError on
/// uids shorter than 8 chars. Two independent seeds give ~40 bits of spread.
String referralCodeFor(String uid) {
  final a = _fnv1a32(uid, 0x811c9dc5);
  final b = _fnv1a32(uid, 0x811c9dc5 ^ 0x5bd1e995);
  final buf = StringBuffer();
  var h = a;
  for (var i = 0; i < 8; i++) {
    if (i == 4) h = b; // second half draws from the independent hash
    buf.write(_codeAlphabet[h & 0x1F]);
    h >>= 5;
  }
  return buf.toString();
}

enum RedeemResult { success, invalidCode, selfReferral, alreadyRedeemed, error }

class ReferralNotifier extends StateNotifier<AsyncValue<void>> {
  ReferralNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Ensures the current user's referral code lookup doc exists.
  /// Safe to call repeatedly (idempotent `set`).
  Future<String?> ensureCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final code = referralCodeFor(user.uid);
    await db.collection(FirestoreCollections.referralCodes).doc(code).set(
      {'uid': user.uid},
      SetOptions(merge: true),
    );
    return code;
  }

  Future<RedeemResult> redeemCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return RedeemResult.error;

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return RedeemResult.invalidCode;
    if (code == referralCodeFor(user.uid)) return RedeemResult.selfReferral;

    state = const AsyncLoading();
    try {
      final codeDoc = await db
          .collection(FirestoreCollections.referralCodes)
          .doc(code)
          .get();
      if (!codeDoc.exists) {
        state = const AsyncData(null);
        return RedeemResult.invalidCode;
      }

      final inviterUid = codeDoc.data()?['uid'] as String?;
      if (inviterUid == null) {
        state = const AsyncData(null);
        return RedeemResult.invalidCode;
      }
      if (inviterUid == user.uid) {
        state = const AsyncData(null);
        return RedeemResult.selfReferral;
      }

      final inviteeRef =
          db.collection(FirestoreCollections.users).doc(user.uid);
      final inviteeSnap = await inviteeRef.get();
      if (inviteeSnap.exists &&
          inviteeSnap.data()?['referred_by'] != null) {
        state = const AsyncData(null);
        return RedeemResult.alreadyRedeemed;
      }

      // The referral doc id is the invitee's uid, so a user can create at most
      // one referral record (a re-redeem becomes a blocked update). The `code`
      // is included so security rules can verify the inviter actually owns it.
      // Reward-granting (XP + badge on both accounts) happens server-side in
      // cloud_functions/referral_rewards.js — a client can only be trusted to
      // write its own user document.
      await db
          .collection(FirestoreCollections.referrals)
          .doc(user.uid)
          .set({
        'inviter_uid': inviterUid,
        'invitee_uid': user.uid,
        'code': code,
        'created_at': FieldValue.serverTimestamp(),
      });

      _ref.invalidate(appUserProvider);
      state = const AsyncData(null);
      return RedeemResult.success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return RedeemResult.error;
    }
  }
}

final referralNotifierProvider =
    StateNotifierProvider<ReferralNotifier, AsyncValue<void>>(
  (ref) => ReferralNotifier(ref),
);

/// Own referral code — creates the lookup doc on first access.
final myReferralCodeProvider = FutureProvider<String?>((ref) {
  return ref.read(referralNotifierProvider.notifier).ensureCode();
});

/// Count of successful referrals made by the current user.
final referralCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  return db
      .collection(FirestoreCollections.referrals)
      .where('inviter_uid', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.length);
});

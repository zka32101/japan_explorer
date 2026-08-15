import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/firestore_instance.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = db;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _logger = Logger();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return _handleSignIn(userCredential);
    } catch (e) {
      _logger.e('Google Sign-In error', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<AppUser?> _handleSignIn(UserCredential credential) async {
    final user = credential.user;
    if (user == null) return null;

    final docRef =
        _firestore.collection(FirestoreCollections.users).doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Traveler',
        photoUrl: user.photoURL,
        preferredCategories: [],
        xp: 0,
        level: 1,
        badges: [],
        streakDays: 0,
        streakRecoveryUsed: 0,
        savedCurationIds: [],
        languageCode: 'en',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newUser.toFirestore());
      return newUser;
    }

    return AppUser.fromFirestore(doc);
  }

  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }
}

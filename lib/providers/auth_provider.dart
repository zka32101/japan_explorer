import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/purchase_service.dart';
import '../services/fcm_service.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(firebaseServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(firebaseAuthStateProvider).maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
      if (user != null) await _onSignIn(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    final uid = state.valueOrNull?.uid;
    await _authService.signOut();
    if (uid != null) {
      // Remove FCM token and reset RevenueCat to anonymous user
      await fcmService.clearTokenForUser(uid);
      await purchaseService.logoutUser();
    }
    state = const AsyncValue.data(null);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<void> _onSignIn(AppUser user) async {
    // Identify user in RevenueCat (entitlements sync across devices)
    await purchaseService.loginUser(user.uid);
    // Save FCM token so this device receives push notifications
    await fcmService.saveTokenForUser(user.uid);
    // Schedule daily culture notification at 9:00 AM
    await fcmService.scheduleDailyCultureNotification(hour: 9, minute: 0);
    // Schedule streak reminder at 20:00
    await fcmService.scheduleStreakReminder(hour: 20, minute: 0);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

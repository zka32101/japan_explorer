import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/streak_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  bool _minDelayDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _animCtrl.forward();
    _startMinDelay();
  }

  Future<void> _startMinDelay() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _minDelayDone = true;
    _tryNavigate();
  }

  /// Called whenever auth state resolves OR minimum delay completes.
  /// Only navigates once both conditions are met.
  void _tryNavigate() {
    if (!_minDelayDone || _navigated || !mounted) return;

    final authState = ref.read(firebaseAuthStateProvider);

    // Still loading — wait for the listen callback to fire again
    if (authState.isLoading) return;

    _navigated = true;
    final isLoggedIn = authState.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );

    if (isLoggedIn) {
      final onboardingDone = ref.read(onboardingStatusProvider);
      ref
          .read(streakNotifierProvider.notifier)
          .checkAndUpdateStreak()
          .then((_) {
        if (!mounted) return;
        context.go(
            onboardingDone ? AppRoutes.home : AppRoutes.onboarding);
      });
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state — fires immediately if already resolved,
    // or as soon as Firebase returns (handles slow connections).
    ref.listen(firebaseAuthStateProvider, (_, state) {
      if (!state.isLoading) _tryNavigate();
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🗾', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Japan Explorer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover the real Japan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white.withValues(alpha: 0.7),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

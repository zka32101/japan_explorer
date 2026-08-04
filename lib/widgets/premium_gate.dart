import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';
import '../providers/premium_provider.dart';
import '../screens/premium_screen.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

/// Open the premium paywall as a full-page modal.
/// Returns true if the user completed a purchase.
Future<bool> showPremiumPaywall(BuildContext context) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const PremiumScreen(),
    ),
  );
  return result ?? false;
}

// ── PremiumGate widget ────────────────────────────────────────────────────────

/// Wraps [child] and displays a lock overlay for free users.
/// Tapping the lock opens [PremiumScreen].
///
/// ```dart
/// PremiumGate(
///   featureName: 'Unlimited Audio Guides',
///   featureEmoji: '🎧',
///   child: _buildPlayer(...),
/// )
/// ```
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String featureEmoji;
  final String? limitMessage;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.featureEmoji = '✨',
    this.limitMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return child;

    return GestureDetector(
      onTap: () => showPremiumPaywall(context),
      child: Stack(
        children: [
          // Blurred / dimmed child
          IgnorePointer(
            child: Opacity(opacity: 0.35, child: child),
          ),
          // Lock overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(featureEmoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    featureName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (limitMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      limitMessage!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'widgets.unlock_premium'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PremiumBadge ──────────────────────────────────────────────────────────────

/// Small "✨ Premium" chip shown next to premium feature names.
class PremiumBadge extends StatelessWidget {
  final bool mini;
  const PremiumBadge({super.key, this.mini = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: mini ? 6 : 8, vertical: mini ? 2 : 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'widgets.premium_badge'.tr(),
        style: TextStyle(
          color: Colors.white,
          fontSize: mini ? 9 : 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    child: const Text(
                      '✨ Unlock Premium',
                      style: TextStyle(
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
        '✨ Premium',
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

// ── UsageBanner ───────────────────────────────────────────────────────────────

/// Shows free-tier usage remaining (e.g. "2 / 3 audio guides used today").
/// Hides automatically for premium users.
class UsageBanner extends ConsumerWidget {
  final int used;
  final int limit;
  final String label;
  final String period;

  const UsageBanner({
    super.key,
    required this.used,
    required this.limit,
    required this.label,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    final remaining = limit - used;
    final isCritical = remaining <= 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCritical
            ? Colors.orange.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? Colors.orange.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining > 0
                      ? '$remaining $label remaining $period'
                      : 'No $label remaining $period',
                  style: TextStyle(
                    color: isCritical ? Colors.orange : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: used / limit,
                    minHeight: 4,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isCritical ? Colors.orange : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => showPremiumPaywall(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

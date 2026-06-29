import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/premium_provider.dart';

// ── Feature list ──────────────────────────────────────────────────────────────

const _features = [
  (icon: '🎧', text: 'Unlimited AI Audio Guides in 5 languages'),
  (icon: '✨', text: 'Unlimited AI Trip Planning'),
  (icon: '🧠', text: 'Unlimited Daily Challenges & detailed analytics'),
  (icon: '🤝', text: 'Priority host matching & unlimited meetup requests'),
  (icon: '📶', text: 'Offline curation cache for travel without internet'),
  (icon: '🚫', text: 'No usage limits — ever'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paywallProvider);

    // Auto-close on successful purchase
    ref.listen<PaywallState>(paywallProvider, (_, next) {
      if (next.isSuccess && context.mounted) {
        Navigator.pop(context, true); // return true = purchased
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildHero(),
                        const SizedBox(height: 28),
                        _buildFeatureList(),
                        const SizedBox(height: 28),
                        _buildPlans(context, ref, state),
                        const SizedBox(height: 20),
                        _buildCTA(context, ref, state),
                        const SizedBox(height: 12),
                        _buildRestoreButton(context, ref, state),
                        const SizedBox(height: 24),
                        _buildFooterLinks(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return SizedBox.expand(
      child: CustomPaint(painter: _SakuraBgPainter()),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 4),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ).createShader(bounds),
          child: const Text('✨',
              style: TextStyle(fontSize: 52, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Japan Explorer Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock the complete Japan experience',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Feature list ────────────────────────────────────────────────────────────

  Widget _buildFeatureList() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: _features
            .map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(f.icon,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          f.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 18),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Plan cards ──────────────────────────────────────────────────────────────

  Widget _buildPlans(
      BuildContext context, WidgetRef ref, PaywallState state) {
    if (state.packages.isEmpty) {
      // No packages yet — show placeholder cards
      return _buildFallbackPlans(ref, state);
    }

    return Row(
      children: state.packages
          .where((p) =>
              p.packageType == PackageType.monthly ||
              p.packageType == PackageType.annual)
          .map((pkg) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: pkg == state.packages.first ? 0 : 8,
                    right: pkg == state.packages.last ? 0 : 8,
                  ),
                  child: _PlanCard(
                    package: pkg,
                    isSelected: state.selectedId == pkg.identifier,
                    onTap: () => ref
                        .read(paywallProvider.notifier)
                        .selectPackage(pkg.identifier),
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Shown while RevenueCat packages are loading or unavailable
  Widget _buildFallbackPlans(WidgetRef ref, PaywallState state) {
    return Row(
      children: [
        Expanded(
          child: _StaticPlanCard(
            label: 'Monthly',
            price: '\$4.99',
            sub: 'per month',
            id: 'monthly',
            isSelected: state.selectedId == 'monthly' ||
                (state.selectedId == null),
            onTap: () =>
                ref.read(paywallProvider.notifier).selectPackage('monthly'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StaticPlanCard(
            label: 'Annual',
            price: '\$39.99',
            sub: '\$3.33/mo · Save 33%',
            id: 'annual',
            isBestValue: true,
            isSelected: state.selectedId == 'annual',
            onTap: () =>
                ref.read(paywallProvider.notifier).selectPackage('annual'),
          ),
        ),
      ],
    );
  }

  // ── CTA button ──────────────────────────────────────────────────────────────

  Widget _buildCTA(
      BuildContext context, WidgetRef ref, PaywallState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state.isLoading
              ? null
              : () => ref.read(paywallProvider.notifier).purchase(),
          child: Center(
            child: state.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Continue with Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Error + Restore ──────────────────────────────────────────────────────────

  Widget _buildRestoreButton(
      BuildContext context, WidgetRef ref, PaywallState state) {
    return Column(
      children: [
        if (state.error != null) ...[
          Text(
            state.error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  final ok =
                      await ref.read(paywallProvider.notifier).restore();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No previous purchases found')),
                    );
                  }
                },
          child: Text(
            'Restore Purchases',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(
            label: 'Terms',
            url: 'https://japan-explorer.app/terms'),
        Text(' · ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
        _FooterLink(
            label: 'Privacy',
            url: 'https://japan-explorer.app/privacy'),
      ],
    );
  }
}

// ── Plan card (live RevenueCat package) ───────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isAnnual => package.packageType == PackageType.annual;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAnnual)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            if (_isAnnual) const SizedBox(height: 8),
            Text(
              _isAnnual ? 'Annual' : 'Monthly',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.storeProduct.priceString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isAnnual
                  ? 'per year · save ~33%'
                  : 'per month',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Static fallback plan card (no RevenueCat connection) ─────────────────────

class _StaticPlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final String id;
  final bool isSelected;
  final bool isBestValue;
  final VoidCallback onTap;

  const _StaticPlanCard({
    required this.label,
    required this.price,
    required this.sub,
    required this.id,
    required this.isSelected,
    required this.onTap,
    this.isBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBestValue)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            if (isBestValue) const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer link ───────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  final String label;
  final String url;
  const _FooterLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white30,
        ),
      ),
    );
  }
}

// ── Background painter ─────────────────────────────────────────────────────────

class _SakuraBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle radial gradient in top-right (warm) and bottom-left (cool)
    final paintWarm = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.8),
        radius: 1.0,
        colors: [
          const Color(0xFFE63946).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paintCool = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, 0.8),
        radius: 1.0,
        colors: [
          const Color(0xFF457B9D).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), paintWarm);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), paintCool);
  }

  @override
  bool shouldRepaint(_) => false;
}

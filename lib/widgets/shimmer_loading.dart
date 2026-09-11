import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _base(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300;
}

Color _highlight(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF3E3E3E) : Colors.grey.shade100;
}

// ── Curation card skeleton ────────────────────────────────────────────────────

class CurationCardSkeleton extends StatelessWidget {
  const CurationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(height: 200, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(),
                      const SizedBox(width: 8),
                      _chip(width: 80),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({double width = 64}) => Container(
        height: 26,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
      );
}

/// Show N curation card skeletons while loading
class CurationListSkeleton extends StatelessWidget {
  final int count;
  const CurationListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: CurationCardSkeleton(),
          ),
          childCount: count,
        ),
      ),
    );
  }
}

// ── Host card skeleton ────────────────────────────────────────────────────────

class HostCardSkeleton extends StatelessWidget {
  const HostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2-column grid of host card skeletons
class HostGridSkeleton extends StatelessWidget {
  final int count;
  const HostGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const HostCardSkeleton(),
    );
  }
}

// ── Generic list skeleton ─────────────────────────────────────────────────────

class ListItemSkeleton extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ListItemSkeleton({super.key, this.count = 5, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, __) => Shimmer.fromColors(
        baseColor: _base(ctx),
        highlightColor: _highlight(ctx),
        child: Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Inline shimmer text placeholder ──────────────────────────────────────────

class ShimmerText extends StatelessWidget {
  final double? width;
  final double height;
  const ShimmerText({super.key, this.width, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ── Profile skeleton ──────────────────────────────────────────────────────────

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 18,
                  width: 140,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  height: 22,
                  width: 80,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11))),
            ],
          ),
        ],
      ),
    );
  }
}

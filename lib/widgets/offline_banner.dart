import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// A slim banner shown at the top of the screen when the device is offline.
/// Animates in/out smoothly. Drop it into any Scaffold's body or Column.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isOnline
          ? const SizedBox.shrink()
          : Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                color: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('offline.banner'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Wraps a [child] widget with an offline banner at the top.
/// Use this in Scaffold bodies where you want the banner to appear automatically.
class OfflineAwarePage extends ConsumerWidget {
  final Widget child;
  const OfflineAwarePage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}

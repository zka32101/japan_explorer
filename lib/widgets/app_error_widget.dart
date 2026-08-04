import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';

/// Generic error view used across screens.
class AppErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message ?? 'widgets.error_default'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('widgets.try_again'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner — fits inside a column/list without taking full screen.
class AppErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('common.retry'.tr(),
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Helper extension — builds an error widget from AsyncValue.
extension AsyncValueErrorExt<T> on AsyncValue<T> {
  /// Returns an [AppErrorWidget] when in error state, otherwise null.
  Widget? buildError({VoidCallback? onRetry}) {
    return whenOrNull(
      error: (e, _) => AppErrorWidget(
        message: _friendlyMessage(e),
        onRetry: onRetry,
      ),
    );
  }

  String _friendlyMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'widgets.error_network_detail'.tr();
    }
    if (msg.contains('permission') || msg.contains('PERMISSION_DENIED')) {
      return 'widgets.error_permission_detail'.tr();
    }
    if (msg.contains('not-found')) {
      return 'widgets.error_not_found'.tr();
    }
    return 'widgets.error_load_failed'.tr();
  }
}

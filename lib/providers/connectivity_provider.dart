import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Emits `true` when online, `false` when offline.
/// Starts with an async check of current state, then streams changes.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Emit current state immediately
  yield await connectivityService.isOnline;
  // Then yield each connectivity change
  yield* connectivityService.onConnectivityChanged;
});

/// Synchronous read of connectivity — defaults to `true` (optimistic)
/// while the initial check is pending.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (v) => v,
    orElse: () => true, // assume online until we know otherwise
  );
});

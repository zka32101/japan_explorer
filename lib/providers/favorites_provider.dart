import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/curation.dart';
import '../models/rating.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';
import 'curations_provider.dart';

/// Ids of the spots the signed-in user has saved, in the order they were saved.
final favoriteIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(appUserProvider).valueOrNull?.savedCurationIds ?? const [];
});

final isFavoriteProvider = Provider.family<bool, String>((ref, curationId) {
  return ref.watch(favoriteIdsProvider).contains(curationId);
});

/// The user's memo for each saved spot, keyed by curation id.
final favoriteNotesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(appUserProvider).valueOrNull?.favoriteNotes ?? const {};
});

/// The saved spots themselves, in the order they were saved.
final favoriteCurationsProvider = FutureProvider<List<Curation>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider);
  final loaded = await Future.wait(
      ids.map((id) => ref.watch(curationDetailProvider(id).future)));
  return [
    for (final c in loaded)
      if (c != null) c,
  ];
});

/// The plan entry a favorite becomes when it is added to a trip plan.
PlanSpot planSpotFromCuration(Curation c, {int order = 0, String? note}) =>
    PlanSpot(
      curationId: c.id,
      curationTitle: c.title,
      imageUrl: c.imageUrls.isNotEmpty ? c.imageUrls.first : null,
      order: order,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );

/// Toggles [curationId] in the user's favorites and shows a snackbar.
/// Asks the user to sign in when nobody is.
Future<void> toggleFavorite(
    BuildContext context, WidgetRef ref, String curationId) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final user = ref.read(appUserProvider).valueOrNull;
  if (user == null) {
    messenger.showSnackBar(SnackBar(
      content: Text(tr('favorites.login_required')),
      action: SnackBarAction(
        label: tr('favorites.sign_in'),
        onPressed: () => router.go(AppRoutes.login),
      ),
    ));
    return;
  }
  final save = !user.savedCurationIds.contains(curationId);
  await ref
      .read(firebaseServiceProvider)
      .setCurationSaved(user.uid, curationId, save);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(tr(save ? 'favorites.added' : 'favorites.removed')),
      action: save
          ? SnackBarAction(
              label: tr('favorites.view'),
              onPressed: () => router.push(AppRoutes.favorites),
            )
          : null,
    ));
}

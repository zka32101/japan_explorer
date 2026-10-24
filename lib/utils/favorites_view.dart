import '../models/curation.dart';

enum FavoriteSort { newest, area }

/// Categories present in [curations], in the app's usual category order.
List<String> categoriesPresent(List<Curation> curations) {
  final present = curations.map((c) => c.category).toSet();
  return [
    for (final c in CurationCategory.all)
      if (present.contains(c)) c,
  ];
}

/// Applies the favorites screen's filter and sort.
///
/// [savedOrder] is the order the spots were saved in (oldest first).
List<Curation> filterAndSortFavorites(
  List<Curation> savedOrder, {
  String? category,
  FavoriteSort sort = FavoriteSort.newest,
}) {
  final filtered = category == null
      ? [...savedOrder]
      : savedOrder.where((c) => c.category == category).toList();
  switch (sort) {
    case FavoriteSort.newest:
      return filtered.reversed.toList();
    case FavoriteSort.area:
      filtered.sort((a, b) {
        final byPrefecture = a.prefecture.compareTo(b.prefecture);
        if (byPrefecture != 0) return byPrefecture;
        final byCity = a.city.compareTo(b.city);
        if (byCity != 0) return byCity;
        return a.title.compareTo(b.title);
      });
      return filtered;
  }
}

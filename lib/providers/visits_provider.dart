import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showglobe_core/showglobe_core.dart' show VisitRecord;

import '../data/japan_regions.dart';
import '../models/curation.dart';
import '../models/journal_entry.dart';
import 'curations_provider.dart';
import 'journal_provider.dart';

/// 日記の記録を、共通の「行った場所の記録」に変換する。
/// [curations] は curation id → スポット（取得できなかったものは含めない）。
/// 写真は日記の写真を優先し、無ければスポットの最初の画像。
List<VisitRecord> buildVisitRecords(
  Iterable<JournalEntry> entries,
  Map<String, Curation> curations,
) {
  return [
    for (final e in entries)
      VisitRecord(
        placeId: e.curationId,
        title: e.curationTitle,
        visitedAt: e.visitDate,
        regionId: japanRegionId(curations[e.curationId]?.prefecture),
        imageUrl: e.imageUrl.isNotEmpty
            ? e.imageUrl
            : (curations[e.curationId]?.imageUrls.firstOrNull),
      ),
  ];
}

/// 日記から作った、行った場所の記録（スタンプ帳・年間まとめの元データ）。
final visitRecordsProvider = FutureProvider<List<VisitRecord>>((ref) async {
  final entries = ref.watch(journalProvider).entries;
  final ids = entries.map((e) => e.curationId).toSet();
  final curations = <String, Curation>{};
  await Future.wait([
    for (final id in ids)
      ref.watch(curationDetailProvider(id).future).then((c) {
        if (c != null) curations[id] = c;
      }).catchError((_) {}),
  ]);
  return buildVisitRecords(entries, curations);
});

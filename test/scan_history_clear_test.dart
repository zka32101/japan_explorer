import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/scan_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScanRecord _record(String id, String? imagePath, {int minutesAgo = 0}) =>
    ScanRecord(
      id: id,
      landmarkName: 'Spot $id',
      description: '',
      historicalBackground: '',
      howToExperience: '',
      phraseJapanese: '',
      phraseRomaji: '',
      phraseEnglish: '',
      scannedAt: DateTime(2026, 10, 22, 9).subtract(Duration(minutes: minutesAgo * 10)),
      provider: 'gemini',
      imagePath: imagePath,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clear() removes all records and only the photos inside the app dirs',
      () async {
    final tmp = await Directory.systemTemp.createTemp('scan_clear_');
    addTearDown(() => tmp.delete(recursive: true));
    final owned = Directory('${tmp.path}/owned')..createSync();
    final foreign = Directory('${tmp.path}/foreign')..createSync();
    final ownedPhoto = File('${owned.path}/a.jpg')..writeAsStringSync('x');
    final foreignPhoto = File('${foreign.path}/b.jpg')..writeAsStringSync('y');

    final repo = ScanHistoryRepository();
    await repo.add(_record('1', ownedPhoto.path, minutesAgo: 2));
    await repo.add(_record('2', foreignPhoto.path, minutesAgo: 1));
    await repo.add(_record('3', null));
    expect((await repo.getAll()).length, 3);

    await repo.clear(ownedDirs: () async => [owned.path]);

    expect(await repo.getAll(), isEmpty);
    expect(ownedPhoto.existsSync(), isFalse);
    expect(foreignPhoto.existsSync(), isTrue, reason: 'outside the app dirs');
  });

  test('isInsideAny does not follow .. out of the app dir', () {
    expect(ScanHistoryRepository.isInsideAny('/app/tmp/a.jpg', ['/app/tmp']), isTrue);
    expect(ScanHistoryRepository.isInsideAny('/app/tmp/../secret.jpg', ['/app/tmp']), isFalse);
    expect(ScanHistoryRepository.isInsideAny('/app/tmp2/a.jpg', ['/app/tmp']), isFalse);
  });
}

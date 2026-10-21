import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showglobe_core/showglobe_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('共通訳文(kit)とアプリ訳文が重なって読み込める(全13言語)', () async {
    const loader = ShowglobeAssetLoader();
    for (final l in Language.values) {
      final m = await loader.load('assets/translations', l.locale);
      expect((m['settings'] as Map)['title'], isNotNull, reason: '${l.code} kit');
      expect((m['settings'] as Map)['copyright'], isNotNull, reason: '${l.code} app');
      expect((m['errors'] as Map)['network'], isNotNull, reason: '${l.code} errors');
      expect((m['home'] as Map), isNotEmpty, reason: '${l.code} home');
      expect((m['premium'] as Map)['hero_title'], isNotNull);
      expect((m['premium'] as Map)['restore'], isNotNull);
    }
  });
}

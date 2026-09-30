import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/models/culture_content.dart';
import 'package:japan_explorer/providers/language_provider.dart';
import 'package:japan_explorer/services/culture_translation_store.dart';

CultureContent _article({String? titleJa}) => CultureContent(
      id: 'tea_ceremony_01',
      categoryId: 'culture',
      title: 'The Way of Tea',
      subtitle: 'Zen in a bowl',
      description: 'English description',
      titleJa: titleJa,
      imageUrl: '',
      tags: const [],
      level: 1,
      createdAt: DateTime(2026, 1, 1),
      readTime: 5,
      sourceUrl: '',
      keyFacts: const ['fact en'],
      didYouKnow: 'dyk en',
    );

void main() {
  final store = CultureTranslationStore.instance;

  setUp(store.debugReset);

  test('falls back to English when nothing is translated', () {
    final a = _article();
    expect(a.localizedTitle('th'), 'The Way of Tea');
    expect(a.localizedSubtitle('th'), 'Zen in a bowl');
    expect(a.localizedDescription('th'), 'English description');
    expect(a.localizedKeyFacts('th'), ['fact en']);
    expect(a.localizedDidYouKnow('th'), 'dyk en');
  });

  test('uses the bundled translation for the language', () {
    store.debugSet('th', const {
      'tea_ceremony_01': CultureTranslation(
        title: 'ชา',
        subtitle: 'เซน',
        description: 'คำอธิบาย',
        keyFacts: ['ข้อเท็จจริง'],
        didYouKnow: 'รู้หรือไม่',
      ),
    });
    final a = _article();
    expect(a.localizedTitle('th'), 'ชา');
    expect(a.localizedDescription('th'), 'คำอธิบาย');
    expect(a.localizedKeyFacts('th'), ['ข้อเท็จจริง']);
    expect(a.localizedDidYouKnow('th'), 'รู้หรือไม่');
    // Another language is untouched.
    expect(a.localizedTitle('es'), 'The Way of Tea');
  });

  test('a partial translation only replaces what it has', () {
    store.debugSet('es', const {
      'tea_ceremony_01': CultureTranslation(title: 'El camino del té'),
    });
    final a = _article();
    expect(a.localizedTitle('es'), 'El camino del té');
    expect(a.localizedSubtitle('es'), 'Zen in a bowl');
  });

  test('Simplified and Traditional Chinese are separate', () {
    store.debugSet('zh', const {
      'tea_ceremony_01': CultureTranslation(title: '茶道'),
    });
    store.debugSet('zh-TW', const {
      'tea_ceremony_01': CultureTranslation(title: '茶道（繁）'),
    });
    final a = _article();
    expect(a.localizedTitle('zh'), '茶道');
    expect(a.localizedTitle('zh-TW'), '茶道（繁）');
  });

  test('bundled translation wins over the legacy Firestore field', () {
    store.debugSet('ja', const {
      'tea_ceremony_01': CultureTranslation(title: '茶の湯（アセット）'),
    });
    expect(_article(titleJa: '茶の湯（Firestore）').localizedTitle('ja'), '茶の湯（アセット）');
  });

  test('the legacy Firestore field is used when there is no bundled file', () {
    expect(_article(titleJa: '茶の湯（Firestore）').localizedTitle('ja'), '茶の湯（Firestore）');
  });

  test('CultureTranslation.fromCompact reads the compact keys', () {
    final t = CultureTranslation.fromCompact({
      't': 'a',
      's': 'b',
      'd': 'c',
      'k': ['x', 'y'],
      'y': 'z',
    });
    expect(t.title, 'a');
    expect(t.subtitle, 'b');
    expect(t.description, 'c');
    expect(t.keyFacts, ['x', 'y']);
    expect(t.didYouKnow, 'z');
    final empty = CultureTranslation.fromCompact({});
    expect(empty.title, isNull);
    expect(empty.keyFacts, isNull);
  });

  test('every Language code is unique and Traditional Chinese is not "zh"', () {
    final codes = Language.values.map((l) => l.code).toList();
    expect(codes.toSet().length, codes.length);
    expect(Language.zhHant.code, 'zh-TW');
    expect(Language.zh.code, 'zh');
  });
}

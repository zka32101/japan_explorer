import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/data/japan_regions.dart';

void main() {
  test('47 prefectures, unique ids, labels and grid cells', () {
    expect(japanRegions, hasLength(47));
    expect(japanRegions.map((r) => r.id).toSet(), hasLength(47));
    expect(japanRegions.map((r) => r.label).toSet(), hasLength(47));
    expect(japanRegions.map((r) => (r.col, r.row)).toSet(), hasLength(47));
    // ids are the JIS codes 01..47
    expect(japanRegions.map((r) => r.id).toSet(),
        {for (var i = 1; i <= 47; i++) i.toString().padLeft(2, '0')});
    for (final r in japanRegions) {
      expect(r.col, inInclusiveRange(0, 10));
      expect(r.row, inInclusiveRange(0, 12));
    }
  });

  test('prefecture names in Japanese and English map to the same id', () {
    expect(japanRegionId('Kyoto'), '26');
    expect(japanRegionId('kyoto'), '26');
    expect(japanRegionId('Kyoto Prefecture'), '26');
    expect(japanRegionId('京都'), '26');
    expect(japanRegionId('京都府'), '26');
    expect(japanRegionId('Tokyo'), '13');
    expect(japanRegionId('Tokyo-to'), '13');
    expect(japanRegionId('東京都'), '13');
    expect(japanRegionId('Osaka-fu'), '27');
    expect(japanRegionId('Hokkaido'), '01');
    expect(japanRegionId('北海道'), '01');
    expect(japanRegionId('Kanagawa-ken'), '14');
    expect(japanRegionId('Okinawa'), '47');
    expect(japanRegionId('  Nara '), '29');
  });

  test('unknown or empty names give null', () {
    expect(japanRegionId(null), isNull);
    expect(japanRegionId(''), isNull);
    expect(japanRegionId('Atlantis'), isNull);
  });
}

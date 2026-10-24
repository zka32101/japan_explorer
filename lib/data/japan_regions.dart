import 'package:showglobe_core/showglobe_core.dart' show Region;

/// 47 都道府県のタイルマップ（おおよその地理に沿った格子配置）。
/// id は JIS X 0401 の 2 桁コード。
const List<Region> japanRegions = [
  Region(id: '01', label: '北海道', col: 10, row: 0),
  Region(id: '02', label: '青森', col: 9, row: 1),
  Region(id: '05', label: '秋田', col: 8, row: 2),
  Region(id: '03', label: '岩手', col: 9, row: 2),
  Region(id: '06', label: '山形', col: 8, row: 3),
  Region(id: '04', label: '宮城', col: 9, row: 3),
  Region(id: '17', label: '石川', col: 5, row: 4),
  Region(id: '16', label: '富山', col: 6, row: 4),
  Region(id: '15', label: '新潟', col: 7, row: 4),
  Region(id: '07', label: '福島', col: 8, row: 4),
  Region(id: '18', label: '福井', col: 4, row: 5),
  Region(id: '21', label: '岐阜', col: 5, row: 5),
  Region(id: '20', label: '長野', col: 6, row: 5),
  Region(id: '10', label: '群馬', col: 7, row: 5),
  Region(id: '09', label: '栃木', col: 8, row: 5),
  Region(id: '08', label: '茨城', col: 9, row: 5),
  Region(id: '32', label: '島根', col: 0, row: 6),
  Region(id: '31', label: '鳥取', col: 1, row: 6),
  Region(id: '28', label: '兵庫', col: 2, row: 6),
  Region(id: '26', label: '京都', col: 3, row: 6),
  Region(id: '25', label: '滋賀', col: 4, row: 6),
  Region(id: '23', label: '愛知', col: 5, row: 6),
  Region(id: '19', label: '山梨', col: 6, row: 6),
  Region(id: '11', label: '埼玉', col: 7, row: 6),
  Region(id: '13', label: '東京', col: 8, row: 6),
  Region(id: '12', label: '千葉', col: 9, row: 6),
  Region(id: '35', label: '山口', col: 0, row: 7),
  Region(id: '34', label: '広島', col: 1, row: 7),
  Region(id: '33', label: '岡山', col: 2, row: 7),
  Region(id: '27', label: '大阪', col: 3, row: 7),
  Region(id: '29', label: '奈良', col: 4, row: 7),
  Region(id: '24', label: '三重', col: 5, row: 7),
  Region(id: '22', label: '静岡', col: 6, row: 7),
  Region(id: '14', label: '神奈川', col: 8, row: 7),
  Region(id: '40', label: '福岡', col: 0, row: 8),
  Region(id: '44', label: '大分', col: 1, row: 8),
  Region(id: '38', label: '愛媛', col: 2, row: 8),
  Region(id: '37', label: '香川', col: 3, row: 8),
  Region(id: '36', label: '徳島', col: 4, row: 8),
  Region(id: '30', label: '和歌山', col: 5, row: 8),
  Region(id: '41', label: '佐賀', col: 0, row: 9),
  Region(id: '43', label: '熊本', col: 1, row: 9),
  Region(id: '45', label: '宮崎', col: 2, row: 9),
  Region(id: '39', label: '高知', col: 3, row: 9),
  Region(id: '42', label: '長崎', col: 0, row: 10),
  Region(id: '46', label: '鹿児島', col: 1, row: 10),
  Region(id: '47', label: '沖縄', col: 0, row: 12),
];

/// 英語名（小文字）。日本語名は [japanRegions] の label に県/府/都/道を足した形も受け付ける。
const Map<String, String> _englishNames = {
  'hokkaido': '01', 'aomori': '02', 'iwate': '03', 'miyagi': '04',
  'akita': '05', 'yamagata': '06', 'fukushima': '07', 'ibaraki': '08',
  'tochigi': '09', 'gunma': '10', 'saitama': '11', 'chiba': '12',
  'tokyo': '13', 'kanagawa': '14', 'niigata': '15', 'toyama': '16',
  'ishikawa': '17', 'fukui': '18', 'yamanashi': '19', 'nagano': '20',
  'gifu': '21', 'shizuoka': '22', 'aichi': '23', 'mie': '24',
  'shiga': '25', 'kyoto': '26', 'osaka': '27', 'hyogo': '28',
  'nara': '29', 'wakayama': '30', 'tottori': '31', 'shimane': '32',
  'okayama': '33', 'hiroshima': '34', 'yamaguchi': '35', 'tokushima': '36',
  'kagawa': '37', 'ehime': '38', 'kochi': '39', 'fukuoka': '40',
  'saga': '41', 'nagasaki': '42', 'kumamoto': '43', 'oita': '44',
  'miyazaki': '45', 'kagoshima': '46', 'okinawa': '47',
};

final Map<String, String> _byName = () {
  final m = <String, String>{..._englishNames};
  for (final r in japanRegions) {
    m[r.label] = r.id;
    for (final suffix in const ['県', '府', '都', '道']) {
      m['${r.label}$suffix'] = r.id;
    }
  }
  return m;
}();

/// 都道府県名（日本語・英語、「Kyoto」「Tokyo-to」「京都府」など）から地域 ID を返す。
/// 分からなければ null。
String? japanRegionId(String? raw) {
  if (raw == null) return null;
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  s = s
      .replaceAll(RegExp(r'\s+|-'), '')
      .replaceAll('prefecture', '')
      .replaceAll('metropolis', '');
  final direct = _byName[s];
  if (direct != null) return direct;
  // 末尾の ken / fu / to / do を落として探す（kyoto のような名前は直接一致が先）。
  for (final suffix in const ['ken', 'fu', 'to', 'do']) {
    if (s.endsWith(suffix)) {
      final hit = _byName[s.substring(0, s.length - suffix.length)];
      if (hit != null) return hit;
    }
  }
  return null;
}

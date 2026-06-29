import '../models/season_event.dart';

/// Returns date-driven seasonal events and phenomena for Japan.
class SeasonService {
  static const _events = <SeasonEvent>[
    // ── Spring ──────────────────────────────────────────────────────────
    SeasonEvent(
      id: 'plum_blossom',
      emoji: '🌸',
      title: 'Plum Blossoms',
      titleJa: '梅',
      description: 'Ume (plum) trees bloom first, signaling spring\'s arrival.',
      tip: 'Visit Kitano Tenmangu (Kyoto) or Yushima Tenman-gū (Tokyo) for beautiful plum gardens.',
      season: SeasonType.spring,
      startMonth: 2, startDay: 1,
      endMonth: 3, endDay: 10,
    ),
    SeasonEvent(
      id: 'sakura',
      emoji: '🌸',
      title: 'Cherry Blossoms',
      titleJa: '桜',
      description: 'Japan\'s most celebrated season. Parks fill with picnickers for hanami (flower viewing).',
      tip: 'Peak bloom lasts only 1–2 weeks. Check jma.go.jp for daily forecasts. Arrive at parks early!',
      season: SeasonType.spring,
      startMonth: 3, startDay: 20,
      endMonth: 4, endDay: 25,
    ),
    SeasonEvent(
      id: 'golden_week',
      emoji: '🎏',
      title: 'Golden Week',
      titleJa: 'ゴールデンウィーク',
      description: 'Japan\'s biggest holiday week. Parks, trains and attractions are extremely crowded.',
      tip: 'Book everything weeks in advance. If you can, avoid major cities — rural Japan is quieter.',
      season: SeasonType.spring,
      startMonth: 4, startDay: 29,
      endMonth: 5, endDay: 5,
    ),
    // ── Summer ──────────────────────────────────────────────────────────
    SeasonEvent(
      id: 'tsuyu',
      emoji: '☔',
      title: 'Rainy Season',
      titleJa: '梅雨',
      description: 'The tsuyu (rainy season) brings high humidity and frequent rain.',
      tip: 'Carry a fold-up umbrella daily. Hydrangeas bloom beautifully during this time.',
      season: SeasonType.summer,
      startMonth: 6, startDay: 5,
      endMonth: 7, endDay: 20,
    ),
    SeasonEvent(
      id: 'tanabata',
      emoji: '⭐',
      title: 'Tanabata Festival',
      titleJa: '七夕',
      description: 'Star festival celebrating the meeting of two celestial lovers. Colorful streamers decorate streets.',
      tip: 'Write your wish on a tanzaku (paper strip) and hang it on a bamboo branch.',
      season: SeasonType.summer,
      startMonth: 7, startDay: 1,
      endMonth: 7, endDay: 10,
    ),
    SeasonEvent(
      id: 'summer_festivals',
      emoji: '🎆',
      title: 'Summer Festivals',
      titleJa: '夏祭り',
      description: 'Thousands of matsuri (festivals) happen across Japan with fireworks, yukata, and street food.',
      tip: 'Rent a yukata (summer kimono) for the full festival experience. Arrive before dark for fireworks.',
      season: SeasonType.summer,
      startMonth: 7, startDay: 15,
      endMonth: 8, endDay: 31,
    ),
    SeasonEvent(
      id: 'obon',
      emoji: '🏮',
      title: 'Obon',
      titleJa: 'お盆',
      description: 'Buddhist festival to honor ancestors. Families return home and bon odori dances are held.',
      tip: 'Many businesses close. Bon odori dances are public and visitors are welcome to join.',
      season: SeasonType.summer,
      startMonth: 8, startDay: 13,
      endMonth: 8, endDay: 16,
    ),
    // ── Autumn ──────────────────────────────────────────────────────────
    SeasonEvent(
      id: 'koyo',
      emoji: '🍁',
      title: 'Autumn Foliage',
      titleJa: '紅葉',
      description: 'Koyo (autumn leaves) turns forests into brilliant red, orange, and gold.',
      tip: 'Nikko, Kyoto\'s Arashiyama, and Hokkaido are prime spots. Peak varies by region.',
      season: SeasonType.autumn,
      startMonth: 10, startDay: 15,
      endMonth: 11, endDay: 30,
    ),
    SeasonEvent(
      id: 'culture_day',
      emoji: '🎭',
      title: 'Culture Day',
      titleJa: '文化の日',
      description: 'National holiday celebrating art and culture. Many museums offer free admission.',
      tip: 'Check local museums — many are free on November 3rd.',
      season: SeasonType.autumn,
      startMonth: 11, startDay: 3,
      endMonth: 11, endDay: 3,
    ),
    // ── Winter ──────────────────────────────────────────────────────────
    SeasonEvent(
      id: 'illuminations',
      emoji: '✨',
      title: 'Winter Illuminations',
      titleJa: 'イルミネーション',
      description: 'Cities light up with spectacular winter illumination displays.',
      tip: 'Nabana no Sato (Mie), Ashikaga Flower Park, and teamLab events are world-famous.',
      season: SeasonType.winter,
      startMonth: 11, startDay: 20,
      endMonth: 1, endDay: 10,
    ),
    SeasonEvent(
      id: 'oshogatsu',
      emoji: '🎍',
      title: 'New Year',
      titleJa: 'お正月',
      description: 'Japan\'s most important holiday. Millions visit shrines for hatsumode (first shrine visit).',
      tip: 'Visit smaller shrines to avoid crushing crowds. Eat soba on New Year\'s Eve for good luck.',
      season: SeasonType.winter,
      startMonth: 12, startDay: 28,
      endMonth: 1, endDay: 4,
    ),
    SeasonEvent(
      id: 'setsubun',
      emoji: '👹',
      title: 'Setsubun Bean Throwing',
      titleJa: '節分',
      description: 'The day before spring. People throw roasted beans to drive out evil spirits.',
      tip: 'Chant "Oni wa soto, fuku wa uchi!" while throwing beans. Celebrities join at famous temples.',
      season: SeasonType.winter,
      startMonth: 2, startDay: 3,
      endMonth: 2, endDay: 3,
    ),
    SeasonEvent(
      id: 'sapporo_snow',
      emoji: '🏔️',
      title: 'Sapporo Snow Festival',
      titleJa: '札幌雪まつり',
      description: 'Giant snow and ice sculptures fill Odori Park for one week, attracting 2 million visitors.',
      tip: 'The Susukino Ice Festival runs simultaneously. Book accommodation months in advance.',
      season: SeasonType.winter,
      startMonth: 2, startDay: 4,
      endMonth: 2, endDay: 11,
    ),
    SeasonEvent(
      id: 'koinobori',
      emoji: '🎏',
      title: 'Koinobori — Carp Streamers',
      titleJa: '鯉のぼり',
      description: 'Giant carp wind socks fly across rivers and hilltops for Children\'s Day (May 5).',
      tip: 'Kintaikyo Bridge (Yamaguchi) and Kazo (Saitama) have spectacular installations.',
      season: SeasonType.spring,
      startMonth: 4, startDay: 1,
      endMonth: 5, endDay: 5,
    ),
    SeasonEvent(
      id: 'wisteria',
      emoji: '💜',
      title: 'Wisteria Blooms',
      titleJa: '藤の花',
      description: 'Purple and white wisteria creates dreamlike tunnels in late April and May.',
      tip: 'Ashikaga Flower Park (Tochigi) has 160-year-old wisteria. Kawachi Fuji Garden offers a stunning tunnel.',
      season: SeasonType.spring,
      startMonth: 4, startDay: 15,
      endMonth: 5, endDay: 15,
    ),
    SeasonEvent(
      id: 'sunflower',
      emoji: '🌻',
      title: 'Sunflower Fields',
      titleJa: 'ひまわり畑',
      description: 'Vast sunflower fields turn Japanese hillsides gold in late July and August.',
      tip: 'Hokuryu Town (Hokkaido) plants 2.3 million sunflowers. Zama City (Kanagawa) is convenient from Tokyo.',
      season: SeasonType.summer,
      startMonth: 7, startDay: 15,
      endMonth: 8, endDay: 20,
    ),
    SeasonEvent(
      id: 'halloween',
      emoji: '🎃',
      title: 'Halloween in Japan',
      titleJa: 'ハロウィン',
      description: 'Shibuya Crossing becomes the world\'s most surreal Halloween party with 100,000+ costumed revelers.',
      tip: 'Kawasaki Halloween Parade is family-friendly. Check police diversions if visiting Shibuya.',
      season: SeasonType.autumn,
      startMonth: 10, startDay: 28,
      endMonth: 10, endDay: 31,
    ),
    SeasonEvent(
      id: 'ginkgo',
      emoji: '🌿',
      title: 'Ginkgo Avenue Gold',
      titleJa: 'イチョウ並木',
      description: 'Iconic ginkgo tree avenues turn brilliant yellow in mid-November.',
      tip: 'Jingu Gaien (Tokyo, mid-Nov to Dec) is the most famous. Showa Kinen Park has 300 trees.',
      season: SeasonType.autumn,
      startMonth: 11, startDay: 5,
      endMonth: 12, endDay: 5,
    ),
    SeasonEvent(
      id: 'shichi_go_san',
      emoji: '👘',
      title: 'Shichi-Go-San',
      titleJa: '七五三',
      description: 'Children aged 3, 5 and 7 dress in kimono and visit shrines to pray for long healthy lives.',
      tip: 'November 15 is the traditional date. Meiji Shrine (Tokyo) and Heian Shrine (Kyoto) are iconic venues.',
      season: SeasonType.autumn,
      startMonth: 11, startDay: 1,
      endMonth: 11, endDay: 25,
    ),
    // ── Year Round ───────────────────────────────────────────────────────
    SeasonEvent(
      id: 'onsen',
      emoji: '♨️',
      title: 'Onsen Hot Springs',
      titleJa: '温泉',
      description: 'Japan has over 27,000 hot spring sources. From luxury ryokan to outdoor rotenburo, onsen culture is unmissable.',
      tip: 'Hakone (from Tokyo), Beppu (Kyushu) and Kinosaki (Hyogo) offer very different onsen experiences.',
      season: SeasonType.yearRound,
      startMonth: 1, startDay: 1,
      endMonth: 12, endDay: 31,
    ),
    SeasonEvent(
      id: 'sumo',
      emoji: '🤼',
      title: 'Grand Sumo Tournaments',
      titleJa: '大相撲本場所',
      description: 'Six 15-day honbasho tournaments per year in Tokyo (Jan/May/Sep), Osaka (Mar), Nagoya (Jul) and Fukuoka (Nov).',
      tip: 'Arrive early to watch morning practice. Buy tickets from the official site in advance.',
      season: SeasonType.yearRound,
      startMonth: 1, startDay: 1,
      endMonth: 12, endDay: 31,
    ),
    SeasonEvent(
      id: 'matsuri',
      emoji: '🥁',
      title: 'Local Matsuri Festivals',
      titleJa: '祭り',
      description: 'Every neighborhood has its own matsuri with mikoshi (portable shrines), taiko drums and street food stalls.',
      tip: 'Ask locals or check the tourism office for neighborhood festivals — often more authentic than big events.',
      season: SeasonType.yearRound,
      startMonth: 1, startDay: 1,
      endMonth: 12, endDay: 31,
    ),
  ];

  /// Returns events active on [date].
  static List<SeasonEvent> getActiveEvents(DateTime date) =>
      _events.where((e) => e.isActive(date)).toList();

  /// Returns the current primary season for [date].
  static SeasonType getCurrentSeason(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return SeasonType.spring;
    if (m >= 6 && m <= 8) return SeasonType.summer;
    if (m >= 9 && m <= 11) return SeasonType.autumn;
    return SeasonType.winter;
  }

  /// Returns all events for a given season (null = all).
  static List<SeasonEvent> getEventsBySeason(SeasonType? season) {
    if (season == null) return List.unmodifiable(_events);
    return _events.where((e) => e.season == season).toList();
  }

  /// Returns all events.
  static List<SeasonEvent> getAllEvents() => List.unmodifiable(_events);
}

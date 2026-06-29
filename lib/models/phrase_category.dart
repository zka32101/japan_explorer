/// A single Japanese phrase for travelers.
class TravelPhrase {
  final String id;
  final String japanese;
  final String romaji;
  final String english;
  final String? usageNote;

  const TravelPhrase({
    required this.id,
    required this.japanese,
    required this.romaji,
    required this.english,
    this.usageNote,
  });
}

/// A named group of phrases.
class PhraseCategory {
  final String id;
  final String emoji;
  final String title;
  final List<TravelPhrase> phrases;

  const PhraseCategory({
    required this.id,
    required this.emoji,
    required this.title,
    required this.phrases,
  });
}

/// All built-in phrase categories with static data.
class TravelPhrases {
  static const categories = <PhraseCategory>[
    PhraseCategory(
      id: 'greetings',
      emoji: '👋',
      title: 'Greetings',
      phrases: [
        TravelPhrase(
          id: 'hello',
          japanese: 'こんにちは',
          romaji: 'Konnichiwa',
          english: 'Hello / Good afternoon',
          usageNote: 'Universal greeting, use after morning.',
        ),
        TravelPhrase(
          id: 'good_morning',
          japanese: 'おはようございます',
          romaji: 'Ohayou gozaimasu',
          english: 'Good morning',
          usageNote: 'Polite form. Omit ございます with friends.',
        ),
        TravelPhrase(
          id: 'good_evening',
          japanese: 'こんばんは',
          romaji: 'Konbanwa',
          english: 'Good evening',
        ),
        TravelPhrase(
          id: 'goodbye',
          japanese: 'さようなら',
          romaji: 'Sayounara',
          english: 'Goodbye (formal / final)',
          usageNote: 'Use じゃあね (Jaa ne) for casual partings.',
        ),
        TravelPhrase(
          id: 'thank_you',
          japanese: 'ありがとうございます',
          romaji: 'Arigatou gozaimasu',
          english: 'Thank you very much',
          usageNote: 'Most useful phrase in Japan!',
        ),
        TravelPhrase(
          id: 'excuse_me',
          japanese: 'すみません',
          romaji: 'Sumimasen',
          english: 'Excuse me / Sorry',
          usageNote: 'Use to get attention or apologize.',
        ),
        TravelPhrase(
          id: 'sorry',
          japanese: 'ごめんなさい',
          romaji: 'Gomennasai',
          english: 'I\'m sorry',
        ),
        TravelPhrase(
          id: 'yes_no',
          japanese: 'はい / いいえ',
          romaji: 'Hai / Iie',
          english: 'Yes / No',
        ),
      ],
    ),
    PhraseCategory(
      id: 'restaurant',
      emoji: '🍜',
      title: 'Restaurant & Food',
      phrases: [
        TravelPhrase(
          id: 'itadakimasu',
          japanese: 'いただきます',
          romaji: 'Itadakimasu',
          english: 'Let\'s eat (said before a meal)',
          usageNote: 'Essential — always say this before eating.',
        ),
        TravelPhrase(
          id: 'gochisousama',
          japanese: 'ごちそうさまでした',
          romaji: 'Gochisousama deshita',
          english: 'Thank you for the meal',
          usageNote: 'Say after finishing. Staff will appreciate it.',
        ),
        TravelPhrase(
          id: 'menu',
          japanese: 'メニューをください',
          romaji: 'Menyuu wo kudasai',
          english: 'Please give me the menu',
        ),
        TravelPhrase(
          id: 'this_please',
          japanese: 'これをください',
          romaji: 'Kore wo kudasai',
          english: 'This one, please',
          usageNote: 'Point at the menu or model dish.',
        ),
        TravelPhrase(
          id: 'bill',
          japanese: 'お会計をお願いします',
          romaji: 'Okaikei wo onegaishimasu',
          english: 'Bill / Check, please',
        ),
        TravelPhrase(
          id: 'delicious',
          japanese: 'おいしい！',
          romaji: 'Oishii!',
          english: 'Delicious!',
          usageNote: 'Chefs love hearing this.',
        ),
        TravelPhrase(
          id: 'vegetarian',
          japanese: 'ベジタリアンです',
          romaji: 'Bejitarian desu',
          english: 'I am vegetarian',
        ),
        TravelPhrase(
          id: 'allergy',
          japanese: 'アレルギーがあります',
          romaji: 'Arerugii ga arimasu',
          english: 'I have an allergy',
          usageNote: 'Add the food name: 〇〇アレルギーがあります',
        ),
      ],
    ),
    PhraseCategory(
      id: 'transport',
      emoji: '🚄',
      title: 'Transport',
      phrases: [
        TravelPhrase(
          id: 'where_is',
          japanese: '〇〇はどこですか？',
          romaji: '〇〇 wa doko desu ka?',
          english: 'Where is [place]?',
          usageNote: 'Add the place name before は.',
        ),
        TravelPhrase(
          id: 'ticket',
          japanese: '切符をください',
          romaji: 'Kippu wo kudasai',
          english: 'A ticket, please',
        ),
        TravelPhrase(
          id: 'train_to',
          japanese: '〇〇に行く電車はどれですか？',
          romaji: '〇〇 ni iku densha wa dore desu ka?',
          english: 'Which train goes to [place]?',
        ),
        TravelPhrase(
          id: 'last_train',
          japanese: '終電は何時ですか？',
          romaji: 'Shūden wa nanji desu ka?',
          english: 'What time is the last train?',
        ),
        TravelPhrase(
          id: 'taxi',
          japanese: 'タクシーをお願いします',
          romaji: 'Takushii wo onegaishimasu',
          english: 'Please call a taxi',
        ),
        TravelPhrase(
          id: 'go_to',
          japanese: '〇〇まで行ってください',
          romaji: '〇〇 made itte kudasai',
          english: 'Please take me to [place]',
          usageNote: 'Use in taxis.',
        ),
        TravelPhrase(
          id: 'how_much',
          japanese: 'いくらですか？',
          romaji: 'Ikura desu ka?',
          english: 'How much is it?',
        ),
      ],
    ),
    PhraseCategory(
      id: 'shopping',
      emoji: '🛍️',
      title: 'Shopping',
      phrases: [
        TravelPhrase(
          id: 'looking',
          japanese: '見ているだけです',
          romaji: 'Mite iru dake desu',
          english: 'I\'m just looking',
          usageNote: 'Politely decline staff attention.',
        ),
        TravelPhrase(
          id: 'try_on',
          japanese: '試着してもいいですか？',
          romaji: 'Shichaku shite mo ii desu ka?',
          english: 'May I try this on?',
        ),
        TravelPhrase(
          id: 'discount',
          japanese: '割引はありますか？',
          romaji: 'Waribiki wa arimasu ka?',
          english: 'Is there a discount?',
          usageNote: 'Note: haggling is uncommon in Japan.',
        ),
        TravelPhrase(
          id: 'tax_free',
          japanese: '免税で買えますか？',
          romaji: 'Menzei de kaemasu ka?',
          english: 'Can I buy this tax-free?',
          usageNote: 'Tourists can often get tax-free on ¥5,000+ purchases.',
        ),
        TravelPhrase(
          id: 'card',
          japanese: 'カードで払えますか？',
          romaji: 'Kaado de haraemasu ka?',
          english: 'Can I pay by card?',
        ),
        TravelPhrase(
          id: 'receipt',
          japanese: 'レシートをください',
          romaji: 'Reshiito wo kudasai',
          english: 'Please give me a receipt',
        ),
        TravelPhrase(
          id: 'gift_wrap',
          japanese: 'プレゼント用に包んでもらえますか？',
          romaji: 'Purezento you ni tsutsunde moraemasu ka?',
          english: 'Could you gift-wrap it?',
          usageNote: 'Japanese gift wrapping (包装) is beautiful.',
        ),
      ],
    ),
    PhraseCategory(
      id: 'emergency',
      emoji: '🆘',
      title: 'Emergency',
      phrases: [
        TravelPhrase(
          id: 'help',
          japanese: '助けてください！',
          romaji: 'Tasukete kudasai!',
          english: 'Please help me!',
        ),
        TravelPhrase(
          id: 'call_police',
          japanese: '警察を呼んでください',
          romaji: 'Keisatsu wo yonde kudasai',
          english: 'Please call the police',
          usageNote: 'Emergency number: 110 (police), 119 (ambulance/fire).',
        ),
        TravelPhrase(
          id: 'ambulance',
          japanese: '救急車を呼んでください',
          romaji: 'Kyuukyuusha wo yonde kudasai',
          english: 'Please call an ambulance',
        ),
        TravelPhrase(
          id: 'hospital',
          japanese: '病院はどこですか？',
          romaji: 'Byouin wa doko desu ka?',
          english: 'Where is the hospital?',
        ),
        TravelPhrase(
          id: 'lost',
          japanese: '迷子になりました',
          romaji: 'Maigo ni narimashita',
          english: 'I am lost',
        ),
        TravelPhrase(
          id: 'stolen',
          japanese: '盗まれました',
          romaji: 'Nusumaremashita',
          english: 'It was stolen',
        ),
        TravelPhrase(
          id: 'dont_understand',
          japanese: 'わかりません',
          romaji: 'Wakarimasen',
          english: 'I don\'t understand',
        ),
        TravelPhrase(
          id: 'english',
          japanese: '英語が話せる人はいますか？',
          romaji: 'Eigo ga hanaseru hito wa imasu ka?',
          english: 'Is there someone who speaks English?',
        ),
      ],
    ),
    PhraseCategory(
      id: 'hotel',
      emoji: '🏨',
      title: 'Hotel',
      phrases: [
        TravelPhrase(
          id: 'checkin',
          japanese: 'チェックインをお願いします',
          romaji: 'Chekku-in wo onegaishimasu',
          english: 'Check-in, please',
        ),
        TravelPhrase(
          id: 'checkout',
          japanese: 'チェックアウトをお願いします',
          romaji: 'Chekku-auto wo onegaishimasu',
          english: 'Check-out, please',
        ),
        TravelPhrase(
          id: 'lost_key',
          japanese: '部屋のカギをなくしました',
          romaji: 'Heya no kagi wo nakushimashita',
          english: 'I lost my room key',
        ),
        TravelPhrase(
          id: 'wifi_password',
          japanese: 'Wi-Fiのパスワードを教えてください',
          romaji: 'Wai-fai no pasuwaado wo oshiete kudasai',
          english: 'Please tell me the Wi-Fi password',
        ),
        TravelPhrase(
          id: 'more_towel',
          japanese: 'タオルをもう一枚もらえますか？',
          romaji: 'Taoru wo mou ichi-mai moraemasu ka?',
          english: 'Could I have one more towel?',
        ),
        TravelPhrase(
          id: 'wake_up_call',
          japanese: '〇〇時にモーニングコールをお願いします',
          romaji: '〇〇-ji ni mooningu-kooru wo onegaishimasu',
          english: 'Please give me a wake-up call at 〇〇',
          usageNote: 'Replace 〇〇 with the time, e.g. 七時 (shichi-ji) = 7 AM.',
        ),
        TravelPhrase(
          id: 'luggage_storage',
          japanese: '荷物を預かってもらえますか？',
          romaji: 'Nimotsu wo azukatte moraemasu ka?',
          english: 'Could you keep my luggage?',
          usageNote: 'Useful before check-in or after check-out.',
        ),
        TravelPhrase(
          id: 'room_noisy',
          japanese: '隣の部屋がうるさいです',
          romaji: 'Tonari no heya ga urusai desu',
          english: 'The next room is noisy',
        ),
      ],
    ),
    PhraseCategory(
      id: 'health',
      emoji: '🏥',
      title: 'Health',
      phrases: [
        TravelPhrase(
          id: 'feel_sick',
          japanese: '気分が悪いです',
          romaji: 'Kibun ga warui desu',
          english: "I don't feel well",
        ),
        TravelPhrase(
          id: 'headache',
          japanese: '頭が痛いです',
          romaji: 'Atama ga itai desu',
          english: 'I have a headache',
        ),
        TravelPhrase(
          id: 'stomachache',
          japanese: 'お腹が痛いです',
          romaji: 'Onaka ga itai desu',
          english: 'I have a stomachache',
        ),
        TravelPhrase(
          id: 'pharmacy',
          japanese: '薬局はどこですか？',
          romaji: 'Yakkyoku wa doko desu ka?',
          english: 'Where is the pharmacy?',
          usageNote: 'Look for ドラッグストア (drug store) signs.',
        ),
        TravelPhrase(
          id: 'see_doctor',
          japanese: '医者に診てもらいたいです',
          romaji: 'Isha ni mite morai-tai desu',
          english: 'I want to see a doctor',
        ),
        TravelPhrase(
          id: 'this_medicine',
          japanese: 'この薬をください',
          romaji: 'Kono kusuri wo kudasai',
          english: 'Please give me this medicine',
          usageNote: 'Point at the item or show a photo.',
        ),
        TravelPhrase(
          id: 'insurance',
          japanese: '海外旅行保険があります',
          romaji: 'Kaigai ryokou hoken ga arimasu',
          english: 'I have travel insurance',
        ),
      ],
    ),
    PhraseCategory(
      id: 'sightseeing',
      emoji: '🎌',
      title: 'Sightseeing',
      phrases: [
        TravelPhrase(
          id: 'photo_ok',
          japanese: '写真を撮ってもいいですか？',
          romaji: 'Shashin wo totte mo ii desu ka?',
          english: 'May I take a photo?',
          usageNote: 'Always ask inside temples and museums.',
        ),
        TravelPhrase(
          id: 'take_photo_for_me',
          japanese: '写真を撮ってもらえますか？',
          romaji: 'Shashin wo totte moraemasu ka?',
          english: 'Could you take a photo for me?',
        ),
        TravelPhrase(
          id: 'entrance_fee',
          japanese: '入場料はいくらですか？',
          romaji: 'Nyuujouryou wa ikura desu ka?',
          english: 'What is the entrance fee?',
        ),
        TravelPhrase(
          id: 'opening_hours',
          japanese: '何時まで開いていますか？',
          romaji: 'Nanji made aite imasu ka?',
          english: 'Until what time are you open?',
        ),
        TravelPhrase(
          id: 'recommend',
          japanese: 'おすすめはありますか？',
          romaji: 'Osusume wa arimasu ka?',
          english: 'Do you have any recommendations?',
        ),
        TravelPhrase(
          id: 'speak_slowly',
          japanese: 'ゆっくり話してください',
          romaji: 'Yukkuri hanashite kudasai',
          english: 'Please speak slowly',
          usageNote: 'Very useful when staff speak quickly.',
        ),
        TravelPhrase(
          id: 'say_again',
          japanese: 'もう一度言ってください',
          romaji: 'Mou ichido itte kudasai',
          english: 'Please say it again',
        ),
        TravelPhrase(
          id: 'write_it_down',
          japanese: '書いてもらえますか？',
          romaji: 'Kaite moraemasu ka?',
          english: 'Could you write it down?',
          usageNote: 'Helpful when you can\'t catch spoken Japanese.',
        ),
      ],
    ),
    PhraseCategory(
      id: 'numbers',
      emoji: '🔢',
      title: 'Numbers & Time',
      phrases: [
        TravelPhrase(
          id: 'numbers_basic',
          japanese: '一、二、三、四、五、六、七、八、九、十',
          romaji: 'Ichi, ni, san, shi, go, roku, nana, hachi, kyuu, juu',
          english: '1, 2, 3, 4, 5, 6, 7, 8, 9, 10',
          usageNote: 'Four is also "yon"; nine is also "ku". Use fingers to help.',
        ),
        TravelPhrase(
          id: 'what_time',
          japanese: '何時ですか？',
          romaji: 'Nanji desu ka?',
          english: 'What time is it?',
        ),
        TravelPhrase(
          id: 'reservation_time',
          japanese: '〇〇時に予約したいです',
          romaji: '〇〇-ji ni yoyaku shitai desu',
          english: 'I\'d like to make a reservation at 〇〇 o\'clock',
          usageNote: 'Say the number + ji: 七時 (shichi-ji) = 7 o\'clock.',
        ),
        TravelPhrase(
          id: 'today_tomorrow',
          japanese: '今日 / 明日 / 昨日',
          romaji: 'Kyou / Ashita / Kinou',
          english: 'Today / Tomorrow / Yesterday',
        ),
        TravelPhrase(
          id: 'cash_only',
          japanese: '現金のみですか？',
          romaji: 'Genkin nomi desu ka?',
          english: 'Is it cash only?',
          usageNote: 'Many small restaurants and temples are cash only.',
        ),
        TravelPhrase(
          id: 'change',
          japanese: 'おつりをください',
          romaji: 'Otsuri wo kudasai',
          english: 'Please give me change',
        ),
        TravelPhrase(
          id: 'how_many_minutes',
          japanese: '何分かかりますか？',
          romaji: 'Nanpun kakarimasu ka?',
          english: 'How many minutes will it take?',
        ),
      ],
    ),
    PhraseCategory(
      id: 'nature',
      emoji: '🌸',
      title: 'Nature & Weather',
      phrases: [
        TravelPhrase(
          id: 'cherry_blossom',
          japanese: '桜がきれいですね',
          romaji: 'Sakura ga kirei desu ne',
          english: 'The cherry blossoms are beautiful, aren\'t they?',
          usageNote: 'A perfect icebreaker during hanami season (late March–April).',
        ),
        TravelPhrase(
          id: 'hot_today',
          japanese: '今日は暑いですね',
          romaji: 'Kyou wa atsui desu ne',
          english: 'It\'s hot today, isn\'t it?',
          usageNote: 'Weather small talk is universal. Replace with 寒い (samui) for cold.',
        ),
        TravelPhrase(
          id: 'rain_forecast',
          japanese: '雨が降りそうですね',
          romaji: 'Ame ga furi-sou desu ne',
          english: 'It looks like it might rain, doesn\'t it?',
        ),
        TravelPhrase(
          id: 'Mt_fuji',
          japanese: '富士山はどこから見えますか？',
          romaji: 'Fujisan wa doko kara miemasu ka?',
          english: 'From where can you see Mount Fuji?',
        ),
        TravelPhrase(
          id: 'umbrella_borrow',
          japanese: '傘を貸してもらえますか？',
          romaji: 'Kasa wo kashite moraemasu ka?',
          english: 'Could you lend me an umbrella?',
          usageNote: 'Many convenience stores sell cheap umbrellas for ¥500–700.',
        ),
        TravelPhrase(
          id: 'typhoon',
          japanese: '台風が来ていますか？',
          romaji: 'Taifuu ga kite imasu ka?',
          english: 'Is a typhoon coming?',
          usageNote: 'Typhoon season is June–October. Check NHK World for updates.',
        ),
      ],
    ),
    PhraseCategory(
      id: 'onsen',
      emoji: '♨️',
      title: 'Onsen & Bath',
      phrases: [
        TravelPhrase(
          id: 'onsen_tattoo',
          japanese: 'タトゥーがありますが、入れますか？',
          romaji: 'Tattoo ga arimasu ga, hairemasu ka?',
          english: 'I have a tattoo — am I allowed to enter?',
          usageNote: 'Many onsen prohibit tattoos. Ask beforehand to avoid awkwardness.',
        ),
        TravelPhrase(
          id: 'onsen_towel',
          japanese: 'タオルは貸してもらえますか？',
          romaji: 'Taoru wa kashite moraemasu ka?',
          english: 'Can I borrow a towel?',
        ),
        TravelPhrase(
          id: 'onsen_mixed',
          japanese: '混浴はありますか？',
          romaji: 'Konyoku wa arimasu ka?',
          english: 'Is there a mixed-gender bath?',
        ),
        TravelPhrase(
          id: 'wash_before',
          japanese: '入る前に体を洗ってください',
          romaji: 'Hairu mae ni karada wo aratte kudasai',
          english: 'Please wash your body before entering',
          usageNote: 'This is essential etiquette — always shower before the communal bath.',
        ),
        TravelPhrase(
          id: 'onsen_hot',
          japanese: '熱すぎます',
          romaji: 'Atsusugimasu',
          english: 'It\'s too hot',
        ),
        TravelPhrase(
          id: 'onsen_checkout',
          japanese: 'チェックアウトは何時ですか？',
          romaji: 'Chekkuauto wa nanji desu ka?',
          english: 'What time is checkout?',
        ),
      ],
    ),
    PhraseCategory(
      id: 'shrine_temple',
      emoji: '⛩️',
      title: 'Shrines & Temples',
      phrases: [
        TravelPhrase(
          id: 'entrance_fee',
          japanese: '拝観料はいくらですか？',
          romaji: 'Haikanryou wa ikura desu ka?',
          english: 'How much is the admission fee?',
        ),
        TravelPhrase(
          id: 'omikuji',
          japanese: 'おみくじはどこですか？',
          romaji: 'Omikuji wa doko desu ka?',
          english: 'Where are the fortune slips?',
          usageNote: 'Omikuji are paper fortunes ranging from great luck (大吉) to great misfortune (大凶).',
        ),
        TravelPhrase(
          id: 'prayer',
          japanese: 'お参りしてもいいですか？',
          romaji: 'Omairi shite mo ii desu ka?',
          english: 'May I pray here?',
        ),
        TravelPhrase(
          id: 'photo_ok',
          japanese: '写真を撮ってもいいですか？',
          romaji: 'Shashin wo totte mo ii desu ka?',
          english: 'May I take a photo?',
          usageNote: 'Always ask inside temple halls. Some areas prohibit photography.',
        ),
        TravelPhrase(
          id: 'goshuin',
          japanese: '御朱印をいただけますか？',
          romaji: 'Goshuin wo itadakemasu ka?',
          english: 'May I receive a stamp seal (goshuin)?',
          usageNote: 'Goshuin are calligraphic ink stamps given at shrines/temples. Bring a goshuin-cho (stamp book).',
        ),
        TravelPhrase(
          id: 'close_time',
          japanese: '閉門時間は何時ですか？',
          romaji: 'Heimon jikan wa nanji desu ka?',
          english: 'What time do the gates close?',
        ),
      ],
    ),
    PhraseCategory(
      id: 'izakaya',
      emoji: '🍻',
      title: 'Izakaya & Nightlife',
      phrases: [
        TravelPhrase(
          id: 'kanpai',
          japanese: '乾杯！',
          romaji: 'Kanpai!',
          english: 'Cheers!',
          usageNote: 'Wait until everyone has a drink and make eye contact when clinking glasses.',
        ),
        TravelPhrase(
          id: 'one_more',
          japanese: 'もう一杯ください',
          romaji: 'Mou ippai kudasai',
          english: 'One more drink please',
        ),
        TravelPhrase(
          id: 'nomihodai',
          japanese: '飲み放題はありますか？',
          romaji: 'Nomihodai wa arimasu ka?',
          english: 'Is there all-you-can-drink?',
          usageNote: 'Nomihodai is very common at izakayas, usually 90 min for ¥1,500–2,500.',
        ),
        TravelPhrase(
          id: 'no_alcohol',
          japanese: 'アルコール抜きでお願いします',
          romaji: 'Arukooru nuki de onegai shimasu',
          english: 'Without alcohol please',
        ),
        TravelPhrase(
          id: 'last_order',
          japanese: 'ラストオーダーは何時ですか？',
          romaji: 'Rasuto oodaa wa nanji desu ka?',
          english: 'What time is last order?',
        ),
        TravelPhrase(
          id: 'bill_split',
          japanese: '割り勘でお願いします',
          romaji: 'Warikan de onegai shimasu',
          english: 'We\'d like to split the bill',
          usageNote: 'Warikan (split equally) is very common among friends in Japan.',
        ),
        TravelPhrase(
          id: 'otoshi',
          japanese: 'お通しは何ですか？',
          romaji: 'Otoshi wa nan desu ka?',
          english: 'What is the otoshi (table charge appetizer)?',
          usageNote: 'Otoshi is a small appetizer that doubles as a cover charge (¥300–600). It\'s standard at izakayas.',
        ),
      ],
    ),
    PhraseCategory(
      id: 'convenience',
      emoji: '🏪',
      title: 'Convenience Store',
      phrases: [
        TravelPhrase(
          id: 'heat_up',
          japanese: '温めてもらえますか？',
          romaji: 'Atatamete moraemasu ka?',
          english: 'Could you heat this up?',
          usageNote: 'Konbini staff will microwave food purchases — just ask.',
        ),
        TravelPhrase(
          id: 'bag_needed',
          japanese: '袋をください',
          romaji: 'Fukuro wo kudasai',
          english: 'Please give me a bag',
          usageNote: 'Japan charges for plastic bags (¥3–5). Ask if you need one.',
        ),
        TravelPhrase(
          id: 'atm_location',
          japanese: 'ATMはどこですか？',
          romaji: 'ATM wa doko desu ka?',
          english: 'Where is the ATM?',
          usageNote: '7-Eleven and Japan Post ATMs accept most foreign cards.',
        ),
        TravelPhrase(
          id: 'copy_machine',
          japanese: 'コピー機はどこですか？',
          romaji: 'Kopii-ki wa doko desu ka?',
          english: 'Where is the copy/print machine?',
          usageNote: 'Konbini printers can print documents and even tourist tickets.',
        ),
        TravelPhrase(
          id: 'suica_charge',
          japanese: 'Suicaにチャージしたいです',
          romaji: 'Suica ni chaaji shitai desu',
          english: 'I\'d like to charge my Suica card',
        ),
        TravelPhrase(
          id: 'receipt',
          japanese: 'レシートをください',
          romaji: 'Reshiito wo kudasai',
          english: 'Please give me a receipt',
        ),
      ],
    ),
  ];

  static List<TravelPhrase> search(String query) {
    final q = query.toLowerCase();
    return categories
        .expand((c) => c.phrases)
        .where((p) =>
            p.english.toLowerCase().contains(q) ||
            p.romaji.toLowerCase().contains(q) ||
            p.japanese.contains(q))
        .toList();
  }
}

/// A single cultural knowledge quiz question.
class CulturalChallenge {
  final String id;
  final ChallengeCategory category;
  final String question;
  final List<String> options;  // exactly 4
  final int correctIndex;
  final String explanation;
  final int xpCorrect;
  final int xpAttempt; // XP even for wrong answer (for trying)

  const CulturalChallenge({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.xpCorrect = 15,
    this.xpAttempt = 5,
  });
}

enum ChallengeCategory {
  history,
  etiquette,
  food,
  language,
  customs,
}

extension ChallengeCategoryExt on ChallengeCategory {
  String get label {
    switch (this) {
      case ChallengeCategory.history:   return 'History';
      case ChallengeCategory.etiquette: return 'Etiquette';
      case ChallengeCategory.food:      return 'Food & Drink';
      case ChallengeCategory.language:  return 'Language';
      case ChallengeCategory.customs:   return 'Customs';
    }
  }

  String get emoji {
    switch (this) {
      case ChallengeCategory.history:   return '⛩️';
      case ChallengeCategory.etiquette: return '🙇';
      case ChallengeCategory.food:      return '🍣';
      case ChallengeCategory.language:  return '📝';
      case ChallengeCategory.customs:   return '🎋';
    }
  }
}

/// Static bank of 35 cultural questions.
class ChallengeBank {
  static const all = <CulturalChallenge>[
    // ── History ──────────────────────────────────────────────────────────
    CulturalChallenge(
      id: 'h_01',
      category: ChallengeCategory.history,
      question: 'In which century did the samurai warrior class emerge as a dominant force in Japan?',
      options: ['6th century', '8th century', '10th century', '12th century'],
      correctIndex: 3,
      explanation: 'The samurai rose to power in the 12th century, especially after the Genpei War (1180–1185), which established the first shogunate under Minamoto no Yoritomo.',
    ),
    CulturalChallenge(
      id: 'h_02',
      category: ChallengeCategory.history,
      question: 'What is the name of Japan\'s ancient imperial capital city, founded in 710 AD?',
      options: ['Kyoto', 'Nara', 'Osaka', 'Kamakura'],
      correctIndex: 1,
      explanation: 'Nara (then called Heijō-kyō) was Japan\'s first permanent capital, established in 710 AD. It\'s famous for its giant Buddha and free-roaming deer.',
    ),
    CulturalChallenge(
      id: 'h_03',
      category: ChallengeCategory.history,
      question: 'For how many years was Japan closed to almost all foreign contact during the Edo period?',
      options: ['50 years', '100 years', '200 years', '300 years'],
      correctIndex: 2,
      explanation: 'Japan\'s sakoku (closed country) policy lasted roughly 200 years, from 1639 to 1853, when Commodore Perry\'s "Black Ships" forced Japan to open its ports.',
    ),
    CulturalChallenge(
      id: 'h_04',
      category: ChallengeCategory.history,
      question: 'What is the famous golden pavilion in Kyoto called?',
      options: ['Ginkaku-ji', 'Kinkaku-ji', 'Ryoan-ji', 'Fushimi Inari'],
      correctIndex: 1,
      explanation: 'Kinkaku-ji (金閣寺) is the "Temple of the Golden Pavilion." The top two floors are covered in gold leaf. Ginkaku-ji is the Silver Pavilion (though it\'s not actually silver).',
    ),
    CulturalChallenge(
      id: 'h_05',
      category: ChallengeCategory.history,
      question: 'What does "Meiji Restoration" refer to?',
      options: [
        'A period of Buddhist temple rebuilding',
        'The return of imperial rule and Japan\'s rapid modernization in 1868',
        'A major earthquake recovery effort',
        'The unification of Japan\'s feudal domains',
      ],
      correctIndex: 1,
      explanation: 'The Meiji Restoration of 1868 ended the Shogunate, restored Emperor Meiji to power, and launched Japan\'s astonishing transformation from a feudal state to a modern industrialized nation.',
    ),
    CulturalChallenge(
      id: 'h_06',
      category: ChallengeCategory.history,
      question: 'Which city served as Japan\'s capital for over 1,000 years before Tokyo?',
      options: ['Nara', 'Osaka', 'Kyoto', 'Kamakura'],
      correctIndex: 2,
      explanation: 'Kyoto (originally Heian-kyō) was Japan\'s imperial capital from 794 until 1869, when Emperor Meiji moved the capital to Edo, which was renamed Tokyo.',
    ),
    CulturalChallenge(
      id: 'h_07',
      category: ChallengeCategory.history,
      question: 'What are the three "unifiers" of Japan who ended the Sengoku period of civil war?',
      options: [
        'Tokugawa, Toyotomi, Minamoto',
        'Oda Nobunaga, Toyotomi Hideyoshi, Tokugawa Ieyasu',
        'Minamoto, Taira, Ashikaga',
        'Honda, Yamamoto, Kuroda',
      ],
      correctIndex: 1,
      explanation: 'Oda Nobunaga began unification, Toyotomi Hideyoshi continued it, and Tokugawa Ieyasu completed it by establishing the Tokugawa Shogunate after the Battle of Sekigahara in 1600.',
    ),

    // ── Etiquette ────────────────────────────────────────────────────────
    CulturalChallenge(
      id: 'e_01',
      category: ChallengeCategory.etiquette,
      question: 'What should you do before entering a traditional Japanese home?',
      options: [
        'Knock and wait to be invited',
        'Remove your shoes in the genkan (entryway)',
        'Bring a gift wrapped in red paper',
        'Bow three times',
      ],
      correctIndex: 1,
      explanation: 'Removing shoes in the genkan (玄関) is essential in Japanese homes and many traditional establishments. This keeps the living space clean and is a deeply ingrained cultural practice.',
    ),
    CulturalChallenge(
      id: 'e_02',
      category: ChallengeCategory.etiquette,
      question: 'When eating ramen in Japan, what is considered an acceptable — even complimentary — sound to make?',
      options: ['Tapping chopsticks on the bowl', 'Slurping noodles loudly', 'Clicking fingers for the staff', 'Blowing on the broth'],
      correctIndex: 1,
      explanation: 'Slurping noodles is perfectly acceptable in Japan and can signal to the chef that you\'re enjoying your meal. It\'s not considered rude — quite the opposite!',
    ),
    CulturalChallenge(
      id: 'e_03',
      category: ChallengeCategory.etiquette,
      question: 'What is considered rude to do on the Tokyo subway?',
      options: [
        'Reading a book',
        'Talking on your phone',
        'Sleeping',
        'Eating a sandwich',
      ],
      correctIndex: 1,
      explanation: 'Talking on your phone is frowned upon on Japanese trains. Most passengers stay silent or use quiet earphones. Signs explicitly ask passengers to keep phone calls brief or silent.',
    ),
    CulturalChallenge(
      id: 'e_04',
      category: ChallengeCategory.etiquette,
      question: 'How should you hand money to a cashier in Japan?',
      options: [
        'Place it directly in the cashier\'s hand',
        'Throw it on the counter',
        'Place it on the small tray provided',
        'Use only contactless payment',
      ],
      correctIndex: 2,
      explanation: 'Most Japanese shops have a small cash tray (sometimes called a "calton") at the register specifically for placing cash and receiving change. This avoids direct hand contact and is considered proper etiquette.',
    ),
    CulturalChallenge(
      id: 'e_05',
      category: ChallengeCategory.etiquette,
      question: 'When giving or receiving a business card (meishi) in Japan, what is the proper way to handle it?',
      options: [
        'Immediately put it in your pocket',
        'Receive with both hands, read it carefully, and treat it respectfully',
        'Fold it if you\'re taking notes',
        'Write on it to confirm contact details',
      ],
      correctIndex: 1,
      explanation: 'The meishi (名刺) exchange ritual is highly important in Japan. Receive and give cards with both hands, read it attentively, and never write on or fold a business card — it\'s seen as disrespecting the person.',
    ),

    // ── Food ─────────────────────────────────────────────────────────────
    CulturalChallenge(
      id: 'f_01',
      category: ChallengeCategory.food,
      question: 'What is "umami" — often called the fifth basic taste?',
      options: [
        'A combination of sweet and sour',
        'A savory, meaty taste from glutamate compounds',
        'The bitterness of green tea',
        'The heat from wasabi',
      ],
      correctIndex: 1,
      explanation: 'Umami (旨味) was identified by Japanese scientist Kikunae Ikeda in 1908. It\'s the savory taste of glutamate, found in dashi, soy sauce, miso, mushrooms, and aged cheeses.',
    ),
    CulturalChallenge(
      id: 'f_02',
      category: ChallengeCategory.food,
      question: 'What is the difference between sashimi and sushi?',
      options: [
        'Sashimi uses raw fish; sushi uses only vegetables',
        'Sashimi is raw fish alone; sushi is fish/toppings with vinegared rice',
        'They are the same dish with different names',
        'Sashimi is cooked; sushi is raw',
      ],
      correctIndex: 1,
      explanation: 'Sashimi (刺身) is sliced raw fish or seafood served alone. Sushi (寿司) pairs fish or other toppings with vinegared rice. Sushi can actually be made with cooked or pickled ingredients too.',
    ),
    CulturalChallenge(
      id: 'f_03',
      category: ChallengeCategory.food,
      question: 'What is "matcha" and how does it differ from regular green tea?',
      options: [
        'Matcha is fermented green tea; regular green tea is fresh',
        'Matcha is powdered whole green tea leaves; regular green tea is steeped leaves',
        'Matcha is a red tea; green tea is lighter',
        'They are identical — just different spellings',
      ],
      correctIndex: 1,
      explanation: 'Matcha (抹茶) is made from shade-grown tea leaves ground into a fine powder. You consume the entire leaf, making it more nutrient-dense than regular sencha, which is brewed by steeping leaves.',
    ),
    CulturalChallenge(
      id: 'f_04',
      category: ChallengeCategory.food,
      question: 'What does "omakase" mean in a Japanese restaurant?',
      options: [
        'All-you-can-eat',
        '"I leave it to you" — chef\'s choice tasting menu',
        'A specific type of ramen',
        'A vegetarian menu option',
      ],
      correctIndex: 1,
      explanation: 'Omakase (お任せ) means "I leave it to you." The chef selects and prepares each course based on the best available seasonal ingredients. It\'s the ultimate expression of trust between chef and diner.',
    ),
    CulturalChallenge(
      id: 'f_05',
      category: ChallengeCategory.food,
      question: 'What is the main ingredient distinguishing miso soup\'s dashi broth in most traditional Japanese cooking?',
      options: ['Dried shrimp', 'Kombu (kelp) and katsuobushi (dried bonito flakes)', 'Chicken stock', 'Soy sauce and sake'],
      correctIndex: 1,
      explanation: 'Traditional dashi (出汁) is made from kombu (dried kelp) and katsuobushi (bonito flakes). This combination creates the umami-rich base for miso soup, ramen broth, and many sauces.',
    ),
    CulturalChallenge(
      id: 'f_06',
      category: ChallengeCategory.food,
      question: 'What is "yakitori"?',
      options: [
        'Deep-fried pork cutlet',
        'Grilled chicken skewers seasoned with salt or tare sauce',
        'A type of sushi roll',
        'Pan-fried gyoza dumplings',
      ],
      correctIndex: 1,
      explanation: 'Yakitori (焼き鳥) literally means "grilled bird." Small pieces of chicken are skewered and grilled over charcoal, seasoned with either salt (shio) or sweet tare sauce. Every part of the chicken is used.',
    ),

    // ── Language ──────────────────────────────────────────────────────────
    CulturalChallenge(
      id: 'l_01',
      category: ChallengeCategory.language,
      question: 'How many writing systems does Japanese use?',
      options: ['1', '2', '3', '4'],
      correctIndex: 2,
      explanation: 'Japanese uses three writing systems: hiragana (phonetic, native words), katakana (phonetic, foreign words/emphasis), and kanji (Chinese characters with Japanese readings). Romaji (Latin script) is sometimes counted as a fourth.',
    ),
    CulturalChallenge(
      id: 'l_02',
      category: ChallengeCategory.language,
      question: 'What does "sumimasen" (すみません) mean?',
      options: [
        'Good morning',
        'Excuse me / I\'m sorry / Thank you (for the inconvenience)',
        'Where is the bathroom?',
        'How much does this cost?',
      ],
      correctIndex: 1,
      explanation: 'Sumimasen is one of the most versatile phrases in Japanese. Use it to get someone\'s attention, to apologize for a small inconvenience, or to express gratitude for trouble taken on your behalf.',
    ),
    CulturalChallenge(
      id: 'l_03',
      category: ChallengeCategory.language,
      question: 'What is the Japanese word for "thank you very much" in its most polite form?',
      options: ['Arigatou', 'Domo', 'Arigatou gozaimasu', 'Kansha shimasu'],
      correctIndex: 2,
      explanation: '"Arigatou gozaimasu" (ありがとうございます) is the most polite form of thank you. "Arigatou" alone is casual, suitable for friends. "Domo" is very casual, like just saying "thanks."',
    ),
    CulturalChallenge(
      id: 'l_04',
      category: ChallengeCategory.language,
      question: 'What does the Japanese counter "-hon" (-本) count?',
      options: ['Round objects like balls', 'Flat objects like paper', 'Long, thin objects like pens, bottles, and roads', 'Small animals'],
      correctIndex: 2,
      explanation: 'Japanese has specific counters for different shapes. -Hon (本) counts long, thin objects: pencils, bottles, umbrellas, rivers, and even phone calls. Counting in Japanese requires matching the counter to the object type.',
    ),
    CulturalChallenge(
      id: 'l_05',
      category: ChallengeCategory.language,
      question: 'What does "kawaii" (かわいい) mean?',
      options: ['Scary / frightening', 'Cute / adorable', 'Delicious', 'Fast / quick'],
      correctIndex: 1,
      explanation: 'Kawaii (可愛い) means cute or adorable. It\'s one of the most pervasive concepts in Japanese culture, influencing fashion, art, consumer products, and even corporate mascots.',
    ),
    CulturalChallenge(
      id: 'l_06',
      category: ChallengeCategory.language,
      question: 'What is the meaning of "omotenashi" (おもてなし)?',
      options: [
        'A type of Japanese noodle dish',
        'Wholehearted hospitality with no expectation of reward',
        'A form of martial arts',
        'A traditional greeting bow',
      ],
      correctIndex: 1,
      explanation: 'Omotenashi (おもてなし) is the Japanese concept of wholehearted hospitality — anticipating guests\' needs without being asked, and providing service without expectation of reward or tip.',
    ),

    // ── Customs ──────────────────────────────────────────────────────────
    CulturalChallenge(
      id: 'c_01',
      category: ChallengeCategory.customs,
      question: 'What is "hanami" and when does it typically take place?',
      options: [
        'A winter fire ceremony in December',
        'Cherry blossom viewing parties in spring',
        'A harvest festival in autumn',
        'A New Year\'s shrine visit',
      ],
      correctIndex: 1,
      explanation: 'Hanami (花見) means "flower viewing." People gather under blooming sakura (cherry blossom) trees, typically in late March to early April, to eat, drink, and enjoy the fleeting beauty of the blossoms.',
    ),
    CulturalChallenge(
      id: 'c_02',
      category: ChallengeCategory.customs,
      question: 'What is "hatsumode"?',
      options: [
        'The first cup of sake of the New Year',
        'A traditional coming-of-age ceremony',
        'The first shrine or temple visit of the New Year',
        'A type of new year\'s food',
      ],
      correctIndex: 2,
      explanation: 'Hatsumode (初詣) is the first visit to a Shinto shrine or Buddhist temple after New Year. Millions visit in the first three days of January to pray for good fortune in the coming year.',
    ),
    CulturalChallenge(
      id: 'c_03',
      category: ChallengeCategory.customs,
      question: 'What is O-Bon (お盆)?',
      options: [
        'A summer music festival',
        'A Buddhist festival to honor ancestors\' spirits',
        'A national sports day',
        'A type of traditional dance performance',
      ],
      correctIndex: 1,
      explanation: 'O-Bon is a Buddhist festival honoring deceased ancestors whose spirits are believed to return to visit the living. Celebrated mid-August, it includes lantern floating, bon odori dancing, and family reunions.',
    ),
    CulturalChallenge(
      id: 'c_04',
      category: ChallengeCategory.customs,
      question: 'In Japan, what color are traditional mourning clothes at funerals?',
      options: ['White', 'Black', 'Dark blue', 'Grey'],
      correctIndex: 1,
      explanation: 'Black (黒) is worn at Japanese funerals, similar to Western conventions. White is also linked to death in some traditional contexts (white kimono for burial), though it can equally signify purity in celebrations.',
    ),
    CulturalChallenge(
      id: 'c_05',
      category: ChallengeCategory.customs,
      question: 'What is the significance of the "torii gate" at a Shinto shrine?',
      options: [
        'It marks the boundary between the sacred and ordinary worlds',
        'It is purely decorative',
        'It indicates the shrine\'s ranking in importance',
        'It was historically used as a market entrance',
      ],
      correctIndex: 0,
      explanation: 'The torii (鳥居) marks the transition from the mundane world to the sacred space of the shrine. Walking through one symbolically purifies you as you enter the divine realm. You should bow before passing through.',
    ),
    CulturalChallenge(
      id: 'c_06',
      category: ChallengeCategory.customs,
      question: 'What should you do before drinking in a group in Japan?',
      options: [
        'Pour your own drink first',
        'Wait until everyone is served, then say "Kanpai!" (cheers) together',
        'Take the first sip silently as a sign of respect',
        'Offer a toast speech lasting at least 2 minutes',
      ],
      correctIndex: 1,
      explanation: 'In Japan, you wait until everyone has their drink, then say "Kanpai!" (乾杯) together before the first sip. Also, it\'s polite to pour for others rather than yourself — watch others\' glasses and refill them.',
    ),
    CulturalChallenge(
      id: 'c_07',
      category: ChallengeCategory.customs,
      question: 'What is the tradition of "omiyage"?',
      options: [
        'A formal letter written to introduce yourself',
        'Bringing back local food gifts for coworkers and family after traveling',
        'A type of flower arrangement',
        'A ceremony marking the end of a meal',
      ],
      correctIndex: 1,
      explanation: 'Omiyage (お土産) is the deeply ingrained custom of bringing back local specialty foods as gifts when you travel. It\'s an expression of thoughtfulness and social obligation, and is taken very seriously in Japanese work culture.',
    ),
    CulturalChallenge(
      id: 'c_08',
      category: ChallengeCategory.customs,
      question: 'What is "wabi-sabi" in Japanese aesthetics?',
      options: [
        'The love of perfect symmetry and luxury',
        'The beauty found in imperfection, impermanence, and incompleteness',
        'A decorative style using bright colors',
        'A form of rock garden design',
      ],
      correctIndex: 1,
      explanation: 'Wabi-sabi (侘び寂び) is a fundamental Japanese aesthetic — finding beauty in the imperfect, transient, and incomplete. It\'s seen in cracked pottery repaired with gold (kintsugi), weathered wood, and the fading of cherry blossoms.',
    ),

    // ── History (additional) ─────────────────────────────────────────────
    CulturalChallenge(
      id: 'h_08',
      category: ChallengeCategory.history,
      question: 'What was the name of Japan\'s military government ruled by shoguns?',
      options: ['Mikado', 'Shogunate (Bakufu)', 'Daimyo Council', 'Imperial Court'],
      correctIndex: 1,
      explanation: 'The Shogunate (幕府, Bakufu) was Japan\'s de facto military government from 1185 to 1868. While the Emperor remained a symbolic figure, real power rested with the shogun, a hereditary military dictator.',
    ),
    CulturalChallenge(
      id: 'h_09',
      category: ChallengeCategory.history,
      question: 'Which event in 1945 led directly to Japan\'s surrender in World War II?',
      options: [
        'The Battle of Okinawa',
        'The atomic bombings of Hiroshima and Nagasaki',
        'The Soviet declaration of war',
        'All of the above contributed',
      ],
      correctIndex: 3,
      explanation: 'Japan\'s surrender resulted from a combination: the atomic bombings of Hiroshima (Aug 6) and Nagasaki (Aug 9), Soviet declaration of war (Aug 8), and the emperor\'s own decision. Historians debate the relative weight of each factor.',
    ),
    CulturalChallenge(
      id: 'h_10',
      category: ChallengeCategory.history,
      question: 'What were "daimyo" in feudal Japan?',
      options: [
        'Traveling merchants who traded between regions',
        'Powerful feudal lords who controlled large domains',
        'Elite ninja commanders',
        'Buddhist high priests',
      ],
      correctIndex: 1,
      explanation: 'Daimyo (大名) were powerful feudal lords who ruled large territories called domains (han). They commanded armies of samurai, collected taxes, and pledged allegiance to the shogun. There were about 250 daimyo domains at the start of the Meiji period.',
    ),

    // ── Etiquette (additional) ─────────────────────────────────────────────
    CulturalChallenge(
      id: 'e_06',
      category: ChallengeCategory.etiquette,
      question: 'What does it mean when a Japanese person sucks air through their teeth with a hissing sound?',
      options: [
        'They are expressing anger',
        'They are signaling that something is difficult or impossible',
        'They are asking you to be quieter',
        'It is a traditional greeting',
      ],
      correctIndex: 1,
      explanation: 'The sucking-teeth sound (tsk or hiss) is a common Japanese non-verbal cue meaning "this is difficult," "I\'m not sure," or politely "no." It\'s often followed by "chotto..." (a bit...) — Japan\'s classic indirect refusal.',
    ),
    CulturalChallenge(
      id: 'e_07',
      category: ChallengeCategory.etiquette,
      question: 'In Japan, when is it considered appropriate to eat or drink while walking?',
      options: [
        'Always — convenience is valued',
        'Only at festivals and street food areas',
        'Never — it is always rude',
        'Only beverages are acceptable',
      ],
      correctIndex: 1,
      explanation: 'Eating while walking (aruki-gui) is generally considered bad manners in Japan. The exception is at festivals (matsuri) and designated street food areas like Nakamise in Asakusa, where vendors explicitly sell food to eat on the spot.',
    ),
    CulturalChallenge(
      id: 'e_08',
      category: ChallengeCategory.etiquette,
      question: 'Which of these chopstick actions are taboo in Japan?',
      options: [
        'Sticking them upright into a bowl of rice',
        'Resting them on the chopstick holder between bites',
        'Passing food directly from your chopsticks to someone else\'s',
        'Both sticking upright in rice (A) and passing food directly (C)',
      ],
      correctIndex: 3,
      explanation: 'Two major taboos: (1) sticking chopsticks upright in rice resembles incense at funerals, and (2) passing food directly from chopstick to chopstick mimics a funeral bone-passing ceremony. Both are deeply associated with death.',
    ),

    // ── Food (additional) ────────────────────────────────────────────────
    CulturalChallenge(
      id: 'f_07',
      category: ChallengeCategory.food,
      question: 'What is the difference between miso soup served at breakfast vs. dinner in Japan?',
      options: [
        'Breakfast miso is always white (shiro); dinner is always red (aka)',
        'There is typically no difference — miso soup is served at every meal',
        'Breakfast miso is thicker; dinner miso is lighter',
        'Miso soup is only served at dinner in traditional settings',
      ],
      correctIndex: 1,
      explanation: 'Miso soup (味噌汁) is a staple at Japanese breakfast, lunch, and dinner. Japan has over 1,000 varieties of miso — regional differences are significant. Kyoto tends toward lighter white miso; Nagoya prefers rich red Hatcho miso.',
    ),
    CulturalChallenge(
      id: 'f_08',
      category: ChallengeCategory.food,
      question: 'What is "kaiseki" cuisine?',
      options: [
        'A fast food chain unique to Japan',
        'A multi-course Japanese haute cuisine rooted in tea ceremony',
        'A type of communal hot pot meal',
        'Street food eaten at night markets',
      ],
      correctIndex: 1,
      explanation: 'Kaiseki (懐石/会席) is Japan\'s highest form of cuisine — an artistic multi-course meal that emphasizes seasonal ingredients, balanced flavors, and exquisite presentation. It evolved from the simple meal served before tea ceremony.',
    ),
    CulturalChallenge(
      id: 'f_09',
      category: ChallengeCategory.food,
      question: 'What is "natto" and why do many foreigners find it challenging?',
      options: [
        'A very spicy curry — too hot for most palates',
        'Fermented soybeans with a strong smell, sticky texture, and stringy consistency',
        'A raw fish dish served at room temperature',
        'A bitter green vegetable with an acquired taste',
      ],
      correctIndex: 1,
      explanation: 'Natto (納豆) is a traditional breakfast food made of fermented soybeans. Its strong ammonia-like smell, sticky mucilage, and stringy "neba-neba" texture challenge most newcomers. But it\'s extremely nutritious and is loved by many Japanese.',
    ),

    // ── Language (additional) ────────────────────────────────────────────
    CulturalChallenge(
      id: 'l_07',
      category: ChallengeCategory.language,
      question: 'What does "itadakimasu" mean and when is it said?',
      options: [
        '"Goodbye" — said when leaving a restaurant',
        '"I humbly receive" — said before eating a meal',
        '"Thank you for the food" — said after finishing a meal',
        '"Welcome" — said by restaurant staff to customers',
      ],
      correctIndex: 1,
      explanation: '"Itadakimasu" (いただきます) is said before eating and literally means "I humbly receive." It expresses gratitude to everyone involved in the meal — farmers, cooks, and the food itself. The post-meal equivalent is "gochisousama deshita."',
    ),
    CulturalChallenge(
      id: 'l_08',
      category: ChallengeCategory.language,
      question: 'What is "keigo" in Japanese?',
      options: [
        'A type of traditional poetry with 5-7-5 syllable structure',
        'The formal honorific language system used in professional and polite contexts',
        'A regional dialect spoken in Kyoto',
        'The written form of Japanese using only kanji',
      ],
      correctIndex: 1,
      explanation: 'Keigo (敬語) is Japanese\'s elaborate honorific speech system with three levels: sonkeigo (respectful, for others\' actions), kenjougo (humble, for your own actions), and teineigo (polite, everyday formal speech). Mastering keigo takes Japanese people years.',
    ),
    CulturalChallenge(
      id: 'l_09',
      category: ChallengeCategory.language,
      question: 'What does "yabai" (ヤバい) mean in modern Japanese slang?',
      options: [
        'Only "dangerous" or "bad" — its original meaning',
        'Delicious — a food-specific compliment',
        'Either "amazing/awesome" OR "terrible/dangerous" depending on context',
        'Very tired or exhausted',
      ],
      correctIndex: 2,
      explanation: 'Yabai originally meant "dangerous" or "bad." In modern slang (especially among younger Japanese), it has expanded to also mean "amazing," "incredible," or "awesome" — the opposite meaning. Context and tone determine which is meant.',
    ),

    // ── Customs (additional) ─────────────────────────────────────────────
    CulturalChallenge(
      id: 'c_09',
      category: ChallengeCategory.customs,
      question: 'What is "nemawashi" in Japanese business culture?',
      options: [
        'A type of bonsai pruning technique',
        'The practice of building consensus before a formal meeting through informal discussions',
        'A ceremonial gift-giving ritual at contract signing',
        'A method of bowing that indicates seniority',
      ],
      correctIndex: 1,
      explanation: 'Nemawashi (根回し, literally "going around the roots") is the Japanese practice of quietly sounding out stakeholders and building consensus before a proposal is formally presented. By the time of the official meeting, agreement is already reached behind the scenes.',
    ),
    CulturalChallenge(
      id: 'c_10',
      category: ChallengeCategory.customs,
      question: 'What is "karoshi" and why is it a significant social issue in Japan?',
      options: [
        'A traditional coming-of-age ceremony at age 20',
        'Death from overwork — a recognized medical and legal cause of death',
        'A custom of extreme fasting during religious festivals',
        'The practice of working multiple part-time jobs',
      ],
      correctIndex: 1,
      explanation: 'Karoshi (過労死) means "death from overwork" and is a recognized cause of death in Japan, typically from heart attack, stroke, or suicide caused by extreme workplace stress. Japan has implemented "Premium Friday" and overtime caps to combat it.',
    ),
    CulturalChallenge(
      id: 'c_11',
      category: ChallengeCategory.customs,
      question: 'What is "shokunin" spirit in Japanese craftsmanship?',
      options: [
        'The belief that supernatural spirits inhabit handmade objects',
        'A dedication to mastery and perfection of one\'s craft through lifelong practice',
        'A union of craftsmen who protect traditional techniques',
        'The ritual blessing of tools at the start of each workday',
      ],
      correctIndex: 1,
      explanation: 'Shokunin (職人) spirit is the total dedication to one\'s craft — whether sushi, pottery, carpentry, or tailoring. A true shokunin spends decades perfecting a single skill. This philosophy drives the extraordinary quality seen across Japanese crafts and cuisine.',
    ),
    CulturalChallenge(
      id: 'c_12',
      category: ChallengeCategory.customs,
      question: 'What is "ma" (間) in Japanese art and design?',
      options: [
        'A unit of measurement used in traditional architecture',
        'The concept of negative space, pause, and emptiness as a meaningful element',
        'A type of room divider made of paper and wood',
        'The golden ratio applied to Japanese garden design',
      ],
      correctIndex: 1,
      explanation: 'Ma (間) refers to the conscious use of negative space, silence, or pause as an active element in art, music, architecture, and conversation. Unlike Western traditions that fill space, Japanese aesthetics treat emptiness as meaningful — a pause in music, the bare wall in a tokonoma alcove.',
    ),
  ];

  /// Get today's challenge deterministically from the date.
  static CulturalChallenge getForDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    final index = dayOfYear % all.length;
    return all[index];
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Çok dilli string yönetimi - 8 dil desteği
/// TR, EN, IT, FR, RU, DE, AR, FA
class AppStrings {
  // Context for LanguageProvider
  static BuildContext? _context;
  static void setContext(BuildContext context) => _context = context;
  
  /// Get current language code (tr, en, it, fr, ru, de, ar, fa)
  static String get _langCode {
    if (_context == null) return 'tr';
    try {
      final languageProvider = Provider.of<LanguageProvider>(_context!, listen: false);
      return languageProvider.languageCode;
    } catch (e) {
      return 'tr';
    }
  }

  // Backward compatibility
  static bool get _isEnglish => _langCode == 'en';
  static bool get isEnglish => _isEnglish;

  /// Multi-language string selector
  /// Usage: _tr({'tr': 'Türkçe', 'en': 'English', ...})
  static String _tr(Map<String, String> translations) {
    return translations[_langCode] ?? translations['en'] ?? translations['tr'] ?? '';
  }

  // Uygulama genel
  static String get appName => 'Falla';
  static String get appSlogan => _tr({
    'tr': 'Mistik Fal ve Astroloji',
    'en': 'Mystic Fortune and Astrology',
    'it': 'Fortuna Mistica e Astrologia',
    'fr': 'Fortune Mystique et Astrologie',
    'ru': 'Мистическая Фортуна и Астрология',
    'de': 'Mystische Wahrsagung und Astrologie',
    'ar': 'الطالع الروحاني والفلك',
    'fa': 'فال عرفانی و طالع‌بینی',
  });
  
  // Ana ekran
  static String get welcome => _tr({
    'tr': 'Hoşgeldin', 'en': 'Welcome', 'it': 'Benvenuto', 'fr': 'Bienvenue',
    'ru': 'Добро пожаловать', 'de': 'Willkommen', 'ar': 'مرحباً', 'fa': 'خوش آمدید',
  });
  static String get guest => _tr({
    'tr': 'Misafir', 'en': 'Guest', 'it': 'Ospite', 'fr': 'Invité',
    'ru': 'Гость', 'de': 'Gast', 'ar': 'ضيف', 'fa': 'مهمان',
  });
  static String get karma => 'Karma';
  static String get searchHint => _tr({
    'tr': 'Ne aramıştın', 'en': 'What were you looking for', 'it': 'Cosa cercavi',
    'fr': 'Que cherchiez-vous', 'ru': 'Что вы искали', 'de': 'Was suchten Sie',
    'ar': 'ماذا كنت تبحث عنه', 'fa': 'چه چیزی جستجو می‌کردید',
  });
  
  // Fal türleri
  static String get selectFortune => _tr({
    'tr': 'Falını Seç', 'en': 'Choose Your Fortune', 'it': 'Scegli la Tua Fortuna',
    'fr': 'Choisissez Votre Fortune', 'ru': 'Выбери Свою Судьбу', 'de': 'Wähle Dein Schicksal',
    'ar': 'اختر طالعك', 'fa': 'فال خود را انتخاب کنید',
  });
  static String get coffeeFortune => _tr({
    'tr': 'Kahve Falı', 'en': 'Coffee Fortune', 'it': 'Lettura del Caffè',
    'fr': 'Cafédomancie', 'ru': 'Гадание на кофе', 'de': 'Kaffeesatzlesen',
    'ar': 'قراءة الفنجان', 'fa': 'فال قهوه',
  });
  static String get tarotFortune => _tr({
    'tr': 'Tarot', 'en': 'Tarot', 'it': 'Tarocchi', 'fr': 'Tarot',
    'ru': 'Таро', 'de': 'Tarot', 'ar': 'التاروت', 'fa': 'تاروت',
  });
  static String get palmFortune => _tr({
    'tr': 'El Falı', 'en': 'Palm Reading', 'it': 'Chiromanzia',
    'fr': 'Chiromancie', 'ru': 'Хиромантия', 'de': 'Handlesen',
    'ar': 'قراءة الكف', 'fa': 'کف‌بینی',
  });
  static String get katinaFortune => _tr({
    'tr': 'Katina Falı', 'en': 'Katina Fortune', 'it': 'Fortuna Katina',
    'fr': 'Fortune Katina', 'ru': 'Гадание Катина', 'de': 'Katina Wahrsagung',
    'ar': 'طالع كاتينا', 'fa': 'فال کاتینا',
  });
  static String get faceFortune => _tr({
    'tr': 'Yüz Falı', 'en': 'Face Fortune', 'it': 'Fisiognomica',
    'fr': 'Physiognomonie', 'ru': 'Физиогномика', 'de': 'Gesichtslesen',
    'ar': 'قراءة الوجه', 'fa': 'فال چهره',
  });
  static String get astrology => _tr({
    'tr': 'Astroloji', 'en': 'Astrology', 'it': 'Astrologia', 'fr': 'Astrologie',
    'ru': 'Астрология', 'de': 'Astrologie', 'ar': 'علم الفلك', 'fa': 'طالع‌بینی',
  });
  
  // Rüya alanı
  static String get dreamArea => _tr({
    'tr': 'Rüya Alanı', 'en': 'Dream Area', 'it': 'Area Sogni',
    'fr': 'Zone de Rêves', 'ru': 'Сновидения', 'de': 'Traumbereich',
    'ar': 'منطقة الأحلام', 'fa': 'تعبیر خواب',
  });
  static String get interpretDream => _tr({
    'tr': 'Rüya Yorumla', 'en': 'Interpret Dream', 'it': 'Interpreta Sogno',
    'fr': 'Interpréter Rêve', 'ru': 'Толкование снов', 'de': 'Traum deuten',
    'ar': 'تفسير الحلم', 'fa': 'تعبیر خواب',
  });
  static String get drawDream => _tr({
    'tr': 'Rüyamı Çiz', 'en': 'Draw My Dream', 'it': 'Disegna il Mio Sogno',
    'fr': 'Dessiner Mon Rêve', 'ru': 'Нарисуй мой сон', 'de': 'Zeichne meinen Traum',
    'ar': 'ارسم حلمي', 'fa': 'رویای من را بکش',
  });
  
  // Karma alanı
  static String get karmaArea => _tr({
    'tr': 'Karma Alanı', 'en': 'Karma Area', 'it': 'Area Karma',
    'fr': 'Zone Karma', 'ru': 'Область Кармы', 'de': 'Karma-Bereich',
    'ar': 'منطقة الكارما', 'fa': 'بخش کارما',
  });
  static String get buyKarma => _tr({
    'tr': 'Karma Satın Al', 'en': 'Buy Karma', 'it': 'Acquista Karma',
    'fr': 'Acheter Karma', 'ru': 'Купить Карму', 'de': 'Karma kaufen',
    'ar': 'شراء الكارما', 'fa': 'خرید کارما',
  });
  static String get buy => _tr({
    'tr': 'Satın Al', 'en': 'Buy', 'it': 'Acquista', 'fr': 'Acheter',
    'ru': 'Купить', 'de': 'Kaufen', 'ar': 'شراء', 'fa': 'خرید',
  });
  static String get earn => _tr({
    'tr': 'Kazan', 'en': 'Earn', 'it': 'Guadagna', 'fr': 'Gagner',
    'ru': 'Заработать', 'de': 'Verdienen', 'ar': 'اكسب', 'fa': 'کسب کنید',
  });
  static String get freeKarma => _tr({
    'tr': 'Ücretsiz Karma', 'en': 'Free Karma', 'it': 'Karma Gratuito',
    'fr': 'Karma Gratuit', 'ru': 'Бесплатная Карма', 'de': 'Kostenloses Karma',
    'ar': 'كارما مجانية', 'fa': 'کارمای رایگان',
  });
  static String get premiumKarma => _tr({
    'tr': 'Premium Karma', 'en': 'Premium Karma', 'it': 'Karma Premium',
    'fr': 'Karma Premium', 'ru': 'Премиум Карма', 'de': 'Premium Karma',
    'ar': 'كارما مميزة', 'fa': 'کارمای ویژه',
  });
  static String get quickAndEasy => _isEnglish ? 'Quick and easy load' : 'Hızlı ve kolay yükle';
  static String get earnByTasks => _isEnglish ? 'Complete tasks, earn by watching' : 'Görev yap, izleyerek kazan';
  static String get vipPrivileges => _isEnglish ? 'VIP privileges' : 'VIP ayrıcalıklar';
  
  // Karma kazanma ekranı
  static String get dailyLoginReward => _isEnglish ? 'Daily Login Reward' : 'Günlük Giriş Ödülü';
  static String get streakDays => _isEnglish ? 'Streak: {0} days' : 'Seri: {0} gün';
  static String get todayKarma => _isEnglish ? 'Today: {0} Karma' : 'Bugün: {0} Karma';
  static String get dailyLoginRewardTable => _isEnglish ? 'Daily Login Reward Table' : 'Günlük Giriş Ödül Tablosu';
  static String get watchAdForKarma => _isEnglish ? 'Watch ad for +{0} Karma' : '+{0} Karma için reklam izle';
  static String get premiumDiscount => _isEnglish ? '+1 Fortune discount (Go Premium)' : '+1 Fal indirimi (Premium\'a geç)';
  static String get adOrAuraMatch => _isEnglish ? '+{0} Karma (ad) or 1 Free Aura Match' : '+{0} Karma ek (reklam) veya 1 Ücretsiz Aura Eşleşme';
  static String get watchAd => _isEnglish ? 'Watch Ad' : 'Reklam İzle';
  static String get watchAdDescription => _isEnglish ? 'Earn karma by watching ads' : 'Reklam izleyerek karma kazan';
  static String get dailyLimitReached => _isEnglish ? 'Daily limit reached' : 'Günlük limit doldu';
  static String get remainingLimit => _isEnglish ? 'Remaining: {0}/{1}' : 'Kalan: {0}/{1}';
  static String get watch => _isEnglish ? 'Watch' : 'İzle';
  static String get spinWheel => _isEnglish ? 'Spin Wheel' : 'Çark Çevir';
  static String get spinWheelDescription => _isEnglish ? 'Spin the wheel of fate and earn karma' : 'Kader çarkını çevir ve karma kazan';
  static String get spinWheelButton => _isEnglish ? 'Spin Wheel' : 'Çarkı Çevir';
  static String get inviteFriend => _isEnglish ? 'Invite Friend' : 'Arkadaşını Davet Et';
  static String get inviteFriendDescription => _isEnglish ? 'Invite your friend, earn karma' : 'Arkadaşını davet et, karma kazan';
  static String get invitedCount => _isEnglish ? 'Invited count:' : 'Davet ettiği sayı:';
  static String get karmaEarnedFromSystem => _isEnglish ? 'Karma earned from this system:' : 'Bu sistem ile kazandığı karma:';
  static String get invite => _isEnglish ? 'Invite' : 'Davet Et';
  static String get shareOnInstagram => _isEnglish ? 'Share on Instagram' : 'Instagram\'da Paylaş';
  static String get shareOnInstagramDescription => _isEnglish ? 'Share on Instagram story, earn karma' : 'Instagram story\'nde paylaş, karma kazan';
  static String get oneTimeOnly => _isEnglish ? '(One time only)' : '(Tek seferlik hepsi)';
  static String get instagramStory => 'Instagram Story';
  static String get rateApp => _isEnglish ? 'Rate App' : 'Puan Ver';
  static String get rateAppMessage => _isEnglish ? 'If you liked the app, you can rate it in the store!' : 'Uygulamayı beğendiyseniz mağazada puan verebilirsiniz!';
  
  // Diğer alanlar
  static String get otherAreas => _isEnglish ? 'Other Areas' : 'Diğer Alanlar';
  static String get playAndEarn => _isEnglish ? 'Play and Earn' : 'Oyna Kazan';
  static String get loveTest => _tr({
    'tr': 'Aşk Testi', 'en': 'Love Test', 'it': 'Test dell\'Amore',
    'fr': 'Test d\'Amour', 'ru': 'Тест на любовь', 'de': 'Liebestest',
    'ar': 'اختبار الحب', 'fa': 'تست عشق',
  });
  static String get loveCompatibility => _isEnglish ? 'Love Compatibility' : 'Aşk Uyumu';
  static String get calculateHarmony => _isEnglish ? 'Calculate Harmony' : 'Uyum Hesapla';
  static String get personalityTest => _tr({
    'tr': 'Kişilik Testi', 'en': 'Personality Test', 'it': 'Test della Personalità',
    'fr': 'Test de Personnalité', 'ru': 'Тест личности', 'de': 'Persönlichkeitstest',
    'ar': 'اختبار الشخصية', 'fa': 'تست شخصیت',
  });
  static String get compatibilityTest => _isEnglish ? 'Compatibility Test' : 'Uyumluluk Testi';
  static String get careerTest => _isEnglish ? 'Career Test' : 'Kariyer Testi';
  static String get friendshipTest => _isEnglish ? 'Friendship Test' : 'Arkadaşlık Testi';
  static String get familyTest => _isEnglish ? 'Family Test' : 'Aile Testi';
  static String get soulMateAnalysis => _isEnglish ? 'Soulmate Analysis' : 'Ruh Eşi Analizi';
  static String get liveChat => _isEnglish ? 'Live Chat' : 'Canlı Sohbet';
  static String get biorhythm => _tr({
    'tr': 'Biyoritim', 'en': 'Biorhythm', 'it': 'Bioritmo', 'fr': 'Biorythme',
    'ru': 'Биоритм', 'de': 'Biorhythmus', 'ar': 'الإيقاع الحيوي', 'fa': 'بیوریتم',
  });
  
  // Aşk adayı
  static String get loveCandidate => _isEnglish ? 'Love Candidate' : 'Aşk Adayı';
  static String get loveCandidates => _isEnglish ? 'Love Candidates' : 'Aşk Adayları';
  static String get viewAllCandidates => _isEnglish ? 'View All Candidates' : 'Tüm Adayları Gör';
  static String get addNewCandidate => _isEnglish ? 'Add New Candidate' : 'Yeni Aday Ekle';
  static String get noLoveCandidate => _isEnglish ? 'No love candidate yet' : 'Henüz aşk adayı yok';
  static String get addYourFirstCandidate => _isEnglish ? 'Add your first love candidate' : 'İlk aşk adayını ekle';
  
  // Test alanı
  static String get tests => _isEnglish ? 'Tests' : 'Testler';
  static String get availableTests => _isEnglish ? 'Available Tests' : 'Mevcut Testler';
  static String get completedTests => _isEnglish ? 'Completed Tests' : 'Tamamlanan Testler';
  static String get generateNewTest => _isEnglish ? 'Generate New Test' : 'Yeni Test Oluştur';
  static String get yourTests => _isEnglish ? 'Your Tests' : 'Testlerin';
  static String get testGenerated => _isEnglish ? 'Test created successfully' : 'Test başarıyla oluşturuldu';
  static String get completed => _isEnglish ? 'Completed' : 'Tamamlandı';
  static String get seeAllTests => _isEnglish ? 'See All Tests' : 'Tüm Testleri Gör';
  // Test alt açıklamaları
  static String get personalityTestSubtitle =>
      _isEnglish ? 'Discover your personality' : 'Kişiliğini keşfet';
  
  // Kişilik testi form alanları
  static String get enterYourName => _isEnglish ? 'Enter your name' : 'Adınızı girin';
  static String get selectYourBirthDate => _isEnglish ? 'Select your birth date' : 'Doğum tarihinizi seçin';
  
  // Kişilik testi soruları
  static String get personalityQ1 => _isEnglish 
      ? 'What is your first reaction when you face a problem?'
      : 'Bir sorunla karşılaştığında ilk tepkin nedir?';
  static String get personalityQ1A1 => _isEnglish 
      ? 'I don\'t panic, I immediately look for a solution'
      : 'Panik olmam, hemen çözüm ararım';
  static String get personalityQ1A2 => _isEnglish 
      ? 'I think first, then take action'
      : 'Önce düşünürüm, sonra harekete geçerim';
  static String get personalityQ1A3 => _isEnglish 
      ? 'I withdraw into myself, I need some alone time'
      : 'İçime kapanırım, biraz yalnız kalırım';
  static String get personalityQ1A4 => _isEnglish 
      ? 'I laugh it off, I trust the universe\'s plan'
      : 'Gülüp geçerim, evrenin planına güvenirim';
  
  static String get personalityQ2 => _isEnglish 
      ? 'How do you show your feelings to someone?'
      : 'Birine karşı duygularını nasıl gösterirsin?';
  static String get personalityQ2A1 => _isEnglish 
      ? 'I say it openly'
      : 'Açıkça söylerim';
  static String get personalityQ2A2 => _isEnglish 
      ? 'I show it through my actions'
      : 'Davranışlarımla belli ederim';
  static String get personalityQ2A3 => _isEnglish 
      ? 'I want them to notice over time'
      : 'Zamanla fark etsin isterim';
  static String get personalityQ2A4 => _isEnglish 
      ? 'I keep it inside, I don\'t open up easily'
      : 'İçimde yaşarım, kolay açılmam';
  
  static String get personalityQ3 => _isEnglish 
      ? 'When you meet new people...'
      : 'Yeni insanlarla tanıştığında…';
  static String get personalityQ3A1 => _isEnglish 
      ? 'I chat immediately'
      : 'Hemen sohbet ederim';
  static String get personalityQ3A2 => _isEnglish 
      ? 'I observe first'
      : 'Önce gözlemlerim';
  static String get personalityQ3A3 => _isEnglish 
      ? 'I\'m friendly but cautious'
      : 'Samimi ama temkinliyim';
  static String get personalityQ3A4 => _isEnglish 
      ? 'I keep to myself, it depends on my energy'
      : 'Kendi halimdeyim, enerjime göre değişir';
  
  static String get personalityQ4 => _isEnglish 
      ? 'How do obstacles affect you?'
      : 'Engeller seni nasıl etkiler?';
  static String get personalityQ4A1 => _isEnglish 
      ? 'They make me more determined'
      : 'Daha da hırslandırır';
  static String get personalityQ4A2 => _isEnglish 
      ? 'I make a logical plan'
      : 'Mantıklı plan yaparım';
  static String get personalityQ4A3 => _isEnglish 
      ? 'I solve it over time'
      : 'Zamanla çözerim';
  static String get personalityQ4A4 => _isEnglish 
      ? 'I leave it to life\'s balance'
      : 'Hayatın dengesine bırakırım';
  
  static String get personalityQ5 => _isEnglish 
      ? 'Which one describes you the most?'
      : 'Hangisi seni en çok tanımlar?';
  static String get personalityQ5A1 => _isEnglish ? 'Courage' : 'Cesaret';
  static String get personalityQ5A2 => _isEnglish ? 'Wisdom' : 'Bilgelik';
  static String get personalityQ5A3 => _isEnglish ? 'Peace' : 'Huzur';
  static String get personalityQ5A4 => _isEnglish ? 'Intuition' : 'Sezgi';
  
  static String get personalityQ6 => _isEnglish 
      ? 'What does daydreaming mean to you?'
      : 'Hayal kurmak senin için…';
  static String get personalityQ6A1 => _isEnglish 
      ? 'A way to shape reality'
      : 'Gerçekleri şekillendirme yolu';
  static String get personalityQ6A2 => _isEnglish 
      ? 'Not unnecessary but I use it limitedly'
      : 'Gereksiz değil ama sınırlı kullanırım';
  static String get personalityQ6A3 => _isEnglish 
      ? 'Something that nourishes my soul'
      : 'Ruhumu besleyen şey';
  static String get personalityQ6A4 => _isEnglish 
      ? 'The essence of life, everything starts there'
      : 'Hayatın özü, her şey orada başlar';
  
  static String get personalityQ7 => _isEnglish 
      ? 'Where do you feel most peaceful?'
      : 'Kendini en huzurlu hissettiğin yer:';
  static String get personalityQ7A1 => _isEnglish 
      ? 'Crowded, energetic environments'
      : 'Kalabalık, enerjik ortamlar';
  static String get personalityQ7A2 => _isEnglish 
      ? 'A quiet, organized room'
      : 'Sessiz, düzenli bir oda';
  static String get personalityQ7A3 => _isEnglish 
      ? 'In nature, outdoors'
      : 'Doğada, açık havada';
  static String get personalityQ7A4 => _isEnglish 
      ? 'In my dream world, when I\'m alone'
      : 'Hayal dünyamda, yalnızken';
  static String get friendshipTestSubtitle =>
      _isEnglish ? 'Analyze your friendship relations' : 'Arkadaşlık ilişkilerini analiz et';
  static String get loveTestSubtitle =>
      _isEnglish ? 'Analyze your love life' : 'Aşk hayatını analiz et';
  static String get relationshipCompatibilitySubtitle =>
      _isEnglish ? 'Analyze your relationship compatibility' : 'İlişki uyumluluğunu analiz et';

  // Özel test: İlişkinde Gerçekten Ne İstiyorsun?
  static String get relationshipWhatYouWantSubtitle =>
      _isEnglish ? 'Discover your love style' : 'Aşk tarzını keşfet';
  
  // Burç alanı
  static String get dailyHoroscope => _isEnglish ? 'Your Horoscope Today' : 'Burcuna Göre Bugün';
  static String get aiUpdatedDaily => _isEnglish ? 'Updated daily.' : 'Her gün yenilenir.';
  
  // Fal bakma süreci
  static String get forMyself => _isEnglish ? 'For Myself' : 'Kendim için';
  static String get forSomeoneElse => _isEnglish ? 'For Someone Else' : 'Başkası için';
  static String get topic1Label => _isEnglish ? 'Topic 1' : '1. Konu';
  static String get topic2Label => _isEnglish ? 'Topic 2' : '2. Konu';
  static String get selectCards => _isEnglish ? 'Select Cards' : 'Kartları Seç';
  static String get askQuestion => _isEnglish ? 'Ask Question' : 'Soru Sor';
  static String get optional => _isEnglish ? '(Optional)' : '(İsteğe bağlı)';
  
  // Kullanıcı bilgileri
  static String get name => _isEnglish ? 'Name' : 'Ad';
  static String get birthDate => _isEnglish ? 'Birth Date' : 'Doğum Tarihi';
  static String get birthPlace => _isEnglish ? 'Birth Place' : 'Doğum Yeri';
  static String get relationshipStatus => _isEnglish ? 'Relationship Status' : 'İlişki Durumu';
  static String get gender => _isEnglish ? 'Gender' : 'Cinsiyet';
  static String get pleaseSelectGender => _isEnglish ? 'Please select gender' : 'Lütfen cinsiyet seçin';
  static String get job => _isEnglish ? 'Occupation' : 'Meslek';
  
  // İlişki durumları
  static String get inRelationship => _isEnglish ? 'In a relationship' : 'İlişkisi var';
  static String get single => _isEnglish ? 'Single' : 'İlişkisi yok';
  static String get married => _isEnglish ? 'Married' : 'Evli';
  static String get complicated => _isEnglish ? 'Complicated' : 'Karışık';
  static String get separated => _isEnglish ? 'Separated' : 'Ayrılmış';
  static String get platonic => _isEnglish ? 'Platonic' : 'Platonik';
  static String get dating => _isEnglish ? 'Dating' : 'Flört halinde';
  static String get widowed => _isEnglish ? 'Widowed' : 'Dul';
  
  // Cinsiyet
  static String get female => _isEnglish ? 'Female' : 'Kadın';
  static String get male => _isEnglish ? 'Male' : 'Erkek';
  static String get lgbt => _isEnglish ? 'LGBT' : 'LGBT';
  
  // Meslek
  static String get working => _isEnglish ? 'Working' : 'Çalışıyor';
  static String get unemployed => _isEnglish ? 'Unemployed' : 'İşsiz';
  static String get student => _isEnglish ? 'Student' : 'Öğrenci';
  static String get retired => _isEnglish ? 'Retired' : 'Emekli';
  static String get freelancer => _isEnglish ? 'Freelancer' : 'Serbest';
  static String get housewife => _isEnglish ? 'Housewife' : 'Ev Hanımı';
  static String get manager => _isEnglish ? 'Manager' : 'Yönetici';
  static String get officer => _isEnglish ? 'Officer' : 'Memur';

  // Social / Aura safety
  static String get birthDateRequiredForSocial => _isEnglish
      ? 'Please add your birth date in your profile before using social and aura match features.'
      : 'Sosyal ve aura eşleşme özelliklerini kullanmadan önce profilinden doğum tarihini eklemelisin.';
  static String get ageGroupMismatchError => _isEnglish
      ? 'This profile cannot be matched due to age restrictions.'
      : 'Yaş kısıtlaması nedeniyle bu profil ile eşleşme yapılamaz.';
  
  // Butonlar
  static String get start => _isEnglish ? 'Start' : 'Başla';
  static String get continue_ => _isEnglish ? 'Continue' : 'Devam Et';
  static String get send => _isEnglish ? 'Send' : 'Gönder';
  static String get save => _isEnglish ? 'Save' : 'Kaydet';
  static String get share => _isEnglish ? 'Share' : 'Paylaş';
  static String get shareFailed => _isEnglish ? 'Failed to share' : 'Paylaşım başarısız oldu';
  static String get back => _tr({
    'tr': 'Geri', 'en': 'Back', 'it': 'Indietro', 'fr': 'Retour',
    'ru': 'Назад', 'de': 'Zurück', 'ar': 'رجوع', 'fa': 'بازگشت',
  });
  static String get next => _tr({
    'tr': 'İleri', 'en': 'Next', 'it': 'Avanti', 'fr': 'Suivant',
    'ru': 'Далее', 'de': 'Weiter', 'ar': 'التالي', 'fa': 'بعدی',
  });
  static String get done => _tr({
    'tr': 'Tamam', 'en': 'Done', 'it': 'Fatto', 'fr': 'Fait',
    'ru': 'Готово', 'de': 'Fertig', 'ar': 'تم', 'fa': 'انجام شد',
  });
  static String get complete => _tr({
    'tr': 'Tamamla', 'en': 'Complete', 'it': 'Completa', 'fr': 'Compléter',
    'ru': 'Завершить', 'de': 'Abschließen', 'ar': 'إكمال', 'fa': 'تکمیل',
  });
  static String get cancel => _tr({
    'tr': 'İptal', 'en': 'Cancel', 'it': 'Annulla', 'fr': 'Annuler',
    'ru': 'Отмена', 'de': 'Abbrechen', 'ar': 'إلغاء', 'fa': 'لغو',
  });
  static String get confirm => _tr({
    'tr': 'Onayla', 'en': 'Confirm', 'it': 'Conferma', 'fr': 'Confirmer',
    'ru': 'Подтвердить', 'de': 'Bestätigen', 'ar': 'تأكيد', 'fa': 'تایید',
  });
  static String get accept => _isEnglish ? 'Accept' : 'Kabul Et';
  static String get reject => _isEnglish ? 'Reject' : 'Reddet';
  static String get showMore => _isEnglish ? 'Show More' : 'Devamını Gör';
  static String get termsOfService => _isEnglish ? 'Terms of Service' : 'Kullanım Koşulları';
  static String get lastUpdated => _isEnglish ? 'Last Updated: 08.11.2025' : 'Son Güncelleme: 08.11.2025';
  static String get termsNotAccepted => _isEnglish ? 'Terms Not Accepted' : 'Koşullar Kabul Edilmedi';
  static String get termsMustBeAccepted => _isEnglish 
      ? 'You must accept the terms of service to create an account.'
      : 'Hesap oluşturmak için kullanım koşullarını kabul etmelisiniz.';
  
  // Mesajlar
  static String get loading => _isEnglish ? 'Loading...' : 'Yükleniyor...';
  static String get fortuneBeingSent => _isEnglish ? 'Sending Fortune' : 'Fal Gönderiliyor';
  static String get fortuneAddedToMyFortunes => _isEnglish ? 'Your reading has been added to \'My Fortunes\' menu!' : 'Yorumunuz \'Fallarım\' menüsüne eklendi!';
  static String get checkResultInMyFortunes => _isEnglish ? 'You can see the result from the My Fortunes section.' : 'Fallarım bölümünden sonucunu görebilirsin.';
  static String get earnKarma => _isEnglish ? 'Earn Karma' : 'Karma Kazan';
  static String get frequency => _isEnglish ? 'Frequency' : 'Frekans';
  static String get connect => _isEnglish ? 'Connect' : 'Bağlan';
  static String get mood => _isEnglish ? 'Mood' : 'Mod';
  static String get processing => _isEnglish ? 'Processing...' : 'İşleniyor...';
  static String get startSubscription => _isEnglish ? 'Start Subscription' : 'Aboneliği Başlat';
  static String get shareAppMessage => _isEnglish ? 'Check out this amazing app!' : 'Bu harika uygulamaya göz at!';
  static String get termsOfUse => _isEnglish ? 'Terms of Use' : 'Kullanım Koşulları';
  static String get details => _isEnglish ? 'Details' : 'Detaylar';
  static String get fallaComment => _isEnglish ? "Falla's Comment" : "Falla'ın Yorumu";
  
  // Hata mesajları
  static String get error => _isEnglish ? 'Error' : 'Hata';
  static String get networkError => _isEnglish ? 'Internet connection error' : 'İnternet bağlantısı hatası';
  static String get unknownError => _isEnglish ? 'An unknown error occurred' : 'Bilinmeyen hata oluştu';
  static String get tryAgain => _isEnglish ? 'Try again' : 'Tekrar dene';
  
  // Validasyon
  static String get fieldRequired => _isEnglish ? 'This field is required' : 'Bu alan zorunludur';
  static String get invalidEmail => _isEnglish ? 'Invalid email address' : 'Geçersiz e-posta adresi';
  static String get passwordTooShort => _isEnglish ? 'Password must be at least 6 characters' : 'Şifre en az 6 karakter olmalıdır';
  
  // Navigation
  static String get home => 'Falla';
  static String get myFortunes => _tr({
    'tr': 'Fallarım', 'en': 'My Fortunes', 'it': 'Le Mie Fortune', 'fr': 'Mes Fortunes',
    'ru': 'Мои Гадания', 'de': 'Meine Schicksale', 'ar': 'طالعي', 'fa': 'فال‌های من',
  });
  static String get farm => _isEnglish ? 'Farm' : 'Çiftlik';
  static String get horoscopes => _isEnglish ? 'Horoscopes' : 'Burçlar';
  static String get premium => _isEnglish ? 'Premium' : 'Premium';
  
// Test bölümü
  static String get questions => _isEnglish ? 'Questions' : 'Sorular';
  static String get noTests => _isEnglish ? 'No tests yet' : 'Henüz test yok';
  static String get generateFirstTest => _isEnglish ? 'Create your first test' : 'İlk testini oluştur';
  static String get noCompletedTests => _isEnglish ? 'No completed tests yet' : 'Henüz tamamlanmış test yok';
  static String get completeFirstTest => _isEnglish ? 'Complete your first test' : 'İlk testini tamamla';
  // Özel test adları
  static String get relationshipWhatYouWantTest => _isEnglish
      ? 'What Do You Really Want In Your Relationship?'
      : 'İlişkinde Gerçekten Ne İstiyorsun?';
  static String get loveRedFlagsTest => _isEnglish
      ? 'Can You See The Red Flags In Love?'
      : 'Aşkta Kırmızı Bayrakları Görebiliyor musun?';
  static String get zodiacFunLevelTest => _isEnglish
      ? 'How Fun Are You According to Your Zodiac Sign?'
      : 'Burcuna Göre Ne Kadar Eğlencelisin';
  static String get zodiacChaosLevelTest => _isEnglish
      ? 'How Chaotic Are You According to Your Zodiac Sign?'
      : 'Burcuna Göre Ne Kadar Kaotiksin?';
  
  // Tarot bölümü
  static String get tarotCard => _isEnglish ? 'Tarot Card' : 'Tarot Kartı';
  static String get selectMore => _isEnglish ? 'Select more' : 'Daha fazla seç';
  static String get remaining => _isEnglish ? 'remaining' : 'kalan';
  static String get generateReading => _isEnglish ? 'Generate Reading' : 'Yorum Oluştur';
  static String get selectedCards => _isEnglish ? 'Selected Cards' : 'Seçilen Kartlar';
  static String get loadingCards => _isEnglish ? 'Loading cards...' : 'Kartlar yükleniyor...';
  static String get cardInput => _isEnglish ? 'Card Input' : 'Kart Girişi';
  static String get cardOutput => _isEnglish ? 'Card Output' : 'Kart Çıkışı';
  static String get questionHint => _isEnglish ? 'Write your question...' : 'Sorunuzu yazın...';
  
  static String get dailyGift => _isEnglish ? 'Daily Gift' : 'Günlük Hediye';
  static String get dailyGiftDesc => _isEnglish ? 'Collect your daily reward' : 'Günlük ödülünü topla';
  static String get claim => _isEnglish ? 'Claim' : 'Al';
  static String get dailyQuests => _isEnglish ? 'Daily Quests' : 'Günlük Görevler';
  static String get tapToSeeDetails => _isEnglish ? 'Tap to see details' : 'Detayları görmek için dokun';
  
  // Eksik string'ler
  static String get maxCards => _isEnglish ? 'Maximum Cards' : 'Maksimum Kart';
  static String get generatingReading => _isEnglish ? 'Generating reading...' : 'Yorum oluşturuluyor...';
  static String get shufflingCards => _isEnglish ? 'Shuffling cards...' : 'Kartlar karıştırılıyor...';
  static String get focusOnQuestion => _isEnglish ? 'Focus on your question' : 'Sorunuza odaklanın';
  static String get tarotForSelf => _isEnglish ? 'Tarot for Myself' : 'Kendim için Tarot';
  static String get tarotForSomeone => _isEnglish ? 'Tarot for Someone' : 'Başkası için Tarot';
  static String get tarotInstructions => _isEnglish ? 'Tarot instructions' : 'Tarot talimatları';
  static String get tarot => _isEnglish ? 'Tarot' : 'Tarot';
  static String get coffee => _isEnglish ? 'Coffee Fortune' : 'Kahve Falı';
  static String get palm => _isEnglish ? 'Palm Reading' : 'El Falı';
  static String get welcomeBack => _isEnglish ? 'Welcome back' : 'Tekrar hoşgeldin';
  static String get dailyFortune => _isEnglish ? 'Daily Fortune' : 'Günlük Fal';
  static String get dailyFortuneDesc => _isEnglish 
      ? 'Discover what the stars have in store for you today. Get personalized fortune readings based on your zodiac sign and cosmic energies.'
      : 'Bugün yıldızların senin için ne hazırladığını keşfet. Burcuna ve kozmik enerjilere göre kişiselleştirilmiş fal yorumları al.';
  static String get startFortune => _isEnglish ? 'Start Fortune' : 'Fal Başlat';
  static String get fortuneTypes => _isEnglish ? 'Fortune Types' : 'Fal Türleri';
  static String get tarotDesc => _isEnglish 
      ? 'Discover your destiny through mystical tarot cards. Each card reveals hidden truths about your past, present, and future.'
      : 'Mistik tarot kartları aracılığıyla kaderini keşfet. Her kart geçmişin, şimdin ve geleceğin hakkında gizli gerçekleri ortaya çıkarır.';
  static String get coffeeDesc => _isEnglish 
      ? 'Read your fortune from coffee grounds. Traditional Turkish coffee fortune telling reveals insights through the patterns left in your cup.'
      : 'Kahve telvesinden falını oku. Geleneksel Türk kahve falı, fincanında kalan desenler aracılığıyla içgörüler ortaya çıkarır.';
  static String get palmDesc => _isEnglish 
      ? 'Explore your life path through palm reading. The lines on your palm reveal your personality, relationships, and future possibilities.'
      : 'El falı aracılığıyla yaşam yolunu keşfet. Avucundaki çizgiler kişiliğini, ilişkilerini ve gelecek olasılıklarını ortaya çıkarır.';
  static String get astrologyDesc => _isEnglish 
      ? 'Unlock cosmic wisdom through astrology. Discover how planetary positions influence your life, relationships, and destiny.'
      : 'Astroloji aracılığıyla kozmik bilgeliği keşfet. Gezegen pozisyonlarının hayatını, ilişkilerini ve kaderini nasıl etkilediğini öğren.';
  static String get dreamInterpretation => _isEnglish ? 'Dream Interpretation' : 'Rüya Yorumu';
  static String get dreamDesc => _isEnglish 
      ? 'Unlock the hidden meanings of your dreams. Share your dream details and receive mystical interpretations that reveal insights about your subconscious mind.'
      : 'Rüyalarının gizli anlamlarını keşfet. Rüya detaylarını paylaş ve bilinçaltın hakkında içgörüler ortaya çıkaran mistik yorumlar al.';
  static String get faceDesc => _isEnglish 
      ? 'Discover your destiny through face reading. Facial features reveal insights about your personality, future, and life path.'
      : 'Yüz okuma ile kaderini keşfet. Yüz hatları, kişiliğin, geleceğin ve yaşam yolun hakkında içgörüler ortaya çıkarır.';
  static String get katinaDesc => _isEnglish 
      ? 'Share your concerns and receive guidance through Katina fortune. This ancient method provides answers to your deepest questions.'
      : 'Endişelerini paylaş ve Katina falı aracılığıyla rehberlik al. Bu kadim yöntem en derin sorularına yanıtlar sunar.';
  static String get karmaSystem => _isEnglish ? 'Karma System' : 'Karma Sistemi';
  static String get currentKarma => _isEnglish ? 'Current Karma' : 'Mevcut Karma';
  static String get karmaDesc => _isEnglish 
      ? 'Earn karma points by watching ads or completing daily tasks. Use your karma to unlock premium features and access exclusive fortune readings.'
      : 'Reklam izleyerek veya günlük görevleri tamamlayarak karma puanları kazan. Karmanı premium özelliklerin kilidini açmak ve özel fal yorumlarına erişmek için kullan.';
  static String get otherFeatures => _isEnglish ? 'Other Features' : 'Diğer Özellikler';
  static String get zodiacCompatibility => _isEnglish ? 'Zodiac Compatibility' : 'Burç Uyumluluğu';
  static String get numerology => _isEnglish ? 'Numerology' : 'Numeroloji';
  static String get fortunes => _isEnglish ? 'Fortunes' : 'Fallar';
  static String get profile => _tr({
    'tr': 'Profil', 'en': 'Profile', 'it': 'Profilo', 'fr': 'Profil',
    'ru': 'Профиль', 'de': 'Profil', 'ar': 'الملف الشخصي', 'fa': 'پروفایل',
  });
  static String get signedOut => _isEnglish ? 'Signed out' : 'Çıkış yapıldı';
  static String get totalFortunes => _isEnglish ? 'Total Fortunes' : 'Toplam Fal';
  static String get dailyFortunes => _isEnglish ? 'Daily Fortunes' : 'Günlük Fallar';
  static String get memberSince => _isEnglish ? 'Member Since' : 'Üyelik Tarihi';
  static String get lastLogin => _isEnglish ? 'Last Login' : 'Son Giriş';
  static String get settings => _tr({
    'tr': 'Ayarlar', 'en': 'Settings', 'it': 'Impostazioni', 'fr': 'Paramètres',
    'ru': 'Настройки', 'de': 'Einstellungen', 'ar': 'الإعدادات', 'fa': 'تنظیمات',
  });
  static String get notifications => _isEnglish ? 'Notifications' : 'Bildirimler';
  static String get privacy => _isEnglish ? 'Privacy' : 'Gizlilik';
  static String get help => _isEnglish ? 'Help' : 'Yardım';
  static String get about => _isEnglish ? 'About' : 'Hakkında';
  static String get editProfile => _isEnglish ? 'Edit Profile' : 'Profili Düzenle';
  static String get signOut => _isEnglish ? 'Sign Out' : 'Çıkış Yap';
  static String get signIn => _isEnglish ? 'Sign In' : 'Giriş Yap';
  static String get daysAgo => _isEnglish ? 'days ago' : 'gün önce';
  static String get monthsAgo => _isEnglish ? 'months ago' : 'ay önce';
  static String get yearsAgo => _isEnglish ? 'years ago' : 'yıl önce';
  static String get premiumTitle => _isEnglish 
      ? 'Unlock Premium Experience'
      : 'Premium Deneyimi Keşfet';
  static String get premiumSubtitle => _isEnglish 
      ? 'Get unlimited access to all features and enjoy an ad-free mystical journey'
      : 'Tüm özelliklere sınırsız erişim kazan ve reklamsız mistik bir yolculuğun tadını çıkar';
  static String get premiumFeatures => _isEnglish ? 'Premium Features' : 'Premium Özellikler';
  static String get choosePlan => _isEnglish ? 'Choose Plan' : 'Plan Seç';
  static String get mostPopular => _isEnglish ? 'Most Popular' : 'En Popüler';
  static String get popular => _isEnglish ? 'Popular' : 'POPÜLER';
  static String get alreadyPremium => _isEnglish ? 'Already Premium' : 'Zaten Premium';
  static String get upgradeToPremium => _isEnglish ? 'Upgrade to Premium' : 'Premium\'a Yükselt';
  static String get goPremium => _isEnglish ? 'Go Premium' : 'Premium\'a Geç';
  static String get unlimitedFeaturesAdFree => _isEnglish 
      ? 'Unlimited features, ad-free experience'
      : 'Sınırsız özellikler, reklamsız deneyim';
  static String get seeAllFeatures => _isEnglish ? 'See All Features' : 'Tüm Özellikleri Gör';
  static String get continueReading => _isEnglish ? 'Continue Reading' : 'Devamını oku';
  static String horoscopeFor(String zodiacSign, String timeframe) => _isEnglish
      ? '$zodiacSign Horoscope for $timeframe'
      : '$zodiacSign Burcu İçin $timeframe Yorumu';
  static String get detailButton => _isEnglish ? 'Detail' : 'Detay';
  static String get purchaseSuccessful => _isEnglish ? 'Purchase successful' : 'Satın alma başarılı';
  static String get selectFortuneType => _isEnglish ? 'Select fortune type' : 'Fal türü seç';
  static String get notEnoughKarma => _isEnglish ? 'Not enough karma' : 'Yeterli karma yok';
  static String get preparingFortune => _isEnglish ? 'Preparing fortune...' : 'Fal hazırlanıyor...';
  static String get chooseYourPath => _isEnglish ? 'Choose your path' : 'Yolunu seç';
  static String get selectFortuneDesc => _isEnglish ? 'Fortune selection description' : 'Fal seçimi açıklaması';
  static String get fortuneFor => _isEnglish ? 'Fortune for' : 'Fal için';
  static String get forMyselfDesc => _isEnglish ? 'For myself description' : 'Kendim için açıklama';
  static String get forSomeoneDesc => _isEnglish ? 'For someone description' : 'Başkası için açıklama';
  static String get addedToFavorites => _isEnglish ? 'Added to favorites' : 'Favorilere eklendi';
  static String get removedFromFavorites => _isEnglish ? 'Removed from favorites' : 'Favorilerden çıkarıldı';
  static String get ratingSubmitted => _isEnglish ? 'Rating submitted' : 'Değerlendirme gönderildi';
  static String get shareMessage => _isEnglish ? 'Share message' : 'Paylaşım mesajı';
  static String get fortuneResult => _isEnglish ? 'Fortune Result' : 'Fal Sonucu';
  static String get interpretation => _isEnglish ? 'Interpretation' : 'Yorum';
  static String get rateFortune => _isEnglish ? 'Rate Fortune' : 'Falı Değerlendir';
  static String get yourRating => _isEnglish ? 'Your Rating' : 'Değerlendirmeniz';
  static String get newFortune => _isEnglish ? 'New Fortune' : 'Yeni Fal';
  static String get backToHome => _isEnglish ? 'Back to Home' : 'Ana Sayfaya Dön';
  static String get minutesAgo => _isEnglish ? 'minutes ago' : 'dakika önce';
  static String get hoursAgo => _isEnglish ? 'hours ago' : 'saat önce';
  static String get yesterday => _isEnglish ? 'yesterday' : 'dün';
  static String get fortunesHistory => _isEnglish ? 'Fortunes History' : 'Fal Geçmişi';
  static String get total => _isEnglish ? 'total' : 'toplam';
  static String get all => _isEnglish ? 'All' : 'Tümü';
  static String get newest => _isEnglish ? 'Newest' : 'En Yeni';
  static String get oldest => _isEnglish ? 'Oldest' : 'En Eski';
  static String get favorites => _isEnglish ? 'Favorites' : 'Favoriler';
  static String get rating => _isEnglish ? 'Rating' : 'Değerlendirme';
  static String get noFortunes => _isEnglish ? 'No fortunes' : 'Fal yok';
  static String get startFirstFortune => _isEnglish ? 'Start your first fortune' : 'İlk falını başlat';
  static String get statistics => _isEnglish ? 'Statistics' : 'İstatistikler';
  static String get cards => _isEnglish ? 'cards' : 'kartlar';
  static String get social => _tr({
    'tr': 'Sosyal', 'en': 'Social', 'it': 'Social', 'fr': 'Social',
    'ru': 'Социальное', 'de': 'Sozial', 'ar': 'اجتماعي', 'fa': 'اجتماعی',
  });
  
  // Ana sayfa - Rüya bölümü
  static String get drawMyDream => _isEnglish ? 'Draw My Dream' : 'Rüyamı Çiz';
  static String get dreamHistory => _isEnglish ? 'My Dream History' : 'Rüya Geçmişim';
  
  // Ana sayfa - Karma bölümü
  static String get perVideo => _isEnglish ? 'Per video' : 'Video başına';
  static String get dailyLimit => _isEnglish ? 'Daily limit' : 'Günlük limit';
  static String get watchAdsToEarn => _isEnglish ? 'Watch Ads to Earn' : 'Reklam İzleyerek Kazan';
  static String get karmaEarned => _isEnglish ? 'karma earned!' : 'karma kazandınız!';
  static String get adNotWatched => _isEnglish ? 'Ad not watched. Could not earn karma.' : 'Reklam izlenmedi. Karma kazanamadınız.';
  
  // Ana sayfa - Diğer özellikler
  static String get auraMatch => _isEnglish ? 'Aura Match' : 'Aura Eşleşmesi';
  static String get auraAnalysis => _isEnglish ? 'Aura Analysis' : 'Aura Analizi';
  
  // Burç isimleri
  static String get aries => _isEnglish ? 'Aries' : 'Koç';
  static String get taurus => _isEnglish ? 'Taurus' : 'Boğa';
  static String get gemini => _isEnglish ? 'Gemini' : 'İkizler';
  static String get cancer => _isEnglish ? 'Cancer' : 'Yengeç';
  static String get leo => _isEnglish ? 'Leo' : 'Aslan';
  static String get virgo => _isEnglish ? 'Virgo' : 'Başak';
  static String get libra => _isEnglish ? 'Libra' : 'Terazi';
  static String get scorpio => _isEnglish ? 'Scorpio' : 'Akrep';
  static String get sagittarius => _isEnglish ? 'Sagittarius' : 'Yay';
  static String get capricorn => _isEnglish ? 'Capricorn' : 'Oğlak';
  static String get aquarius => _isEnglish ? 'Aquarius' : 'Kova';
  static String get pisces => _isEnglish ? 'Pisces' : 'Balık';
  
  // Burç varsayılan mesajları
  static String get starsSpeakingToday => _isEnglish ? 'The stars are speaking for you today.' : 'Yıldızlar bugün senin için konuşuyor.';
  
  // Karma satın alma ekranı
  static String get useKarmaForFortunes => _isEnglish ? 'Use karma to read fortunes and unlock features' : 'Fal bakmak ve özellikleri açmak için karma kullan';
  static String get karmaPackages => _isEnglish ? 'Karma Packages' : 'Karma Paketleri';
  static String get specialPackages => _isEnglish ? 'Special Packages' : 'Özel Paketler';
  static String get specialPackagesDesc => _isEnglish ? 'Special packages for more value' : 'Daha fazla değer için özel paketler';
  static String get karmaAddedSuccessfully => _isEnglish ? 'karma successfully added!' : 'karma başarıyla eklendi!';
  static String get packagePurchasedSuccessfully => _isEnglish ? 'Package purchased successfully! karma added.' : 'Paket başarıyla satın alındı! karma eklendi.';
  static String get purchaseProcessingError => _isEnglish ? 'Error processing purchase:' : 'Satın alma işlenirken hata:';
  static String get purchaseError => _isEnglish ? 'Purchase error:' : 'Satın alma hatası:';
  static String get purchaseStarted => _isEnglish ? 'Purchase process started...' : 'Satın alma işlemi başlatıldı...';
  static String get pleaseLoginFirst => _isEnglish ? 'Please login first' : 'Lütfen önce giriş yapın';
  static String get productNotFound => _isEnglish ? 'Product not found' : 'Ürün bulunamadı';
  static String get purchaseNotAvailable => _isEnglish ? 'Purchase is currently unavailable. Please try again later.' : 'Satın alma şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
  static String get purchaseCouldNotStart => _isEnglish ? 'Purchase could not be started' : 'Satın alma başlatılamadı';
  
  // BillingResponse error messages
  static String getPurchaseErrorMessage(String? errorCode) {
    if (errorCode == null) {
      return _isEnglish ? 'Unknown error occurred' : 'Bilinmeyen bir hata oluştu';
    }
    
    final errorLower = errorCode.toLowerCase();
    
    // BillingResponse error codes
    if (errorLower.contains('itemunavailable') || errorLower.contains('item_unavailable')) {
      return _isEnglish 
          ? 'This item is currently unavailable. Please try again later.'
          : 'Bu ürün şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
    } else if (errorLower.contains('usercanceled') || errorLower.contains('user_canceled')) {
      return _isEnglish 
          ? 'Purchase was cancelled'
          : 'Satın alma iptal edildi';
    } else if (errorLower.contains('serviceunavailable') || errorLower.contains('service_unavailable')) {
      return _isEnglish 
          ? 'Purchase service is currently unavailable. Please try again later.'
          : 'Satın alma servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
    } else if (errorLower.contains('billingunavailable') || errorLower.contains('billing_unavailable')) {
      return _isEnglish 
          ? 'Billing service is unavailable on this device.'
          : 'Bu cihazda fatura servisi kullanılamıyor.';
    } else if (errorLower.contains('itemalreadyowned') || errorLower.contains('item_already_owned')) {
      return _isEnglish 
          ? 'You already own this item.'
          : 'Bu ürüne zaten sahipsiniz.';
    } else if (errorLower.contains('developererror') || errorLower.contains('developer_error')) {
      return _isEnglish 
          ? 'A developer error occurred. Please contact support.'
          : 'Bir geliştirici hatası oluştu. Lütfen destek ile iletişime geçin.';
    } else if (errorLower.contains('networkerror') || errorLower.contains('network_error')) {
      return _isEnglish 
          ? 'Network error. Please check your internet connection and try again.'
          : 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
    } else if (errorLower.contains('service_disconnected')) {
      return _isEnglish 
          ? 'Service disconnected. Please try again.'
          : 'Servis bağlantısı kesildi. Lütfen tekrar deneyin.';
    } else if (errorLower.contains('feature_not_supported')) {
      return _isEnglish 
          ? 'This feature is not supported on your device.'
          : 'Bu özellik cihazınızda desteklenmiyor.';
    } else if (errorLower.contains('service_timeout')) {
      return _isEnglish 
          ? 'Service request timed out. Please try again.'
          : 'Servis isteği zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    
    // Fallback: return the original error code if no match found
    return _isEnglish 
        ? 'Purchase error: $errorCode'
        : 'Satın alma hatası: $errorCode';
  }
  static String get daysAdFree => _isEnglish ? 'days ad-free' : 'gün reklamsız';
  static String get auraMatches => _isEnglish ? 'aura matches' : 'aura eşleşmesi';
  static String get karmaPlusBonus => _isEnglish ? 'Karma + Bonus' : 'Karma + Bonus';
  
  // Sosyal ekran
  static String get userSessionNotFound => _isEnglish ? 'User session not found' : 'Kullanıcı oturumu bulunamadı';
  static String get matchesCouldNotLoad => _isEnglish ? 'Matches could not be loaded:' : 'Eşleşmeler yüklenemedi:';
  static String get matches => _isEnglish ? 'Matches' : 'Eşleşme';
  
  // Test ekranı
  static String get popularTests => _isEnglish ? 'Popular Tests' : 'Popüler Testler';
  static String get otherTests => _isEnglish ? 'Other Tests' : 'Diğer Testler';
  static String get testsLoading => _isEnglish ? 'Loading tests...' : 'Testler yükleniyor...';
  
  // Fal sayfaları - Genel
  static String get createFortune => _isEnglish ? 'Create Fortune' : 'Falı Oluştur';
  static String get uploadPhotos => _isEnglish ? 'Upload Photos' : 'Fotoğrafları Yükleyin';
  static String get questionOptional => _isEnglish ? 'Your Question (Optional)' : 'Sorunuz (İsteğe Bağlı)';
  static String get problemOptional => _isEnglish ? 'Problem (Optional)' : 'Sorun (İsteğe Bağlı)';
  static String get exampleLoveLife => _isEnglish ? 'E.g.: How will my love life be?' : 'Örn: Aşk hayatım nasıl olacak?';
  static String get exampleLoveLifeShort => _isEnglish ? 'E.g.: My love life?' : 'Örn: Aşk hayatım?';
  static String get exampleFuture => _isEnglish ? 'E.g.: How is my future?' : 'Örn: Geleceğim nasıl?';
  static String get exampleCareer => _isEnglish ? 'E.g.: Hint about my career?' : 'Örn: Kariyerimle ilgili ipucu?';
  static String get selectFromGallery => _isEnglish ? 'Select from Gallery' : 'Galeriden Seç';
  static String get takePhoto => _isEnglish ? 'Take Photo' : 'Fotoğraf Çek';
  static String get gallery => _isEnglish ? 'Gallery' : 'Galeri';
  static String get camera => _isEnglish ? 'Camera' : 'Kamera';
  static String get noPhotoSelected => _isEnglish ? 'No photo selected yet' : 'Henüz fotoğraf seçilmedi';
  static String get tips => _isEnglish ? 'Tips' : 'İpuçları';
  static String get images => _isEnglish ? 'Images' : 'Görseller';
  static String get fortuneCreationError => _isEnglish ? 'Error creating fortune' : 'Fal oluşturulurken hata oluştu';
  static String get imageUploadError => _isEnglish ? 'Image upload error. Please try again.' : 'Görsel yükleme hatası. Lütfen tekrar deneyin.';
  static String get permissionError => _isEnglish ? 'Permission error. Images could not be uploaded.' : 'Yetki hatası. Görseller yüklenemedi.';
  static String get networkConnectionError => _isEnglish ? 'Internet connection error. Please check.' : 'İnternet bağlantısı hatası. Lütfen kontrol edin.';
  static String get photoSelectionError => _isEnglish ? 'Error selecting photo:' : 'Fotoğraf seçilirken hata oluştu:';
  static String get photoCaptureError => _isEnglish ? 'Error capturing photo:' : 'Fotoğraf çekilirken hata oluştu:';
  static String get imageCaptureError => _isEnglish ? 'Image could not be captured:' : 'Görüntü alınamadı:';
  static String get pleaseSelectAtLeastOnePhoto => _isEnglish ? 'Please select at least one photo' : 'Lütfen en az bir fotoğraf seçin';
  static String get shareFailedTextCopied => _isEnglish ? 'Share failed. Text copied.' : 'Paylaşım açılamadı. Metin kopyalandı.';
  static String get dreamDrawing => _isEnglish ? 'Dream Drawing' : 'Rüya Çizimi';
  
  // Dream Interpretation Screen
  static String get tellYourDream => _isEnglish ? 'Tell your dream in detail, and Falla will interpret it.' : 'Rüyanı detaylıca anlat, Falla yorumlasın.';
  static String get yourDream => _isEnglish ? 'Your Dream' : 'Rüyan';
  static String get dreamExampleHint => _isEnglish ? 'E.g.: I got lost in a dark forest and a wolf appeared…' : 'Örn: Karanlık bir ormanda kayboldum ve bir kurt belirdi…';
  static String get createInterpretation => _isEnglish ? 'Create Interpretation' : 'Yorumu Oluştur';
  static String get writeYourDream => _isEnglish ? 'Write your dream' : 'Rüyanı yaz';
  
  // Dream Draw Screen
  static String get drawMyDreamTitle => _isEnglish ? 'Draw My Dream' : 'Rüyamı Çiz';
  static String get describeYourDream => _isEnglish ? 'Describe Your Dream' : 'Rüyanı Anlat';
  static String get dreamDrawExampleHint => _isEnglish ? 'E.g.: While walking in a foggy forest, purple stars were falling from the sky…' : 'Örn: Sisli bir ormanda yürürken gökyüzünden mor yıldızlar yağıyordu…';
  static String get selectStyle => _isEnglish ? 'Select Style' : 'Stil Seç';
  static String get drawing => _isEnglish ? 'Drawing…' : 'Çiziliyor…';
  static String get drawMyDreamButton => _isEnglish ? 'Draw My Dream' : 'Rüyamı Çiz';
  static String get youMustWriteDream => _isEnglish ? 'You must write your dream.' : 'Rüyanı yazmalısın.';
  static String get noInternetConnection => _isEnglish ? 'No internet connection or DNS could not be resolved. Please try again.' : 'İnternet bağlantısı yok veya DNS çözümlenemedi. Lütfen tekrar deneyin.';
  static String get userLoginRequired => _isEnglish ? 'User login required.' : 'Kullanıcı girişi gerekli.';
  static String get imageCouldNotBeUploaded => _isEnglish ? 'Image could not be uploaded.' : 'Görsel yüklenemedi.';
  static String get imageCouldNotBeGenerated => _isEnglish ? 'Image could not be generated:' : 'Görsel üretilemedi:';
  static String get dreamVisualized => _isEnglish ? 'Your dream has been visualized' : 'Rüyanız görselleştirildi';
  
  // Face Fortune Screen
  static String get pleaseSelectAtLeastOneFacePhoto => _isEnglish ? 'Please select at least one face photo' : 'Lütfen en az bir yüz fotoğrafı seçin';
  static String get requiredKarma => _isEnglish ? 'Required' : 'Gerekli';
  static String get karmaRequired => _isEnglish ? 'Required: {0} karma' : 'Gerekli: {0} karma';
  static String get facePhotos => _isEnglish ? 'Face Photos' : 'Yüz Fotoğrafları';
  static String get uploadFacePhotosClear => _isEnglish ? 'Upload photos where your face is clearly visible' : 'Yüzün net göründüğü fotoğrafları yükleyin';
  static String get uploadPhoto => _isEnglish ? 'Upload Photo' : 'Fotoğraf Yükle';
  
  // Dream Draw Style Options
  static List<String> get dreamDrawStyles => _isEnglish
      ? [
          'Mystic, dim tones, purple-pink aura',
          'Surreal, oil painting, van gogh texture',
          'Cinematic, high contrast, dramatic lighting',
          'Watercolor, pastel, soft texture',
          'Comic book, dark ink and neon',
        ]
      : [
          'Mistik, loş tonlar, mor-pembe aura',
          'Sürreal, yağlı boya, van gogh dokusu',
          'Sinematik, yüksek kontrast, dramatik ışık',
          'Su boyası, pastel, yumuşak doku',
          'Çizgi roman, koyu mürekkep ve neon',
        ];
  
  // Dream Draw AI Prompt
  static String get dreamVisualizePrompt => _isEnglish 
      ? 'Visualize the dream: {0} | Style: {1} | theme: night, stars, light mist, glowing aura, high detail, cinematic lighting, 4k'
      : 'Rüyayı görselleştir: {0} | Stil: {1} | tema: gece, yıldızlar, hafif sis, parıltılı aura, yüksek detay, sinematik ışık, 4k';
  
  // Social - Love Compatibility
  static String get loveCompatibilityTestResult => _isEnglish 
      ? 'Our Love Compatibility Test Result: {0}%\n\nCheck love compatibility with Falla!'
      : 'Aşk Uyumu Testi Sonucumuz: {0}%\n\nFalla ile aşk uyumuna bak!';
  
  // Zodiac Elements (for compatibility calculation)
  static Set<String> get zodiacFireElements => _isEnglish 
      ? {'Aries', 'Leo', 'Sagittarius'}
      : {'Koç', 'Aslan', 'Yay'};
  static Set<String> get zodiacEarthElements => _isEnglish 
      ? {'Taurus', 'Virgo', 'Capricorn'}
      : {'Boğa', 'Başak', 'Oğlak'};
  static Set<String> get zodiacAirElements => _isEnglish 
      ? {'Gemini', 'Libra', 'Aquarius'}
      : {'İkizler', 'Terazi', 'Kova'};
  static Set<String> get zodiacWaterElements => _isEnglish 
      ? {'Cancer', 'Scorpio', 'Pisces'}
      : {'Yengeç', 'Akrep', 'Balık'};
  
  // Aura Colors (for matching)
  static List<String> get auraColorNames => _isEnglish
      ? ['Purple', 'Blue', 'Green', 'Yellow', 'Orange', 'Red', 'Pink', 'Indigo', 'Turquoise']
      : ['Mor', 'Mavi', 'Yeşil', 'Sarı', 'Turuncu', 'Kırmızı', 'Pembe', 'Indigo', 'Turkuaz'];
  
  // Aura Moods (for matching)
  static List<String> get positiveMoods => _isEnglish
      ? ['Happy', 'Energetic', 'Calm', 'Relaxed', 'Cheerful']
      : ['Mutlu', 'Enerjik', 'Sakin', 'Rahat', 'Neşeli'];
  static List<String> get negativeMoods => _isEnglish
      ? ['Tired', 'Stressed', 'Anxious', 'Sad']
      : ['Yorgun', 'Stresli', 'Kaygılı', 'Üzgün'];
  
  // Social - Soulmate Analysis
  static String get sendRequest => _isEnglish ? 'Send Request' : 'İstek Gönder';
  static String get sendConnectionRequestTo => _isEnglish 
      ? 'Send connection request to {0}?'
      : '{0} kullanıcısına bağlantı isteği gönderilsin mi?';
  static String get noFreeMatchesLeft => _isEnglish 
      ? 'You have no free matches left'
      : 'Ücretsiz eşleşme hakkınız kalmadı';
  static String get freeMatchNotAvailable => _isEnglish 
      ? 'Free match not available'
      : 'Ücretsiz eşleşme kullanılamadı';
  
  // Fortune Result
  static String get fortuneStillPreparing => _isEnglish 
      ? 'Your fortune is still being prepared! Please wait.'
      : 'Falınız henüz hazırlanıyor! Lütfen bekleyin.';
  
  // Main Screen
  static String get dailyVideoLimitReached => _isEnglish 
      ? 'You have reached the daily video limit. Please try again tomorrow.'
      : 'Günlük video limitine ulaştınız. Yarın tekrar deneyin.';
  
  // Card Widgets
  static String get mystical => _isEnglish ? 'MYSTICAL' : 'MİSTİK';
  static String get selected => _isEnglish ? 'SELECTED' : 'SEÇİLDİ';
  static String get mysticalCards => _isEnglish ? 'MYSTICAL CARDS' : 'MİSTİK KARTLAR';
  
  // Coffee Fortune Photo Descriptions
  static String get coffeeGroundsAndResidues => _isEnglish ? 'Coffee Grounds and Residues' : 'Kahve Telvesi ve Kalıntıları';
  static String get coffeeGroundsAndResiduesDesc => _isEnglish ? 'Take clear photos that clearly show the coffee grounds and residues.' : 'Kahve telvesi ve kalıntılarını net gösteren fotoğraflar çek.';
  static String get cupAndPlateDifferentAngles => _isEnglish ? 'Cup and Plate from Different Angles' : 'Fincan ve Tabağın Farklı Açıları';
  static String get cupAndPlateDifferentAnglesDesc => _isEnglish ? 'Upload clear photos of the cup and plate taken from different angles.' : 'Fincan ve tabağın farklı açılardan çekilmiş net fotoğraflarını yükleyin.';
  static String get facePhotosClear => _isEnglish ? 'Face Photos - Clear Face' : 'Yüz Fotoğrafları - Net Yüz';
  static String get facePhotosClearDesc => _isEnglish ? 'Upload photos where your face is clearly visible.' : 'Yüzün net göründüğü fotoğrafları yükleyin.';
  static String get fortuneTellerLooking => _isEnglish ? 'The fortune teller is looking at your fortune…' : 'Falcı falınıza bakıyor…';
  static String get speedUpFortuneTeller => _isEnglish ? 'You can watch an ad to speed up your fortune teller\'s thinking' : 'Falcınızın düşünmesini hızlandırmak için reklam izleyebilirsiniz';
  static String get speedUpFortuneTellerButton => _isEnglish ? 'Speed Up Fortune Teller\'s Thinking' : 'Falcının Düşünmesini Hızlandır';
  
  // Kahve falı
  static String get fortuneTopicsTitle => _isEnglish ? 'What are you curious about?' : 'Merak ettiğin konular?';
  static String get forWhomTitle => _isEnglish ? 'For whom?' : 'Kimin için?';
  static String get nameTitle => _isEnglish ? 'Name' : 'İsim';
  static String get nameHint => _isEnglish ? 'Enter name' : 'İsim giriniz';
  static String get birthDateTitle => _isEnglish ? 'Birth date' : 'Doğum günü';
  static String get birthDateHint => _isEnglish ? 'Day / Month / Year' : 'Gün / Ay / Yıl';
  static String get relationshipStatusTitle => _isEnglish ? 'Relationship status' : 'İlişki durumu';
  static String get jobStatusTitle => _isEnglish ? 'Job status' : 'İş durumu';
  static String get selectHint => _isEnglish ? 'Select' : 'Seçiniz';
  static List<String> get fortuneTopics => _isEnglish
      ? [
          'Love',
          'Family',
          'Friendship',
          'Career',
          'Health',
          'General',
          'Luck',
        ]
      : [
          'Aşk',
          'Aile',
          'Arkadaş',
          'Kariyer',
          'Sağlık',
          'Genel',
          'Şansıma',
        ];
  static List<String> get relationshipStatusOptions => _isEnglish
      ? [
          'Single',
          'Crush',
          'Talking stage',
          'Honeymoon phase',
          'In a relationship',
          'Recently broke up',
          'Engaged',
          'Married',
          'Widowed',
          'Divorced',
        ]
      : [
          'İlişkisi yok',
          'Platonik',
          'Flört halinde',
          'Cicim ayları',
          'İlişkisi var',
          'Yeni ayrılmış',
          'Nişanlı',
          'Evli',
          'Dul',
          'Boşanmış',
        ];
  static List<String> get jobStatusOptions => _isEnglish
      ? [
          'Academic',
          'Not working',
          'Retired',
          'Homemaker',
          'Self-employed',
          'Public sector',
          'Job seeking',
          'Student',
          'Private sector',
        ]
      : [
          'Akademisyen',
          'Çalışmıyor',
          'Emekli',
          'Ev hanımı',
          'Kendi işini yapıyor',
          'Kamu Sektörü',
          'İş arıyor',
          'Öğrenci',
          'Özel Sektör',
        ];
  static String get coffeePhotos => _isEnglish ? 'Coffee Photos' : 'Kahve Fotoğrafları';
  static String get upload3to5Photos => _isEnglish ? 'Upload 3-5 photos (cup, plate)' : '3-5 fotoğraf yükleyin (fincan, tabak)';
  static String get tipShowCoffeeResidue => _isEnglish ? '• Show coffee residue in the cup clearly' : '• Fincanın içindeki kahve kalıntılarını net gösterin';
  static String get tipPhotographPlate => _isEnglish ? '• Also photograph the cup\'s plate' : '• Fincanın tabağını da fotoğraflayın';
  static String get tipUseGoodLighting => _isEnglish ? '• Use good lighting' : '• İyi aydınlatma kullanın';
  static String get tipPhotographFromDifferentAngles => _isEnglish ? '• Photograph the cup from different angles' : '• Fincanı farklı açılardan çekin';
  static String get coffeeExamplePhotosTitle => _isEnglish
      ? 'Sample Photos (How should you take them?)'
      : 'Örnek Fotoğraflar (Nasıl çekmelisin?)';
  static String get coffeeExamplePhotosDesc => _isEnglish
      ? 'For a good coffee fortune, upload clear photos of the cup and plate from different angles. The coffee grounds and residue should be clearly visible.'
      : 'İyi bir kahve falı için fincan ve tabağın farklı açılardan çekilmiş net fotoğraflarını yükleyin. Kahve telvesi ve kalıntıları net görünmeli.';
  static String get coffeeExampleCupTop => _isEnglish ? 'Cup - Top view' : 'Fincan Üstten';
  static String get coffeeExampleCupSide => _isEnglish ? 'Cup - Side view' : 'Fincan Yandan';
  static String get coffeeExamplePlateTop => _isEnglish ? 'Plate - Top view' : 'Tabağın Üstü';
  
  // El falı
  static String get palmFortuneCreationError => _isEnglish ? 'Palm fortune could not be created' : 'El falı oluşturulamadı';
  static String get photographPalmLines => _isEnglish ? 'Take photos showing palm lines clearly.' : 'Avuç içi çizgilerini net gösteren fotoğraflar çek.';
  static String get leftPalm => _isEnglish ? 'Left Palm' : 'Sol Avuç';
  static String get rightPalm => _isEnglish ? 'Right Palm' : 'Sağ Avuç';
  static String get takePalmPhoto => _isEnglish ? 'Take palm photo' : 'Avuç içi fotoğrafı çek';
  
  // Katina falı
  static String get katinaFortuneCreationError => _isEnglish ? 'Katina could not be created' : 'Katina oluşturulamadı';
  static String get katinaFortuneDesc => _isEnglish ? 'You can specify your problem for Katina fortune, let Falla interpret it.' : 'Katina falı için sorunu belirtebilirsin, Falla yorumlasın.';
  
  // Yüz falı
  static String get faceFortuneCreationError => _isEnglish ? 'Face fortune could not be created' : 'Yüz falı oluşturulamadı';
  static String get faceFortuneDesc => _isEnglish ? 'Discover your destiny through face reading. Facial features reveal insights about your personality, future, and life path.' : 'Yüz okuma ile kaderini keşfet. Yüz hatları, kişiliğin, geleceğin ve yaşam yolun hakkında içgörüler ortaya çıkarır.';
  
  // Tarot falı - ek string'ler
  static String get tapToSelectCards => _isEnglish ? 'Tap below to select cards' : 'Kart seçmek için alta dokunun';
  static String get cardsSelected => _isEnglish ? 'cards selected' : 'kart seçildi';
  static String get exampleRelationshipFuture => _isEnglish ? 'E.g.: Future of my relationship?' : 'Örn: İlişkimin geleceği?';
  static String get select3Cards => _isEnglish ? 'Select 3 cards' : '3 kart seçin';
  static String get pleaseSelect3Cards => _isEnglish ? 'Please select 3 cards' : 'Lütfen 3 kart seçiniz';
  
  // Sosyal sayfalar
  static String get discoverCompatibleSouls => _isEnglish ? 'Discover people compatible with your soul' : 'Ruhunun uyumlu olduğu kişileri keşfet';
  static String get match => _isEnglish ? 'Match' : 'Eşleş';
  static String get noAuraMatchesYet => _isEnglish ? 'No aura-compatible matches yet' : 'Henüz aura uyumlu eşleşmen yok';
  static String get pressMatchToMeetNewPeople => _isEnglish ? 'Press Match to meet new people' : 'Eşleş butonuna basarak yeni insanlarla tanış';
  static String get messages => _isEnglish ? 'Messages' : 'Mesajlar';
  static String get connectFromSoulmateAnalysis => _isEnglish ? 'Connect with aura-compatible people from Soulmate Analysis page' : 'Ruh Eşi Analizi sayfasından aura uyumlu kişilerle bağlantı kur';
  static String get messageCouldNotBeSent => _isEnglish ? 'Message could not be sent:' : 'Mesaj gönderilemedi:';
  static String get noMessagesYet => _isEnglish ? 'No messages yet' : 'Henüz mesaj yok';
  static String get sendYourFirstMessage => _isEnglish ? 'Send your first message' : 'İlk mesajınızı gönderin';
  static String get writeMessage => _isEnglish ? 'Write a message...' : 'Mesaj yazın...';
  static String get compatibility => _isEnglish ? 'Compatibility' : 'Uyum';
  static String get relationshipQuestions => _isEnglish ? 'Relationship Questions' : 'İlişki Soruları';
  static String get trustLevel => _isEnglish ? 'Trust level' : 'Güven düzeyi';
  static String get communicationQuality => _isEnglish ? 'Communication quality' : 'İletişim kalitesi';
  static String get conflictFrequency => _isEnglish ? 'Conflict frequency (0=none, 5=often)' : 'Kavga sıklığı (0=hiç, 5=çok)';
  static String get futureGoalAlignment => _isEnglish ? 'Future goal alignment' : 'Gelecek hedef uyumu';
  static String get fillNameAndBirthDates => _isEnglish ? 'Fill in names and birth dates.' : 'İsim ve doğum tarihlerini doldurun.';
  static String get calculating => _isEnglish ? 'Calculating…' : 'Hesaplanıyor…';
  static String get calculateLoveCompatibility => _isEnglish ? 'Calculate Love Compatibility' : 'Aşk Uyumunu Hesapla';
  static String get loveCompatibilityTest => _isEnglish ? 'Love Compatibility Test' : 'Aşk Uyumu Testi';
  static String get personA => _isEnglish ? 'Person A' : 'Kişi A';
  static String get personB => _isEnglish ? 'Person B' : 'Kişi B';
  static String get zodiacLabel => _isEnglish ? 'Zodiac' : 'Burç';
  static String get compatibilityScore => _isEnglish ? 'Compatibility Score' : 'Uyum Skoru';
  static String get whatDoesFallaSay => _isEnglish ? 'What does Falla say?' : 'Falla ne diyor?';
  static String get calculationFailed => _isEnglish ? 'Calculation failed:' : 'Hesaplama başarısız:';
  static String get sessionNotFound => _isEnglish ? 'Session not found' : 'Oturum bulunamadı';
  static String get couldNotLoad => _isEnglish ? 'Could not load:' : 'Yüklenemedi:';
  static String get searchingMatches => _isEnglish ? 'Searching for matches...' : 'Eşleşmeler aranıyor...';
  static String get noSuitableMatchFound => _isEnglish ? 'No suitable match found' : 'Uygun eşleşme bulunamadı';
  static String get zodiacUnknown => _isEnglish ? 'Zodiac unknown' : 'Burç bilinmiyor';
  static String get percentCompatibility => _isEnglish ? '% Compatibility' : '% Uyum';
  static String get auraEnergy => _isEnglish ? 'Aura Energy' : 'Aura Enerjisi';
  static String get establishConnection => _isEnglish ? 'Establish Connection' : 'Bağlantı Kur';
  static String get connectionEstablished => _isEnglish ? 'Connection established:' : 'Bağlantı kuruldu:';
  static String get auraCompatible => _isEnglish ? '✨ Aura compatible' : '✨ Aura uyumlu';
  static String get connectionCouldNotBeEstablished => _isEnglish ? 'Connection could not be established:' : 'Bağlantı kurulamadı:';
  
  // Match system strings
  static String get pendingRequests => _isEnglish ? 'Pending Requests' : 'Bekleyen İstekler';
  static String get requests => _isEnglish ? 'Requests' : 'İstekler';
  static String get chat => _isEnglish ? 'Chat' : 'Sohbet';
  static String get genderFilter => _isEnglish ? 'Gender Filter' : 'Cinsiyet Filtresi';
  static String get genderFilterDesc => _isEnglish ? 'Filter matches by gender (10 karma per use)' : 'Eşleşmeleri cinsiyete göre filtrele (kullanım başına 10 karma)';
  static String get genderFilterUsed => _isEnglish ? 'Gender filter used' : 'Cinsiyet filtresi kullanıldı';
  static String get useGenderFilter => _isEnglish ? 'Use Gender Filter' : 'Cinsiyet Filtresini Kullan';
  static String get filterByGender => _isEnglish ? 'Filter by Gender' : 'Cinsiyete Göre Filtrele';
  static String get allGenders => _isEnglish ? 'All Genders' : 'Tüm Cinsiyetler';
  static String get matchAccepted => _isEnglish ? 'Match accepted with' : 'Eşleşme kabul edildi:';
  static String get matchEstablished => _isEnglish ? 'Match established!' : 'Eşleşme kuruldu!';
  static String get matchAlreadyExists => _isEnglish ? 'Match already exists' : 'Eşleşme zaten mevcut';
  static String get requestAlreadySent => _isEnglish ? 'Request already sent' : 'İstek zaten gönderildi';
  static String get requestSent => _isEnglish ? 'Request sent to' : 'İstek gönderildi:';
  static String get requestRejected => _isEnglish ? 'Request rejected' : 'İstek reddedildi';
  static String get blockUser => _isEnglish ? 'Block User' : 'Kullanıcıyı Engelle';
  static String get blockUserConfirm => _isEnglish ? 'Are you sure you want to block this user? They will not be able to send you requests or see you in discover lists.' : 'Bu kullanıcıyı engellemek istediğinize emin misiniz? Size istek gönderemez ve keşfet listelerinde görünmez.';
  static String get userBlocked => _isEnglish ? 'User blocked successfully' : 'Kullanıcı başarıyla engellendi';
  static String get userUnblocked => _isEnglish ? 'User unblocked successfully' : 'Kullanıcı engeli başarıyla kaldırıldı';
  static String get blockedUsers => _isEnglish ? 'Blocked Users' : 'Engellenenler';
  static String get blockedUsersEmpty => _isEnglish ? 'No blocked users' : 'Engellenen kullanıcı yok';
  static String get blockedUsersDesc => _isEnglish ? 'Users you have blocked will not be able to see your profile or send you requests.' : 'Engellediğiniz kullanıcılar profilinizi göremez veya size istek gönderemez.';
  static String get unblockUser => _isEnglish ? 'Unblock' : 'Engeli Kaldır';
  static String get unblockUserConfirm => _isEnglish ? 'Are you sure you want to unblock this user?' : 'Bu kullanıcının engelini kaldırmak istediğinize emin misiniz?';
  static String get chatBlockedByAge => _isEnglish ? 'This chat has been closed due to age restrictions.' : 'Bu sohbet yaş kısıtlaması sebebiyle kapatıldı.';
  static String get matchBlockedByAge => _isEnglish ? 'This match has been blocked due to age restrictions.' : 'Bu eşleşme yaş kısıtlaması sebebiyle engellendi.';
  static String get errorOccurred => _isEnglish ? 'An error occurred:' : 'Bir hata oluştu:';

  // Spin Wheel Screen
  static String get spinning => _isEnglish ? 'Spinning...' : 'Dönüyor...';
  static String get spin => _isEnglish ? 'Spin' : 'Çevir';
  static String get canSpinOncePerDay => _isEnglish ? 'You can spin the wheel once every 24 hours.' : 'Çarkı 24 saatte bir çevirebilirsin.';
  static String get dailyExtraSpinUsed => _isEnglish ? 'You have used your daily extra spin.' : 'Günlük ekstra çevirme hakkınızı kullandınız.';
  static String get adNotWatchedExtraSpin => _isEnglish ? 'Ad not watched. Could not earn extra spin.' : 'Reklam izlenmedi. Ekstra çevirme hakkı kazanılamadı.';
  static String get daily2xRewardUsed => _isEnglish ? 'You have used your daily 2x reward.' : 'Günlük 2x ödül hakkınızı kullandınız.';
  static String get adNotWatched2xReward => _isEnglish ? 'Ad not watched. Reward could not be doubled.' : 'Reklam izlenmedi. Ödül ikiye katlanamadı.';
  static String get rewardDoubled => _isEnglish ? '🎉 Your reward has been doubled! You earned +{amount} more karma!' : '🎉 Ödülünüz ikiye katlandı! +{amount} karma daha kazandınız!';
  static String get doubleReward => _isEnglish ? 'Double Reward 2x' : 'Ödülü 2x Katla';
  static String get watchAdToDoubleReward => _isEnglish ? 'Watch an ad to double your reward' : 'Reklam izleyerek ödülünüzü ikiye katlayın';
  static String get watchAdAndSpinExtra => _isEnglish ? 'Watch Ad & Spin Extra' : 'Reklam İzle & Ekstra Çevir';
  static String get daily1ExtraSpin => _isEnglish ? '1 daily extra spin' : 'Günlük 1 ekstra çevirme hakkı';

  // Premium Screen
  static String get adFreeExperience => _isEnglish ? 'Ad-Free Experience' : 'Reklamsız Deneyim';
  static String get adFreeExperienceDesc => _isEnglish 
      ? 'Enjoy uninterrupted fortune readings without any advertisements. Focus on your mystical journey without distractions.'
      : 'Hiç reklam görmeden kesintisiz fal deneyimi yaşa. Dikkat dağıtıcı olmadan mistik yolculuğuna odaklan.';
  static String get daily25Karma => _isEnglish ? 'Daily 25 Karma' : 'Günlük 25 Karma';
  static String get daily25KarmaDesc => _isEnglish 
      ? 'Receive 25 karma points automatically every day. Build your karma faster and unlock premium features effortlessly.'
      : 'Her gün otomatik olarak 25 karma puanı kazan. Karmanı daha hızlı biriktir ve premium özellikleri zahmetsizce aç.';
  static String get priorityFortuneReading => _isEnglish ? 'Priority Fortune Reading' : 'Öncelikli Fal Baktırma';
  static String get priorityFortuneReadingDesc => _isEnglish 
      ? 'Your fortune readings are processed with priority speed. Get faster results and never wait in queue again.'
      : 'Fal yorumların öncelikli hızda işlenir. Daha hızlı sonuçlar al ve bir daha asla sırada bekleme.';
  static String get auraMatchAdvantages => _isEnglish ? 'Aura Match Advantages' : 'Aura Eşleşmesi Avantajları';
  static String get auraMatchAdvantagesDesc => _isEnglish 
      ? 'Select gender preferences for free and get one daily aura match. Find your perfect soulmate connection.'
      : 'Cinsiyet tercihlerini ücretsiz seç ve günlük 1 aura eşleşmesi al. Mükemmel ruh eşi bağlantını bul.';
  static String auraFreeMatches(int count) =>
      _isEnglish ? '$count free' : '$count ücretsiz';
  static String get weekly => _isEnglish ? 'Weekly' : 'Haftalık';
  static String get week => _isEnglish ? 'week' : 'hafta';
  static String get monthly => _isEnglish ? 'Monthly' : 'Aylık';
  static String get month => _isEnglish ? 'month' : 'ay';
  static String get yearly => _isEnglish ? 'Yearly' : 'Yıllık';
  static String get year => _isEnglish ? 'year' : 'yıl';
  static String get bestValue => _isEnglish ? 'Best Value' : 'En İyi Değer';
  static String get premiumMembershipNotUpdated => _isEnglish ? 'Premium membership could not be updated' : 'Premium üyelik güncellenemedi';
  static String get purchaseErrorUnknown => _isEnglish ? 'Unknown error' : 'Bilinmeyen hata';
  static String get subscriptionNotFound => _isEnglish ? 'Subscription not found' : 'Abonelik bulunamadı';
  static String get purchaseNotAvailableTryLater => _isEnglish ? 'Purchase is not available right now. Please try again later.' : 'Satın alma şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  // Test Result Screen
  static String get testResult => _isEnglish ? 'Test Result' : 'Test Sonucu';
  static String get testResults => _isEnglish ? 'Test Results' : 'Test Sonuçları';
  static String get testCompleted => _isEnglish ? 'Completed' : 'Tamamlandı';
  static String get personalityTestCompleted => _isEnglish ? 'Personality Test Completed' : 'Kişilik Testi Tamamlandı';
  static String get testResultPreparing => _isEnglish ? 'Your test result is being prepared! Please wait.' : 'Test sonucunuz henüz hazırlanıyor! Lütfen bekleyin.';
  static String get shareError => _isEnglish ? 'Share error:' : 'Paylaşım hatası:';
  static String get resultCopiedToClipboard => _isEnglish ? 'Result copied to clipboard' : 'Sonuç panoya kopyalandı';
  static String get copyError => _isEnglish ? 'Copy error:' : 'Kopyalama hatası:';
  static String get fortuneTellerLookingAtTest => _isEnglish ? 'Fortune teller is looking at your test…' : 'Falcı testinize bakıyor…';
  static String get watchAdToSpeedUpFortuneTeller => _isEnglish ? 'You can watch an ad to speed up your fortune teller\'s thinking' : 'Falcınızın düşünmesini hızlandırmak için reklam izleyebilirsiniz';
  static String get remainingTime => _isEnglish ? 'Remaining Time' : 'Kalan Süre';
  static String get speedUpFortuneTellerThinking => _isEnglish ? 'Speed Up Fortune Teller\'s Thinking' : 'Falcının Düşünmesini Hızlandır';
  static String get watchAdToSpeedUp5Min => _isEnglish ? 'Watch an ad to speed up by 5 minutes' : 'Reklam izleyerek 5 dakika hızlandır';
  static String get analysisResult => _isEnglish ? 'Analysis Result' : 'Analiz Sonucu';
  static String get copy => _isEnglish ? 'Copy' : 'Kopyala';
  static String get returnToTestsPage => _isEnglish ? 'Return to Tests Page' : 'Testler Sayfasına Dön';
  static String get newTest => _isEnglish ? 'New Test' : 'Yeni Test Yap';
  static String get testDate => _isEnglish ? 'Test Date:' : 'Test Tarihi:';
  static String get daysAgoShort => _isEnglish ? 'days ago' : 'gün önce';
  static String get weeksAgo => _isEnglish ? 'weeks ago' : 'hafta önce';
  static String get now => _isEnglish ? 'now' : 'şimdi';
  static String get minAgo => _isEnglish ? 'min ago' : 'dk önce';

  // Profile Screen
  static String get signingOut => _isEnglish ? 'Signing Out' : 'Çıkış Yapılıyor';
  static String get guestSignOutWarning => _isEnglish ? 'You are signing out from a guest account. When you sign out:' : 'Misafir hesabından çıkış yapıyorsunuz. Çıkış yaptığınızda:';
  static String get allFortunesWillBeDeleted => _isEnglish ? 'All your fortunes will be deleted' : 'Tüm fallarınız silinecek';
  static String get karmaPointsWillBeLost => _isEnglish ? 'Your karma points will be lost' : 'Karma puanınız kaybolacak';
  static String get profileInfoWillBeDeleted => _isEnglish ? 'Your profile information will be deleted' : 'Profil bilgileriniz silinecek';
  static String get cannotAccessAccountAgain => _isEnglish ? 'You will not be able to access this account again' : 'Bu hesaba tekrar erişemeyeceksiniz';
  static String get areYouSureSignOut => _isEnglish ? 'Are you sure you want to sign out?' : 'Çıkış yapmak istediğinize emin misiniz?';
  static String get deleteAccount => _tr({
    'tr': 'Hesabı Sil', 'en': 'Delete Account', 'it': 'Elimina Account', 'fr': 'Supprimer Compte',
    'ru': 'Удалить аккаунт', 'de': 'Konto Löschen', 'ar': 'حذف الحساب', 'fa': 'حذف حساب',
  });
  static String get thisActionCannotBeUndone => _isEnglish ? 'This action cannot be undone!' : 'Bu işlem geri alınamaz!';
  static String get areYouSureDeleteAccount => _isEnglish ? 'Are you sure you want to delete your account?\n\n' : 'Hesabınızı silmek istediğinizden emin misiniz?\n\n';
  static String get allPersonalDataWillBeDeleted => _isEnglish ? '• All your personal data will be deleted\n' : '• Tüm kişisel verileriniz silinecek\n';
  static String get fortuneHistoryWillBeLost => _isEnglish ? '• Your fortune history will be lost\n' : '• Fal geçmişiniz kaybolacak\n';
  static String get karmaPointsWillBeReset => _isEnglish ? '• Your karma points will be reset\n' : '• Karma puanlarınız sıfırlanacak\n';
  static String get premiumMembershipWillBeCancelled => _isEnglish ? '• Your premium membership will be cancelled\n\n' : '• Premium üyeliğiniz iptal edilecek\n\n';
  static String get thisActionIsPermanent => _isEnglish ? 'This action is permanent and cannot be undone.' : 'Bu işlem kalıcıdır ve geri alınamaz.';
  static String get accountDeletedSuccessfully => _isEnglish ? 'Your account has been successfully deleted.' : 'Hesabınız başarıyla silindi.';
  static String get errorDeletingAccount => _isEnglish ? 'An error occurred while deleting the account.' : 'Hesap silinirken bir hata oluştu.';
  static String get errorDeletingAccountWithError => _isEnglish ? 'Error occurred while deleting account:' : 'Hesap silinirken hata oluştu:';
  static String get profileLoading => _isEnglish ? 'Loading profile...' : 'Profil yükleniyor...';
  static String get themeSettings => _tr({
    'tr': 'Tema', 'en': 'Theme', 'it': 'Tema', 'fr': 'Thème',
    'ru': 'Тема', 'de': 'Thema', 'ar': 'مظهر', 'fa': 'تم',
  });
  static String get language => _tr({
    'tr': 'Dil', 'en': 'Language', 'it': 'Lingua', 'fr': 'Langue',
    'ru': 'Язык', 'de': 'Sprache', 'ar': 'لغة', 'fa': 'زبان',
  });
  static String get areYouSure => _tr({
    'tr': 'Emin misin?', 'en': 'Are you sure?', 'it': 'Sei sicuro?', 'fr': 'Êtes-vous sûr?',
    'ru': 'Вы уверены?', 'de': 'Bist du sicher?', 'ar': 'هل أنت متأكد؟', 'fa': 'آیا مطمئن هستید؟',
  });
  static String get delete => _tr({
    'tr': 'Sil', 'en': 'Delete', 'it': 'Elimina', 'fr': 'Supprimer',
    'ru': 'Удалить', 'de': 'Löschen', 'ar': 'حذف', 'fa': 'حذف',
  });
  static String get darkTheme => _isEnglish ? 'Dark Theme' : 'Karanlık Tema';
  static String get lightTheme => _isEnglish ? 'Light Theme' : 'Aydınlık Tema';
  static String get mysticalMode => _isEnglish ? 'Mystical Mode' : 'Mistik Mod';
  static String get particleEffects => _isEnglish ? 'Particle Effects' : 'Parçacık Efektleri';
  static String get glowEffects => _isEnglish ? 'Glow Effects' : 'Işıltı Efektleri';
  static String get premiumTheme => _isEnglish ? 'Premium Theme' : 'Premium Tema';
  static String get privacyPolicy => _isEnglish ? 'Privacy Policy' : 'Gizlilik Politikası';
  static String get privacyPolicyDesc => _isEnglish ? 'Falla app values user privacy greatly. Your personal information is stored securely and not shared with third parties.\n\n' : 'Falla uygulaması, kullanıcı gizliliğine büyük önem verir. Kişisel bilgileriniz güvenli bir şekilde saklanır ve üçüncü taraflarla paylaşılmaz.\n\n';
  static String get privacyPolicyPoints => _isEnglish ? '• All your data is stored encrypted\n• Your fortune results are only accessible to you\n• Your profile information can be updated anytime\n• You can delete your account anytime' : '• Tüm verileriniz şifrelenmiş bir şekilde saklanır\n• Fal sonuçlarınız sadece sizin erişiminize açıktır\n• Profil bilgileriniz istediğiniz zaman güncellenebilir\n• Hesabınızı istediğiniz zaman silebilirsiniz';
  static String get close => _isEnglish ? 'Close' : 'Kapat';
  static String get helpAndSupport => _isEnglish ? 'Help and Support' : 'Yardım ve Destek';
  static String get helpDesc => _isEnglish ? 'Everything you\'re looking for in the Falla app is here:\n\n' : 'Falla uygulamasında aradığınız her şey burada:\n\n';
  static String get helpPoints => _isEnglish ? '• Select fortune type from home page to read fortunes\n• Describe your dream in detail for dream interpretation\n• Update your mood for aura analysis\n• Solve personality tests from the Tests section\n• Complete daily tasks to earn karma' : '• Fal bakmak için ana sayfadan fal türünü seçin\n• Rüya yorumu için rüyanızı detaylıca anlatın\n• Aura analizi için ruh halinizi güncelleyin\n• Testler bölümünden kişilik testlerinizi çözün\n• Karma kazanmak için günlük görevleri tamamlayın';
  static String get questionsContact => _isEnglish ? 'For your questions:' : 'Sorularınız için:';
  static String get mysticalFortuneApp => _isEnglish ? 'Mystical fortune and astrology app\n\n' : 'Mistik fal ve astroloji uygulaması\n\n';
  static String get fallaWith => _isEnglish ? 'With Falla:\n' : 'Falla ile:\n';
  static String get fallaFeatures => _isEnglish ? '• Tarot, coffee, palm reading and more\n• Dream interpretations\n• Aura analysis and compatible matches\n• Daily horoscope readings\n• Personality and compatibility tests\n\n' : '• Tarot, kahve, el falı ve daha fazlası\n• Rüya yorumları\n• Aura analizi ve uyumlu eşleşmeler\n• Günlük burç yorumları\n• Kişilik ve uyumluluk testleri\n\n';
  static String get copyright => _isEnglish ? '© 2025 Falla. All rights reserved.' : '© 2025 Falla. Tüm hakları saklıdır.';
  static String get languageChangedSuccessfully => _isEnglish ? 'Language changed successfully' : 'Dil başarıyla değiştirildi';
  static String get profileUpdated => _isEnglish ? 'Profile updated' : 'Profil güncellendi';
  static String get saveChanges => _isEnglish ? 'Save Changes' : 'Değişiklikleri Kaydet';
  static String get auraColorLabel => _isEnglish ? 'Aura Color' : 'Aura Rengi';
  static String get auraColorHint => _isEnglish ? 'Your aura color is determined automatically based on your analyses.' : 'Aura rengi analizlerinize göre otomatik belirlenir.';
  static String get auraUpdatedSuccessfully => _isEnglish ? 'Aura color updated successfully!' : 'Aura rengi başarıyla güncellendi!';
  
  // Policy Links
  static String get byPurchasingYouAccept => _isEnglish ? 'By purchasing, you accept:' : 'Satın alarak şunları kabul etmiş olursunuz:';
  static String get privacyPolicyLink => _isEnglish ? 'Privacy Policy' : 'Gizlilik Politikası';
  static String get userAgreementLink => _isEnglish ? 'User Agreement' : 'Kullanıcı Sözleşmesi';
  static String get termsOfServiceLink => _isEnglish ? 'Terms of Service' : 'Kullanım Koşulları';

  // Auth Screens
  static String get loginError => _isEnglish ? 'Login Error' : 'Giriş Hatası';
  static String get loginFailed => _isEnglish ? 'Login failed' : 'Giriş yapılamadı';
  static String get guestLoginFailed => _isEnglish ? 'Guest login failed' : 'Misafir girişi başarısız';
  static String get ok => _isEnglish ? 'OK' : 'Tamam';
  static String get pleaseEnterEmail => _isEnglish ? 'Please enter your email address' : 'Lütfen e-posta adresinizi girin';
  static String get passwordResetEmailSent => _isEnglish ? '📧 Password reset email sent!\nCheck your inbox.' : '📧 Şifre sıfırlama e-postası gönderildi!\nE-posta kutunuzu kontrol edin.';
  static String get passwordResetFailed => _isEnglish ? 'Password reset failed' : 'Şifre sıfırlama başarısız';
  static String get welcomeToMysticalWorld => _isEnglish ? 'Welcome to the mystical world' : 'Mistik dünyaya hoş geldin';
  static String get email => _isEnglish ? 'Email' : 'E-posta';
  static String get password => _isEnglish ? 'Password' : 'Şifre';
  static String get forgotPassword => _isEnglish ? 'Forgot Password' : 'Şifremi Unuttum';
  static String get login => _isEnglish ? 'Login' : 'Giriş Yap';
  static String get dontHaveAccount => _isEnglish ? 'Don\'t have an account? ' : 'Hesabın yok mu? ';
  static String get register => _isEnglish ? 'Register' : 'Kayıt Ol';
  static String get or => _isEnglish ? 'or' : 'veya';
  static String get continueAsGuest => _isEnglish ? 'Continue as Guest' : 'Misafir Olarak Devam Et';
  static String get joinMysticalWorld => _isEnglish ? 'Join the mystical world' : 'Mistik dünyaya katıl';
  static String get fullName => _isEnglish ? 'Full Name' : 'Ad Soyad';
  static String get confirmPassword => _isEnglish ? 'Password (Repeat)' : 'Şifre (Tekrar)';
  static String get selectBirthDate => _isEnglish ? 'Select Birth Date' : 'Doğum Tarihi Seç';
  static String get zodiac => _isEnglish ? 'Zodiac' : 'Burç';
  static String get pleaseSelectBirthDate => _isEnglish ? 'Please select your birth date' : 'Lütfen doğum tarihinizi seçin';
  static String get pleaseSelectZodiac => _isEnglish ? 'Please select your zodiac sign' : 'Lütfen burcunuzu seçin';
  static String get registrationError => _isEnglish ? 'Registration Error' : 'Kayıt Hatası';
  static String get registrationFailed => _isEnglish ? 'Registration failed' : 'Kayıt başarısız';
  static String get alreadyHaveAccount => _isEnglish ? 'Already have an account? ' : 'Zaten hesabın var mı? ';
  static String get verifyingIdentity => _isEnglish ? 'Verifying identity...' : 'Kimlik doğrulanıyor...';
  static String get selectLanguage => _tr({
    'tr': 'Dil Seç', 'en': 'Select Language', 'it': 'Seleziona Lingua', 'fr': 'Choisir la Langue',
    'ru': 'Выбрать язык', 'de': 'Sprache wählen', 'ar': 'اختر اللغة', 'fa': 'انتخاب زبان',
  });
  static String get selectZodiac => _tr({
    'tr': 'Burç Seç', 'en': 'Select Zodiac', 'it': 'Seleziona Segno', 'fr': 'Choisir Signe',
    'ru': 'Выбрать знак', 'de': 'Sternzeichen w.', 'ar': 'اختر البرج', 'fa': 'انتخاب برج',
  });
  static String get selectGender => _tr({
    'tr': 'Cinsiyet Seç', 'en': 'Select Gender', 'it': 'Seleziona Genere', 'fr': 'Choisir Genre',
    'ru': 'Выбрать пол', 'de': 'Geschlecht w.', 'ar': 'اختر الجنس', 'fa': 'انتخاب جنسیت',
  });

  // Astrology Screens
  static String get notSpecified => _isEnglish ? 'Not Specified' : 'Belirtilmemiş';
  static String get natalChart => _isEnglish ? 'Natal Chart' : 'Kişisel Harita (Natal Chart)';
  static String get natalChartDesc => _isEnglish ? 'Planet positions at your birth moment and your astrological interpretation' : 'Doğum anınızdaki gezegen pozisyonları ve astrolojik yorumunuz';
  static String get birthDateLabel => _isEnglish ? 'Birth Date:' : 'Doğum Tarihi:';
  static String get createMyNatalChart => _isEnglish ? 'Create My Natal Chart' : 'Kişisel Haritamı Oluştur';
  static String get dailyHoroscopeReadings => _isEnglish ? 'Daily Horoscope Readings' : 'Günlük Burç Yorumları';
  static String get today => _isEnglish ? 'Today' : 'Bugün';
  static String get tomorrow => _isEnglish ? 'Tomorrow' : 'Yarın';
  static String get forAllZodiacSigns => _isEnglish ? 'for all zodiac signs' : 'tarihi için tüm burçlar';
  static String get dailyComment => _isEnglish ? 'Daily Comment' : 'Günlük yorum';
  static String get horoscopeLove => _isEnglish ? 'Love' : 'Aşk';
  static String get horoscopeCareer => _isEnglish ? 'Career' : 'Kariyer';
  static String get horoscopeHealth => _isEnglish ? 'Health' : 'Sağlık';
  static String get autoUserZodiac => _isEnglish ? 'Auto\nuser\'s\nzodiac' : 'Oto\nkişinin\nburcu';
  static String get detail => _isEnglish ? 'Detail' : 'Detay';
  static String get userInfoNotFound => _isEnglish ? 'User information not found.' : 'Kullanıcı bilgisi bulunamadı.';
  static String get addBirthDateForNatalChart => _isEnglish ? 'Add your birth date from your profile for a personal chart.' : 'Kişisel harita için doğum tarihinizi profilinizden ekleyin.';
  static String get creatingNatalChart => _isEnglish ? 'Creating your natal chart...' : 'Kişisel haritanız oluşturuluyor...';
  static String get natalChartCouldNotBeCreated => _isEnglish ? 'Natal chart could not be created:' : 'Kişisel harita oluşturulamadı:';
  static String get tomorrowInsight => _isEnglish ? 'Tomorrow\'s Insight' : 'Yarın için önsezi';
  static String get insightCouldNotBeGenerated => _isEnglish ? 'Insight could not be generated:' : 'Önsezi üretilemedi:';
  
  // Zodiac Date Ranges
  static String get zodiacDateAries => _isEnglish ? 'March 21 - April 20' : '21 Mart - 20 Nisan';
  static String get zodiacDateTaurus => _isEnglish ? 'April 21 - May 21' : '21 Nisan - 21 Mayıs';
  static String get zodiacDateGemini => _isEnglish ? 'May 22 - June 21' : '22 Mayıs - 21 Haziran';
  static String get zodiacDateCancer => _isEnglish ? 'June 22 - July 22' : '22 Haziran - 22 Temmuz';
  static String get zodiacDateLeo => _isEnglish ? 'July 23 - August 22' : '23 Temmuz - 22 Ağustos';
  static String get zodiacDateVirgo => _isEnglish ? 'August 23 - September 22' : '23 Ağustos - 22 Eylül';
  static String get zodiacDateLibra => _isEnglish ? 'September 23 - October 22' : '23 Eylül - 22 Ekim';
  static String get zodiacDateScorpio => _isEnglish ? 'October 23 - November 21' : '23 Ekim - 21 Kasım';
  static String get zodiacDateSagittarius => _isEnglish ? 'November 22 - December 21' : '22 Kasım - 21 Aralık';
  static String get zodiacDateCapricorn => _isEnglish ? 'December 22 - January 20' : '22 Aralık - 20 Ocak';
  static String get zodiacDateAquarius => _isEnglish ? 'January 21 - February 19' : '21 Ocak - 19 Şubat';
  static String get zodiacDatePisces => _isEnglish ? 'February 20 - March 20' : '20 Şubat - 20 Mart';

  // Biorhythm Screen
  static String get biorhythmTitle => _isEnglish ? 'Biorhythm' : 'Biyoritim';
  static String get selectBirthDateFirst => _isEnglish ? 'Please select your birth date first.' : 'Önce doğum tarihini seç.';
  static String get aiCommentCouldNotBeRetrieved => _isEnglish ? 'AI comment could not be retrieved:' : 'AI yorumu alınamadı:';
  static String get date => _isEnglish ? 'Date' : 'Tarih';
  static String get select => _isEnglish ? 'Select' : 'Seç';
  static String get dailyBalance => _isEnglish ? 'Daily Balance' : 'Günlük Denge';
  static String get physical => _isEnglish ? 'Physical' : 'Fiziksel';
  static String get emotional => _isEnglish ? 'Emotional' : 'Duygusal';
  static String get mental => _isEnglish ? 'Mental' : 'Zihinsel';
  static String get gettingComment => _isEnglish ? 'Getting Comment…' : 'Yorum Alınıyor…';
  static String get getAIComment => _isEnglish ? 'Get AI Comment' : 'AI Yorumunu Al';
  static String get minus6Days => _isEnglish ? '−6d' : '−6g';
  static String get plus6Days => _isEnglish ? '+6d' : '+6g';

  // Aura Analysis Screen
  static String get auraAnalysisTitle => _isEnglish ? 'Aura Analysis' : 'Aura Analizi';
  static String get addBirthDateToProfileFirst => _isEnglish ? 'Please add your birth date to your profile first.' : 'Önce doğum tarihinizi profilinize ekleyin.';
  static String get auraCouldNotBeUpdated => _isEnglish ? 'Aura could not be updated:' : 'Aura güncellenemedi:';
  static String get discoverYourSpiritualEnergy => _isEnglish ? 'Discover your spiritual energy' : 'Ruhsal enerjini keşfet';
  static String get auraDesc => _isEnglish ? 'Your mood, sleep duration, and emotions determine your aura color and frequency.' : 'Ruh halin, uyku süren ve duyguların aura rengini ve frekansını belirler.';
  static String get sleepDuration => _isEnglish ? 'Sleep Duration' : 'Uyku Süresi';
  static String get hours => _isEnglish ? 'hours' : 'saat';
  static String get todaysEmotion => _isEnglish ? 'Today\'s Emotion' : 'Günün Duygusu';
  static String get auraDescription => _isEnglish ? 'Aura Description' : 'Aura Açıklaması';
  static String get analyzing => _isEnglish ? 'Analyzing…' : 'Analiz ediliyor…';
  static String get updateAura => _isEnglish ? 'Update Aura' : 'Aura Güncelle';

  // Social visibility
  static String get socialVisibilityTitle =>
      _isEnglish ? 'Show my profile in Social section' : 'Sosyal bölümde profilimi göster';
  static String get socialVisibilityDesc => _isEnglish
      ? 'When turned off, other users cannot see you in discover, nearby or aura match lists. Existing chats are preserved.'
      : 'Kapalı olduğunda, kimse seni keşfet, yakındakiler veya aura eşleşmesi listelerinde göremez. Mevcut sohbetlerin korunur.';
  static String get socialVisibilityStatusHidden =>
      _isEnglish ? 'You are currently hidden in Social.' : 'Şu anda sosyal bölümde gizlisin.';
  static String get socialVisibilityStatusVisible =>
      _isEnglish ? 'You are currently visible in Social.' : 'Şu anda sosyal bölümde görünürsün.';
  // Mood and Emotion options
  static String get happy => _isEnglish ? 'Happy' : 'Mutlu';
  static String get tired => _isEnglish ? 'Tired' : 'Yorgun';
  static String get stressed => _isEnglish ? 'Stressed' : 'Stresli';
  static String get calm => _isEnglish ? 'Calm' : 'Sakin';
  static String get energetic => _isEnglish ? 'Energetic' : 'Enerjik';
  static String get anxious => _isEnglish ? 'Anxious' : 'Kaygılı';
  static String get relaxed => _isEnglish ? 'Relaxed' : 'Rahat';
  static String get sad => _isEnglish ? 'Sad' : 'Üzgün';
  static String get excited => _isEnglish ? 'Excited' : 'Heyecanlı';

  // Main Screen
  static String get showMyFortunes => _isEnglish ? 'Show My Fortunes' : 'Fallarımı Göster';
  static String get yourHoroscopesToday => _isEnglish ? 'Your Horoscopes Today' : 'Bugünün Burç Yorumları';
  
  // Aura Match Filter
  static String get findCompatiblePerson => _isEnglish ? 'Find Compatible Person' : 'Uyumlu Kişiyi Bul';
  static String get onlyCompatiblePeople => _isEnglish ? 'Only Compatible People' : 'Sadece Uyumlu Kişiler';
  static String get showAll => _isEnglish ? 'Show All' : 'Tümünü Göster';
  static String get noCompatiblePersonFound => _isEnglish ? 'No compatible person found' : 'Uyumlu kişi bulunamadı';
  
  // Terms of Service
  static String get termsOfServiceShort => _isEnglish
      ? 'Falla Aura – Terms of Service\n\nEffective Date: 2025\nLast Updated: 08.11.2025\n\nBy using Falla Aura, you agree to our terms of service. The app provides fortune readings, aura analysis, spiritual tests, and astrological content for entertainment and personal awareness purposes only.\n\nYour content is stored securely in cloud storage (Firebase Storage) and is only processed for service delivery. Data is encrypted via HTTPS and not shared with third parties.\n\nSome features are paid. Subscriptions are managed through App Store or Google Play. Falla Aura does not guarantee the accuracy of interpretations and the service is provided "as is".\n\nYou can delete your account at any time. Data will be permanently deleted within 30 days.'
      : 'FALLA AURA – KULLANIM KOŞULLARI\n\nYürürlük Tarihi: 2025\nSon Güncelleme: 08.11.2025\n\nFalla Aura\'yı kullanarak kullanım koşullarımızı kabul etmiş olursunuz. Uygulama, yalnızca eğlence ve kişisel farkındalık amacıyla fal yorumları, aura analizi, ruhsal testler ve astrolojik içerikler sunar.\n\nİçerikleriniz güvenli bir şekilde bulut depolamada (Firebase Storage) saklanır ve yalnızca hizmet sunumu amacıyla işlenir. Veriler HTTPS üzerinden şifrelenir ve üçüncü taraflarla paylaşılmaz.\n\nBazı özellikler ücretlidir. Abonelikler App Store veya Google Play üzerinden yönetilir. Falla Aura, yorumların doğruluğu konusunda garanti vermez ve hizmet "olduğu gibi" sunulmaktadır.\n\nHesabınızı istediğiniz zaman silebilirsiniz. Veriler 30 gün içinde kalıcı olarak silinir.';
  
  static String get termsOfServiceFull => _isEnglish
      ? '''FALLA AURA – TERMS OF USE

Effective Date: 2025
Last Updated: 2025-12-02

By downloading, installing or using the Falla Aura mobile application (the "App"), you acknowledge that you have read, understood and agree to be bound by these Terms of Use (the "Terms"). If you do not agree to these Terms, you must not use the App.

These Terms apply to all services provided by Falla Aura ("we", "us", "our").

1. Definitions

For the purposes of these Terms:

"App" means the Falla Aura mobile application and all related digital services and content.

"Service" means all features provided through the App, including fortune readings, tarot, aura analysis, biorhythm, tests, aura matching, chat, gamification, premium packages and similar functions.

"User" / "you" means any natural person who downloads, registers for, or otherwise uses the App.

"User Content" means any content uploaded, submitted or created in the App by the User (such as photos, text, messages, videos, audio, profile information, etc.).

"Social Features" means aura matching, user profiles, chat, notifications and other modules that enable interaction between users.

2. Nature of the Service – For Entertainment Purposes Only

The App provides:

Fortune-telling and readings (e.g. coffee cup readings, tarot, palm, dream interpretation, etc.),

Aura analysis and energy-based interpretations,

Astrological insights and daily horoscope content,

Biorhythm calculations,

Love, relationship, personality and mood tests,

An aura compatibility and similar criteria–based matching system,

Chat and communication between matched users,

Gamification and virtual point/credit systems.

All such content and interpretations are provided solely for entertainment and personal awareness purposes.

They do not constitute professional advice in the fields of health, psychology, therapy, law, finance, career or any similar area.

The App does not predict the future with certainty; all decisions you make based on the Service are entirely your own responsibility.

No information provided in the App constitutes a medical diagnosis, psychological counselling, legal opinion or financial investment advice.

3. Age Restriction and Access to the App

You must be at least 16 years old to use the App.

If local law sets a higher minimum age, that higher age requirement will apply.

If we determine that you are under 16 years of age, your account may be closed and your data may be deleted in accordance with applicable law.

You may not create an account on behalf of another person or use someone else's identity.

4. Account Creation and Security

Certain features of the App may require you to create an account. You are responsible for ensuring that the information you provide during registration is accurate, current and complete.

You are responsible for maintaining the confidentiality of your account information (such as e-mail, password, etc.). You are deemed responsible for all activities that occur under your account.

If you believe that your account has been used without your authorization, you must contact us immediately.

5. License and Right of Use

Subject to your compliance with these Terms, we grant you a personal, limited, non-exclusive and non-transferable license to use the App on your mobile devices.

The following actions are strictly prohibited:

Copying, modifying, reverse engineering or decompiling the App or attempting to derive its source code,

Selling, renting, sublicensing or otherwise commercializing any part of the App,

Attempting to circumvent or disable any security or technical protection measures,

Using bots, scripts or other automated tools in a way that overloads, abuses or disrupts the system.

6. User Content and Responsibility

You are solely and fully responsible for the legal consequences of all photos, text, messages and other content that you upload to or share through the App.

The following types of content are strictly prohibited when using the App:

Profanity, insults, threats, humiliation, hate speech, racist or discriminatory expressions,

Pornographic, obscene or sexually explicit content,

Content that encourages harm to others or self-harm,

Fraud, spam, advertising, promotion or mass messages for marketing purposes,

Any content that infringes copyrights, trademarks, privacy rights or personality rights,

Any promotion or advertisement of illegal products or services, or content that violates applicable laws.

If such content is detected, the relevant content may be removed, your account may be temporarily or permanently suspended without prior notice and, where deemed necessary, the matter may be reported to the competent authorities.

You must not share photos, personal data or private messages belonging to others without their consent.

7. Fortune, Aura and Test Results

Fortune, aura, dream, biorhythm and test results are:

Generated automatically or semi-automatically using artificial intelligence, algorithms and symbolic interpretation systems.

These results:

Are provided solely for entertainment and awareness,

Do not guarantee any real-world outcomes,

Do not assume responsibility for any decisions you make.

Any decisions, risks or consequences arising from your use of the App and its results are entirely your responsibility.

8. Aura Matching and Social Features

Aura matching is performed using a matching algorithm based on users' profile information (such as zodiac sign, age range, gender preference, aura color, mood, etc.).

Compatibility percentages are only indicative estimates of potential compatibility and are not guarantees.

The profile information that may be displayed to other users as a result of matching includes:

Nickname or username,

Age range, zodiac sign, aura color, mood (as defined by the App's logic),

Profile image (if provided),

General location information (country/city level, if you have chosen to share it).

Within chat and social areas:

You may not engage in harassment, threats, bullying, coercive flirting or sending persistent unwanted messages.

You may not make sexual, obscene requests or offers.

You may not request or share personal information that could endanger someone's safety (such as address, phone number, precise location, etc.).

Users are personally responsible for their own safety if they decide to meet other users in real life. Falla Aura is not liable for any damage, loss or dispute arising from communication or meetings between users.

Reporting and blocking:

You may report and/or block any user or message that you find inappropriate.

Reported accounts may be reviewed; where necessary, chat logs may be examined for moderation purposes.

9. Virtual Currency, Points and Premium Features

The App may include virtual point or currency systems such as "karma", "coins", "energy", etc.

These virtual items are for use only within the App; unless explicitly stated otherwise, they:

Cannot be sold for real money,

Cannot be refunded for real money,

Cannot be transferred or assigned to other users.

Premium features, subscriptions and packages are sold through the Apple App Store or Google Play Store.

Prices, durations and included content are specified within the App and/or on the store listing pages.

Purchases and subscription transactions are subject to the respective terms and policies of the relevant store (Apple/Google).

Refund requests are handled according to the refund procedures of the relevant platform; Falla Aura does not provide any additional refund commitment beyond those platform policies.

The renewal, modification and cancellation of subscriptions must be managed by the User via the App Store / Google Play subscription management screens.

10. Intellectual Property Rights

All software code, design, logos, trademarks, icons, graphics, text, audio and other content within the App are owned by Falla Aura or used under license.

You may not:

Copy, reproduce or facilitate the reproduction of such content,

Create derivative works based on it, sell or distribute it.

The "Falla Aura" name and logos may not be used without prior written permission.

11. Privacy and Personal Data Protection

Details on how your personal data is processed and protected are set out in our Privacy Policy.

By using the App, you agree to the data processing activities described in the Privacy Policy.

The Privacy Policy forms an integral part of these Terms.

12. Third-Party Services

Falla Aura may use third-party services such as Firebase, Google Cloud, OpenAI and others for storage, analytics, artificial intelligence, notifications, error reporting and similar purposes.

These services are subject to their own terms of use and privacy policies, and the relevant providers may process data on their own servers.

By continuing to use the App, you agree to the use of such third-party services.

13. Disclaimer of Warranties and Limitation of Liability

The App and the Service are provided "as is" and "as available".

No guarantee is given regarding fitness for a particular purpose, uninterrupted or error-free operation, or any particular result.

Falla Aura is not liable for:

The accuracy or reliability of any fortunes, readings, tests or matching results,

Communications, disputes or meetings between users,

Problems, data loss or damage caused by your device, operating system or internet connection,

Interruptions, failures or errors that may occur in third-party services.

Some jurisdictions do not allow certain limitations of liability; in such cases, the relevant limitation will apply to the maximum extent permitted by applicable law.

14. Termination and Account Closure

You may delete your account and stop using the Service at any time via the settings/account menu within the App.

Falla Aura may temporarily or permanently suspend or terminate your account in the following cases:

Violation of these Terms or the Privacy Policy,

Behavior that endangers the safety of other users,

Fraud, spam, abuse or attacks on the system,

Any other reasonable grounds we deem appropriate.

Upon termination of your account:

Your access to the App may be stopped,

Your User Content may be deleted or anonymised in accordance with the Privacy Policy.

15. Governing Law and Dispute Resolution

Unless otherwise required by mandatory law, these Terms are governed by the laws of the Republic of Türkiye.

In disputes arising from the use of the App, the courts and enforcement offices at the User's place of residence shall have jurisdiction.

Apple Inc. and Google LLC are not parties to the content of the App or the legal relationship and disputes between the User and Falla Aura. The store providers act only as distribution platforms.

16. Changes to the Terms

Falla Aura may update these Terms from time to time.

Changes will take effect on the date they are published within the App or notified to you.

Your continued use of the App after such date constitutes your acceptance of the updated Terms.

17. Contact

For any questions, comments or requests regarding these Terms or the App, you can contact us at:

E-mail: falla@loegs.com

Web: https://www.loegs.com/falla'''
      : '''FALLA AURA – KULLANIM KOŞULLARI

Yürürlük Tarihi: 2025
Son Güncelleme: 2025-12-02

Falla Aura mobil uygulamasını ("Uygulama") indirerek, yükleyerek veya kullanarak, aşağıda yer alan Kullanım Koşulları'nı ("Koşullar") okuduğunuzu, anladığınızı ve bunlara bağlı kalmayı kabul ettiğinizi beyan etmiş olursunuz. Koşulları kabul etmiyorsanız Uygulama'yı kullanmamalısınız.

Bu Koşullar, Falla Aura tarafından sunulan tüm hizmetler için geçerlidir. ("Biz", "Bize", "Bizim")

1. Tanımlar

Bu Koşullar'da:

"Uygulama": Falla Aura mobil uygulaması ve ona bağlı tüm dijital hizmet ve içerikleri,

"Hizmet": Uygulama üzerinden sunulan fal, tarot, aura analizi, biyoritim, testler, aura eşleşmesi, sohbet, oyunlaştırma, premium paketler ve benzeri tüm fonksiyonları,

"Kullanıcı" / "Siz": Uygulama'yı indiren, kayıt olan veya herhangi bir şekilde kullanan gerçek kişiyi,

"Kullanıcı İçeriği": Kullanıcı tarafından Uygulama'ya yüklenen, gönderilen veya oluşturulan her türlü içerik (fotoğraf, metin, mesaj, video, ses, profil bilgisi vb.),

"Sosyal Özellikler": Aura eşleşmesi, kullanıcı profilleri, sohbet (chat), bildirimler ve benzeri kullanıcılar arası etkileşim modüllerini,
ifade eder.

2. Hizmetin Niteliği – Yalnızca Eğlence Amaçlıdır

Uygulama;

Fal yorumları (kahve, tarot, el, rüya vb.),

Aura analizi ve enerji yorumları,

Astrolojik yorumlar ve günlük burçlar,

Biyoritim hesaplamaları,

Aşk, ilişki, kişilik ve ruh hali testleri,

Aura uyumu ve benzeri kriterlere dayalı eşleşme sistemi,

Eşleşen kullanıcılar arasında sohbet imkânı,

Oyunlaştırma & sanal puan/kredi sistemleri
sağlar.

Tüm bu içerikler ve yorumlar yalnızca eğlence ve kişisel farkındalık amaçlıdır.

Sağlık, psikoloji, terapi, hukuk, finans, kariyer veya benzeri konularda profesyonel tavsiye yerine geçmez.

Uygulama, geleceği kesin olarak öngörmez; alınan kararlar tamamen Kullanıcı'nın kendi sorumluluğundadır.

Uygulama'da sunulan hiçbir bilgi, tıbbi teşhis, psikolojik danışmanlık, hukuki görüş veya finansal yatırım tavsiyesi değildir.

3. Yaş Sınırı ve Uygulamaya Erişim

Uygulama'yı kullanmak için en az 16 yaşında olmalısınız.

Yerel mevzuat daha yüksek bir yaş sınırı öngörüyorsa, bu üst sınır geçerlidir.

16 yaşından küçük olduğunuz tespit edilirse, hesabınız kapatılabilir ve verileriniz yürürlükteki mevzuata uygun şekilde silinebilir.

Kendi adınıza değil, başkası adına hesap açamazsınız.

4. Hesap Oluşturma ve Güvenlik

Uygulama'daki bazı özellikleri kullanmak için hesap oluşturmanız gerekebilir. Kayıt sırasında verdiğiniz bilgilerin doğru, güncel ve eksiksiz olmasından siz sorumlusunuz.

Hesap bilgilerinizin (e-posta, şifre vb.) gizliliğini korumakla yükümlüsünüz. Hesabınız üzerinden gerçekleşen tüm aktivitelerden siz sorumlu kabul edilirsiniz.

Hesabınızın yetkisiz kullanıldığını düşünüyorsanız derhal bizimle iletişime geçmelisiniz.

5. Lisans ve Kullanım Hakkı

Size, Koşullar'a uygun davrandığınız sürece, Uygulama'yı mobil cihazlarınızda kullanmanız için kişisel, sınırlı, münhasır olmayan ve devredilemez bir lisans verilir.

Aşağıdaki işlemler kesinlikle yasaktır:

Uygulama'yı kopyalamak, değiştirmek, tersine mühendislik yapmak, kaynak koda dönüştürmek,

Uygulama'nın herhangi bir kısmını satmak, kiralamak, lisanslamak,

Güvenlik önlemlerini aşmaya çalışmak,

Sistem yükünü bozacak şekilde bot, script, otomatik araç kullanmak.

6. Kullanıcı İçeriği ve Sorumluluk

Uygulama'ya yüklediğiniz fotoğraf, metin, mesaj ve benzeri tüm içeriklerin hukuki sorumluluğu tamamen size aittir.

Uygulama'yı kullanırken aşağıdaki içerikler kesinlikle yasaktır:

Küfür, hakaret, tehdit, aşağılama, nefret söylemi, ırkçı veya ayrımcı ifadeler,

Pornografik, müstehcen veya cinsel içerikli paylaşımlar,

Başkasına veya kendine zarar vermeyi teşvik eden içerikler,

Dolandırıcılık, spam, reklam, promosyon veya tanıtım amaçlı toplu mesajlar,

Telif hakkı, marka, mahremiyet veya kişilik haklarını ihlal eden her türlü içerik,

Kanunlara aykırı, yasa dışı ürün/hizmet tanıtımları.

Bu tür içeriklerin tespiti hâlinde, ilgili içerik silinebilir, hesabınız uyarılmaksızın geçici veya kalıcı olarak kapatılabilir ve gerekli görülürse yetkili makamlara bildirim yapılabilir.

Başkalarına ait fotoğraf, kişisel veri veya özel mesajları izinleri olmadan paylaşmamalısınız.

7. Fortune (Fal), Aura ve Test Sonuçları

Fal, aura, rüya, biyoritim ve test sonuçları;

Yapay zekâ, algoritmalar ve sembolik yorumlama sistemleri kullanılarak otomatik veya yarı otomatik şekilde oluşturulur.

Bu sonuçlar;

Sadece eğlence / farkındalık içindir,

Gerçek dünyadaki olayları garanti etmez,

Alacağınız kararların sorumluluğunu üstlenmez.

Uygulama'dan elde edilen sonuçlar doğrultusunda aldığınız kararlar, riskler ve sonuçlar tamamen sizin sorumluluğunuzdadır.

8. Aura Eşleşmesi ve Sosyal Özellikler

Aura eşleşmesi, kullanıcıların profil bilgileri (burç, yaş aralığı, cinsiyet tercihi, aura rengi, ruh hali vb.) üzerinden bir eşleşme algoritması ile yapılır.

Eşleşme yüzdeleri sadece tahmini uyum göstergesidir, garanti değildir.

Eşleşme sonucunda görünen profil bilgileri:

Takma ad veya kullanıcı adı,

Yaş aralığı, burç, aura rengi, ruh hali (uygulama mantığına göre),

Profil görüntüsü (varsa),

Genel lokasyon bilgisi (ülke/şehir düzeyinde, eğer paylaşmayı seçtiyseniz).

Sohbet ve sosyal alanlarda:

Taciz, tehdit, zorbalık, flört baskısı, ısrarlı mesaj gibi davranışlarda bulunamazsınız.

Cinsel içerik, müstehcen talep veya tekliflerde bulunamazsınız.

Başkasının güvenliğini tehlikeye sokacak kişisel bilgileri (adres, telefon, özel konum vb.) talep edemez veya paylaşamazsınız.

Kullanıcılar, diğer kullanıcılarla gerçek hayatta görüşme kararı alırken kendi güvenliklerinden bizzat sorumludur. Falla Aura, kullanıcılar arasındaki iletişim ve olası buluşmalardan doğabilecek hiçbir zarar veya uyuşmazlıktan sorumlu tutulamaz.

Şikâyet ve engelleme:

Uygun görmediğiniz bir kullanıcıyı veya mesajı rapor edebilir ve/veya engelleyebilirsiniz.

Raporlanan hesaplar incelenebilir; gerektiğinde sohbet kayıtları moderasyon amacıyla görüntülenebilir.

9. Sanal Para, Puan ve Premium Özellikler

Uygulama'da "karma", "coin", "enerji" vb. sanal puan/para sistemleri bulunabilir.

Bu sanal varlıklar, yalnızca Uygulama içinde kullanım içindir; gerçek para karşılığı geri satılamaz, iade edilemez, başka kullanıcılara devredilemez (aksi açıkça belirtilmedikçe).

Premium özellikler, abonelikler ve paketler; Apple App Store veya Google Play üzerinden satılır.

Fiyatlar, süreler ve içerikler Uygulama içinde ve mağaza sayfasında belirtilir.

Satın alma ve abonelik işlemleri ilgili mağazanın (Apple/Google) kendi şart ve politikalarına tabidir.

İade talepleri için ilgili platformun iade süreçleri geçerlidir; Falla Aura bu politikaların dışında ayrıca bir iade taahhüdü vermez.

Aboneliklerin yenilenmesi, değiştirilmesi ve iptali;

Kullanıcı tarafından App Store / Google Play abonelik yönetim ekranları üzerinden yapılmalıdır.

10. Fikri Mülkiyet Hakları

Uygulama'da yer alan tüm yazılım kodu, tasarım, logo, marka, ikon, grafik, metin, ses ve diğer içerikler Falla Aura'ya aittir veya lisanslı olarak kullanılmaktadır.

Bu içerikleri;

Kopyalayamaz, çoğaltamaz, çoğaltılmasına aracılık edemez,

Türev çalışma oluşturamaz, satamaz veya dağıtamazsınız.

"Falla Aura" markası ve logoları, önceden yazılı izin alınmadan kullanılamaz.

11. Gizlilik ve Kişisel Veri Koruması

Kişisel verilerinizin işlenmesi ve korunmasına ilişkin detaylar "Gizlilik Politikası" dokümanında açıklanmıştır.

Uygulama'yı kullanarak, Gizlilik Politikası'nda açıklanan veri işleme faaliyetlerini kabul etmiş olursunuz.

Gizlilik Politikası bu Koşullar'ın ayrılmaz bir parçasıdır.

12. Üçüncü Taraf Servisler

Falla Aura; depolama, analitik, yapay zekâ, bildirim, hata raporlama vb. amaçlarla üçüncü taraf servisler (Firebase, Google Cloud, OpenAI vb.) kullanabilir.

Bu servisler kendi kullanım ve gizlilik şartlarına tabidir; ilgili sağlayıcılar, verileri kendi veri merkezlerinde işleyebilir.

Kullanıcı, Uygulama'yı kullanmaya devam ederek bu üçüncü taraf servislerin kullanımını kabul eder.

13. Sorumluluk Reddi

Uygulama ve Hizmet "olduğu gibi" ve "mevcut hâliyle" sunulmaktadır;

Belirli bir amaca uygunluk, kesintisizlik, hatasızlık veya sonuç garantisi verilmez.

Falla Aura;

Fal, yorum, test ve eşleşme sonuçlarının doğruluğu veya güvenilirliği,

Kullanıcılar arasında gerçekleşen iletişimler, tartışmalar, buluşmalar,

Cihazınız veya internet bağlantınız kaynaklı sorunlar, veri kayıpları,

Üçüncü taraf servislerde meydana gelebilecek kesinti veya hatalardan
doğan zararlardan sorumlu tutulamaz.

Bazı yargı alanlarında belirli sorumluluk sınırlamalarına izin verilmeyebilir; bu durumda ilgili sınırlama, yürürlükteki hukuk kapsamında azami ölçüde uygulanır.

14. Sözleşmenin Feshi ve Hesabın Kapatılması

Siz, dilediğiniz zaman Uygulama içindeki ayarlar/hesap menüsünden hesabınızı silebilir ve Hizmet'i kullanmayı bırakabilirsiniz.

Falla Aura, aşağıdaki hâllerde hesabınızı geçici veya kalıcı olarak askıya alabilir veya sona erdirebilir:

Bu Koşullar'ın veya Gizlilik Politikası'nın ihlali,

Diğer kullanıcıların güvenliğini tehlikeye atan davranışlar,

Dolandırıcılık, spam, kötüye kullanım, sistem saldırısı,

Uygun bulmadığımız başka makul gerekçeler.

Hesabın sonlandırılması hâlinde;

Uygulama'ya erişiminiz durdurulabilir,

Kullanıcı İçeriği'niz, Gizlilik Politikası'na uygun şekilde silinebilir veya anonimleştirilebilir.

15. Uygulanacak Hukuk ve Uyuşmazlıklar

İşbu Koşullar, aksi belirtilmedikçe Türkiye Cumhuriyeti hukukuna tabidir.

Uygulama kullanımından doğan uyuşmazlıklarda, Kullanıcı'nın yerleşim yerindeki mahkemeler ve icra daireleri yetkilidir.

Apple Inc. ve Google LLC; Uygulama'nın içeriği, Kullanıcı ile Falla Aura arasındaki hukuki ilişkiler ve uyuşmazlıkların tarafı değildir. Mağaza sağlayıcıları, sadece dağıtım platformudur.

16. Koşullarda Değişiklik

Falla Aura, bu Koşullar'ı zaman zaman güncelleyebilir.

Değişiklikler Uygulama içinde yayınlandığı veya size bildirildiği tarihte yürürlüğe girer.

Uygulama'yı kullanmaya devam etmeniz, güncellenen Koşullar'ı kabul ettiğiniz anlamına gelir.

17. İletişim

Bu Koşullar veya Uygulama ile ilgili her türlü soru, görüş ve talebiniz için:

E-posta: falla@loegs.com

Web: https://www.loegs.com/falla''';
  
  // Tarot card names helper - returns localized name for card ID
  static String getTarotCardName(String cardId) {
    const cardNames = {
      // Major Arcana
      'the_fool': {'tr': 'Deli', 'en': 'The Fool'},
      'magician': {'tr': 'Büyücü', 'en': 'The Magician'},
      'high_priestess': {'tr': 'Başrahibe', 'en': 'The High Priestess'},
      'empress': {'tr': 'İmparatoriçe', 'en': 'The Empress'},
      'emperor': {'tr': 'İmparator', 'en': 'The Emperor'},
      'hierophant': {'tr': 'Aziz', 'en': 'The Hierophant'},
      'lovers': {'tr': 'Aşıklar', 'en': 'The Lovers'},
      'chariot': {'tr': 'Savaş Arabası', 'en': 'The Chariot'},
      'strength': {'tr': 'Güç', 'en': 'Strength'},
      'hermit': {'tr': 'Ermiş', 'en': 'The Hermit'},
      'wheel_of_fortune': {'tr': 'Kader Çarkı', 'en': 'Wheel of Fortune'},
      'justice': {'tr': 'Adalet', 'en': 'Justice'},
      'the_hanged_man': {'tr': 'Asılan Adam', 'en': 'The Hanged Man'},
      'death': {'tr': 'Ölüm', 'en': 'Death'},
      'temperance': {'tr': 'Denge', 'en': 'Temperance'},
      'devil': {'tr': 'Şeytan', 'en': 'The Devil'},
      'the_tower': {'tr': 'Kule', 'en': 'The Tower'},
      'the_moon': {'tr': 'Ay', 'en': 'The Moon'},
      'the_sun': {'tr': 'Güneş', 'en': 'The Sun'},
      'judgement': {'tr': 'Mahkeme', 'en': 'Judgement'},
      'the_world': {'tr': 'Dünya', 'en': 'The World'},
      // Pages
      'page_of_swords': {'tr': 'Vale Kılıç', 'en': 'Page of Swords'},
      'page_of_cups': {'tr': 'Vale Kupalar', 'en': 'Page of Cups'},
      'page_of_wands': {'tr': 'Vale Değnek', 'en': 'Page of Wands'},
      'page_of_pentacles': {'tr': 'Vale Tılsım', 'en': 'Page of Pentacles'},
      // Knights
      'knight_of_swords': {'tr': 'Şövalye Kılıç', 'en': 'Knight of Swords'},
      'knight_of_wands': {'tr': 'Şövalye Değnek', 'en': 'Knight of Wands'},
      'knight_of_pentacles': {'tr': 'Şövalye Tılsım', 'en': 'Knight of Pentacles'},
      'knight_of_cups': {'tr': 'Şövalye Kupalar', 'en': 'Knight of Cups'},
      // Queens
      'queen_of_pentacles': {'tr': 'Kraliçe Tılsım', 'en': 'Queen of Pentacles'},
      'queen_of_cups': {'tr': 'Kraliçe Kupalar', 'en': 'Queen of Cups'},
      'queen_of_swords': {'tr': 'Kraliçe Kılıç', 'en': 'Queen of Swords'},
      'queen_of_wands': {'tr': 'Kraliçe Değnek', 'en': 'Queen of Wands'},
      // Kings
      'king_of_pentacles': {'tr': 'Kral Tılsım', 'en': 'King of Pentacles'},
      'king_of_cups': {'tr': 'Kral Kupalar', 'en': 'King of Cups'},
      'king_of_swords': {'tr': 'Kral Kılıç', 'en': 'King of Swords'},
      'king_of_wands': {'tr': 'Kral Değnek', 'en': 'King of Wands'},
    };
    final names = cardNames[cardId];
    if (names == null) return cardId;
    return _isEnglish ? names['en']! : names['tr']!;
  }
  
  // Zodiac sign name helper - returns localized zodiac name
  static String getZodiacName(String zodiacTr) {
    const zodiacMap = {
      'Koç': {'tr': 'Koç', 'en': 'Aries'},
      'Boğa': {'tr': 'Boğa', 'en': 'Taurus'},
      'İkizler': {'tr': 'İkizler', 'en': 'Gemini'},
      'Yengeç': {'tr': 'Yengeç', 'en': 'Cancer'},
      'Aslan': {'tr': 'Aslan', 'en': 'Leo'},
      'Başak': {'tr': 'Başak', 'en': 'Virgo'},
      'Terazi': {'tr': 'Terazi', 'en': 'Libra'},
      'Akrep': {'tr': 'Akrep', 'en': 'Scorpio'},
      'Yay': {'tr': 'Yay', 'en': 'Sagittarius'},
      'Oğlak': {'tr': 'Oğlak', 'en': 'Capricorn'},
      'Kova': {'tr': 'Kova', 'en': 'Aquarius'},
      'Balık': {'tr': 'Balık', 'en': 'Pisces'},
    };
    final names = zodiacMap[zodiacTr];
    if (names == null) return zodiacTr;
    return _isEnglish ? names['en']! : names['tr']!;
  }
  
  // Normalize zodiac sign - converts any zodiac name to current language version
  static String? normalizeZodiacSign(String? zodiacSign) {
    if (zodiacSign == null) return null;
    
    // Create reverse map: English -> Turkish
    const reverseMap = {
      'Aries': 'Koç',
      'Taurus': 'Boğa',
      'Gemini': 'İkizler',
      'Cancer': 'Yengeç',
      'Leo': 'Aslan',
      'Virgo': 'Başak',
      'Libra': 'Terazi',
      'Scorpio': 'Akrep',
      'Sagittarius': 'Yay',
      'Capricorn': 'Oğlak',
      'Aquarius': 'Kova',
      'Pisces': 'Balık',
    };
    
    // If it's English, convert to Turkish first
    final turkishZodiac = reverseMap[zodiacSign] ?? zodiacSign;
    
    // Then convert to current language
    return getZodiacName(turkishZodiac);
  }
  
  // Convert zodiac sign to Turkish for database storage
  static String? zodiacSignToTurkish(String? zodiacSign) {
    if (zodiacSign == null) return null;
    
    // Create reverse map: English -> Turkish
    const reverseMap = {
      'Aries': 'Koç',
      'Taurus': 'Boğa',
      'Gemini': 'İkizler',
      'Cancer': 'Yengeç',
      'Leo': 'Aslan',
      'Virgo': 'Başak',
      'Libra': 'Terazi',
      'Scorpio': 'Akrep',
      'Sagittarius': 'Yay',
      'Capricorn': 'Oğlak',
      'Aquarius': 'Kova',
      'Pisces': 'Balık',
    };
    
    // If it's English, convert to Turkish
    if (reverseMap.containsKey(zodiacSign)) {
      return reverseMap[zodiacSign];
    }
    
    // If it's already Turkish, return as is
    const turkishSigns = ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 
                          'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık'];
    if (turkishSigns.contains(zodiacSign)) {
      return zodiacSign;
    }
    
    // If unknown, return as is
    return zodiacSign;
  }
  
  // Test form field labels
  static String get yourName => _isEnglish ? 'Your name' : 'Senin adın';
  static String get yourBirthDate => _isEnglish ? 'Your birth date' : 'Senin doğum tarihin';
  static String get friendName => _isEnglish ? 'Friend\'s name' : 'Arkadaşının adı';
  static String get friendBirthDate => _isEnglish ? 'Friend\'s birth date' : 'Arkadaşının doğum tarihi';
  static String get partnerName => _isEnglish ? 'Partner\'s name' : 'Partnerinin adı';
  static String get partnerBirthDate => _isEnglish ? 'Partner\'s birth date' : 'Partnerinin doğum tarihi';
  static String get enterFriendName => _isEnglish ? 'Enter your friend\'s name' : 'Arkadaşınızın adını girin';
  static String get selectFriendBirthDate => _isEnglish ? 'Select your friend\'s birth date' : 'Arkadaşınızın doğum tarihini seçin';
  static String get howIsYourMood => _isEnglish ? 'How is your mood?' : 'Ruh halin nasıl?';
  static String get dayMood => _isEnglish ? 'Day\'s mood' : 'Günün ruh hali';
  
  // Friendship Test
  static String get friendshipQ1 => _isEnglish ? 'What do you think a true friendship is based on?' : 'Gerçek bir dostluk sence neye dayanır?';
  static String get friendshipQ1A1 => _isEnglish ? 'Trust' : 'Güvene';
  static String get friendshipQ1A2 => _isEnglish ? 'Laughter' : 'Kahkahaya';
  static String get friendshipQ1A3 => _isEnglish ? 'Being there in difficult times' : 'Zorlukta yanında olmaya';
  static String get friendshipQ1A4 => _isEnglish ? 'Constant communication' : 'Sürekli iletişime';
  static String get friendshipQ2 => _isEnglish ? 'What do you enjoy doing together the most?' : 'Birlikte ne yapmaktan en çok keyif alırsınız?';
  static String get friendshipQ2A1 => _isEnglish ? 'Sharing troubles' : 'Dertleşmek';
  static String get friendshipQ2A2 => _isEnglish ? 'Laughing, being silly' : 'Gülmek, saçmalamak';
  static String get friendshipQ2A3 => _isEnglish ? 'Exploring new places' : 'Yeni yerler keşfetmek';
  static String get friendshipQ2A4 => _isEnglish ? 'Just hanging out quietly is enough' : 'Sessizce takılmak bile yetiyor';
  static String get friendshipQ3 => _isEnglish ? 'How do you feel when sharing secrets?' : 'Sırlarını paylaşırken nasıl hissediyorsun?';
  static String get friendshipQ3A1 => _isEnglish ? 'I fully trust' : 'Tam güveniyorum';
  static String get friendshipQ3A2 => _isEnglish ? 'I tell most but not everything' : 'Çoğunu anlatırım ama her şeyi değil';
  static String get friendshipQ3A3 => _isEnglish ? 'I\'m cautious' : 'Temkinliyim';
  static String get friendshipQ3A4 => _isEnglish ? 'It depends on the topic' : 'Konuya göre değişir';
  static String get friendshipQ4 => _isEnglish ? 'When it comes to keeping secrets, your friend...' : 'Bir sır saklama konusunda arkadaşın…';
  static String get friendshipQ4A1 => _isEnglish ? 'Never tells anyone' : 'Asla kimseye söylemez';
  static String get friendshipQ4A2 => _isEnglish ? 'Might slip sometimes' : 'Bazen ağzından kaçırabilir';
  static String get friendshipQ4A3 => _isEnglish ? 'Can\'t resist gossip' : 'Dedikoduya dayanamaz';
  static String get friendshipQ4A4 => _isEnglish ? 'Keeps it if it\'s important to them' : 'Ona göre önemliyse tutar';
  static String get friendshipQ5 => _isEnglish ? 'What movie genre would describe you?' : 'Sizi anlatan film türü ne olurdu?';
  static String get friendshipQ5A1 => _isEnglish ? 'Comedy' : 'Komedi';
  static String get friendshipQ5A2 => _isEnglish ? 'Drama' : 'Dram';
  static String get friendshipQ5A3 => _isEnglish ? 'Fantasy' : 'Fantastik';
  static String get friendshipQ5A4 => _isEnglish ? 'Romantic-comedy (something mixed)' : 'Romantik-komedi (karışık bir şey)';
  
  // Love Test
  static String get loveQ1 => _isEnglish ? 'What does love mean to you?' : 'Aşk senin için ne ifade ediyor?';
  static String get loveQ1A1 => _isEnglish ? 'Building a real connection' : 'Gerçek bir bağ kurmak';
  static String get loveQ1A2 => _isEnglish ? 'Passion and excitement' : 'Tutku ve heyecan';
  static String get loveQ1A3 => _isEnglish ? 'Trust that develops over time' : 'Zamanla gelişen bir güven';
  static String get loveQ1A4 => _isEnglish ? 'Fun, I don\'t take it too seriously' : 'Eğlence, fazla ciddiye almam';
  static String get loveQ2 => _isEnglish ? 'What do you value most in a relationship?' : 'Bir ilişkide en çok neye değer verirsin?';
  static String get loveQ2A1 => _isEnglish ? 'Loyalty' : 'Sadakat';
  static String get loveQ2A2 => _isEnglish ? 'Excitement and surprises' : 'Heyecan ve sürprizler';
  static String get loveQ2A3 => _isEnglish ? 'Understanding and communication' : 'Anlayış ve iletişim';
  static String get loveQ2A4 => _isEnglish ? 'Freedom' : 'Özgürlük';
  static String get loveQ3 => _isEnglish ? 'When you argue with your partner, usually...' : 'Partnerinle tartıştığında genelde...';
  static String get loveQ3A1 => _isEnglish ? 'I go silent, withdraw into my shell' : 'Sessizleşir, kendi kabuğuma çekilirim';
  static String get loveQ3A2 => _isEnglish ? 'I want to talk and solve it immediately' : 'Hemen konuşup çözmek isterim';
  static String get loveQ3A3 => _isEnglish ? 'I get a bit cold but then recover' : 'Biraz soğurum ama sonra toparlarım';
  static String get loveQ3A4 => _isEnglish ? 'I don\'t push, I let it flow' : 'Üzerine gitmem, akışa bırakırım';
  static String get loveQ4 => _isEnglish ? 'How do you look at the past in your love life?' : 'Aşk hayatında geçmişe nasıl bakarsın?';
  static String get loveQ4A1 => _isEnglish ? 'Everything is a lesson' : 'Her şey bir ders';
  static String get loveQ4A2 => _isEnglish ? 'I wish I could change some things' : 'Keşke bazı şeyleri değiştirebilsem';
  static String get loveQ4A3 => _isEnglish ? 'I don\'t care anymore' : 'Artık önemsemem';
  static String get loveQ4A4 => _isEnglish ? 'Some memories are still inside me' : 'Bazı anılar hâlâ içimde';
  static String get loveQ5 => _isEnglish ? 'Jealousy in a relationship for you is...' : 'İlişkide kıskançlık senin için…';
  static String get loveQ5A1 => _isEnglish ? 'A natural feeling, but should be under control' : 'Doğal bir his, ama kontrol altında olmalı';
  static String get loveQ5A2 => _isEnglish ? 'A sign of love' : 'Aşkın göstergesi';
  static String get loveQ5A3 => _isEnglish ? 'Unnecessary drama' : 'Gereksiz bir dram';
  static String get loveQ5A4 => _isEnglish ? 'I don\'t really have it' : 'Bende pek olmaz';
  static String get loveQ6 => _isEnglish ? 'What attracts you most in a partner?' : 'Bir partnerinde seni en çok çeken şey?';
  static String get loveQ6A1 => _isEnglish ? 'Their eyes' : 'Gözleri';
  static String get loveQ6A2 => _isEnglish ? 'Their sense of humor' : 'Mizah anlayışı';
  static String get loveQ6A3 => _isEnglish ? 'Their intelligence' : 'Zekâsı';
  static String get loveQ6A4 => _isEnglish ? 'Their stance / energy' : 'Duruşu / enerjisi';
  
  // Compatibility Test
  static String get compatibilityQ1 => _isEnglish ? 'In an argument, who takes the first step back?' : 'Bir tartışmada ilk kim geri adım atar?';
  static String get compatibilityQ1A1 => _isEnglish ? 'Me, peace is important' : 'Ben, huzur önemli';
  static String get compatibilityQ1A2 => _isEnglish ? 'They usually win me over' : 'O, genelde gönlümü alır';
  static String get compatibilityQ1A3 => _isEnglish ? 'We both are stubborn' : 'İkimiz de inat ederiz';
  static String get compatibilityQ1A4 => _isEnglish ? 'Time solves it' : 'Zaman çözer';
  static String get compatibilityQ2 => _isEnglish ? 'How does your partner\'s energy usually affect you?' : 'Partnerinin enerjisi seni genelde nasıl etkiliyor?';
  static String get compatibilityQ2A1 => _isEnglish ? 'It relaxes me' : 'Rahatlatıyor';
  static String get compatibilityQ2A2 => _isEnglish ? 'It raises me too much' : 'Aşırı yükseltiyor';
  static String get compatibilityQ2A3 => _isEnglish ? 'It confuses me' : 'Karıştırıyor';
  static String get compatibilityQ2A4 => _isEnglish ? 'It balances me' : 'Dengeye sokuyor';
  
  // Red Flags Test
  static String get loveRedFlagsSubtitle => _isEnglish ? 'Measure your relationship awareness' : 'İlişki farkındalığını ölç';
  static String get redFlagsQ1 => _isEnglish ? 'When you\'re newly interested in someone, usually...' : 'Birine yeni ilgi duyduğunda genelde…';
  static String get redFlagsQ1A1 => _isEnglish ? 'I go blind, I see everything as beautiful' : 'Gözüm kör olur, her şeyi güzel görürüm';
  static String get redFlagsQ1A2 => _isEnglish ? 'I approach carefully but get affected quickly' : 'Dikkatli yaklaşırım ama çabuk etkilenirim';
  static String get redFlagsQ1A3 => _isEnglish ? 'I immediately analyze the other person' : 'Karşı tarafı hemen analiz ederim';
  static String get redFlagsQ1A4 => _isEnglish ? 'I look at their energy as well as my feelings' : 'Hislerim kadar enerjisine de bakarım';
  static String get redFlagsQ2 => _isEnglish ? 'What do you do if someone pushes your boundaries?' : 'Biri sınırlarını zorlarsa ne yaparsın?';
  static String get redFlagsQ2A1 => _isEnglish ? 'I cover it up, don\'t want problems' : 'Üstünü kapatırım, sorun çıkmasın';
  static String get redFlagsQ2A2 => _isEnglish ? 'I warn them once' : 'Bir kez uyarırım';
  static String get redFlagsQ2A3 => _isEnglish ? 'I get cold and withdraw' : 'Soğurum ve geri çekilirim';
  static String get redFlagsQ2A4 => _isEnglish ? 'I say it clearly and set my distance' : 'Açıkça söylerim ve mesafemi koyarım';
  static String get redFlagsQ3 => _isEnglish ? 'If you feel someone is emotionally manipulating you...' : 'Birinin seni duygusal olarak manipüle ettiğini hissedersen…';
  static String get redFlagsQ3A1 => _isEnglish ? 'I ignore it' : 'Göz ardı ederim';
  static String get redFlagsQ3A2 => _isEnglish ? 'I hesitate' : 'Kararsız kalırım';
  static String get redFlagsQ3A3 => _isEnglish ? 'I notice but don\'t leave immediately' : 'Fark ederim ama hemen gitmem';
  static String get redFlagsQ3A4 => _isEnglish ? 'I distance myself immediately' : 'Hemen uzaklaşırım';
  static String get redFlagsQ4 => _isEnglish ? 'What guides you most in love?' : 'Aşkta hangisi seni daha çok yönlendirir?';
  static String get redFlagsQ4A1 => _isEnglish ? 'My heart, I don\'t think' : 'Kalbim, düşünmem';
  static String get redFlagsQ4A2 => _isEnglish ? 'My heart but I keep my eyes open' : 'Kalbim ama gözüm açık olur';
  static String get redFlagsQ4A3 => _isEnglish ? 'My logic, I analyze first' : 'Mantığım, önce analiz ederim';
  static String get redFlagsQ4A4 => _isEnglish ? 'Heart and intuition work together' : 'Kalp ve sezgi birlikte çalışır';
  static String get redFlagsQ5 => _isEnglish ? 'How do you interpret it when your partner is jealous?' : 'Partnerin seni kıskandığında bunu nasıl yorumlarsın?';
  static String get redFlagsQ5A1 => _isEnglish ? 'It\'s nice, they value me' : 'Güzel bir şey, değer veriyor';
  static String get redFlagsQ5A2 => _isEnglish ? 'Normal but shouldn\'t overdo it' : 'Normal ama abartmasın';
  static String get redFlagsQ5A3 => _isEnglish ? 'It bothers me' : 'Rahatsız olurum';
  static String get redFlagsQ5A4 => _isEnglish ? 'I can\'t tolerate controlling behaviors at all' : 'Kontrolcü davranışlara asla tahammül edemem';
  static String get redFlagsQ6 => _isEnglish ? 'If your partner constantly monitors you...' : 'Partnerin sürekli seni denetliyorsa…';
  static String get redFlagsQ6A1 => _isEnglish ? 'I think "They do it out of love."' : '"Aşktan yapıyor." diye düşünürüm';
  static String get redFlagsQ6A2 => _isEnglish ? 'It annoys me but I tolerate it' : 'Sinir olurum ama idare ederim';
  static String get redFlagsQ6A3 => _isEnglish ? 'This is a red flag' : 'Bu bir kırmızı bayraktır';
  static String get redFlagsQ6A4 => _isEnglish ? 'I distance myself immediately' : 'Hemen uzaklaşırım';
  static String get redFlagsQ7 => _isEnglish ? 'If someone punishes you by silencing you (ghosting, giving you the silent treatment, etc.)...' : 'Biri seni susturarak cezalandırırsa (ghosting, trip atma vs.)…';
  static String get redFlagsQ7A1 => _isEnglish ? 'I try to win them back' : 'Onu geri kazanmaya çalışırım';
  static String get redFlagsQ7A2 => _isEnglish ? 'I question what I did' : 'Ne yaptığımı sorgularım';
  static String get redFlagsQ7A3 => _isEnglish ? 'I notice it but give them time' : 'Bunu fark ederim ama zaman tanırım';
  static String get redFlagsQ7A4 => _isEnglish ? 'I protect my energy and withdraw' : 'Enerjimi korur, geri çekilirim';
  static String get redFlagsQ8 => _isEnglish ? 'How far would you go to make someone happy?' : 'Birini mutlu etmek için ne kadar ileri gidersin?';
  static String get redFlagsQ8A1 => _isEnglish ? 'No limit, as long as they\'re happy' : 'Sınırım yok, yeter ki mutlu olsun';
  static String get redFlagsQ8A2 => _isEnglish ? 'Up to a point, then I stop' : 'Bir yere kadar, sonra dururum';
  static String get redFlagsQ8A3 => _isEnglish ? 'Sacrifice should be mutual' : 'Fedakârlık karşılıklı olmalı';
  static String get redFlagsQ8A4 => _isEnglish ? 'I need to be happy first' : 'Önce kendim mutlu olmalıyım';
  
  // Funny Test
  static String get zodiacFunLevelSubtitle => _isEnglish ? 'Measure your fun level' : 'Eğlence seviyeni ölç';
  static String get funnyQ1 => _isEnglish ? 'What usually happens when you enter a room?' : 'Bir ortama girdiğinde genelde ne olur?';
  static String get funnyQ1A1 => _isEnglish ? 'I immediately connect with everyone' : 'Herkesle hemen kaynaşırım';
  static String get funnyQ1A2 => _isEnglish ? 'I don\'t speak until I understand the vibe' : 'Ortamı çözmeden konuşmam';
  static String get funnyQ1A3 => _isEnglish ? 'I\'m quiet but observant' : 'Sessiz ama gözlemciyim';
  static String get funnyQ1A4 => _isEnglish ? 'The room feels incomplete without me 😎' : 'Ben gelmeden ortam eksik hissedilir 😎';
  static String get funnyQ2 => _isEnglish ? 'What style of jokes make you laugh the most?' : 'En çok hangi tarzda espriler seni güldürür?';
  static String get funnyQ2A1 => _isEnglish ? 'Witty and subtle humor' : 'Zeki ve ince mizah';
  static String get funnyQ2A2 => _isEnglish ? 'Absurd and silly things' : 'Absürt ve saçma şeyler';
  static String get funnyQ2A3 => _isEnglish ? 'Daily life comedy' : 'Günlük hayat komedisi';
  static String get funnyQ2A4 => _isEnglish ? 'Dark humor, slightly sarcastic things' : 'Kara mizah, hafif alaycı şeyler';
  static String get funnyQ3 => _isEnglish ? 'In your friend group, you\'re usually...' : 'Arkadaş grubunda sen genelde...';
  static String get funnyQ3A1 => _isEnglish ? 'The joker' : 'Şakacı ruh';
  static String get funnyQ3A2 => _isEnglish ? 'Listener / observer' : 'Dinleyici / gözlemci';
  static String get funnyQ3A3 => _isEnglish ? 'The organizer' : 'Organizatör';
  static String get funnyQ3A4 => _isEnglish ? 'Unpredictable surprise character 😂' : 'Dengesiz sürpriz karakter 😂';
  static String get funnyQ4 => _isEnglish ? 'Even when your mood is down...' : 'Moralin bozukken bile...';
  static String get funnyQ4A1 => _isEnglish ? 'I still make people laugh' : 'Yine insanları güldürürüm';
  static String get funnyQ4A2 => _isEnglish ? 'I go silent' : 'Sessizleşirim';
  static String get funnyQ4A3 => _isEnglish ? 'I withdraw into myself' : 'Kendi halime çekilirim';
  static String get funnyQ4A4 => _isEnglish ? 'There\'s always a part of me laughing inside' : 'İçimden kahkaha atan bir taraf hep vardır';
  static String get funnyQ5 => _isEnglish ? 'What is "fun" like in your life?' : '"Eğlence" senin hayatında nasıl bir şeydir?';
  static String get funnyQ5A1 => _isEnglish ? 'Life itself!' : 'Hayatın kendisi!';
  static String get funnyQ5A2 => _isEnglish ? 'It changes according to my mood' : 'Ruh halime göre değişir';
  static String get funnyQ5A3 => _isEnglish ? 'Irregular but intense' : 'Düzensiz ama yoğun';
  static String get funnyQ5A4 => _isEnglish ? 'Sometimes even silence is fun' : 'Bazen sessizlik bile eğlencedir';
  static String get funnyQ6 => _isEnglish ? 'Which word describes you?' : 'Hangi kelime seni anlatıyor?';
  static String get funnyQ6A1 => _isEnglish ? 'Enthusiasm' : 'Coşku';
  static String get funnyQ6A2 => _isEnglish ? 'Balance' : 'Denge';
  static String get funnyQ6A3 => _isEnglish ? 'Chaos' : 'Kaos';
  static String get funnyQ6A4 => _isEnglish ? 'Dream' : 'Rüya';
  
  // Chaos Test
  static String get zodiacChaosLevelSubtitle => _isEnglish ? 'Measure your chaos energy' : 'Kaos enerjini ölç';
  static String get chaosQ1 => _isEnglish ? 'When someone angers you, usually...' : 'Birisi seni sinirlendirdiğinde genelde...';
  static String get chaosQ1A1 => _isEnglish ? 'I explode immediately 😤' : 'Hemen patlarım 😤';
  static String get chaosQ1A2 => _isEnglish ? 'I stay silent, go crazy inside' : 'Sessiz kalır, içten içe deliririm';
  static String get chaosQ1A3 => _isEnglish ? 'I don\'t care but I hold a grudge' : 'Umursamam ama kinimi tutarım';
  static String get chaosQ1A4 => _isEnglish ? 'I laugh it off, then settle the score later' : 'Güler geçerim, sonra hesaplaşırım';
  static String get chaosQ2 => _isEnglish ? 'If something doesn\'t go as planned...' : 'Bir şey planladığın gibi gitmezse...';
  static String get chaosQ2A1 => _isEnglish ? 'I panic but recover' : 'Paniklerim ama toparlarım';
  static String get chaosQ2A2 => _isEnglish ? 'I delete everything and start over' : 'Her şeyi silip yeniden başlarım';
  static String get chaosQ2A3 => _isEnglish ? 'I go crazy but don\'t show it' : 'Kafayı yerim ama çaktırmam';
  static String get chaosQ2A4 => _isEnglish ? 'I let it flow (but there\'s a storm inside)' : 'Akışa bırakırım (ama içimde fırtına kopar)';
  static String get chaosQ3 => _isEnglish ? 'What do you do when you feel at "breaking point"?' : 'Kendini "patlama noktasında" hissettiğinde ne yaparsın?';
  static String get chaosQ3A1 => _isEnglish ? 'I shut down, don\'t answer anyone' : 'Kapatırım, kimseye cevap vermem';
  static String get chaosQ3A2 => _isEnglish ? 'I write / draw' : 'Yazı yazar / çizerim';
  static String get chaosQ3A3 => _isEnglish ? 'I call someone and vent' : 'Birini arayıp dökerim';
  static String get chaosQ3A4 => _isEnglish ? 'I lock myself in a room and get lost in music' : 'Odaya kapanır, müzikle kaybolurum';
  static String get chaosQ4 => _isEnglish ? 'How much drama is in your life?' : 'Hayatında dram ne kadar var?';
  static String get chaosQ4A1 => _isEnglish ? 'Drama finds me 😅' : 'Dram beni bulur 😅';
  static String get chaosQ4A2 => _isEnglish ? 'I exaggerate a bit sometimes' : 'Ben biraz abartırım bazen';
  static String get chaosQ4A3 => _isEnglish ? 'I can\'t live without drama' : 'Dramsız yaşayamam';
  static String get chaosQ4A4 => _isEnglish ? 'I\'m calm but everyone around me is dramatic' : 'Sakinim ama etrafımdaki herkes dramatik';
  static String get chaosQ5 => _isEnglish ? 'When an event affects you...' : 'Bir olay seni etkilediğinde…';
  static String get chaosQ5A1 => _isEnglish ? 'I think about it for days' : 'Günlerce düşünürüm';
  static String get chaosQ5A2 => _isEnglish ? 'I forget it within 5 minutes' : '5 dakika içinde unuturum';
  static String get chaosQ5A3 => _isEnglish ? 'It stays with me but I don\'t show it' : 'Bende kalır ama belli etmem';
  static String get chaosQ5A4 => _isEnglish ? 'It changes my energy, I\'m reborn' : 'Enerjimi değiştirir, yeniden doğarım';
  static String get chaosQ6 => _isEnglish ? 'Who usually wins in an argument?' : 'Bir tartışmada genelde kim kazanır?';
  static String get chaosQ6A1 => _isEnglish ? 'Me (I\'m scary sometimes 😈)' : 'Ben (korkutucuyum bazen 😈)';
  static String get chaosQ6A2 => _isEnglish ? 'The other side (I don\'t bother)' : 'Karşı taraf (uğraşmam)';
  static String get chaosQ6A3 => _isEnglish ? 'Depends on who...' : 'Kime bağlı…';
  static String get chaosQ6A4 => _isEnglish ? 'No one wins, I just explode' : 'Kimse kazanmaz, sadece patlarım';
  static String get chaosQ7 => _isEnglish ? 'Have you ever cried and laughed at the same time?' : 'Aynı anda hem ağlayıp hem güldüğün oldu mu?';
  static String get chaosQ7A1 => _isEnglish ? 'Every week' : 'Her hafta';
  static String get chaosQ7A2 => _isEnglish ? 'Sometimes' : 'Bazen';
  static String get chaosQ7A3 => _isEnglish ? 'Rarely' : 'Nadir';
  static String get chaosQ7A4 => _isEnglish ? 'No but it happens inside me' : 'Hayır ama içimden oluyor';
  
  // Super Power Test
  static String get hiddenSuperPowerTest => _isEnglish ? 'What Is Your Hidden Super Power?' : 'Gizli Süper Gücün Ne?';
  static String get hiddenSuperPowerSubtitle => _isEnglish ? 'Discover the power within you' : 'İçindeki gücü keşfet';
  static String get superPowerQ1 => _isEnglish ? 'When you first see someone, usually...' : 'Birini ilk kez gördüğünde genelde…';
  static String get superPowerQ1A1 => _isEnglish ? 'I immediately feel their energy' : 'Onun enerjisini hemen hissederim';
  static String get superPowerQ1A2 => _isEnglish ? 'I try to figure out their behavior' : 'Davranışlarını çözmeye çalışırım';
  static String get superPowerQ1A3 => _isEnglish ? 'I talk immediately' : 'Hemen konuşurum';
  static String get superPowerQ1A4 => _isEnglish ? 'I act cold and observe' : 'Soğuk davranır, gözlemlerim';
  static String get superPowerQ2 => _isEnglish ? 'My reaction in a crisis is usually...' : 'Kriz anında tepkim genelde…';
  static String get superPowerQ2A1 => _isEnglish ? 'I calm everyone down' : 'Herkesi sakinleştiririm';
  static String get superPowerQ2A2 => _isEnglish ? 'I analyze silently' : 'Sessizce analiz ederim';
  static String get superPowerQ2A3 => _isEnglish ? 'I panic but recover' : 'Paniklerim ama toparlarım';
  static String get superPowerQ2A4 => _isEnglish ? 'I take control' : 'Kontrolü ele alırım';
  static String get superPowerQ3 => _isEnglish ? 'What aspect of yourself are you proud of?' : 'Kendinle gurur duyduğun yönün ne?';
  static String get superPowerQ3A1 => _isEnglish ? 'My empathy' : 'Empatim';
  static String get superPowerQ3A2 => _isEnglish ? 'My determination' : 'Kararlılığım';
  static String get superPowerQ3A3 => _isEnglish ? 'My creativity' : 'Yaratıcılığım';
  static String get superPowerQ3A4 => _isEnglish ? 'My quick thinking' : 'Hızlı düşünmem';
  static String get superPowerQ4 => _isEnglish ? 'What do you do when you\'re tired?' : 'Yorulduğunda ne yaparsın?';
  static String get superPowerQ4A1 => _isEnglish ? 'Music / meditation' : 'Müzik / meditasyon';
  static String get superPowerQ4A2 => _isEnglish ? 'I make plans' : 'Plan yaparım';
  static String get superPowerQ4A3 => _isEnglish ? 'I talk to people' : 'İnsanlarla konuşurum';
  static String get superPowerQ4A4 => _isEnglish ? 'I completely shut down and go into silence' : 'Tamamen kapanır, sessizliğe giderim';
  static String get superPowerQ5 => _isEnglish ? 'When a friend is sad...' : 'Bir arkadaşın üzgün olduğunda…';
  static String get superPowerQ5A1 => _isEnglish ? 'I notice even without feeling' : 'Hissetmeden bile fark ederim';
  static String get superPowerQ5A2 => _isEnglish ? 'I find a logical solution' : 'Mantıklı şekilde çözüm bulurum';
  static String get superPowerQ5A3 => _isEnglish ? 'I try to entertain them' : 'Onu eğlendirmeye çalışırım';
  static String get superPowerQ5A4 => _isEnglish ? 'I get sad for them' : 'Onun yerine üzülürüm';
  static String get superPowerQ6 => _isEnglish ? 'When I see a problem...' : 'Bir problem gördüğümde…';
  static String get superPowerQ6A1 => _isEnglish ? 'I immediately produce a solution' : 'Hemen çözüm üretirim';
  static String get superPowerQ6A2 => _isEnglish ? 'I analyze first' : 'Önce analiz ederim';
  static String get superPowerQ6A3 => _isEnglish ? 'I feel it, then it gets solved' : 'Hissederim, sonra çözülür';
  static String get superPowerQ6A4 => _isEnglish ? 'I approach from a different perspective' : 'Farklı bakış açısıyla yaklaşırım';
  static String get superPowerQ7 => _isEnglish ? 'Which of the following describes you?' : 'Aşağıdakilerden hangisi seni anlatıyor?';
  static String get superPowerQ7A1 => _isEnglish ? 'Quiet but deep' : 'Sessiz ama derin';
  static String get superPowerQ7A2 => _isEnglish ? 'Energetic and leader' : 'Enerjik ve lider';
  static String get superPowerQ7A3 => _isEnglish ? 'Emotional but strong' : 'Duygusal ama güçlü';
  static String get superPowerQ7A4 => _isEnglish ? 'Analytical and strategic' : 'Analitik ve stratejik';
  static String get superPowerQ8 => _isEnglish ? 'If your mind were like an orchestra...' : 'Zihnin bir orkestra gibi olsaydı…';
  static String get superPowerQ8A1 => _isEnglish ? 'A melancholic melody' : 'Melankolik bir melodi';
  static String get superPowerQ8A2 => _isEnglish ? 'A loud, rhythmic beat' : 'Gür, tempolu bir ritim';
  static String get superPowerQ8A3 => _isEnglish ? 'A calm but deep harmony' : 'Sakin ama derin bir armoni';
  static String get superPowerQ8A4 => _isEnglish ? 'An unbalanced but creative symphony' : 'Dengesiz ama yaratıcı bir senfoni';
  static String get superPowerQ9 => _isEnglish ? 'What do your friends say about you?' : 'Arkadaşların senin için ne der?';
  static String get superPowerQ9A1 => _isEnglish ? '"It\'s hard to understand you but there\'s a wisdom."' : '"Seni anlamak zor ama bir bilgelik var."';
  static String get superPowerQ9A2 => _isEnglish ? '"Always strong, controlling everything."' : '"Hep güçlü, her şeyi kontrol ediyor."';
  static String get superPowerQ9A3 => _isEnglish ? '"Creative, full of different ideas."' : '"Yaratıcı, değişik fikirlerle dolu."';
  static String get superPowerQ9A4 => _isEnglish ? '"Fast, like a radar that notices everything."' : '"Hızlı, her şeyi fark eden bir radar gibi."';
  static String get superPowerQ10 => _isEnglish ? 'If you had a super power, which would it be?' : 'Bir süper gücün olsaydı hangisi olurdu?';
  static String get superPowerQ10A1 => _isEnglish ? 'Energy healing' : 'Enerji şifası';
  static String get superPowerQ10A2 => _isEnglish ? 'Mind control' : 'Zihin kontrolü';
  static String get superPowerQ10A3 => _isEnglish ? 'Invisibility' : 'Görünmezlik';
  static String get superPowerQ10A4 => _isEnglish ? 'Stopping time' : 'Zamanı durdurmak';
  
  // Planet Energy Test
  static String get planetEnergyTest => _isEnglish ? 'Which Planet\'s Energy Is Dominant In You?' : 'Hangi Gezegenin Enerjisi Sende Baskın?';
  static String get planetEnergySubtitle => _isEnglish ? 'Discover your planet energy' : 'Gezegen enerjini keşfet';
  static String get planetEnergyQ1 => _isEnglish ? 'How do you spend a day?' : 'Bir günü nasıl geçirirsin?';
  static String get planetEnergyQ1A1 => _isEnglish ? 'Planned and efficient' : 'Planlı ve verimli';
  static String get planetEnergyQ1A2 => _isEnglish ? 'With emotional fluctuations' : 'Duygusal dalgalanmalarla';
  static String get planetEnergyQ1A3 => _isEnglish ? 'Seeking adventure' : 'Macera arayarak';
  static String get planetEnergyQ1A4 => _isEnglish ? 'In flow, intuitively' : 'Akışta, sezgisel şekilde';
  static String get planetEnergyQ2 => _isEnglish ? 'What do you trust when making a decision?' : 'Bir konuda karar alırken neye güvenirsin?';
  static String get planetEnergyQ2A1 => _isEnglish ? 'My logic' : 'Mantığıma';
  static String get planetEnergyQ2A2 => _isEnglish ? 'My heart' : 'Kalbime';
  static String get planetEnergyQ2A3 => _isEnglish ? 'My inner voice' : 'İç sesime';
  static String get planetEnergyQ2A4 => _isEnglish ? 'My experience' : 'Deneyimime';
  static String get planetEnergyQ3 => _isEnglish ? 'When an event affects you...' : 'Bir olay seni etkilediğinde...';
  static String get planetEnergyQ3A1 => _isEnglish ? 'I analyze it inside' : 'İçimde analiz ederim';
  static String get planetEnergyQ3A2 => _isEnglish ? 'I react emotionally' : 'Duygusal tepki veririm';
  static String get planetEnergyQ3A3 => _isEnglish ? 'I immediately head for a solution' : 'Hemen çözüme yönelirim';
  static String get planetEnergyQ3A4 => _isEnglish ? 'I say "The universe\'s plan" and move on' : '"Evrenin planı" deyip geçerim';
  static String get planetEnergyQ4 => _isEnglish ? 'People around you usually see you as...' : 'Çevrendekiler seni genelde...';
  static String get planetEnergyQ4A1 => _isEnglish ? 'Strong and confident' : 'Güçlü ve özgüvenli';
  static String get planetEnergyQ4A2 => _isEnglish ? 'Emotional but warm' : 'Duygusal ama sıcak';
  static String get planetEnergyQ4A3 => _isEnglish ? 'Dreamy' : 'Hayalperest';
  static String get planetEnergyQ4A4 => _isEnglish ? 'Logical and calm' : 'Mantıklı ve sakin';
  static String get planetEnergyQ5 => _isEnglish ? 'What motivates you most in life?' : 'Hayatta seni en çok motive eden şey ne?';
  static String get planetEnergyQ5A1 => _isEnglish ? 'Success' : 'Başarı';
  static String get planetEnergyQ5A2 => _isEnglish ? 'Love' : 'Sevgi';
  static String get planetEnergyQ5A3 => _isEnglish ? 'Freedom' : 'Özgürlük';
  static String get planetEnergyQ5A4 => _isEnglish ? 'Wisdom' : 'Bilgelik';
  static String get planetEnergyQ6 => _isEnglish ? 'The word that best describes your energy:' : 'Enerjini en iyi tanımlayan kelime:';
  static String get planetEnergyQ6A1 => _isEnglish ? 'Passion' : 'Tutku';
  static String get planetEnergyQ6A2 => _isEnglish ? 'Peace' : 'Huzur';
  static String get planetEnergyQ6A3 => _isEnglish ? 'Discovery' : 'Keşif';
  static String get planetEnergyQ6A4 => _isEnglish ? 'Balance' : 'Denge';
  static String get planetEnergyQ7 => _isEnglish ? 'How active is your imagination?' : 'Hayal gücün ne kadar aktif?';
  static String get planetEnergyQ7A1 => _isEnglish ? 'I\'m realistic but I dream' : 'Gerçekçiyim ama hayal ederim';
  static String get planetEnergyQ7A2 => _isEnglish ? 'I have a separate universe in my head' : 'Kafamda ayrı bir evren var';
  static String get planetEnergyQ7A3 => _isEnglish ? 'I dream but immediately take action' : 'Hayal kurarım ama hemen aksiyona geçerim';
  static String get planetEnergyQ7A4 => _isEnglish ? 'I have few but clear dreams' : 'Az ama net hayallerim olur';
  static String get planetEnergyQ8 => _isEnglish ? 'What do you do first when a problem arises?' : 'Bir problem çıktığında ilk ne yaparsın?';
  static String get planetEnergyQ8A1 => _isEnglish ? 'I create a strategy' : 'Strateji kurarım';
  static String get planetEnergyQ8A2 => _isEnglish ? 'I act instinctively' : 'İçgüdüsel davranırım';
  static String get planetEnergyQ8A3 => _isEnglish ? 'I calm down and analyze' : 'Sakinleşir, analiz ederim';
  static String get planetEnergyQ8A4 => _isEnglish ? 'I leave it to the universe' : 'Evrene bırakırım';
  static String get planetEnergyQ9 => _isEnglish ? 'How do you experience love?' : 'Aşkı nasıl yaşarsın?';
  static String get planetEnergyQ9A1 => _isEnglish ? 'Intense and deep' : 'Yoğun ve derin';
  static String get planetEnergyQ9A2 => _isEnglish ? 'Logical but loving' : 'Mantıklı ama sevgi dolu';
  static String get planetEnergyQ9A3 => _isEnglish ? 'Exciting and impulsive' : 'Heyecanlı ve dürtüsel';
  static String get planetEnergyQ9A4 => _isEnglish ? 'As a spiritual connection' : 'Ruhsal bağlantı olarak';
  
  // Soulmate Zodiac Test
  static String get soulmateZodiacTest => _isEnglish ? 'What Zodiac Sign Is Your Soulmate?' : 'Ruh Eşin Hangi Burçtan?';
  static String get soulmateZodiacSubtitle => _isEnglish ? 'Discover your soulmate' : 'Ruh eşini keşfet';
  static String get soulmateZodiacQ1 => _isEnglish ? 'What is most important to you in a relationship?' : 'Bir ilişkide senin için en önemli şey ne?';
  static String get soulmateZodiacQ1A1 => _isEnglish ? 'Trust and loyalty' : 'Güven ve sadakat';
  static String get soulmateZodiacQ1A2 => _isEnglish ? 'Passion and excitement' : 'Tutku ve heyecan';
  static String get soulmateZodiacQ1A3 => _isEnglish ? 'Emotional connection' : 'Duygusal bağ';
  static String get soulmateZodiacQ1A4 => _isEnglish ? 'Intelligence and understanding' : 'Zeka ve anlayış';
  static String get soulmateZodiacQ2 => _isEnglish ? 'Which word best describes you?' : 'Kendini en iyi hangi kelimeyle tanımlarsın?';
  static String get soulmateZodiacQ2A1 => _isEnglish ? 'Calm' : 'Sakin';
  static String get soulmateZodiacQ2A2 => _isEnglish ? 'Passionate' : 'Tutkulu';
  static String get soulmateZodiacQ2A3 => _isEnglish ? 'Deep' : 'Derin';
  static String get soulmateZodiacQ2A4 => _isEnglish ? 'Free' : 'Özgür';
  static String get soulmateZodiacQ3 => _isEnglish ? 'When you fall in love, usually...' : 'Kalbini kaptırdığında genelde…';
  static String get soulmateZodiacQ3A1 => _isEnglish ? 'I show my feelings immediately' : 'Duygularımı hemen belli ederim';
  static String get soulmateZodiacQ3A2 => _isEnglish ? 'I want it to be understood from my eyes' : 'Gözlerinden anlaşılsın isterim';
  static String get soulmateZodiacQ3A3 => _isEnglish ? 'I bond secretly' : 'Gizli gizli bağlanırım';
  static String get soulmateZodiacQ3A4 => _isEnglish ? 'I live it fast but intense' : 'Hızlı ama yoğun yaşarım';
  static String get soulmateZodiacQ4 => _isEnglish ? 'What color is love for you?' : 'Aşk senin için hangi renktir?';
  static String get soulmateZodiacQ4A1 => _isEnglish ? 'Blue (calm, deep)' : 'Mavi (sakin, derin)';
  static String get soulmateZodiacQ4A2 => _isEnglish ? 'Red (passionate, strong)' : 'Kırmızı (tutkulu, güçlü)';
  static String get soulmateZodiacQ4A3 => _isEnglish ? 'Pink (romantic, pure)' : 'Pembe (romantik, saf)';
  static String get soulmateZodiacQ4A4 => _isEnglish ? 'Purple (mystical, intuitive)' : 'Mor (mistik, sezgisel)';
  static String get soulmateZodiacQ5 => _isEnglish ? 'The personality type that attracts you most:' : 'Seni en çok çeken kişilik tipi:';
  static String get soulmateZodiacQ5A1 => _isEnglish ? 'Trustworthy, calm' : 'Güven veren, sakin';
  static String get soulmateZodiacQ5A2 => _isEnglish ? 'Mysterious, deep gaze' : 'Gizemli, derin bakan';
  static String get soulmateZodiacQ5A3 => _isEnglish ? 'Fun, positive' : 'Eğlenceli, pozitif';
  static String get soulmateZodiacQ5A4 => _isEnglish ? 'Intelligent and independent' : 'Zeki ve bağımsız';
  static String get soulmateZodiacQ6 => _isEnglish ? 'What was your biggest lesson in love?' : 'Aşkta en büyük dersin ne oldu?';
  static String get soulmateZodiacQ6A1 => _isEnglish ? 'Patience' : 'Sabır';
  static String get soulmateZodiacQ6A2 => _isEnglish ? 'Valuing yourself' : 'Kendine değer vermek';
  static String get soulmateZodiacQ6A3 => _isEnglish ? 'Everything is about energy' : 'Her şey enerjiyle alakalı';
  static String get soulmateZodiacQ6A4 => _isEnglish ? 'Sometimes love is not enough' : 'Bazen sevgi yeterli değil';
  static String get soulmateZodiacQ7 => _isEnglish ? 'How do you usually live life?' : 'Hayatı genelde nasıl yaşarsın?';
  static String get soulmateZodiacQ7A1 => _isEnglish ? 'In flow' : 'Akışta';
  static String get soulmateZodiacQ7A2 => _isEnglish ? 'Planned and controlled' : 'Planlı ve kontrollü';
  static String get soulmateZodiacQ7A3 => _isEnglish ? 'With emotional intensity' : 'Duygusal yoğunlukla';
  static String get soulmateZodiacQ7A4 => _isEnglish ? 'Living in the moment' : 'Anı yaşayarak';
  
  // Mental Health Color Test
  static String get mentalHealthColorTest => _isEnglish ? 'Which Color Reflects Your Mental Health?' : 'Ruh Sağlığını Yansıtan Renk Hangisi';
  static String get mentalHealthColorSubtitle => _isEnglish ? 'Discover your mood' : 'Ruh halini keşfet';
  static String get mentalHealthColorMoodHint => _isEnglish ? 'Good / mixed / tired / energetic' : 'İyi / karışık / yorgun / enerjik';
  static String get mentalHealthColorQ1 => _isEnglish ? 'How have you been feeling lately?' : 'Son zamanlarda kendini nasıl hissediyorsun?';
  static String get mentalHealthColorQ1A1 => _isEnglish ? 'Emotionally mixed' : 'Duygusal olarak karışık';
  static String get mentalHealthColorQ1A2 => _isEnglish ? 'Peaceful and balanced' : 'Huzurlu ve dengeli';
  static String get mentalHealthColorQ1A3 => _isEnglish ? 'Tired but hopeful' : 'Yorgun ama umutlu';
  static String get mentalHealthColorQ1A4 => _isEnglish ? 'Energetic and motivated' : 'Enerjik ve motive';
  static String get mentalHealthColorQ2 => _isEnglish ? 'How does your mind usually work?' : 'Zihnin genelde nasıl çalışır?';
  static String get mentalHealthColorQ2A1 => _isEnglish ? 'Constantly analyzes, never stops' : 'Sürekli analiz eder, durmaz';
  static String get mentalHealthColorQ2A2 => _isEnglish ? 'Lives in the moment, doesn\'t overthink' : 'Anı yaşar, fazla düşünmez';
  static String get mentalHealthColorQ2A3 => _isEnglish ? 'Thinks deeply but intuitively' : 'Derin ama sezgisel düşünür';
  static String get mentalHealthColorQ2A4 => _isEnglish ? 'Sometimes scattered but recovers' : 'Zaman zaman dağılır ama toparlar';
  static String get mentalHealthColorQ3 => _isEnglish ? 'What do you do first in a difficult period?' : 'Zor bir dönemde ilk yaptığın şey nedir?';
  static String get mentalHealthColorQ3A1 => _isEnglish ? 'I withdraw into myself' : 'Kendi içime çekilirim';
  static String get mentalHealthColorQ3A2 => _isEnglish ? 'I get support from loved ones' : 'Yakınlarımdan destek alırım';
  static String get mentalHealthColorQ3A3 => _isEnglish ? 'I act as if nothing happened' : 'Hiçbir şey olmamış gibi davranırım';
  static String get mentalHealthColorQ3A4 => _isEnglish ? 'I turn to meditation, music or art' : 'Meditasyon, müzik veya sanata yönelirim';
  static String get mentalHealthColorQ4 => _isEnglish ? 'Describe your current energy in one word:' : 'Bir kelimeyle şu anki enerjini tarif et:';
  static String get mentalHealthColorQ4A1 => _isEnglish ? 'Wavy' : 'Dalgalı';
  static String get mentalHealthColorQ4A2 => _isEnglish ? 'Calm' : 'Dingin';
  static String get mentalHealthColorQ4A3 => _isEnglish ? 'Closed' : 'Kapalı';
  static String get mentalHealthColorQ4A4 => _isEnglish ? 'Bright' : 'Aydınlık';
  static String get mentalHealthColorQ5 => _isEnglish ? 'Where do you feel best?' : 'Kendini en iyi hissettiğin yer:';
  static String get mentalHealthColorQ5A1 => _isEnglish ? 'In a quiet room' : 'Sessiz bir odada';
  static String get mentalHealthColorQ5A2 => _isEnglish ? 'In nature, outdoors' : 'Doğada, açık havada';
  static String get mentalHealthColorQ5A3 => _isEnglish ? 'With friends' : 'Arkadaşlarla';
  static String get mentalHealthColorQ5A4 => _isEnglish ? 'When doing creative things' : 'Yaratıcı şeyler yaparken';
  
  // Spirit Animal Test
  static String get spiritAnimalTest => _isEnglish ? 'What Is Your Totem Animal?' : 'Totem Hayvanın Hangisi?';
  static String get spiritAnimalSubtitle => _isEnglish ? 'Discover your spirit animal' : 'Ruhsal hayvanını keşfet';
  static String get spiritAnimalQ1 => _isEnglish ? 'If we had to describe you in one word?' : 'Bir kelimeyle seni anlat desek?';
  static String get spiritAnimalQ1A1 => _isEnglish ? 'Curious' : 'Meraklı';
  static String get spiritAnimalQ1A2 => _isEnglish ? 'Strong' : 'Güçlü';
  static String get spiritAnimalQ1A3 => _isEnglish ? 'Calm' : 'Sakin';
  static String get spiritAnimalQ1A4 => _isEnglish ? 'Emotional' : 'Duygusal';
  static String get spiritAnimalQ2 => _isEnglish ? 'What do you do in difficult times?' : 'Zor zamanlarda ne yaparsın?';
  static String get spiritAnimalQ2A1 => _isEnglish ? 'I observe silently' : 'Sessizce gözlemlerim';
  static String get spiritAnimalQ2A2 => _isEnglish ? 'I fight' : 'Mücadele ederim';
  static String get spiritAnimalQ2A3 => _isEnglish ? 'I run away, regenerate' : 'Kaçar, yenilenirim';
  static String get spiritAnimalQ2A4 => _isEnglish ? 'I listen to my inner voice' : 'İç sesimi dinlerim';
  static String get spiritAnimalQ3 => _isEnglish ? 'How is your mood usually?' : 'Ruh halin genelde nasıl?';
  static String get spiritAnimalQ3A1 => _isEnglish ? 'Absent-minded but deep' : 'Dalgın ama derin';
  static String get spiritAnimalQ3A2 => _isEnglish ? 'Brave and direct' : 'Cesur ve direkt';
  static String get spiritAnimalQ3A3 => _isEnglish ? 'Variable but colorful' : 'Değişken ama renkli';
  static String get spiritAnimalQ3A4 => _isEnglish ? 'Wise and serene' : 'Bilge ve dingin';
  static String get spiritAnimalQ4 => _isEnglish ? 'When you enter a room, usually:' : 'Bir ortama girdiğinde genelde:';
  static String get spiritAnimalQ4A1 => _isEnglish ? 'I immediately blend in' : 'Hemen kaynaşırım';
  static String get spiritAnimalQ4A2 => _isEnglish ? 'I observe' : 'Gözlemlerim';
  static String get spiritAnimalQ4A3 => _isEnglish ? 'I act according to my energy' : 'Kendi enerjime göre davranırım';
  static String get spiritAnimalQ4A4 => _isEnglish ? 'I speak little, feel a lot' : 'Az konuşur, çok hissederim';
  static String get spiritAnimalQ5 => _isEnglish ? 'The moment you feel free:' : 'Kendini özgür hissettiğin an:';
  static String get spiritAnimalQ5A1 => _isEnglish ? 'When trying something new' : 'Yeni bir şey denerken';
  static String get spiritAnimalQ5A2 => _isEnglish ? 'In nature, alone' : 'Doğada, tek başımayken';
  static String get spiritAnimalQ5A3 => _isEnglish ? 'When I reach a goal' : 'Bir hedefe ulaştığımda';
  static String get spiritAnimalQ5A4 => _isEnglish ? 'With meditation or music' : 'Meditasyon veya müzikle';
  static String get spiritAnimalQ6 => _isEnglish ? 'You usually determine whether to trust someone...' : 'Birine güvenip güvenmeyeceğini genelde...';
  static String get spiritAnimalQ6A1 => _isEnglish ? 'I understand immediately' : 'Hemen anlarım';
  static String get spiritAnimalQ6A2 => _isEnglish ? 'I figure it out through experience' : 'Deneyimleyerek çözerim';
  static String get spiritAnimalQ6A3 => _isEnglish ? 'I\'m affected by others\' energy' : 'Başkalarının enerjisinden etkilenirim';
  static String get spiritAnimalQ6A4 => _isEnglish ? 'I trust my instincts 100%' : 'İçgüdülerime %100 güvenirim';
  static String get spiritAnimalQ7 => _isEnglish ? 'Being alone...' : 'Yalnız kalmak…';
  static String get spiritAnimalQ7A1 => _isEnglish ? 'Relaxing' : 'Rahatlatıcı';
  static String get spiritAnimalQ7A2 => _isEnglish ? 'Unnecessary' : 'Gereksiz';
  static String get spiritAnimalQ7A3 => _isEnglish ? 'Inspiring' : 'İlham verici';
  static String get spiritAnimalQ7A4 => _isEnglish ? 'Transformative' : 'Dönüştürücü';
  static String get spiritAnimalQ8 => _isEnglish ? 'The time you feel strongest:' : 'Kendini en güçlü hissettiğin zaman:';
  static String get spiritAnimalQ8A1 => _isEnglish ? 'Morning' : 'Sabah';
  static String get spiritAnimalQ8A2 => _isEnglish ? 'Midnight' : 'Gece yarısı';
  static String get spiritAnimalQ8A3 => _isEnglish ? 'Sunset' : 'Gün batımı';
  static String get spiritAnimalQ8A4 => _isEnglish ? 'Midday' : 'Gün ortası';
  static String get spiritAnimalQ9 => _isEnglish ? 'Where do you feel most peaceful?' : 'Kendini nerede en huzurlu hissedersin?';
  static String get spiritAnimalQ9A1 => _isEnglish ? 'In the forest' : 'Ormanda';
  static String get spiritAnimalQ9A2 => _isEnglish ? 'By the sea' : 'Deniz kenarında';
  static String get spiritAnimalQ9A3 => _isEnglish ? 'In the city' : 'Şehirde';
  static String get spiritAnimalQ9A4 => _isEnglish ? 'In a quiet room' : 'Sessiz bir odada';
  
  // Energy Stage Test
  static String get energyStageTest => _isEnglish ? 'What Stage Is Your Energy At Right Now?' : 'Şu Anda Enerjin Hangi Aşamada?';
  static String get energyStageSubtitle => _isEnglish ? 'Discover the energy universe' : 'Enerji evreni keşfet';
  static String get energyStageQ1 => _isEnglish ? 'The first thing you feel when you start the day:' : 'Güne başladığında ilk hissettiğin şey:';
  static String get energyStageQ1A1 => _isEnglish ? 'I feel reborn' : 'Yeniden doğmuş gibiyim';
  static String get energyStageQ1A2 => _isEnglish ? 'I feel a bit mixed' : 'Biraz karışık hissediyorum';
  static String get energyStageQ1A3 => _isEnglish ? 'I\'m still tired' : 'Hâlâ yorgunum';
  static String get energyStageQ1A4 => _isEnglish ? 'I\'m calm but motivated' : 'Sakin ama motiveyim';
  static String get energyStageQ2 => _isEnglish ? 'How would you describe your life energy right now?' : 'Hayat enerjini şu anda nasıl tarif edersin?';
  static String get energyStageQ2A1 => _isEnglish ? 'Strong and rising' : 'Güçlü ve yükselen';
  static String get energyStageQ2A2 => _isEnglish ? 'Stagnant, a bit uncertain' : 'Durağan, biraz kararsız';
  static String get energyStageQ2A3 => _isEnglish ? 'I feel it\'s declining' : 'Düşüşte hissediyorum';
  static String get energyStageQ2A4 => _isEnglish ? 'Balanced, peaceful' : 'Dengede, huzurluyum';
  static String get energyStageQ3 => _isEnglish ? 'What is the dominant feeling in your heart right now?' : 'Kalbinde en baskın his şu anda ne?';
  static String get energyStageQ3A1 => _isEnglish ? 'Hope' : 'Umut';
  static String get energyStageQ3A2 => _isEnglish ? 'Uncertainty' : 'Belirsizlik';
  static String get energyStageQ3A3 => _isEnglish ? 'Tiredness' : 'Yorgunluk';
  static String get energyStageQ3A4 => _isEnglish ? 'Peace' : 'Huzur';
  static String get energyStageQ4 => _isEnglish ? 'Lately your mind...' : 'Son günlerde zihnin…';
  static String get energyStageQ4A1 => _isEnglish ? 'Full of creative ideas' : 'Yaratıcı fikirlerle dolu';
  static String get energyStageQ4A2 => _isEnglish ? 'Too crowded' : 'Fazla kalabalık';
  static String get energyStageQ4A3 => _isEnglish ? 'Seems slowed down' : 'Yavaşlamış gibi';
  static String get energyStageQ4A4 => _isEnglish ? 'Clear and calm' : 'Net ve sakin';
  static String get energyStageQ5 => _isEnglish ? 'How is your interaction with people going?' : 'İnsanlarla etkileşimin nasıl gidiyor?';
  static String get energyStageQ5A1 => _isEnglish ? 'My energy matches with everyone' : 'Herkesle enerjim tutuyor';
  static String get energyStageQ5A2 => _isEnglish ? 'Some people tire me' : 'Bazı kişiler beni yoruyor';
  static String get energyStageQ5A3 => _isEnglish ? 'I want to distance myself' : 'Uzaklaşma isteğim var';
  static String get energyStageQ5A4 => _isEnglish ? 'I have few but quality communication' : 'Az ama kaliteli iletişim kuruyorum';
  static String get energyStageQ6 => _isEnglish ? 'Do you feel close to the universe?' : 'Kendini evrene yakın hissediyor musun?';
  static String get energyStageQ6A1 => _isEnglish ? 'Yes, I have a very strong connection' : 'Evet, çok güçlü bağlantım var';
  static String get energyStageQ6A2 => _isEnglish ? 'I feel it sometimes' : 'Bazen hissediyorum';
  static String get energyStageQ6A3 => _isEnglish ? 'I\'ve been disconnected for a long time' : 'Uzun zamandır kopuğum';
  static String get energyStageQ6A4 => _isEnglish ? 'Silent but aware' : 'Sessiz ama farkındayım';
  static String get energyStageQ7 => _isEnglish ? 'Do you feel where you\'re going in life right now?' : 'Şu anda hayatta nereye gittiğini hissediyor musun?';
  static String get energyStageQ7A1 => _isEnglish ? 'Yes, I\'m in control' : 'Evet, kontrol bende';
  static String get energyStageQ7A2 => _isEnglish ? 'Not sure yet' : 'Henüz emin değilim';
  static String get energyStageQ7A3 => _isEnglish ? 'I feel lost' : 'Kaybolmuş gibiyim';
  static String get energyStageQ7A4 => _isEnglish ? 'I\'m in flow, no rush' : 'Akıştayım, acelem yok';
  static String get energyStageQ8 => _isEnglish ? 'How do you feel at the end of the day?' : 'Günün sonunda kendini nasıl hissediyorsun?';
  static String get energyStageQ8A1 => _isEnglish ? 'Satisfied' : 'Tatmin olmuş';
  static String get energyStageQ8A2 => _isEnglish ? 'Mixed' : 'Karışık';
  static String get energyStageQ8A3 => _isEnglish ? 'Empty' : 'Boş';
  static String get energyStageQ8A4 => _isEnglish ? 'Peaceful' : 'Huzurlu';
  
  // Test Screen Messages
  static String get userNotLoggedIn => _isEnglish ? 'User not logged in' : 'Kullanıcı giriş yapmamış';
  static String get pleaseAnswerAllQuestions => _isEnglish ? 'Please answer all questions' : 'Lütfen tüm soruları cevaplayın';
  static String get resultsPreparing => _isEnglish ? 'Preparing results...' : 'Sonuçlar hazırlanıyor...';
  static String get dearUser => _isEnglish ? 'Dear user' : 'Değerli kullanıcı';
  static String get testCompletedMessage => _isEnglish ? 'I completed the test. Please analyze these test results and give me a detailed result.' : 'testini tamamladım. Lütfen bu test sonuçlarını analiz et ve bana detaylı bir sonuç ver.';
  static String get testCompletion => _isEnglish ? 'Test completion:' : 'Test tamamlama:';
  static String get testName => _isEnglish ? 'Test Name:' : 'Test Adı:';
  static String get testDescription => _isEnglish ? 'Test Description:' : 'Test Açıklaması:';
  static String get questionsAndAnswers => _isEnglish ? 'QUESTIONS AND ANSWERS:' : 'SORULAR VE CEVAPLAR:';

  // Quest titles
  static String get questCoffeeFortuneTitle => _isEnglish ? 'Send 1 coffee fortune' : '1 kahve falı gönder';
  static String get questLoveTestTitle => _isEnglish ? 'Solve 1 love test' : '1 aşk testi çöz';
  static String get questAuraMatchTitle => _isEnglish ? 'Try 1 aura match' : '1 aura eşleşme dene';

  // Love compatibility
  static String get discoverLoveCompatibility => _isEnglish 
      ? 'Discover love compatibility and find your soulmate' 
      : 'Aşk uyumunu keşfet ve ruh eşini bul';

  // Daily reward
  static String get dailyAuraReward => _isEnglish ? 'Daily Aura Reward' : 'Günlük Aura Ödülün';
  static String get todayKarmaWaiting => _isEnglish 
      ? 'Today +{0} karma is waiting for you. Claim it now to keep your streak!' 
      : 'Bugün +{0} karma seni bekliyor. Serini bozmamak için hemen al!';
  static String get claimMyReward => _isEnglish ? 'Claim My Reward' : 'Ödülümü Al';
  static String get dayStreak => _isEnglish ? '{0} day streak' : '{0} günlük seri';
  static String get streakWillReset => _isEnglish 
      ? 'If you don\'t log in today, your {0} day streak will be reset!' 
      : 'Bugün giriş yapmazsan {0} günlük serin sıfırlanır!';
  static String get todaysQuests => _isEnglish ? 'Today\'s Quests' : 'Bugünkü Görevler';
  static String get completedQuest => _isEnglish ? 'Completed!' : 'Tamamlandı!';
  
  static String get moodGood => _isEnglish ? 'Good' : 'İyi';
  static String get moodMixed => _isEnglish ? 'Mixed' : 'Karışık';
  static String get moodTired => _isEnglish ? 'Tired' : 'Yorgun';
  static String get moodEnergetic => _isEnglish ? 'Energetic' : 'Enerjik';
}

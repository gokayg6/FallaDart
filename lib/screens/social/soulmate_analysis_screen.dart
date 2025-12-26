import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/mystical_dialog.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/fortune/karma_cost_badge.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/firebase_service.dart';

class SoulmateAnalysisScreen extends StatefulWidget {
  const SoulmateAnalysisScreen({super.key});

  @override
  State<SoulmateAnalysisScreen> createState() => _SoulmateAnalysisScreenState();
}

class _SoulmateAnalysisScreenState extends State<SoulmateAnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdsService _ads = AdsService();
  bool _loading = true;
  String? _error;
  List<_Candidate> _candidates = [];
  List<_Candidate> _allCandidates = []; // Tüm adaylar
  bool _showOnlyCompatible = false; // Sadece uyumlu kişileri göster
  String? _genderFilter; // null = all, 'male', 'female', 'other'
  bool _genderFilterUsed = false; // Cinsiyet filtresi kullanıldı mı?
  int _index = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    _loadCandidates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _createMatchDocument({
    required String initiatorId,
    required UserModel currentUser,
    required UserModel targetUser,
    required double score,
    required bool hasAuraCompatibility,
  }) async {
    final existing = await _firestore
        .collection('matches')
        .where('users', arrayContains: currentUser.id)
        .get();

    for (final doc in existing.docs) {
      final users = List<String>.from(doc['users'] ?? []);
      if (users.contains(targetUser.id)) {
        return;
      }
    }

    await _firestore.collection('matches').add({
      'users': [currentUser.id, targetUser.id],
      'initiator': initiatorId,
      'status': 'accepted',
      'score': score,
      'hasAuraCompatibility': hasAuraCompatibility,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadCandidates() async {
    try {
      final current = Provider.of<UserProvider>(context, listen: false).user;
      if (current == null) throw Exception(AppStrings.sessionNotFound);

      // Birth date is mandatory for social / aura matching
      if (current.birthDate == null) {
        setState(() {
          _error = AppStrings.birthDateRequiredForSocial;
          _loading = false;
        });
        return;
      }

      final snap = await _firestore.collection('users').limit(50).get();
      final others = snap.docs
          .where((d) => d.id != current.id)
          .map((d) => UserModel.fromFirestore(d))
          .where((u) =>
              u.birthDate != null &&
              u.ageGroup == current.ageGroup &&
              u.socialVisible &&
              !current.blockedUsers.contains(u.id) &&
              !u.blockedUsers.contains(current.id))
          .toList();

      final scored = others
          .map((u) => _Candidate(
                user: u, 
                score: _scoreUsers(current, u),
                auraCompatibility: _calculateAuraCompatibility(current, u),
              ))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      if (mounted) {
        setState(() {
          _allCandidates = scored.take(20).toList();
          _candidates = _filterCandidates();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${AppStrings.couldNotLoad} $e';
          _loading = false;
        });
      }
    }
  }

  Color? _getAuraColor(UserModel user) {
    final colorName = user.preferences['auraColor']?.toString();
    if (colorName == null) return null;
    return _parseColorFromName(colorName);
  }

  Color? _parseColorFromName(String name) {
    // Color names can be in Turkish or English, map both
    final colorMap = {
      // Turkish
      'Mor': const Color(0xFF9B59B6),
      'Mavi': const Color(0xFF3498DB),
      'Yeşil': const Color(0xFF2ECC71),
      'Sarı': const Color(0xFFF1C40F),
      'Turuncu': const Color(0xFFE67E22),
      'Kırmızı': const Color(0xFFE74C3C),
      'Pembe': const Color(0xFFE91E63),
      'Indigo': const Color(0xFF6C5CE7),
      'Turkuaz': const Color(0xFF1ABC9C),
      // English
      'Purple': const Color(0xFF9B59B6),
      'Blue': const Color(0xFF3498DB),
      'Green': const Color(0xFF2ECC71),
      'Yellow': const Color(0xFFF1C40F),
      'Orange': const Color(0xFFE67E22),
      'Red': const Color(0xFFE74C3C),
      'Pink': const Color(0xFFE91E63),
      'Turquoise': const Color(0xFF1ABC9C),
    };
    return colorMap[name] ?? const Color(0xFF9B59B6);
  }

  List<_Candidate> _filterCandidates() {
    var filtered = _allCandidates;
    
    // Cinsiyet filtresi
    if (_genderFilter != null) {
      filtered = filtered.where((c) => c.user.gender == _genderFilter).toList();
    }
    
    // Aura uyumu filtresi
    if (_showOnlyCompatible) {
      filtered = filtered.where((c) => c.auraCompatibility > 0).toList();
    }
    
    return filtered;
  }

  void _toggleCompatibleFilter() {
    if (!mounted) return;
    setState(() {
      _showOnlyCompatible = !_showOnlyCompatible;
      _candidates = _filterCandidates();
      _index = 0; // İlk karta dön
      if (_candidates.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  Future<void> _showGenderFilterDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    const requiredKarma = 10;
    if (user.karma < requiredKarma) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.notEnoughKarma}. ${AppStrings.requiredKarma}: $requiredKarma ${AppStrings.karma}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    final selectedGender = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.filterByGender,
          style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.genderFilterDesc} (${AppStrings.requiredKarma}: $requiredKarma ${AppStrings.karma})',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                AppStrings.allGenders,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              leading: Radio<String?>(
                value: null,
                groupValue: _genderFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: Text(
                AppStrings.isEnglish ? 'Male' : 'Erkek',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              leading: Radio<String?>(
                value: 'male',
                groupValue: _genderFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: Text(
                AppStrings.isEnglish ? 'Female' : 'Kadın',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              leading: Radio<String?>(
                value: 'female',
                groupValue: _genderFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: Text(
                AppStrings.isEnglish ? 'Other' : 'Diğer',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              leading: Radio<String?>(
                value: 'other',
                groupValue: _genderFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    if (selectedGender == null) return; // İptal edildi

    // Karma kes
    final success = await userProvider.spendKarma(
      requiredKarma,
      AppStrings.genderFilterUsed,
    );

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.notEnoughKarma}. ${AppStrings.requiredKarma}: $requiredKarma ${AppStrings.karma}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _genderFilter = selectedGender;
      _genderFilterUsed = true;
      _candidates = _filterCandidates();
      _index = 0;
      if (_candidates.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.genderFilterUsed),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _calculateAuraCompatibility(UserModel a, UserModel b) {
    final aColor = a.preferences['auraColor']?.toString();
    final bColor = b.preferences['auraColor']?.toString();
    final aFreq = (a.preferences['auraFrequency'] as num?)?.toDouble() ?? 50.0;
    final bFreq = (b.preferences['auraFrequency'] as num?)?.toDouble() ?? 50.0;
    final aMood = a.preferences['auraMood']?.toString();
    final bMood = b.preferences['auraMood']?.toString();

    // Eğer aura rengi yoksa, sadece frekans uyumuna bak
    if (aColor == null || bColor == null) {
      final freqDiff = (aFreq - bFreq).abs();
      if (freqDiff < 15) return 20.0; // Frekans uyumu varsa uyumlu kabul et
      if (freqDiff < 25) return 15.0;
      return 0.0;
    }

    double score = 0;

    // Aura rengi uyumu (aynı renk = +35, uyumlu renkler = +20-25)
    if (aColor == bColor) {
      score += 35;
    } else {
      // Genişletilmiş uyumlu renk çiftleri
      // Note: Color names are stored in Turkish in database, but we check both
      final compatiblePairs = [
        ['Mor', 'Indigo', 'Pembe', 'Purple', 'Pink'], // Mor tonları
        ['Mavi', 'Turkuaz', 'Indigo', 'Blue', 'Turquoise'], // Mavi tonları
        ['Yeşil', 'Turkuaz', 'Mavi', 'Green', 'Blue'], // Yeşil-mavi tonları
        ['Sarı', 'Turuncu', 'Kırmızı', 'Yellow', 'Orange', 'Red'], // Sıcak tonlar
        ['Pembe', 'Kırmızı', 'Mor', 'Pink', 'Red', 'Purple'], // Pembe tonları
        ['Turuncu', 'Kırmızı', 'Sarı', 'Orange', 'Red', 'Yellow'], // Turuncu tonları
      ];
      
      bool isCompatible = false;
      int compatibilityLevel = 0;
      
      for (final pair in compatiblePairs) {
        final aIndex = pair.indexOf(aColor);
        final bIndex = pair.indexOf(bColor);
        
        if (aIndex != -1 && bIndex != -1) {
          isCompatible = true;
          // Aynı grupta ama farklı renkler
          final distance = (aIndex - bIndex).abs();
          if (distance == 0) {
            compatibilityLevel = 3; // Aynı renk (zaten yukarıda kontrol edildi)
          } else if (distance == 1) {
            compatibilityLevel = 2; // Çok yakın renkler
          } else {
            compatibilityLevel = 1; // Aynı grupta ama uzak
          }
          break;
        }
      }
      
      if (isCompatible) {
        if (compatibilityLevel == 2) {
          score += 25; // Çok uyumlu renkler
        } else if (compatibilityLevel == 1) {
          score += 20; // Uyumlu renkler
        }
      } else {
        // Uyumlu değilse ama yine de bazı kombinasyonlar kabul edilebilir
        // Örneğin: Mor-Mavi, Yeşil-Sarı gibi
        final neutralPairs = [
          ['Mor', 'Mavi', 'Purple', 'Blue'],
          ['Yeşil', 'Sarı', 'Green', 'Yellow'],
          ['Mavi', 'Yeşil', 'Blue', 'Green'],
        ];
        for (final pair in neutralPairs) {
          if (pair.contains(aColor) && pair.contains(bColor)) {
            score += 15; // Nötr uyum
            break;
          }
        }
      }
    }

    // Frekans uyumu (yakın frekanslar = +25, orta yakın = +15, uzak = +5)
    final freqDiff = (aFreq - bFreq).abs();
    if (freqDiff < 10) {
      score += 25; // Çok yakın frekanslar
    } else if (freqDiff < 20) {
      score += 15; // Yakın frekanslar
    } else if (freqDiff < 30) {
      score += 10; // Orta yakın frekanslar
    } else if (freqDiff < 40) {
      score += 5; // Biraz uzak ama kabul edilebilir
    }

    // Ruh hali uyumu (+15)
    if (aMood != null && bMood != null) {
      final positiveMoods = AppStrings.positiveMoods;
      final negativeMoods = AppStrings.negativeMoods;
      final neutralMoods = AppStrings.isEnglish 
          ? ['Normal', 'Balanced', 'Calm']
          : ['Normal', 'Dengeli', 'Sakin'];
      
      if ((positiveMoods.contains(aMood) && positiveMoods.contains(bMood)) ||
          (negativeMoods.contains(aMood) && negativeMoods.contains(bMood)) ||
          (neutralMoods.contains(aMood) && neutralMoods.contains(bMood))) {
        score += 15;
      } else if ((positiveMoods.contains(aMood) && neutralMoods.contains(bMood)) ||
                 (neutralMoods.contains(aMood) && positiveMoods.contains(bMood))) {
        score += 10; // Pozitif-nötr uyumu
      }
    }

    return score;
  }

  double _scoreUsers(UserModel a, UserModel b) {
    double score = 0;

    // Burç uyumu (30%)
    if (a.zodiacSign != null && b.zodiacSign != null) {
      if (a.zodiacSign == b.zodiacSign) {
        score += 30;
      } else {
        // Uyumlu burç çiftleri (basit mantık)
        score += 10;
      }
    }

    // Yaş uyumu (20%)
    if (a.birthDate != null && b.birthDate != null) {
      final ageDiff = (a.age - b.age).abs();
      if (ageDiff <= 2) {
        score += 20;
      } else if (ageDiff <= 5) {
        score += 15;
      } else if (ageDiff <= 10) {
        score += 10;
      }
    }

    // Aura uyumu (40%) - En önemli faktör
    score += _calculateAuraCompatibility(a, b);

    // Rastgele varyasyon (10%)
    score += Random().nextDouble() * 10;

    return score.clamp(0, 100);
  }

  void _next() {
    if (_index < _candidates.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _connectWith(_Candidate c) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final current = userProvider.user;
      if (current == null) throw Exception(AppStrings.sessionNotFound);
      final target = c.user;

      // Karma veya ücretsiz eşleşme kontrolü
      final auraMatchCost = PricingConstants.auraMatchCost;
      final freeMatches = current.freeAuraMatches;
      final isPremium = current.isPremium;
      
      // Premium kullanıcılar için sadece ücretsiz eşleşme hakkı kullanılabilir
      // Normal kullanıcılar için karma kontrolü yapılır
      final hasFreeMatch = isPremium && freeMatches > 0;
      final hasEnoughKarma = !isPremium && current.karma >= auraMatchCost;
      
      // Debug modunda premium kullanıcılar için ücretsiz eşleşme, normal kullanıcılar için karma kontrolü
      // UserProvider'da isPremium debug modunda true döndürüyor, bu yüzden gerçek premium kontrolü için
      // Firestore'dan gelen isPremium değerini kullanıyoruz (current.isPremium)
      final canConnect = hasFreeMatch || hasEnoughKarma;
      
      if (!canConnect) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.karmaRequired.replaceAll('{0}', auraMatchCost.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Aura uyumu kontrolü - _calculateAuraCompatibility fonksiyonunu kullan
      // Eğer aura uyum skoru 20'den fazlaysa uyumlu kabul et
      final auraCompatibilityScore = _calculateAuraCompatibility(current, target);
      final hasAuraCompatibility = auraCompatibilityScore >= 20.0;

      // Age-group safety: do not allow cross-age requests
      if (current.ageGroup != target.ageGroup) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.ageGroupMismatchError),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Zaten accepted match var mı?
      final existingMatchQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: target.id)
          .get();

      bool alreadyMatched = false;
      for (final doc in existingMatchQuery.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(current.id) && users.contains(target.id)) {
          alreadyMatched = true;
          break;
        }
      }

      if (alreadyMatched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.matchAlreadyExists),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Karşı taraftan gelen bekleyen istek var mı?
      final incomingRequest = await _firestore
          .collection('social_requests')
          .where('fromUserId', isEqualTo: target.id)
          .where('toUserId', isEqualTo: current.id)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (incomingRequest.docs.isNotEmpty) {
        final requestId = incomingRequest.docs.first.id;
        await _firestore.collection('social_requests').doc(requestId).update({
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _createMatchDocument(
          initiatorId: target.id,
          currentUser: current,
          targetUser: target,
          score: c.score,
          hasAuraCompatibility: hasAuraCompatibility,
        );

        if (!mounted) return;
        
        // Reklam göster
        _showInterstitialAd();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.matchAccepted} ${target.name}! ${AppStrings.matchEstablished}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Daha önce bu kullanıcıya gönderilmiş bekleyen istek var mı?
      final outgoingRequest = await _firestore
          .collection('social_requests')
          .where('fromUserId', isEqualTo: current.id)
          .where('toUserId', isEqualTo: target.id)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (outgoingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.requestAlreadySent),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      {
        // Yeni istek gönder - önce confirmation dialog göster
        final confirmed = await MysticalDialog.showConfirm(
          context: context,
          title: AppStrings.sendRequest,
          message: AppStrings.sendConnectionRequestTo.replaceAll('{0}', target.name),
          confirmText: AppStrings.confirm,
          cancelText: AppStrings.cancel,
          onConfirm: () async {
            try {
              // Dialog onayından sonra tekrar kontrol et (kullanıcı durumu değişmiş olabilir)
              final updatedUser = userProvider.user;
              if (updatedUser == null) {
                if (!mounted) return;
                await MysticalDialog.showError(
                  context: context,
                  title: AppStrings.errorOccurred,
                  message: AppStrings.sessionNotFound,
                );
                return;
              }
              
              final updatedFreeMatches = updatedUser.freeAuraMatches;
              final updatedIsPremium = updatedUser.isPremium;
              final updatedHasFreeMatch = updatedIsPremium && updatedFreeMatches > 0;
              final updatedHasEnoughKarma = !updatedIsPremium && updatedUser.karma >= auraMatchCost;
              
              if (!updatedHasFreeMatch && !updatedHasEnoughKarma) {
                if (!mounted) return;
                final errorMessage = updatedIsPremium 
                    ? AppStrings.noFreeMatchesLeft
                    : AppStrings.karmaRequired.replaceAll('{0}', auraMatchCost.toString());
                await MysticalDialog.showError(
                  context: context,
                  title: AppStrings.errorOccurred,
                  message: errorMessage,
                );
                return;
              }
              
              // Karma kes veya ücretsiz eşleşme kullan
              if (!kDebugMode) {
                if (updatedHasFreeMatch) {
                  // Ücretsiz eşleşme kullan
                  final success = await userProvider.useFreeAuraMatch();
                  if (!success) {
                    if (!mounted) return;
                    await MysticalDialog.showError(
                      context: context,
                      title: AppStrings.errorOccurred,
                      message: AppStrings.freeMatchNotAvailable,
                    );
                    return;
                  }
                } else {
                  // Karma kes
                  final success = await userProvider.spendKarma(
                    auraMatchCost,
                    'Aura eşleşmesi',
                  );
                  if (!success) {
                    if (!mounted) return;
                    await MysticalDialog.showError(
                      context: context,
                      title: AppStrings.errorOccurred,
                      message: AppStrings.notEnoughKarma,
                    );
                    return;
                  }
                }
              }
              
              await _firestore.collection('social_requests').add({
                'fromUserId': updatedUser.id,
                'toUserId': target.id,
                'status': 'pending',
                'score': c.score,
                'hasAuraCompatibility': hasAuraCompatibility,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              // Record quest completion for aura match
              try {
                final firebaseService = FirebaseService();
                final completedQuests = await firebaseService.getCompletedQuests(updatedUser.id);
                if (!completedQuests.contains('aura_match')) {
                  await firebaseService.recordQuestCompletion(updatedUser.id, 'aura_match');
                  // Add karma reward
                  final questReward = PricingConstants.getQuestById('aura_match')?['karma'] as int? ?? 2;
                  await userProvider.addKarma(
                    questReward,
                    'Görev tamamlandı: Aura eşleşmesi',
                  );
                }
              } catch (e) {
                // Quest completion error - silent fail
              }
              
              if (!mounted) return;
              
              // Reklam göster
              _showInterstitialAd();
              
              await MysticalDialog.showSuccess(
                context: context,
                title: AppStrings.requestSent,
                message: '${AppStrings.requestSent} ${target.name}!',
              );
            } catch (e) {
              if (!mounted) return;
              await MysticalDialog.showError(
                context: context,
                title: AppStrings.errorOccurred,
                message: '${AppStrings.connectionCouldNotBeEstablished} $e',
              );
            }
          },
        );
        
        // Eğer kullanıcı iptal ettiyse hiçbir şey yapma
        if (confirmed != true) return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.connectionCouldNotBeEstablished} $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? Center(child: MysticalLoading(type: MysticalLoadingType.crystal, message: AppStrings.searchingMatches))
                    : _error != null
                        ? Center(child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent)))
                        : _candidates.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _showOnlyCompatible
                                          ? AppStrings.noCompatiblePersonFound
                                          : AppStrings.noSuitableMatchFound,
                                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_showOnlyCompatible) ...[
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          _toggleCompatibleFilter();
                                        },
                                        child: Text(
                                          AppStrings.showAll,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : PageView.builder(
                                  controller: _pageController,
                                  scrollDirection: Axis.vertical,
                                  onPageChanged: (i) => setState(() => _index = i),
                                  itemCount: _candidates.length,
                                  itemBuilder: (ctx, i) {
                                    return Center(
                                      child: _candidateCard(_candidates[i], heightFactor: 0.68),
                                    );
                                  },
                                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: textColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.auraMatch,
                  style: AppTextStyles.headingLarge.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              // Ücretsiz eşleşme varsa göster, yoksa karma maliyeti göster
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  if (user == null) {
                    return const KarmaCostBadge(fortuneType: 'aura');
                  }
                  
                  final freeMatches = user.freeAuraMatches;
                  final isPremium = user.isPremium;
                  
                  if (isPremium && freeMatches > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.karmaGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.karma.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.karma.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.auraFreeMatches(freeMatches),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const KarmaCostBadge(fortuneType: 'aura');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cinsiyet filtresi butonu
          if (!_genderFilterUsed)
            GestureDetector(
              onTap: _showGenderFilterDialog,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppColors.modernCardDecoration.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.useGenderFilter,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.karma.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '10 ${AppStrings.karma}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.karma,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Aktif cinsiyet filtresi gösterimi
          if (_genderFilter != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppColors.modernCardDecoration.copyWith(
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _genderFilter == 'male' 
                        ? (AppStrings.isEnglish ? 'Male' : 'Erkek')
                        : _genderFilter == 'female'
                            ? (AppStrings.isEnglish ? 'Female' : 'Kadın')
                            : (AppStrings.isEnglish ? 'Other' : 'Diğer'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _genderFilter = null;
                        _candidates = _filterCandidates();
                        _index = 0;
                        if (_candidates.isNotEmpty && _pageController.hasClients) {
                          _pageController.jumpToPage(0);
                        }
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          // Uyumlu kişiyi bul filtresi
          GestureDetector(
            onTap: _toggleCompatibleFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppColors.modernCardDecoration.copyWith(
                color: _showOnlyCompatible
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surface.withValues(alpha: 0.4),
                border: Border.all(
                  color: _showOnlyCompatible
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (_showOnlyCompatible)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: -3,
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showOnlyCompatible ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showOnlyCompatible 
                        ? '${AppStrings.onlyCompatiblePeople} (${_candidates.length})'
                        : AppStrings.findCompatiblePerson,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateCard(_Candidate c, {double heightFactor = 0.7}) {
    final u = c.user;
    final h = MediaQuery.of(context).size.height * heightFactor;
    final auraColor = _getAuraColor(u);
    final auraColorName = u.preferences['auraColor']?.toString() ?? '—';
    final auraFrequency = (u.preferences['auraFrequency'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (auraColor ?? Colors.purple).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Animated aura glow background
            if (auraColor != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 2.0,
                      colors: [
                        auraColor.withValues(alpha: 0.3),
                        auraColor.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            // Animated border glow
            if (auraColor != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: auraColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Main card content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppColors.modernCardDecoration,
              height: h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and name
                  Row(
                    children: [
                      // Enhanced profile avatar with aura glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (auraColor ?? AppColors.primary).withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: (auraColor ?? AppColors.primary).withValues(alpha: 0.3),
                            ),
                            Positioned.fill(
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.surface.withValues(alpha: 0.9),
                                      AppColors.surface.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: AppTextStyles.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  u.zodiacSign ?? AppStrings.zodiacUnknown,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Enhanced compatibility badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: c.score >= 80
                              ? const LinearGradient(
                                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : c.score >= 60
                                  ? AppColors.karmaGradient
                                  : LinearGradient(
                                      colors: [Colors.orange.shade600, Colors.orange.shade800],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (c.score >= 80
                                      ? const Color(0xFF00E676)
                                      : c.score >= 60
                                          ? AppColors.karma
                                          : Colors.orange.shade700)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.score.toStringAsFixed(0),
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              AppStrings.percentCompatibility,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Enhanced aura info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppColors.modernCardDecoration.copyWith(
                      color: (auraColor ?? Colors.purple).withValues(alpha: 0.1),
                      border: Border.all(
                        color: (auraColor ?? Colors.purple).withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: (auraColor ?? Colors.purple).withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: auraColor ?? Colors.purple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (auraColor ?? Colors.purple).withValues(alpha: 0.7),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.auraEnergy,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auraColorName,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (auraFrequency != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: auraFrequency / 100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  (auraColor ?? Colors.purple).withValues(alpha: 0.8),
                                                  (auraColor ?? Colors.purple),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${auraFrequency.toStringAsFixed(0)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Enhanced action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _connectWith(c),
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.handshake, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.establishConnection,
                                      style: AppTextStyles.buttonLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _next,
                            borderRadius: BorderRadius.circular(16),
                            child: Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInterstitialAd() async {
    await _ads.createInterstitialAd(
      adUnitId: _ads.interstitialAdUnitId,
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _ads.createInterstitialAd(
              adUnitId: _ads.interstitialAdUnitId,
            );
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
          },
        );
        ad.show();
      },
      onAdFailedToLoad: (error) {
        if (kDebugMode) {
          print('❌ Interstitial ad failed to load: $error');
        }
      },
    );
  }
}

class _Candidate {
  final UserModel user;
  final double score;
  final double auraCompatibility;
  _Candidate({
    required this.user, 
    required this.score,
    required this.auraCompatibility,
  });
}



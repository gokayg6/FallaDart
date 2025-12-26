import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/utils/helpers.dart';
import 'soulmate_analysis_screen.dart';
import 'chat_detail_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _loading = true;
  List<_ChatMatch> _matches = [];
  List<_SocialRequest> _pendingRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    // ... (Keep existing logic, it's sound)
    try {
      final currentUser = Provider.of<UserProvider>(context, listen: false).user;
      if (currentUser == null) {
        if (mounted) setState(() { _error = AppStrings.userSessionNotFound; _loading = false; });
        return;
      }

      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.id)
          .orderBy('createdAt', descending: true)
          .get();

      final matches = <_ChatMatch>[];

      for (final matchDoc in matchesSnapshot.docs) {
        final data = matchDoc.data();
        final status = data['status']?.toString() ?? 'accepted';
        if (status == 'age_blocked' || status != 'accepted') continue;
        
        final users = List<String>.from(data['users'] ?? []);
        final otherUserId = users.firstWhere((id) => id != currentUser.id, orElse: () => '');
        if (otherUserId.isEmpty) continue;

        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (!otherUserDoc.exists) continue;

        final otherUser = UserModel.fromFirestore(otherUserDoc);
        if (currentUser.ageGroup != otherUser.ageGroup) continue;
        
        matches.add(_ChatMatch(
          matchId: matchDoc.id,
          user: otherUser,
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: status,
          isInitiator: false,
        ));
      }

      final requestsSnapshot = await _firestore
          .collection('social_requests')
          .where('toUserId', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final pendingRequests = <_SocialRequest>[];
      for (final requestDoc in requestsSnapshot.docs) {
        final requestData = requestDoc.data();
        final fromUserId = requestData['fromUserId']?.toString();
        if (fromUserId == null) continue;

        final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
        if (!fromUserDoc.exists) continue;

        final fromUser = UserModel.fromFirestore(fromUserDoc);
        pendingRequests.add(_SocialRequest(
          requestId: requestDoc.id,
          user: fromUser,
          score: (requestData['score'] as num?)?.toDouble() ?? 0.0,
          createdAt: (requestData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          hasAuraCompatibility: requestData['hasAuraCompatibility'] as bool? ?? false,
        ));
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _pendingRequests = pendingRequests;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${AppStrings.matchesCouldNotLoad} $e';
          _loading = false;
        });
      }
    }
  }

  // ... (Keep other logic methods like _acceptRequest, _rejectRequest, etc.)
  Future<void> _acceptRequest(_SocialRequest request) async {
     try {
      final currentUser = Provider.of<UserProvider>(context, listen: false).user;
      if (currentUser == null) return;

      await _firestore.collection('social_requests').doc(request.requestId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _createMatchIfNeeded(
        initiatorId: request.user.id,
        currentUser: currentUser,
        otherUser: request.user,
        score: request.score,
        hasAuraCompatibility: request.hasAuraCompatibility,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.matchAccepted} ${request.user.name}!'), backgroundColor: Colors.green));
      _loadMatches();
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _rejectRequest(_SocialRequest request) async {
    try {
      await _firestore.collection('social_requests').doc(request.requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _loadMatches();
    } catch (e) {}
  }
  
  Future<void> _createMatchIfNeeded({
    required String initiatorId,
    required UserModel currentUser,
    required UserModel otherUser,
    required double score,
    required bool hasAuraCompatibility,
  }) async {
    final existingMatches = await _firestore.collection('matches').where('users', arrayContains: currentUser.id).get();
    for (final doc in existingMatches.docs) {
      final users = List<String>.from(doc['users'] ?? []);
      if (users.contains(otherUser.id)) return;
    }
    await _firestore.collection('matches').add({
      'users': [currentUser.id, otherUser.id],
      'initiator': initiatorId,
      'status': 'accepted',
      'score': score,
      'hasAuraCompatibility': hasAuraCompatibility,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Force dark mode aesthetic for consistency with "Masterpiece Glass"
        // typically implies dark backgrounds with glowing elements
        final isDark = themeProvider.isDarkMode; 
        
        return Scaffold(
          backgroundColor: Colors.transparent, // Let main background show through
          body: Container(
             // Use a transparent container to just respect the parent gradient
            child: SafeArea(
              bottom: false, // Let navbar handle bottom
              child: Column(
                children: [
                   _buildHeader(isDark),
                   const SizedBox(height: 16),
                   _buildCustomGlassTabBar(isDark),
                   const SizedBox(height: 16),
                   Expanded(
                     child: TabBarView(
                       controller: _tabController,
                       children: [
                         _buildRequestsTab(isDark),
                         _buildChatTab(isDark),
                         _buildPrivacyTab(isDark),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.social,
                style: AppTextStyles.headingLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  shadows: isDark ? [
                    Shadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 12),
                  ] : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.discoverCompatibleSouls,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: (isDark ? Colors.white : AppColors.textPrimary).withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomGlassTabBar(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.primary : AppColors.aquaIndigo,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(text: AppStrings.requests),
          Tab(text: AppStrings.chat),
          Tab(text: AppStrings.privacy),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(bool isDark) {
    if (_loading) return Center(child: MysticalLoading(type: MysticalLoadingType.spinner));
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100), // Bottom padding for navbar
      children: [
        _buildAuraMatchCard(isDark),
        const SizedBox(height: 24),
        if (_pendingRequests.isNotEmpty) ...[
          Text(
            "${AppStrings.pendingRequests} (${_pendingRequests.length})",
            style: TextStyle(
              color: (isDark ? Colors.white : AppColors.textPrimary).withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.map((req) => _buildRequestItem(req, isDark)),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.getTextSecondary(isDark).withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz yeni istek yok",
                    style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatTab(bool isDark) {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.getTextSecondary(isDark).withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "Henüz bir sohbetin yok",
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMatchItem(_matches[index], isDark),
    );
  }

  Widget _buildPrivacyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100), // Bottom padding for navbar
      children: [
        _buildSettingsGlassCard(
          isDark: isDark,
          title: AppStrings.socialVisibilityTitle,
          content: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.socialVisibilityDesc,
                      style: TextStyle(color: (isDark ? Colors.white : AppColors.textPrimary).withOpacity(0.6), fontSize: 13),
                    ),
                  ),
                  Switch.adaptive(
                    value: userProvider.socialVisible,
                    activeColor: AppColors.primary,
                    onChanged: (val) => userProvider.updateSocialVisibility(val),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsGlassCard(
          isDark: isDark,
          title: "Engellenen Kullanıcılar",
          content: Text("Yönetmek için dokunun", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13)),
          onTap: () {
             // Show blocked users dialog or screen
          },
        ),
      ],
    );
  }

  Widget _buildAuraMatchCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.auto_awesome, size: 120, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text("PREMIUM", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.auraMatch,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ruh eşini bulmak için mistik analiz yap",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const SoulmateAnalysisScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppStrings.match.toUpperCase(),
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(_SocialRequest req, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
             radius: 24,
             backgroundColor: AppColors.primary.withOpacity(0.2),
             child: Text(req.user.name[0].toUpperCase(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.user.name,
                  style: TextStyle(color: (isDark ? Colors.white : AppColors.textPrimary), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "%${req.score.toInt()} Uyum",
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildActionButton(Icons.close, Colors.red, () => _rejectRequest(req)),
              const SizedBox(width: 8),
              _buildActionButton(Icons.check, Colors.green, () => _acceptRequest(req)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(_ChatMatch match, bool isDark) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(matchId: match.matchId, otherUser: match.user, score: match.score)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(match.user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.user.name,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sohbete başlamak için dokun",
                    style: TextStyle(color: (isDark ? Colors.white : AppColors.textPrimary).withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.getTextSecondary(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSettingsGlassCard({required bool isDark, required String title, required Widget content, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

class _ChatMatch {
  final String matchId;
  final UserModel user;
  final String? auraColor;
  final double? auraFrequency;
  final double score;
  final DateTime createdAt;
  final String status;
  final bool isInitiator;

  _ChatMatch({
    required this.matchId,
    required this.user,
    this.auraColor,
    this.auraFrequency,
    required this.score,
    required this.createdAt,
    required this.status,
    required this.isInitiator,
  });
}

class _SocialRequest {
  final String requestId;
  final UserModel user;
  final String? auraColor;
  final double? auraFrequency;
  final double score;
  final DateTime createdAt;
  final bool hasAuraCompatibility;

  _SocialRequest({
    required this.requestId,
    required this.user,
    this.auraColor,
    this.auraFrequency,
    required this.score,
    required this.createdAt,
    required this.hasAuraCompatibility,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../providers/theme_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserModel otherUser;
  final String matchId;
  final String? auraColor;
  final double? auraFrequency;
  final double score;

  const ChatDetailScreen({
    super.key,
    required this.otherUser,
    required this.matchId,
    this.auraColor,
    this.auraFrequency,
    required this.score,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = Provider.of<UserProvider>(context, listen: false).user;
      if (currentUser == null) return;

      // Yaş kısıtlaması kontrolü
      if (currentUser.ageGroup != widget.otherUser.ageGroup) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.chatBlockedByAge),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Match durumunu kontrol et
      final matchDoc = await _firestore.collection('matches').doc(widget.matchId).get();
      if (matchDoc.exists) {
        final matchData = matchDoc.data();
        final status = matchData?['status']?.toString();
        if (status == 'age_blocked') {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.chatBlockedByAge),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Chat ID oluştur (alfabetik sıralı, tutarlı olması için)
      final userIds = [currentUser.id, widget.otherUser.id]..sort();
      _chatId = '${userIds[0]}_${userIds[1]}';

      // Chat document'i var mı kontrol et, yoksa oluştur
      // get() çağrısı permission denied verebilir, bu durumda document yok demektir
      DocumentSnapshot? chatDoc;
      try {
        chatDoc = await _firestore.collection('chats').doc(_chatId).get();
      } catch (e) {
        // Permission denied veya document yok, yeni chat oluştur
        chatDoc = null;
      }
      
      if (chatDoc == null || !chatDoc.exists) {
        await _firestore.collection('chats').doc(_chatId).set({
          'users': userIds,
          'matchId': widget.matchId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Mesajı gönder
      await _firestore.collection('chats').doc(_chatId).collection('messages').add({
        'senderId': currentUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Chat'in lastMessageAt'ini güncelle (hata olsa bile mesaj gönderildi, sessizce devam et)
      try {
        // Sadece lastMessageAt'i güncelle (users array'ini değiştirme)
        await _firestore.collection('chats').doc(_chatId).update({
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // lastMessageAt güncellemesi başarısız olsa bile mesaj gönderildi, hata logla ama kullanıcıya gösterme
        print('Chat lastMessageAt update failed: $e');
      }

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.messageCouldNotBeSent} $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color? _parseColorFromName(String? name) {
    if (name == null) return null;
    final colorMap = {
      'Mor': const Color(0xFF9B59B6),
      'Mavi': const Color(0xFF3498DB),
      'Yeşil': const Color(0xFF2ECC71),
      'Sarı': const Color(0xFFF1C40F),
      'Turuncu': const Color(0xFFE67E22),
      'Kırmızı': const Color(0xFFE74C3C),
      'Pembe': const Color(0xFFE91E63),
      'Indigo': const Color(0xFF6C5CE7),
      'Turkuaz': const Color(0xFF1ABC9C),
    };
    return colorMap[name] ?? const Color(0xFF9B59B6);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (_isLoading || _chatId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
          child: Center(
            child: MysticalLoading(
              type: MysticalLoadingType.spinner,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final auraColor = _parseColorFromName(widget.auraColor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(auraColor),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: MysticalLoading(
                          type: MysticalLoadingType.spinner,
                          size: 32,
                          color: Colors.white,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white54),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.noMessagesYet,
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.sendYourFirstMessage,
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index].data() as Map<String, dynamic>;
                        final isMe = message['senderId'] == currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color? auraColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    final surfaceColor = AppColors.getSurface(isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surfaceColor.withValues(alpha: 0.9),
            surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: auraColor != null
                      ? RadialGradient(
                          colors: [
                            auraColor.withValues(alpha: 0.6),
                            auraColor.withValues(alpha: 0.2),
                          ],
                        )
                      : null,
                  color: auraColor ?? AppColors.primary,
                ),
              ),
              Positioned.fill(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    widget.otherUser.name.isNotEmpty
                        ? widget.otherUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.auraColor != null)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: auraColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.auraColor!,
                        style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '%${widget.score.toStringAsFixed(0)} ${AppStrings.compatibility}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textSecondaryColor.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['text'] as String? ?? '';
    final timestamp = message['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: Text(
                widget.otherUser.name.isNotEmpty
                    ? widget.otherUser.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.cardBackground.withValues(alpha: 0.8),
                          AppColors.cardBackground.withValues(alpha: 0.6),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
              child: Text(
                Provider.of<UserProvider>(context, listen: false).user?.name.isNotEmpty == true
                    ? Provider.of<UserProvider>(context, listen: false).user!.name[0].toUpperCase()
                    : 'S',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceColor.withValues(alpha: 0.9),
            AppColors.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = themeProvider.isDarkMode;
            final inputTextColor = AppColors.getInputTextColor(isDark);
            final inputHintColor = AppColors.getInputHintColor(isDark);
            final inputBgColor = isDark ? AppColors.cardBackground.withValues(alpha: 0.6) : Colors.grey[200]!;
            
            return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                      color: inputBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                      style: AppTextStyles.bodyMedium.copyWith(color: inputTextColor),
                  decoration: InputDecoration(
                    hintText: AppStrings.writeMessage,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: inputHintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
            );
          },
        ),
      ),
    );
  }
}


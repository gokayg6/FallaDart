import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../providers/theme_provider.dart';

class CoffeeFortuneReaderScreen extends StatelessWidget {
  final List<XFile> photos;
  final String name;
  final String relation;
  final String gender;
  final String topic;
  final String job;
  final Map<String, dynamic> reader; // 👈 SEÇİLEN FALCI

  const CoffeeFortuneReaderScreen({
    super.key,
    required this.photos,
    required this.name,
    required this.relation,
    required this.gender,
    required this.topic,
    required this.job,
    required this.reader,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Fal Gönderiliyor', style: TextStyle(color: AppColors.getTextPrimary(isDark))),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        children: [
          _userInfoCard(context),
          const SizedBox(height: 24),
          _readerInfoCard(context),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => _loadingDialog(ctx, reader: reader),
              );
              await Future.delayed(const Duration(seconds: 2));
              Navigator.of(context).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF24183F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
                      const SizedBox(height: 12),
                      const Text(
                        "Yorumunuz 'Fallarım' menüsüne eklendi!",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Fallarım bölümünden sonucunu görebilirsin.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        // Özel bir Fallarım ekranı varsa buraya yönlendirme ekleyebilirsin!
                      },
                      child: const Text("Tamam", style: TextStyle(color: Colors.amber)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text("Falı Gönder ve Sonucu Gör"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD26AFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text("Karma Kazan", style: TextStyle(color: Colors.amber)),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _userInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1D163C), const Color(0xFF30206A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person, color: Colors.white70),
            radius: 32,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelValue("Ad", name),
                _labelValue("İlişki", relation),
                _labelValue("Cinsiyet", gender),
                _labelValue("İş", job),
                if (topic != "-") _labelValue("Konu", topic),
                const SizedBox(height: 7),
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photos[i].path),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
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

  Widget _readerInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(reader["photo"]),
            radius: 33,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reader["name"],
                      style: const TextStyle(
                        color: Color(0xFFD26AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(width: 7),
                    ...List.generate(
                      reader["featuresEmoji"].length,
                      (j) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(reader["featuresEmoji"][j], style: const TextStyle(fontSize: 17)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reader["features"].join(" • "),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber[300], size: 17),
                    Text(
                      "${reader["rating"]}",
                      style: const TextStyle(color: Colors.amber, fontSize: 13.8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 7),
                    Text("(${reader["votes"]} oy)", style: const TextStyle(color: Colors.white38, fontSize: 12.5)),
                    const SizedBox(width: 10),
                    Icon(Icons.monetization_on, color: Colors.yellow[700], size: 18),
                    Text(
                      "${reader["karma"]} karma",
                      style: const TextStyle(color: Colors.yellow, fontSize: 12.9, fontWeight: FontWeight.w500),
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

  Widget _labelValue(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Text("$label: ",
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                )),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

Widget _loadingDialog(BuildContext ctx, {required Map<String, dynamic> reader}) {
  return Dialog(
    backgroundColor: Colors.white.withValues(alpha: 0.04),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 22),
          CircleAvatar(
            backgroundImage: AssetImage(reader["photo"]),
            radius: 38,
          ),
          const SizedBox(height: 10),
          Text(
            "${reader['name']} yorumun hazırlanıyor...",
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 20),
          MysticalLoading(
            type: MysticalLoadingType.spinner,
            size: 32,
            color: const Color(0xFFD26AFF),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

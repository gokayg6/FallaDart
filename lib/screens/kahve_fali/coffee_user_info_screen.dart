import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'coffee_fortune_reader_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/theme_provider.dart';

// Falcı listesi (sabit)
final List<Map<String, dynamic>> readers = [
  {
    "name": "Serpil",
    "photo": "assets/images/woman1.png",
    "features": ["Aşk", "İlişki", "Spiritüel"],
    "featuresEmoji": ["❤️", "💌", "🔮"],
    "rating": 4.9,
    "votes": 1320,
    "karma": 10,
  },
  {
    "name": "Aysel",
    "photo": "assets/images/woman2.png",
    "features": ["İlişki", "Kariyer"],
    "featuresEmoji": ["💌", "💼"],
    "rating": 4.8,
    "votes": 920,
    "karma": 15,
  },
  {
    "name": "Onur",
    "photo": "assets/images/man1.png",
    "features": ["Genel", "Sağlık", "Kariyer"],
    "featuresEmoji": ["🔮", "🍀", "📈"],
    "rating": 4.7,
    "votes": 530,
    "karma": 30,
  },
  {
    "name": "Baran",
    "photo": "assets/images/man2.png",
    "features": ["Kariyer", "Para"],
    "featuresEmoji": ["💼", "💰"],
    "rating": 4.6,
    "votes": 710,
    "karma": 10,
  },
];

class CoffeeUserInfoScreen extends StatefulWidget {
  final List<XFile> photos;
  const CoffeeUserInfoScreen({super.key, required this.photos});

  @override
  State<CoffeeUserInfoScreen> createState() => _CoffeeUserInfoScreenState();
}

class _CoffeeUserInfoScreenState extends State<CoffeeUserInfoScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime? _birthday;
  String? _relation;
  String? _gender;
  String? _job;
  int? _selectedReaderIndex;

  final List<Map<String, String>> relations = [
    {"label": "İlişkisi var", "emoji": "💑"},
    {"label": "İlişkisi yok", "emoji": "😶"},
    {"label": "Evli", "emoji": "💍"},
    {"label": "Karışık", "emoji": "🤯"},
    {"label": "Ayrılmış", "emoji": "💔"},
    {"label": "Platonik", "emoji": "🥺"},
    {"label": "Flört halinde", "emoji": "💬"},
    {"label": "Dul", "emoji": "🖤"},
  ];

  final List<Map<String, String>> genders = [
    {"label": "Kadın", "emoji": "👩"},
    {"label": "Erkek", "emoji": "👨"},
    {"label": "LGBT", "emoji": "🏳️‍🌈"},
  ];

  final List<Map<String, String>> jobs = [
    {"label": "Çalışıyor", "emoji": "💼"},
    {"label": "İşsiz", "emoji": "😕"},
    {"label": "Öğrenci", "emoji": "🎓"},
    {"label": "Emekli", "emoji": "👴"},
    {"label": "Serbest", "emoji": "🧑‍💻"},
    {"label": "Ev Hanımı", "emoji": "🏠"},
    {"label": "Yönetici", "emoji": "👔"},
    {"label": "Memur", "emoji": "🗂️"},
  ];

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: isDark 
          ? ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD26AFF),
            onPrimary: Colors.white,
            surface: Color(0xFF1B1449),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Color(0xFF130A28),
          ),
            )
          : ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFD26AFF),
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.grey[100],
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _showSelectMenu({
    required String title,
    required List<Map<String, String>> options,
    required String? selected,
    required Function(String) onSelected,
  }) async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SelectScreen(
          title: title,
          options: options,
          selected: selected,
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _showReaderMenu() async {
    final picked = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReaderSelectScreen(selectedIndex: _selectedReaderIndex),
      ),
    );
    if (picked != null) setState(() => _selectedReaderIndex = picked);
  }

  @override
  Widget build(BuildContext context) {
    final selectedReader = _selectedReaderIndex != null ? readers[_selectedReaderIndex!] : null;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bilgilerini Doldur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.isDarkMode;
              final inputTextColor = AppColors.getInputTextColor(isDark);
              final inputHintColor = AppColors.getInputHintColor(isDark);
              
              return Column(
        children: [
          _inputCard(
            child: TextField(
              controller: _nameCtrl,
                      style: TextStyle(color: inputTextColor),
                      decoration: InputDecoration(
                labelText: 'Adın',
                        labelStyle: TextStyle(color: inputHintColor),
                border: InputBorder.none,
                        prefixIcon: Icon(Icons.person, color: inputHintColor, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _inputCard(
            onTap: _selectBirthday,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.cake, color: inputHintColor, size: 22),
              title: Text(
                _birthday == null
                    ? "Doğum Tarihi"
                    : "${_birthday!.day}.${_birthday!.month}.${_birthday!.year}",
                style: TextStyle(
                          color: _birthday == null ? inputHintColor : inputTextColor,
                  fontSize: 15,
                ),
              ),
                      trailing: Icon(Icons.calendar_today, color: inputHintColor.withOpacity(0.7), size: 20),
                    ),
            ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          _inputCard(
            onTap: () => _showSelectMenu(
              title: "İlişki Durumu Seç",
              options: relations,
              selected: _relation,
              onSelected: (v) => setState(() => _relation = v),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_border, color: Colors.white38, size: 22),
              title: Text(
                _relation == null
                    ? "İlişki Durumu"
                    : "${relations.firstWhere((e) => e["label"] == _relation)["emoji"]} $_relation",
                style: TextStyle(
                  color: _relation == null ? Colors.white54 : Colors.white,
                  fontSize: 15,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
            ),
          ),
          const SizedBox(height: 15),
          _inputCard(
            onTap: () => _showSelectMenu(
              title: "Cinsiyet Seç",
              options: genders,
              selected: _gender,
              onSelected: (v) => setState(() => _gender = v),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wc, color: Colors.white38, size: 22),
              title: Text(
                _gender == null
                    ? "Cinsiyet"
                    : "${genders.firstWhere((e) => e["label"] == _gender)["emoji"]} $_gender",
                style: TextStyle(
                  color: _gender == null ? Colors.white54 : Colors.white,
                  fontSize: 15,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
            ),
          ),
          const SizedBox(height: 15),
          _inputCard(
            onTap: () => _showSelectMenu(
              title: "İş Durumu Seç",
              options: jobs,
              selected: _job,
              onSelected: (v) => setState(() => _job = v),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.work_outline, color: Colors.white38, size: 22),
              title: Text(
                _job == null
                    ? "İş Durumu"
                    : "${jobs.firstWhere((e) => e["label"] == _job)["emoji"]} $_job",
                style: TextStyle(
                  color: _job == null ? Colors.white54 : Colors.white,
                  fontSize: 15,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
            ),
          ),
          const SizedBox(height: 15),
          _inputCard(
            onTap: _showReaderMenu,
            child: selectedReader == null
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.psychology, color: Colors.white38, size: 22),
                    title: const Text(
                      "Falcı Seç",
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(selectedReader["photo"]),
                      radius: 16,
                    ),
                    title: Text(
                      "${selectedReader['name']}  •  ${selectedReader['features'].join(' • ')}",
                      style: const TextStyle(color: Color(0xFFD26AFF), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber[300], size: 15),
                        Text(
                          "${selectedReader['rating']} (${selectedReader['votes']} oy)",
                          style: const TextStyle(color: Colors.amber, fontSize: 12.3, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 7),
                        Icon(Icons.monetization_on, color: Colors.yellow[700], size: 15),
                        Text(
                          "${selectedReader['karma']} karma",
                          style: const TextStyle(color: Colors.yellow, fontSize: 12.2, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.check_circle, color: Color(0xFFD26AFF), size: 23),
                  ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              if (_nameCtrl.text.isNotEmpty &&
                  _birthday != null &&
                  _relation != null &&
                  _gender != null &&
                  _job != null &&
                  _selectedReaderIndex != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoffeeFortuneReaderScreen(
                      photos: widget.photos,
                      name: _nameCtrl.text,
                      relation: _relation!,
                      gender: _gender!,
                      topic: "-",
                      job: _job!,
                      reader: readers[_selectedReaderIndex!], // SEÇİLEN FALCI
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.arrow_forward_ios),
            label: Text(AppStrings.continue_),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD26AFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _inputCard({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: child,
      ),
    );
  }
}

// Falcı seçim ekranı (tam ekran)
class ReaderSelectScreen extends StatelessWidget {
  final int? selectedIndex;
  const ReaderSelectScreen({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        title: Text("Falcı Seç", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: ListView.builder(
        itemCount: readers.length,
        itemBuilder: (ctx, i) {
          final r = readers[i];
          final isSel = selectedIndex == i;
          return GestureDetector(
            onTap: () => Navigator.pop(context, i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? Color(0xFFD26AFF).withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? Color(0xFFD26AFF) : Colors.transparent,
                  width: isSel ? 1.8 : 0.8,
                ),
                boxShadow: isSel
                    ? [BoxShadow(color: Color(0xFFD26AFF).withValues(alpha: 0.16), blurRadius: 16)]
                    : [],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(r["photo"]),
                    radius: 30,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              r["name"],
                              style: TextStyle(
                                color: isSel ? Color(0xFFD26AFF) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ...List.generate(
                              r["featuresEmoji"].length,
                              (j) => Text(
                                r["featuresEmoji"][j],
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          r["features"].join(" • "),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber[300], size: 18),
                            Text(
                              "${r["rating"]}",
                              style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text("(${r["votes"]} oy)", style: const TextStyle(color: Colors.white38, fontSize: 13)),
                            const SizedBox(width: 12),
                            Icon(Icons.monetization_on, color: Colors.yellow[700], size: 18),
                            Text(
                              "${r["karma"]} karma",
                              style: const TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSel)
                    const Icon(Icons.check_circle, color: Color(0xFFD26AFF), size: 26)
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

// Tam ekran seçim menüsü (ilişki, cinsiyet, iş)
class _SelectScreen extends StatelessWidget {
  final String title;
  final List<Map<String, String>> options;
  final String? selected;
  const _SelectScreen({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: ListView(
        children: options.map((e) {
          bool sel = selected == e["label"];
          return ListTile(
            leading: Text(e["emoji"] ?? "", style: const TextStyle(fontSize: 22)),
            title: Text(
              e["label"] ?? "",
              style: TextStyle(
                color: sel ? Color(0xFFD26AFF) : textColor,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: sel
                ? const Icon(Icons.check, color: Color(0xFFD26AFF))
                : null,
            onTap: () => Navigator.pop(context, e["label"]),
          );
        }).toList(),
      ),
      ),
    );
  }
}

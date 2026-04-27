// Themed avatar picker — lets users choose from multiple DiceBear styles.
// Each "theme" uses a different DiceBear style with vibrant backgrounds.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Available avatar themes using DiceBear API styles.
class AvatarTheme {
  final String name;
  final String style;
  final IconData icon;
  final Color color;
  final String bgColors;

  const AvatarTheme({
    required this.name,
    required this.style,
    required this.icon,
    required this.color,
    this.bgColors = 'b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf',
  });

  /// Generate a DiceBear avatar URL for this theme with the given seed.
  String generateUrl(String seed) {
    final encoded = Uri.encodeComponent(seed);
    return 'https://api.dicebear.com/9.x/$style/png'
        '?seed=$encoded&backgroundColor=$bgColors&size=200';
  }
}

/// All available avatar themes.
const List<AvatarTheme> kAvatarThemes = [
  AvatarTheme(
    name: 'Adventurer',
    style: 'adventurer',
    icon: Icons.explore_rounded,
    color: AppTheme.electricBlue,
  ),
  AvatarTheme(
    name: 'Pixel Hero',
    style: 'pixel-art',
    icon: Icons.grid_view_rounded,
    color: AppTheme.neonGreen,
  ),
  AvatarTheme(
    name: 'Lorelei',
    style: 'lorelei',
    icon: Icons.face_rounded,
    color: AppTheme.radiantPink,
  ),
  AvatarTheme(
    name: 'Notionist',
    style: 'notionists',
    icon: Icons.draw_rounded,
    color: AppTheme.vividOrange,
  ),
  AvatarTheme(
    name: 'Big Smile',
    style: 'big-smile',
    icon: Icons.emoji_emotions_rounded,
    color: Color(0xFFFFD700),
  ),
  AvatarTheme(
    name: 'Thumbs',
    style: 'thumbs',
    icon: Icons.thumb_up_rounded,
    color: Color(0xFF9C27B0),
  ),
  AvatarTheme(
    name: 'Micah',
    style: 'micah',
    icon: Icons.palette_rounded,
    color: Color(0xFF00BCD4),
  ),
  AvatarTheme(
    name: 'Bottts',
    style: 'bottts',
    icon: Icons.smart_toy_rounded,
    color: Color(0xFF4CAF50),
  ),
  AvatarTheme(
    name: 'Fun Emoji',
    style: 'fun-emoji',
    icon: Icons.mood_rounded,
    color: Color(0xFFFF5722),
    bgColors: 'b6e3f4,c0aede,ffd5dc,ffdfbf,d1f4e0',
  ),
];

/// Shows a bottom sheet dialog where the user can pick an avatar theme
/// and seed variation variant. Returns the chosen avatar URL or null.
Future<String?> showAvatarPicker({
  required BuildContext context,
  required String seed,
  String? currentUrl,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AvatarPickerSheet(seed: seed, currentUrl: currentUrl),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  final String seed;
  final String? currentUrl;

  const _AvatarPickerSheet({required this.seed, this.currentUrl});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late int _selectedThemeIndex;
  late int _selectedVariant;
  final int _variantCount = 6;

  @override
  void initState() {
    super.initState();
    _selectedThemeIndex = 0;
    _selectedVariant = 0;

    // Try to detect current theme from URL
    if (widget.currentUrl != null) {
      for (int i = 0; i < kAvatarThemes.length; i++) {
        if (widget.currentUrl!.contains('/${kAvatarThemes[i].style}/')) {
          _selectedThemeIndex = i;
          break;
        }
      }
    }
  }

  String _seedForVariant(int variant) {
    if (variant == 0) return widget.seed;
    return '${widget.seed}_v$variant';
  }

  String get _selectedUrl {
    return kAvatarThemes[_selectedThemeIndex].generateUrl(
      _seedForVariant(_selectedVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = kAvatarThemes[_selectedThemeIndex];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.glassBorder),
          left: BorderSide(color: AppTheme.glassBorder),
          right: BorderSide(color: AppTheme.glassBorder),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.face_rounded, color: theme.color, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Selected avatar preview
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.accentGradient,
                    boxShadow: AppTheme.glow(theme.color, blur: 20, spread: 2),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppTheme.bgPrimary,
                    backgroundImage: NetworkImage(_selectedUrl),
                  ),
                ),
              ),

              Text(
                theme.name,
                style: TextStyle(
                  color: theme.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Theme styles horizontal list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'STYLE',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  controller: scrollCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kAvatarThemes.length,
                  itemBuilder: (_, i) {
                    final t = kAvatarThemes[i];
                    final isSelected = i == _selectedThemeIndex;
                    final url = t.generateUrl(
                      _seedForVariant(_selectedVariant),
                    );
                    return GestureDetector(
                      onTap: () => setState(() => _selectedThemeIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? t.color : AppTheme.glassBorder,
                            width: isSelected ? 2 : 1,
                          ),
                          color:
                              isSelected
                                  ? t.color.withValues(alpha: 0.1)
                                  : AppTheme.glassWhite,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.bgPrimary,
                              backgroundImage: NetworkImage(url),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.name,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? t.color
                                        : AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Variants
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VARIATION',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _variantCount,
                  itemBuilder: (_, i) {
                    final url = kAvatarThemes[_selectedThemeIndex].generateUrl(
                      _seedForVariant(i),
                    );
                    final isSelected = i == _selectedVariant;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedVariant = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? theme.color : AppTheme.glassBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.bgPrimary,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // Confirm button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppTheme.accentGradient,
                      boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _selectedUrl),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Use This Avatar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

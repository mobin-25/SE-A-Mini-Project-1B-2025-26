import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool voiceEnabled = true;
  double textSize = 18;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      voiceEnabled         = prefs.getBool('voice_enabled') ?? true;
      textSize             = prefs.getDouble('text_size')   ?? 18;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', notificationsEnabled);
    await prefs.setBool('voice_enabled', voiceEnabled);
    await prefs.setDouble('text_size', textSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
              const SizedBox(height: 4),
              const Text("Customize your experience", style: TextStyle(fontSize: 14, color: kTextGrey)),
              const SizedBox(height: 28),

              _SectionLabel("Preferences"),
              const SizedBox(height: 12),

              _ToggleTile(
                icon: Icons.notifications_rounded,
                color: const Color(0xFFF39C12),
                title: "Notifications",
                subtitle: "Receive medication reminders",
                value: notificationsEnabled,
                onChanged: (v) { setState(() => notificationsEnabled = v); _save(); },
              ),
              const SizedBox(height: 10),
              _ToggleTile(
                icon: Icons.record_voice_over_rounded,
                color: const Color(0xFF16A085),
                title: "Voice Feedback",
                subtitle: "Speak status updates aloud",
                value: voiceEnabled,
                onChanged: (v) { setState(() => voiceEnabled = v); _save(); },
              ),

              const SizedBox(height: 24),
              _SectionLabel("Accessibility"),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.text_fields_rounded, color: kPrimary, size: 22)),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Text Size", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextDark)),
                            Text("Adjust for readability", style: TextStyle(fontSize: 12, color: kTextGrey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("A", style: TextStyle(fontSize: 14, color: kTextGrey)),
                        Expanded(
                          child: Slider(
                            value: textSize,
                            min: 14,
                            max: 28,
                            divisions: 7,
                            activeColor: kPrimary,
                            onChanged: (v) { setState(() => textSize = v); _save(); },
                          ),
                        ),
                        const Text("A", style: TextStyle(fontSize: 22, color: kTextGrey, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Center(child: Text("Sample Text", style: TextStyle(fontSize: textSize, color: kTextDark, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionLabel("About"),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    _AboutRow(Icons.info_rounded, "App Version", "1.0.0"),
                    const Divider(height: 24),
                    _AboutRow(Icons.privacy_tip_rounded, "Privacy", "Your data stays on device"),
                    const Divider(height: 24),
                    _AboutRow(Icons.favorite_rounded, "Made with", "❤️ for seniors"),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextGrey, letterSpacing: 0.8));
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextDark)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextGrey)),
          ])),
          Switch(value: value, onChanged: onChanged, activeColor: kPrimary),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AboutRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kTextGrey, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextDark)),
      ],
    );
  }
}
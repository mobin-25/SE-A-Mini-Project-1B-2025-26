import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kSuccess  = Color(0xFF27AE60);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  bool diabetes = false;
  bool bp = false;
  bool heart = false;
  List<String> customConditions = [];
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      diabetes = prefs.getBool("diabetes") ?? false;
      bp       = prefs.getBool("bp")       ?? false;
      heart    = prefs.getBool("heart")    ?? false;
      customConditions = prefs.getStringList("custom_conditions") ?? [];
    });

    // Optionally sync from AppProvider if it's there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<AppProvider>().profile;
      if (profile != null) {
        setState(() {
          diabetes = profile.diabetes;
          bp = profile.bp;
          heart = profile.heart;
          customConditions = profile.customConditions;
        });
      }
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("diabetes", diabetes);
    await prefs.setBool("bp",       bp);
    await prefs.setBool("heart",    heart);
    await prefs.setStringList("custom_conditions", customConditions);

    final uid = AuthService.uid;
    if (uid != null) {
      await FirebaseService.updateProfile(uid, {
        'diabetes': diabetes,
        'bp': bp,
        'heart': heart,
        'customConditions': customConditions,
      });
      if (mounted) {
        context.read<AppProvider>().updateHealth(diabetes: diabetes, bp: bp, heart: heart);
      }
    }

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _saved = false); });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kSuccess,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text("Health profile saved!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  int get activeConditions => [diabetes, bp, heart].where((v) => v).length + customConditions.length;

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

              // ── Header ────────────────────────────────────────────────
              const Text("Health Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
              const SizedBox(height: 4),
              const Text("Track your medical conditions", style: TextStyle(fontSize: 14, color: kTextGrey)),

              const SizedBox(height: 24),

              // ── Summary Banner ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D7DD2), Color(0xFF5BA4E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeConditions == 0 ? "No conditions recorded" : "$activeConditions Condition${activeConditions > 1 ? 's' : ''} Tracked",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Keep this updated for emergencies",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text("Medical Conditions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
              const SizedBox(height: 14),

              // ── Condition Cards ────────────────────────────────────────
              _ConditionCard(
                icon: Icons.water_drop_rounded,
                title: "Diabetes",
                description: "Blood sugar management",
                color: const Color(0xFFE67E22),
                value: diabetes,
                onChanged: (v) => setState(() => diabetes = v),
              ),
              const SizedBox(height: 12),
              _ConditionCard(
                icon: Icons.favorite_rounded,
                title: "Blood Pressure",
                description: "Hypertension or hypotension",
                color: const Color(0xFFE74C3C),
                value: bp,
                onChanged: (v) => setState(() => bp = v),
              ),
              const SizedBox(height: 12),
              _ConditionCard(
                icon: Icons.monitor_heart_rounded,
                title: "Heart Condition",
                description: "Cardiac or cardiovascular issues",
                color: const Color(0xFF8E44AD),
                value: heart,
                onChanged: (v) => setState(() => heart = v),
              ),

              const SizedBox(height: 24),

              // ── Custom Conditions ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Additional Conditions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showAddConditionDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded, color: kPrimary, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

              if (customConditions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    "No custom conditions added yet",
                    style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      for (int i = 0; i < customConditions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomConditionCard(
                            condition: customConditions[i],
                            onRemove: () => setState(() => customConditions.removeAt(i)),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // ── Save Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? kSuccess : kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      key: ValueKey(_saved),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_saved ? Icons.check_rounded : Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _saved ? "Saved!" : "Save Profile",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddConditionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Condition"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "e.g., Asthma, Arthritis, Allergy",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final condition = controller.text.trim();
              if (condition.isNotEmpty && !customConditions.contains(condition)) {
                setState(() => customConditions.add(condition));
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConditionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.08) : kCard,
          border: Border.all(color: value ? color.withOpacity(0.4) : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: value ? color.withOpacity(0.15) : const Color(0xFFF0F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: value ? color : const Color(0xFFB0BEC5), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: value ? color : kTextDark)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 12, color: kTextGrey)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                border: Border.all(color: value ? color : const Color(0xFFCDD5DE), width: 2),
                shape: BoxShape.circle,
              ),
              child: value ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomConditionCard extends StatelessWidget {
  final String condition;
  final VoidCallback onRemove;

  const _CustomConditionCard({
    required this.condition,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        border: Border.all(color: const Color(0xFFE8EDF5), width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, color: const Color(0xFFE74C3C).withOpacity(0.7), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Multi-step onboarding flow with glassmorphic design, gradient accents,
// neon progress bar, and animated transitions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  late final AnimationController _progressAnim;

  // Step 1: Personal details
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _gender = 'Male';
  String? _bloodGroup;

  // Step 2: Body measurements
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergPhoneCtrl = TextEditingController();

  // Step 3: Health conditions
  final Set<String> _selectedConditions = {};
  final _customConditionCtrl = TextEditingController();

  // Step 4: Allergies
  final Set<String> _selectedAllergies = {};
  final _customAllergyCtrl = TextEditingController();

  // Accent per step
  static const _stepAccents = [
    AppTheme.electricBlue,
    AppTheme.neonGreen,
    AppTheme.vividOrange,
    AppTheme.radiantPink,
  ];

  static const _stepIcons = [
    Icons.person_rounded,
    Icons.monitor_heart_rounded,
    Icons.local_hospital_rounded,
    Icons.warning_amber_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _emergNameCtrl.dispose();
    _emergPhoneCtrl.dispose();
    _customConditionCtrl.dispose();
    _customAllergyCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name to continue'),
          backgroundColor: AppTheme.radiantPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
      gender: _gender,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      bloodGroup: _bloodGroup,
      height: double.tryParse(_heightCtrl.text.trim()),
      weight: double.tryParse(_weightCtrl.text.trim()),
      emergencyContactName:
          _emergNameCtrl.text.trim().isNotEmpty
              ? _emergNameCtrl.text.trim()
              : null,
      emergencyContactPhone:
          _emergPhoneCtrl.text.trim().isNotEmpty
              ? _emergPhoneCtrl.text.trim()
              : null,
      healthConditions: _selectedConditions.toList(),
      allergies: _selectedAllergies.toList(),
      onboardingComplete: true,
    );
    await ref.read(profileProvider.notifier).updateProfile(profile);
    widget.onComplete();
  }

  Color get _accent => _stepAccents[_currentPage];

  @override
  Widget build(BuildContext context) {
    final stepLabels = [
      'Personal Info',
      'Body & Emergency',
      'Health Conditions',
      'Allergies',
    ];
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading:
              _currentPage > 0
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _back,
                  )
                  : null,
          title: Row(
            children: [
              Icon(_stepIcons[_currentPage], color: _accent, size: 22),
              const SizedBox(width: 8),
              Text(stepLabels[_currentPage]),
            ],
          ),
          actions: [
            if (_currentPage >= 2)
              TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // --- Neon progress bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  final done = i <= _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient:
                            done
                                ? LinearGradient(
                                  colors: [
                                    _stepAccents[i],
                                    i < _totalPages - 1
                                        ? _stepAccents[i + 1]
                                        : _stepAccents[i],
                                  ],
                                )
                                : null,
                        color: done ? null : AppTheme.glassWhite,
                        boxShadow:
                            done
                                ? [
                                  BoxShadow(
                                    color: _stepAccents[i].withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Text(
              'Step ${_currentPage + 1} of $_totalPages',
              style: TextStyle(color: _accent, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalPage(),
                  _buildBodyPage(),
                  _buildConditionsPage(),
                  _buildAllergiesPage(),
                ],
              ),
            ),
            // Continue button with gradient
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        _accent,
                        _currentPage < _totalPages - 1
                            ? _stepAccents[_currentPage + 1]
                            : AppTheme.electricBlue,
                      ],
                    ),
                    boxShadow: AppTheme.glow(_accent, blur: 16),
                  ),
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage < _totalPages - 1
                          ? 'Continue'
                          : 'Get Started',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Page 1: Personal Info ---
  Widget _buildPersonalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.person_rounded,
            AppTheme.electricBlue,
            'Tell us about yourself',
            'We\'ll personalize your health experience',
          ),
          const SizedBox(height: 24),
          _label('Full Name *'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Age'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Age',
                        prefixIcon: Icon(
                          Icons.cake_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Gender'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          dropdownColor: AppTheme.bgSecondary,
                          items:
                              ['Male', 'Female', 'Other']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _gender = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Blood Group'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                kBloodGroups.map((bg) {
                  final sel = _bloodGroup == bg;
                  return ChoiceChip(
                    label: Text(bg),
                    selected: sel,
                    onSelected: (_) => setState(() => _bloodGroup = bg),
                    selectedColor: AppTheme.electricBlue,
                    backgroundColor: AppTheme.glassWhite,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            sel ? AppTheme.electricBlue : AppTheme.glassBorder,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          _label('Phone'),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Phone number',
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Email'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email address',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 2: Body & Emergency ---
  Widget _buildBodyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.monitor_heart_rounded,
            AppTheme.neonGreen,
            'Body Measurements',
            'Used for BMI and health insights',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Height (cm)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 170'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Weight (kg)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 70'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _header(
            Icons.emergency_rounded,
            AppTheme.radiantPink,
            'Emergency Contact',
            'In case of medical emergency',
          ),
          const SizedBox(height: 16),
          _label('Contact Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _emergNameCtrl,
            decoration: const InputDecoration(
              hintText: 'Emergency contact name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Contact Phone'),
          const SizedBox(height: 6),
          TextField(
            controller: _emergPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Emergency contact phone',
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 3: Health Conditions ---
  Widget _buildConditionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.local_hospital_rounded,
            AppTheme.vividOrange,
            'Health Conditions',
            'Select any conditions you have (optional)',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                kCommonConditions.map((c) {
                  final sel = _selectedConditions.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: sel,
                    onSelected:
                        (s) => setState(() {
                          s
                              ? _selectedConditions.add(c)
                              : _selectedConditions.remove(c);
                        }),
                    selectedColor: AppTheme.vividOrange.withValues(alpha: 0.3),
                    backgroundColor: AppTheme.glassWhite,
                    checkmarkColor: AppTheme.vividOrange,
                    labelStyle: TextStyle(
                      color:
                          sel ? AppTheme.vividOrange : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            sel ? AppTheme.vividOrange : AppTheme.glassBorder,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customConditionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add custom condition...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glow(AppTheme.vividOrange, blur: 10),
                ),
                child: IconButton(
                  onPressed: () {
                    final v = _customConditionCtrl.text.trim();
                    if (v.isNotEmpty) {
                      setState(() => _selectedConditions.add(v));
                      _customConditionCtrl.clear();
                    }
                  },
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.vividOrange,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedConditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.vividOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_selectedConditions.length}',
                    style: const TextStyle(
                      color: AppTheme.vividOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Page 4: Allergies ---
  Widget _buildAllergiesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.warning_amber_rounded,
            AppTheme.radiantPink,
            'Allergies',
            'Select any known allergies (optional)',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                kCommonAllergies.map((a) {
                  final sel = _selectedAllergies.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: sel,
                    onSelected:
                        (s) => setState(() {
                          s
                              ? _selectedAllergies.add(a)
                              : _selectedAllergies.remove(a);
                        }),
                    selectedColor: AppTheme.radiantPink.withValues(alpha: 0.3),
                    backgroundColor: AppTheme.glassWhite,
                    checkmarkColor: AppTheme.radiantPink,
                    labelStyle: TextStyle(
                      color:
                          sel ? AppTheme.radiantPink : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            sel ? AppTheme.radiantPink : AppTheme.glassBorder,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customAllergyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add custom allergy...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glow(AppTheme.radiantPink, blur: 10),
                ),
                child: IconButton(
                  onPressed: () {
                    final v = _customAllergyCtrl.text.trim();
                    if (v.isNotEmpty) {
                      setState(() => _selectedAllergies.add(v));
                      _customAllergyCtrl.clear();
                    }
                  },
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.radiantPink,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedAllergies.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.radiantPink,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_selectedAllergies.length}',
                    style: const TextStyle(
                      color: AppTheme.radiantPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(IconData icon, Color accent, String title, String subtitle) {
    return GlassCard(
      borderColor: accent.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.glow(accent, blur: 12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 14),
  );
}

/// Symptom Checker — glassmorphic symptom chips, gradient result cards,
/// accent-colored icons, nebula background.
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/nebula_background.dart';
import '../widgets/glass_card.dart';

const Map<String, List<String>> kSymptomToMedicineMap = {
  'Fever': ['Paracetamol (e.g., Crocin, Tylenol)', 'Ibuprofen (e.g., Advil)'],
  'Headache': ['Aspirin', 'Ibuprofen', 'Paracetamol'],
  'Cough': ['Dextromethorphan (Cough Syrup)', 'Honey & Lozenges'],
  'Sore Throat': ['Lozenges (e.g., Strepsils)', 'Salt Water Gargle'],
  'Stomach Ache': ['Antacids (e.g., Digene, Tums)', 'Pepto-Bismol'],
  'Nausea': ['Ondansetron', 'Ginger supplements'],
  'Allergies': ['Cetirizine (e.g., Zyrtec)', 'Loratadine (e.g., Claritin)'],
  'Body Ache': ['Ibuprofen', 'Acetaminophen'],
};

const _symptomIcons = <String, IconData>{
  'Fever': Icons.thermostat_rounded,
  'Headache': Icons.psychology_rounded,
  'Cough': Icons.air_rounded,
  'Sore Throat': Icons.mic_off_rounded,
  'Stomach Ache': Icons.sick_rounded,
  'Nausea': Icons.sentiment_dissatisfied_rounded,
  'Allergies': Icons.spa_rounded,
  'Body Ache': Icons.accessibility_new_rounded,
};

const _chipAccents = [
  AppTheme.electricBlue,
  AppTheme.neonGreen,
  AppTheme.vividOrange,
  AppTheme.radiantPink,
];

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selectedSymptoms = {};
  List<String> _suggestedMedicines = [];

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
      _updateSuggestions();
    });
  }

  void _updateSuggestions() {
    final suggestions = <String>{};
    for (final symptom in _selectedSymptoms) {
      if (kSymptomToMedicineMap.containsKey(symptom)) {
        suggestions.addAll(kSymptomToMedicineMap[symptom]!);
      }
    }
    _suggestedMedicines = suggestions.toList();
  }

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Symptom Checker'),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disclaimer
                GlassCard(
                  borderColor: AppTheme.electricBlue.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.electricBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Disclaimer: These are OTC suggestions only. Consult a doctor for severe symptoms.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section title
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.radiantPink,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: AppTheme.glow(AppTheme.radiantPink, blur: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'WHAT ARE YOU FEELING?',
                      style: TextStyle(
                        color: AppTheme.radiantPink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Symptom chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      kSymptomToMedicineMap.keys.toList().asMap().entries.map((
                        e,
                      ) {
                        final idx = e.key;
                        final symptom = e.value;
                        final isSelected = _selectedSymptoms.contains(symptom);
                        final accent = _chipAccents[idx % _chipAccents.length];
                        final icon =
                            _symptomIcons[symptom] ??
                            Icons.help_outline_rounded;
                        return GestureDetector(
                          onTap: () => _toggleSymptom(symptom),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? accent.withValues(alpha: 0.2)
                                      : AppTheme.glassWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected ? accent : AppTheme.glassBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? AppTheme.glow(accent, blur: 8)
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  color:
                                      isSelected
                                          ? accent
                                          : AppTheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  symptom,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? accent
                                            : AppTheme.textSecondary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 28),

                // Results
                if (_selectedSymptoms.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: AppTheme.glow(AppTheme.neonGreen, blur: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SUGGESTED MEDICINES',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_suggestedMedicines.isEmpty)
                    const Text(
                      'No specific suggestions found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    ...List.generate(_suggestedMedicines.length, (i) {
                      final accent = _chipAccents[i % _chipAccents.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x28FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  boxShadow: AppTheme.glow(accent, blur: 6),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.medication_rounded,
                                      color: accent,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    _suggestedMedicines[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.health_and_safety_rounded,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Select your symptoms above\nto see suggested relief.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

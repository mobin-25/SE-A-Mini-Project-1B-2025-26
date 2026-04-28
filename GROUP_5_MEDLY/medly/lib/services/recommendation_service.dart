import '../db/database_helper.dart';
import '../models/disease.dart';
import '../models/medicine.dart';

class RecommendationResult {
  final Disease disease;
  final double score;
  final List<Medicine> medicines;

  RecommendationResult({
    required this.disease,
    required this.score,
    required this.medicines,
  });
}

class RecommendationService {
  final _db = DatabaseHelper.instance;

  Future<List<RecommendationResult>> recommend(List<int> selectedSymptomIds) async {
    if (selectedSymptomIds.isEmpty) return [];

    // Step 1: Get all diseases
    final diseaseRows = await _db.queryAll('diseases');
    final diseases = diseaseRows.map((d) => Disease.fromMap(d)).toList();

    // Step 2: Score each disease
    List<RecommendationResult> results = [];

    for (final disease in diseases) {
      double score = 0.0;

      for (final symptomId in selectedSymptomIds) {
        final rows = await _db.rawQuery('''
          SELECT weight FROM disease_symptoms
          WHERE disease_id = ? AND symptom_id = ?
        ''', [disease.id, symptomId]);

        if (rows.isNotEmpty) {
          score += rows.first['weight'] as double;
        }
      }

      if (score > 0) {
        // Step 3: Get recommended medicines for this disease
        final medRows = await _db.rawQuery('''
          SELECT m.*, md.effectiveness_score
          FROM medicines m
          JOIN medicine_disease md ON m.medicine_id = md.medicine_id
          WHERE md.disease_id = ?
          ORDER BY md.effectiveness_score DESC
        ''', [disease.id]);

        final medicines = medRows.map((m) => Medicine.fromMap(m)).toList();

        results.add(RecommendationResult(
          disease: disease,
          score: score,
          medicines: medicines,
        ));
      }
    }

    // Sort by highest score
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
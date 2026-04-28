import '../db/database_helper.dart';
import '../models/drug_interaction.dart';

class InteractionResult {
  final String medicine1;
  final String medicine2;
  final String severity;
  final String description;

  InteractionResult({
    required this.medicine1,
    required this.medicine2,
    required this.severity,
    required this.description,
  });
}

class InteractionService {
  final _db = DatabaseHelper.instance;

  /// Check all pairs among selected medicine IDs
  Future<List<InteractionResult>> checkInteractions(List<int> medicineIds) async {
    List<InteractionResult> results = [];

    // Generate all pairs
    for (int i = 0; i < medicineIds.length; i++) {
      for (int j = i + 1; j < medicineIds.length; j++) {
        final id1 = medicineIds[i];
        final id2 = medicineIds[j];

        final rows = await _db.rawQuery('''
          SELECT di.*, m1.name AS med1_name, m2.name AS med2_name
          FROM drug_interactions di
          JOIN medicines m1 ON di.medicine1_id = m1.medicine_id
          JOIN medicines m2 ON di.medicine2_id = m2.medicine_id
          WHERE (di.medicine1_id = ? AND di.medicine2_id = ?)
             OR (di.medicine1_id = ? AND di.medicine2_id = ?)
        ''', [id1, id2, id2, id1]);

        if (rows.isNotEmpty) {
          final row = rows.first;
          results.add(InteractionResult(
            medicine1: row['med1_name'] as String,
            medicine2: row['med2_name'] as String,
            severity: row['severity'] as String,
            description: row['description'] as String,
          ));
        } else {
          // No interaction found — mark as safe
          final m1 = await _db.rawQuery('SELECT name FROM medicines WHERE medicine_id = ?', [id1]);
          final m2 = await _db.rawQuery('SELECT name FROM medicines WHERE medicine_id = ?', [id2]);
          if (m1.isNotEmpty && m2.isNotEmpty) {
            results.add(InteractionResult(
              medicine1: m1.first['name'] as String,
              medicine2: m2.first['name'] as String,
              severity: 'safe',
              description: 'No known interaction',
            ));
          }
        }
      }
    }
    return results;
  }
}
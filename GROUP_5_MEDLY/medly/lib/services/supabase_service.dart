import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  // ── USER ID (simple device-based for now) ─────────────────────────────────
  String get userId => 'user_default'; // Replace with real auth later

  // ── MEDICINES ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    final res = await _client.from('medicines').select();
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> getMedicineDetail(int medicineId) async {
    final res = await _client
        .from('medicines')
        .select()
        .eq('medicine_id', medicineId)
        .maybeSingle();
    if (res == null) return null;

    // Get alternates
    final alts = await _client
        .from('alternate_medicines')
        .select('reason, medicines!alternate_medicines_alternate_id_fkey(medicine_id, name, type)')
        .eq('medicine_id', medicineId);

    res['alternates'] = alts;
    return res;
  }

  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    final res = await _client
        .from('medicines')
        .select()
        .or('name.ilike.%$query%,composition.ilike.%$query%,generic_name.ilike.%$query%,category.ilike.%$query%');
    return List<Map<String, dynamic>>.from(res);
  }

  // ── SYMPTOMS ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllSymptoms() async {
    final res = await _client.from('symptoms').select();
    return List<Map<String, dynamic>>.from(res);
  }

  // ── RECOMMENDATIONS ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRecommendations(List<int> symptomIds) async {
    final res = await _client
        .from('disease_symptoms')
        .select('disease_id, weight, diseases(name, description)')
        .inFilter('symptom_id', symptomIds);

    final Map<int, Map<String, dynamic>> scoreMap = {};
    for (final row in res) {
      final diseaseId = row['disease_id'] as int;
      final weight = (row['weight'] as num).toDouble();
      final disease = row['diseases'] as Map<String, dynamic>;
      if (scoreMap.containsKey(diseaseId)) {
        scoreMap[diseaseId]!['score'] += weight;
      } else {
        scoreMap[diseaseId] = {
          'disease_id': diseaseId,
          'name': disease['name'],
          'description': disease['description'],
          'score': weight,
        };
      }
    }

    final sorted = scoreMap.values.toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    for (final disease in sorted) {
      final meds = await _client
          .from('medicine_disease')
          .select('effectiveness_score, medicines(medicine_id, name, composition, type, dosage_info, category)')
          .eq('disease_id', disease['disease_id'])
          .order('effectiveness_score', ascending: false);
      disease['medicines'] = meds.map((m) => m['medicines']).toList();
    }
    return sorted;
  }

  // ── DRUG INTERACTIONS ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> checkInteractions(List<int> medicineIds) async {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < medicineIds.length; i++) {
      for (int j = i + 1; j < medicineIds.length; j++) {
        final id1 = medicineIds[i];
        final id2 = medicineIds[j];

        // Get medicine names first
        final m1 = await _client
            .from('medicines')
            .select('name')
            .eq('medicine_id', id1)
            .single();
        final m2 = await _client
            .from('medicines')
            .select('name')
            .eq('medicine_id', id2)
            .single();

        final name1 = m1['name'] as String;
        final name2 = m2['name'] as String;

        // Query interactions table using names (case-insensitive)
        final res = await _client
            .from('interactions')
            .select()
            .or('and(drug_a.ilike.$name1,drug_b.ilike.$name2),and(drug_a.ilike.$name2,drug_b.ilike.$name1)');

        if (res.isNotEmpty) {
          results.add({
            'medicine1': name1,
            'medicine2': name2,
            'severity': res.first['severity'],
            'description': res.first['description'],
            'advice': res.first['advice'],
          });
        } else {
          results.add({
            'medicine1': name1,
            'medicine2': name2,
            'severity': 'safe',
            'description': 'No known interaction between these medicines.',
            'advice': '',
          });
        }
      }
    }
    return results;
  }

  // ── PHARMACIES ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllPharmacies() async {
    final res = await _client.from('pharmacies').select();
    return List<Map<String, dynamic>>.from(res);
  }

  // ── DOSAGE SCHEDULES ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final res = await _client
        .from('dosage_schedule')
        .select('*, medicines(name)')
        .eq('active', true)
        .order('time');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addSchedule({
    required int medicineId,
    required String medicineName,
    required String time,
    bool withFood = false,
    List<String>? daysOfWeek,
    String? notes,
  }) async {
    await _client.from('dosage_schedule').insert({
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'time': time,
      'status': 'pending',
      'missed_count': 0,
      'with_food': withFood,
      'days_of_week': daysOfWeek ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      'notes': notes,
      'active': true,
      'user_id': userId,
    });
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await _client
        .from('dosage_schedule')
        .update({'active': false})
        .eq('schedule_id', scheduleId);
  }

  Future<void> markTaken(int scheduleId) async {
    await _client
        .from('dosage_schedule')
        .update({'status': 'taken'})
        .eq('schedule_id', scheduleId);
  }

  Future<void> markMissed(int scheduleId, int currentMissedCount) async {
    await _client
        .from('dosage_schedule')
        .update({'status': 'missed', 'missed_count': currentMissedCount + 1})
        .eq('schedule_id', scheduleId);
  }

  // ── USER PROFILE ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final res = await _client
          .from('user_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      // Check if profile already exists
      final existing = await _client
          .from('user_profile')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final data = {
        ...profile,
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // UPDATE existing row
        await _client
            .from('user_profile')
            .update(data)
            .eq('user_id', userId);
      } else {
        // INSERT new row
        await _client
            .from('user_profile')
            .insert(data);
      }
    } catch (e) {
      debugPrint('saveUserProfile error: $e');
    }
  }

  // ── MEDICINE STOCK ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMedicineStock() async {
    final res = await _client
        .from('medicine_stock')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addMedicineStock({
    required int medicineId,
    required String medicineName,
    required int totalCount,
    required int currentCount,
    int dailyDose = 1,
    int lowStockThreshold = 5,
    DateTime? expiryDate,
    String? notes,
  }) async {
    await _client.from('medicine_stock').insert({
      'user_id': userId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'total_count': totalCount,
      'current_count': currentCount,
      'daily_dose': dailyDose,
      'low_stock_threshold': lowStockThreshold,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'notes': notes,
      'purchase_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<void> updateStock(int stockId, int newCount) async {
    await _client
        .from('medicine_stock')
        .update({'current_count': newCount, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', stockId);
  }

  Future<void> deleteMedicineStock(int stockId) async {
    await _client.from('medicine_stock').delete().eq('id', stockId);
  }

  Future<List<Map<String, dynamic>>> getLowStockAlerts() async {
    final res = await getMedicineStock();
    return res.where((s) =>
      (s['current_count'] as int) <= (s['low_stock_threshold'] as int)
    ).toList();
  }

  Future<List<Map<String, dynamic>>> getExpiringMedicines() async {
    final soon = DateTime.now().add(const Duration(days: 30));
    final res = await getMedicineStock();
    return res.where((s) {
      if (s['expiry_date'] == null) return false;
      final exp = DateTime.tryParse(s['expiry_date'] as String);
      return exp != null && exp.isBefore(soon);
    }).toList();
  }
}

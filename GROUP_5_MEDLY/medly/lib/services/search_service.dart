import '../models/medicine.dart';
import 'supabase_service.dart';

class SearchService {
  final _supa = SupabaseService.instance;

  int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<List<int>> d = List.generate(
        s.length + 1, (i) => List.generate(t.length + 1, (j) => 0));
    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+cost]
            .reduce((a, b) => a < b ? a : b);
      }
    }
    return d[s.length][t.length];
  }

  Future<List<Medicine>> fuzzySearch(String query) async {
    query = query.toLowerCase().trim();
    if (query.isEmpty) return [];

    // Fetch from Supabase (PostgreSQL ilike search)
    final rows = await _supa.searchMedicines(query);
    final medicines = rows.map((m) => Medicine(
      id: m['medicine_id'],
      name: m['name'],
      composition: m['composition'] ?? '',
      type: m['type'] ?? '',
      dosageInfo: m['dosage_info'] ?? '',
    )).toList();

    // Apply fuzzy ranking on top of DB results
    List<Map<String, dynamic>> scored = [];
    for (final med in medicines) {
      final nameLower = med.name.toLowerCase();
      final distance = levenshtein(query, nameLower);
      bool contains = nameLower.contains(query);
      bool startsWith = nameLower.startsWith(query);
      int score = distance;
      if (contains) score -= 3;
      if (startsWith) score -= 5;
      scored.add({'medicine': med, 'score': score});
    }
    scored.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
    return scored.map((s) => s['medicine'] as Medicine).toList();
  }
}
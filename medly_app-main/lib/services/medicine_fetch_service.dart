import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Fetches medicine data from OpenFDA when not found in Supabase,
/// then saves it back to Supabase for future queries.
class MedicineFetchService {
  final _supa = SupabaseService.instance;

  Future<Map<String, dynamic>?> fetchAndSave(String name) async {
    try {
      // 1. Try OpenFDA by brand name
      var result = await _fetchFromOpenFDA('openfda.brand_name', name);

      // 2. Fallback: try generic name
      result ??= await _fetchFromOpenFDA('openfda.generic_name', name);

      if (result == null) return null;

      // 3. Save to Supabase medicines table
      await _saveToSupabase(result);

      return result;
    } catch (e) {
      debugPrint('MedicineFetchService error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFromOpenFDA(
      String field, String name) async {
    final encodedName = Uri.encodeComponent('"$name"');
    final uri = Uri.parse(
      'https://api.fda.gov/drug/label.json?search=$field:$encodedName&limit=1',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;

    final r = results.first as Map<String, dynamic>;
    final openfda = r['openfda'] as Map<String, dynamic>? ?? {};

    // Extract brand name
    final brandNames = openfda['brand_name'] as List?;
    final genericNames = openfda['generic_name'] as List?;
    final pharmClass = openfda['pharm_class_epc'] as List?;
    final substanceName = openfda['substance_name'] as List?;
    final route = openfda['route'] as List?;

    final medName = brandNames?.first as String? ??
        genericNames?.first as String? ??
        name;
    final genericName = genericNames?.first as String? ?? '';
    final composition = substanceName?.join(', ') ?? genericName;
    final category = pharmClass?.first as String? ?? 'General';
    final type = _mapRouteToType(route?.first as String?);

    // Truncate long text fields
    String _trunc(dynamic val, [int max = 300]) {
      if (val == null) return '';
      final s = val.toString();
      return s.length > max ? '${s.substring(0, max)}...' : s;
    }

    final dosageRaw = r['dosage_and_administration'];
    final dosageInfo = dosageRaw is List
        ? _trunc(dosageRaw.first)
        : _trunc(dosageRaw);

    return {
      'name': medName,
      'generic_name': genericName,
      'composition': composition,
      'category': category,
      'type': type,
      'dosage_info': dosageInfo.isEmpty ? 'See label' : dosageInfo,
    };
  }

  String _mapRouteToType(String? route) {
    if (route == null) return 'Tablet';
    switch (route.toUpperCase()) {
      case 'ORAL':
        return 'Tablet';
      case 'TOPICAL':
        return 'Gel';
      case 'INTRAVENOUS':
      case 'INJECTION':
        return 'Injection';
      case 'OPHTHALMIC':
        return 'Eye Drop';
      default:
        return 'Tablet';
    }
  }

  Future<void> _saveToSupabase(Map<String, dynamic> medicine) async {
    try {
      await Supabase.instance.client
          .from('medicines')
          .upsert(medicine, onConflict: 'name');
      debugPrint('MedicineFetchService: saved "${medicine['name']}" to Supabase');
    } catch (e) {
      debugPrint('MedicineFetchService: Supabase save failed: $e');
    }
  }
}
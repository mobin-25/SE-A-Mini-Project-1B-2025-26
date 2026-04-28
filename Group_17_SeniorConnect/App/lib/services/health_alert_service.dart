import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RiskLevel { low, medium, high, critical }

class HealthAlert {
  final RiskLevel    riskLevel;
  final String       title;
  final String       message;
  final List<String> recommendations;
  final String       cityName;
  final int          activeCases;
  final DateTime     fetchedAt;

  HealthAlert({required this.riskLevel, required this.title, required this.message,
    required this.recommendations, required this.cityName,
    required this.activeCases, required this.fetchedAt});

  Map<String, dynamic> toJson() => {
    'riskLevel': riskLevel.index, 'title': title, 'message': message,
    'recommendations': recommendations, 'cityName': cityName,
    'activeCases': activeCases, 'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory HealthAlert.fromJson(Map<String, dynamic> j) => HealthAlert(
    riskLevel: RiskLevel.values[j['riskLevel'] ?? 0],
    title: j['title'] ?? '', message: j['message'] ?? '',
    recommendations: List<String>.from(j['recommendations'] ?? []),
    cityName: j['cityName'] ?? 'Your area',
    activeCases: j['activeCases'] ?? 0,
    fetchedAt: DateTime.tryParse(j['fetchedAt'] ?? '') ?? DateTime.now(),
  );

  int get colorValue {
    switch (riskLevel) {
      case RiskLevel.low:      return 0xFF27AE60;
      case RiskLevel.medium:   return 0xFFF39C12;
      case RiskLevel.high:     return 0xFFE74C3C;
      case RiskLevel.critical: return 0xFF8E1111;
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:      return 'Low Risk';
      case RiskLevel.medium:   return 'Moderate Risk';
      case RiskLevel.high:     return 'High Risk';
      case RiskLevel.critical: return 'Critical';
    }
  }

  String get voiceMessage {
    switch (riskLevel) {
      case RiskLevel.low:      return 'Health risk in your area is low. Stay safe.';
      case RiskLevel.medium:   return 'Moderate health risk nearby. Please take precautions.';
      case RiskLevel.high:     return 'High infection risk nearby. Wear a mask and stay indoors.';
      case RiskLevel.critical: return 'Critical health alert. Please avoid going outside immediately.';
    }
  }
}

class HealthAlertService {
  static const _cacheKey    = 'health_alert_cache';
  static const _cacheExpiry = Duration(hours: 6);

  static Future<HealthAlert> getAlert({
    bool  forceRefresh = false,
    bool? hasDiabetes, bool? hasBP, bool? hasHeart, int? userAge,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null) return _personalize(cached, hasDiabetes, hasBP, hasHeart, userAge);
    }
    final city = await _detectCity();
    HealthAlert? alert;
    alert ??= await _tryDiseaseShCountry(city);
    alert ??= await _tryDiseaseShGlobal(city);
    alert ??= _fallbackAlert(city);
    await _saveCache(alert);
    return _personalize(alert, hasDiabetes, hasBP, hasHeart, userAge);
  }

  static Future<String> _detectCity() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return 'India';
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 6));
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&zoom=10'),
        headers: {'User-Agent': 'SeniorCheckInApp/1.0', 'Accept-Language': 'en'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final addr = (json.decode(res.body)['address'] as Map<String, dynamic>?) ?? {};
        return addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state'] ?? 'India';
      }
    } catch (_) {}
    return 'India';
  }

  static Future<HealthAlert?> _tryDiseaseShCountry(String city) async {
    try {
      final res = await http.get(Uri.parse('https://disease.sh/v3/covid-19/countries/India'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = json.decode(res.body) as Map<String, dynamic>;
        return _buildAlert(city, (d['todayCases'] as num?)?.toInt() ?? 0,
            (d['active'] as num?)?.toInt() ?? 0, (d['todayDeaths'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {}
    return null;
  }

  static Future<HealthAlert?> _tryDiseaseShGlobal(String city) async {
    try {
      final res = await http.get(Uri.parse('https://disease.sh/v3/covid-19/all'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = json.decode(res.body) as Map<String, dynamic>;
        return _buildAlert(city, ((d['todayCases'] as num?)?.toInt() ?? 0) ~/ 200,
            ((d['active'] as num?)?.toInt() ?? 0) ~/ 200, 0);
      }
    } catch (_) {}
    return null;
  }

  static HealthAlert _buildAlert(String city, int todayCases, int active, int deaths) {
    RiskLevel risk; String title, message;
    if (todayCases > 5000 || active > 500000 || deaths > 100) {
      risk = RiskLevel.critical; title = 'Critical Health Alert';
      message = 'Very high infection levels near $city. Avoid all non-essential outings.';
    } else if (todayCases > 1000 || active > 100000) {
      risk = RiskLevel.high; title = 'High Risk in Your Area';
      message = 'Significant infection activity near $city. Take precautions when going out.';
    } else if (todayCases > 200 || active > 10000) {
      risk = RiskLevel.medium; title = 'Moderate Alert';
      message = 'Some infection activity near $city. Follow standard hygiene guidelines.';
    } else {
      risk = RiskLevel.low; title = 'You\'re in a Safe Zone';
      message = 'Infection levels near $city are currently low. Stay vigilant.';
    }
    return HealthAlert(riskLevel: risk, title: title, message: message,
        recommendations: _recs(risk), cityName: city, activeCases: todayCases, fetchedAt: DateTime.now());
  }

  static HealthAlert _fallbackAlert(String city) => HealthAlert(
    riskLevel: RiskLevel.low, title: 'Stay Healthy',
    message: 'Could not fetch live data. Follow general hygiene precautions.',
    recommendations: _recs(RiskLevel.low), cityName: city, activeCases: 0, fetchedAt: DateTime.now());

  static HealthAlert _personalize(HealthAlert base, bool? hasDiabetes, bool? hasBP, bool? hasHeart, int? userAge) {
    final isHighRisk = (hasDiabetes ?? false) || (hasBP ?? false) || (hasHeart ?? false) || (userAge ?? 0) >= 60;
    RiskLevel risk = base.riskLevel;
    if (isHighRisk && base.riskLevel != RiskLevel.critical) risk = RiskLevel.values[base.riskLevel.index + 1];
    final extra = <String>[];
    if (hasDiabetes == true) extra.addAll(['Monitor blood sugar more frequently during outbreaks.', 'Infections can raise blood sugar — check twice daily.']);
    if (hasBP == true) extra.addAll(['Keep BP medication stocked for at least 2 weeks.', 'Stress from illness can spike blood pressure — stay calm.']);
    if (hasHeart == true) extra.addAll(['Heart patients face higher risk — avoid crowded places.', 'Keep emergency cardiac medicines easily accessible.']);
    if ((userAge ?? 0) >= 60) extra.add('Seniors are at higher risk. Postpone non-urgent outings.');
    return HealthAlert(
      riskLevel: risk, title: base.title,
      message: isHighRisk && risk != base.riskLevel ? '${base.message} Extra caution advised for your health profile.' : base.message,
      recommendations: [...base.recommendations, ...extra],
      cityName: base.cityName, activeCases: base.activeCases, fetchedAt: base.fetchedAt,
    );
  }

  static List<String> _recs(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:      return ['Wash hands with soap for at least 20 seconds.', 'Stay hydrated — drink 8 glasses of water daily.', 'Take Vitamin C and D supplements.', 'Maintain a healthy sleep schedule.'];
      case RiskLevel.medium:   return ['Wear a mask in crowded or indoor spaces.', 'Avoid large gatherings where possible.', 'Sanitize hands after touching surfaces.', 'Take Vitamin C, D and Zinc supplements.', 'Keep a 2-week supply of your regular medicines.'];
      case RiskLevel.high:     return ['Wear N95 mask if going outside.', 'Limit outdoor trips to essential needs only.', 'Disinfect groceries and deliveries.', 'Check temperature and oxygen levels daily.', 'Stock up on medicines and essentials for 1 month.'];
      case RiskLevel.critical: return ['Stay home — avoid ALL non-essential outings.', 'Wear N95 mask even indoors if visitors come.', 'Ventilate rooms regularly — open windows.', 'Monitor oxygen with a pulse oximeter.', 'Watch for: fever, cough, breathlessness.', 'Contact doctor immediately if symptoms appear.'];
    }
  }

  static Future<void> _saveCache(HealthAlert a) async {
    try { final p = await SharedPreferences.getInstance(); await p.setString(_cacheKey, json.encode(a.toJson())); } catch (_) {}
  }
  static Future<HealthAlert?> _loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null) return null;
      final a = HealthAlert.fromJson(json.decode(raw));
      return DateTime.now().difference(a.fetchedAt) < _cacheExpiry ? a : null;
    } catch (_) { return null; }
  }
  static Future<void> clearCache() async { final p = await SharedPreferences.getInstance(); await p.remove(_cacheKey); }
}
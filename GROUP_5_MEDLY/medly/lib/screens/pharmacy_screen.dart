import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Add to pubspec.yaml:
//   http: ^1.2.1
//   url_launcher: ^6.2.4
//   geolocator: ^11.0.0
//
// Get a FREE Geoapify API key at: https://myprojects.geoapify.com
// Free tier: 3,000 requests/day — more than enough

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  // ✅ Replace with your key from https://myprojects.geoapify.com (free signup)
  static const String _geoapifyKey = '53e2e443730448c68735211b8e4a16c1';

  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = false;
  String? _error;
  Position? _userPosition;

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(2)} km';
  }

  Future<void> _findNearby() async {
    setState(() {
      _loading = true;
      _error = null;
      _pharmacies = [];
    });

    try {
      // 1. Get user location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied. Please enable it in Settings.';
          _loading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userPosition = position;

      // 2. Call Geoapify Places API to find real pharmacies nearby
      final lat = position.latitude;
      final lon = position.longitude;
      const radius = 3000; // 3 km radius

      final url = Uri.parse(
        'https://api.geoapify.com/v2/places'
        '?categories=healthcare.pharmacy'
        '&filter=circle:$lon,$lat,$radius'
        '&bias=proximity:$lon,$lat'
        '&limit=20'
        '&apiKey=$_geoapifyKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Geoapify error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];

      if (features.isEmpty) {
        setState(() {
          _error = 'No pharmacies found within 3 km. Try again in a different location.';
          _loading = false;
        });
        return;
      }

      final pharmacies = features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final geo = f['geometry'] as Map<String, dynamic>;
        final coords = geo['coordinates'] as List;
        final pLon = (coords[0] as num).toDouble();
        final pLat = (coords[1] as num).toDouble();

        final dist = _haversine(lat, lon, pLat, pLon);

        return {
          'name': props['name']?.toString() ?? 'Pharmacy',
          'address': props['formatted']?.toString() ??
              props['address_line2']?.toString() ?? '',
          'phone': props['contact']?['phone']?.toString(),
          'opening_hours': props['opening_hours']?.toString(),
          'latitude': pLat,
          'longitude': pLon,
          'distance_km': dist,
        };
      }).toList();

      pharmacies.sort(
          (a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));

      setState(() {
        _pharmacies = pharmacies;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _navigate(Map<String, dynamic> pharmacy) async {
    final lat = pharmacy['latitude'] as double;
    final lon = pharmacy['longitude'] as double;
    final name = Uri.encodeComponent(pharmacy['name'] as String);

    // Browser-compatible Google Maps URL (always works)
    final browserUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lon'
      '&destination_place_id=$name'
      '&travelmode=driving',
    );

    // Try native app URIs first (Android / iOS), then fall back to browser
    final uris = [
      Uri.parse('google.navigation:q=$lat,$lon&mode=d'),
      Uri.parse('comgooglemaps://?daddr=$lat,$lon&directionsmode=driving'),
      browserUrl,
    ];

    for (final uri in uris) {
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        continue;
      }
    }

    // Last resort: force-open the browser URL without canLaunchUrl check
    try {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Maps. Coordinates: $lat, $lon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _call(String phone, BuildContext context) async {
    // Copy to clipboard as a fallback/convenience
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied: $phone'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        actions: [
          if (_pharmacies.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _findNearby,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_pharmacy, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Find Real Pharmacies Near You',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _userPosition != null
                      ? 'Lat: ${_userPosition!.latitude.toStringAsFixed(4)}, Lon: ${_userPosition!.longitude.toStringAsFixed(4)}'
                      : 'Tap below to detect your location',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: _loading ? null : _findNearby,
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _loading
                        ? 'Searching...'
                        : _pharmacies.isEmpty
                            ? 'Find Nearest Pharmacies'
                            : 'Search Again',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),

          // Results count
          if (_pharmacies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.place, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_pharmacies.length} pharmacies found nearby',
                    style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ],
              ),
            ),

          // Pharmacy list
          Expanded(
            child: _pharmacies.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_pharmacy_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No pharmacies loaded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Tap the button above to find real\npharmacies near your location', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _pharmacies.length,
                    itemBuilder: (_, i) {
                      final p = _pharmacies[i];
                      final dist = _formatDistance(p['distance_km'] as double);
                      final isNearest = i == 0;
                      final hasPhone = p['phone'] != null;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isNearest
                                ? cs.primary.withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: isNearest ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Rank
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isNearest ? cs.primary : cs.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: isNearest
                                          ? const Icon(Icons.star, color: Colors.white, size: 18)
                                          : Text('${i + 1}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.onSurfaceVariant)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                p['name'] as String,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            if (isNearest)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: cs.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text('Nearest',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.directions_walk,
                                                size: 13, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(dist,
                                                style: TextStyle(
                                                    color: Colors.grey.shade600, fontSize: 13)),
                                          ],
                                        ),
                                        if ((p['address'] as String).isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            p['address'] as String,
                                            style: TextStyle(
                                                color: Colors.grey.shade500, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (hasPhone) ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _call(p['phone'] as String, context),
                                        icon: const Icon(Icons.call, size: 16),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(p['phone'] as String),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    flex: hasPhone ? 1 : 2,
                                    child: FilledButton.icon(
                                      onPressed: () => _navigate(p),
                                      icon: const Icon(Icons.navigation, size: 16),
                                      label: const Text('Navigate'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

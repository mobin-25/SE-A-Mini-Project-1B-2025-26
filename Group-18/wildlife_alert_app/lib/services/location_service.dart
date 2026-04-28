import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

enum LocationPermissionStatus { granted, denied, permanentlyDenied }

class LocationService {
  /// Checks current permission and requests it if not yet decided.
  /// Returns a [LocationPermissionStatus] so callers can distinguish
  /// between a simple denial (re-requestable) and a permanent denial
  /// (requires opening system settings).
  static Future<LocationPermissionStatus> checkStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionStatus.permanentlyDenied;
      }
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }
    return LocationPermissionStatus.granted;
  }

  /// Legacy helper — returns true only when permission is granted.
  static Future<bool> requestPermission() async {
    return (await checkStatus()) == LocationPermissionStatus.granted;
  }

  /// Opens the system app-settings page so the user can grant location.
  static Future<void> openSettings() => Geolocator.openAppSettings();

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      // Fallback to coordinates if geocoding fails
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }
}
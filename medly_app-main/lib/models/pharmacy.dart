class Pharmacy {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  double? distanceKm; // computed at runtime

  Pharmacy({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
  });

  Map<String, dynamic> toMap() => {
    'pharmacy_id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Pharmacy.fromMap(Map<String, dynamic> map) => Pharmacy(
    id: map['pharmacy_id'],
    name: map['name'],
    latitude: map['latitude'],
    longitude: map['longitude'],
  );
}
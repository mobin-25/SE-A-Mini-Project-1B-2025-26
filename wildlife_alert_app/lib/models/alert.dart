class Alert {
  final String id;
  final String message;
  final String? imageUrl;
  final String userId;
  final String? userEmail;
  final String priority;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  Alert({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.userId,
    this.userEmail,
    required this.priority,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      message: json['message'] ?? 'Unknown alert',
      imageUrl: json['image_url'],
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'],
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Open',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationAddress: json['location_address'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'image_url': imageUrl,
      'user_id': userId,
      'user_email': userEmail,
      'priority': priority,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
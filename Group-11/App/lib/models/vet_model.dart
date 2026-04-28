class Vet {
  final String id;
  final String name;
  final String clinic;
  final String location;
  final String experience;
  final String image;

  Vet({
    required this.id,
    required this.name,
    required this.clinic,
    required this.location,
    required this.experience,
    required this.image,
  });

  factory Vet.fromFirestore(Map<String, dynamic> data, String id) {
    return Vet(
      id: id,
      name: data['name'] ?? '',
      clinic: data['clinic'] ?? '',
      location: data['location'] ?? '',
      experience: data['experience'] ?? '',
      image: data['image'] ?? '',
    );
  }
}
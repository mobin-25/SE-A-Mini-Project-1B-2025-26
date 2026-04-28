import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vet_model.dart';

class VetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Vet>> getVets() {
    return _firestore.collection('vets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vet.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}
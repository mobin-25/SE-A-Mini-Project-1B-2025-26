import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  // ✅ ACCEPT REQUEST (UPDATED)
  Future<void> acceptRequest(String requestId, String petId) async {
    // 1. Update request status + add adoption date
    await FirebaseFirestore.instance
        .collection('adoption_requests')
        .doc(requestId)
        .update({
      'status': 'accepted',
      'adoptionDate': Timestamp.now(), // ⭐ NEW FIELD ADDED
    });

    // 2. Mark pet as adopted
    await FirebaseFirestore.instance
        .collection('pets')
        .doc(petId)
        .update({
      'isAdopted': true,
    });
  }

  // ❌ REJECT REQUEST
  Future<void> rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('adoption_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adoption Requests")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adoption_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading requests"));
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var doc = requests[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['petName'] ?? "No Name"),
                  subtitle: Text(
                    "User: ${data['userEmail']}\nStatus: ${data['status']}",
                  ),
                  isThreeLine: true,

                  trailing: data['status'] == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ ACCEPT
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Colors.green),
                              onPressed: () =>
                                  acceptRequest(doc.id, data['petId']),
                            ),

                            // ❌ REJECT
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red),
                              onPressed: () =>
                                  rejectRequest(doc.id),
                            ),
                          ],
                        )
                      : Text(
                          data['status'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: data['status'] == 'accepted'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
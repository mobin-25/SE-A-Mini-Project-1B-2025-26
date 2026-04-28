import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  Future<void> updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vet Appointments"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading appointments"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments found"));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final doc = appointments[index];
              final data = doc.data() as Map<String, dynamic>;

              final status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// INFO
                      Text(
                        data['petName'] ?? 'Appointment',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      Text("User: ${data['userName'] ?? 'Unknown'}"),
                      Text("Vet: ${data['vetName'] ?? 'Unknown'}"),
                      Text("Date: ${data['date'] ?? 'No Date'}"),
                      Text("Time: ${data['time'] ?? 'No Time'}"),

                      const SizedBox(height: 10),

                      /// STATUS TEXT
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// BUTTONS (ONLY IF PENDING)
                      if (status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  updateStatus(doc.id, 'approved');
                                },
                                child: const Text("Accept"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  updateStatus(doc.id, 'rejected');
                                },
                                child: const Text("Reject"),
                              ),
                            ),
                          ],
                        ),
                    ],
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
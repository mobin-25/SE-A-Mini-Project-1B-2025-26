import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DeleteAllStudentsButton extends StatelessWidget {
  const DeleteAllStudentsButton({super.key});

  Future<String> _deleteAllStudents() async {
    FirebaseApp? secondaryApp;
    int deletedFirestore = 0;
    int deletedAuth = 0;

    try {
      // ── STEP 1: Delete all docs from 'students' collection ──
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('students').get();

      // Delete in batches of 500 (Firestore limit)
      final batches = <WriteBatch>[];
      WriteBatch batch = firestore.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        deletedFirestore++;

        if (count == 500) {
          batches.add(batch);
          batch = firestore.batch();
          count = 0;
        }
      }
      if (count > 0) batches.add(batch);
      for (final b in batches) {
        await b.commit();
      }

      // ── STEP 2: Delete Auth accounts via secondary app ──
      // We re-sign in each student account and delete it
      try {
        secondaryApp = Firebase.app('DeleteStudentsApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'DeleteStudentsApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth =
      FirebaseAuth.instanceFor(app: secondaryApp);

      // Get all stored emails from the deleted Firestore docs
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String email = data['email'] ?? '';
        final String password = data['default_password'] ?? '';

        if (email.isEmpty || password.isEmpty) continue;
        if (!email.endsWith('@apsit.edu.in')) continue;

        try {
          // Sign in with stored credentials then delete
          final userCred =
          await secondaryAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          await userCred.user?.delete();
          await secondaryAuth.signOut();
          deletedAuth++;
        } catch (e) {
          debugPrint("Could not delete auth for $email: $e");
        }
      }

      await secondaryApp.delete();
      secondaryApp = null;

      return "✅ Done!\n"
          "• Firestore: $deletedFirestore student records deleted\n"
          "• Auth: $deletedAuth accounts deleted\n\n"
          "You can now re-upload your Excel file.";
    } catch (e) {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
      return "❌ Error: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // ── Confirm dialog ──
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text("Delete All Students?",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "This will permanently delete:\n"
                  "• All student records from Firestore\n"
                  "• All student login accounts\n\n"
                  "Your teacher account will NOT be affected.\n\n"
                  "This cannot be undone!",
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes, Delete All"),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // ── Loading dialog ──
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: const Row(
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Deleting all students...\nThis may take a minute.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final result = await _deleteAllStudents();

        // Close loading dialog
        if (context.mounted) Navigator.pop(context);

        // Show result
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    result.startsWith('✅')
                        ? Icons.check_circle
                        : Icons.error,
                    color: result.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text("Result",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(result,
                    style: const TextStyle(fontSize: 14)),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      },
      icon: const Icon(Icons.delete_forever),
      label: const Text("Delete All Students",
          style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
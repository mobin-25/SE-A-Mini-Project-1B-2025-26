import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vet_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Vet vet;

  const BookAppointmentScreen({super.key, required this.vet});

  @override
  State<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// 📅 PICK DATE
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// ⏰ PICK TIME (CIRCLE CLOCK)
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  /// 🔥 BOOK APPOINTMENT
  Future<void> bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    /// ✅ FORMAT DATE (NO 00:00:00)
    final formattedDate =
        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";

    await FirebaseFirestore.instance.collection('appointments').add({
      'userName': userData['name'],
      'userEmail': user.email,
      'petName': "Appointment", // ✅ changed
      'vetName': widget.vet.name,
      'date': formattedDate, // ✅ clean date
      'time': selectedTime!.format(context),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment Booked")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book with ${widget.vet.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 📅 DATE BUTTON
            ElevatedButton(
              onPressed: pickDate,
              child: Text(
                selectedDate == null
                    ? "Select Date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
            ),

            const SizedBox(height: 20),

            /// ⏰ TIME BUTTON (CLOCK UI)
            ElevatedButton(
              onPressed: pickTime,
              child: Text(
                selectedTime == null
                    ? "Select Time"
                    : selectedTime!.format(context),
              ),
            ),

            const SizedBox(height: 30),

            /// ✅ CONFIRM BUTTON
            ElevatedButton(
              onPressed: (selectedDate == null || selectedTime == null)
                  ? null
                  : bookAppointment,
              child: const Text("Confirm Appointment"),
            ),
          ],
        ),
      ),
    );
  }
}
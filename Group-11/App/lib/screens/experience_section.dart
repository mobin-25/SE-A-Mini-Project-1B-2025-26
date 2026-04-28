import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref('experiences');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "❤️ Adoption Experiences",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 170,
          child: StreamBuilder<DatabaseEvent>(
            stream: dbRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return const Center(child: Text("No experiences yet"));
              }

              final data = snapshot.data!.snapshot.value as Map;
              final experiences = data.values.toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: experiences.length,
                itemBuilder: (context, index) {
                  final exp = experiences[index];

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            exp['userName'] ?? "Anonymous",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          content: SingleChildScrollView(
                            child: Text(exp['review'] ?? ""),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            )
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 240,
                      margin: const EdgeInsets.all(8),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // 👤 NAME + ICON
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.person,
                                        size: 16, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    exp['userName'] ?? "Anonymous",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 💬 REVIEW PREVIEW
                              Expanded(
                                child: Text(
                                  exp['review'] ?? "",
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // 👇 READ MORE HINT
                              const Text(
                                "Tap to read more",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
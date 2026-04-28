/// Repository for managing chat rooms and messages.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class ChatRepository {
  final FirestoreService _firestore = FirestoreService();

  /// Get or create a chat room between doctor and patient.
  Future<ChatRoom> getOrCreateChatRoom({
    required String doctorId,
    required String patientId,
    required String doctorName,
    required String patientName,
  }) async {
    // Check if chat room exists
    final snapshot =
        await _firestore.chatRoomsCollection
            .where('doctorId', isEqualTo: doctorId)
            .where('patientId', isEqualTo: patientId)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return ChatRoom.fromMap(snapshot.docs.first.data());
    }

    // Create new chat room
    final room = ChatRoom(
      doctorId: doctorId,
      patientId: patientId,
      doctorName: doctorName,
      patientName: patientName,
    );
    await _firestore.chatRoomsCollection.doc(room.id).set(room.toMap());
    return room;
  }

  /// Get all chat rooms for the current user (doctor).
  Future<List<ChatRoom>> getDoctorChatRooms() async {
    final doctorId = _firestore.uid;
    final snapshot =
        await _firestore.chatRoomsCollection
            .where('doctorId', isEqualTo: doctorId)
            .get();
    return snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList()
      ..sort(
        (a, b) => (b.lastMessageTime ?? DateTime(2000)).compareTo(
          a.lastMessageTime ?? DateTime(2000),
        ),
      );
  }

  /// Stream chat rooms for real-time updates (doctor side).
  Stream<List<ChatRoom>> watchDoctorChatRooms() {
    final doctorId = _firestore.uid;
    return _firestore.chatRoomsCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final rooms =
              snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList()
                ..sort(
                  (a, b) => (b.lastMessageTime ?? DateTime(2000)).compareTo(
                    a.lastMessageTime ?? DateTime(2000),
                  ),
                );
          return rooms;
        });
  }

  /// Stream chat rooms for real-time updates (patient side).
  Stream<List<ChatRoom>> watchPatientChatRooms() {
    final patientId = _firestore.uid;
    return _firestore.chatRoomsCollection
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final rooms =
              snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList()
                ..sort(
                  (a, b) => (b.lastMessageTime ?? DateTime(2000)).compareTo(
                    a.lastMessageTime ?? DateTime(2000),
                  ),
                );
          return rooms;
        });
  }

  /// Send a message in a chat room.
  Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
    await _firestore
        .chatMessagesCollection(chatRoomId)
        .doc(message.id)
        .set(message.toMap());
    // Update last message in chat room
    await _firestore.chatRoomsCollection.doc(chatRoomId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp.toIso8601String(),
    });
  }

  /// Stream messages in a chat room (real-time).
  Stream<List<ChatMessage>> watchMessages(String chatRoomId) {
    return _firestore
        .chatMessagesCollection(chatRoomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromMap(doc.data()))
                  .toList(),
        );
  }
}

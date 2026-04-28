// Patient Chat — chat room list + real-time messaging with doctors.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/nebula_background.dart';

/// Displays all chat rooms the patient has with doctors.
class PatientChatScreen extends ConsumerWidget {
  const PatientChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(patientChatRoomsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            children: const [
              Icon(
                Icons.chat_bubble_rounded,
                color: AppTheme.electricBlue,
                size: 24,
              ),
              SizedBox(width: 10),
              Text('Messages'),
            ],
          ),
        ),
        body: roomsAsync.when(
          data: (rooms) {
            if (rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chat will be available after your appointment is accepted',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: rooms.length,
              itemBuilder: (_, i) => _ChatRoomTile(room: rooms[i]),
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppTheme.electricBlue),
              ),
          error:
              (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.radiantPink),
                ),
              ),
        ),
      ),
    );
  }
}

class _ChatRoomTile extends ConsumerWidget {
  final ChatRoom room;
  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PatientChatDetailScreen(
                  chatRoomId: room.id,
                  doctorName: room.doctorName,
                ),
          ),
        );
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
              ),
              child: Center(
                child: Text(
                  room.doctorName.isNotEmpty
                      ? room.doctorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${room.doctorName}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (room.lastMessage != null && room.lastMessage!.isNotEmpty)
                    Text(
                      room.lastMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (room.lastMessageTime != null)
              Text(
                _formatTime(room.lastMessageTime!),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('hh:mm a').format(dt);
    }
    return DateFormat('MMM dd').format(dt);
  }
}

/// Real-time chat with a specific doctor.
class PatientChatDetailScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String doctorName;

  const PatientChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.doctorName,
  });

  @override
  ConsumerState<PatientChatDetailScreen> createState() =>
      _PatientChatDetailScreenState();
}

class _PatientChatDetailScreenState
    extends ConsumerState<PatientChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final message = ChatMessage(
      senderId: FirestoreService().uid,
      text: text,
      timestamp: DateTime.now(),
    );
    ref.read(patientChatRepoProvider).sendMessage(widget.chatRoomId, message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      patientChatMessagesStreamProvider(widget.chatRoomId),
    );

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.greenBlueGradient,
                ),
                child: Center(
                  child: Text(
                    widget.doctorName.isNotEmpty
                        ? widget.doctorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Dr. ${widget.doctorName}'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Start a conversation with your doctor',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                  );
                },
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.electricBlue,
                      ),
                    ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.electricBlue.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppTheme.bgPrimary.withValues(alpha: 0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _send,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.accentGradient,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == FirestoreService().uid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isMe
                  ? AppTheme.electricBlue.withValues(alpha: 0.2)
                  : AppTheme.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(
            color:
                isMe
                    ? AppTheme.electricBlue.withValues(alpha: 0.3)
                    : AppTheme.textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final chat = ChatService();
    final myUid = auth.currentUid ?? '';

    return Scaffold(
      body: StreamBuilder<List<ChatRoom>>(
        stream: chat.getChatRooms(myUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Belum ada chat', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Mulai chat baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewChatScreen()),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(
              indent: 72, height: 0, thickness: 0.5),
            itemBuilder: (context, i) {
              final room = rooms[i];
              final otherUid =
                  room.members.firstWhere((m) => m != myUid, orElse: () => '');
              return _ChatRoomTile(
                room: room,
                otherUid: otherUid,
                myUid: myUid,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewChatScreen()),
        ),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String otherUid;
  final String myUid;

  const _ChatRoomTile({
    required this.room,
    required this.otherUid,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: ChatService().watchUser(otherUid),
      builder: (context, snap) {
        final user = snap.data;
        final name = user?.name ?? '...';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final isOnline = user?.isOnline ?? false;

        String timeStr = '';
        if (room.lastMessageTime != null) {
          final now = DateTime.now();
          final diff = now.difference(room.lastMessageTime!);
          if (diff.inDays == 0) {
            timeStr = DateFormat('HH:mm').format(room.lastMessageTime!);
          } else if (diff.inDays == 1) {
            timeStr = 'Kemarin';
          } else {
            timeStr = DateFormat('dd/MM').format(room.lastMessageTime!);
          }
        }

        return ListTile(
          onTap: () {
            if (user == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  chatId: room.chatId,
                  otherUser: user,
                ),
              ),
            );
          },
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.teal,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(
            room.lastMessage.isEmpty ? 'Mulai percakapan...' : room.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: Text(timeStr,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        );
      },
    );
  }
}

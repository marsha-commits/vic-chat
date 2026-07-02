import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'call_screen.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final myUid = auth.currentUid ?? '';
    final chatService = ChatService();

    return StreamBuilder<List<CallLog>>(
      stream: chatService.getCallLogs(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final calls = snap.data ?? [];

        if (calls.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada log panggilan',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: calls.length,
          separatorBuilder: (_, __) =>
              const Divider(indent: 72, height: 0, thickness: 0.5),
          itemBuilder: (context, i) {
            final call = calls[i];
            final isMissed = call.status == CallStatus.missed;
            final isMe = call.callerId == myUid;
            final otherUid = isMe ? call.receiverId : call.callerId;

            return FutureBuilder<UserModel?>(
              future: auth.getUserById(otherUid),
              builder: (context, userSnap) {
                final user = userSnap.data;
                final name = user?.name ?? '...';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                return ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.teal,
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  title: Text(name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMissed ? Colors.red : Colors.black87,
                      )),
                  subtitle: Row(
                    children: [
                      Icon(
                        isMe ? Icons.call_made : Icons.call_received,
                        size: 14,
                        color: isMissed ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(call.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      call.type == CallType.video
                          ? Icons.videocam_outlined
                          : Icons.call_outlined,
                      color: AppColors.teal,
                    ),
                    onPressed: user == null
                        ? null
                        : () {
                            final callId =
                                '${myUid}_${otherUid}_${DateTime.now().millisecondsSinceEpoch}';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CallScreen(
                                  channelName: callId,
                                  remoteUserName: name,
                                  isVideo: call.type == CallType.video,
                                  isIncoming: false,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

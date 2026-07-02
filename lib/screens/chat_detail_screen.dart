import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _auth = AuthService();
  final _chat = ChatService();

  @override
  void initState() {
    super.initState();
    _chat.markAsRead(widget.chatId, _auth.currentUid ?? '');
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await _chat.sendMessage(
      chatId: widget.chatId,
      senderId: _auth.currentUid ?? '',
      text: text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startCall({required bool isVideo}) async {
    final myUid = _auth.currentUid ?? '';
    final myUser = await _auth.getUserById(myUid);
    final callId = '${myUid}_${widget.otherUser.uid}_${DateTime.now().millisecondsSinceEpoch}';

    await CallService.sendCallSignal(
      callId: callId,
      callerId: myUid,
      callerName: myUser?.name ?? 'Unknown',
      receiverId: widget.otherUser.uid,
      callType: isVideo ? 'video' : 'voice',
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelName: callId,
            remoteUserName: widget.otherUser.name,
            isVideo: isVideo,
            isIncoming: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _auth.currentUid ?? '';
    final other = widget.otherUser;

    return Scaffold(
      backgroundColor: AppColors.chatBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<UserModel?>(
          stream: _chat.watchUser(other.uid),
          builder: (context, snap) {
            final live = snap.data ?? other;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Text(
                    live.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.teal, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        live.isOnline ? 'online' : 'last seen recently',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _startCall(isVideo: true),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startCall(isVideo: false),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (_) {},
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('View contact')),
              PopupMenuItem(value: 'media', child: Text('Media')),
              PopupMenuItem(value: 'search', child: Text('Search')),
              PopupMenuItem(value: 'mute', child: Text('Mute')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chat.getMessages(widget.chatId),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pesan. Say hi! 👋',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == myUid;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.bubbleOut : AppColors.bubbleIn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isMe ? 10 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 10),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 1,
                offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text,
                style: const TextStyle(fontSize: 14.5, color: Colors.black87)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF34B7F1)
                        : Colors.black45,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined,
                            color: Colors.grey),
                        onPressed: () {}),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: () {}),
                    IconButton(
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: Colors.grey),
                        onPressed: () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.teal,
              child: IconButton(
                icon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, val, __) => Icon(
                    val.text.trim().isEmpty ? Icons.mic : Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

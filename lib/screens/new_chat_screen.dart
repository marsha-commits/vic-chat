import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _phoneController = TextEditingController();
  final _auth = AuthService();
  final _chat = ChatService();
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() { _loading = true; _error = null; });

    final results = await _chat.searchUserByPhone(phone);
    setState(() => _loading = false);

    if (results.isEmpty) {
      setState(() => _error = 'User tidak ditemukan');
      return;
    }

    final other = results.first;
    final myUid = _auth.currentUid!;

    if (other.uid == myUid) {
      setState(() => _error = 'Itu nomor kamu sendiri 😅');
      return;
    }

    await _chat.createChatRoomIfNotExists(myUid, other.uid);
    final chatId = _chat.getChatId(myUid, other.uid);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatId: chatId, otherUser: other),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Baru')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_search, size: 60, color: AppColors.teal),
            const SizedBox(height: 16),
            const Text('Masukkan nomor HP teman kamu\n(format: +62xxxx)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+628123456789',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cari', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../constants/app_constants.dart';
import 'chats_tab.dart';
import 'status_tab.dart';
import 'calls_tab.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    _auth.setOnlineStatus(true);
    _listenIncomingCalls();
  }

  void _listenIncomingCalls() {
    final myUid = _auth.currentUid;
    if (myUid == null) return;

    CallService.listenIncomingCall(myUid).listen((signal) {
      if (signal != null && mounted) {
        _showIncomingCallDialog(signal);
      }
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> signal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Panggilan Masuk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.teal.withOpacity(0.15),
              child: const Icon(Icons.person, size: 36, color: AppColors.teal),
            ),
            const SizedBox(height: 12),
            Text(
              signal['callerName'] ?? 'Unknown',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              signal['callType'] == 'video'
                  ? 'Video Call masuk...'
                  : 'Voice Call masuk...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.call_end, color: Colors.red),
            label: const Text('Tolak', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await CallService.updateCallStatus(signal['callId'], 'rejected');
              if (mounted) Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('Angkat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await CallService.updateCallStatus(signal['callId'], 'answered');
              Navigator.pop(context);
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      channelName: signal['callId'],
                      remoteUserName: signal['callerName'] ?? 'Unknown',
                      isVideo: signal['callType'] == 'video',
                      isIncoming: true,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _auth.setOnlineStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vic Chat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'logout') {
                await _auth.signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'group', child: Text('New group')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CALLS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          ChatsTab(),
          StatusTab(),
          CallsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        onPressed: () {},
        child: Icon(
          [Icons.message, Icons.camera_alt, Icons.add_call][_tab.index],
          color: Colors.white,
        ),
      ),
    );
  }
}

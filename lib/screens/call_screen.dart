import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';
import '../constants/app_constants.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String remoteUserName;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.remoteUserName,
    required this.isVideo,
    required this.isIncoming,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _callEnded = false;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    final hasPermission =
        await CallService.requestPermissions(video: widget.isVideo);
    if (!hasPermission) {
      _showPermissionError();
      return;
    }

    if (widget.isVideo) {
      await CallService.startVideoCall(
        channelName: widget.channelName,
        onUserJoined: (uid, _) {
          setState(() => _remoteUid = uid);
          _startTimer();
        },
        onUserOffline: (uid, _) {
          setState(() => _remoteUid = null);
          _endCall();
        },
        onJoinSuccess: () => setState(() => _localUserJoined = true),
      );
    } else {
      await CallService.startVoiceCall(
        channelName: widget.channelName,
        onUserJoined: (uid, _) {
          setState(() => _remoteUid = uid);
          _startTimer();
        },
        onUserOffline: (uid, _) {
          setState(() => _remoteUid = null);
          _endCall();
        },
        onJoinSuccess: () => setState(() => _localUserJoined = true),
      );
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _callEnded) return false;
      setState(() => _secondsElapsed++);
      return true;
    });
  }

  String get _callDuration {
    final m = _secondsElapsed ~/ 60;
    final s = _secondsElapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    setState(() => _callEnded = true);
    await CallService.endCall();
    if (mounted) Navigator.pop(context);
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
            'Izin mikrofon/kamera dibutuhkan untuk melakukan panggilan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    CallService.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.isVideo ? _buildVideoCall() : _buildVoiceCall(),
    );
  }

  // ─── VIDEO CALL UI ────────────────────────────────────────────────────────
  Widget _buildVideoCall() {
    return Stack(
      children: [
        // Remote video (full screen)
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: CallService.engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
            : _buildWaitingScreen(),

        // Local video (small, pojok kanan atas)
        if (_localUserJoined && !_isCameraOff)
          Positioned(
            right: 16,
            top: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 160,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: CallService.engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          ),

        // Top info
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.remoteUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _remoteUid != null
                              ? _callDuration
                              : 'Memanggil...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildCallControls(isVideo: true),
        ),
      ],
    );
  }

  // ─── VOICE CALL UI ────────────────────────────────────────────────────────
  Widget _buildVoiceCall() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top info
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.teal.withOpacity(0.2),
                  child: Text(
                    widget.remoteUserName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _remoteUid != null ? _callDuration : 'Memanggil...',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),

          // Bottom controls
          _buildCallControls(isVideo: false),
        ],
      ),
    );
  }

  // ─── SHARED CONTROLS ─────────────────────────────────────────────────────
  Widget _buildCallControls({required bool isVideo}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 48, top: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: _isMuted ? 'Unmute' : 'Mute',
                onTap: () async {
                  setState(() => _isMuted = !_isMuted);
                  await CallService.toggleMic(_isMuted);
                },
              ),
              if (isVideo)
                _ControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  label: _isCameraOff ? 'Cam On' : 'Cam Off',
                  onTap: () async {
                    setState(() => _isCameraOff = !_isCameraOff);
                    await CallService.toggleCamera(_isCameraOff);
                  },
                ),
              if (!isVideo)
                _ControlButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                  label: _isSpeakerOn ? 'Speaker' : 'Earphone',
                  onTap: () async {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                    await CallService.toggleSpeaker(_isSpeakerOn);
                  },
                ),
              if (isVideo)
                _ControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Flip',
                  onTap: () async => await CallService.switchCamera(),
                ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.teal.withOpacity(0.2),
              child: Text(
                widget.remoteUserName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.remoteUserName,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 12),
            const Text('Menunggu...',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

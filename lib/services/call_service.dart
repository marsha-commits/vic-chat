import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class CallService {
  static RtcEngine? _engine;

  static RtcEngine get engine {
    if (_engine == null) throw Exception('CallService belum di-init');
    return _engine!;
  }

  /// Init Agora engine (panggil 1x waktu app start atau sebelum call)
  static Future<void> init() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: agoraAppId));
  }

  /// Minta izin mikrofon dan kamera
  static Future<bool> requestPermissions({bool video = true}) async {
    final permissions = [Permission.microphone];
    if (video) permissions.add(Permission.camera);
    final results = await permissions.request();
    return results.values.every((s) => s.isGranted);
  }

  /// Mulai video call — join channel Agora
  static Future<void> startVideoCall({
    required String channelName,
    required void Function(int uid, int elapsed) onUserJoined,
    required void Function(int uid, UserOfflineReasonType reason) onUserOffline,
    required void Function() onJoinSuccess,
  }) async {
    await _engine!.enableVideo();
    await _engine!.startPreview();

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => onJoinSuccess(),
      onUserJoined: (connection, uid, elapsed) => onUserJoined(uid, elapsed),
      onUserOffline: (connection, uid, reason) => onUserOffline(uid, reason),
      onError: (err, msg) => print('Agora error $err: $msg'),
    ));

    await _engine!.joinChannel(
      token: agoraToken ?? '',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  /// Mulai voice call — join channel Agora tanpa video
  static Future<void> startVoiceCall({
    required String channelName,
    required void Function(int uid, int elapsed) onUserJoined,
    required void Function(int uid, UserOfflineReasonType reason) onUserOffline,
    required void Function() onJoinSuccess,
  }) async {
    await _engine!.disableVideo();

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => onJoinSuccess(),
      onUserJoined: (connection, uid, elapsed) => onUserJoined(uid, elapsed),
      onUserOffline: (connection, uid, reason) => onUserOffline(uid, reason),
    ));

    await _engine!.joinChannel(
      token: agoraToken ?? '',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  /// Keluar dari channel
  static Future<void> endCall() async {
    await _engine?.leaveChannel();
    await _engine?.stopPreview();
  }

  /// Toggle mute mikrofon
  static Future<void> toggleMic(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  /// Toggle kamera
  static Future<void> toggleCamera(bool disabled) async {
    await _engine?.muteLocalVideoStream(disabled);
  }

  /// Ganti kamera depan/belakang
  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Toggle speaker
  static Future<void> toggleSpeaker(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  /// Destroy engine (panggil di dispose)
  static Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  /// ─── SIGNALING via Firestore ──────────────────────────────────────────────
  /// Simpan sinyal panggilan keluar di Firestore agar penerima bisa terima
  static Future<void> sendCallSignal({
    required String callId,
    required String callerId,
    required String callerName,
    required String receiverId,
    required String callType, // 'voice' atau 'video'
  }) async {
    await FirebaseFirestore.instance.collection('call_signals').doc(callId).set({
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'callType': callType,
      'status': 'ringing',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Jawab panggilan / tolak
  static Future<void> updateCallStatus(String callId, String status) async {
    await FirebaseFirestore.instance
        .collection('call_signals')
        .doc(callId)
        .update({'status': status});
  }

  /// Listen sinyal panggilan masuk untuk user tertentu
  static Stream<Map<String, dynamic>?> listenIncomingCall(String myUid) {
    return FirebaseFirestore.instance
        .collection('call_signals')
        .where('receiverId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snap) =>
            snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── USER ────────────────────────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String? photoUrl;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.photoUrl,
    this.status = 'Hey there! I am using WaClone',
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? 'Unknown',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'Hey there! I am using WaClone',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phone': phone,
    'name': name,
    'photoUrl': photoUrl,
    'status': status,
    'isOnline': isOnline,
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
  };
}

/// ─── MESSAGE ─────────────────────────────────────────────────────────────────
enum MessageType { text, image, audio, call }

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    'senderId': senderId,
    'text': text,
    'type': type.name,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
  };
}

/// ─── CHAT ROOM ───────────────────────────────────────────────────────────────
class ChatRoom {
  final String chatId;
  final List<String> members;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastSenderId;

  const ChatRoom({
    required this.chatId,
    required this.members,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId = '',
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      chatId: map['chatId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: map['lastSenderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'members': members,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime != null
        ? Timestamp.fromDate(lastMessageTime!)
        : null,
    'lastSenderId': lastSenderId,
  };
}

/// ─── CALL LOG ────────────────────────────────────────────────────────────────
enum CallType { voice, video }
enum CallStatus { ongoing, ended, missed, rejected }

class CallLog {
  final String callId;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime timestamp;
  final int durationSeconds;

  const CallLog({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.timestamp,
    this.durationSeconds = 0,
  });

  factory CallLog.fromMap(Map<String, dynamic> map) {
    return CallLog(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'voice'),
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'ended'),
        orElse: () => CallStatus.ended,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'callId': callId,
    'callerId': callerId,
    'receiverId': receiverId,
    'type': type.name,
    'status': status.name,
    'timestamp': Timestamp.fromDate(timestamp),
    'durationSeconds': durationSeconds,
  };
}

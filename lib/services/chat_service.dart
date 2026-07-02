import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Buat atau ambil chat room antara 2 user
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> createChatRoomIfNotExists(
      String myUid, String otherUid) async {
    final chatId = getChatId(myUid, otherUid);
    final ref = _db.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      final room = ChatRoom(
        chatId: chatId,
        members: [myUid, otherUid],
      );
      await ref.set(room.toMap());
    }
  }

  /// Kirim pesan
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      messageId: messageId,
      senderId: senderId,
      text: text,
      type: type,
      timestamp: now,
    );

    final batch = _db.batch();

    // Simpan pesan
    batch.set(
      _db.collection('chats').doc(chatId).collection('messages').doc(messageId),
      message.toMap(),
    );

    // Update last message di chat room
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });

    await batch.commit();
  }

  /// Stream pesan real-time
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromMap(d.data())).toList());
  }

  /// Stream semua chat room milik user
  Stream<List<ChatRoom>> getChatRooms(String uid) {
    return _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatRoom.fromMap(d.data())).toList());
  }

  /// Tandai pesan sebagai sudah dibaca
  Future<void> markAsRead(String chatId, String myUid) async {
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: myUid)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Cari user berdasarkan nomor HP
  Future<List<UserModel>> searchUserByPhone(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  /// Stream data user tertentu (buat nampilkan online status)
  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null,
    );
  }

  /// Simpan log panggilan
  Future<void> saveCallLog(CallLog log) async {
    await _db.collection('calls').doc(log.callId).set(log.toMap());
  }

  /// Stream log panggilan user
  Stream<List<CallLog>> getCallLogs(String uid) {
    return _db
        .collection('calls')
        .where(Filter.or(
          Filter('callerId', isEqualTo: uid),
          Filter('receiverId', isEqualTo: uid),
        ))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CallLog.fromMap(d.data())).toList());
  }
}

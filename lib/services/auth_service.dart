import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kirim OTP ke nomor HP
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verify on Android
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Verifikasi OTP yang diinput user
  Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Simpan atau update data user di Firestore
  Future<void> saveUserToFirestore({
    required String name,
    String? photoUrl,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    final user = UserModel(
      uid: uid,
      phone: currentUser?.phoneNumber ?? '',
      name: name,
      photoUrl: photoUrl,
      isOnline: true,
    );

    await _firestore.collection('users').doc(uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Cek apakah user sudah punya profil
  Future<bool> hasProfile() async {
    final uid = currentUid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['name'] ?? '').toString().isNotEmpty;
  }

  /// Update status online
  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Logout
  Future<void> signOut() async {
    await setOnlineStatus(false);
    await _auth.signOut();
  }

  /// Ambil data user dari Firestore
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Stream user sendiri
  Stream<UserModel?> get currentUserStream {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots().map(
      (snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null,
    );
  }
}

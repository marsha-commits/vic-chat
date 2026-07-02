import 'package:flutter/material.dart';

/// ─── GANTI DENGAN APP ID AGORA KAMU ─────────────────────────────────────────
/// Daftar gratis di https://console.agora.io
/// Buat project → ambil App ID → paste di sini
const String agoraAppId = 'YOUR_AGORA_APP_ID';

/// Token Agora (null = no-auth mode — oke buat development)
/// Untuk production, buat token server: https://docs.agora.io/en/video-calling/token-authentication
const String? agoraToken = null;

/// ─── WARNA APLIKASI ──────────────────────────────────────────────────────────
class AppColors {
  static const teal       = Color(0xFF075E54);
  static const tealLight  = Color(0xFF128C7E);
  static const green      = Color(0xFF25D366);
  static const bubbleOut  = Color(0xFFDCF8C6);
  static const bubbleIn   = Colors.white;
  static const chatBg     = Color(0xFFECE5DD);
  static const appBar     = Color(0xFF075E54);
}

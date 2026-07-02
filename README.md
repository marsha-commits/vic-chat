# WaClone – Flutter Chat & Video Call App

WhatsApp clone dengan **chat real-time**, **video call**, dan **voice call** sungguhan.

---

## 🛠 Tech Stack

| Layer | Tool |
|-------|------|
| UI | Flutter |
| Auth | Firebase Phone Auth (OTP) |
| Database | Cloud Firestore (real-time) |
| Storage | Firebase Storage |
| Video/Voice Call | Agora RTC Engine |

---

## ⚙️ Setup – Wajib Dilakukan Sebelum Run

### 1. Buat Firebase Project

1. Buka [console.firebase.google.com](https://console.firebase.google.com)
2. Klik **Add project** → beri nama (misal: `wa-clone`)
3. Di sidebar, klik **Authentication** → **Sign-in method** → aktifkan **Phone**
4. Di sidebar, klik **Firestore Database** → **Create database** → pilih mode **Test** (dev)

### 2. Tambahkan App ke Firebase

#### Android
1. Di Firebase Console → **Project Settings** → **Add app** → pilih Android
2. Isi package name: `com.example.wa_clone`
3. Download `google-services.json`
4. Taruh di folder: `android/app/google-services.json`

#### iOS (opsional)
1. Add app → pilih iOS
2. Bundle ID: `com.example.waClone`
3. Download `GoogleService-Info.plist`
4. Taruh di `ios/Runner/GoogleService-Info.plist`

### 3. Setup Agora

1. Daftar gratis di [console.agora.io](https://console.agora.io)
2. **New Project** → beri nama → Auth Certificate: **Testing** (no token, gratis)
3. Salin **App ID**
4. Buka file `lib/constants/app_constants.dart`
5. Ganti `YOUR_AGORA_APP_ID` dengan App ID kamu:
   ```dart
   const String agoraAppId = 'abc123yourappid';
   ```

### 4. Update `android/build.gradle`

Pastikan ada ini di `android/build.gradle`:
```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Dan di `android/app/build.gradle` paling bawah:
```groovy
apply plugin: 'com.google.gms.google-services'
```

Juga pastikan `minSdkVersion` minimal **21**:
```groovy
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

---

## 🚀 Jalankan App

```bash
# Install dependencies
flutter pub get

# Run di device/emulator
flutter run
```

---

## 📁 Struktur Folder

```
lib/
├── constants/
│   └── app_constants.dart      ← Agora App ID + warna
├── models/
│   └── models.dart             ← UserModel, MessageModel, CallLog, dll
├── services/
│   ├── auth_service.dart       ← Firebase Phone Auth
│   ├── chat_service.dart       ← Firestore real-time chat
│   └── call_service.dart       ← Agora RTC + Firestore signaling
├── screens/
│   ├── login_screen.dart       ← Input nomor HP
│   ├── otp_screen.dart         ← 6-digit OTP verifikasi
│   ├── setup_profile_screen.dart
│   ├── home_screen.dart        ← Tab host + incoming call listener
│   ├── chats_tab.dart          ← Daftar chat real-time
│   ├── new_chat_screen.dart    ← Cari user by phone
│   ├── chat_detail_screen.dart ← Bubble chat real-time + tombol call
│   ├── call_screen.dart        ← Video & voice call screen (Agora)
│   ├── status_tab.dart
│   └── calls_tab.dart          ← Log panggilan dari Firestore
└── main.dart                   ← Firebase init + Auth routing
```

---

## 🔥 Fitur

- ✅ Login OTP (nomor HP asli, Firebase)
- ✅ Setup profil nama setelah login pertama
- ✅ Real-time chat (Firestore streaming)
- ✅ Read receipt (centang dua biru)
- ✅ Online/offline status
- ✅ Video call sungguhan (Agora)
- ✅ Voice call sungguhan (Agora)
- ✅ Incoming call notification + terima/tolak
- ✅ Kontrol call: mute, kamera off, flip kamera, speaker
- ✅ Timer durasi panggilan
- ✅ Log panggilan (Firestore)
- ✅ Cari user by nomor HP

---

## 🔮 Next Steps (belum ada, bisa lo tambahin)

- Push notification panggilan masuk (FCM + background handler)
- Kirim foto/file di chat
- Status / Stories
- Group chat
- Token Agora dari server (production security)
- Enkripsi pesan end-to-end

---

## ⚠️ Catatan Penting

- **Agora gratis**: 10.000 menit/bulan gratis — lebih dari cukup buat dev & testing
- **Firebase Phone Auth**: butuh nomor HP beneran. Buat testing, bisa tambahkan test numbers di Firebase Console → Authentication → Phone → Test phone numbers
- Kalau di emulator kamera tidak jalan, test di device fisik

# Security Audit

Tanggal audit: 2026-04-20

## Ringkasan

Project ini tidak memakai permission Android berisiko tinggi seperti kamera, mikrofon, lokasi, akses kontak, SMS, overlay, accessibility service, atau screen capture. Untuk iOS juga belum ada privacy permission string yang sensitif di `Info.plist`.

## Permission

- Android release manifest utama hanya berisi deklarasi aplikasi dan activity launcher.
- Permission `INTERNET` hanya ada di `android/app/src/debug/AndroidManifest.xml` dan `android/app/src/profile/AndroidManifest.xml` untuk kebutuhan development Flutter.
- Android sekarang diset `allowBackup=false` dan `usesCleartextTraffic=false` agar backup app data dan trafik HTTP plain tidak diizinkan secara default.
- iOS `ios/Runner/Info.plist` tidak berisi akses kamera, foto, mikrofon, lokasi, atau contact.

## Dependency

Dependency aplikasi yang aktif saat ini:

- `flutter_riverpod`: state management
- `go_router`: navigasi
- `hive`, `hive_flutter`: local storage
- `intl`: formatting
- `uuid`: id generator
- `google_fonts`: font styling
- `file_picker`: pilih/simpan file
- `excel`: import/export XLSX
- `pdf`, `printing`: generate dan print PDF/struk
- `open_filex`: buka file hasil export

Catatan:

- Tidak ada dependency yang mengindikasikan overlay, accessibility hook, remote control, keylogger, atau background surveillance.
- `file_picker`, `printing`, dan `open_filex` memang berinteraksi dengan file/print, jadi perilakunya harus dijaga tetap eksplisit dari aksi user.

## Temuan Penting

- `android/app/build.gradle.kts` masih memakai debug signing untuk build release. Ini aman untuk development, tetapi tidak ideal untuk distribusi production.
- `applicationId` masih `com.example.summary_global`. Untuk distribusi resmi, sebaiknya ganti ke namespace milik brand/publisher yang sah.
- Nama aplikasi Android sebelumnya masih generik. Sudah dirapikan ke `Summary Global`, tetapi untuk produksi lebih baik memakai nama brand final.

## Rekomendasi Lanjutan

1. Gunakan release signing key resmi sendiri sebelum distribusi.
2. Ganti `applicationId` dan bundle identifier ke identitas brand yang konsisten.
3. Distribusikan lewat channel resmi dan sediakan privacy policy + identitas publisher.
4. Hindari menambah package yang meminta overlay, accessibility, auto-start background, atau permission sensitif jika tidak benar-benar wajib.
5. Audit ulang manifest dan plist setiap kali menambah plugin baru.

# UI UX SPEC - Flutter Mobile Summary Report Cafe

## 1. Tujuan
Dokumen ini menjadi standar implementasi UI/UX untuk aplikasi Flutter mobile agar:
- Alur kasir cepat.
- Owner mudah baca kondisi bisnis harian.
- Pola komponen konsisten di seluruh fitur.

## 2. Prinsip UX Utama
- Cepat: aksi utama selesai dalam sedikit tap.
- Jelas: angka penting tampil di atas.
- Konsisten: istilah, warna status, posisi aksi stabil.
- Aman: aksi berisiko wajib konfirmasi.
- Ringkas: form pendek dan fokus pada data penting.

## 3. Informasi Arsitektur Mobile
Pola navigasi:
- App bar atas (burger/menu + judul + user action).
- Bottom navigation 4 tab:
  - Dashboard
  - Transaksi
  - Riwayat
  - Laporan
- Halaman tambahan dibuka dengan push route.

Menu tambahan (drawer/profile):
- Produk
- Pelanggan
- Pengeluaran
- Pengaturan
- Profil
- Logout

## 4. Visual Direction
Palet utama:
- Primary Red: `#B3261E`
- Primary Dark: `#7F1D1D`
- Background Cream: `#F7F1E8`
- Surface White: `#FFFFFF`
- Text Dark: `#1F2937`
- Muted Gray: `#6B7280`
- Border: `#D1D5DB`

Font:
- Heading: `Sora`
- Body/UI: `DM Sans`
- Nominal angka: `IBM Plex Sans`

## 5. Komponen Inti
- `AppTopBar`
- `BottomNavBar`
- `KpiCard`
- `ProductCard`
- `SummaryCard`
- `FilterChips`
- `DataListItem`
- `StatusBadge`
- `PrimaryButton`
- `ConfirmDialog`

Aturan status badge:
- Lunas: hijau.
- Pending: merah muda/merah gelap.
- Refund/Batal: merah tegas.

## 6. Screen Blueprint (Mobile)
### 6.1 Dashboard
- KPI ringkas (omzet, transaksi, pending, top payment).
- Chart tren pemasukan.
- Alert stok menipis.

### 6.2 Transaksi
- Search menu.
- Kategori via chips.
- List/card menu produk.
- Ringkasan order + total bayar.
- Aksi: Simpan, Bayar, Cetak.

### 6.3 Riwayat
- Filter cepat (tanggal/status/metode).
- List transaksi/pembayaran.
- Detail transaksi.

### 6.4 Laporan
- Preset tanggal (hari ini/minggu ini/bulan ini/custom).
- KPI laporan.
- Chart ringkas.
- Aksi export.

### 6.5 Login
- Email + password.
- Aksi login utama.
- Lupa password.
- Link ke halaman utama.

### 6.6 Landing (opsional mobile webview/promo)
- Hero value proposition.
- CTA login/demo.

## 7. UX Rules untuk Kasir
- Tombol aksi utama berada di area bawah dan mudah dijangkau ibu jari.
- Total bayar harus selalu terlihat menonjol.
- Minimalisasi input manual dengan pilihan cepat.
- Konfirmasi sebelum batal/hapus.

## 8. Responsive Rule (Mobile)
Target ukuran desain:
- 390 x 844 sebagai base frame.

Aturan:
- Safe area wajib dipatuhi.
- Tidak ada komponen penting tertutup keyboard.
- List panjang harus smooth scrolling.

## 9. Accessibility
- Kontras warna cukup.
- Tap target minimal 44x44.
- Label input jelas.
- Dukungan screen reader untuk elemen aksi utama.
- Error message spesifik dan mudah dipahami.

## 10. State Wajib
Setiap halaman data wajib punya:
- Loading
- Empty
- Error
- Success

## 11. Microcopy
- Gunakan bahasa Indonesia operasional.
- Konsisten istilah (`Pending`, `Lunas`, `Refund`).
- Hindari istilah teknis backend.

## 12. QA Checklist
- Alur transaksi standar <= 30 detik.
- Total bayar selalu benar.
- Filter berdampak ke data list/summary.
- State loading/empty/error muncul sesuai kondisi.
- Navigasi tab dan push route konsisten.
- UI tetap nyaman di Android dan iOS.

## 13. Handoff Flutter
- Semua style dipusatkan di `AppTheme`.
- Buat token warna + text style global.
- Komponen reusable disimpan di `lib/shared/widgets`.
- Jangan hardcode warna/font per halaman.

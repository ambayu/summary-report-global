# PRD - Aplikasi Flutter Mobile Summary Report Cafe

## 1. Overview
Nama produk:
- Summary Report Cafe (Flutter Mobile)

Platform target:
- Android
- iOS

Tujuan sistem:
- Membantu owner, admin, dan kasir memantau performa cafe dari aplikasi mobile.
- Mempercepat alur transaksi hingga pembayaran dari perangkat kasir.
- Menyediakan laporan penjualan, pengeluaran, dan profit sederhana dalam satu aplikasi.

Target pengguna:
- Owner
- Admin operasional
- Kasir

Dokumen pendamping:
- `ui-ux-spec.md`
- `route.md`
- `api-route.md`

## 2. Scope Versi
MVP:
- Dashboard
- Transaksi
- Riwayat Pembayaran
- Menu Produk
- Pelanggan
- Laporan
- Pengeluaran
- User Management
- Pengaturan

Fase lanjutan:
- Inventori
- Supplier
- Multi-cabang
- Promo lanjutan
- Loyalty lanjutan

## 3. Functional Requirements
### 3.1 Dashboard
- Total pemasukan hari ini.
- Jumlah transaksi hari ini.
- Jumlah transaksi pending.
- Metode pembayaran paling sering dipakai.
- Produk terlaris.
- Grafik pemasukan harian dan mingguan.
- Peringatan stok menipis (jika inventori aktif).

### 3.2 Transaksi dan Pembayaran
Buat transaksi baru:
- Pilih meja/nomor order.
- Pilih item menu.
- Input qty dan catatan.
- Terapkan diskon.
- Hitung pajak/service charge otomatis.
- Pilih metode pembayaran.
- Status bayar: lunas, pending, split bill.

Daftar transaksi:
- Filter tanggal, kasir, metode bayar, status.
- Lihat detail transaksi.
- Edit transaksi tertentu (sesuai role).
- Batalkan transaksi.
- Cetak/share struk.

Riwayat pembayaran:
- Cash
- QRIS
- Debit/kredit
- E-wallet
- Transfer

### 3.3 Produk/Menu
- CRUD menu.
- Kategori menu.
- Harga jual.
- Foto produk.
- Status tersedia/habis.
- Varian/ukuran.
- Topping/bahan tambahan.
- Harga modal opsional.

### 3.4 Pelanggan
- Nama dan nomor HP.
- Riwayat transaksi pelanggan.
- Total pembelian.
- Member point/loyalty.
- Penanda pelanggan favorit.

### 3.5 Meja/Order
- Daftar meja.
- Status meja: kosong, terisi, selesai.
- Pindah meja.
- Gabung order.
- Pisah bill.

### 3.6 Laporan
- Harian, mingguan, bulanan.
- Per produk, kategori, kasir, metode pembayaran.
- Diskon, refund, profit sederhana.
- Filter tanggal.
- Export Excel/PDF.

### 3.7 Pengeluaran
- Input biaya operasional.
- Kategori pengeluaran.
- Laporan pengeluaran.
- Laba-rugi sederhana.

### 3.8 User Management
- Kelola user.
- Kelola role dan hak akses.
- Aktivitas user.
- Reset password.

Role standar:
- Owner: akses penuh.
- Admin: operasional + laporan.
- Kasir: transaksi dan riwayat transaksi.

### 3.9 Pengaturan
- Profil cafe.
- Logo.
- Kontak.
- Pajak/service charge.
- Metode pembayaran aktif.
- Printer struk.
- Format struk.
- Jam operasional.
- Backup data.

## 4. Non-Functional Requirements
- Mobile-first UI (Android/iOS).
- Waktu buka halaman utama <= 2 detik pada perangkat menengah.
- Input transaksi cepat, target <= 30 detik untuk transaksi standar.
- Role-based access control.
- Audit log untuk aksi finansial penting.
- Error handling ramah user dan retry untuk request gagal.

## 5. Arsitektur Sistem
Frontend mobile:
- Flutter
- `go_router` untuk navigasi
- State management: Riverpod atau Bloc (pilih salah satu konsisten)
- HTTP client: Dio

Backend:
- NestJS
- Prisma
- JWT
- RBAC (roles + permissions)

Database:
- MySQL

## 6. Struktur Data Inti
Entity utama:
- users
- roles
- products
- categories
- transactions
- transaction_items
- payments
- customers
- expenses
- expense_categories
- settings

Entity tambahan rekomendasi:
- tables
- refunds
- audit_logs
- branches (untuk multi-cabang)

## 7. KPI dan Success Metrics
- Transaksi kasir selesai <= 30 detik.
- Error input transaksi turun >= 50% dibanding proses manual.
- Owner bisa akses insight utama <= 3 tap dari dashboard.
- Export laporan sukses > 95% percobaan.

## 8. Acceptance Criteria
- User bisa login dan akses menu sesuai role.
- Kasir bisa buat transaksi, simpan pending, dan selesaikan pembayaran.
- Owner bisa melihat dashboard harian dan laporan ringkas.
- Admin bisa mengelola produk, pelanggan, pengeluaran, user.
- Pengaturan pajak/service memengaruhi transaksi baru.
- Semua list utama mendukung filter dan pagination.

## 9. Rencana Implementasi Bertahap
Fase 1:
- Auth, Dashboard, Transaksi, Riwayat, Laporan dasar.

Fase 2:
- Produk, Pelanggan, Pengeluaran, Pengaturan, User Management.

Fase 3:
- Inventori, supplier, multi-cabang, loyalty/promo lanjutan.

# PAPER MCP STARTER - Flutter Mobile UI (Summary Report Cafe)

## 1. Tujuan
Dokumen ini adalah panduan cepat untuk membuat desain mobile di Paper MCP sebelum implementasi Flutter.

## 2. Theme Wajib
Warna:
- Primary Red: `#B3261E`
- Primary Dark: `#7F1D1D`
- Background Cream: `#F7F1E8`
- Surface White: `#FFFFFF`
- Text Dark: `#1F2937`
- Muted Gray: `#6B7280`
- Border: `#D1D5DB`

Font:
- Heading: `Sora`
- Body: `DM Sans`
- Nominal: `IBM Plex Sans`

## 3. Artboard Setup
Gunakan artboard mobile:
- Width: `390px`
- Height: `844px`

Buat frame minimum:
1. `Mobile - Login`
2. `Mobile - Dashboard`
3. `Mobile - Transaksi`
4. `Mobile - Riwayat`
5. `Mobile - Laporan`
6. `Mobile - Drawer/Profile Menu`

## 4. Struktur Per Frame
### 4.1 Login
- Logo/judul app
- Input email
- Input password
- Tombol `Masuk`
- Link `Lupa Password`

### 4.2 Dashboard
- Topbar: burger icon + judul + user icon
- KPI cards ringkas
- Chart pemasukan
- Alert stok menipis
- Bottom nav (Dashboard aktif)

### 4.3 Transaksi
- Topbar
- Search menu
- Filter kategori (chips)
- List/card produk
- Ringkasan order + total
- Tombol aksi transaksi
- Bottom nav (Transaksi aktif)

### 4.4 Riwayat
- Topbar
- Filter cepat
- List transaksi
- Status badge lunas/pending
- Bottom nav (Riwayat aktif)

### 4.5 Laporan
- Topbar
- Preset filter tanggal
- KPI laporan
- Chart ringkas
- Tombol export
- Bottom nav (Laporan aktif)

### 4.6 Drawer/Profile Menu
- Avatar + nama user
- Menu: Produk, Pelanggan, Pengeluaran, Pengaturan, Profil
- Tombol logout

## 5. State Wajib
Untuk tiap frame utama data:
- Default
- Loading
- Empty
- Error

## 6. Flow Prototype Minimum
Flow 1 (Kasir):
1. Login
2. Transaksi
3. Bayar
4. Cetak struk

Flow 2 (Owner):
1. Login
2. Dashboard
3. Laporan
4. Export

## 7. Prompt Paper MCP Siap Pakai
"Buat desain mobile app Flutter Summary Report Cafe ukuran 390x844 dengan 6 frame: Login, Dashboard, Transaksi, Riwayat, Laporan, dan Drawer/Profile Menu. Gunakan tema merah (#B3261E), abu, putih, cream (#F7F1E8), font Sora untuk heading dan DM Sans untuk body. Tambahkan state default/loading/empty/error untuk frame data dan gunakan bottom nav 4 tab: Dashboard, Transaksi, Riwayat, Laporan." 

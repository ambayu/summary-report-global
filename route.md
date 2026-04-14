# Route Structure - Flutter Mobile (Summary Report Cafe)

## 1. Tujuan
Dokumen ini menjadi acuan route untuk aplikasi **Flutter mobile** (Android/iOS) Summary Report Cafe.

Prinsip:
- Navigasi cepat untuk kasir.
- Struktur jelas untuk owner/admin.
- Siap dipakai dengan `go_router`.

## 2. Navigation Pattern (Mobile)
Pola utama:
- `Auth Flow` untuk login.
- `Main Shell` dengan bottom navigation 4 tab.
- Detail page memakai push route di atas tab aktif.

Bottom tab utama:
- Dashboard
- Transaksi
- Riwayat
- Laporan

## 3. Route List (Mobile)
### 3.1 Auth
- `/splash` -> cek sesi awal
- `/login` -> login
- `/forgot-password` -> lupa password

### 3.2 Main Shell (Bottom Tabs)
- `/dashboard` -> tab dashboard
- `/transaksi` -> tab transaksi kasir
- `/riwayat` -> tab riwayat transaksi/pembayaran
- `/laporan` -> tab laporan ringkas

### 3.3 Stack Routes di atas Tab
Transaksi:
- `/transaksi/new` -> transaksi baru
- `/transaksi/:transactionId` -> detail transaksi
- `/transaksi/:transactionId/edit` -> edit transaksi
- `/transaksi/:transactionId/payment` -> proses pembayaran

Riwayat:
- `/riwayat/:transactionId` -> detail riwayat transaksi
- `/riwayat/payment/:paymentId` -> detail pembayaran

Laporan:
- `/laporan/filter` -> filter laporan
- `/laporan/detail/:reportType` -> detail laporan per tipe

### 3.4 Menu Tambahan (Drawer / Profile Menu)
- `/produk` -> daftar menu produk
- `/produk/tambah` -> tambah produk
- `/produk/:productId/edit` -> edit produk
- `/pelanggan` -> daftar pelanggan
- `/pelanggan/:customerId` -> detail pelanggan
- `/pengeluaran` -> daftar/input pengeluaran
- `/pengeluaran/:expenseId/edit` -> edit pengeluaran
- `/pengaturan` -> pengaturan umum
- `/profil` -> profil user

## 4. Role Access (Mobile)
- Owner:
  - akses semua route
- Admin:
  - semua operasional kecuali aksi sensitif tertentu
- Kasir:
  - `/dashboard`
  - `/transaksi*`
  - `/riwayat*`
  - akses terbatas ke `/pelanggan`

## 5. go_router Recommendation
Gunakan `StatefulShellRoute` untuk bottom tabs.

Contoh struktur:
```dart
/splash
/login

StatefulShellRoute.indexedStack (
  /dashboard
  /transaksi
  /riwayat
  /laporan
)

/transaksi/new
/transaksi/:transactionId
/transaksi/:transactionId/edit
/transaksi/:transactionId/payment

/riwayat/:transactionId
/riwayat/payment/:paymentId

/laporan/filter
/laporan/detail/:reportType

/produk
/produk/tambah
/produk/:productId/edit
/pelanggan
/pelanggan/:customerId
/pengeluaran
/pengeluaran/:expenseId/edit
/pengaturan
/profil
```

## 6. Naming Rules
- Gunakan lowercase + kebab-case untuk path yang terdiri dari 2 kata.
- Gunakan parameter route konsisten: `:transactionId`, `:productId`, `:customerId`.
- Hindari nested route terlalu dalam (> 3 level) untuk mobile.

## 7. Suggested Flutter Folder Structure
```txt
lib/
  app/
    router/
      app_router.dart
      route_names.dart
  features/
    auth/
    dashboard/
    transaksi/
    riwayat/
    laporan/
    produk/
    pelanggan/
    pengeluaran/
    pengaturan/
    profil/
  shared/
    widgets/
    theme/
    utils/
```

## 8. API Impact
Tidak ada perubahan besar di backend route.
Frontend Flutter cukup konsumsi endpoint pada `api-route.md` yang sudah ada.

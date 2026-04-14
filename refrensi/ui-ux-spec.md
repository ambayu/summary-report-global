UI UX SPEC - Website Bagian Organisasi Pemerintah Kota Medan

## 1. Tujuan Dokumen
Dokumen ini menjadi standar UI UX implementasi agar:
- Pengalaman pengguna konsisten di seluruh halaman publik dan admin
- Keputusan desain bisa direplikasi untuk aplikasi berikutnya
- Tim dev, desain, dan QA memakai acuan yang sama

Dokumen ini melengkapi PRD, bukan menggantikan PRD.

## 2. Prinsip UX
Prinsip utama:
- Jelas: pengguna langsung paham fungsi halaman dalam 5 detik
- Ringkas: satu halaman fokus pada satu tujuan utama
- Konsisten: pola komponen, istilah, dan perilaku tidak berubah-ubah
- Cepat: interaksi utama terasa responsif di desktop dan mobile
- Aman: aksi berisiko (hapus, ubah massal) selalu ada konfirmasi

## 3. Informasi Arsitektur dan Navigasi
Publik:
- Beranda
- Profil
- Struktur
- Berita
- SOP

Admin:
- Dashboard
- Berita
- SOP
- Struktur
- Site Content
- Users
- Roles
- Permissions

Aturan navigasi:
- Nama menu, slug route, nama folder page, dan nama komponen harus konsisten
- Breadcrumb opsional untuk halaman detail dan form
- CTA primer ditempatkan konsisten di area atas kanan konten

## 4. Desain Visual Dasar
Tipografi:
- Heading: font heading proyek
- Body: font body proyek
- Gunakan maksimal 3 level heading dalam satu layar

Warna:
- Warna utama mengikuti token primary proyek
- Warna status:
  - info
  - success
  - warning
  - danger
- Kontras teks minimal memenuhi standar aksesibilitas

Spacing dan radius:
- Gunakan skala spacing konsisten (4, 8, 12, 16, 20, 24, 32)
- Radius komponen mengikuti pola panel dan input yang sudah ada

Shadow dan border:
- Surface utama memakai border halus dan shadow ringan
- Jangan tumpuk terlalu banyak efek visual dalam satu komponen

## 5. Aturan Komponen Umum
Button:
- Variants: primary, secondary, ghost, danger
- State wajib: default, hover, focus, disabled, loading

Input dan Select:
- Wajib punya visible label yang jelas
- Placeholder hanya pelengkap, bukan pengganti label
- Error message harus spesifik, bukan generik

Upload file:
- Field gambar wajib upload file, tidak boleh input URL manual
- Field dokumen wajib upload file sesuai tipe yang diizinkan
- Allowlist minimal:
  - Gambar: PNG, JPG/JPEG, WEBP
  - Dokumen: PDF
- Validasi tipe dan ukuran file wajib dilakukan di frontend dan backend

Badge:
- Dipakai untuk status ringkas
- Jangan gunakan badge untuk paragraf panjang

Modal dan Dialog:
- Dipakai untuk konfirmasi aksi destruktif
- Tombol aksi berisiko wajib jelas dan tidak ambigu

Toast atau Alert:
- Sukses: jelas menyebut aksi yang berhasil
- Gagal: jelas menyebut apa yang gagal dan langkah lanjut

## 6. Aturan Data Table
Table admin harus menggunakan komponen DataTable reusable.

Aturan struktur:
- Kolom didefinisikan lewat konfigurasi
- Sorting, filtering, dan aksi baris dikontrol lewat props
- Desktop memakai grid table, mobile memakai card mode

Aturan pagination:
- Wajib server-side pagination
- API list wajib menerima query:
  - page
  - perPage
  - search (opsional)
- UI pagination wajib membaca:
  - meta.page
  - meta.perPage
  - meta.totalItems
  - meta.totalPages

Aturan perPage:
- Pilihan perPage wajib tersedia: 10, 20, 50
- Nilai default perPage: 10
- Saat perPage berubah, halaman kembali ke page 1
- Perubahan perPage harus memicu request API baru

Aturan search dan filter:
- Search input harus debounce atau deferred
- Filter cepat dipakai untuk skenario paling sering
- Filter manual harus bisa dihapus satu per satu atau reset semua

Aturan empty, loading, error:
- Loading: skeleton atau teks loading yang jelas
- Empty: tampilkan pesan dan arahkan ke aksi tambah data bila relevan
- Error: tampilkan pesan gagal dan opsi retry bila memungkinkan

Aturan skeleton component (reusable):
- Wajib tersedia komponen `Skeleton` generik untuk loading state lintas halaman
- Untuk halaman form, gunakan komponen turunan seperti `FormPageSkeleton`
- Untuk halaman tabel, gunakan `SkeletonTable`
- Untuk halaman list card/grid, gunakan `SkeletonCardGrid`
- Skeleton harus dipakai saat data edit form masih loading agar field kosong tidak sempat tampil
- Skeleton harus mempertahankan layout akhir (tinggi dan struktur mendekati komponen final)

## 7. Aturan Form
Aturan layout:
- Form panjang dibagi per section
- Tombol simpan dan batal selalu terlihat jelas

Aturan validasi:
- Validasi field wajib dilakukan sebelum submit
- Pesan validasi ditampilkan dekat field terkait
- Submit button berubah ke loading saat proses simpan

Aturan edit:
- Mode tambah dan edit menggunakan pola halaman yang sama
- Tombol kembali ke list selalu tersedia

## 8. State dan Microcopy
State minimal per halaman:
- Initial
- Loading
- Success
- Empty
- Error

Aturan microcopy:
- Gunakan bahasa Indonesia yang lugas
- Hindari istilah teknis internal untuk user non-teknis
- Konsisten antara label menu, judul halaman, dan aksi tombol

## 9. Responsive Behavior
Breakpoint utama:
- Mobile
- Tablet
- Desktop

Aturan responsive:
- Konten utama tetap terbaca tanpa zoom di mobile
- Aksi penting tidak tersembunyi di layar kecil
- Table wajib punya versi card di mobile
- Sidebar admin berubah ke drawer pada mobile

## 10. Accessibility
Checklist aksesibilitas:
- Semua input terhubung ke label
- Semua tombol bisa diakses keyboard
- Focus ring terlihat jelas
- Kontras warna teks memenuhi standar
- Elemen interaktif punya aria-label jika perlu
- Dialog trap focus saat terbuka

## 11. Motion dan Interaksi
Aturan motion:
- Gunakan transisi singkat dan konsisten
- Hindari animasi berlebihan yang mengganggu performa
- Hover dan active state harus memberi feedback jelas

## 12. QA Checklist UI UX
Sebelum merge, cek:
- Konsistensi spacing, radius, tipografi
- State loading, empty, error muncul dengan benar
- Pagination page dan perPage sinkron dengan API
- Search dan filter tidak merusak pagination
- Tampilan mobile dan desktop sama-sama usable
- Tidak ada teks placeholder yang tertinggal

## 13. Governance
Versioning dokumen:
- Perubahan aturan UI UX dicatat di changelog proyek
- Jika ada komponen baru, tambahkan aturan penggunaannya di dokumen ini

Kepatuhan:
- PR yang mengubah komponen inti harus menyebut dampak ke UI UX Spec
- Jika menyimpang dari spec, wajib ada alasan yang terdokumentasi

PRD - Website Bagian Organisasi Pemerintah Kota Medan

## 1. Overview
Nama produk:
- Website Bagian Organisasi Pemerintah Kota Medan

Dokumen pendamping:
- UI UX Spec ada di file `docs/ui-ux-spec.md` sebagai acuan khusus antarmuka, interaksi, dan usability.

Tujuan sistem:
- Menyediakan informasi resmi Bagian Organisasi Pemko Medan untuk publik.
- Menyediakan dashboard admin untuk mengelola seluruh konten publik dari satu panel.
- Menjamin data landing page, profil, berita, struktur, SOP, dan footer berasal dari database, bukan dari mock data.

Target pengguna:
- Masyarakat umum
- Pegawai pemerintah
- Admin Bagian Organisasi

## 2. Scope Fitur
Website publik:
- Beranda
- Profil Organisasi
- Struktur Organisasi
- Berita dan pengumuman
- Dokumen SOP

Dashboard admin:
- Login admin
- Dashboard ringkasan
- Manajemen berita
- Manajemen SOP
- Manajemen struktur organisasi
- Manajemen landing page dan footer
- Manajemen user
- Manajemen role
- Daftar permission

Konten landing page yang wajib bisa diatur dari admin:
- Hero badge
- Hero button utama dan sekunder
- Hero slides
- Deskripsi section profil
- Highlight profil
- Konten halaman profil
- CTA landing
- Footer title
- Footer address
- Footer email
- Footer copyright

## 3. Functional Requirements
Website publik:
- Menampilkan landing page dari data database
- Menampilkan berita terbaru dari data database
- Menampilkan struktur organisasi dari data database
- Menampilkan dokumen SOP dari data database
- Menampilkan footer dari data database

Admin:
- Login dengan JWT
- Sidebar menu tampil berdasarkan permission `resource:menu`
- Halaman dicek dengan permission `resource:view`
- Aksi create, update, delete dicek di backend dan frontend
- Perubahan data harus langsung bisa direfresh dengan SWR mutate

Manajemen berita:
- Tambah berita
- Edit berita
- Hapus berita
- Upload atau isi URL gambar

Manajemen SOP:
- Tambah SOP
- Edit SOP
- Hapus SOP

Manajemen struktur:
- Tambah struktur
- Edit struktur
- Hapus struktur

Manajemen landing dan footer:
- Kelola menu site content terpisah: hero slider, profil, CTA, footer
- Tambah, edit, hapus hero slide
- Tambah, edit, hapus profile highlight
- Edit CTA dan footer publik

## 4. Non-Functional Requirements
- Website responsif desktop dan mobile
- Konsisten menggunakan React + Vite + TailwindCSS di frontend
- Konsisten menggunakan NestJS + Prisma + MySQL di backend
- Data layer frontend menggunakan SWR
- Struktur kode modular dan mudah dikembangkan
- Tidak boleh ada ketergantungan `mockData` untuk konten publik produksi

## 5. Arsitektur
Frontend:
- React
- Vite
- TailwindCSS
- React Router
- SWR

Backend:
- NestJS
- Prisma
- JWT Authentication
- Permission guard per route

Database:
- MySQL

## 6. Resource dan Permission
Resource minimal:
- `dashboard`
- `news`
- `sop`
- `organization-structure`
- `site-content`
- `user`
- `role`
- `permission`

Action minimal:
- `menu`
- `view`
- `create`

Contoh permission:
- `news:menu`
- `news:view`
- `news:create`
- `site-content:menu`
- `site-content:view`
- `site-content:create`
- `user:menu`
- `user:view`
- `user:create`
- `role:menu`
- `role:view`
- `role:create`
- `permission:menu`
- `permission:view`
- `permission:create`

## 7. Frontend Structure Rules
Aturan utama:
- Folder admin wajib dikelompokkan per menu
- Satu menu admin wajib memiliki satu folder sendiri
- File list page dan form page harus berada dalam folder menu yang sama
- Page tidak boleh memanggil `useSWR(...)` langsung
- Page wajib memakai hook dari module API
- Data publik juga tidak boleh bergantung pada `mockData`

Struktur frontend yang benar:

```txt
src/
  api/
    client.ts
  components/
    ...
  config/
    adminMenu.ts
  modules/
    news/
      api.ts
    sop/
      api.ts
    structure/
      api.ts
    site-content/
      api.ts
    users/
      api.ts
    roles/
      api.ts
    permissions/
      api.ts
  pages/
    public/
      HomePage.tsx
      ProfilePage.tsx
      StructurePage.tsx
      NewsListPage.tsx
      NewsDetailPage.tsx
      SopPage.tsx
    admin/
      auth/
        LoginPage.tsx
        UnauthorizedPage.tsx
      dashboard/
        Page.tsx
        api.ts
      berita/
        Page.tsx
        FormPage.tsx
        api.ts
      sop/
        Page.tsx
        FormPage.tsx
        api.ts
      struktur/
        Page.tsx
        FormPage.tsx
        api.ts
      site-content/
        Page.tsx
        api.ts
      users/
        Page.tsx
        FormPage.tsx
        api.ts
      roles/
        Page.tsx
        FormPage.tsx
        api.ts
      permissions/
        Page.tsx
        api.ts
```

Penjelasan:
- `src/modules/<resource>/api.ts` adalah sumber hook SWR dan mutation yang reusable
- `src/pages/admin/<menu>/api.ts` boleh berupa wrapper atau re-export agar tetap satu folder dengan page menu
- `Page.tsx` hanya fokus pada UI dan interaksi halaman
- `FormPage.tsx` hanya fokus pada input, validasi, dan submit

## 8. Routing Rules
Route publik:

```txt
/
/profil
/struktur
/berita
/berita/:id
/sop
```

Route admin:

```txt
/admin
/admin/login
/admin/unauthorized

/admin/berita
/admin/berita/tambah
/admin/berita/:id/edit

/admin/sop
/admin/sop/tambah
/admin/sop/:id/edit

/admin/struktur
/admin/struktur/tambah
/admin/struktur/:id/edit

/admin/site-content
/admin/site-content/slider
/admin/site-content/slider/tambah
/admin/site-content/slider/:slideIndex/edit
/admin/site-content/profil
/admin/site-content/cta
/admin/site-content/footer

/admin/users
/admin/users/tambah
/admin/users/:id/edit

/admin/roles
/admin/roles/tambah
/admin/roles/:id/edit

/admin/permissions
```

Aturan route:
- List page dan form page harus dipisah
- Route `tambah` dipakai untuk create
- Route `:id/edit` dipakai untuk edit
- Untuk site content, route parent hanya sebagai pengelompokan menu dan harus diarahkan ke child route
- Hero slider wajib memakai route list terpisah dari route form tambah/edit
- `permission` adalah halaman daftar, sedangkan assign permission dilakukan di form role

Aturan konsistensi penamaan (wajib):
- Nama menu sidebar harus sama dengan slug route admin agar mudah dicari
- Nama folder page admin harus mengikuti slug route yang sama
- Nama komponen page admin harus mengikuti nama route (pascal case dari slug route)
- Hindari alias nama berbeda untuk route yang sama (contoh: route `berita` tapi folder `news`)

Contoh konsisten:
- Route `/admin/berita` -> menu `Berita` -> folder `pages/admin/berita` -> komponen `AdminBeritaPage`
- Route `/admin/struktur` -> menu `Struktur` -> folder `pages/admin/struktur` -> komponen `AdminStrukturPage`
- Route `/admin/site-content/slider` -> menu `Site Content > Hero Slider` -> folder `pages/admin/site-content` -> komponen `AdminSiteContentSliderPage`
- Route `/admin/site-content/slider/tambah` dan `/admin/site-content/slider/:slideIndex/edit` -> komponen form terpisah `AdminSiteContentSliderFormPage`

## 9. Data Layer Rules
Larangan:
- Jangan menulis `useSWR(...)` langsung di file page
- Jangan meletakkan logic create, update, delete langsung di page jika bisa dipindahkan ke module
- Jangan menggunakan `mockData` untuk konten landing, profil, atau footer

Aturan:
- Setiap resource memiliki `src/modules/<resource>/api.ts`
- Module API berisi:
  - key SWR
  - hook list
  - hook detail bila dibutuhkan
  - hook mutations
- Page hanya mengonsumsi hook tersebut

Aturan form input (wajib):
- Setiap input, select, dan textarea wajib memiliki label yang terlihat (visible label)
- Placeholder hanya bersifat pendukung, bukan pengganti label
- Label wajib konsisten dengan istilah menu dan field di backend

Aturan loading UI (wajib):
- Komponen skeleton reusable harus tersedia untuk loading state form dan halaman umum
- Saat mode edit memuat data awal, tampilkan skeleton terlebih dahulu sebelum form siap

Aturan upload file (wajib):
- Field gambar tidak boleh memakai input URL manual, harus memakai upload file
- Field dokumen SOP tidak boleh memakai input nama file atau URL manual, harus upload file PDF
- Allowlist file upload minimal:
  - Gambar: `image/png`, `image/jpeg`, `image/webp`
  - Dokumen: `application/pdf`
- Validasi file wajib dilakukan di frontend dan backend (tipe dan ukuran)
- Request dengan tipe file di luar allowlist wajib ditolak
- Upload file wajib melalui endpoint backend storage (`POST /uploads?kind=image|pdf`) dengan multipart
- Database hanya menyimpan URL file hasil upload, bukan data base64 file
- Untuk mode local storage, file disimpan di folder `bag-orta-api/uploads/` dan diakses via route statis `/uploads/*`
- Arsitektur wajib siap dipindah ke object storage (S3-compatible) tanpa mengubah kontrak payload database

Struktur penyimpanan file (local):

```txt
bag-orta-api/
  uploads/
    images/
    docs/
```

Kontrak response upload API:
- `url`: URL publik file untuk disimpan ke database
- `path`: relative path file di storage
- `kind`: jenis file (`image` atau `pdf`)
- `mimeType`, `size`, `originalName`

## 10. Table Component Rules
Aturan pembuatan table component (wajib, reusable lintas aplikasi):
- Gunakan komponen table generik yang reusable (`DataTable`) untuk seluruh list admin
- Definisi kolom harus berbasis konfigurasi (column config), bukan hardcoded per sel
- Aksi baris (edit/hapus) wajib diinjeksikan lewat props agar tidak mengunci logic ke satu resource
- State UI table (loading, empty, error) wajib ditangani konsisten
- Komponen table wajib mendukung desktop dan mobile card mode
- Export data (mis. CSV) boleh dilakukan pada data halaman aktif
- Khusus Hero Slider, halaman list wajib menggunakan `DataTable` yang sama dengan resource admin lain
- Form tambah/edit Hero Slider wajib berada di halaman terpisah dari halaman list table

Aturan pagination API (wajib):
- Semua endpoint list wajib mengambil data per halaman dari API (`page`, `perPage`), bukan full fetch
- Response list wajib memakai bentuk:
  - `items`: data pada halaman aktif
  - `meta.page`: halaman aktif
  - `meta.perPage`: ukuran halaman
  - `meta.totalItems`: total data
  - `meta.totalPages`: total halaman
- Frontend wajib mengirim `page` dan `perPage` saat memanggil endpoint list
- Pagination UI di frontend wajib menggunakan metadata dari API, bukan menghitung dari full data lokal
- Batas `perPage` backend harus dijaga (contoh maksimal 100) untuk keamanan performa

Keputusan arsitektur pagination:
- Data pagination diambil per page dari API (server-side pagination)
- Full fetch untuk seluruh data list admin tidak diperbolehkan pada produksi

Contoh:

```ts
// src/modules/news/api.ts
import useSWR, { useSWRConfig } from "swr";
import { newsApi } from "@/api/client";

export const NEWS_LIST_KEY = "/news";

export function useNewsList() {
  return useSWR(NEWS_LIST_KEY, () => newsApi.list());
}

export function useNewsDetail(id?: string) {
  return useSWR(id ? `/news/${id}` : null, () => newsApi.getById(id as string));
}

export function useNewsMutations() {
  const { mutate } = useSWRConfig();

  return {
    async createNews(payload) {
      const result = await newsApi.create(payload);
      await mutate(NEWS_LIST_KEY);
      return result;
    },
  };
}
```

## 11. Public Content Rule
Semua konten publik harus memiliki sumber data yang jelas dari API.

Aturan:
- Hero landing berasal dari `site-content.heroSlides`
- CTA landing berasal dari `site-content`
- Profil landing dan halaman profil berasal dari `site-content`
- Footer publik berasal dari `site-content`
- Berita berasal dari resource `news`
- Struktur berasal dari resource `organization-structure`
- SOP berasal dari resource `sop`

Larangan:
- Jangan membuat ulang `src/data/mockData.ts` untuk konten publik yang sudah punya API
- Jika butuh placeholder saat development, buat fallback ringan di komponen atau seed database, bukan file mock permanen

## 12. Backend Structure Rules
Struktur backend yang benar:

```txt
src/
  auth/
  dashboard/
  uploads/
    uploads.controller.ts
    uploads.module.ts
  news/
  sops/
  organization-structure/
  site-content/
    dto/
      create-site-content.dto.ts
      update-site-content.dto.ts
    site-content.controller.ts
    site-content.service.ts
    site-content.module.ts
  users/
  roles/
    dto/
      create-role.dto.ts
      update-role.dto.ts
    roles.controller.ts
    roles.service.ts
    roles.module.ts
  permissions/
    permissions.controller.ts
    permissions.service.ts
    permissions.module.ts
```

Aturan backend:
- Satu resource memiliki satu module NestJS sendiri
- DTO disimpan di folder `dto/`
- Permission dicek di controller route
- `site-content` bersifat singleton dan memakai `id = 1`
- Upload file diproses di module khusus `uploads` agar terpisah dari logic resource domain
- Route statis `/uploads` wajib aktif untuk serving file local storage
- URL file hasil upload yang disimpan ke database harus bersifat publik/terbaca frontend
- Permission tidak lagi hardcoded per role di source code
- Permission harus dibaca dari tabel relasi role dan permission
- Assign permission ke role dilakukan saat create atau edit role
- Permission harus ditampilkan berkelompok per menu/resource di form role

## 13. Prisma Data Model Rules
Prisma schema adalah source of truth untuk struktur data.

Model utama:
- `User`
- `Role`
- `Permission`
- `RolePermission`
- `News`
- `Sop`
- `OrganizationStructure`
- `SiteContent`
- `HeroSlide`
- `ProfileHighlight`

Aturan:
- `User` harus berelasi ke `Role`
- `RolePermission` adalah pivot antara `Role` dan `Permission`
- `Permission` minimal memiliki `resource` dan `action`
- `SiteContent` menyimpan field umum landing, profil, CTA, dan footer
- `HeroSlide` berelasi ke `SiteContent`
- `ProfileHighlight` berelasi ke `SiteContent`
- Data urutan slide dan highlight wajib memakai `displayOrder`

## 14. Seeder Rules
Seeder harus modular dan dipisah per domain.

Struktur yang benar:

```txt
prisma/
  seed.ts
  seeds/
    seed-roles.ts
    seed-permissions.ts
    seed-role-permissions.ts
    seed-users.ts
    seed-news.ts
    seed-sops.ts
    seed-organization-structures.ts
    seed-site-content.ts
```

Aturan:
- `prisma/seed.ts` hanya menjadi orchestrator
- Isi seed per domain ditempatkan di folder `prisma/seeds/`
- Urutan delete dan create harus aman terhadap relasi
- Landing page default wajib disediakan dari seed `site-content`
- Role, permission, dan pivot role permission wajib di-seed secara modular

Pola `seed.ts`:
- hapus child table dulu
- hapus parent table
- panggil fungsi seed per domain satu per satu

## 15. Acceptance Criteria
Sistem dianggap benar bila:
- Landing page tidak lagi memakai `mockData`
- Footer publik bisa diubah dari admin
- Hero, profil, CTA, dan footer bisa diubah dari admin
- Role dan permission tersimpan di database melalui tabel `roles`, `permissions`, dan `role_permissions`
- Sidebar admin mengikuti permission hasil relasi role dan permission
- Halaman user, role, dan permission tersedia di admin
- Form role langsung menyediakan pilihan permission yang dikelompokkan per menu
- Berita, SOP, dan struktur tetap dikelola dari admin masing-masing
- Public pages memakai hook modular, bukan `useSWR` langsung di page
- Semua list endpoint memakai server-side pagination (`page`, `perPage`) dan tidak full fetch
- Seeder backend modular dan mudah diperluas
- Struktur folder tetap konsisten dengan PRD ini

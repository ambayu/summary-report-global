# Clone App Build

Alur yang didukung sekarang:

1. Di aplikasi, owner buka `Pengaturan`.
2. Isi `Nama Cafe`, upload logo, lalu isi `Package ID Clone`.
3. Tekan `Siapkan Clone App`.
4. Aplikasi akan mengekspor file bundle `.json`.
5. Pindahkan file bundle itu ke komputer/project ini bila perlu.
6. Jalankan script build:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_clone_app.ps1 -BundlePath "C:\path\clone_app_bundle.json"
```

Opsional build AAB:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_clone_app.ps1 -BundlePath "C:\path\clone_app_bundle.json" -BuildTarget appbundle
```

Hasil build akan:

- memakai nama aplikasi dari bundle
- memakai icon launcher dari logo bundle
- memakai `applicationId` dari bundle
- keluar di folder `build\clone_app\output`

Catatan:

- ini membangun app clone dari project Flutter, bukan langsung dari aplikasi Android yang sedang berjalan
- package id harus valid, contoh: `com.brand.cafe`
- release signing project masih perlu dirapikan kalau ingin distribusi resmi

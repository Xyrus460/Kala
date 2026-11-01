# KALA — Jalan Kartini

Game horor naratif orang pertama berbasis Godot dan GDScript, dengan eksplorasi rumah, sekolah, dan pabrik, pengumpulan bukti, puzzle, serta pengejaran. Versi source saat ini: **0.17.0**.

## Membuka source code

Repository ini berisi source GDScript di `scripts/`, scene dan level di `scenes/`, serta aset game di `assets/`.

1. Clone repository ini atau unduh melalui **Code → Download ZIP**, lalu ekstrak seluruh isinya.
2. Siapkan Godot **4.7.2**, versi yang dipakai untuk pengujian lokal. `project.godot` menggunakan fitur Godot 4.7 dan renderer **Forward Plus**.
3. Pilih **Import**, buka `project.godot`, dan tunggu impor aset selesai.
4. Tekan **F5** untuk menjalankan game.

Cache `.godot/`, backup, binary Godot, serta build `KALA.exe` dan `KALA.pck` tidak disertakan dalam repository. Cache dibuat ulang oleh Godot saat impor. `BUKA_EDITOR.bat` dan script build di `tools/` mengacu ke binary lokal di `tools/engine/stable/`; untuk membuka source, gunakan menu Import di Godot yang terpasang. Sebelum mengekspor build sendiri, pasang export templates yang sesuai dan sesuaikan path custom template pada `export_presets.cfg`.

Kredit dan lisensi aset pihak ketiga tersedia di [THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt).

## Menjalankan build Windows

Jika sudah memiliki atau mengekspor paket Windows, jalankan **KALA.exe**. **KALA.pck harus tetap berada di samping KALA.exe**: itulah paket aset dan kode game. Untuk membagikan build, salin kedua berkas bersama. Game tidak memerlukan HTML asli, browser, JavaScript, Node.js, maupun instalasi Godot di komputer pemain.

Saat membagikan build, sertakan juga **THIRD_PARTY_NOTICES.txt** untuk kredit dan lisensi aset.

`MAIN_KALA.bat` menjalankan build biasa atau memakai Godot lokal jika build belum ada. `MAIN_KALA_RINGAN.bat` memilih renderer Compatibility dan memerlukan build Windows di folder proyek.

## Kontrol

| Tombol | Fungsi |
|---|---|
| WASD / panah atas-bawah | Bergerak |
| Mouse / panah kiri-kanan | Melihat |
| Shift | Lari; tarik tubuh saat kabel tertambat |
| Tahan Ctrl | Jongkok dan bergerak lebih senyap |
| E | Interaksi dekat / tutup dokumen |
| F | Lampu |
| R | Penjepit LENTERA-G setelah ditemukan; tarik kembali / lepas cengkeraman |
| Q | Pulse Lentera-G; jeda 6 detik, memakai kapasitas panas yang sama |
| E tujuh kali | Berjuang lepas dari tangan |
| J | Jurnal |
| Esc | Jeda / tutup panel |
| Klik-tahan lalu geser foto | Putar foto secara manual |
| E / Spasi / Esc saat adegan cerita | Lewati adegan |

Ventilasi sempit menurunkan kamera dan collider otomatis. Tarik kisi dan rem kipas dengan penjepit; rem kipas bertahan 6,5 detik. Setelah akses pabrik terbuka, berjalan menuruni tangga sampai bordes untuk berpindah area. Gerbang sekolah/jalan memakai interaksi dekat.

## Pengembangan dan pengujian

- `scenes/main/main.tscn` adalah scene utama; `scenes/levels/` memuat 14 area.
- `scripts/systems/level.gd` menyambungkan layout dengan gameplay; `assets/source_layout.json` memuat posisi dan metadata. Sesuaikan collider JSON jika mengubah penghalang yang dipakai AI A*.
- `assets/models/source/` dan `assets/textures/source_generated/` memuat aset hasil konversi sumber. Aset pihak ketiga beserta atribusinya tersedia di `assets/vendor/`.
- `tools/BAKE_LEVELS.ps1` membangun ulang scene dari aset sumber dan mengganti edit scene manual. Cadangkan edit terlebih dahulu.
- Skrip `.mjs` dan pustaka raster di `tools/` hanya alat konversi offline. Folder `tools/`, `docs/`, `tests/`, dan `backups/` tidak disertakan dalam paket game.

Jalankan perintah berikut dari root proyek melalui PowerShell:

```powershell
.\tools\TEST_PROJECT.ps1
.\tools\BUILD_WINDOWS.ps1
```

`TEST_PROJECT.ps1` mengimpor aset lalu menjalankan 18 suite gameplay, layout, cerita, penjepit, dan regresi versi 0.4–0.17. `BUILD_WINDOWS.ps1` mengekspor `KALA.exe` dan `KALA.pck`. Kedua skrip memakai binary lokal `tools/engine/stable/Godot_v4.7.2-stable_win64_console.exe`; siapkan binary console dan editor Godot yang sesuai di folder tersebut. Konfigurasi ekspor dijelaskan pada bagian membuka source code.

## Simpanan

Save native memakai `user://kala_native_v1.json`, terpisah dari save browser. Menu **Muat Game** menampilkan riwayat checkpoint dan **Pilih Bagian** menyediakan 18 titik awal untuk pemeriksaan gameplay. Simpanan manual dibuat melalui **Esc → Simpan Checkpoint**; autosave menyimpan 48 snapshot progres terbaru.

Save lama mempertahankan progres; posisi dapat dikembalikan ke spawn area saat migrasi layout agar tidak muncul di dalam dinding. Pengujian menggunakan profil `.qa_userdata/` dan save khusus.

## Dokumentasi

- [Riwayat perubahan](CHANGELOG.md).
- [Rincian versi 0.17 dan cakupan pemeriksaan](docs/REVISION_0_17.md).
- [Laporan validasi 0.17](docs/validation_17.json).
- [Kredit dan lisensi aset](THIRD_PARTY_NOTICES.txt).

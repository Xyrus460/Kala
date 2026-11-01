# KALA 0.12 — sekolah, interaksi dan pengaturan

31 Oktober 2026.

## Perubahan

- Permukaan fondasi sekolah diturunkan di bawah lantai, lantai pengaman rangkap dibuang, dan bordes yang bertumpuk dihapus. Ubin memakai koordinat dunia dan antialiasing pada sambungan. Sisi bawah pelat tetap berupa plafon polos.
- Seluruh kusen/daun/header pintu lama yang terpotong dibersihkan. Daun pintu sekolah memakai **Kenney Building Kit** dengan skala sesuai bukaan dan gagang asli. Bukaan 1,8 m serta jalur tangga dipertahankan.
- Dua bank loker memakai **Locker oleh J-Toastie**, ditambah **Padlock oleh Quaternius**. Loker Raka tetap tersambung ke puzzle empat digit dan bukti surat.
- Ruangan memiliki isi sesuai fungsi: studio seni/ruang musik (easel, reproduksi Monet, piano, gitar pada stand, kuas, speaker), UKS (ranjang, kabinet dan wastafel), kantin (konter, kulkas dan meja), multimedia (layar dan baris kursi), kelas (meja, kursi, buku dan papan), ruang baca/arsip (rak berisi buku dan meja), klub sains (meja praktikum), aula (panggung, bangku dan speaker). Meja kecil menopang catatan lantai atas.
- Danu, Raka, Adit dan teman sekelas laki-laki memakai karakter berkerangka **Quaternius Casual Character**, dengan material seragam, idle/walk yang dibaurkan, serta pose duduk/reach yang terhubung ke adegan cerita. Sari, Ratna dan Daisy mempertahankan modelnya.
- Panel kabel dirancang ulang berdasarkan susunan kabinet industri: dua rel, blok terminal sekrup, kanal kabel, pemutus dan meter. Tidak ada lagi urutan jawaban besar atau tombol petunjuk jawaban; catatan cerita tetap menjadi sumber informasi puzzle.
- Tangan pemegang senter dihapus. Gerak mengangkat/menurunkan alat menggunakan peredaman yang tidak bergantung frame rate. Jurnal tampil sebagai buku dua halaman, dengan animasi sampul membuka dan transisi menutup.
- Keypad dipasang pada dudukan yang tersambung dinding. Label lama yang melayang dan pipa tepat di depannya dibersihkan.
- R-17 dipindahkan ke dock servis di luar jeruji, dan mesh pickup yang sebelumnya ikut disembunyikan oleh pergantian dekorasi dipulihkan. Posisi pemasangan sel kini memakai koordinat level secara konsisten. Penempatan mesin baru menghindari area akses item penting. Bantuan bidik dekat untuk benda kecil tetap memeriksa dinding; tidak mengambil barang menembus tembok.
- Settings memakai tab Kontrol / Display / Graphics / Audio / Gameplay, daftar kiri, deskripsi kanan, reset default, navigasi Q/E dan tampilan hitam-merah. Graphics meliputi preset, skala render, MSAA, bayangan senter, SSAO, SSIL dan bloom. Display mencakup mode layar, V-Sync, batas FPS dan FOV. Efek yang tidak didukung Compatibility dinonaktifkan di UI.
- Aset instans berulang dicache agar rak buku/kursi tidak berulang kali membaca berkas impor. Save sekolah lama dipindahkan ke spawn aman sambil mempertahankan progres.

## Aset dan referensi

Daftar pencipta, URL sumber, lisensi dan adaptasi: [ATTRIBUTION.txt](../assets/vendor/revision12/ATTRIBUTION.txt), [SOURCES.json](../assets/vendor/revision12/SOURCES.json), dan [THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt).

- [Kenney Building Kit](https://kenney.nl/assets/building-kit): pintu gratis CC0 yang sudah tersedia di proyek.
- [Locker, J-Toastie](https://poly.pizza/m/aGmZ4jQD2y): CC BY 3.0; kredit disertakan.
- [Casual Character, Quaternius](https://poly.pizza/m/kZ3DmIoGip): CC0; model dan animasi sumber.
- [Hitachi S10VE manual, Figure 7-8, halaman PDF 110](https://www.hitachi.com/products/it/control_sys/platform/controller/manual/pdf/SEE-1-001A.pdf): referensi susunan panel, tanpa menyalin gambar atau mereknya ke game.
- [Stacks of Wheat (End of Summer), Claude Monet](https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Stacks_of_Wheat_(End_of_Summer)_-_1985.1103_-_Art_Institute_of_Chicago.jpg): reproduksi domain publik untuk bahan belajar di studio seni.
- Gambar settings dari pengguna menjadi acuan tata letak dan warna. Ikon settings dibuat sebagai SVG asli.

## Validasi

Suite resmi: `tools/TEST_PROJECT.ps1`. Tambahan `tests/revision12.gd` memeriksa pemilihan R-17 dengan ray pemain, perubahan status pengambilan/pemasangan, akses item/catatan pada empat area, kabel, penerapan graphics, dan siklus jurnal. `tests/revision11.gd` memeriksa berjalan melewati 39 bukaan serta naik/turun kedua tangga sekolah.

Seluruh 770 pemeriksaan otomatis lulus. Build Windows memuat 14 area di Forward+ dan Compatibility dari folder terpisah, lalu kedua proses keluar dengan kode 0. Pemeriksaan ini mencakup interaksi progres, perjalanan antararea dan 14 render game. Playthrough manual sampai setiap ending belum dilakukan.

Pada saat aplikasi ditutup, Compatibility mencatat dua tekstur 349.524 byte yang belum dilepas. Diagnostik yang sama tercatat pada versi 0.11. Log error Forward+ kosong. Lihat [hasil dan hash build](validation_12.json), [studio seni](screenshots/art_12.png), [loker](screenshots/lockers_12.png), [panel kabel](screenshots/wiring_12.png) dan [menu graphics](screenshots/graphics_12.png).

Build sebelumnya: `backups/revision12_before/build`. Jalankan ulang `KALA.exe` bersama `KALA.pck` untuk memakai versi baru.

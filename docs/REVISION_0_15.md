# KALA 0.15 / 1 November 2026

Revisi Rumah Relai, generator, dan penambahan Memori / Jalur Servis B1 berdasarkan sebelas gambar pengguna.

## Perubahan per gambar

1. **R-17:** soket kosong yang semula tinggal blok dibangun menjadi kabinet beralas, rongga isolator, tiga pin tembaga, rel pengunci, pelat nama dan status. Unit yang diambil dari dock kini berupa kartrid berlabel R-17 dengan terminal logam. Pengambilan dan pemasangan tetap memakai Lentera-G.
2. **Tuas:** konsol arsip lama diganti kabinet utuh dengan alas, tuas Kenney Factory Kit, grip merah, pelat nama dan status relai. Kotak/platform lama yang tertinggal di lantai disembunyikan bersama collision-nya.
3. **Kontak generator:** dua kertas/placeholder melayang dihapus. Satu bridge contact dari keramik, dua terminal tembaga dan pegangan logam diletakkan di dalam kotak perkakas terbuka di meja arsip. Saat diambil, kotaknya tetap berada di meja.
4. **Arsip:** rak lama diganti rangka baja dan ambalan, karton bertape yang menapak serta label kecil. Janji Ibu dipasang pada clipboard dinding, bukan melayang di depan kardus.
5. **Jalur kanan:** properti roda/pipa besar dipindahkan ke sisi kanan belakang, jauh dari bukaan pintu generator. Panel datar dekoratif yang menyerupai benda terpotong dihapus.
6. **Generator:** generator diesel G-02 dibuat ulang dengan skid, mounting karet, blok mesin, empat kepala silinder, alternator bersirip, radiator, tangki, knalpot, instrumen dan slot kontak. Ruangan memakai lantai beton servis, garis batas, saluran pipa, drain, meja baja/kayu dan clipboard pemeliharaan. Penanda inspeksi biru diletakkan di depan permukaan panel, dan tidak lagi mensyaratkan listrik relai sudah aktif.
7. **Relai dan tulisan:** kereta/gerbang dekoratif serta papan cabang besar yang menutup pandangan dihapus. Tiga dial dipasang lebih rendah pada kabinet, judul ruangan ditempatkan tinggi di dinding belakang. Angka/arah tersembunyi memakai tinta biru. Hubungan putaran tetap sama: I ikut mengubah II, II ikut mengubah III.
8–11. **B1:** dua tangga fisik menuju landing, ruang Gema Arsip dan ruang servis. Cabang “Tenaga” dihapus. Masing-masing ruangan baru berukuran 18 × 20 meter; keduanya tersambung ke landing bawah. Ada panggung, 24 CRT, empat tombol, konsol rekaman, saluran bundar berusuk dan maskot kelinci putih/toska. Pintu servis membuka ke bab pengejaran yang sudah ada, termasuk penyesuaian lintasan cutscene di lantai B1.

## Gema Arsip

- Ronde 1: ulangi tiga simbol dan nada sesuai urutan.
- Ronde 2: empat simbol, jawab dari akhir ke awal.
- Ronde 3: lima simbol; abaikan gangguan abu-abu bertanda ×.
- Simbol dan nama tersedia bersama warna/nada. Tombol dapat ditekan dari dekat dengan E atau dijangkau memakai R.
- Jawaban salah dan waktu habis mendekatkan maskot. Kesalahan berulang memicu lunge dan kerusakan akal sehat; ronde dapat diulang di konsol.
- Ronde selesai disimpan ke flag checkpoint. Timer berhenti ketika kontrol pemain berhenti, termasuk menu/cutscene. Keluar dari area membatalkan ronde yang sedang berjalan, tetapi mempertahankan ronde yang sudah selesai.
- Generator dan R-17 memberi catu; penyelarasan relai/tuas serta penyelesaian Gema Arsip diperlukan untuk melanjutkan melalui jalur servis.

Nomor layout checkpoint dinaikkan menjadi 15 agar koordinat lama yang berada di dalam properti hasil penggantian kembali ke spawn aman. Bukti dan progres cerita tetap disimpan. Checkpoint yang sudah berada di bab selanjutnya tetap bisa dilanjutkan.

## Referensi dan aset gratis

Arahan desain berikut adalah pilihan untuk KALA, berdasarkan referensi visual; aset game komersial tidak dimasukkan.

| Referensi | Penerapan di KALA |
| --- | --- |
| [Amnesia: The Bunker — halaman resmi penerbit di Steam](https://store.steampowered.com/app/1944430/Amnesia_The_Bunker/) | Peralatan yang terbaca sebagai benda mekanis, kontak fisik, generator dengan panel fungsi dan area perawatan. |
| [Alien: Isolation — halaman resmi SEGA di Steam](https://store.steampowered.com/app/214490/Alien_Isolation/) | Konsistensi kabinet, CRT, pipa, label fungsi dan penghubung servis. |
| Gambar 9–10 dari pengguna / Poppy Playtime Chapter 2 | Ruang uji dengan bank monitor dan ancaman dari bukaan bundar. Gema Arsip memakai simbol arsip, urutan balik, gangguan rekaman dan ancaman horizontal. |
| [Kenney Factory Kit](https://kenney.nl/assets/factory-kit) — CC0 | `lever-single.glb`, pipa dan mesin servis dari aset lokal yang sudah tersedia; material, kabinet, kontak dan pemasangan disesuaikan. |
| [Quaternius Ultimate Animated Animals](https://quaternius.com/packs/ultimateanimatedanimals.html) — CC0; [Bunny yang dipakai proyek](https://poly.pizza/m/irZjWFARyl) | Menggunakan kembali rig `revision13/pengawas.glb`, turunan `bunny.glb`. Varian ruang memori diberi tubuh putih, telinga/nose pink, crest toska, rompi gelap dan mata besar sesuai arah gambar 11. |
| [Quaternius Modular Sci-Fi MegaKit](https://quaternius.com/packs/modularscifimegakit.html) — tersedia opsi gratis CC0 | Kandidat tambahan yang diperiksa; tidak ditambahkan ke distribusi ini. |

Tidak ada unduhan aset baru yang diperlukan: tuas, pipa dan rig kelinci yang sesuai sudah berada dalam proyek. Shader, kabinet, generator, kontak, clipboard, ruangan serta nada memori dibuat untuk KALA. Kredit lengkap tetap dalam `THIRD_PARTY_NOTICES.txt`.

## Validasi

`tests/revision15.tscn` menguji ray interaksi sebenarnya, pengambilan/pemasangan, tinta biru tanpa daya, logika putaran, tangga dengan CharacterBody pemain, ronde, kegagalan, serangan, pause, persistensi ronde saat ruangan dimuat ulang, shutter dan transisi ke pursuit.

`tests/capture15.tscn` merender relai, soket, tuas, generator, reveal biru, kontak, arsip, tangga, memori, maskot dan servis pada Forward+ dan Compatibility. Laporan akhir tes, hash build dan smoke mandiri ditulis ke `docs/validation_15.json`. Pemeriksaan otomatis dan render ini belum mencakup satu putaran permainan manual sampai semua ending.

Hasil akhir: **511 pemeriksaan pada enam rangkaian, 0 kegagalan**, **30 render** dan **14 area dimuat dari EXE mandiri pada kedua renderer**, masing-masing keluar dengan kode 0. Paket berisi 2.135 resource. Compatibility masih mencatat dua tekstur engine ketika proses ditutup, sama seperti 0.14; ini dipisahkan sebagai diagnostik engine yang sudah diketahui dalam laporan validasi.

Build sebelumnya: `backups/revision15_before/build`. Jalankan kembali `KALA.exe` bersama `KALA.pck` untuk memuat 0.15.

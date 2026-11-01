# KALA 0.13 — karakter dan eksplorasi pabrik

31 Oktober 2026.

## Perubahan

- Tangan pada cutscene shower dihapus sepenuhnya. Aliran air, suara, gerak kamera, skip dan status selesai mandi tetap terhubung ke cerita.
- Danu, Raka dan Adit memakai tiga kepala/rambut unduhan berbeda; tinggi, lebar badan dan warna kulit dibedakan. Teman kelas memiliki identitas Bima, Fajar, Nadia dan Intan. Seragam mengikuti kerangka saat duduk, berdiri, berjalan dan mengulurkan tangan.
- Sari memakai rig perempuan, rambut bob, blus putih dan rok sekolah dari bagian modular gratis. Bu Ratna memakai wajah/rambut dewasa, pakaian formal lengan panjang berwarna khaki, rok dan sepatu dari aset gratis. Nama dada dan kerah mengikuti tulang dada.
- Pengawas memakai mesh dan rig kelinci Quaternius yang diadaptasi dari referensi pengguna: tubuh biru, tungkai lebih panjang, telinga lebih pendek, mata bulat besar, moncong lebar, hidung hitam, tangan/kaki kuning dan syal merah. Idle/walk memakai animasi sumber. Patung panggung menghilang saat puzzle memicu Pengawas; pertarungan memakai model yang sama.
- Setelah senter pecah, pemain melewati hub inspeksi yang bercabang ke **Galeri Pameran** dan **Pos Pengawas**. Pemain mencari sekering di meja inventaris galeri, dapat membaca log kamera, memasang sekering di kabinet pos pengawas, lalu kembali ke shutter utara yang terbuka. Setelah eksplorasi ini barulah pemain tiba di ruang relai dan menemukan Lentera-G.
- Lima penghubung utama pabrik menggunakan lantai mendatar. Collision tangga dan railing lama dibersihkan; batas peta, navigasi, gerak aktor cerita dan pemicu pergantian area diperbarui. Jalur ventilasi pada pengejaran tetap mengikuti bentuk area kejaran.
- Kabel penjepit berawal dari marker pada lubang laras model Lentera-G. Kepala tiga rahang yang asli meluncur ke ujung kabel dan kembali ke socket mesin ketika ditarik. Gerak mengangkat alat dan rotasi kamera ikut menggerakkan titik awal kabel.
- Checkpoint dengan tata letak pabrik lama dikembalikan ke spawn aman, dengan bukti, barang dan progres cerita tetap tersimpan. Pengujian menggunakan profil `.qa_userdata` terpisah dari save pemain.

## Aset dan referensi

Sumber, lisensi dan adaptasi tersedia dalam [kredit aset](../assets/vendor/revision13/ATTRIBUTION.txt), [manifest unduhan](../assets/vendor/revision13/SOURCES.json), dan [THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt). Model CC0 berasal dari Quaternius; pakaian Suit dicatat sebagai CC BY 3.0 sesuai halaman unduhnya.

[Poppy Playtime Chapter 1, Mob Entertainment](https://www.mobentertainment.com/poppy-playtime) menjadi acuan ritme eksplorasi: hub, ruang dengan fungsi berbeda, petunjuk lingkungan, pemulihan daya, kembali ke pintu yang sebelumnya tertutup, lalu penemuan alat. Galeri memuat display mainan, inventaris dan palet pabrik yang sama dengan area KALA lainnya.

## Validasi

`tools/TEST_PROJECT.ps1` mencakup seluruh suite lama dan `tests/revision13.gd`. Suite baru menjalankan capsule dan ray interaksi pemain melalui hub, galeri, pos pengawasan, shutter serta pickup Lentera-G; memeriksa karakter duduk/berdiri; dan mengukur kedua ujung kabel serta posisi rahang di beberapa arah bidik. Render diambil langsung dari Godot dengan `tests/capture13.gd`.

Seluruh **818 pemeriksaan otomatis lulus**. Paket Windows final memuat **14 area** dalam Forward+ dan Compatibility dari folder terpisah; kedua proses keluar dengan kode 0. Sepuluh render game diperiksa secara visual. Hash paket di folder uji sama dengan `KALA.pck` yang diserahkan.

Log error Forward+ kosong. Saat ditutup, Compatibility masih mencatat dua tekstur 349.524 byte yang belum dilepas, diagnostik yang juga tercatat pada versi 0.11 dan 0.12. Rincian ada di laporan JSON. Playthrough manual sampai setiap ending belum dilakukan.

Laporan hasil akhir dan hash build: [validation_13.json](validation_13.json). Preview: [karakter](screenshots/characters_13.png), [Sari dan Bu Ratna](screenshots/ratna_13.png), [Pengawas](screenshots/mascot_13.png), [kelas](screenshots/classroom_13.png), [shower](screenshots/shower_13.png), [hub inspeksi](screenshots/route_entrance_13.png), [galeri](screenshots/gallery_13.png), [pos pengawasan](screenshots/control_13.png), [penjepit](screenshots/claw_13.png).

Cadangan build sebelum perubahan: `backups/revision13_before/build`. Jalankan ulang `KALA.exe` bersama `KALA.pck` untuk memakai versi 0.13.

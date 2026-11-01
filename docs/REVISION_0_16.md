# KALA 0.16 — menu dan perpustakaan checkpoint

Referensi pengguna dipakai untuk komposisi menu; latar lorong sekolah/jalur servis dan identitas KALA tetap berasal dari game ini. Tidak ada aset Poppy Playtime yang dimasukkan.

- Menu utama: judul kiri atas, enam pilihan teks kiri bawah, latar 3D, film grain dan tipografi putih kusam. Tidak ada pilihan Graphics terpisah.
- Pengaturan: Kontrol, Tampilan, Audio dan Permainan. Tampilan mencakup pengaturan layar serta tujuh kontrol kualitas yang sebelumnya berada di tab Graphics. Judul, garis, ikon dan penanda pilihan memakai putih/abu, bukan merah.
- Muat Game: daftar bergulir, thumbnail level, tujuan, tanggal lokal, waktu main, foto berbingkai dan rincian di kanan. Mendukung mouse, klik dua kali, panah dan Enter. Delete meminta konfirmasi; Esc membatalkan konfirmasi atau kembali ke menu asal.
- Riwayat tersimpan terpisah dari checkpoint Continue lama, pada `kala_native_v1.json.history.json`. Save lama dimigrasikan tanpa mengubah snapshot aslinya. Setiap simpanan manual mendapat baris tersendiri. Autosave progres dibatasi 48; autosave tanpa perubahan progres memperbarui baris terbaru. Tidak ada batas pemangkasan simpanan manual.
- Thumbnail otomatis memakai render permainan. Simpan manual saat jeda memakai gambar sebelum menu jeda dibuka. Foto level bawaan tersedia untuk save lama atau checkpoint yang dibuat saat panel terbuka.
- Pilih Bagian: 18 titik awal yang selalu tersedia. Setiap template membuat data baru, membawa perlengkapan/prasyarat yang diperlukan dan tetap membiarkan puzzle serta boss bagian itu belum selesai. Memori dimulai di B1 dengan tiga ronde kosong. Halusinasi membawa empat bukti yang dapat digunakan.
- Muat Game dan Pengaturan dari Pause kembali ke Pause. Gameplay dan musuh tetap berhenti selama panel terbuka.

## Validasi

`tests/revision16.tscn` memeriksa riwayat, migrasi, pemuatan snapshot independen, penghapusan, data rusak, keyboard, seluruh 18 level/prasyarat, dan navigasi menu. `tests/revision12.tscn`, integrasi serta regresi cerita diperiksa kembali untuk perubahan pengaturan dan penyimpanan. Hasil terbaru disimpan di log `docs/*_latest_console.log` dan `docs/validation_16.json`.

`tests/capture16.tscn` merender foto level serta screenshot menu utama, Pengaturan, Simpanan dan Pilih Bagian. Hasil berada di `docs/screenshots/*_16.png`. Pemeriksaan visual mencakup ukuran 1280×720, 960×540 dan jendela 4:3 dengan komposisi yang dipertahankan.

Pengujian menggunakan profil `.qa_userdata`, bukan simpanan/settings pemain. Source yang disentuh dan kedua berkas build 0.15 dicadangkan di `backups/revision16_before`. Foto bawaan menggambarkan titik awal level; thumbnail simpanan baru merekam posisi permainan sebenarnya ketika render tersedia.

Hasil akhir: **320 pemeriksaan, 0 kegagalan** (menu/save 66, pengaturan/regresi 0.12 sebanyak 49, integrasi 177, cerita 28). Build mandiri **0.16.0** lolos pada Forward+ dan Compatibility: masing-masing memuat 14 area, menu 18 bagian dengan foto terpaket, serta empat kategori Pengaturan. Kedua proses keluar dengan kode 0 tanpa diagnostik error/warning. Hasil dan SHA-256 build tersedia di `docs/release_16.json`.

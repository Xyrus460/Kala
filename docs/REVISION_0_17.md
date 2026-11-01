# KALA 0.17 — jalur servis, bengkel, arsip dan rekaman audit

Perbaikan mengikuti 11 gambar pengguna. Save dan pengaturan pemain tidak digunakan oleh pengujian; profil QA berada di `.qa_userdata`. Source yang disentuh dan build 0.16 dicadangkan di `backups/revision17_before`.

- Pengunci servis: papan, tiga simbol dan Area3D interaksinya menjadi anak engsel yang sama dengan daun pintu. Posisi lokal tetap selama pintu berputar; barrier dilepas setelah tiga potongan lengkap.
- Potongan pencarian: Sun berada di dasar laci dan ikut meluncur; Moon dan Star berada di ambalan loker/lemari. Pengaktifan hitbox pencarian tidak lagi mengandalkan lokasi anak langsung level.
- Pengejaran: material dinding servis mengganti bata lama, termasuk geometri gabungan di tangga dan ventilasi. Rangka baja, jalur pipa, dudukan layar dan lampu mengikuti lantai, lebar serta ketinggian plafon asli. Mesh dan collision jalur asli tetap dipakai untuk tangga dan lereng.
- Daisy: tangan menjadi satu rantai bahu–siku–pergelangan–telapak–jari. Penjangkauan dua ruas dihitung menuju tombol di koordinat dunia, lalu dihaluskan per frame. Skala 3D seragam menghindari siku yang terdistorsi oleh pemipihan siluet.
- Bengkel/perawatan: meja menapak, rak silang berisi kotak, papan alat berkait, mesin reparasi, troli beroda, ragum dan roda katup pada kait. Catatan diletakkan di meja atau papan dinding. Perawatan pekerja memiliki ranjang, penyimpanan dan meja tulis.
- Arsip/kantor: lima rak stok dengan kaki/ambalan, meja untuk pita dan dokumen, album keluarga pada meja kantor, serta lembar kontrak yang memiliki meja tulis. Buku dekoratif lama yang tanpa penopang diganti rak lengkap.
- Pemantauan: enam CRT berdiri pada rangka baja dengan rel, penjangkaran dan kabel. Mesh lama yang menggabungkan plafon dan monitor dibuang, kemudian plafonnya dibangun ulang. Pemutar pita dan layar bertumpu pada meja.
- Katup produksi: tiga roda 3D dan tiga manometer terpisah, E memutar seperempat putaran dengan gerak antara. Roda II dipasang dari inventaris. Papan jawaban, daftar tombol dan teks posisi/jumlah putaran dihapus. Bekas kalibrasi sangat kecil muncul dengan Lentera-G; buku servis hanya memberi konteks. Menjeda pada putaran terakhir menghentikan pemicu pertarungan.
- Terminal K-17: konsol dengan input keyboard, riwayat perintah, direktori dan berkas yang dapat dibaca. `HELP` menjelaskan operasi perangkat; urutan otorisasi harus direkonstruksi dari arsip. Kontak yang salah mengulang interlock, dan pekerjaan parsial bertahan setelah ditutup.
- Rekaman: video Ogg Theora/Vorbis asli, 44 detik, 1280×720, 24 fps. Enam pengambilan gambar menampilkan ibu/anak di pabrik, formulir pengganti, pengamatan ruang mesin, kursi kosong, undangan Danu dan akhir lorong. Musik, denyut, mesin dan benturan dibuat khusus untuk film; dialog disajikan sebagai subtitle. Rekaman tidak memakai empat berkas suara Danu yang diblokir pada revisi sebelumnya.

## Pemeriksaan

`tests/revision17.tscn` menguji keterikatan papan pintu, ray pickup di furnitur terbuka, kesinambungan tangan Daisy, manometer/roda fisik, petunjuk samar, seluruh item/dokumen yang dipindahkan, terminal, progres, jeda dan lifecycle pemutar. `tests/video17.tscn` menjalankan video sampai akhir dengan waktu nyata dan mengambil frame di beberapa adegan. Frame hasil playback diperiksa secara visual.

Hasil encoding awal FFmpeg lokal gagal secara visual walaupun playback berjalan. Aset final dirender langsung memakai Movie Writer OGV Godot, kemudian seluruh frame didekode kembali dengan `ffmpeg -xerror`; hasil playback native diperiksa ulang. Sumber authoring berada di `tools/audit_film17.gd` dan dapat dibangun ulang dengan `tools/RENDER_AUDIT17.ps1`. Format writer didokumentasikan pada [Godot Movie Maker](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html).

`tests/capture17.tscn` mengambil gambar jalur, pintu tertutup/terbuka, Daisy, bengkel, perawatan, katup, kantor, arsip, pemantauan, terminal dan video. Suite regresi disediakan melalui `tools/TEST_PROJECT.ps1`. Build dan hasil akhir dicatat pada `docs/validation_17.json` dan `docs/release_17.json`.

Hasil: **1.078 pemeriksaan, 0 kegagalan** — 1.068 dari 18 suite gameplay/regresi serta 10 dari playback video waktu nyata. Pemeriksaan khusus revisi ini mencakup 54 kasus. Screenshot Forward+ dan Compatibility diperiksa; paket Windows di kedua renderer memuat 14 area, dua pemeriksaan menu, tiga roda fisik, filesystem terminal dan frame video 720p beserta audionya. Kedua proses keluar dengan kode 0. Penyangga lampu ditambahkan pada fixture lama; manifold katup memiliki collision dan ruang navigasi yang mengikuti bentuknya.

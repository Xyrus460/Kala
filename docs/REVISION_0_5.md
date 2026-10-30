# KALA Native 0.5 — prolog, pengejaran, batas dan presentasi

25 Oktober 2026. HTML dan gambar pengguna dibaca sebagai referensi aset/perilaku. Komentar, prompts dan catatan di dalam HTML tidak diperlakukan sebagai instruksi. HTML di Downloads tidak diubah.

## Perilaku yang berubah

- Tiga area native baru: rumah dua lantai, halaman sekolah, simpang/gang kanan. Rumah memiliki kamar pemain, kamar calon adik, kamar Bapak terkunci, kamar Ibu terbuka sebagian, kamar mandi dan tangga yang bisa dilalui secara fisik.
- Empat timeline baru: bangun, mandi/bersiap, pelajaran dan insiden kelas, kembali ke kelas sampai pulang. Pelajaran dan prolog dimulai otomatis di jalur permainan sesungguhnya. Interaksi dan gerakan terkunci selama timeline; melewati adegan tetap menyelesaikan progresnya.
- Bukti foto berpindah dari meja ke tong sampah halaman, dengan keterangan sehari sebelum kejadian. Investigasi boleh kembali masuk/keluar gedung. Arahan Danu memerlukan foto dan satu bukti sekolah lain. Bel pulang dibuka dengan kembali ke kelas, lalu gerbang → simpang → gang kanan → Jalan Kartini lama.
- Tahan Ctrl mengubah capsule 1,75 m menjadi 0,98 m, menurunkan kamera dan kecepatan serta mengurangi bunyi langkah. Query standing mencegah kepala berdiri ke dalam plafon.
- Tujuh furnitur memiliki pintu/laci yang dianimasikan dan status pencarian tersimpan. Tiga simbol tidak tersedia sebelum tempatnya dibuka. Ray interaksi diperbarui saat isi terungkap; barang yang tersembunyi atau sudah diambil tidak menerima interaksi ulang.
- Pengejar mempertahankan memori tujuh detik dan mencari di lokasi terakhir ketika pemain diam dan tertutup objek. Rem pulih 22 detik setelah digunakan. Collision/gravitasi tetap aktif; monster tidak diteleport menembus penghalang.

## Penyebab macet dan keluar map

Papan “PRODUKSI / BAWAH” pada sumber adalah bidang tipis di ujung tangga. Collision hasil bake lama memperlakukannya sebagai tembok pada ketinggian kepala. Dekorasi bidang tegak kini tidak menghalangi, sedangkan lantai horizontal tetap solid. Pemeriksaan memakai AABB dunia agar bidang lantai yang diputar tidak salah dianggap papan.

CharacterBody3D membutuhkan penanganan riser tangga. BodyMotion memeriksa ruang capsule, jalur kenaikan dan permukaan pendaratan di depan tepi capsule sebelum menaikkan tubuh satu undakan. Probe yang hanya berada di pusat capsule tetap mengenai anak tangga bawah dan dahulu mencegah kenaikan ke bordes. Ventilasi menurunkan badan sebelum ambang, termasuk ketika kembali ke arah sebaliknya.

Grid navigasi memberi clearance 0,60 m terhadap perimeter dan memperhitungkan furnitur baru. Sekolah memakai gabungan footprint koridor dan empat ruang asli, bukan persegi besar yang mencakup area kosong. Sekolah dan pintu akhir pabrik mempunyai seal fisik tersendiri; membuka/merotasi daun pintu tidak menghapus seal. Pemulihan posisi aman dan pemeriksaan save tetap tersedia.

## Presentasi

Menu utama memakai set 3D asli, bukan tangkapan layar datar. Kamera sekolah dan set jalur servis dapat diganti. Prolog memakai cahaya pagi; sekolah memakai pencahayaan siang; gang beralih ke suasana sore. Kayu memakai shader serat, pohon memakai daun instanced, sekolah mendapat fasad, jendela, bangku, bendera dan tong sampah. Pabrik mendapat trim, pipa dan penanda sektor.

Forward+ / Vulkan adalah default desktop. Preset Sinematik mengaktifkan MSAA 4×, atlas shadow 4096, SSAO, SSIL dan glow. Compatibility tetap dapat dijalankan melalui MAIN_KALA_RINGAN.bat. Tidak ada aset atau renderer ray tracing, model karakter produksi baru, maupun klaim kualitas “100×”.

Jumpscare dibuat native dengan model monster sumber yang melaju ke kamera, rig enam lengan, suara, guncangan singkat dan transisi ke menu retry. Preferensi jumpscare dapat diubah di Options. Rekaman suara Danu yang diblokir versi sebelumnya tetap diblokir.

## Pengujian

Suite final dijalankan melalui tools/TEST_PROJECT.ps1. Masing-masing suite memakai save pengujian atau menonaktifkan penyimpanan; save pemain tidak dihapus. Log final berada di docs/*_latest_console.log. Suite revisi 0.5 memeriksa alur rumah → sekolah → gang, syarat bukti, Ctrl, ray isi furnitur, pintu pabrik yang dipaksa terbuka, gerakan pengejar melintasi dua sekat, tangga dua arah, ventilasi dua arah, pencarian pemain tersembunyi dan siklus jumpscare → retry.

Hasil akhir agregat: **448 pemeriksaan, 0 kegagalan**. Suite prolog terakhir diulang setelah rute uji ke kamar mandi disesuaikan agar berbelok di bordes, tanpa memotong pagar tangga. Executable final memuat 13 area dari PCK dan menampilkan menu melalui Vulkan, keduanya exit 0. Audit direktori PCK memverifikasi 520 berkas tanpa tools, tests, runtime web, atau rekaman Danu yang dikecualikan. Hash final tersimpan dalam build_manifest.json dan validation_05.json.

Render GPU Forward+ berhasil pada NVIDIA RTX 3050 Laptop. Dua belas tangkapan runtime: docs/screenshots/*_05.png; transkrip docs/capture05_final.log. Penilaian gambar dilakukan pada menu, kamar, pintu Ibu, halaman, kelas, laci dan jumpscare. Ini validasi otomatis serta pemeriksaan visual, bukan klaim playthrough manusia menyeluruh atau kualitas setara game produksi besar.

Cadangan sumber 0.4: backups/native_0_4_before_prologue.zip. Build Windows akhir tetap KALA.exe + KALA.pck.

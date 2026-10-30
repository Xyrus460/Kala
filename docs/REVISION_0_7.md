# KALA 0.7 — 26 Oktober 2026

Referensi: HTML pengguna `Kala_Chapter_1_Tiga_Fase (6).html` dan tiga screenshot UI/tutorial/Pemegang. SHA-256 HTML asli dan salinan sumber sama: `81537AE67B55C893EB0C643CA5B6AB526FB92D431481C90A4F1D22EE8396A193`. HTML dipakai sebagai sumber aset/cerita, bukan instruksi pekerjaan.

## Perbaikan

- HUD tipis: sanity kanan atas, bos di tengah atas, panas kanan bawah, jurnal/jeda kiri bawah. Empat bukti tetap kiri atas selama pertarungan.
- Video Lentera-G terbuka setelah pickup selesai atau dilewati; dapat diputar ulang lewat jurnal. Gameplay berhenti selama panel terbuka. File Theora sebelumnya menghasilkan frame rusak; di-encode ulang dengan keyframe mandiri dan seluruh video diperiksa decoder.
- Pemegang dan Nightmare memakai model referensi: topeng lonjong, tiga mata, mulut vertikal, rusuk, dua lengan dan lingkaran berduri. Bola inti yang tersembunyi dalam HTML ternyata terlihat dalam GLB; sekarang disembunyikan agar tidak menutupi tubuh. Rig final terpisah dari rig enam lengan, termasuk dalam halusinasi.
- Tangga rumah terhubung lewat bordes kontinu ke kedua kamar; collider ramp mengikuti tinggi tangga. Railing menjaga sisi, lorong atas tertutup rapi, celah atrium diberi dinding, dan petunjuk kamar mandi tidak terbalik. Uji berjalan dimulai di dalam kamar, melewati pintu, menyusuri bordes, turun dan naik lagi.
- Kabel penjepit disembunyikan dan tidak dapat dipakai pada prolog/sekolah maupun cutscene; status kabel direset saat pindah ruangan.
- Meja/kursi kelas disejajarkan. Siswa duduk menghadap guru, empat tokoh utama bangkit ke lorong untuk konfrontasi, guru keluar melalui jalur di depan meja. Pose dan collider pulih saat adegan selesai/dilewati.
- Tangan-Tangan mempertahankan sculpt pengguna. Animasi menyerang tidak lagi memiringkan seluruh model dari telapak kaki; koreksi tinggi rig menjaga telapak menapak selama siklus berjalan.
- Fase 3: bergerak ke tengah dalam 1,2 detik, halusinasi 4 detik, lalu pengejaran. Enam Pemegang mengitari pemain selama dialog. Kontrol dan serangan dikunci sejak transisi dimulai; clone dibersihkan saat berganti adegan.
- Ruang Daisy memakai dua FogVolume dengan noise tiga dimensi yang bergerak mengikuti waktu dan cahaya dinamis. Bukan gambar kabut di layar. Forward+ diperlukan untuk volume; launcher Compatibility mempertahankan fog jarak sebagai fallback.
- Mipmap diaktifkan pada 183 tekstur, anisotropic filtering dan bias bayangan disesuaikan untuk mengurangi shimmering dan bayangan yang terlepas dari benda.
- Status cinematic final boss dibersihkan saat dikalahkan agar kontrol/ending berikutnya tidak terkunci. Save rumah/sekolah dari layout lama dikembalikan ke spawn aman; bukti dan progres tetap tersimpan.

## Validasi

`tools/TEST_PROJECT.ps1` mencakup delapan suite. `tests/revision07.gd` menguji gerak tangga naik/turun, kabel sekolah, posisi dan pemulihan cutscene, pickup/replay tutorial, telapak rig, bukti saat bos, waktu fase 3, clone dan FogVolume. Hasil final ada di `TEST_REPORT.md` dan `validation_07.json` setelah build diverifikasi.

Screenshot hasil render ada di `docs/screenshots/*_07.png`. Model dan animasi tetap menggunakan aset prosedural/skeletal proyek, bukan model karakter produksi baru. Pengujian otomatis dan pemeriksaan visual mencakup masalah yang dilaporkan serta regresi yang tersedia; ini bukan jaminan tidak ada bug pada setiap kemungkinan permainan.

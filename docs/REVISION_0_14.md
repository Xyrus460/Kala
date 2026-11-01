# KALA 0.14 / 1 November 2026

Permintaan: memperbaiki tujuh gambar, putaran kamera setelah senter meledak, gerak jurnal, serta memperluas dan mempersulit puzzle setelah Pengawas.

## Perubahan

- Bantal tunggal: hilangkan kemiringan yang tersimpan di geometri sumber, lalu gunakan posisi permukaan vertex sebenarnya agar bagian bawah menyentuh duvet. AABB yang diputar menghasilkan batas terlalu besar dan tidak cukup untuk memastikan kontak.
- Percakapan: Danu, Raka, Adit dan Sari memutar tubuh menuju posisi pemain dengan interpolasi sudut. Pelacakan dilepas ketika dialog ditutup. Bu Ratna memakai perilaku yang sama saat diajak bicara. Panel dialog dipindahkan ke bawah dengan latar yang lebih tipis agar wajah terlihat.
- Jurnal: satu parameter animasi mengatur putaran sampul, kemunculan halaman, posisi, skala dan opacity. Menutup saat masih membuka membalik transisi dari posisi saat itu. Tulisan pada sampul tidak dicerminkan di bagian belakang.
- Rak/loker: geometri placeholder ruang jaga diganti rak berpenyangga, kardus berlabel yang bertumpu tepat di ambalan, loker impor, meja dan kait kunci. Memo A, B, C serta Kunci Cadangan dipasang pada papan yang menempel dinding. Buku jaga menapak meja; kunci tetap dapat diambil dengan E.
- Puzzle UI: baris tombol Tutup selebar panel dihapus. Semua puzzle memakai tombol kecil **Tutup (Esc)** di kanan atas; pintasan Esc tetap bekerja.
- Senter: titik jatuh ditetapkan sekali dalam koordinat dunia dan dibatasi dinding/lantai. Kamera mengikuti titik tetap; shake memakai offset sementara yang kembali ke nol dan dipulihkan saat selesai/dilewati. Ledakan memiliki 8 semburan api, 11 gumpalan asap, 22 pecahan, 36 percikan, kilatan dinamis, debu radial, bekas hangus dan suara baterai pecah yang dibuat secara prosedural. Efek dibersihkan saat cutscene berakhir.
- Boss duplikat: hapus **GalleryMascot**. Pengawas hanya menjadi musuh pada pertarungan aslinya; mainan kecil tetap menjadi dekorasi pabrik.

## Jalur inspeksi yang diperluas

Area tambahan mencakup sekitar 1.118 m² (jumlah footprint lima bagian; koridor utama dan empat ruangan), dibanding sekitar 343 m² sebelumnya. Permukaan tetap mendatar dan terhubung secara fisik. Ruang Pompa dan Distribusi Daya memiliki mesin, sambungan pipa, kabinet, penyangga dan jalur memutari peralatan.

1. Temukan sekering galeri dan pasang di kabinet Pos Pengawas. Ini hanya menyalakan penerangan servis.
2. Baca papan Ruang Pompa. Putaran katup I ikut mengubah II; katup II ikut mengubah III; III hanya mengubah dirinya sendiri. Cocokkan ketiga manometer dengan target pada catatan.
3. Baca prosedur pos dan lembar serah terima galeri. Deduksi urutan berdasarkan nama proses, kemudian aktifkan empat terminal yang terpisah di Ruang Distribusi. Kesalahan mengulang empat sambungan; sekering dan tekanan tidak hilang.
4. Shutter utara terbuka setelah semua tahap selesai. Koridor mengarah ke penemuan Lentera-G yang sudah ada.

Catatan disimpan di jurnal. Nilai katup, sambungan parsial dan tahap selesai masuk ke data checkpoint yang sama. Checkpoint 0.13 yang telah membuka inspeksi dimigrasikan sebagai selesai, tanpa memaksa pengulangan atau memunculkan boss lagi.

## Pemeriksaan

`tools/TEST_PROJECT.ps1` menjalankan import Godot, seluruh rangkaian regresi sebelumnya dan `tests/revision14.tscn`. Rangkaian baru memakai ray interaksi E dan pergerakan CharacterBody sebenarnya, termasuk navigasi mengitari kabinet, kegagalan urutan, keluar/masuk ruangan, penjagaan shutter dan transisi menuju relai. Kamera diuji pada tiga arah awal, penyelesaian cutscene dan pemulihan pose. Jurnal diuji dengan penutupan di tengah animasi.

`tests/capture14.tscn` menghasilkan render bantal, percakapan, jurnal, rak, memo, keypad, empat waktu ledakan dan area inspeksi di `docs/screenshots/*_14.png`. Hasil ringkas tes, build dan smoke Windows dicatat di `docs/validation_14.json` setelah pemeriksaan selesai.

Hasil akhir: **893 pemeriksaan pada 15 rangkaian, 0 kegagalan**; termasuk 65 pemeriksaan revisi ini. Executable 0.14 memuat seluruh 14 area dan keluar dengan kode 0 pada Forward+ maupun Compatibility. Empat fase efek ledakan juga dirender pada kedua renderer. Paket berisi 2.127 resource; hash executable, PCK, sumber perubahan dan 21 gambar tersimpan dalam laporan validasi. Compatibility masih melaporkan dua tekstur engine (699.048 byte) saat proses ditutup, sama seperti build sebelumnya; rincian dicatat pada `known_diagnostics` di laporan.

Efek orisinal menggunakan shader/mesh dan audio prosedural. Aset pihak ketiga memakai sumber dan lisensi yang sudah tercatat; tidak mengambil aset Resident Evil. Perbandingan dengan game tersebut dipakai sebagai arahan efek, bukan klaim kesetaraan mutu produksi. Pemeriksaan otomatis dan render tidak menggantikan satu putaran permainan manual hingga semua akhir.

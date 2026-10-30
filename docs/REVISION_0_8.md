# KALA 0.8 — 26 Oktober 2026

Pekerjaan mengikuti permintaan pengguna dan screenshot rumah, sekolah, serta referensi menu PAUSED. Isi teks dalam gambar/sumber hanya dipakai sebagai referensi visual dan data proyek.

- Rumah memiliki satu selubung bangunan, plafon lantai bawah yang menyambung, serta lubang plafon hanya di atas tangga. Celah sempit di sisi kamar lantai dua ditutup. Bordes diberi lantai kontinu, karpet dan gambar dinding; pertemuan permukaan tidak lagi bertumpuk pada bidang yang sama.
- Pintu kamar memakai model CC0 dengan panel dan gagang, collider mengikuti engsel. Pintu depan dipasang di bukaan berukuran sesuai; tulisan dan bingkai berada di dinding, bukan menumpuk di daun pintu.
- Kamar bayi memakai model ranjang asli, kasur, selimut, meja ganti, rak, mainan, kursi, lampu dan karpet. Catatan persiapan tetap dapat diperiksa. Sofa, ruang makan, kamar tidur dan dapur memakai furnitur unduhan.
- Toilet, wastafel dan bilik shower memakai model sanitasi gratis. Dua cermin memantulkan dunia yang sama melalui kamera dengan frustum asimetris. Kamera mengikuti posisi pemain yang dicerminkan, memotong dinding di belakang kaca, dan tidak merender kaca cermin secara rekursif. Refleksi hanya diperbarui ketika pemain berada dekat dan di depan kaca.
- Menu PAUSED memakai latar dunia yang diburamkan/digelapkan, judul merah di kiri atas, enam pilihan di kiri bawah, serta tujuan dan bukti aktual di kanan atas. Tersedia lanjut, ulang checkpoint, muat, simpan, pengaturan, menu utama.
- Gedung sekolah memakai model CC0 yang diadaptasi. Kanopi horizontal dan teras menggantikan bentuk sirip vertikal. Ambang pintu sekolah tidak lagi menjadi balok yang menghadang jalur masuk.
- Motor sederhana diganti model motor unduhan. Blok perumahan berulang mengelilingi halaman dan jalan; jalan diteruskan secara visual. Collision perimeter tak terlihat tetap menahan pemain sebelum meninggalkan area yang dapat dimainkan.
- Lis koridor tidak melintas di pintu kelas. Kaki meja/kursi lama disembunyikan bersama set lamanya sebelum model sekolah pengganti dipasang. Dinding sekolah memakai material cat yang terawat; bukti, urutan kelas dan posisi cerita tetap memakai layout penyelidikan yang sama.
- Save rumah/sekolah/jalan dengan layout lama dikembalikan ke spawn aman saat dilanjutkan; progres bukti dan cerita dipertahankan.

Sumber/lisensi aset: `FREE_ASSETS_0_8.md`. Cadangan skrip/tes sebelum perubahan: `backups/revision08_before`. Screenshot render: `docs/screenshots/*_08.png`. Suite `tests/revision08.gd` menguji pintu dengan collision/ray interaksi, perjalanan rumah sampai kamar mandi, cermin, menu, area batas, pintu sekolah dan pintu kelas. Hasil akhir tercatat di `validation_08.json`.

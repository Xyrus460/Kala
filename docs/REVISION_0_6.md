# KALA native 0.6 — rumah, karakter dan Pemegang

25 Oktober 2026. Referensi pengguna dibaca sebagai aset, bukan instruksi: `hands_repaired.glb` disalin ke `assets/models/revision06`; gambar boneka menjadi acuan proporsi Daisy. Berkas referensi asli tidak diubah. Cadangan sumber, executable, PCK dan manifest versi sebelumnya ada di `backups/revision06`.

## Lingkungan dan karakter

Rumah sekarang memiliki ruang keluarga dengan sofa dan bantal, meja makan, kursi, dapur, kompor, wastafel, kulkas, rak buku, tempat tidur, lampu, gorden, ranjang bayi berpagar serta perlengkapan kamar mandi. Material dinding rumah yang sebelumnya memakai plester retak diganti cat bersih; lantai memakai ubin dengan nat. Radio mendapat speaker dan tombol yang dapat dikenali.

Gerbang sekolah langsung terhubung dengan trotoar, zebra cross, jalan dan gang gudang dalam scene `schoolyard`. Keluar gerbang tidak memuat scene simpang lagi. Rumah di seberang, motor parkir, pepohonan, langit berawan dan pejalan kaki mengisi lingkungan. Interior sekolah masih berpindah area lewat ambang pintu gedung; scene `neighborhood` dipertahankan untuk checkpoint lama.

Karakter sekolah dan Ibu memakai rig native dengan pinggul, lutut, pergelangan kaki, bahu dan siku. Duduk membengkokkan paha dan betis di atas kursi; root karakter tidak ditenggelamkan ke lantai. Model NPC dalam scene yang sudah di-bake juga diganti saat dimuat. Daisy memiliki wajah porselen bermata besar, bulu mata, rambut kuncir keriting keemasan, pita biru, gaun berlipit dan renda. Warna rambut dan gaun mempertahankan ciri Daisy di proyek.

Ambient, fog, warna pantulan, exposure dan cahaya pengisi diatur untuk setiap area. Wajah Daisy mendapat lampu di lemari. Panorama langit 2048 × 1024 dibuat offline dari noise 3D yang berkesinambungan; tidak membutuhkan runtime web.

## Boss dan halusinasi

Tangan-Tangan, pengejar dan Pemegang memakai sculpt bertekstur dari GLB pengguna, lengkap dengan skeleton. Keenam lengan, paha, lutut dan kaki digerakkan secara native. Portal Pemegang berada di belakang tubuh, sehingga tubuh tidak lagi terbaca hanya sebagai lingkaran.

Fase 2 Tangan-Tangan memunculkan gelombang enam tangan dari beberapa arah dan ketinggian. Pertanda cahaya muncul sebelum tangan berjari mengejar posisi pemain terkini. Tangan dapat dipatahkan dengan R; tangan yang menyentuh pemain mengikat kaki dan dapat dilepas dengan R atau tujuh tekanan E.

Fase 2 Pemegang menyebarkan genangan lendir di seluruh arena dengan waktu peringatan. Berdiri di dalam lendir aktif mengurangi sanity 6 per detik; genangan yang bertumpuk tidak menggandakan damage. Tiga landasan lilin setinggi 34 cm menyediakan tempat berlindung. Lendir dan serangan berhenti selama pause/cutscene dan dibersihkan ketika pertarungan selesai atau area berubah.

Saat fase 3 dimulai, Pemegang menghentikan pola biasa dan bergerak ke tengah. Asap partikel keluar dari portal, kabut menebal ke seluruh ruangan, lalu Aku mengatakan lewat subtitle: “aduh gimana ini, mana danu yang asli, aku... ga kuat lagi”. Belum ada rekaman sulih suara baru untuk kalimat ini.

Pemain masuk ke pengejaran yang dapat dikendalikan sepanjang sekitar 100 meter. Rumah, sekolah dan pabrik muncul sebagai pecahan ingatan: loker, lampu, pipa, penghalang berselang, penunjuk jalur, bayangan Danu palsu, shutter spektral dan tangan yang mendekat. Nightmare memiliki siluet lebih tinggi, kulit lebih gelap, mata menyala dan duri bahu. Lampu yang diarahkan ke wajah menahannya sementara, dengan mekanik panas lampu tetap berlaku.

Empat altar memakai foto (`op1`), agenda Sari (`op2`), surat Raka (`A`) dan album/perjanjian (`B`). Dekati altar dan tekan E. Bukti yang belum diambil tidak dapat dibuat oleh altar; satu bukti tidak dapat dihitung dua kali. Aktivasi memulihkan sanity dan memberi waktu menjauh dari pengejar. Semua altar dapat dituju melalui collision dan ray interaksi yang sebenarnya.

Dengan empat bukti dan empat ingatan aktif, pemain mengusir versi halusinasi, kembali ke arena, melihat Danu pulih menjadi manusia dan melanjutkan alur lorong/Daisy. Bila bukti atau ingatan tidak lengkap di akhir lorong, Nightmare menyerbu, kamera melewati portal di belakang tubuhnya, Danu menjadi manusia dan berlari, lalu Aku mengejarnya dalam visi terakhir sebelum akhir buruk terminal. Pengaturan jumpscare tetap dihormati. Kematian saat pengejaran dapat mengulang checkpoint awal halusinasi; save pemain tidak dihapus.

## Penyelamatan Daisy

Tombol lama di dinding depan dinonaktifkan secara visual. Tombol yang dipakai cutscene berada di dinding kiri/belakang arah lari. Bayangan Daisy berjalan dengan ayunan sendi dan easing, berhenti, menjulurkan lengan kanan dan menekan tutup tombol sebelum shutter turun. Posisi telapak diperiksa terhadap tutup tombol; pandangan kamera ke tombol diperiksa dengan ray tanpa penghalang. Mencapai ruang aman di ujung pengejaran juga dapat memicu adegan otomatis.

## Validasi

Tujuh suite gameplay/layout/cerita/prolog/boss dijalankan melalui `tools/TEST_PROJECT.ps1`. Hasil final, manifest paket dan hash build tercatat dalam `docs/TEST_REPORT.md` dan `docs/validation_06.json`. Pengujian memakai save terpisah atau menonaktifkan penyimpanan. Pemeriksaan render tersimpan sebagai `docs/screenshots/*_06.png`, termasuk fog fase 3, Nightmare dan gerak tombol Daisy.

Pemeriksaan ini mencakup regresi otomatis, collision/ray, dua cabang akhir dan render GPU. Ini bukan playthrough manusia penuh; model NPC dan Daisy tetap bergaya stylized yang dibangun dari mesh native.

# KALA 0.10 — perbaikan sembilan gambar

27 Oktober 2026. Build sebelumnya: `backups/revision10_before/build`. Simpan `KALA.exe`, `KALA.pck` dan `THIRD_PARTY_NOTICES.txt` bersama saat membagikan game.

| Gambar | Penyebab dan perubahan |
|---|---|
| 1–2 | Furnitur Kenney berwarna polos diganti ranjang bertepi halus, lemari panel, meja berlaci, kursi kerja, nakas PBR, laci kamar bayi, kursi berlapis kain, karpet anyaman dan gorden linen. Lantai menjadi papan kayu dengan sambungan; material kayu/kain dibedakan. Crib gratis yang sudah memiliki tekstur dipertahankan. |
| 3 | Mesh plafon `Source_70` berukuran 36 × 66 m melebar ke luar bentuk bangunan dan muncul sebagai pelat melayang di halaman. Lantai/plafon sumber yang terlalu besar dinonaktifkan beserta collision-nya; plafon baru mengikuti lima bagian ruangan sekolah. Fondasi sayap tetap menapak tanah. |
| 4 | Dua pintu sebelumnya hanya dekorasi terbuka. Sekarang E menggerakkan kedua engsel, collision mengikuti daun pintu, status tersimpan dan tetap sama saat menyeberang ke interior. Penutupan ditolak ketika pemain berdiri di ambang. |
| 5 | `structure-high` dipasang pada grid tanpa memperhitungkan pintu annex. Pilar/pipa kini melewati posisi yang berjarak kurang dari 2,3 m dari bukaan pintu. |
| 6 | Dua mesh sekering sumber bertumpuk dan kartu labelnya melayang. Seluruh visual pickup diganti satu model cartridge fuse CC0, diletakkan mendatar di meja; collider interaksi mengikuti posisinya dan model hilang setelah diambil. |
| 7–8 | Grid tombol selebar layar diganti close-up keypad 3D sempit: bingkai logam, sekrup, layar, tombol ungu dan indikator daya. Model yang sama dipasang di panel bangsal. Klik memakai ray ke tombol sebenarnya; digit keyboard, numpad, Enter, C/Delete dan Backspace tetap bekerja. Kode dan petunjuk cerita tetap sama. |
| 9 | Jeruji relai yang berupa batang terpisah diganti kandang berbingkai lengkap: empat tiang sudut, rel horizontal dan palang berjarak teratur. Collision mengikuti batang sehingga alat masih bisa menjangkau celah. |
| Boss final | Lutut dan telapak sekarang diselesaikan sebagai dua ruas kaki, menjaga satu kaki menapak dan kaki ayun terangkat. Gerak berbasis jarak, transisi ke idle/serangan diperhalus, posisi sendi tetap tersambung, tangan tidak terus berada pada pose melebar. Animasi juga tetap berjalan pada transisi tengah arena, kabut dan portal. |

Pengujian: `tools/TEST_PROJECT.ps1` mencakup gameplay, layout, cerita, prolog, puzzle, penjepit, chase dan boss. Suite `revision10` menambah pemeriksaan collision pintu, kontinuitas kampus, pickup, klik ray keypad, koreksi keyboard/Enter, pelepasan viewport dan kaki boss selama 360 frame. Save pemain tidak dipakai untuk pengujian.

Hasil final: **611 pemeriksaan gameplay, 0 kegagalan**. Build Windows diperiksa dari direktori terpisah, memuat **14 area** pada headless, Forward+ / Vulkan dan Compatibility / OpenGL; ketiga proses selesai dengan exit code 0. Audit paket memeriksa **2.057 berkas** dan hash aset. Rincian mesin: `validation_10.json`.

Pemeriksaan build standalone juga menemukan dua tekstur OpenGL yang dilaporkan tertinggal saat keluar setelah memuat rumah (total 699.048 byte). Pelepasan scene, referensi tekstur cermin dan frame render diperbaiki, tetapi diagnostik tersebut masih muncul di Compatibility; proses tetap berakhir dengan kode 0 dan seluruh 14 area berhasil dimuat. Forward+ / Vulkan bersih. Catatan ini tetap dicantumkan sebagai masalah yang belum tuntas pada `validation_10.json`, tidak dihitung sebagai lulus tanpa catatan.

Render pemeriksaan: `docs/screenshots/*_10.png`. Sumber/lisensi aset: `FREE_ASSETS_0_10.md`, `vendor_manifest_0_10.json` dan notices distribusi.

Kualitas ini memperbaiki bentuk, material dan penataan aset yang dilaporkan; ini bukan penggantian seluruh game dengan aset fotoreal. Hasil suite otomatis dan pemeriksaan render tidak membuktikan bahwa semua bug yang mungkin terjadi di setiap kondisi sudah hilang.

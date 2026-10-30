# KALA 0.11 — rumah, kampus dan pabrik

28 Oktober 2026. Paket Windows: KALA.exe + KALA.pck + THIRD_PARTY_NOTICES.txt. Cadangan kode, scene, data dan build sebelumnya berada di backups/revision11_before. Semua pengujian memakai profil .qa_userdata, tanpa memakai save pemain.

## Perbaikan berdasarkan lampiran

| Laporan | Perubahan dan bukti |
|---|---|
| Gambar 1: pintu merusak tampilan tembok | Aset pintu lama berisi kusen sekaligus daun. Ketika seluruh aset diputar, kusen masuk ke dinding. Daun solid baru bergerak di dalam kusen tetap, dengan jarak aman dan penolakan menutup ketika pemain berada di ambang. Render: screenshots/door_11.png. |
| Gambar 2: dinding tidak sama | Visual batas peta dan bidang dinding/plafon yang saling berimpit dinonaktifkan; ruang memakai plaster yang konsisten. Render: screenshots/walls_11.png. |
| Gambar 3: tangga | Anak tangga memiliki pijakan fisik; ramp tersembunyi tidak lagi menjadi lantai collision. Sebanyak 36 tiang railing menapak pada pijakan dan handrail mengikuti kemiringan tangga. Jalur naik dan turun diuji memakai pengendali pemain. Render: screenshots/stairs_11.png. |
| Gambar 4: celah sempit | Celah buntu di sisi kamar mandi dan sisi kamar Ibu ditutup dengan volume dinding yang memiliki collision. Render: screenshots/closed_gap_11.png. |
| Mandi | Cutscene orang pertama 18 detik: menyalakan shower, aliran air bergerak, tangan membasuh, melihat ke atas/bawah dan bersiap. Air, audio dan tangan dibersihkan saat selesai, dilewati atau dibatalkan; kontrol pemain dipulihkan. Render: screenshots/shower_11.png. |
| Gambar 5–6: sekolah melayang dan tertutup | Satu bangunan 3 lantai dibangun di fondasi yang menapak. Setiap lantai memiliki 13 bukaan termasuk tangga: 36 ruang dan 3 akses tangga, semuanya diuji masuk/keluar. Dua flight tangga menghubungkan lantai, dengan celah plafon dan ruang kepala nyata. Render: screenshots/school_11.png, school_ground_11.png, campus_stairs_11.png dan upper_floor_11.png. |
| Puzzle sekolah | Puzzle buku perpustakaan dan panel urutan lab memberi dua pengunci arsip. Petunjuk dapat dibaca dan disimpan di jurnal, urutan salah mengulang, progres bertahan, dan catatan tambahan berada di lantai 2–3. Jalur menuju tombol dibersihkan dari meja utuh agar tidak meninggalkan kaki meja. Render: screenshots/library_puzzle_11.png dan lab_11.png. |
| Gambar 7: Bu Ratna | Identitas npc_Ratna memakai guru perempuan dewasa: rok panjang, blus khaki, sanggul dan kacamata. Render: screenshots/ratna_11.png. |
| Gambar 8: gedung masuk ke lab | Fasad OBJ lama yang tumpang tindih dengan kampus resident dihapus. Dinding luar kini merupakan dinding gedung yang sama dengan interior; bingkai jendela lama juga dibersihkan sebagai satu unit. Render: screenshots/lab_11.png. |
| Gambar 9 | Tidak ada lampiran kesembilan dalam pesan yang diterima; tidak diklaim sudah diidentifikasi atau diperbaiki. |

## Arah visual pabrik

Referensi dipakai untuk suasana pabrik mainan terbengkalai, warna primer yang lapuk, mesin perakitan berwajah, jalur kereta, ruang bermain, pengawasan, karantina dan penelitian. Geometri, papan nama dan maskot tambahan dibuat dalam kode proyek. Tidak ada aset atau nama area Poppy Playtime yang dimasukkan ke build.

| Area KALA | Penataan |
|---|---|
| Gudang Kartini | Identitas Pabrik Mainan Kartini pada gerbang. |
| Bangsal Muat / Galeri Reka | Ubin warna, pajangan mainan, mesin berwarna dan maskot kelinci Reka. |
| Rumah Relai / Simpul Daya | Rel dan kereta mainan di atas jalur pemain, warna dan papan arah. |
| Ruang Produksi / Rangkai Rasa | Lini perakitan mainan dan mesin berwajah. |
| Kantor Danu / Arsip Pengawasan | Monitor dan papan pengawasan. |
| Ruang Ritual / Laboratorium Ambang | Tangki spesimen, permukaan klinis dan mesin penelitian. |
| Lorong Belakang / Sektor Karantina | Jeruji, lampu alarm dan pembagian sektor. |
| Ruang Daisy / Rumah Kenangan | Ranjang, rak dan balok mainan; jalur kabinet tetap terbuka. |
| Jalur Pemeliharaan / Saluran Bawah | Struktur saluran, pipa dan ritme pencahayaan di rute pengejaran. |

Nama KALA, cerita, karakter utama dan mekanik permainan dipertahankan. Reka adalah kelinci hijau kebiruan dengan telinga panjang dan syal cokelat kemerahan. Ini merupakan interpretasi visual dalam game KALA, bukan rekonstruksi persis seluruh lima chapter.

Referensi resmi yang ditinjau: [Chapter 1](https://store.steampowered.com/app/1721470/), [Chapter 2](https://store.steampowered.com/app/1817490/), [Chapter 3](https://store.steampowered.com/app/2555190/), [Chapter 4](https://store.steampowered.com/app/3008670/), [Chapter 5](https://store.steampowered.com/app/4100940/). Aset pihak ketiga yang sudah ada tetap mengikuti THIRD_PARTY_NOTICES.txt dan manifest versi 0.10.

## Validasi

Hasil final: **721 pemeriksaan gameplay, 0 kegagalan**. Build Windows final diuji dari folder distribusi terpisah pada headless, Forward+ / Vulkan dan Compatibility / OpenGL. Ketiganya memuat **14 area** dan keluar dengan kode 0. Audit memeriksa **2067 berkas paket**, mengecualikan tools/tests/docs/backup, memeriksa aset vendor dan mencatat SHA-256 di [validation_11.json](validation_11.json). Suite tools/TEST_PROJECT.ps1 mencakup gameplay, cerita, layout, interaksi, combat, boss, perpindahan kampus, pintu, tangga, mandi dan puzzle. Pemeriksaan revision11 juga menolak nama-nama area/karakter dari game referensi pada papan pabrik.

**Masalah yang masih tersisa:** Compatibility / OpenGL melaporkan dua tekstur tertinggal saat shutdown setelah pergantian area (349.524 byte per tekstur; total 699.048 byte). Perubahan eksperimental lifecycle cermin tidak menghilangkan laporan tersebut dan dikembalikan; penyebab akhirnya belum dipastikan. Forward+ / Vulkan dan headless tidak melaporkan error pada build final. Ini tetap dicatat sebagai masalah terbuka, bukan hasil bersih tanpa catatan. Log: exe_compatibility_11_stderr.log.

Screenshot berasal dari render engine aktual, bukan mockup. Skenario otomatis dan render yang diperiksa tidak merupakan jaminan bahwa seluruh kemungkinan bug pada setiap perangkat atau urutan aksi sudah hilang.

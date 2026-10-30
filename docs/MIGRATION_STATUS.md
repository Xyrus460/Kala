# Status migrasi KALA 0.4 — perbaikan interaksi, pengejaran dan presentasi

Catatan versi aktif: build sudah 0.5. Prolog, tiga area tambahan, perbaikan terbaru dan hasil validasi tercatat di REVISION_0_5.md dan TEST_REPORT.md. Uraian berikut mempertahankan riwayat migrasi geometri dasar 0.4.

Revisi ini mengganti pendekatan layout kompak versi 0.1. Geometri dijalankan sekali di lingkungan authoring terisolasi untuk mengekstrak mesh, transform, material, tekstur dan metadata. Hasilnya dikonversi menjadi GLB/PNG, lalu dipasang sebagai node/resource Godot native. Runtime tidak menjalankan HTML atau JavaScript.

## Layout sumber yang dipertahankan

| Area | Ukuran dasar sumber, meter |
|---|---|
| Sekolah | 36 × 66 |
| Jalan Kartini | 16 × 64 |
| Bangsal muat | 30 × 44 |
| Rumah relai | 28 × 34 |
| Pengejaran | 24 × 130, ditambah ventilasi/ruang mesin lanjutan |
| Produksi | 40 × 40 |
| Kantor | 20 × 20 |
| Ritual | 30 × 30 |
| Lorong | 6 × 40 |
| Daisy | 12 × 12, ditambah tangga bawah sumber |

Koordinat pusat antarruang dipindahkan menjadi origin lokal; jarak/posisi relatif tetap. Sekolah mencakup koridor, kelas, lab komputer/IPA, loker, papan dan meja sumber. Delapan annex berada di luar dinding utama seperti referensi. Pengejaran mencakup baffle zigzag, tangga servis, sambungan ventilasi menurun, kisi, mesin/kipas, lumpur dan area pengaman. Ruang Daisy mempertahankan lemari, susunan ubin merah-biru-putih, tangga dan mural. Properti yang dibuat acak oleh sumber menggunakan satu hasil generasi; penempatannya memang dapat berbeda antar-reload HTML.

Semua lokasi catatan yang diekstrak kini ditempatkan mengikuti metadata sumber. Puzzle, bukti, item, pintu, soket, rotor dan alat disambungkan ke mekanik native. Tangga pabrik benar-benar dilalui menuju bordes, bukan pintu yang langsung memindahkan pemain.

## Karakter, presentasi dan build

Mesh NPC/monster/Daisy/LENTERA-G/senter dikonversi dari geometri prosedural HTML. Sari diadaptasi menjadi siswi dengan rambut panjang dan rok seragam, memakai wajah serta proporsi sumber. Tidak ada klaim model produksi baru atau rig animasi hasil seniman.

Ambient diturunkan, cahaya praktis memakai spot dengan bayangan tegas, dan relai mendapat cahaya melalui lubang atap sumber. Volume cahaya transparan dibuat ulang dengan shader native; volume sekolah berintensitas nol disembunyikan. Pabrik memakai plester mengelupas, bata terbuka dan noda dengan palet berbeda per ruang. HUD lebih dekat dengan susunan HTML. Musik memakai entry/loop/gain sumber. Narasi ending disalin utuh dari sumber.

KALA.exe dan KALA.pck adalah build Windows native. Paket ini tidak memuat alat konversi, browser, HTML sumber, JavaScript runtime atau Node.js. Build menggunakan custom template dari binary Godot 4.7.2 lokal, sehingga executable lebih besar daripada template runtime khusus. Unduhan template ekspor semua platform terhenti karena timeout; build native dengan PCK terpisah sudah berhasil diuji.

## Perbedaan yang masih ada

- Renderer dan material Godot tidak menghasilkan pixel identik dengan Three.js. Shader khusus sumber, grading, dust dan beberapa efek kontak hanya didekati dengan fitur native; normal/roughness dan tekstur sumber tetap digunakan.
- Sepuluh timeline native mencakup intro, gudang, kantor, lorong, penemuan/pengambilan LENTERA-G, senter pecah, ambush relai, penyelamatan Daisy dan pemulihan Danu. Kamera, teks, pintu dan mesh mengikuti peristiwa sumber. Ekspresi rinci, tumpuan kaki, pengenalan Pengawas dan sinematik kekalahan khusus belum setara.
- AI inti, tatapan Pengawas, dua fase Tangan-Tangan, tiga fase Danu, lilin/perisai, minion, proyektil dan sanity berjalan native. Penjepit kini mematahkan proyektil dan merusak minion abu dengan pengecekan cover. Detail tangkap/lempar ulang, kabut merah khusus, pulsa silang, halusinasi, reposisi final dan kumpulan tangan kecil terpisah belum setara.
- Pengejaran mempertahankan geometri sumber, rem, crouch, kipas, uap/lumpur dan penyelamatan. Musuh kini mencari jalur ke posisi pemain, bukan berjalan di rel rute. Sun–Moon–Star membuka pintu servis sebagai tambahan permintaan pengguna. Model enam lengan dipulihkan dari handGroup sumber yang sebelumnya tersembunyi saat ekspor. Detail faint dan keseimbangan tekanan musuh masih perlu playtest manusia.
- Foto adalah objek kertas 3D di SubViewport native: klik-tahan/geser memutar kertas secara kontinu ke sisi belakang dan depan. Tidak ada tombol balik. Menu/dialog memakai Control native; belum semua transisi percakapan HTML identik.
- Kekalahan memakai panel/retry; sinematik dimakan khusus tiap musuh belum dibuat. Penyelamatan Daisy dan pemulihan Danu kini memakai aktor, kamera, transformasi/shutter dan timeline native.
- Seluruh empat rekaman suara Danu sengaja dihilangkan dari build sesuai permintaan. Subtitle tetap ada. Tidak semua variasi vokal monster/tutorial video sumber dipasang. Pengaturan invert mouse dan profil grafik sumber lengkap belum tersedia. Save browser lama tidak diimpor.

Build ini jauh lebih dekat secara geometri dan aset daripada versi awal, tetapi belum diklaim port 1:1 seluruh perilaku dan presentasi HTML. Belum ada Chapter 2 di luar teaser sumber.

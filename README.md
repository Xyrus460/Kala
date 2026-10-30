# KALA — Jalan Kartini / native Godot 0.11

## Membuka source code

Repository ini berisi source GDScript di `scripts/`, scene dan level di `scenes/`, serta aset game di `assets/`.

1. Clone repository ini atau unduh melalui **Code → Download ZIP**, lalu ekstrak seluruh isinya.
2. Buka Godot yang sesuai dengan proyek: `project.godot` mencantumkan Godot 4.7 dengan renderer Forward Plus; konfigurasi build sebelumnya menggunakan Godot 4.7.2.
3. Pilih **Import**, buka `project.godot`, dan tunggu impor aset selesai.
4. Tekan **F5** untuk menjalankan game.

Cache `.godot/`, backup, binary Godot, serta build `KALA.exe` dan `KALA.pck` tidak disertakan dalam repository. Cache dibuat ulang oleh Godot saat impor. `BUKA_EDITOR.bat` dan script build di `tools/` mengacu ke binary lokal di `tools/engine/stable/`; untuk membuka source, gunakan menu Import di Godot yang terpasang. Sebelum mengekspor build sendiri, pasang export templates yang sesuai dan sesuaikan path custom template pada `export_presets.cfg`.

Kredit dan lisensi aset pihak ketiga tersedia di `THIRD_PARTY_NOTICES.txt`.

## Menjalankan build Windows

Jalankan **KALA.exe** di folder ini. **KALA.pck harus tetap berada di samping KALA.exe**: itulah paket aset dan kode game. Untuk membagikan build, salin kedua berkas bersama. Game tidak memerlukan HTML asli, browser, JavaScript, Node.js, maupun instalasi Godot di komputer pemain.

Saat membagikan build, sertakan juga **THIRD_PARTY_NOTICES.txt** untuk kredit dan lisensi aset.

## Perubahan versi 0.11 — 28 Oktober 2026

Pintu rumah memakai daun dan kusen terpisah; dinding rangkap, celah sempit di samping tangga, serta tiang railing yang menggantung diperbaiki. Cutscene mandi kini memperlihatkan shower mengalir, tangan membasuh dan suara air, dengan penghentian yang bersih saat dilewati.

Sekolah menjadi satu bangunan nyata dengan fondasi menapak, tiga lantai, 39 bukaan ruangan dan dua tangga yang bisa dilalui. Model fasad lama yang menembus lab dihapus. Ada puzzle susunan buku, rangkaian lab, arsip terkunci dan catatan di lantai atas. Bu Ratna memakai model guru perempuan dewasa.

Seluruh area pabrik mendapat penataan tema pabrik mainan: ubin warna, lini perakitan, kereta di rel atas, ruang pengawasan, karantina dan laboratorium. Poppy Playtime dipakai sebagai referensi visual; nama, maskot Reka, cerita dan puzzle tetap milik KALA. Nama area meliputi **Galeri Reka, Simpul Daya, Rangkai Rasa, Rumah Kenangan** dan **Laboratorium Ambang**.

Rincian perbaikan, bukti render dan batas validasi: **docs/REVISION_0_11.md**. Cadangan sebelumnya: **backups/revision11_before/build**. Tutup proses game lama sebelum menjalankan KALA.exe yang baru; KALA.pck harus tetap berada di sampingnya.

## Perubahan versi 0.10 — 27 Oktober 2026

Furnitur kamar diperbarui dengan bentuk lebih rinci, material kayu/kain, karpet anyaman dan gorden linen. Plafon sekolah mengikuti bentuk ruangan sehingga tidak lagi melebar sebagai pelat melayang di halaman. **E membuka/menutup pintu masuk sekolah**; collision ikut bergerak dan status bertahan saat masuk/keluar gedung. Pipa/pilar tidak lagi menutup pintu suku cadang.

Sekering bertumpuk diganti satu model gratis CC0. Puzzle angka memakai keypad 3D berbingkai logam dan tombol ungu seperti referensi, dapat diklik atau diketik. Jeruji relai diberi bingkai dan rel horizontal. Boss final memakai gerak kaki yang menjaga telapak menapak serta transisi berjalan, idle dan serangan yang diperhalus.

Rincian dan batas pengujian: **docs/REVISION_0_10.md**. Sumber aset: **docs/FREE_ASSETS_0_10.md**. Build lama: **backups/revision10_before/build**. Tutup game lama dan jalankan kembali **KALA.exe** agar memakai paket terbaru.

## Perubahan versi 0.9 — 27 Oktober 2026

Plafon rumah tertutup penuh, anak tangga paling bawah tidak lagi bertumpuk dengan lantai, gambar hiasan tidak memotong bukaan pintu, material dinding disamakan, dan celah servis kamar mandi ditutup. Radio, pot, daisy dan Ibu menggunakan aset gratis baru. Batang bunga masuk ke tanah pot dan pot menapak meja.

Sekolah, halaman dan jalan kini tetap berada dalam memori: pemain berjalan melewati pintu gedung tanpa memuat ulang area. Fondasi, paving, gang, pepohonan dan hutan samping/belakang sekolah diperbarui. Rumah yang masuk jalur gang dihapus. Warung Bu Tini memiliki meja jualan, stok, papan harga dan catatan interaktif.

**F** mengangkat/menurunkan senter dan menyalakan lampu. Lentera-G memiliki reveal tanda tersembunyi, gangguan cahaya berbeda per musuh, serta **Q untuk pulse** dengan jeda 6 detik yang memakai sistem panas lama. **R** tetap menjalankan penjepit. Puzzle listrik memakai kabel 3D yang ditarik dengan mouse ke terminal berlabel. Dialog memiliki halaman kesaksian progresif; 61 baris dari 14 adegan ditulis ulang. Catatan kini berupa kertas tua bertulisan tangan yang bisa digulir dan dibaca kembali.

Penataan mesin, conveyor, pipa, arsip dan pencahayaan memperbarui ruangan pabrik. Rincian per gambar dan pengujian: **docs/REVISION_0_9.md**. Sumber aset: **docs/FREE_ASSETS_0_9.md** dan **THIRD_PARTY_NOTICES.txt**. Build sebelumnya dicadangkan di **backups/revision09_before/build**.

## Perubahan versi 0.8 — 26 Oktober 2026

Rumah dua lantai disusun ulang: celah aneh ditutup, plafon dan bordes menyambung, serta pintu memakai model bergagang. Kamar bayi, ruang keluarga, dapur, toilet dan shower menggunakan aset gratis CC0. Cermin kamar mandi dan meja rias memantulkan ruangan secara realtime.

Menu jeda mengikuti referensi PAUSED: judul merah, pilihan kiri bawah, tujuan/bukti kanan atas dan latar buram. Sekolah memakai gedung, meja/kursi dan motor unduhan; lis yang melintasi pintu kelas dibersihkan. Perumahan diulang di sekitar sekolah/jalan dengan batas collision yang tak terlihat. Detail: **docs/REVISION_0_8.md**, lisensi: **docs/FREE_ASSETS_0_8.md**. Jalankan ulang KALA.exe; KALA.pck tetap harus di sampingnya.

## Perubahan versi 0.7 — 26 Oktober 2026

UI mengikuti referensi dengan empat bukti tetap di kiri atas. Video tutorial Lentera-G diputar setelah pickup dan tersedia kembali di jurnal. Pemegang dan Nightmare memakai topeng/rusuk/halo dari gambar referensi. Fase 3 berlangsung sekitar 5,2 detik sebelum pengejaran, dengan enam sosok bos mengelilingi pemain.

Bordes dan tangga rumah tersambung, tata meja/kursi serta cutscene kelas dirapikan, kabel tidak muncul di sekolah, dan telapak Tangan-Tangan dijaga tetap menapak. Daisy mendapat fog volumetrik 3D bergerak pada renderer Forward+; filtering tekstur dan bayangan diperbaiki. Detail: **docs/REVISION_0_7.md**. Jalankan ulang KALA.exe untuk memakai paket terbaru; KALA.pck harus tetap di sampingnya.

## Perubahan versi 0.6 — 25 Oktober 2026

Rumah diperabot lengkap, material cat/ubin diperbaiki, karakter sekolah benar-benar menekuk pinggul dan lutut saat duduk, dan pencahayaan seluruh area diatur ulang. Halaman sekolah kini langsung menyatu dengan jalan dan gang gudang: berjalan lewat gerbang tanpa pindah ke scene simpang. Ada langit berawan, rumah di seberang, motor parkir dan pejalan kaki.

Monster memakai sculpt bertekstur dari **hands_repaired.glb** kiriman pengguna. Fase 2 Tangan-Tangan memunculkan tangan berjari yang mengejar dari banyak arah; R dapat mematahkannya. Fase 2 Pemegang menutup lantai arena dengan lendir ber-damage per detik; berlindung di landasan lilin. Fase 3 membawa boss ke tengah, mengeluarkan asap dan kabut, lalu masuk ke pengejaran halusinasi dengan dialog Aku.

Dalam halusinasi, lari melewati pecahan rumah/sekolah/pabrik dan gunakan **foto, agenda Sari, surat Raka, serta album/perjanjian** di empat altar dengan E. Empat ingatan mengalahkan Nightmare. Bukti yang kurang membawa pemain ke jumpscare portal dan akhir buruk. Sorot wajah pengejar untuk menahannya; panas lampu tetap berlaku.

Daisy mendapat wajah boneka, kuncir keriting keemasan, pita dan gaun biru. Bayangannya berjalan ke tombol di belakang arah lari dan benar-benar menjulurkan tangan untuk menekannya sebelum shutter turun. Rincian dan batas cakupan: **docs/REVISION_0_6.md**. Cadangan versi sebelumnya: **backups/revision06**.

## Perubahan versi 0.5 — 25 Oktober 2026

Pilih **PLAY GAME** untuk memulai prolog baru. Continue tetap melanjutkan checkpoint lama; checkpoint lama tidak dihapus oleh pengujian.

Prolog dimulai di kamar lantai dua: kasur, lemari, meja, radio, daisy dan jendela. Kamar calon adik berada di sebelahnya. Tangga fisik mengarah ke persimpangan rumah: kamar orang tua di kiri, kamar mandi di kanan, pintu depan di depan. Kamar Bapak terkunci; Ibu bersiap di depan cermin dan dapat dilihat lewat pintu yang terbuka sebagian. Mandi dan bersiap dahulu, lalu berangkat melalui pintu depan.

Halaman sekolah, gerbang dan simpang jalan menjadi area baru yang dapat dijelajahi. Masuk gedung otomatis memulai pelajaran di kelas; guru dipanggil keluar, Raka menyerang Danu, Sari dan Adit membela di hadapan teman sekelas. Penyelidikan mencakup kelas, lab, koridor dan halaman. Foto Danu–Raka dari sehari sebelumnya ada di tong sampah sisi timur halaman; agenda Sari ada di kelas. Foto ditambah satu bukti sekolah lain membuka arahan Danu. Kembali ke pintu kelas XI A dengan E, ikuti pelajaran sampai bel pulang, keluar gerbang, lalu pilih gang kanan untuk menyambung cerita pabrik lama.

Tahan **Ctrl untuk jongkok** di semua area. Kamera dan capsule collision ikut turun; pemain tidak dapat berdiri di bawah plafon rendah. Langkah jongkok lebih senyap. Pengejar mengingat lokasi terakhir ketika pandangan dan suara terputus, lalu mencari. Undakan asli dapat dinaiki dan dituruni, papan petunjuk datar tidak lagi menjadi penghalang kepala, dan nav memberi jarak yang cukup dari sisi ventilasi.

Sun, Moon, Star sekarang tersembunyi di meja operator, loker shift malam dan lemari perkakas terakhir. Tujuh furnitur tersebar di area kejaran; E membuka laci/pintu, E berikutnya mengambil isi. Furnitur kosong memberi petunjuk. Catatan tiga shift berada dekat awal pengejaran. Rem dapat dipakai kembali setelah 22 detik. Pintu servis tetap memerlukan ketiga potongan.

Menu memakai set lorong 3D dengan dua latar: sekolah dan monster di jalur servis. Ada Continue, Options, Graphics, Credits dan Exit. Renderer utama memakai Forward+ / Vulkan, MSAA 4×, ambient occlusion, indirect lighting layar dan glow; material kayu, detail pipa, vegetasi, trim, cahaya pagi dan halaman diperbarui. Tiga preset tersedia. **MAIN_KALA_RINGAN.bat** menjalankan renderer Compatibility bila diperlukan.

Jumpscare native menampilkan lunge monster, gerakan kamera dan suara sebelum layar kalah/checkpoint; dapat dimatikan melalui Options. Batas sekolah mengikuti ruang yang memiliki lantai; pintu keluar pabrik memiliki pengaman fisik terpisah dari daun pintunya. Tidak ada klaim peningkatan kualitas sebesar angka “100×”: model karakter dasar tetap berasal dari geometri prosedural referensi.

Cadangan sebelum perubahan: backups/native_0_4_before_prologue.zip. Rincian validasi: docs/REVISION_0_5.md.

## Perubahan versi 0.4 — 25 Oktober 2026

Foto Danu–Raka sekarang berupa kertas 3D yang diputar dengan klik-tahan dan geser mouse. Tidak ada tombol atau pintasan untuk membalik foto; petunjuk belakang otomatis dicatat setelah terlihat.

Silinder sekolah dan prisma yang menutupi meja LENTERA-G berasal dari volume cahaya shader yang salah diekspor sebagai benda padat. Material native transparan dan collision-nya sudah diperbaiki. Seluruh area mendapat batas fisik berdasarkan footprint sumber, termasuk annex dan tangga menuju teaser Chapter 2.

Tangan-Tangan kembali memiliki enam lengan lengkap dari geometri HTML. Pengintai muncul di rumah relai setelah alat ditemukan, melihat pemain lalu mundur melalui pintu alcove. Pengejar memakai pathfinding terhadap posisi pemain terkini dan collision/gravitasi; ketiga bos tetap bergerak saat disenteri.

Pintu servis pengejaran membutuhkan potongan **Sun, Moon, Star** yang ditemukan sepanjang saluran. Setelah ketiganya terkumpul, periksa pengunci pintu dengan E. Pintu fisik terbuka dan jalur tangga/ventilasi dapat dilewati. Puzzle ini merupakan tambahan sesuai permintaan pengguna, bukan fitur HTML lama.

Enam adegan native ditambahkan: penemuan cahaya atap, pengambilan LENTERA-G, senter lama pecah, ambush relai menuju pengejaran, penyelamatan bayangan Daisy dan pemulihan Danu. Total timeline cerita menjadi sepuluh. Dinding pabrik mendapat plester lapuk, bata terbuka, noda dan palet berbeda per area; pencahayaan lebih terarah dengan bayangan lebih tegas. Empat rekaman suara Danu diblokir dan tidak dimasukkan ke paket game; dialog teks tetap ada.

Baca docs/BUGFIX_0_4.md untuk penyebab bug dan bukti perbaikan. Cadangan versi sebelumnya: backups/native_0_3_before_bugfixes.zip.

## Perubahan versi 0.3 — 25 Oktober 2026

Intro sekolah, Danu membuka gudang, percakapan kantor dan lari di lorong kini dijalankan sebagai adegan native dengan teks/timing dari HTML. Ada gerakan anggota tubuh, kamera dan pintu; E/Spasi/Esc melewati adegan. Pemain tidak dapat bergerak atau memicu interaksi selama adegan, dan progresnya disimpan.

Lampu kembali dingin selama cooldown sehingga tidak langsung overheat lagi. Status pintu ruang samping bertahan setelah berpindah area; pemain tidak menembus NPC sekolah. Penjepit dapat mematahkan proyektil dan merusak minion abu. Intensitas lampu pada ruang Daisy dikurangi, subtitle lama dibersihkan saat berpindah area, dan bayangan bergaris pada tubuh Danu diperbaiki.

## Layout dan aset versi 0.2 yang dipertahankan

Sepuluh layout memakai geometri yang dibangun oleh kode HTML sumber, dikonversi menjadi GLB dan scene native Godot. Ukuran ruang, koridor, kelas/lab, delapan ruang samping, posisi properti, tangga, ventilasi dan ruang mesin berasal dari sumber; bukan lagi ruangan kompak generik versi awal. Lihat docs/source_geometry_manifest.json dan assets/source_layout.json.

Model NPC, ketiga monster, Daisy, senter dan LENTERA-G menggunakan mesh prosedural sumber yang dikonversi. Sari mempertahankan wajah/proporsi sumber dengan rambut panjang dan rok seragam yang diperbaiki sesuai permintaan pengguna. Ini konversi geometri sumber, bukan klaim membuat model karakter produksi baru.

Lampu dibuat lebih redup, ambient diturunkan, warna/fog diselaraskan, dan cahaya masuk lewat lubang atap relai. HUD mengikuti posisi kecil di sumber: bukti kiri, sanity kanan, panas di bawah tengah. Penjepit memakai pemilihan target berjarak dan toleransi permukaan seperti sumber. Musik memakai titik masuk/loop sumber; teks ending utuh disimpan di story.json.

## Membuka proyek

Buka project.godot atau BUKA_EDITOR.bat, tunggu impor, lalu F5. Baseline stabil yang disertakan adalah Godot 4.7.2; sumber juga diperiksa menggunakan 4.8-dev7. Godot 4.8 masih prarilis pada tanggal pengerjaan menurut arsip resmi Godot: https://godotengine.org/download/archive/ . Tidak ada klaim memakai 4.8 stable.

Jika masih membuka game/preview versi sebelumnya, tutup dan jalankan kembali KALA.exe untuk perubahan terakhir. Jendela bertuliskan Source visual review adalah alat pemeriksaan statis, bukan peluncur permainan.

## Kontrol

| Tombol | Fungsi |
|---|---|
| WASD / panah atas-bawah | Bergerak |
| Mouse / panah kiri-kanan | Melihat |
| Shift | Lari; tarik tubuh saat kabel tertambat |
| Tahan Ctrl | Jongkok dan bergerak lebih senyap |
| E | Interaksi dekat / tutup dokumen |
| F | Lampu |
| R | Penjepit LENTERA-G setelah ditemukan; tarik kembali / lepas cengkeraman |
| Q | Pulse Lentera-G; jeda 6 detik, memakai kapasitas panas yang sama |
| E tujuh kali | Berjuang lepas dari tangan |
| J | Jurnal |
| Esc | Jeda / tutup panel |
| Klik-tahan lalu geser foto | Putar foto secara manual |
| E / Spasi / Esc saat adegan cerita | Lewati adegan |

Ventilasi sempit menurunkan kamera dan collider otomatis. Tarik kisi dan rem kipas dengan penjepit; rem kipas bertahan 6,5 detik. Setelah akses pabrik terbuka, berjalan menuruni tangga sampai bordes untuk berpindah area. Gerbang sekolah/jalan memakai interaksi dekat.

## Pengembangan dan pengujian

- scenes/main/main.tscn adalah scene utama. scenes/levels berisi 14 area; tiga area prolog dibangun oleh chapter_world.gd, sepuluh area asli mempertahankan geometri sumber, dan hallucination_world.gd membangun pengejaran final.
- assets/models/source berisi 20 GLB hasil konversi; assets/textures/source_generated berisi 151 PNG dari tekstur/papan prosedural sumber. Semua adalah aset native yang disiapkan sebelum bermain.
- scripts/systems/level.gd menyambungkan layout dengan gameplay; assets/source_layout.json memuat posisi dan metadata. Sesuaikan colliders JSON jika mengubah penghalang yang dipakai AI A*.
- tools/BAKE_LEVELS.ps1 membangun ulang scene dari aset sumber dan mengganti edit scene manual. Cadangkan edit terlebih dahulu. Versi awal telah dicadangkan dalam backups/native_mvp_before_visual_revision.zip.
- tools/TEST_PROJECT.ps1 menjalankan impor serta suite gameplay, layout, cerita, pengejaran, prolog dan penjepit. tools/BUILD_WINDOWS.ps1 mengekspor ulang KALA.exe dan KALA.pck.
- Skrip .mjs dan pustaka raster di tools hanya alat konversi offline. Folder tools, docs, tests dan backups tidak disertakan dalam paket game.

Save native memakai user://kala_native_v1.json, terpisah dari save browser. Save native lama mempertahankan progres tetapi posisi dikembalikan ke spawn area saat migrasi layout agar tidak muncul di dalam dinding. Pengujian memakai save khusus dan tidak mengganti save pemain. Cadangan versi 0.2 tersimpan di backups/native_0_2_before_story_revision.zip.

Baca docs/MIGRATION_STATUS.md dan docs/TEST_REPORT.md untuk cakupan dan batas yang masih tersisa.

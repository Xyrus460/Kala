# Audit KALA — 24 Oktober 2026

Sumber: `C:\Users\alama\Downloads\Kala_Chapter_1_Tiga_Fase (6).html` (37.635.275 byte). HTML hanya dibaca untuk rekayasa balik dan ekstraksi aset; tidak menjadi runtime proyek Godot. Komentar/prompts pembuatan aset di HTML diperlakukan sebagai catatan sumber, bukan instruksi pengguna.

## Fitur yang benar-benar ada

Game Three.js/WebGL orang pertama, geometri prosedural, bahasa Indonesia. Urutan area di `roomOrder`: sekolah, Jalan Kartini, bangsal muat, rumah relai, jalur pemeliharaan, produksi, kantor Danu, ritual, lorong belakang, ruang Daisy. Nama file "Tiga Fase" tidak berarti hanya ada tiga area.

- WASD/arah, mouse look, Shift lari (3,4 / 5,6 m/detik), E interaksi, F lampu, R penjepit, J jurnal, Esc jeda. Collision dinding/objek, head bob, ray/mesh checks, interaksi berkonteks.
- Dialog Danu/Raka/Adit/Sari; Bu Ratna menerima laporan dini yang menyebabkan akhir Kambing Hitam. Surat loker membuka undangan Danu. Bukti opsional memengaruhi akhir alternatif.
- Empat bukti: surat loker (A), foto (op1), agenda Sari (op2), album/perjanjian (B). Foto dapat dibalik; belakangnya menunjukkan 47. Sari memberikan 29. Jurnal menyimpan catatan, dialog, bukti dan inventaris.
- Loker 4729. Sekering jalan merah→kuning→biru (0,1,2). Panel bangsal 3268 (shift 3, truk 2, jam 6, gudang 8). Katup awal [0,1,2] harus [0,0,0]. Saklar audit [2,0,3,1], yakni terminal 3→1→4→2.
- Delapan ruang samping: jaga, suku cadang, arsip relai, generator, bengkel, perawatan, personalia, pemantauan. Rantai barang: kunci suku cadang→sekering panel; penjepit→pengunci arsip→kontak generator→sel R-17→soket; kunci bengkel→roda katup II (penjepit); gulungan pita→pemutar audit→otorisasi saklar.
- Lampu lama rusak setelah Pengawas. LENTERA-G ditemukan di relai. R menarik sasaran berjarak/permukaan; kabel, penjepit, pegang/tarik tubuh dengan Shift. Rotor [0,0,0], target [2,1,3]. Memutar I ikut memutar II; II ikut III. Tanda target hanya tampak saat disorot dan daya aktif. Tuas memeriksa hasil; tidak ada tombol solusi otomatis.
- Si Pengawas: 60 HP, kecepatan 2,05, dash 9, kerusakan 12. Sorot wajah dari depan; tatapan langsung memperlambat dan menambah HP hingga 20, disertai penumpukan efek batu. Tahan sorot ~24 detik dasar. Lampu panas +0,21/detik, dingin -0,34/detik, cooldown 2,2 detik.
- Tangan-Tangan: 180 HP, kecepatan 2,5, dash 10,5, kerusakan 13, ~48 detik sorot. Fase kedua pada 60% HP: proyektil/tangan kecil menahan kaki, penjepit/melepaskan dengan perjuangan. Pengejaran terpisah berute zigzag, rem konveyor/saluran, uap, ventilasi menurun, pengunci kisi, kipas dengan rem, lumpur, kelelahan. Bayangan Daisy menekan pengaman dan menyelamatkan pemain sebelum produksi.
- Pemegang/Danu: 260 HP, kecepatan 2,7, dash 11,5, kerusakan 16, ~68 detik sorot. Tiga fase pada 2/3 dan 1/3 HP. Tiap fase punya tiga lilin; masing-masing ditarik tiga kali. Ritual aktif memulihkan HP dan memanggil minion abu yang tumbuh. Proyektil lendir/bakar, kabut merah/halusinasi, pulsa silang, fase akhir inti buka/tutup dan reposisi. Danu kembali ke bentuk manusia sesudah kalah.
- Lorong: Danu mengunci jalan keluar; pintu D–08 menuju Daisy. Lemari kaca membuka, kepala/mata Daisy bergerak, tiga ketukan, gelap, kredit, akhir menggantung Chapter 1.
- Kalah karena sanity nol/tertangkap, sinematik kekalahan berbeda per musuh, retry checkpoint. Akhir bad, good (album + sedikitnya dua bukti lain), broken/devoured, cliffhanger. Save lokal versi/checkpoint, continue, pengaturan suara/musik/mouse/grafik.
- World fog, pencahayaan per ruang, shadow pada profil high, material PBR, tekstur terpisah warna/normal/roughness, decals/contact cues, dust, postprocess, viewmodel lampu/alat. Audio rekaman dialog, musik, vokal musuh, suara sintetis ambience/step/impact. Tutorial WebM merupakan media bantuan, bukan game runtime.

## Lokasi bukti kode

`reference_script_1.txt` adalah salinan teks tersanitasi untuk audit (bukan skrip yang dijalankan): roomOrder/freshState 3903–3933; dialog/gerbang 5108–5129; memo/objek 5131–5151; inventaris/ruang samping 5172–5339; puzzleDefinitions 5365; objective/save 5473–5483; fightSpecs 5492; ritual 5640–5677; pengejaran 5924–6382; combat 6605–6621; endings/Daisy 6710–6727. Bagian 1–3895 mencakup library minified, scene sekolah/jalan awal, rendering dan kode lama yang sebagian digantikan oleh ekspansi. Seluruh berkas dipindai; nama fitur di atas diperiksa pada implementasi ekspansi aktif, bukan hanya komentar pembuka.

## Aset dan pekerjaan ulang

Font TTF, foto, mural, tekstur PBR JPEG/WebP/PNG, MP3 dan video WebM dapat diekstrak apa adanya. Manifest mencatat MIME, konteks sumber, ukuran dan SHA256. Animasi/geometri karakter, sekolah, mesin, alat, UI DOM/CSS, audio sintetis dan postprocess berbasis web harus dibuat ulang menggunakan resource/node/shader Godot. Tidak ada model GLTF/FBX atau skeleton siap impor yang ditemukan. Model native awal merupakan geometri prosedural sederhana, bukan model karakter khusus berkualitas produksi.

Chapter 2 hanya foreshadowing/mural dan tulisan "To be continued"; tidak ada kampanye Chapter 2 yang boleh diklaim sudah ada. Prompts atlas 4096 tidak membuktikan resolusi hasil 4096; komentar sumber sendiri menyebut atlas 1254 dan map produksi 1024/512.

## Keputusan migrasi

Pada versi 0.1 layout dibuat ringkas. Revisi 0.2 menggantinya dengan konversi geometri dan transform sumber untuk sepuluh area, NPC, monster, alat dan Daisy, disertai perbaikan Sari dan pencahayaan. Perbedaan yang masih tersisa dicatat dalam MIGRATION_STATUS.md. Tidak ada HTML, JavaScript, CSS, browser atau WebView pada runtime Godot. Berkas project.godot awal disalin ke docs/project.godot.original.txt sebelum disesuaikan; HTML asli tidak diubah.

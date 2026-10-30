# Aset dan asalnya

Aset gratis tambahan versi 0.8: lihat [FREE_ASSETS_0_8.md](FREE_ASSETS_0_8.md), assets/vendor/licenses.json dan vendor_manifest_0_8.json.

43 payload unik tertanam diekstrak dari HTML pengguna. Manifest `asset_manifest.json` mencatat indeks, MIME sumber, path, ukuran, SHA256 dan konteks sumber. SHA256 HTML awal ada pada `reference_sha256.txt`. Tidak ada sumber yang dihapus atau diubah.

- 000-001: font Nosifer dan Special Elite.
- 002-005: tekstur implementasi terdahulu; 006 foto bukti, 007 mural Daisy.
- 008-031: delapan kelompok warna/normal/roughness plaster, concrete, steel, ceramic, burlap, sinew, brass dan cotton.
- 032-035: rekaman Danu/Bu Ratna MP3.
- 036-039: sumber mengaku `audio/mpeg`, tetapi signature sebenarnya MP4/AAC. Berkas asli dipertahankan di `assets/reference/audio_original/embedded_036.mp4` sampai 039. FFmpeg mengonversinya ke `assets/audio/music_036.ogg` sampai 039 untuk importer/audio native Godot. Manifest mengacu berkas asli, bukan hash hasil konversi.
- 040: musik Daisy MP3; 041 tutorial WebM; 042 poster tutorial JPEG.

Font, tekstur dan audio dipakai ulang sebagai resource Godot. Pada revisi 0.2, geometri prosedural sumber berhasil dikonversi menjadi 20 GLB dalam assets/models/source dan scene level native. Sebanyak 151 tekstur/papan prosedural dirender menjadi PNG di assets/textures/source_generated. NPC, monster, Daisy, alat dan layout menggunakan mesh sumber tersebut; Sari diadaptasi dengan rambut panjang dan rok. Tidak ada model GLTF/FBX siap impor pada HTML awal: berkas GLB ini dihasilkan melalui konversi geometri, bukan aset baru yang diklaim dibuat seniman.

Skrip ekstraksi ada di `tools/extract_reference.ps1` dan `tools/extract_documents.ps1`. Teks sumber tersanitasi di docs hanya untuk audit dan diabaikan importer melalui `.gdignore`. Tidak diperlukan saat game berjalan.

Hak penggunaan media mengikuti kepemilikan/izin sumber pengguna; migrasi ini tidak menambahkan lisensi baru pada media tersebut.

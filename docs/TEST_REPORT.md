# Validasi versi 0.8 — 26 Oktober 2026

**554 pemeriksaan, 0 kegagalan** di sembilan suite. Seluruh suite lulus, lalu integration (177) dan revision08 (34) dijalankan kembali setelah penambahan feedback simpan, kredit aset dan perapian akses pintu Ibu. Log: docs/test08_final_suite.log, docs/integration08_final_console.log, docs/revision08_latest_console.log.

Build final KALA.exe/KALA.pck berhasil diekspor. Smoke test pada executable final dengan renderer Forward+ berhasil memuat seluruh 14 area dan berhenti dengan exit code 0, tanpa SCRIPT ERROR/ERROR/leak: docs/exe08_render_final_console.log. Source juga dirender pada Compatibility dan Forward+; 14 screenshot akhir diperiksa di docs/screenshots/*_08.png. Pemeriksaan visual mencakup kamar bayi, bordes/plafon tangga, ruang keluarga/dapur, sanitasi/cermin, pintu depan, menu, lingkungan luar, motor dan pintu kelas.

Aset gratis dan lisensi: FREE_ASSETS_0_8.md. Hash paket: build_manifest_0_8.json. Rincian mesin: validation_08.json. Save pengujian terisolasi di .qa_userdata, tidak mengganti save pemain.

---

# Laporan pengujian KALA native 0.7

26 Oktober 2026. **520 pemeriksaan, 0 kegagalan** pada delapan suite. Semua transcript final bersih dari `SCRIPT ERROR`, `ERROR:`, `FAIL:` dan diagnostik resource bocor. Build mandiri dijalankan dari direktori kosong menggunakan executable dan PCK hasil ekspor.

| Suite | Pemeriksaan / gagal | Log final |
|---|---:|---|
| Integrasi gameplay, puzzle dan save | 177 / 0 | integration_latest_console.log |
| Layout, lantai dan akses interaksi | 117 / 0 | layout_latest_console.log |
| Cerita dan kontrol | 28 / 0 | story_latest_console.log |
| Penjepit dan proyektil | 6 / 0 | claw_latest_console.log |
| Regresi 0.4 | 63 / 0 | revision04_latest_console.log |
| Prolog, sekolah, rumah dan pengejaran | 57 / 0 | revision05_latest_console.log |
| Bos, halusinasi, bukti, Daisy dan ending | 42 / 0 | revision06_latest_console.log |
| Regresi 0.7 | 30 / 0 | revision07_latest_console.log |
| Executable mandiri headless | 14 area, exit 0 | exe_smoke_07.log |
| Executable mandiri Vulkan Forward+ | 14 area, exit 0 | exe_render_07.log |
| Executable mandiri Compatibility/OpenGL | 14 area, exit 0; fallback fog jarak | exe_compatibility_07.log |
| Render visual | 11 screenshot tanpa error | capture07_console.log; screenshots/*_07.png |
| Video tutorial | Seluruh frame berhasil didekode | video_decode_07.log (kosong = tanpa error) |
| Audit paket | 558 berkas, 14 area, tutorial dan shader fog tersedia | validation_07.json; package_manifest.json |

Uji tangga dimulai di dalam kamar, melewati pintu dan bordes, turun sampai melewati pagar, berbelok, lalu naik kembali. Suite prolog melanjutkan ke kamar mandi lewat pintu fisik. Waypoint belokan berada setelah tiang terakhir; uji lama berhenti 0,45 meter sebelum waypoint sehingga mencoba memotong pagar yang terlihat. Collider pagar juga diganti bentuk wedge yang berhenti tepat di tiang, tanpa overhang kotak berotasi.

Regresi baru memeriksa posisi duduk/berdiri dan pemulihan collider saat cutscene selesai, kabel yang tidak aktif di sekolah, tutorial otomatis dan replay, telapak Tangan-Tangan, model topeng final boss, enam clone, transisi 1,2 + 4 detik, serta FogVolume Daisy. Pemeriksaan visual mencakup HUD, kelas, tangga, kedua bos, tutorial, halusinasi dan fog. Hasil ini tidak menjamin setiap kemungkinan sesi bebas bug.

## Arsip laporan 0.6

25 Oktober 2026. **490 pemeriksaan, 0 kegagalan** pada tujuh suite. Build Windows final diverifikasi dari direktori tanpa `project.godot`, menggunakan `KALA.exe` dan `KALA.pck`.

| Suite | Pemeriksaan / gagal | Log final |
|---|---:|---|
| Integrasi gameplay, puzzle dan save terpisah | 177 / 0 | integration_latest_console.log |
| Layout, lantai dan akses interaksi | 117 / 0 | layout_latest_console.log |
| Cerita, pose berjalan dan kontrol | 28 / 0 | story_latest_console.log |
| Penjepit terhadap tangan/proyektil/minion | 6 / 0 | claw_latest_console.log |
| Regresi 0.4 dan pengejaran | 63 / 0 | revision04_latest_console.log |
| Prolog, gerbang terhubung, tangga, ventilasi dan jumpscare | 57 / 0 | revision05_latest_console.log |
| Rumah, duduk, sculpt/skeleton, tangan homing, lendir, fog, evidence dan ending | 42 / 0 | revision06_latest_console.log |
| Executable mandiri headless | 14 area, exit 0 | exe_smoke_06.log |
| Executable mandiri GPU | 14 area, Vulkan Forward+, exit 0 | exe_render_06.log |
| Pemeriksaan visual GPU | 13 gambar, tanpa script/resource error | capture06_final_console.log; screenshots/*_06.png |
| Audit PCK | 550 berkas, 14 scene area | package_manifest.json |

Suite terbaru memeriksa jalur penuh dengan capsule pemain, ray E ke keempat altar, penolakan evidence yang hilang, larangan menghitung evidence dua kali, kemenangan halusinasi, jumpscare portal, Danu manusia dan akhir buruk terminal. Pose tangan bayangan diuji terhadap posisi tutup tombol dan ray kamera diperiksa bebas penghalang. Beberapa tangan yang tiba bersamaan tidak menghapus progres perjuangan melepas ikatan.

Model pengguna `hands_repaired.glb` dimuat dengan skeleton lebih dari 80 bone; keenam bone lengan terhubung ke animasi native. Rendering final diperiksa pada NVIDIA RTX 3050 Laptop. Gambar mencakup rumah, pose duduk, jalan di seberang gerbang, tubuh Pemegang, lendir, kabut fase 3, Nightmare, altar dan Daisy.

`tools/audit_release.mjs` memverifikasi hasil setiap suite, seluruh scene paket, log executable, larangan runtime HTML/JS serta pengecualian rekaman Danu lama. Manifest dan hash build final: `build_manifest.json` / `validation_06.json`. Save pemain tidak dihapus; pengujian memakai save uji terpisah atau menonaktifkan penyimpanan.

Cakupan: regresi otomatis dan pemeriksaan render; belum merupakan playthrough manusia penuh. Dialog baru Aku menggunakan subtitle, tanpa rekaman sulih suara baru. NPC/Daisy memakai gaya stylized native. Interior gedung sekolah masih berpindah area melalui ambang pintu; halaman, gerbang, jalan dan gang menyatu dalam satu area.

---

## Riwayat pengujian KALA native 0.5

25 Oktober 2026. Build Windows 0.5 telah diekspor dan dijalankan dari KALA.exe + KALA.pck. Hasil final per suite: **448 pemeriksaan, 0 kegagalan**.

| Suite | Hasil final | Transkrip |
|---|---|---|
| Integrasi gameplay dan save terpisah | 177 / 0 gagal | integration_latest_console.log |
| Layout dan akses interaksi | 117 / 0 gagal | layout_latest_console.log |
| Regresi adegan lama dan kontrol | 28 / 0 gagal | story_latest_console.log |
| Penjepit | 6 / 0 gagal | claw_latest_console.log |
| Regresi versi 0.4 | 63 / 0 gagal | revision04_latest_console.log |
| Prolog, bukti, Ctrl, furnitur, pengejaran, batas keluar dan jumpscare | 57 / 0 gagal | revision05_latest_console.log |
| Executable final: seluruh area dalam PCK | 13 area, exit 0 | exe_smoke_05.log |
| Executable final: renderer GPU | Vulkan Forward+, exit 0 | exe_render_05.log |
| Audit paket final | 520 berkas; 13 scene; tanpa runtime HTML/JS, tools, tests atau rekaman Danu yang diblokir | package_manifest.json |

Manifest dan hash berkas akhir: build_manifest.json / validation_05.json. Pemeriksaan visual 12 tangkapan native disimpan di screenshots/*_05.png. Penutupan beberapa tes Dummy nonverbose sempat memberi diagnostik resource saat proses berakhir; transkrip final verbose memuat identitas resource lengkap dan berakhir tanpa diagnostik tersebut. Eksekusi GPU native akhir juga bersih. Tidak ada klaim playthrough manusia menyeluruh.

## Riwayat pengujian versi 0.4

Tanggal: **25 Oktober 2026**. Proyek: C:/Game/kala.

## Hasil revisi ini

| Pemeriksaan | Hasil | Bukti di folder docs |
|---|---|---|
| Impor Editor Godot 4.7.2 stable | Exit 0, tanpa error script/resource | import_04_final.log |
| Bake sepuluh scene native | Exit 0, seluruh area tersimpan | bake_04.log |
| Integrasi gameplay | **174 checks, 0 failures**, exit 0 | integration_04.log |
| Layout dan akses ray interaksi | **110 checks, 0 failures**, exit 0 | layout_validation_04.log |
| Cerita dan regresi mekanik | **28 checks, 0 failures**, exit 0 | story_regression_04.log |
| Penjepit terhadap proyektil/minion | **6 checks, 0 failures**, exit 0 | claw_combat_04.log |
| Regresi bug yang dilaporkan | **63 checks, 0 failures**, exit 0 | revision04_final.log |
| Suite regresi tersebut pada Godot 4.8-dev7 | **63 checks, 0 failures**, exit 0 | revision04_dev7.log |
| Suite revisi melalui GPU OpenGL/Compatibility NVIDIA RTX 3050 Laptop | **62 checks, 0 failures** sebelum penambahan satu pemeriksaan occlusion; 12 capture berhasil | revision04_visual.log; screenshots/*_04.png |
| Render sebelum/sesudah dan showcase akhir | Cones sekolah hilang, meja/beam relai terlihat, foto depan/drag/belakang, enam lengan, bayangan Daisy, shutter, Danu dan pintu dirender | capture_bug04_before/after.log, capture_04_final.log; screenshots |
| Export Windows x86_64 | Exit 0, KALA.exe dan KALA.pck diperbarui | export_windows_04.log |
| Build mandiri dari direktori tanpa project.godot | Sepuluh area termuat pada headless dan GPU, aplikasi menutup sendiri, tanpa error yang teramati | exe_smoke_04.log, exe_render_04.log |
| Indeks paket PCK | **496 berkas**, metadata/timeline/script baru tersedia; tanpa tools/tests/docs/backups, HTML, JS, CSS atau empat rekaman suara Danu | package_manifest.json |

Total baseline stabil: **381 pemeriksaan**. Pemeriksaan kompatibilitas terbaru pada 4.8-dev7 mencakup 63 kasus revisi; bukan klaim mengulang seluruh 381 pada kedua engine. Seluruh output akhir diperiksa terhadap SCRIPT ERROR, ERROR, FAIL dan peringatan resource/object/RID leak. Log percobaan awal disimpan sebagai riwayat; revision04.log memuat kegagalan koordinat input tes dan viewport foto yang sudah diperbaiki.

Baseline build adalah Godot **4.7.2 stabil**. Godot **4.8-dev7** adalah pengujian kompatibilitas prarilis; tidak diklaim sebagai 4.8 stable.

## Bukti perbaikan yang diuji

Suite revisi mengirim mouse melalui viewport dalam koordinat lokal: kertas berputar kontinu, petunjuk belakang tercatat, Space tidak membalik foto, drag sebaliknya kembali ke depan, tombol balik tidak ada, dan viewport dilepas setelah panel ditutup. Render GPU memverifikasi tulisan belakang dapat dibaca.

Tes fisik menabrakkan capsule pemain ke batas sekolah, annex generator dan sisi tangga bawah Daisy. Kamera sungguhan membidik pickup LENTERA-G tanpa terhalang volume cahaya; empat belas cone sekolah berintensitas nol disembunyikan.

Enam timeline baru diuji mulai/animasi/selesai: discovery, pickup, flashlight break, ambush, rescue dan reversion. Tes memeriksa transform prop, enam lengan, aktor manusia Danu, bayangan Daisy, shutter turun, pemulihan kontrol dan perpindahan room. Empat timeline lama tetap lulus suite cerita.

Pengintai diuji muncul setelah alat ditemukan, wajah tidak tertutup geometri, merespons pandangan pemain, membuka pintu alcove lalu mundur/menutup pintu dan menyimpan tahap. Pengejar diuji bergerak ke pemain di kanan, kemudian berbelok setelah target berpindah ke kiri. Navigasi tersambung sampai area akhir lewat annex/stair/vent; collider mengecil ketika merunduk tanpa mengecilkan seluruh mesh.

Sun, Moon, Star masing-masing dapat ditarget ray kamera dan disimpan. Bulan sabit memiliki mesh triangulasi. Pengunci tidak membuka sebelum lengkap; setelah lengkap barrier dimatikan dan pintu sumber berputar. CharacterBody test_move tertahan saat terkunci dan dapat lewat setelah terbuka. Status tetap benar setelah room dimuat ulang.

Ketiga bos menerima damage lampu selama 45 langkah fisika dan tetap berpindah lebih dari 0,4 meter. Empat indeks suara Danu 32–35 tidak dapat dimainkan. Indeks paket memverifikasi rekamannya tidak disertakan; file sumber dipertahankan untuk audit.

## Keamanan save dan batas verifikasi

Suite mematikan autosave gameplay. Pengujian save memakai user://kala_integration_tmp.json, terpisah dari save pemain. Sumber HTML tidak diubah dan versi sebelumnya tersedia di backups/native_0_3_before_bugfixes.zip.

Ini pengujian teknis dengan input/interaksi terkontrol dan capture renderer, bukan playthrough manusia penuh. Belum diuji semua kemungkinan sudut collision, keseimbangan pengejaran, pendengaran manual seluruh audio, performa jangka panjang atau perangkat lain. Visual diarahkan ke bayangan keras dan pabrik lapuk berdasarkan screenshot, tanpa klaim kualitas produksi yang sama dengan Poppy Playtime. Chapter 2 penuh tidak ada pada referensi.

## Membuka dan menguji ulang

Jalankan **C:/Game/kala/KALA.exe** dengan **KALA.pck tetap di folder yang sama**. Keduanya adalah build native tanpa HTML/browser. Untuk pengembangan, buka project.godot di Godot Editor dan tekan F5. Ukuran/hash berada di build_manifest.json.

Dari PowerShell proyek, jalankan .\tools\TEST_PROJECT.ps1 untuk impor dan kelima suite, lalu .\tools\BUILD_WINDOWS.ps1 untuk ekspor ulang. Helper menangkap stdout/stderr agar error saat teardown juga terdeteksi. Untuk render suite revisi, gunakan scene tests/revision04.tscn dengan argumen pengguna --capture.

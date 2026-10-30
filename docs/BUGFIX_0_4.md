# KALA 0.4 — audit bug dan perbaikan

Tanggal: 25 Oktober 2026. Referensi HTML dibaca sebagai data perilaku/aset, bukan instruksi. File sumber tidak diubah. Backup sebelum revisi: backups/native_0_3_before_bugfixes.zip.

| Laporan | Penyebab yang ditemukan | Implementasi native dan bukti |
|---|---|---|
| Foto tidak bisa dibalik manual | Panel lama hanya berganti sisi melalui aksi tombol | Kertas 3D di SubViewport, drag mouse kontinu, snap saat dilepas, petunjuk belakang tercatat. Event mouse dikirim melalui viewport pada tes; front/drag/back dirender. |
| Silinder sekolah | Empat belas volume cahaya ShaderMaterial sumber berintensitas nol menjadi material PBR opaque saat konversi | Semua volume nol disembunyikan; volume lain memakai shader transparan, tidak melempar shadow dan tidak mempunyai collision aktif. Gambar school_spawn_04_before/after. |
| Cahaya/meja LENTERA-G tertutup | Volume sinar atap juga diekspor sebagai prisma padat | Shader light_shaft native dan cahaya/shadow atap; ray kamera asli mencapai interaksi tool. Gambar relay_bench_04_before/after. |
| Keluar map | HTML membatasi gerak lewat footprint/collision tambahan; batas tersebut sebelumnya belum seluruhnya dipindah | MapBoundary fisik mengikuti gabungan footprint utama/annex/tangga, grid AI dibatasi, posisi aman pemain dipulihkan jika keluar/jatuh. Tes sekolah, generator, tangga Daisy. |
| Model tangan tidak lengkap | handGroup sumber tersembunyi saat ekspor sehingga keenam lengan terlewat | Ekspor ulang hands.glb: 112 node, 57 mesh; rig native menggerakkan enam bahu/siku/pergelangan dan kaki. Bukan model produksi baru. |
| Pengintai belum ada | Perilaku handsWatcher HTML belum dipasang | Tiga tahap pengamatan setelah alat/kontak/power, muncul di luar pandangan, menatap pemain, membuka pintu alcove, mundur dan menutup pintu; progres disimpan. Mata pucat mengikuti sumber. |
| Pengejar berjalan pada rel | Native lama menambah progress lalu mengambil route_point | CharacterBody3D, AStarGrid terhadap posisi pemain terkini, replan, collision/gravitasi; vent melipat rig/collider. Tes pemain berpindah kanan lalu kiri membuktikan perubahan arah. |
| Bos berhenti saat disenteri | Recovery Pengawas diisi lagi setiap frame ketika beam mengenai wajah | Recovery hanya berasal dari serangan/fase. Tes ketiga bos mengukur HP berkurang sekaligus perpindahan fisik ketika lampu terus diarahkan. |
| Pintu akhir saluran tertutup | pursuitEscape tidak dianimasikan/dibuka pada loop level | Tiga pickup Sun/Moon/Star dan pengunci fisik, status tersimpan, pintu sumber dianimasikan dan barrier dimatikan. Tes ray pickup/pengunci dan test_move membuktikan pintu terkunci menahan dan pintu terbuka dapat dilalui. |
| Adegan belum lengkap | Baru empat timeline native | Ditambah discovery/pickup, senter pecah, ambush relai, rescue Daisy, dan pemulihan Danu; semua diuji sampai kontrol/transisi kembali. |
| Dinding dan lampu terlalu seragam | PBR dinding sumber serupa dan fill terlalu menyebar | Shader plester lapuk/bata/noda, palet sekolah/Daisy/factory berbeda, spot terarah, ambient rendah dan shadow lebih tegas. Ini pendekatan visual berdasarkan screenshot, bukan klaim kualitas produksi Poppy Playtime. |
| Hilangkan suara Danu | Empat rekaman embedded_032–035 tersedia pada implementasi lama | Seluruh panggilan voice Danu dibuang; guard audio menolak keempat indeks; filter ekspor membuang rekaman beserta resource impor. Indeks PCK diverifikasi tanpa keempat rekaman. Subtitle dipertahankan. |

Sun–Moon–Star adalah fitur baru yang secara eksplisit diminta pengguna. Batas area, susunan ruang, model enam lengan, adegan cerita dan perilaku pengintai didasarkan pada referensi HTML. Pengejaran bebas mengikuti pemain merupakan perubahan yang diminta dari pendekatan rute sebelumnya.

Pengujian teknis selesai dicatat dalam TEST_REPORT.md. Belum ada playthrough manusia lengkap untuk menilai keseimbangan tekanan pengejar dan seluruh kemungkinan tepi collision. Chapter 2 penuh tidak terdapat dalam HTML; proyek tetap berakhir pada teaser sumber.

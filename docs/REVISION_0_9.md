# KALA 0.9 — perbaikan rumah, kampus, pabrik dan Lentera-G

Selesai 27 Oktober 2026. Jalankan ulang `KALA.exe`, dengan `KALA.pck` berada di sampingnya. Sumber tetap proyek Godot yang sudah ada. Build 0.8 tersimpan di `backups/revision09_before/build`.

Checkpoint lama tetap menyimpan progres, bukti dan barang. Pada area rumah/kampus yang berubah, posisi checkpoint versi lama dikembalikan ke spawn aman agar tidak berada di dalam dinding baru.

## Audit awal

Lentera-G memakai SpotLight, ray pandang, panas/cooldown bersama, dan penjepit R untuk tuas, benda serta serangan tertentu. Sorotan utama memberi damage terus-menerus. AI sudah memiliki pathfinding, dash, pemulihan, pencarian lokasi terakhir, dan fase boss. Perubahan mengintegrasikan respons baru ke state/timer tersebut tanpa menambah sistem energi kedua atau mengubah fase boss.

Bug rumah berasal dari plafon luar yang terlalu pendek, anak tangga terakhir yang tepat sejajar lantai, bingkai di dinding kamar bayi yang menimpa bukaan, serta finishing dan strip servis yang tidak menyatu. Eksterior sekolah menutup akses interior dengan bidang gelap; beberapa massa rumah melintasi gang.

## Cakupan permintaan gambar

| Referensi | Perubahan |
|---|---|
| 1 | Bingkai kamar bayi dipindahkan ke bidang dinding di sisi pintu. Bukaan diuji bebas dari mesh furnitur/dekorasi. |
| 2 dan 5 | Radio Quaternius, pot Zsky dan bunga daisy Zsky menggantikan bentuk lama. Tanaman bawaan pot dihapus; batang daisy berada dalam tanah, pot tepat pada permukaan meja. |
| 3 | Satu atap solid menutup seluruh rumah, termasuk ujung tangga yang dahulu memperlihatkan langit. Skylight relai pabrik tetap bagian cerita. |
| 4 | Sesuai klarifikasi pengguna, material dinding rumah disamakan pada inti servis dan dinding kamar. |
| 6 | Anak tangga terakhir yang coplanar dengan ubin dihapus; ramp collision tersembunyi dan anak tangga fisik lainnya dipertahankan. |
| 7 | Ibu memakai Animated Woman gratis dengan animasi idle asli aset, rambut/pakaian disesuaikan, dan dialog tersendiri. Cermin tetap realtime. |
| 8 | Strip kosong di antara kamar mandi dan kulit luar rumah ditutup dengan volume solid. |
| 9 | Tembok gang diturunkan ke skala lingkungan, ujungnya berhenti di trotoar, ditambah kolom dan penutup atas. |
| 10 | Rumah yang memotong footprint gang dihilangkan. Jalur lengkap diuji dengan pergerakan pemain. |
| 11 | Sayap sekolah memiliki fondasi menapak tanah; halaman memakai paving berpola dan lapangan berlapis, bukan bidang tanah default. |
| 12 | Nature Kit mengganti pohon lama, termasuk pohon jalan. Hutan mengisi sisi dan belakang sekolah; material daun/batang disesuaikan. |
| 13 | Interior dan halaman tinggal di memori bersama. Ambang pintu bisa dilalui tanpa scene dibongkar/muat ulang. Koordinat direbase agar save, NPC dan adegan lama tetap valid. |
| 14 | Lampiran 14 sama dengan gambar tangga. Warung di area Jalan Kartini tetap dikerjakan: counter, rak stok, lemari dingin, alat kopi, kursi, papan harga dan buku utang yang dapat diperiksa. |
| 15 | Panel dan papan PENERANGAN dipasang ulang di depan bidang dinding, sehingga teks tidak terpotong. |
| 16 | Kabel 3D dapat ditarik dari terminal kiri ke terminal kanan dengan mouse. Label M/K/B melengkapi warna; sambungan tersimpan ketika panel ditutup. |
| 17 | Catatan memakai kertas lapuk, tepi tak rata, bekas lipatan dan font Caveat. Teks asli KALA dapat digulir dan dipilih; gambar referensi tidak disalin. |

Bangsal muat, relai, produksi, kantor, ruang ritual, koridor, ruang Daisy dan jalur pengejaran memperoleh susunan properti industri/dekorasi baru. Conveyor dan mesin membentuk pulau kerja; jalur inspeksi diberi marka, pipa dan rangka mengisi ruang vertikal. Ruang tambahan memakai perlengkapan sesuai fungsinya. Collision mesin baru masuk ke A* agar musuh dapat menghindarinya. Denah cerita, item wajib, pintu, boss dan ending tetap terhubung.

## Interaksi dan kontrol

- **F:** animasi mengangkat/menurunkan senter; Lentera-G ditahan lebih rendah ketika lampu mati agar penjepit masih dapat digunakan.
- **Reveal:** tanda inspeksi muncul bertahap saat disorot dekat dan tanpa penghalang. Pengawas dan Tangan-Tangan memperlihatkan penanda setelah terpapar. Simbol relai lama juga memeriksa jarak dan penghalang.
- **Disrupt:** sorotan Lentera-G memutus efek tatapan Pengawas setelah paparan; Tangan-Tangan melambat sebentar lalu melawan sorotan yang terlalu lama. Pengejar tetap bergerak dengan perlambatan terbatas. Efek memakai timer yang berakhir otomatis.
- **Q / Pulse:** kerucut depan sejauh 10 m, jeda 6 detik, menambah panas 0,26. Dinding dan arah bidik membatasi efek. Lama gangguan berbeda per musuh. Pemegang yang masih terlindungi tidak dilewati mekanik shield-nya.
- **R:** penjepit, jangkar, pelepasan cengkeraman dan interaksi tool lama tetap digunakan.
- **Puzzle kabel:** tahan ujung kabel kiri, tarik ke terminal kanan dengan label sama, lepas. Urutan catu M → K → B sesuai petunjuk. Terminal salah tidak dianggap tersambung.
- **Dialog:** teks bertahap per bagian; E melengkapi teks atau melanjutkan, Esc menutup. Semua dialog empat siswa dan Ibu direvisi; 61 baris pada 14 adegan diperbarui tanpa mengubah durasi/flag pemicu.

## File berubah

Daftar berkas sumber yang dimodifikasi/ditambahkan ada di `change_manifest_0_9.json`. Kelompok utama:

- `chapter_world.gd`, `home_detail.gd`, `free_assets.gd`, `school_detail.gd`, `street_connection.gd`, `neighborhood_backdrop.gd`: perbaikan bangunan, penempatan dan aset.
- `continuous_campus.gd`, `factory_overhaul.gd`, `world_detail.gd`, `main.gd`, `chapter_flow.gd`: sambungan kampus, pabrik dan alur permainan.
- `player.gd`, `enemy.gd`, `audio.gd`: animasi alat, reveal, disrupt, pulse dan suara.
- `hud.gd`, `field_note.gd`, `dialogue_card.gd`, `wiring_board.gd`, `lentera_tutorial.gd`: catatan, dialog dan kabel.
- `story.json`, `cinematics.json`, `walkable_bounds.json`, dua shader material baru, font dan aset vendor.
- Pengujian `revision09`, `capture09`, penyesuaian tes ibu lama di `revision06`, serta `TEST_PROJECT.ps1`.

## Pengujian

Godot 4.7.2. Hasil rinci beserta jalur log ada di `validation_09.json`.

| Suite | Pemeriksaan | Gagal |
|---|---:|---:|
| Integration | 177 | 0 |
| Layout | 118 | 0 |
| Story | 28 | 0 |
| Claw | 6 | 0 |
| Revision 04 | 63 | 0 |
| Revision 05 | 57 | 0 |
| Revision 06 | 42 | 0 |
| Revision 07 | 30 | 0 |
| Revision 08 | 34 | 0 |
| Revision 09 | 34 | 0 |
| **Total** | **589** | **0** |

Tes baru meliputi atap, bukaan pintu, kontak meja-pot, jalan masuk dan keluar kampus tanpa mengganti instance, seluruh gang, input mouse drag kabel, penyimpanan sambungan, catatan, dialog, animasi alat, pulse tidak bisa spam, batas jarak/kerucut, dinding sebagai penghalang, serta musuh kembali mengejar setelah gangguan selesai. Tes lama yang mengasumsikan ibu adalah model prosedural duduk diperbarui untuk menguji model unduhan dengan animasi yang benar-benar berjalan.

Render Forward+ / Vulkan pada RTX 3050 menghasilkan 24 gambar di `screenshots/*_09.png`. Compatibility juga dipakai pada pemeriksaan visual awal. Capture akhir tidak melaporkan error script, shader atau polygon. Pengujian paket Windows dicatat pada manifest build.

## Batas hasil

Aset tetap bergaya low poly. Hutan di luar pagar merupakan latar. Animasi alat dibuat di Godot; tidak memakai model atau animasi Poppy Playtime. Penataan pabrik mengubah prop, zona kerja, material dan pencahayaan sambil mempertahankan denah utama dan sambungan cerita. Validasi mencakup otomatisasi gameplay/cerita dan gambar render; satu playthrough manual penuh seluruh ending belum dilakukan pada paket Windows.

Sumber dan lisensi: `FREE_ASSETS_0_9.md`, `assets/vendor/licenses.json`, dan `THIRD_PARTY_NOTICES.txt`.

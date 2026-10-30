import fs from 'node:fs';
const read = path => JSON.parse(fs.readFileSync(path,'utf8').replace(/^\uFEFF/,''));
const write = (path, data) => fs.writeFileSync(path, JSON.stringify(data,null,2)+'\n');
const bounds = read('assets/walkable_bounds.json');
const rect = (x,z,w,d,y=0,h=4) => ({x,z,w,d,y,h});
bounds.home = {rects:[rect(-9,-8,18,22,0,7)],blockers:[]};
bounds.schoolyard = {rects:[rect(-22,-16,44,40,0,8)],blockers:[]};
bounds.neighborhood = {rects:[rect(-29,-10,58,24,0,7),rect(19,-36,4,30,0,6)],blockers:[]};
bounds.school.rects = [rect(-2,-30.4,4,60.4,0,3.2),rect(-14,-24,12.2,8,0,3.2),rect(-14,6,12.2,8,0,3.2),rect(1.8,-18,10.2,8,0,3.2),rect(1.8,9,10.2,8,0,3.2)];
write('assets/walkable_bounds.json',bounds);
const clips = read('assets/cinematics.json');
clips.wash = {room:'home',flag:'homeReady',steps:[['Air hangat mengusir sisa kantuk. Di sela bunyi pancuran, radio menyebut nama Kartini sekali lagi.',4],['Beberapa menit kemudian. Seragam rapi, buku masuk tas. Ibu sudah tidak memanggil dari kamarnya.',4]]};
clips.wake_home = {room:'home',flag:'homeAwake',steps:[
['06.12. Radio menyala sebelum alarm. Selama beberapa detik, kau lupa hari apa ini.',4],
['IBU, dari bawah: “Sudah bangun? Airnya masih hangat. Jangan terlambat lagi.”',4],
['Di meja, bunga daisy baru menggantikan yang layu. Ibu selalu menggantinya tanpa membangunkanmu.',4],
['Bangun. Turun tangga, belok kanan ke kamar mandi, lalu berangkat sekolah.',4]]};
clips.lesson = {room:'school',flag:'lessonSeen',steps:[
['BU RATNA: “Dalam sebuah kesaksian, bedakan apa yang dilihat dengan apa yang disimpulkan.”',5],
['BU RATNA: “Satu foto bisa benar, tetapi cerita yang dilekatkan padanya bisa salah.”',5],
['PAK ARIF, dari pintu: “Bu Ratna, ada telepon dari kepala sekolah. Sebentar saja.”',4],
['BU RATNA: “Lanjutkan soal kedua. Saya segera kembali.” Pintu menutup. Semua suara pensil berhenti.',4],
['RAKA mencengkeram kerah Danu: “Kembalikan. Jangan sebut nama adikku lagi.”',5],
['SARI berdiri di antara mereka: “Lepaskan dia, Rak! Setiap hari kamu begini!”',4],
['ADIT: “Rak, mundur. Kalau ada masalah, bilang. Jangan pakai tangan.”',4],
['Satu kelas melihat. Kursi bergeser, tetapi tak seorang pun ikut berdiri. Danu memandangmu, bukan Raka.',5],
['DANU: “Aku cuma mau dia ingat janji kita.” Raka melepaskan kerahnya seperti tersengat.',4],
['Mengapa Raka selalu menyerang Danu? Dan janji apa yang membuatnya begitu takut?',4],
['BEL ISTIRAHAT. Cari dua bukti di kelas, perpustakaan, laboratorium, halaman dan dekat gerbang. Dengarkan kedua pihak.',6]]};
clips.return_class = {room:'school',flag:'schoolDismissed',steps:[
['Kau kembali ke kelas. Danu duduk rapi, seolah tak ada yang terjadi. Kursi Raka kosong.',4],
['BU RATNA: “Besok kita bahas jawaban kalian. Ingat: menunda kesimpulan juga sebuah keberanian.”',5],
['13.40. Hujan yang dijanjikan radio tak kunjung turun. Bel pulang berbunyi panjang.',4],
['SARI: “Kalau Danu mengajakmu ke Kartini, kabari aku dulu.” Ia menyelipkan nomor telepon ke agendamu.',5],
['DANU, berbisik: “Keluar gerbang. Belok kanan, masuk gang sempit. Aku tunggu dekat gudang.”',5],
['Rumahmu ada di sebelah kiri. Hari ini, kau memilih arah yang lain.',4]]};
write('assets/cinematics.json',clips);
const story = read('assets/story.json');
story.evidence.op1.title='FOTO DARI TONG SAMPAH / SEHARI SEBELUM KEJADIAN';
story.evidence.op1.body='Foto ini ditemukan terlipat di bawah kertas piket dekat gerbang. Danu dan Raka berdiri berdampingan di depan Gudang Kartini. Raka memegang kotak kecil; tangan Danu berada di bahunya. Keduanya tampak akrab. Tanggal di sudut foto: kemarin.\n\nKalau mereka sudah lama bermusuhan, mengapa mereka datang bersama? Seseorang sengaja membuang bagian yang memuat wajah anak ketiga. Balik kertasnya; ada dua angka yang ditulis terburu-buru.';
story.evidence.op2.title='AGENDA SARI / DUA WAKTU YANG BERBEDA';
story.evidence.op2.body='07.05 — Danu sudah di sekolah. Meminta izin meminjam kamera kelas.\n07.20 — Raka datang dari arah Kartini, bukan arah rumahnya. Seragamnya berdebu.\n07.24 — Danu bilang ia baru pertama kali melihat Raka hari itu.\n\nSari menggarisbawahi dua waktu itu: “Aku ingin percaya Danu. Tapi aku juga ingin dia pulang dengan selamat. Dua hal itu seharusnya tidak bertentangan.”';
story.dialogues.Danu.before='“Raka memang begitu.” Danu mengusap kerahnya, tetapi tak ada luka di tempat yang ia tunjuk. “Kamu tadi lihat sendiri, kan?”\n\nIa tidak menjawab ketika kau menanyakan janji. “Jangan tanya Raka. Kalau kamu mau membantu, cari dulu yang dia sembunyikan. Foto kami mungkin masih ada dekat gerbang.”';
story.dialogues.Danu.after='Danu membaca bukti itu lebih lama daripada yang diperlukan.\n\n“Foto kemarin? Kami dulu teman. Itu tidak berarti dia tak bisa menyakitiku sekarang.” Ia menurunkan suara. “Jangan cerita ke Bu Ratna dulu. Kembali ke kelas. Setelah pulang, keluar gerbang dan belok kanan. Gang sempit menuju Gudang Kartini. Aku bisa menjelaskan semuanya di sana.”\n\nIa tahu kau akan datang jika merasa seseorang membutuhkanmu.';
story.dialogues.Raka.before='“Kamu lihat aku mendorongnya.” Raka menatap lantai. “Itu salah. Aku tahu.”\n\nKau menanyakan kenapa. Ia hampir menjawab, lalu melihat Danu di ujung koridor. “Tanya siapa yang mengambil fotonya. Dan jangan sekali pun menulis nama keluargamu di kertas yang dia berikan.”';
story.dialogues.Raka.after='Raka pucat ketika membaca surat dari lokernya. “Aku tidak pernah meminta dia mengajak orang lain. Aku cuma ingin adikku pulang.”\n\nTangannya gemetar. “Kalau kamu tetap ke sana, bawa bukti itu. Jangan tinggalkan namamu. Mesin itu tidak bisa membedakan janji dengan tanda tangan.”';
story.notes.gate_log={title:'PIKET GERBANG / 07.20',body:'Raka datang tanpa tas. Danu sudah berada di dalam sejak 07.05. Penjaga melihat sebuah mobil bak tua berhenti di seberang jalan sebelum bel pertama. Di pintunya masih terbaca bekas tulisan: KARTINI.\n\nAda bekas sobekan foto tersangkut di bibir tong sampah sebelah timur halaman.'};
story.notes.home_radio={title:'RADIO PAGI / PENGUMUMAN',body:'“...keluarga diminta melapor bila menerima surat atas nama bekas Pabrik Kartini. Kompleks itu ditutup sejak insiden kebakaran...”\n\nIbu mematikan suara dari bawah. “Berita lama. Sarapanmu di meja.”'};
story.notes.home_daisy={title:'BUNGA DI MEJA',body:'Ibu pernah bilang daisy tumbuh menghadap cahaya, bukan menghindari gelap. Pada kartu kecil tertulis: “Kalau takut, lihat baik-baik. Jangan biarkan orang lain memilih apa yang kamu lihat.”\n\nTulisan tangan Ibu berbeda dari tulisan pada kartu. Kau baru menyadarinya sekarang.'};
story.notes.nursery={title:'KAMAR YANG BELUM DIPAKAI',body:'Cat baru, kardus pakaian kecil, ranjang bayi masih terbungkus. Di daftar belanja Ibu, sebuah nama dicoret sampai tak terbaca. Di bawahnya: “Jangan pilih nama sebelum semuanya aman.”\n\nMungkin ia cuma khawatir. Itulah penjelasan yang paling mudah.'};
story.notes.service_clue={title:'CATATAN TEKNISI / TIGA SHIFT',body:'SUN: mulainya shift, tempat operator menyimpan kuitansi.\nMOON: istirahat malam, di balik pintu loker yang penyok.\nSTAR: ketika lampu mati, simpan di lemari perkakas terakhir.\n\nBuka furniturnya dengan E. Jongkok dengan Ctrl untuk melihat bagian bawah. Rem bisa dipakai kembali setelah pulih. Makhluk mengikuti bunyi langkah; putus pandang dan jangan berlari saat bersembunyi.'};
write('assets/story.json',story);
const source=fs.readFileSync('C:/Users/alama/Downloads/Kala_Chapter_1_Tiga_Fase (6).html','utf8');
const sanitized=source.replace(/data:[^;\s"']+;base64,[A-Za-z0-9+/=]+/g,'[EMBEDDED]');
const matches=[...sanitized.matchAll(/.{0,80}(?:jumpscare|jump.?scare|scare|deathScene|deathCine|loseGame|gameOver).{0,180}/gi)].slice(-20).map(x=>x[0]);
fs.writeFileSync('docs/reference_scares_05.txt',matches.join('\n'));
console.log('Updated bounds, prologue timelines and narrative. Scare references:',matches.length);

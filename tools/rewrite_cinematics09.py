"""Update prose without changing story flags, camera timing or clip structure."""
import json
from pathlib import Path

updates = {
    "intro": [
        "Pensil masih berserakan ketika keributan pindah ke koridor.",
        "RAKA: “Kau bilang kemarin yang terakhir.”",
        "SARI: “Rak, tangannya lepas dulu. Kita bisa bicara.”",
        "ADIT: “Aku nggak lihat awalnya. Ada yang mau jelasin?”",
        "Danu melihat ke kelas. Pandangannya berhenti padamu.",
        "SARI: “Ada surat di lokernya. Baca sebelum menyimpulkan.”",
        "DANU: “Aku baik-baik saja.” Ia merapikan kerah yang tidak robek.",
    ],
    "warehouse": [
        "Satu per satu lampu gang berdengung. Danu berdiri di bawah nomor gudang.",
        "DANU: “Di dalam ada jawaban yang tidak bisa kubawa ke sekolah.”",
        "Engsel berderit. Danu membuka kedua daun pintu, lalu menoleh memastikan kau mengikuti.",
        "Suara langkahnya tertelan tumpukan peti. Pintu tetap terbuka.",
    ],
    "office": [
        "Sepatu berhenti di ambang. Danu memandang album yang terbuka.",
        "DANU: “Aku cuma perlu satu orang yang percaya. Kenapa kau membaca sisanya?”",
        "Ia mundur menuju ruang ritual. Di baliknya terdengar rantai ditarik.",
    ],
    "corridor": [
        "Danu melewati pintu servis. Kau mengejar bunyi langkahnya.",
        "AKU: “Danu, tunggu. Siapa yang ada di album itu?”",
        "Ia menoleh, melihat jarak kalian, lalu berlari lebih cepat.",
        "Cahaya luar tinggal selebar daun pintu. Danu sudah di seberang.",
        "DANU: “Jangan bawa dia pulang.” Kunci berputar sebelum kau sempat menjawab.",
    ],
    "discovery": [
        "Cahaya jatuh dari atap yang runtuh, tepat di atas meja inspeksi.",
        "Di bawah debu terbaca LENTERA-G. Kabelnya masih tergulung rapat.",
    ],
    "pickup": ["Gagangnya berat. Di sisi gulungan tertulis: INSPEKSI • TARIK • EVAKUASI."],
    "flash_break": [
        "Pengawas ambruk. Kartu di balik seragam kosong itu memuat tanggal lahir Danu.",
        "Tabung senter terasa panas. Retak putih merambat dari kacanya; kau menjatuhkannya.",
        "Kaca pecah di lantai. Dari ruang relai terdengar kabel ditarik pelan.",
        "DANU, dari pengeras suara: “Dulu dia menjaga pintuku. Sekarang kau berdiri di tempatku.”",
    ],
    "ambush": [
        "Bunyi gulungan berhenti. Sesuatu membuka enam telapak di belakangmu.",
        "Rak besi melengkung ketika kau menunduk dan berbalik lari.",
        "Pintu servis terbuka. Kau menerobos, menuruni anak tangga, dan mendengar benturan yang sama di belakang.",
    ],
    "rescue": [
        "Lututmu menghantam lantai. Langkah pengejar berhenti tepat di belakang.",
        "Sesuatu mencengkeram dan menarikmu. Ujung jarimu gagal meraih ambang.",
        "Bayangan kecil muncul pada dinding. Ia bergerak berlawanan dengan cahaya.",
        "Satu tangan terangkat. Tombol pengaman tenggelam ke rumahnya.",
        "Shutter jatuh memutus cengkeraman. Bunyi besinya terus menggema saat pandanganmu gelap.",
    ],
    "reversion": [
        "Besi Pemegang merekah dari dalam. Bayangannya menyusut di sela debu.",
        "Danu terjatuh dengan kedua tangan menutupi telinga. Seragam sekolahnya masih sama.",
        "DANU: “Sudah kuganti namanya. Kenapa dia tetap tahu namaku?” Ia menatap tangga servis.",
        "Danu bangkit dan turun. Kali ini langkahnya terdengar seperti langkah anak biasa.",
    ],
    "wake_home": [
        "06.12. Suara radio mendahului alarm. Bau teh datang dari bawah.",
        "IBU: “Airnya masih hangat. Tasmu jangan ketinggalan.”",
        "Daisy baru ada di meja. Tanah di pot masih gelap setelah disiram.",
        "Ada suara cangkir diletakkan. Kau bangkit menuju kamar mandi di bawah.",
    ],
    "lesson": [
        "BU RATNA: “Tulis dua kolom: yang kalian lihat, dan yang kalian duga.”",
        "BU RATNA: “Foto menyimpan satu detik. Siapa yang menceritakan detik sebelum dan sesudahnya?”",
        "PAK ARIF: “Bu, kepala sekolah menunggu di telepon.”",
        "BU RATNA: “Kerjakan nomor dua. Saya kembali sebentar lagi.” Pintu menutup.",
        "RAKA: “Kembalikan itu. Adikku tidak ada urusannya.” Ia mencengkeram kerah Danu.",
        "SARI: “Raka, lepas! Tangannya dulu!”",
        "ADIT: “Mundur, Rak. Kita dengarkan satu-satu.”",
        "Kursi berdecit. Danu melihatmu di antara bahu teman-teman yang duduk.",
        "DANU: “Dia yang berjanji.” Tangan Raka mengendur sebelum Danu selesai bicara.",
        "Kertas tugasmu masih memuat dua kolom kosong. Kau belum tahu apa yang harus ditulis.",
        "Bel istirahat. Ada surat, foto, dan orang-orang yang belum selesai bicara.",
    ],
    "return_class": [
        "Danu sudah kembali duduk. Kursi Raka dibiarkan menjorok dari mejanya.",
        "BU RATNA: “Besok kita lanjutkan. Jawaban yang baik boleh dimulai dengan ‘saya belum tahu’.”",
        "13.40. Bel pulang memotong bunyi kipas. Hujan yang disebut radio belum datang.",
        "SARI: “Kalau jadi ke Kartini, kabari aku.” Ia menyelipkan nomor di agendamu.",
        "DANU: “Keluar gerbang, kanan. Ada gang sebelum deretan rumah. Aku tunggu di gudang.”",
        "Di luar, jalan ke rumah membelok ke kiri. Kau memeriksa lagi alamat di foto.",
    ],
    "wash": [
        "Air menutupi suara radio. Sesaat kau masih mendengar kata “Kartini” dari luar kamar mandi.",
        "Seragam selesai dikancingkan. Buku dan agenda masuk tas. Saatnya menuju pintu depan.",
    ],
}

path = Path(__file__).resolve().parents[1] / "assets/cinematics.json"
clips = json.loads(path.read_text(encoding="utf-8-sig"))
for key, prose in updates.items():
    assert len(clips[key]["steps"]) == len(prose), key
    for row, line in zip(clips[key]["steps"], prose):
        row[0] = line
path.write_text(json.dumps(clips, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Updated {sum(map(len, updates.values()))} lines across {len(updates)} clips; timings preserved.")

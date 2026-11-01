extends RefCounted
## Ready-to-play story entry points. Templates never mutate the current game.
const SECTIONS = [
	["home", "home", "RUMAH / PAGI", "Bangun dan bersiap", "Jelajahi rumah, temui Ibu, lalu bersiap ke sekolah."],
	["schoolyard", "schoolyard", "HALAMAN SEKOLAH", "Sebelum bel masuk", "Masuk ke sekolah dan ikuti pelajaran pertama."],
	["school", "school", "SEKOLAH", "Selidiki kejadian di kelas", "Pelajaran selesai. Cari kesaksian, foto dan agenda Sari."],
	["street", "street", "JALAN KARTINI", "Pulihkan penerangan gang", "Bukti sekolah tersedia. Periksa warung dan puzzle kabel."],
	["loading", "loading", "BANGSAL MUAT", "Aktifkan panel bangsal", "Cari kunci dan sekering operator sebelum menghadapi Pengawas."],
	["overseer", "loading", "SI PENGAWAS", "Hadapi Pengawas", "Panel sudah aktif. Pertarungan dimulai dengan senter lama."],
	["inspection", "loading", "GALERI & POS PENGAWAS", "Pulihkan jalur inspeksi", "Pengawas dikalahkan. Cari sekering, atur tekanan dan terminal daya."],
	["relay", "relay", "RUMAH RELAI", "Temukan Lentera-G", "Jalur inspeksi terbuka. Ambil alat di bawah atap kaca."],
	["relay_tools", "relay", "GENERATOR & R-17", "Aktifkan tiga relai", "Lentera-G tersedia. Perbaiki generator, pasang R-17 dan buka arsip."],
	["memory", "relay", "GEMA ARSIP / B1", "Uji memori CRT", "Relai dan arsip aktif. Tiga ronde memori dimulai dari awal."],
	["pursuit", "pursuit", "JALUR PEMELIHARAAN", "Lari dari Tangan-Tangan", "Lentera-G siap. Cari Sun, Moon dan Star untuk membuka jalur servis."],
	["production", "production", "RUANG PRODUKSI", "Pulihkan sistem tekanan", "Pengejaran selesai. Jelajahi bengkel dan cari roda katup."],
	["hands", "production", "TANGAN-TANGAN", "Putuskan cengkeramannya", "Katup sudah aktif. Hadapi Tangan-Tangan dengan Lentera-G."],
	["office", "office", "KANTOR DANU", "Telusuri rekaman audit", "Tangan-Tangan dikalahkan. Cari album, pita dan urutan saklar."],
	["ritual", "ritual", "RUANG RITUAL", "Hadapi Pemegang", "Audit selesai dan empat bukti tersedia. Tiga fase pertarungan."],
	["hallucination", "hallucination", "EMPAT INGATAN", "Lolos dari halusinasi", "Empat bukti dan Lentera-G tersedia. Aktifkan keempat altar."],
	["corridor", "corridor", "LORONG BELAKANG", "Kejar Danu", "Pemegang dikalahkan. Ikuti Danu menuju pintu keluar."],
	["daisy", "daisy", "RUANG DAISY", "Tiga ketukan terakhir", "Pintu D-08 terbuka. Jelajahi bagian akhir Chapter 1."]
]

static func entries() -> Array:
	var result: Array = []
	for i in range(SECTIONS.size()):
		var spec: Array = SECTIONS[i]
		result.append({"id": spec[0], "room": spec[1], "title": spec[2], "objective": spec[3], "description": spec[4], "number": i + 1})
	return result

static func snapshot(state: Node, id: String) -> Dictionary:
	var stage = -1
	for i in range(SECTIONS.size()):
		if SECTIONS[i][0] == id: stage = i; break
	if stage < 0: return {}
	var value: Dictionary = state.fresh_data()
	value.room = SECTIONS[stage][1]; value.layout_revision = state.LAYOUT_REVISION
	value.section_id = id; value.checkpoint_title = SECTIONS[stage][3]
	var flags: Dictionary = value.flags
	flags.prologueVersion = true
	if stage >= 1: flags.merge({"homeAwake": true, "homeReady": true})
	if stage >= 2: flags.merge({"lessonSeen": true, "introSeen": true})
	if stage >= 3:
		flags.merge({"invited": true, "schoolDismissed": true, "choseRight": true, "photoBackSeen": true})
		value.evidence = {"op1": true, "op2": true, "A": true}
		value.puzzles.locker.solved = true
	if stage >= 4:
		value.puzzles.fuse.solved = true; flags.warehouseEntrySeen = true
	if stage >= 5:
		value.puzzles.panel.solved = true; value.installed.panelFuse = true
	if stage >= 6:
		flags.merge({"overseerDefeated": true, "oldFlashBroken": true, "flashBreakComplete": true})
		value.position = [0.0, 0.05, -23.0, 0.0, 0.0]
	if stage >= 7:
		flags.merge({"inspectionFuseHeld": true, "inspectionFuseInstalled": true, "inspectionPressure": true, "inspectionPower": true})
		value.position = []
	if stage >= 8:
		flags.merge({"lenteraOwned": true, "lenteraDiscoverySeen": true, "lenteraPickupSeen": true, "lenteraGuideSeen": true})
	if stage >= 9:
		flags.merge({"relayPower": true, "relaySolved": true, "archiveOpen": true})
		value.installed.generatorContact = true; value.rotors = [2, 1, 3]
		value.position = [-8.0, -3.80, 40.5, 0.0, 0.0]
	if stage >= 10:
		flags.merge({"memorySolved": true, "memoryRound0": true, "memoryRound1": true, "memoryRound2": true, "handsAmbushRunSeen": true, "handsPursuitStarted": true})
		value.position = []
	if stage >= 11:
		flags.merge({"handsPursuitComplete": true, "daisyShadowRescueSeen": true, "daisyRescueButtonPressed": true, "escapePuzzleSolved": true, "ventGrateOpen": true})
		for piece in ["sun", "moon", "star"]: value.items["fragment_" + piece] = true
	if stage >= 12:
		value.puzzles.valve.solved = true; value.installed.valveWheel = true
	if stage >= 13: flags.handsDefeated = true
	if stage >= 14:
		flags.merge({"auditVerified": true, "officeExitSeen": true})
		value.evidence.B = true; value.installed.tapeReel = true; value.puzzles.breaker.solved = true
	if stage >= 16: flags.merge({"tumbalDefeated": true, "danuHumanReturned": true, "danuDescended": true})
	if stage >= 17: flags.merge({"exitLocked": true, "danuChaseSeen": true})
	return value

static func title_for(value: Dictionary) -> String:
	for spec in SECTIONS:
		if spec[1] == value.room: return spec[2]
	return "CHECKPOINT"

static func objective_for(value: Dictionary) -> String:
	var text = str(value.get("checkpoint_title", ""))
	if not text.is_empty(): return text
	for spec in SECTIONS:
		if spec[1] == value.room: return spec[3]
	return "Lanjutkan permainan"

static func playtime(seconds: float) -> String:
	var total = maxi(0, int(seconds))
	return "%02d:%02d:%02d" % [total / 3600, total / 60 % 60, total % 60]

static func date_label(timestamp: float) -> String:
	if timestamp <= 0: return "Simpanan sebelumnya"
	var local_time = Time.get_datetime_dict_from_unix_time(int(timestamp) + int(Time.get_time_zone_from_system().bias) * 60)
	return "%02d/%02d/%04d  %02d:%02d" % [local_time.day, local_time.month, local_time.year, local_time.hour, local_time.minute]

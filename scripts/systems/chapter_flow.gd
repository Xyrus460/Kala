extends RefCounted

var host: Node3D
var travel_spawn = ""

func interact(id: String) -> void:
	var ui = host.ui
	if id.begins_with("campus_"):
		preload("res://scripts/systems/school_puzzles.gd").interact(host,id)
		host._save(); return
	match id:
		"leave_home":
			if not State.flag("homeReady"): ui.notify("Kamar mandi ada di kanan setelah turun tangga. Bersiap dulu sebelum berangkat.", 6)
			else: host._travel("schoolyard")
		"wash":
			if State.flag("homeReady"): ui.notify("Seragam sudah rapi. Tasmu sudah dibawa. Saatnya berangkat.")
			else: host.narrative.start("wash")
		"radio": host._note("home_radio")
		"daisy_home": host._note("home_daisy")
		"nursery_note": host._note("nursery")
		"school_gate":
			if State.flag("schoolDismissed"): ui.notify("Gerbang terbuka ke Jalan Kartini. Belok kanan di trotoar, lalu ikuti gang menuju gudang.", 8)
			else: ui.notify("Belum waktunya pulang. " + ("Danu menyuruhku kembali ke kelas." if State.flag("invited") else "Aku perlu masuk kelas." if not State.flag("lessonSeen") else "Masih ada kesaksian dan bukti yang harus kuperiksa."), 6)
		"enter_school": host._travel("school")
		"trash_photo":
			if not State.flag("lessonSeen"): ui.notify("Ada kertas piket dibuang pagi ini. Bel masuk berbunyi—aku harus ke kelas dulu.")
			elif State.data.evidence.has("op1"): ui.notify("Tong sampah itu kini kosong. Foto sudah kusimpan di jurnal.")
			else:
				host._evidence("op1")
		"photo_missing": ui.notify("Bagian foto di meja ini telah disobek. Sari melihat Danu membuang sesuatu di tong sampah dekat gerbang.", 6)
		"gate_note": host._note("gate_log")
		"return_class":
			if State.flag("schoolDismissed"): ui.notify("Kelas sudah bubar. Keluar melalui gerbang sekolah.")
			elif not State.flag("invited"): ui.notify("Aku belum memahami kejadian tadi. Kumpulkan dua bukti lalu bicara dengan Danu.", 6)
			else: host.narrative.start("return_class")
		"alley":
			if State.flag("schoolDismissed") and State.flag("invited"):
				State.set_flag("choseRight"); host._travel("street")
			else: ui.notify("Aku belum punya alasan masuk ke gang itu.")
		"go_home": ui.notify("Rumahku ada di kiri. Tapi Danu menunggu di gang kanan. Aku sudah terlanjur berjanji untuk mendengarkan.", 7)
		_:
			if id.begins_with("door_"): _door(id.trim_prefix("door_"))
	host._save()

func _door(id: String) -> void:
	var doors: Dictionary = host.level.chapter_world.doors
	if not doors.has(id): return
	if id == "father": host.ui.notify("Terkunci. Dari dalam terdengar batuk Bapak, lalu bunyi kunci diputar sekali lagi.", 6); return
	if id == "mother":
		host.ui.show_dialogue("Ibu", "Ibu menutup bedaknya ketika melihatmu di cermin. “Tehnya di meja. Jangan berangkat dengan perut kosong.”\n\nKau menanyakan daisy yang baru. “Yang kemarin sudah layu. Kamu tidur sampai tidak dengar Ibu masuk.”\n\n“Pulang langsung, ya.” Ia melihat kamar adik melalui pintu. “Kalau temanmu sedang punya masalah, dengarkan dulu. Kamu tidak harus langsung memilih pihak.”")
		return
	if doors[id].open:
		var hinge: Node3D = doors[id].node
		var local = host.level.to_local(host.player.global_position)-hinge.position
		if absf(local.y)<2.0 and Vector2(local.x-0.55,local.z).length()<1.05:
			host.ui.notify("Mundur sedikit dari ambang sebelum menutup pintu."); return
	doors[id].open = not doors[id].open
	State.set_flag("home_door_" + id, doors[id].open)
	host.audio.effect("click")
	if id == "nursery" and doors[id].open: host.ui.notify("Kamar ini belum dipakai. Ibu menyiapkannya untuk adikku.", 5)

func school_evidence_count() -> int:
	var total = 0
	for id in ["A", "op1", "op2"]:
		if State.data.evidence.has(id): total += 1
	return total

func arrived(id: String, previous: String) -> void:
	if id == "schoolyard":
		if previous == "school":
			host.player.position = Vector3(0, 0.3, -12)
			host.player.rotation.y = PI
		else: host.ui.notify("SMA Kartini / 06.58. Jelajahi halaman atau masuk gedung untuk mengikuti pelajaran.", 7)
	elif id == "school":
		if not State.flag("lessonSeen"):
			host.player.position = Vector3(-4.4, 0.05, 11.3)
			host.player.rotation.y = 0
		else: host.player.position = Vector3(0, 0.05, -27)
	elif id == "neighborhood":
		host.ui.notify("13.47 / Simpang Kartini. Kiri menuju rumah. Gang yang disebut Danu ada di kanan.", 8)
	elif id == "street" and previous == "neighborhood":
		host.ui.notify("Gang terasa lebih panjang daripada yang terlihat dari jalan. Di ujungnya, Danu menunggu.", 7)
	host.player.last_safe_position = host.player.position

func update(_delta: float) -> void:
	# Crossing the entrance is enough; no invisible full-screen button is required.
	if State.data.room == "schoolyard" and host.player.position.z < -16.0 and absf(host.player.position.x) < 1.2:
		host._travel("school")
	elif State.data.room == "school" and State.flag("prologueVersion") and host.player.position.z < -30.5 and absf(host.player.position.x) < 1.2:
		host._travel("schoolyard")

func objective() -> String:
	match State.data.room:
		"home": return "Turun tangga. Belok kanan ke kamar mandi, lalu mandi dan bersiap (E)." if not State.flag("homeReady") else "Sudah siap. Keluar lewat pintu depan di bawah tangga."
		"schoolyard": return "Bel masuk. Jelajahi halaman lalu masuk pintu gedung sekolah." if not State.flag("lessonSeen") else "Kembali ke gedung dan kelas XI A." if State.flag("invited") and not State.flag("schoolDismissed") else "Bel pulang. Jalan langsung lewat gerbang, belok kanan, ikuti gang Gudang Kartini." if State.flag("schoolDismissed") else "Cari foto di tong sampah timur halaman. Bukti %d/2; gedung tetap bisa dijelajahi." % school_evidence_count()
		"school": return "Selidiki kelas, perpustakaan, lab dan halaman. Kumpulkan dua bukti (%d/2), lalu temui Danu." % school_evidence_count() if not State.flag("invited") else "Ikuti arahan Danu: kembali ke kelas XI A (E di pintu kelas)." if not State.flag("schoolDismissed") else "Pelajaran usai. Keluar gedung, lalu gerbang sekolah."
		"neighborhood": return "Keluar sekolah. Belok kanan, telusuri gang sempit menuju Gudang Kartini."
	return ""

extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")
const ORDERS = {"books": [2,0,1], "lab": [1,3,0,2]}
const POSITIONS = {"books": Vector3(12.25,0,13), "lab": Vector3(-6.5,0,-21)}
const CLUES = {
	"books": "Catatan pustakawan: susun perjalanan dari akar ke langit. BOTANI lebih dulu, lalu ZOOLOGI, terakhir ASTRONOMI. Tekan punggung buku sesuai urutan. Salah urutan mengulang dari awal.",
	"lab": "Prosedur praktikum: nyalakan AIR dahulu, kemudian PEMANAS, lanjutkan PENDINGIN, dan terakhir SENSOR. Tekan sakelar sesuai urutan. Sakelar salah mengulang rangkaian."
}

func build(level: Node3D) -> void:
	var root = Node3D.new(); root.name = "SchoolPuzzles"; level.add_child(root)
	_board(level,root,"books",POSITIONS.books,["ZOOLOGI","ASTRONOMI","BOTANI"])
	_board(level,root,"lab",POSITIONS.lab,["PENDINGIN","AIR","SENSOR","PEMANAS"])
	G.box(root,Vector3(11.5,0.55,-5),Vector3(1.15,1.1,0.55),G.material("plain",Color("68786f")),true).name = "SchoolArchiveCabinet"
	level.interact(Vector3(11.5,1.25,-4.65),"chapter","Buka laci arsip sekolah","campus_archive",false,Vector3(0.9,0.7,0.2))
	# Optional discoveries reward traversing the real upper floors.
	for i in range(2):
		var p = Vector3(-9,3.4*(i+1)+0.815,0)
		G.box(root,p,Vector3(0.32,0.025,0.24),G.material("plain",Color("d5c8a3")))
		level.interact(p+Vector3.UP*0.10,"chapter","Baca catatan klub lantai %d"%(i+2),"campus_upper_%d"%i,false,Vector3(0.55,0.22,0.4))
	refresh(level)

func _board(level: Node3D, root: Node3D, id: String, p: Vector3, labels: Array) -> void:
	var access = AABB(p+Vector3(-1.7,0,-0.5),Vector3(3.4,1.8,2.8))
	for mesh in level.get_node("SourceWorld").find_children("*","MeshInstance3D",true,false):
		var b: AABB=mesh.global_transform*mesh.get_aabb()
		if b.position.y>=0 and b.end.y<1.8 and maxf(b.size.x,b.size.z)<4 and access.intersects(b):
			# Retire complete desk/chair assemblies, including legs outside the
			# access rectangle, so clearing a route never leaves floating fragments.
			var retired: Node3D = mesh
			var group = mesh.get_parent()
			if group is Node3D and not group is MeshInstance3D and group.get_child_count() in range(2,11): retired=group
			retired.hide()
			for body in retired.find_children("*","StaticBody3D",true,false): body.collision_layer=0
	var board = Node3D.new(); board.name = "Puzzle_"+id; board.position=p; root.add_child(board)
	G.box(board,Vector3(0,0.45,0),Vector3(2.6,0.9,0.55),G.material("plain",Color("677b74")),true)
	for i in range(labels.size()):
		var x = -0.90+i*0.60
		var button = G.box(board,Vector3(x,1.10,0),Vector3(0.30,0.40,0.20),G.material("plain",Color("a69b78")),false)
		button.name = "Button%d"%i
		if id == "books":
			# Bound volumes with page blocks, covers and raised spine bands.
			var paper=G.material("plain",Color("e5dcc1"))
			G.box(button,Vector3(0,0,-0.015),Vector3(0.264,0.36,0.16),paper)
			for dy in [-0.19,0.19]: G.box(button,Vector3(0,dy,0),Vector3(0.31,0.02,0.21),G.material("plain",Color("425c50")))
			G.box(button,Vector3(0,0,0.107),Vector3(0.30,0.38,0.018),G.material("plain",Color("425c50")))
			for dy in [-0.13,0.13]: G.box(button,Vector3(0,dy,0.12),Vector3(0.29,0.015,0.008),G.material("plain",Color("c8b56f")))
			var title=G.sign_text(button,labels[i],Vector3(0,0,0.123),16); title.pixel_size=0.0017; title.outline_size=0
		else:
			G.box(button,Vector3(0,0,0.108),Vector3(0.26,0.35,0.018),G.material("plain",Color("334843")))
			var switch_face=G.box(button,Vector3(0,-0.025,0.13),Vector3(0.12,0.17,0.035),G.material("plain",Color("c9c5af")))
			switch_face.rotation.x=-0.16
			G.box(button,Vector3(0,0.13,0.127),Vector3(0.06,0.025,0.02),G.material("plain",Color("83bba0")))
		var label = G.sign_text(board,labels[i],Vector3(x,1.43,0.12),16); label.pixel_size=0.0045; label.outline_size=0
		level.interact(p+Vector3(x,1.10,0.12),"chapter","Tekan "+labels[i],"campus_%s_%d"%[id,i],false,Vector3(0.35,0.42,0.25))
	var status = G.sign_text(board,"",Vector3(0,1.9,0.12),20); status.name = "Progress"
	G.box(board,Vector3(0,0.92,0.30),Vector3(0.35,0.025,0.22),G.material("plain",Color("ddd3b7")))
	level.interact(p+Vector3(0,0.97,0.35),"chapter","Baca petunjuk "+("perpustakaan" if id=="books" else "praktikum"),"campus_clue_"+id,false,Vector3(0.40,0.13,0.25))

static func refresh(level: Node3D) -> void:
	var root = level.get_node_or_null("SchoolPuzzles")
	if root == null: return
	for id in ORDERS:
		var done = State.flag("campus_"+id+"_done")
		var step = int(State.data.flags.get("campus_"+id+"_step",0))
		root.get_node("Puzzle_"+id+"/Progress").text = "SELESAI" if done else "URUTAN %d / %d"%[step,ORDERS[id].size()]
		for i in range(ORDERS[id].size()):
			var lit = done or ORDERS[id].find(i) < step
			root.get_node("Puzzle_"+id+"/Button%d"%i).material_override = G.material("plain",Color("6da77c") if lit else Color("a69b78"))

static func interact(host: Node3D, id: String) -> void:
	if id.begins_with("campus_clue_"):
		var key = id.trim_prefix("campus_clue_")
		State.add_note("campus_"+key,"Petunjuk sekolah · "+key,CLUES[key])
		host.ui.show_dialogue("Catatan sekolah",CLUES[key]); return
	if id == "campus_archive":
		if not State.flag("campus_books_done") or not State.flag("campus_lab_done"):
			host.ui.notify("Dua pengunci masih aktif. Selesaikan susunan buku perpustakaan dan rangkaian lab IPA.",7); return
		var report = "07.05: Danu masuk gerbang bersama Raka. 07.12: keduanya menuju gudang lama untuk mengembalikan album. Catatan ini tidak menjelaskan pertengkaran di kelas; aku harus mendengar kedua pihak."
		State.add_note("campus_archive","Arsip akses gudang Kartini",report); State.set_flag("campusArchiveRead")
		host.ui.show_dialogue("Arsip akses gudang",report); return
	if id.begins_with("campus_upper_"):
		var text_value = "Klub literasi: pisahkan apa yang kau lihat dari apa yang kau duga. Arsip lantai satu menyimpan catatan akses gudang; dua panel berada di perpustakaan dan lab IPA."
		State.add_note(id,"Catatan klub sekolah",text_value); host.ui.show_dialogue("Catatan klub sekolah",text_value); return
	for key in ORDERS:
		if not id.begins_with("campus_"+key+"_"): continue
		if State.flag("campus_"+key+"_done"): host.ui.notify("Panel sudah selesai; progres tersimpan."); return
		var pressed = int(id.get_slice("_",2)); var order: Array = ORDERS[key]
		var step = clampi(int(State.data.flags.get("campus_"+key+"_step",0)),0,order.size()-1)
		var correct = pressed == order[step]
		step = step+1 if correct else 0
		State.data.flags["campus_"+key+"_step"] = step
		if step == order.size():
			State.set_flag("campus_"+key+"_done"); host.ui.notify("Rangkaian selesai. Satu pengunci laci arsip terbuka.",5)
		else: host.ui.notify("Benar. Lanjutkan urutan." if correct else "Urutan salah. Panel kembali ke awal; periksa petunjuk di meja.",4)
		host.audio.effect("click"); refresh(host.level); return

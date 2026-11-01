extends Control
signal connected(index: int)
var output: RichTextLabel
var command: LineEdit
var display: Control
var history: Array[String] = []
var history_index = 0
var connected_lines: Array = []
var font: SystemFont
var status: Label
var seconds = 0.0

func _ready() -> void:
	name = "RitualTerminal";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_left=0.07;anchor_right=0.93;anchor_top=0.08;anchor_bottom=0.92
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	font = SystemFont.new(); font.font_names=PackedStringArray(["Consolas","Cascadia Mono","monospace"])
	var bezel = Panel.new();bezel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bezel)
	var skin=StyleBoxFlat.new();skin.bg_color=Color("303b35");skin.border_color=Color("667060");skin.set_border_width_all(3);skin.set_corner_radius_all(15);bezel.add_theme_stylebox_override("panel",skin)
	var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",36);margin.add_theme_constant_override("margin_right",36);margin.add_theme_constant_override("margin_top",24);margin.add_theme_constant_override("margin_bottom",24);add_child(margin)
	var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",12);margin.add_child(stack)
	var plate=Label.new();plate.text="K A R T I N I   /   K - 1 7                                           ARSIP LOKAL"
	plate.add_theme_font_override("font",font);plate.add_theme_font_size_override("font_size",15);plate.modulate=Color("b6b49c");stack.add_child(plate)
	var crt=PanelContainer.new();crt.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(crt)
	var green=StyleBoxFlat.new();green.bg_color=Color("081510");green.border_color=Color("17271d");green.set_border_width_all(12);green.set_corner_radius_all(20);green.set_content_margin_all(20);crt.add_theme_stylebox_override("panel",green)
	var screen=VBoxContainer.new();screen.add_theme_constant_override("separation",6);crt.add_child(screen);display=screen
	output=RichTextLabel.new();output.bbcode_enabled=true;output.scroll_following=true;output.size_flags_vertical=Control.SIZE_EXPAND_FILL;output.selection_enabled=true
	output.add_theme_font_override("normal_font",font);output.add_theme_font_override("bold_font",font);output.add_theme_font_size_override("normal_font_size",17);output.add_theme_color_override("default_color",Color("93b99b"));screen.add_child(output)
	var prompt=HBoxContainer.new();screen.add_child(prompt)
	var path=Label.new();path.text="K17:\\AUDIT>";path.add_theme_font_override("font",font);path.add_theme_font_size_override("font_size",17);path.modulate=Color("b6d5a6");prompt.add_child(path)
	command=LineEdit.new();command.name="CommandLine";command.size_flags_horizontal=Control.SIZE_EXPAND_FILL;command.flat=true
	command.add_theme_font_override("font",font);command.add_theme_font_size_override("font_size",17);command.add_theme_color_override("font_color",Color("b6d5a6"));command.caret_blink=true;command.max_length=80
	command.text_submitted.connect(submit);command.gui_input.connect(_history_key);prompt.add_child(command)
	status=Label.new();status.add_theme_font_override("font",font);status.add_theme_font_size_override("font_size",13);status.modulate=Color("b6b49c");stack.add_child(status)
	connected_lines=State.data.puzzles.breaker.current.duplicate()
	write("KARTINI SYSTEMS  /  K-17  /  ROM 03.76\nMEMORY .......... 64K OK\nPITA AUDIT ...... TERBACA\nINTERLOCK ....... SAKSI TERVERIFIKASI\n")
	write("Volume K17:\\AUDIT terpasang.\nKetik HELP untuk perintah perangkat.\n")
	refresh_status();command.call_deferred("grab_focus")

func write(value: String, color = "93b99b") -> void:
	output.append_text("[color="+color+"]"+value.replace("[","[lb]")+"[/color]\n")

func submit(value: String) -> void:
	var line=value.strip_edges().to_upper()
	if line.is_empty():return
	history.append(line);history_index=history.size();command.clear();write("K17:\\AUDIT> "+line,"c3d6b4")
	var words=line.split(" ",false)
	match words[0]:
		"HELP","?":write("DIR                  daftar berkas\nBACA <nama>          baca berkas\nSTATUS               diagnostik interlock\nSAMBUNG <1..4>       tutup satu kontaktor\nRESET                lepaskan kontaktor\nBERSIHKAN            bersihkan layar\n\nUrutan otorisasi tidak tersimpan di ROM.")
		"DIR","LS":write("17-MAR   AUDIT.LOG       rekaman kejadian [sektor rusak]\n17-MAR   PIN.DAT         register kontaktor\n17-MAR   PEMULIHAN.TXT   catatan operator")
		"BACA","CAT","TYPE":
			if words.size()!=2:write("BACA memerlukan nama berkas.","d3aa74");return
			match words[1]:
				"AUDIT.LOG":write("[00:--] pemeriksaan / tidak ada saksi di ruang mesin\n[--:40] satu nama dipindahkan ke kolom tanggungan\n[02:--] pintu ditutup dari luar\n[--:15] pengesahan diterima setelah bunyi berhenti\n\nCRC gagal. Lembar kertas asli disimpan terpisah.")
				"PIN.DAT":write("KONTAKTOR 01  /  PEMINDAHAN\nKONTAKTOR 02  /  PENGESAHAN\nKONTAKTOR 03  /  PEMERIKSAAN\nKONTAKTOR 04  /  PENUTUPAN\n\nRelay mencatat urutan penutupan, bukan nomor jalur.")
				"PEMULIHAN.TXT":write("Jangan menulis ulang log yang rusak.\nRekonstruksi kejadian dari salinan yang belum ditimpa.\nNama pada berkas dapat diganti. Waktu pada kertas tidak.")
				_:write("Berkas tidak ditemukan.","d3aa74")
		"STATUS":
			write("AUDIT: "+("TERBACA" if State.flag("auditVerified") else "BELUM DIVERIFIKASI")+"\nSAKSI: "+("TERCATAT" if State.data.evidence.has("B") else "KOSONG")+"\nKONTAKTOR: "+str(connected_lines.size())+" / 4\nJALUR UTARA: "+("TERBUKA" if State.solved("breaker") else "TERKUNCI"))
		"SAMBUNG","CONNECT":
			if words.size()!=2 or not words[1].is_valid_int() or int(words[1])<1 or int(words[1])>4:
				write("Alamat tidak valid. SAMBUNG <1..4>.","d3aa74");return
			connected.emit(int(words[1])-1)
		"RESET":
			if not State.solved("breaker"):State.data.puzzles.breaker.current.clear();State.changed.emit()
			connected_lines=State.data.puzzles.breaker.current.duplicate();refresh_status();write("Kontaktor dilepas. Interlock kembali siaga.")
		"BERSIHKAN","CLS","CLEAR":output.clear()
		_:write("Perintah tidak dikenal. HELP menampilkan perintah perangkat.","d3aa74")

func acknowledge(index: int, before: int) -> void:
	connected_lines=State.data.puzzles.breaker.current.duplicate()
	if connected_lines.size()>before:write("K%02d  /  KONTAK TERTUTUP  /  REKAMAN DITERIMA"%(index+1))
	else:write("INTERLOCK: urutan kejadian tidak sah.\nSeluruh kontaktor dilepas.","d89174")
	refresh_status()

func refresh_status() -> void:
	status.text="● DAYA  /  LOKAL             KONTAKTOR %d / 4             ESC · LEPAS TERMINAL"%connected_lines.size()

func _history_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or history.is_empty():return
	if event.keycode==KEY_UP:
		history_index=maxi(0,history_index-1);command.text=history[history_index];command.caret_column=command.text.length();accept_event()
	elif event.keycode==KEY_DOWN:
		history_index=mini(history.size(),history_index+1);command.text="" if history_index==history.size() else history[history_index];command.caret_column=command.text.length();accept_event()

func _process(delta: float) -> void:
	seconds+=delta;display.modulate=Color(0.98+sin(seconds*41)*0.015,1,0.98+sin(seconds*37)*0.01)

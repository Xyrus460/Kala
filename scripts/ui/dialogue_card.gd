extends VBoxContainer
signal finished
var text: RichTextLabel
var pages: PackedStringArray
var page = 0
var reveal = 0.0
var next: Button

func build(speaker: String, body: String) -> void:
	pages = body.split("\n\n", false)
	add_theme_constant_override("separation", 16)
	var nameplate = Label.new(); nameplate.text = speaker.to_upper() + "  /  KESAKSIAN"
	nameplate.add_theme_font_size_override("font_size", 15); nameplate.modulate = Color("b5bfa4"); add_child(nameplate)
	text = RichTextLabel.new(); text.custom_minimum_size = Vector2(750, 150); text.fit_content = true
	text.add_theme_font_size_override("normal_font_size", 24); add_child(text)
	next = Button.new(); next.text = "DENGARKAN LANJUTANNYA  ·  E"; next.pressed.connect(advance); add_child(next)
	_show_page()

func _show_page() -> void:
	text.text = pages[page]; text.visible_characters = 0; reveal = 0
	next.text = "SELESAI MENDENGARKAN  ·  E" if page == pages.size() - 1 else "DENGARKAN LANJUTANNYA  ·  E"

func advance() -> void:
	if text.visible_characters < text.get_total_character_count():
		text.visible_characters = text.get_total_character_count(); reveal = text.visible_characters; return
	page += 1
	if page >= pages.size(): finished.emit()
	else: _show_page()

func _process(delta: float) -> void:
	if text == null: return
	reveal += delta * 42
	text.visible_characters = mini(int(reveal), text.get_total_character_count())

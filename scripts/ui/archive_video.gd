extends Control
signal completed
signal closed
var video: VideoStreamPlayer
var transport: Button
var counter: Label
var finish_label: Label
var verified=false
const PATH="res://assets/video/audit_17_maret.ogv"

func _ready() -> void:
	name="AuditVideoPlayer";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back=ColorRect.new();back.color=Color.BLACK;back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(back)
	var stack=VBoxContainer.new();stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.offset_left=24;stack.offset_right=-24;stack.offset_top=14;stack.offset_bottom=-14;add_child(stack)
	var header=HBoxContainer.new();stack.add_child(header)
	var title=Label.new();title.text="KARTINI  /  ARSIP VISUAL  /  17 MARET";title.add_theme_font_size_override("font_size",13);title.modulate=Color("989d8e");title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	var close=Button.new();close.text="Tutup (Esc)";close.flat=true;close.add_theme_font_size_override("font_size",13);close.pressed.connect(func():closed.emit());header.add_child(close)
	var picture=AspectRatioContainer.new();picture.ratio=16.0/9.0;picture.stretch_mode=AspectRatioContainer.STRETCH_FIT;picture.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(picture)
	video=VideoStreamPlayer.new();video.name="AuditFilm";video.expand=true;video.volume_db=-2;video.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.add_child(video)
	video.finished.connect(_finished)
	var footer=HBoxContainer.new();footer.add_theme_constant_override("separation",22);stack.add_child(footer)
	transport=Button.new();transport.text="Ⅱ  Jeda";transport.flat=true;transport.pressed.connect(toggle);footer.add_child(transport)
	var replay=Button.new();replay.text="↺  Putar ulang";replay.flat=true;replay.pressed.connect(play);footer.add_child(replay)
	finish_label=Label.new();finish_label.add_theme_font_size_override("font_size",12);finish_label.modulate=Color("a2b399");finish_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(finish_label)
	counter=Label.new();counter.add_theme_font_size_override("font_size",12);counter.modulate=Color("a5ab9d");footer.add_child(counter)
	if ResourceLoader.exists(PATH):video.stream=load(PATH);play()
	else:
		finish_label.text="Gulungan tidak dapat dibaca.";transport.disabled=true;replay.disabled=true

func toggle() -> void:
	if video.stream==null:return
	if not video.is_playing():play();return
	video.paused=not video.paused;transport.text="▶  Lanjutkan" if video.paused else "Ⅱ  Jeda"

func play() -> void:
	if video.stream==null:return
	video.stop();video.paused=false;video.play();transport.text="Ⅱ  Jeda";finish_label.text=""

func _finished() -> void:
	transport.text="▶  Putar";finish_label.text="Rekaman selesai · disimpan di jurnal"
	if not verified:verified=true;completed.emit()

func _process(_delta: float) -> void:
	if video==null or video.stream==null:return
	var t=int(video.stream_position);counter.text="%02d:%02d"%[t/60,t%60]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_SPACE:
		toggle();get_viewport().set_input_as_handled()

func stop() -> void:
	if is_instance_valid(video):video.stop();video.stream=null

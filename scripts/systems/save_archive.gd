extends RefCounted
## The legacy file stays the Continue checkpoint; history stores independent snapshots.
const MAX_AUTOSAVES = 48

func history_path(state: Node) -> String:
	return state.save_path + ".history.json"

func thumbnail_path(state: Node, id: String) -> String:
	if not id.is_valid_identifier(): return ""
	return state.save_path.get_basename() + "_previews/" + id + ".png"

func write_json(path: String, value: Variant) -> Error:
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(value)); file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func entries(state: Node) -> Array:
	var result: Array = []
	if FileAccess.file_exists(history_path(state)):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(history_path(state)))
		if parsed is Array:
			for value in parsed:
				if value is Dictionary and value.get("id", null) is String and state.valid_save(value.get("data")):
					var normalized = entry(value.data, value.id, state)
					if value.get("saved_at") is float or value.get("saved_at") is int: normalized.saved_at = value.saved_at
					normalized.kind = "manual" if value.get("kind", "auto") == "manual" else "auto"
					result.append(normalized)
	var latest: Dictionary = state.read_save()
	if not latest.is_empty():
		var id = str(latest.get("save_id", "legacy"))
		var found = false
		for i in range(result.size()):
			if result[i].id == id: result[i] = entry(latest, id, state); found = true; break
		if not found: result.append(entry(latest, id, state))
	result.sort_custom(func(a, b):
		if float(a.saved_at) == float(b.saved_at): return str(a.id) > str(b.id)
		return float(a.saved_at) > float(b.saved_at))
	return result

func entry(snapshot: Dictionary, id: String, state: Node) -> Dictionary:
	return {"id": id, "saved_at": snapshot.get("saved_at", FileAccess.get_modified_time(state.save_path)), "kind": snapshot.get("save_kind", "auto"), "data": snapshot.duplicate(true)}

func progress(snapshot: Dictionary) -> String:
	var value = snapshot.duplicate(true)
	for key in ["position", "sanity", "elapsed", "save_id", "saved_at", "save_kind"]: value.erase(key)
	# JSON reloads integers as floats and StringName keys as Strings. Normalize
	# both sides before comparing so an unchanged save survives a disk round trip.
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)))

func persist(state: Node, kind: String) -> Error:
	var records = entries(state)
	var now = Time.get_unix_time_from_system()
	var id = "s_%020d_%020d" % [int(now * 1000000), Time.get_ticks_usec()]
	# Refresh an unchanged autosave; meaningful progress and manual saves get new rows.
	if kind == "auto" and not records.is_empty() and records[0].kind == "auto" and progress(records[0].data) == progress(state.data):
		id = records[0].id; records.pop_front()
	state.data.save_id = id; state.data.saved_at = now; state.data.save_kind = kind
	var error = write_json(state.save_path, state.data)
	if error != OK: return error
	state.checkpoint = state.data.duplicate(true)
	records.push_front(entry(state.data, id, state))
	var autosaves = 0
	for i in range(records.size() - 1, -1, -1):
		if records[i].kind == "manual": continue
		autosaves += 1
	# Keep every manual save and the newest automatic snapshots.
	if autosaves > MAX_AUTOSAVES:
		var kept: Array = []; autosaves = 0
		for record in records:
			if record.kind != "manual": autosaves += 1
			if record.kind == "manual" or autosaves <= MAX_AUTOSAVES: kept.append(record)
		var kept_ids = kept.map(func(record): return record.id)
		for record in records:
			if record.id not in kept_ids: remove_preview(state, record.id)
		records = kept
	return write_json(history_path(state), records)

func load_slot(state: Node, id: String) -> bool:
	for record in entries(state):
		if record.id == id:
			state.data = record.data.duplicate(true)
			state.checkpoint = state.data.duplicate(true)
			state.changed.emit(); return true
	return false

func delete_slot(state: Node, id: String) -> Error:
	if not state.save_enabled: return ERR_UNAVAILABLE
	var records = entries(state)
	var found = false
	for i in range(records.size() - 1, -1, -1):
		if records[i].id == id: records.remove_at(i); found = true
	if not found: return ERR_DOES_NOT_EXIST
	var latest: Dictionary = state.read_save()
	if not latest.is_empty() and str(latest.get("save_id", "legacy")) == id:
		var error: Error
		if records.is_empty(): error = DirAccess.remove_absolute(state.save_path)
		else: error = write_json(state.save_path, records[0].data)
		if error != OK: return error
	var error = write_json(history_path(state), records)
	if error == OK: remove_preview(state, id)
	return error

func remove_preview(state: Node, id: String) -> void:
	var path = thumbnail_path(state, id)
	if not path.is_empty() and FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func save_preview(state: Node, id: String, image: Image) -> Error:
	var path = thumbnail_path(state, id)
	if path.is_empty(): return ERR_INVALID_PARAMETER
	# An async capture may finish after pruning/deletion; don't resurrect its image.
	if not entries(state).any(func(record): return record.id == id): return ERR_DOES_NOT_EXIST
	var error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK: return error
	image.resize(480, 270, Image.INTERPOLATE_LANCZOS)
	return image.save_png(path)

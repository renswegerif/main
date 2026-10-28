class_name Tekeningen
extends Node
## Bewaart de uitgeknipte tekeningen in user://tekeningen en houdt een inbox-map in de gaten.
## Foto's of scans die je in de inbox zet (bijv. via AirDrop), worden vanzelf verwerkt.

signal nieuw(tekening: Dictionary)

const MAP := "user://tekeningen"

## Elke tekening: {"id": String, "texture": Texture2D, "t": int}. Nieuwste achteraan.
var lijst: Array[Dictionary] = []
var inbox := ""
var streng := 38.0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(MAP)
	inbox = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).path_join("Tekenzee-inbox")
	DirAccess.make_dir_recursive_absolute(inbox.path_join("verwerkt"))
	_laad_bestaande()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_kijk_in_inbox)
	add_child(timer)


func _laad_bestaande() -> void:
	var namen := Array(DirAccess.get_files_at(MAP))
	namen.sort()
	for f: String in namen:
		if f.get_extension().to_lower() != "png":
			continue
		var img := Image.load_from_file(MAP.path_join(f))
		if img:
			var id := f.get_basename()
			lijst.append({"id": id, "texture": ImageTexture.create_from_image(img), "t": id.to_int()})


## Knipt de tekening uit een foto en voegt hem toe. Geeft false als er geen tekening in staat.
func voeg_foto_toe(foto: Image) -> bool:
	var uit := Uitknippen.knip(foto, streng)
	if uit == null:
		return false
	var t := int(Time.get_unix_time_from_system() * 1000.0)
	var id := str(t)
	uit.save_png(MAP.path_join(id + ".png"))
	var tek := {"id": id, "texture": ImageTexture.create_from_image(uit), "t": t}
	lijst.append(tek)
	nieuw.emit(tek)
	return true


func laatste(aantal: int) -> Array[Dictionary]:
	return lijst.slice(maxi(0, lijst.size() - aantal))


func wis_alles() -> void:
	for f in DirAccess.get_files_at(MAP):
		DirAccess.remove_absolute(MAP.path_join(f))
	lijst.clear()


func _kijk_in_inbox() -> void:
	var nu := Time.get_unix_time_from_system()
	for f in DirAccess.get_files_at(inbox):
		if not f.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp", "heic"]:
			continue
		var pad := inbox.path_join(f)
		# Even wachten tot het bestand helemaal binnen is.
		if nu - FileAccess.get_modified_time(pad) < 2:
			continue
		var img := Image.load_from_file(pad)
		if img and not voeg_foto_toe(img):
			push_warning("Geen tekening gevonden in " + f)
		DirAccess.rename_absolute(pad, inbox.path_join("verwerkt").path_join(f))

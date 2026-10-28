extends Node2D
## Tekenzee. Alles wat op de beamer komt, hangt onder [member beeld], zodat spiegelen en
## draaien voor de projectie op één plek gebeurt.

const CFG := "user://instellingen.cfg"
const HULP := """Tekenzee  ·  toetsen

SPATIE   foto van de tekening onder de webcam
R           race starten  (of beide spelers tegelijk op hun knop)
ESC       terug naar het aquarium
A / L      speler 1 / speler 2  (ook gamepads, arcadeknoppen en dansmatten)

W   webcambeeld tonen      N   andere camera      K   webcam draaien      J   webcam spiegelen
M   beeld spiegelen          T   beeld 180° draaien    F   volledig scherm
+ / -   dieren groter / kleiner      [ / ]   minder / strenger knippen
O   inbox-map openen (foto's hierin worden vanzelf toegevoegd)
H   deze hulp tonen of verbergen"""

var beeld: Node2D
var tekeningen: Tekeningen
var webcam: Webcam
var aquarium: Aquarium
var race: Race

var _hulp: Label
var _melding: Label
var _melding_tijd := 0.0
var _voorbeeld: TextureRect
var _tegelijk := [-10.0, -10.0]  # wanneer speler 1 en 2 voor het laatst drukten in het aquarium
var _rust_tot := 0.0  # na een race even geen nieuwe race via de knoppen
var _inst := {"spiegel": false, "draai": false, "grootte": 1.0, "cam_draai": 0, "cam_spiegel": false, "streng": 38.0}


func _ready() -> void:
	_maak_knoppen()
	_laad_instellingen()
	tekeningen = Tekeningen.new()
	tekeningen.streng = _inst.streng
	add_child(tekeningen)
	webcam = Webcam.new()
	webcam.draai = _inst.cam_draai
	webcam.spiegel = _inst.cam_spiegel
	add_child(webcam)

	beeld = Node2D.new()
	add_child(beeld)
	_naar_aquarium()

	_voorbeeld = TextureRect.new()
	_voorbeeld.texture = webcam.kijker.get_texture()
	_voorbeeld.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_voorbeeld.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_voorbeeld.visible = false
	beeld.add_child(_voorbeeld)
	_hulp = _tekst(26, HORIZONTAL_ALIGNMENT_LEFT)
	_hulp.text = HULP
	_hulp.visible = false
	var vak := StyleBoxFlat.new()
	vak.bg_color = Color(0.0, 0.03, 0.06, 0.92)
	vak.set_corner_radius_all(18)
	vak.set_content_margin_all(28)
	_hulp.add_theme_stylebox_override("normal", vak)
	_melding = _tekst(40, HORIZONTAL_ALIGNMENT_CENTER)
	get_viewport().size_changed.connect(_schik)
	_schik()
	toon("Druk op H voor hulp")


func _tekst(grootte: int, uitlijning: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", grootte)
	l.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = uitlijning
	beeld.add_child(l)
	return l


## Spelers en extra knoppen. Gamepad 1 = speler 1, gamepad 2 = speler 2, gamepad 3 = foto.
func _maak_knoppen() -> void:
	var acties := {"p1": [KEY_A, 0], "p2": [KEY_L, 1], "foto": [KEY_SPACE, 2]}
	for actie in acties:
		if InputMap.has_action(actie):
			InputMap.erase_action(actie)
		InputMap.add_action(actie)
		var toets := InputEventKey.new()
		toets.physical_keycode = acties[actie][0]
		InputMap.action_add_event(actie, toets)
		for knop in 16:
			var j := InputEventJoypadButton.new()
			j.device = acties[actie][1]
			j.button_index = knop
			InputMap.action_add_event(actie, j)


func _maat() -> Vector2:
	return get_viewport_rect().size


func _schik() -> void:
	var m := _maat()
	var t := Transform2D.IDENTITY
	if _inst.spiegel:
		t = Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2(m.x, 0)) * t
	if _inst.draai:
		t = Transform2D(Vector2(-1, 0), Vector2(0, -1), m) * t
	beeld.transform = t
	if aquarium:
		aquarium.grootte = _inst.grootte
		aquarium.zet_maat(m)
	if race:
		race.zet_maat(m)
	_voorbeeld.position = Vector2(m.x * 0.6, m.y * 0.05)
	_voorbeeld.size = Vector2(m.x * 0.36, m.y * 0.4)
	_hulp.position = Vector2(m.x * 0.05, m.y * 0.08)
	_hulp.size = Vector2(m.x * 0.9, 0)
	_melding.position = Vector2(0, m.y * 0.86)
	_melding.size = Vector2(m.x, m.y * 0.1)
	# tekst en voorbeeld altijd bovenop
	for n in [_voorbeeld, _hulp, _melding]:
		beeld.move_child(n, beeld.get_child_count() - 1)


func toon(tekst: String, duur: float = 3.5) -> void:
	_melding.text = tekst
	_melding.modulate.a = 1.0
	_melding_tijd = duur


func _process(delta: float) -> void:
	if _melding_tijd > 0.0:
		_melding_tijd -= delta
		_melding.modulate.a = clampf(_melding_tijd, 0.0, 1.0)


func _naar_aquarium() -> void:
	if race:
		race.queue_free()
		race = null
		_rust_tot = Time.get_ticks_msec() / 1000.0 + 4.0
	if aquarium:
		return
	aquarium = Aquarium.new()
	aquarium.tekeningen = tekeningen
	aquarium.maat = _maat()
	aquarium.grootte = _inst.grootte
	beeld.add_child(aquarium)
	beeld.move_child(aquarium, 0)


func _naar_race() -> void:
	if race:
		return
	if aquarium:
		aquarium.queue_free()
		aquarium = null
	race = Race.new()
	race.tekeningen = tekeningen
	race.size = _maat()
	race.afgelopen.connect(_naar_aquarium)
	beeld.add_child(race)
	beeld.move_child(race, 0)
	toon("Race! Kies je dier.")


func _foto() -> void:
	if not webcam.heeft_camera():
		toon("Geen webcam gevonden. Sluit er een aan, of zet foto's in de inbox-map (toets O).")
		return
	var img := webcam.foto()
	toon("Even knippen…", 10.0)
	await get_tree().process_frame
	if img and tekeningen.voeg_foto_toe(img):
		toon("Daar zwemt hij!")
	else:
		toon("Geen tekening gevonden. Ligt het blad goed in beeld? Probeer [ of ] voor minder of strenger knippen.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("foto") and race == null:
		_foto()
		return
	if aquarium and (event.is_action_pressed("p1") or event.is_action_pressed("p2")):
		# Beide spelers vlak na elkaar op hun knop: race!
		var i := 0 if event.is_action_pressed("p1") else 1
		var nu := Time.get_ticks_msec() / 1000.0
		_tegelijk[i] = nu
		if absf(_tegelijk[0] - _tegelijk[1]) < 0.6 and nu > _rust_tot:
			_naar_race()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE:
			if _hulp.visible:
				_hulp.visible = false
			else:
				_naar_aquarium()
		KEY_R:
			_naar_race()
		KEY_H:
			_hulp.visible = not _hulp.visible
		KEY_F:
			var vol := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if vol else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_M:
			_inst.spiegel = not _inst.spiegel
			_bewaar("Beeld gespiegeld" if _inst.spiegel else "Beeld niet gespiegeld")
		KEY_T:
			_inst.draai = not _inst.draai
			_bewaar("Beeld 180° gedraaid" if _inst.draai else "Beeld rechtop")
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_inst.grootte = minf(2.5, _inst.grootte * 1.15)
			_bewaar("Grootte %d%%" % roundi(_inst.grootte * 100))
		KEY_MINUS, KEY_KP_SUBTRACT:
			_inst.grootte = maxf(0.4, _inst.grootte / 1.15)
			_bewaar("Grootte %d%%" % roundi(_inst.grootte * 100))
		KEY_BRACKETLEFT:
			_inst.streng = maxf(10.0, _inst.streng - 6.0)
			tekeningen.streng = _inst.streng
			_bewaar("Minder streng knippen (%d)" % _inst.streng)
		KEY_BRACKETRIGHT:
			_inst.streng = minf(80.0, _inst.streng + 6.0)
			tekeningen.streng = _inst.streng
			_bewaar("Strenger knippen (%d)" % _inst.streng)
		KEY_W:
			_voorbeeld.visible = not _voorbeeld.visible
			toon("Webcam: " + webcam.naam())
		KEY_N:
			webcam.volgende()
			toon("Webcam: " + webcam.naam())
		KEY_K:
			_inst.cam_draai = (_inst.cam_draai + 1) % 4
			webcam.draai = _inst.cam_draai
			_bewaar("Webcam %d° gedraaid" % (_inst.cam_draai * 90))
		KEY_J:
			_inst.cam_spiegel = not _inst.cam_spiegel
			webcam.spiegel = _inst.cam_spiegel
			_bewaar("Webcam gespiegeld" if _inst.cam_spiegel else "Webcam niet gespiegeld")
		KEY_O:
			OS.shell_open(ProjectSettings.globalize_path(tekeningen.inbox))
			toon("Inbox: " + tekeningen.inbox)


func _bewaar(melding: String) -> void:
	var c := ConfigFile.new()
	for k in _inst:
		c.set_value("tekenzee", k, _inst[k])
	c.save(CFG)
	_schik()
	toon(melding)


func _laad_instellingen() -> void:
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		for k in _inst:
			_inst[k] = c.get_value("tekenzee", k, _inst[k])

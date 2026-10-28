class_name Aquarium
extends Node2D
## Het zwembad waarin alle tekeningen rondzwemmen. Klik of tik in het water: de dieren schrikken.

const DECOR_SHADER := preload("res://shaders/wiegen.gdshader")

var tekeningen: Tekeningen
var maat := Vector2(1920, 1080)
var max_dieren := 30
var grootte := 1.0

var _zee: Zee
var _decor: Node2D
var _dieren: Node2D
var _bubbels: Array[Dictionary] = []
var _rimpels: Array[Dictionary] = []
var _overlay: Node2D


func _ready() -> void:
	_zee = Zee.new()
	_zee.bronnen = func() -> Array: return _dieren.get_children().map(func(d): return d.position)
	add_child(_zee)
	_decor = Node2D.new()
	add_child(_decor)
	_dieren = Node2D.new()
	add_child(_dieren)
	_overlay = Node2D.new()
	_overlay.draw.connect(_teken_overlay)
	add_child(_overlay)
	for t in tekeningen.laatste(max_dieren):
		_voeg_toe(t, false)
	_vul_voorbeelden()
	tekeningen.nieuw.connect(func(t: Dictionary): _voeg_toe(t, true))
	zet_maat(maat)


func zet_maat(m: Vector2) -> void:
	maat = m
	_zee.maat = m
	_maak_decor()
	for d: Zwemmer in _dieren.get_children():
		d.position = d.position.clamp(Vector2.ZERO, maat)


func aantal_echte() -> int:
	return _dieren.get_children().filter(func(d): return not d.voorbeeld).size()


func _basis_breedte() -> float:
	return minf(maat.x, maat.y) * 0.26 * grootte


func _voeg_toe(t: Dictionary, met_plons: bool) -> void:
	var z := Zwemmer.new()
	z.id = t.id
	z.voorbeeld = t.get("voorbeeld", false)
	z.zet_tekening(t.texture)
	z.breedte = _basis_breedte() * randf_range(0.85, 1.15)
	z.position = Vector2(randf_range(0.15, 0.85) * maat.x, randf_range(0.2, 0.8) * maat.y)
	var richting := -1.0 if randf() < 0.5 else 1.0
	z.set_meta("snelheid", randf_range(0.045, 0.085))
	z.set_meta("wil", richting)
	z.set_meta("v", Vector2(richting * 40.0, 0))
	z.set_meta("schrik", 0.0)
	z.set_meta("groei", 0.0 if met_plons else 1.0)
	_dieren.add_child(z)
	if met_plons:
		for i in 3:
			_rimpels.append({"pos": z.position, "wacht": i * 0.25, "leeftijd": 0.0})
	_ruim_op()


func _vul_voorbeelden() -> void:
	if aantal_echte() >= 3:
		return
	var i := 0
	for tex in Plaatjes.laad("dieren"):
		_voeg_toe({"id": "voorbeeld-%d" % i, "texture": tex, "voorbeeld": true}, false)
		i += 1


func _ruim_op() -> void:
	# Voorbeelden zwemmen weg zodra er echte tekeningen zijn; daarna gaan de oudste eruit.
	if aantal_echte() >= 3:
		for d: Zwemmer in _dieren.get_children():
			if d.voorbeeld:
				d.queue_free()
	var echte := _dieren.get_children().filter(func(d): return not d.voorbeeld and not d.is_queued_for_deletion())
	while echte.size() > max_dieren:
		echte.pop_front().queue_free()


func _maak_decor() -> void:
	for c in _decor.get_children():
		c.queue_free()
	var mat := ShaderMaterial.new()
	mat.shader = DECOR_SHADER
	# ver weg: groot, donker en blauwig
	var achter := Plaatjes.laad("achter")
	for i in achter.size():
		_zet_decor(achter[i], maat.x * (0.2 + 0.6 * i / maxf(1, achter.size() - 1)), maat.y * 0.3, Color(0.25, 0.35, 0.5, 0.6), null)
	# op de bodem: koraal, wier, stenen
	var midden := Plaatjes.laad("midden")
	if midden.is_empty():
		return
	var x := -maat.x * 0.02
	var k := 0
	while x < maat.x * 1.02:
		var tex: Texture2D = midden[k % midden.size()]
		_zet_decor(tex, x, maat.y * randf_range(0.18, 0.3), Color(0.55, 0.6, 0.7), mat)
		x += maat.x * randf_range(0.08, 0.16)
		k += 1


func _zet_decor(tex: Texture2D, x: float, hoogte: float, kleur: Color, mat: Material) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var k := hoogte / tex.get_height()
	s.scale = Vector2(k, k)
	s.position = Vector2(x - tex.get_width() * k * 0.5, maat.y - tex.get_height() * k + maat.y * 0.02)
	s.modulate = kleur
	if mat:
		s.material = mat
	_decor.add_child(s)


func _process(delta: float) -> void:
	var S := minf(maat.x, maat.y)
	for z: Zwemmer in _dieren.get_children():
		var snel: float = z.get_meta("snelheid")
		var wil: float = z.get_meta("wil")
		var v: Vector2 = z.get_meta("v")
		var schrik: float = maxf(0.0, z.get_meta("schrik") - delta)
		var groei: float = minf(1.0, z.get_meta("groei") + delta / 1.4)
		var hard := 3.2 if schrik > 0.0 else 1.0
		var b := z.breedte
		var h := b * z.verhouding()
		if randf() < delta * 0.02:
			wil = -wil
		if z.position.x < b * 0.6:
			wil = 1.0
		if z.position.x > maat.x - b * 0.6:
			wil = -1.0
		v.x += (wil * snel * S * hard - v.x) * minf(1.0, delta * (3.0 if schrik > 0.0 else 0.8))
		var doel_y := sin(Time.get_ticks_msec() / 1000.0 * 0.35 + z.fase) * snel * S * 0.35 * hard
		v.y += (doel_y - v.y) * minf(1.0, delta * 1.2)
		if z.position.y < h:
			v.y += S * 0.5 * delta
		if z.position.y > maat.y - h:
			v.y -= S * 0.5 * delta
		z.position += v * delta
		z.position.x = clampf(z.position.x, -b, maat.x + b)
		z.position.y = clampf(z.position.y, h * 0.4, maat.y - h * 0.4)
		var draai := clampf(v.x / (snel * S * 0.6), -1.0, 1.0)
		z.rotation = atan2(v.y, absf(v.x) + 1.0) * 0.5 * signf(draai if draai != 0.0 else 1.0)
		z.zwiep = 0.2 if schrik > 0.0 else 0.12
		z.beweeg(delta, 2.2 if schrik > 0.0 else 1.0, draai, _veer(groei))
		z.set_meta("wil", wil)
		z.set_meta("v", v)
		z.set_meta("schrik", schrik)
		z.set_meta("groei", groei)
		# belletjes
		if randf() < delta * 0.12:
			_bubbels.append({"pos": z.position + Vector2(signf(draai) * b * 0.45, 0), "r": randf_range(2, 6) * S / 600.0,
				"v": randf_range(20, 45) * S / 600.0, "leeftijd": 0.0, "max": randf_range(1.5, 3.0)})
	for i in range(_bubbels.size() - 1, -1, -1):
		var bel := _bubbels[i]
		bel.leeftijd += delta
		bel.pos += Vector2(sin(bel.leeftijd * 4.0) * 0.3, -bel.v * delta)
		if bel.leeftijd > bel.max:
			_bubbels.remove_at(i)
	for i in range(_rimpels.size() - 1, -1, -1):
		var r := _rimpels[i]
		if r.wacht > 0.0:
			r.wacht -= delta
			continue
		r.leeftijd += delta
		if r.leeftijd > 1.6:
			_rimpels.remove_at(i)
	_overlay.queue_redraw()


## Groeit met een klein veertje over de 1 heen, zoals een plons.
func _veer(x: float) -> float:
	if x >= 1.0:
		return 1.0
	var c := 1.7
	return 1.0 + (c + 1.0) * pow(x - 1.0, 3) + c * pow(x - 1.0, 2)


func _teken_overlay() -> void:
	var S := minf(maat.x, maat.y)
	for r in _rimpels:
		if r.wacht > 0.0:
			continue
		var straal: float = r.leeftijd * S * 0.22
		var kleur := Color(0.7, 0.94, 1.0, 0.5 * (1.0 - r.leeftijd / 1.6))
		_overlay.draw_arc(r.pos, straal, 0, TAU, 48, kleur, 3.0)
	for bel in _bubbels:
		_overlay.draw_arc(bel.pos, bel.r, 0, TAU, 12, Color(0.8, 0.95, 1.0, 0.6 * (1.0 - bel.leeftijd / bel.max)), 1.5)


func schrik_op(plek: Vector2) -> void:
	var S := minf(maat.x, maat.y)
	_rimpels.append({"pos": plek, "wacht": 0.0, "leeftijd": 0.0})
	for z: Zwemmer in _dieren.get_children():
		var d := z.position - plek
		if d.length() < S * 0.35:
			var snel: float = z.get_meta("snelheid")
			z.set_meta("wil", 1.0 if d.x >= 0.0 else -1.0)
			var v: Vector2 = z.get_meta("v")
			v.y = d.normalized().y * snel * S * 2.0
			z.set_meta("v", v)
			z.set_meta("schrik", 1.6)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		schrik_op(get_local_mouse_position())
	elif event is InputEventScreenTouch and event.pressed:
		schrik_op(get_global_transform_with_canvas().affine_inverse() * event.position)

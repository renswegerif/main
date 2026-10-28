class_name Baan
extends Control
## Eén zwembaan in de race. Het dier blijft links staan, de wereld schuift voorbij.

const PX_PER_M := 140.0
const LENGTE_M := 50.0
const BOOSTS := [10.0, 20.0, 30.0, 40.0]
const DECOR_SHADER := preload("res://shaders/wiegen.gdshader")

var naam := "Speler 1"
var kleur := Color(1.0, 0.45, 0.3)
var afstand := 0.0  # meter
var snelheid := 0.0  # meter per seconde
var finish_tijd := -1.0
var mag_zwemmen := false
var vis: Zwemmer

var _decor: Array[Dictionary] = []  # {"node", "x", "diepte"}
var _boost_gehad := {}
var _flits := 0.0
var _gloed: Texture2D
var _decor_laag: Node2D
var _voor_laag: Node2D
var _naam: Label


func _ready() -> void:
	clip_contents = true
	_gloed = Plaatjes.gloed()
	_decor_laag = Node2D.new()
	add_child(_decor_laag)
	vis = Zwemmer.new()
	add_child(vis)
	_voor_laag = Node2D.new()
	add_child(_voor_laag)
	_naam = Label.new()
	_naam.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_naam.add_theme_constant_override("outline_size", 10)
	add_child(_naam)


func zet_dier(tex: Texture2D) -> void:
	vis.zet_tekening(tex)


func opnieuw() -> void:
	afstand = 0.0
	snelheid = 0.0
	finish_tijd = -1.0
	mag_zwemmen = false
	_boost_gehad.clear()
	_bouw_decor()


func _bouw_decor() -> void:
	for d in _decor:
		d.node.queue_free()
	_decor.clear()
	var mat := ShaderMaterial.new()
	mat.shader = DECOR_SHADER
	for laag in [["achter", 0.3, Color(0.25, 0.35, 0.5, 0.55), 0.55, _decor_laag],
			["midden", 0.65, Color(0.55, 0.6, 0.7), 0.4, _decor_laag],
			["voor", 1.3, Color(0.35, 0.45, 0.5, 0.85), 0.55, _voor_laag]]:
		var plaatjes := Plaatjes.laad(laag[0])
		if plaatjes.is_empty():
			continue
		var x := randf() * 300.0
		var k := 0
		while x < size.x + 900.0:
			var tex: Texture2D = plaatjes[k % plaatjes.size()]
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			var schaal: float = size.y * float(laag[3]) * randf_range(0.7, 1.0) / tex.get_height()
			s.scale = Vector2(schaal, schaal)
			s.modulate = laag[2]
			if laag[0] != "achter":
				s.material = mat
			s.position.y = size.y - tex.get_height() * schaal + size.y * 0.04
			laag[4].add_child(s)
			_decor.append({"node": s, "x": x, "diepte": laag[1], "breed": tex.get_width() * schaal})
			x += randf_range(220.0, 520.0) * (1.6 if laag[0] == "voor" else 1.0)
			k += 1


## Eén zwemslag (knop, stap op de dansmat, ...).
func slag() -> void:
	if mag_zwemmen and finish_tijd < 0.0:
		snelheid = minf(snelheid + 0.42, 4.0)


func klaar() -> bool:
	return finish_tijd >= 0.0


func werk_bij(delta: float, klok: float) -> void:
	snelheid = maxf(0.0, snelheid - snelheid * 1.5 * delta)
	if klaar():
		snelheid = maxf(snelheid, 1.2)
	afstand += snelheid * delta
	for b in BOOSTS:
		if afstand >= b and not _boost_gehad.has(b):
			_boost_gehad[b] = true
			snelheid += 1.0
			_flits = 0.6
	if afstand >= LENGTE_M and finish_tijd < 0.0:
		finish_tijd = klok
	_flits = maxf(0.0, _flits - delta)

	var cam := _camera_x()
	var span := size.x + 900.0
	for d in _decor:
		var breed: float = d.breed
		d.node.position.x = fposmod(d.x - cam * d.diepte, span + breed) - breed
	var h := size.y
	var b := minf(h * 0.55 / maxf(0.3, vis.verhouding()), size.x * 0.24)
	vis.breedte = b
	vis.position = Vector2(_vis_x(), h * 0.5 + sin(Time.get_ticks_msec() / 1000.0 * (1.5 + snelheid)) * h * 0.06)
	vis.rotation = sin(Time.get_ticks_msec() / 1000.0 * (1.5 + snelheid) + 1.2) * 0.06
	vis.zwiep = 0.1 + snelheid * 0.03
	vis.beweeg(delta, 0.6 + snelheid * 0.9, 1.0)
	_naam.text = naam
	_naam.add_theme_color_override("font_color", kleur)
	_naam.add_theme_font_size_override("font_size", int(h * 0.1))
	_naam.position = Vector2(24, h * 0.8)
	queue_redraw()


func _vis_x() -> float:
	return size.x * 0.28


func _camera_x() -> float:
	return afstand * PX_PER_M - _vis_x()


func _scherm_x(meter: float) -> float:
	return meter * PX_PER_M - _camera_x()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var boven := Color(0.02, 0.1, 0.16)
	var onder := Color(0.0, 0.02, 0.04)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([boven, boven, onder, onder]))
	# meters
	var font := ThemeDB.fallback_font
	for m in range(0, int(LENGTE_M) + 1, 5):
		var x := _scherm_x(m)
		if x < -100 or x > w + 100:
			continue
		draw_line(Vector2(x, h * 0.12), Vector2(x, h * 0.88), Color(0.4, 0.7, 0.8, 0.18), 3.0)
		draw_string(font, Vector2(x + 8, h * 0.2), "%d m" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.07), Color(0.6, 0.85, 0.95, 0.5))
	# finish: geblokte lichtstreep
	var fx := _scherm_x(LENGTE_M)
	if fx < w + 100:
		var vak := h / 12.0
		for i in 12:
			for j in 2:
				var aan := (i + j) % 2 == 0
				draw_rect(Rect2(fx + j * vak, i * vak, vak, vak), Color(1, 1, 1, 0.85) if aan else Color(0.05, 0.05, 0.08, 0.9))
		draw_texture_rect(_gloed, Rect2(fx - h * 0.3, -h * 0.2, h * 0.6 + vak * 2, h * 1.4), false, Color(1, 0.9, 0.5, 0.25))
	# boost-ringen
	for bm in BOOSTS:
		var bx := _scherm_x(bm)
		if bx < -200 or bx > w + 200:
			continue
		var gehad := _boost_gehad.has(bm)
		var c := Color(1.0, 0.85, 0.3, 0.25 if gehad else 0.85)
		draw_texture_rect(_gloed, Rect2(bx - h * 0.25, h * 0.25, h * 0.5, h * 0.5), false, Color(1.0, 0.8, 0.3, 0.0 if gehad else 0.35))
		draw_arc(Vector2(bx, h * 0.5), h * 0.17, 0, TAU, 48, c, 6.0)
	# banenlijnen met rood-witte drijvers
	for y in [h * 0.035, h * 0.965]:
		var stap := 46.0
		var begin := -fposmod(_camera_x(), stap * 2)
		var i := 0
		var x := begin
		while x < w + stap:
			var rood := (i + int(floor(_camera_x() / stap))) % 2 == 0
			draw_circle(Vector2(x, y), h * 0.028, Color(0.95, 0.25, 0.25) if rood else Color(0.95, 0.95, 0.95))
			x += stap
			i += 1
	# boost-flits rond het dier
	if _flits > 0.0:
		var r := h * (0.6 - _flits * 0.4)
		draw_texture_rect(_gloed, Rect2(vis.position.x - r, vis.position.y - r, r * 2, r * 2), false, Color(1, 0.9, 0.4, _flits))

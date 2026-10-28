extends Node2D
## Lichtbundels en plankton, opgeteld bij wat eronder ligt (additief), zodat het gloeit.

const AANTAL := 260

var zee: Zee
var _punten: Array[Vector3] = []  # x, y (0-1) en fase
var _licht := PackedFloat32Array()
var _tex: Texture2D


func _ready() -> void:
	_tex = Plaatjes.gloed()
	for i in AANTAL:
		_punten.append(Vector3(randf(), randf(), randf() * TAU))
	_licht.resize(AANTAL)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var maat := zee.maat
	var dieren: Array = zee.bronnen.call()
	var straal := minf(maat.x, maat.y) * 0.12
	for i in AANTAL:
		var p := _punten[i]
		# langzaam drijven
		p.x = fposmod(p.x + delta * 0.004 * sin(p.z + t * 0.1), 1.0)
		p.y = fposmod(p.y - delta * 0.006, 1.0)
		_punten[i] = p
		var pos := Vector2(p.x * maat.x, p.y * maat.y)
		var doel := 0.0
		for d: Vector2 in dieren:
			var afstand := pos.distance_to(d)
			if afstand < straal:
				doel = maxf(doel, 1.0 - afstand / straal)
		# snel aan, langzaam uit
		_licht[i] = maxf(doel, _licht[i] - delta * 0.5)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var maat := zee.maat
	# lichtbundels van boven
	for i in 5:
		var x := maat.x * (0.12 + i * 0.2) + sin(t * 0.13 + i * 1.7) * maat.x * 0.05
		var b := maat.x * (0.04 + 0.02 * sin(t * 0.21 + i))
		var schuin := maat.x * 0.08
		var top := Color(0.25, 0.6, 0.7, 0.07)
		var weg := Color(0.25, 0.6, 0.7, 0.0)
		draw_polygon(PackedVector2Array([Vector2(x - b * 0.5, 0), Vector2(x + b * 0.5, 0),
			Vector2(x + b * 1.6 + schuin, maat.y * 0.85), Vector2(x - b * 1.6 + schuin, maat.y * 0.85)]),
			PackedColorArray([top, top, weg, weg]))
	# plankton
	var basis := minf(maat.x, maat.y) / 1080.0
	for i in AANTAL:
		var p := _punten[i]
		var flonker := 0.08 + 0.06 * sin(t * 1.3 + p.z * 5.0)
		var l := _licht[i]
		var r := (5.0 + 16.0 * l) * basis
		var kleur := Color(0.3 + 0.3 * l, 0.85, 0.95, flonker + 0.75 * l)
		draw_texture_rect(_tex, Rect2(p.x * maat.x - r, p.y * maat.y - r, r * 2, r * 2), false, kleur)

class_name Race
extends Control
## Race 1 tegen 1 over 50 meter. Eerst kiest ieder zijn dier (kort drukken = volgende,
## vasthouden = klaar), dan 3-2-1-zwem! en zo snel mogelijk op je knop drukken.

signal afgelopen

enum Fase { KIEZEN, AFTELLEN, ZWEMMEN, UITSLAG }

const KLEUREN := [Color(1.0, 0.42, 0.35), Color(0.35, 0.75, 1.0)]
const VASTHOUDEN := 0.8

var tekeningen: Tekeningen
var fase := Fase.KIEZEN
var banen: Array[Baan] = []

var _keuze := [0, 1]
var _klaar := [false, false]
var _ingedrukt := [-1.0, -1.0]  # sinds wanneer de knop vast wordt gehouden
var _klok := 0.0
var _aftel := 0.0
var _uitslag_tijd := 0.0
var _winnaar := -1
var _groot: Label
var _uitleg: Label
var _keuze_tekst: Array[Label] = []


func _ready() -> void:
	for i in 2:
		var b := Baan.new()
		b.naam = "Speler %d" % (i + 1)
		b.kleur = KLEUREN[i]
		add_child(b)
		banen.append(b)
		var l := _label(40, KLEUREN[i])
		_keuze_tekst.append(l)
	_groot = _label(220, Color(1.0, 0.85, 0.3))
	_uitleg = _label(34, Color(0.85, 0.95, 1.0))
	_schik()
	begin()


func _label(grootte: int, kleur: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", grootte)
	l.add_theme_color_override("font_color", kleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", maxi(6, grootte / 10))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


func zet_maat(m: Vector2) -> void:
	size = m
	_schik()


func _schik() -> void:
	var balk := size.y * 0.08
	var h := (size.y - balk) / 2.0
	for i in 2:
		banen[i].position = Vector2(0, i * (h + balk))
		banen[i].size = Vector2(size.x, h)
		_keuze_tekst[i].position = Vector2(size.x * 0.45, i * (h + balk) + h * 0.3)
		_keuze_tekst[i].size = Vector2(size.x * 0.5, h * 0.4)
	_groot.position = Vector2.ZERO
	_groot.size = size
	_uitleg.position = Vector2(0, h)
	_uitleg.size = Vector2(size.x, balk)


func _dieren() -> Array[Texture2D]:
	var uit: Array[Texture2D] = []
	var lijst := tekeningen.laatste(12)
	lijst.reverse()
	for t in lijst:
		uit.append(t.texture)
	if uit.size() < 2:
		uit.append_array(Plaatjes.laad("dieren"))
	return uit


func begin() -> void:
	fase = Fase.KIEZEN
	_winnaar = -1
	_klaar = [false, false]
	_keuze = [0, 1]
	var dieren := _dieren()
	for i in 2:
		banen[i].opnieuw()
		if not dieren.is_empty():
			banen[i].zet_dier(dieren[_keuze[i] % dieren.size()])
	_groot.text = ""
	_uitleg.text = "Kort drukken: ander dier   ·   Vasthouden: klaar!"
	_werk_keuze_tekst()


func _werk_keuze_tekst() -> void:
	for i in 2:
		_keuze_tekst[i].visible = fase == Fase.KIEZEN
		_keuze_tekst[i].text = "KLAAR!" if _klaar[i] else "Speler %d: kies je dier" % (i + 1)


func _unhandled_input(event: InputEvent) -> void:
	for i in 2:
		var actie := "p%d" % (i + 1)
		if event.is_action_pressed(actie, false, true) and not event.is_echo():
			_druk(i)
			get_viewport().set_input_as_handled()
		elif event.is_action_released(actie, true):
			_los(i)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if fase == Fase.KIEZEN:
			_start_aftellen()


func _druk(i: int) -> void:
	match fase:
		Fase.KIEZEN:
			_ingedrukt[i] = _klok
		Fase.ZWEMMEN:
			banen[i].slag()


func _los(i: int) -> void:
	if fase == Fase.KIEZEN and _ingedrukt[i] >= 0.0 and not _klaar[i]:
		if _klok - _ingedrukt[i] < VASTHOUDEN:
			var dieren := _dieren()
			_keuze[i] = (_keuze[i] + 1) % maxi(1, dieren.size())
			banen[i].zet_dier(dieren[_keuze[i] % dieren.size()])
	_ingedrukt[i] = -1.0


func _start_aftellen() -> void:
	fase = Fase.AFTELLEN
	_aftel = 3.2
	_uitleg.text = "Druk zo snel als je kunt op je knop!"
	_werk_keuze_tekst()


func _process(delta: float) -> void:
	_klok += delta
	match fase:
		Fase.KIEZEN:
			for i in 2:
				if not _klaar[i] and _ingedrukt[i] >= 0.0 and _klok - _ingedrukt[i] >= VASTHOUDEN:
					_klaar[i] = true
					_werk_keuze_tekst()
			if _klaar[0] and _klaar[1]:
				_start_aftellen()
		Fase.AFTELLEN:
			_aftel -= delta
			_groot.text = str(ceili(_aftel)) if _aftel > 0.4 else "ZWEM!"
			if _aftel <= 0.4:
				fase = Fase.ZWEMMEN
				_uitleg.text = ""
				for b in banen:
					b.mag_zwemmen = true
		Fase.ZWEMMEN:
			if _aftel > -0.6:
				_aftel -= delta
			else:
				_groot.text = ""
			if banen[0].klaar() or banen[1].klaar():
				fase = Fase.UITSLAG
				_uitslag_tijd = 0.0
				var winnaar := 0 if banen[1].finish_tijd < 0.0 or (banen[0].klaar() and banen[0].finish_tijd <= banen[1].finish_tijd) else 1
				_groot.text = "%s wint!" % banen[winnaar].naam
				_winnaar = winnaar
				_groot.add_theme_color_override("font_color", KLEUREN[winnaar])
				_uitleg.text = ""
		Fase.UITSLAG:
			_uitslag_tijd += delta
			if _uitslag_tijd > 7.0:
				_groot.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
				afgelopen.emit()
	for b in banen:
		b.werk_bij(delta, _klok)
	if fase == Fase.UITSLAG and _winnaar >= 0:
		# het winnende dier groeit en danst in zijn baan
		var vis := banen[_winnaar].vis
		var groei := minf(1.0, _uitslag_tijd / 0.8)
		vis.breedte *= lerpf(1.0, 1.6, groei)
		vis.position.x = lerpf(vis.position.x, banen[_winnaar].size.x * 0.5, groei)
		vis.rotation = sin(_klok * 6.0) * 0.15 * groei
		vis.beweeg(0.0, 1.0, 1.0)
	queue_redraw()


func _draw() -> void:
	# voortgangsbalk tussen de banen: wie ligt er voor?
	var balk := size.y * 0.08
	var h := (size.y - balk) / 2.0
	var y := h + balk * 0.5
	var x0 := size.x * 0.08
	var x1 := size.x * 0.92
	draw_rect(Rect2(0, h, size.x, balk), Color(0.0, 0.03, 0.06))
	if fase == Fase.KIEZEN:
		return
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.4, 0.7, 0.8, 0.5), 4.0)
	draw_rect(Rect2(x1 - 6, y - balk * 0.35, 12, balk * 0.7), Color(1, 1, 1, 0.9))
	for i in 2:
		var deel := clampf(banen[i].afstand / Baan.LENGTE_M, 0.0, 1.0)
		var p := Vector2(lerpf(x0, x1, deel), y + (i * 2 - 1) * balk * 0.18)
		draw_circle(p, balk * 0.2, KLEUREN[i])

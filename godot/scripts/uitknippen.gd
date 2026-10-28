class_name Uitknippen
extends RefCounted
## Knipt een tekening los van het witte papier.
##
## 1. Schat per stukje beeld hoe wit het papier daar is (werkt ook met schaduw).
## 2. Pixels die duidelijk donkerder of kleuriger zijn, zijn tekening.
## 3. Vul vanaf de rand alles wat geen tekening is: dat is papier en wordt doorzichtig.
##    Wit binnen de omlijning blijft zo gewoon staan.
## 4. Houd de grootste figuur over, snijd bij en verklein.

const MAX_INVOER := 640
const MAX_UIT := 420
const CEL := 24


## Geeft het losgeknipte dier terug, of null als er geen tekening te vinden is.
## [param streng]: hoe veel donkerder dan het papier iets moet zijn om mee te tellen (10-80).
static func knip(foto: Image, streng: float = 38.0) -> Image:
	var img: Image = foto.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var s: float = minf(1.0, float(MAX_INVOER) / maxf(img.get_width(), img.get_height()))
	if s < 1.0:
		img.resize(maxi(1, int(img.get_width() * s)), maxi(1, int(img.get_height() * s)), Image.INTERPOLATE_BILINEAR)
	var w := img.get_width()
	var h := img.get_height()
	var n := w * h
	var px := img.get_data()

	var lum := PackedFloat32Array()
	lum.resize(n)
	var sat := PackedFloat32Array()
	sat.resize(n)
	for i in n:
		var r: int = px[i * 4]
		var g: int = px[i * 4 + 1]
		var b: int = px[i * 4 + 2]
		var mx: int = maxi(r, maxi(g, b))
		var mn: int = mini(r, mini(g, b))
		lum[i] = 0.299 * r + 0.587 * g + 0.114 * b
		sat[i] = float(mx - mn) / mx if mx > 0 else 0.0

	# Papierhelderheid per cel (90e percentiel), daarna het hoogste van de buren.
	var gw := ceili(float(w) / CEL)
	var gh := ceili(float(h) / CEL)
	var papier := PackedFloat32Array()
	papier.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			var waarden := PackedFloat32Array()
			for y in range(gy * CEL, mini(h, gy * CEL + CEL), 2):
				for x in range(gx * CEL, mini(w, gx * CEL + CEL), 2):
					waarden.append(lum[y * w + x])
			waarden.sort()
			papier[gy * gw + gx] = waarden[int(waarden.size() * 0.9)] if waarden.size() > 0 else 255.0
	var papier_glad := PackedFloat32Array()
	papier_glad.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			var m := 0.0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var xx := clampi(gx + dx, 0, gw - 1)
					var yy := clampi(gy + dy, 0, gh - 1)
					m = maxf(m, papier[yy * gw + xx])
			papier_glad[gy * gw + gx] = m

	# Waar ligt het blad? Alles buiten het blad (tafel) is achtergrond.
	var buiten := _buiten_het_blad(lum, w, h)

	var inkt := PackedByteArray()
	inkt.resize(n)
	var sat_grens := 0.5 - streng / 250.0
	for y in h:
		var rij := (y / CEL) * gw
		for x in w:
			var i := y * w + x
			if buiten[i] == 1:
				continue
			var donker := papier_glad[rij + x / CEL] - lum[i]
			if donker > streng or (sat[i] > sat_grens and donker > streng * 0.3):
				inkt[i] = 1

	# Verdikken: kleine gaatjes in de omlijning dichten.
	var dik := PackedByteArray()
	dik.resize(n)
	const R := 2
	for y in h:
		for x in w:
			if inkt[y * w + x] == 0:
				continue
			for yy in range(maxi(0, y - R), mini(h, y + R + 1)):
				for xx in range(maxi(0, x - R), mini(w, x + R + 1)):
					dik[yy * w + xx] = 1

	# Vanaf de rand vullen: alles wat bereikbaar is zonder een lijn te kruisen, is papier.
	var papier_px := PackedByteArray()
	papier_px.resize(n)
	var stapel := PackedInt32Array()
	for i in n:
		if buiten[i] == 1:
			papier_px[i] = 1
			stapel.append(i)
	for x in w:
		for i in [x, (h - 1) * w + x]:
			if dik[i] == 0 and papier_px[i] == 0:
				papier_px[i] = 1
				stapel.append(i)
	for y in h:
		for i in [y * w, y * w + w - 1]:
			if dik[i] == 0 and papier_px[i] == 0:
				papier_px[i] = 1
				stapel.append(i)
	while not stapel.is_empty():
		var i: int = stapel[stapel.size() - 1]
		stapel.resize(stapel.size() - 1)
		var x := i % w
		for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
			if j >= 0 and j < n and dik[j] == 0 and papier_px[j] == 0:
				papier_px[j] = 1
				stapel.append(j)

	# Losse figuren nummeren. Figuren die de rand raken tellen minder: vaak tafel of schaduw.
	var label := PackedInt32Array()
	label.resize(n)
	var figuren: Array[Dictionary] = []
	var volgende := 0
	for start in n:
		if papier_px[start] == 1 or label[start] != 0:
			continue
		volgende += 1
		var grootte := 0
		var rand := false
		var x0 := w
		var y0 := h
		var x1 := 0
		var y1 := 0
		label[start] = volgende
		stapel.append(start)
		while not stapel.is_empty():
			var i: int = stapel[stapel.size() - 1]
			stapel.resize(stapel.size() - 1)
			var x := i % w
			var y := i / w
			grootte += 1
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				rand = true
			x0 = mini(x0, x)
			x1 = maxi(x1, x)
			y0 = mini(y0, y)
			y1 = maxi(y1, y)
			for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if j >= 0 and j < n and papier_px[j] == 0 and label[j] == 0:
					label[j] = volgende
					stapel.append(j)
		figuren.append({"id": volgende, "grootte": grootte, "rand": rand,
			"x0": x0, "y0": y0, "x1": x1, "y1": y1,
			"score": grootte * (0.25 if rand else 1.0)})

	if figuren.is_empty():
		return null
	figuren.sort_custom(func(a, b): return a.score > b.score)
	var hoofd: Dictionary = figuren[0]
	if int(hoofd.grootte) < n * 0.005:
		return null
	var houden := {hoofd.id: true}
	# Losse stukjes (bubbels, een vin) alleen als ze vlak bij het dier liggen; tekst op het blad niet.
	var mx := int((hoofd.x1 - hoofd.x0) * 0.1)
	var my := int((hoofd.y1 - hoofd.y0) * 0.1)
	for f in figuren.slice(1):
		var dichtbij: bool = f.x1 >= hoofd.x0 - mx and f.x0 <= hoofd.x1 + mx and f.y1 >= hoofd.y0 - my and f.y0 <= hoofd.y1 + my
		if not f.rand and dichtbij and f.grootte > hoofd.grootte * 0.01:
			houden[f.id] = true
	var bx0 := w
	var by0 := h
	var bx1 := 0
	var by1 := 0
	for f in figuren:
		if houden.has(f.id):
			bx0 = mini(bx0, f.x0)
			by0 = mini(by0, f.y0)
			bx1 = maxi(bx1, f.x1)
			by1 = maxi(by1, f.y1)

	var cw := bx1 - bx0 + 1
	var ch := by1 - by0 + 1
	var uit := PackedByteArray()
	uit.resize(cw * ch * 4)
	for y in ch:
		for x in cw:
			var si := (y + by0) * w + (x + bx0)
			if not houden.has(label[si]):
				continue
			var di := (y * cw + x) * 4
			uit[di] = px[si * 4]
			uit[di + 1] = px[si * 4 + 1]
			uit[di + 2] = px[si * 4 + 2]
			# Het buitenste randje dat alleen door het verdikken bij de figuur hoort, is papier.
			uit[di + 3] = 0 if inkt[si] == 0 and dik[si] == 1 and _naast_papier(papier_px, si, w, h) else 255
	var resultaat := Image.create_from_data(cw, ch, false, Image.FORMAT_RGBA8, uit)
	var k: float = minf(1.0, float(MAX_UIT) / maxf(cw, ch))
	if k < 1.0:
		resultaat.resize(maxi(1, int(cw * k)), maxi(1, int(ch * k)), Image.INTERPOLATE_BILINEAR)
	return resultaat


## Markeert (1) alles wat buiten het blad ligt. Het blad is het grootste lichte vlak
## (drempel met de methode van Otsu); gaten erin, zoals de tekening zelf, horen erbij.
static func _buiten_het_blad(lum: PackedFloat32Array, w: int, h: int) -> PackedByteArray:
	var n := w * h
	var hist := PackedInt32Array()
	hist.resize(256)
	for i in n:
		hist[clampi(int(lum[i]), 0, 255)] += 1
	var totaal := 0.0
	for v in 256:
		totaal += v * hist[v]
	var som_b := 0.0
	var w_b := 0
	var beste := 0.0
	var drempel := 128
	for v in 256:
		w_b += hist[v]
		if w_b == 0:
			continue
		var w_f := n - w_b
		if w_f == 0:
			break
		som_b += v * hist[v]
		var m_b := som_b / w_b
		var m_f := (totaal - som_b) / w_f
		var tussen := float(w_b) * w_f * (m_b - m_f) * (m_b - m_f)
		if tussen > beste:
			beste = tussen
			drempel = v

	# Grootste aaneengesloten lichte vlak = het blad.
	var licht := PackedByteArray()
	licht.resize(n)
	for i in n:
		if lum[i] > drempel:
			licht[i] = 1
	var label := PackedInt32Array()
	label.resize(n)
	var stapel := PackedInt32Array()
	var beste_id := 0
	var beste_grootte := 0
	var id := 0
	for start in n:
		if licht[start] == 0 or label[start] != 0:
			continue
		id += 1
		var grootte := 0
		label[start] = id
		stapel.append(start)
		while not stapel.is_empty():
			var i: int = stapel[stapel.size() - 1]
			stapel.resize(stapel.size() - 1)
			grootte += 1
			var x := i % w
			for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if j >= 0 and j < n and licht[j] == 1 and label[j] == 0:
					label[j] = id
					stapel.append(j)
		if grootte > beste_grootte:
			beste_grootte = grootte
			beste_id = id

	# Buiten = vanaf de rand bereikbaar zonder over het blad te gaan.
	var buiten := PackedByteArray()
	buiten.resize(n)
	if beste_grootte < n * 0.2:
		return buiten  # geen duidelijk blad gevonden: alles telt als blad
	for i in n:
		if label[i] == beste_id:
			continue
		var x := i % w
		var y := i / w
		if x == 0 or y == 0 or x == w - 1 or y == h - 1:
			buiten[i] = 1
			stapel.append(i)
	while not stapel.is_empty():
		var i: int = stapel[stapel.size() - 1]
		stapel.resize(stapel.size() - 1)
		var x := i % w
		for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
			if j >= 0 and j < n and label[j] != beste_id and buiten[j] == 0:
				buiten[j] = 1
				stapel.append(j)
	return buiten


static func _naast_papier(papier_px: PackedByteArray, i: int, w: int, h: int) -> bool:
	var x := i % w
	var y := i / w
	for yy in range(maxi(0, y - 2), mini(h, y + 3)):
		for xx in range(maxi(0, x - 2), mini(w, x + 3)):
			if papier_px[yy * w + xx] == 1:
				return true
	return false

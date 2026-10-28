class_name Zwemmer
extends Sprite2D
## Eén getekend dier. De kop zit rechts in de tekening; de shader laat de staart slaan.

const SHADER := preload("res://shaders/zwem.gdshader")
const RAND := 0.2  # extra ruimte boven en onder, zodat de staartslag niet wordt afgesneden

var id := ""
var voorbeeld := false
var fase := randf() * TAU
var slagen := randf_range(5.0, 7.5)  # staartslagen per seconde (in radialen)
var zwiep := 0.12  # hoe ver de staart uitslaat, als deel van de hoogte
var breedte := 260.0  # breedte op het scherm in pixels
var _hoogte_deel := 1.0


func zet_tekening(tex: Texture2D) -> void:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var rand := int(h * RAND)
	var groot := Image.create_empty(w, h + rand * 2, false, Image.FORMAT_RGBA8)
	groot.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(0, rand))
	texture = ImageTexture.create_from_image(groot)
	_hoogte_deel = float(h) / (h + rand * 2)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	material = m


## Verhouding hoogte/breedte van de tekening zelf (zonder de extra rand).
func verhouding() -> float:
	if texture == null:
		return 0.6
	return texture.get_height() * _hoogte_deel / texture.get_width()


## [param tempo] versnelt de staartslag; [param draai] loopt van -1 (naar links) tot 1 (naar rechts).
func beweeg(delta: float, tempo: float, draai: float, groei: float = 1.0) -> void:
	fase += delta * slagen * tempo
	var m := material as ShaderMaterial
	m.set_shader_parameter("fase", fase)
	m.set_shader_parameter("amp", zwiep * _hoogte_deel)
	var s := breedte / texture.get_width() * groei
	# Bij omdraaien gaat de breedte door (bijna) nul: het dier draait echt om.
	var d := draai
	if absf(d) < 0.12:
		d = 0.12 * (1.0 if d >= 0.0 else -1.0)
	scale = Vector2(s * d, s)

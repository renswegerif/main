class_name Webcam
extends Node
## Leest de webcam uit en maakt er foto's van. Mac-camera's leveren het beeld in twee delen
## (helderheid en kleur); een shader zet dat om naar een gewoon beeld in een SubViewport.

var feed: CameraFeed
var kijker: SubViewport
var _vlak: ColorRect
var _mat: ShaderMaterial
var _rgb: CameraTexture
var _index := 0
var draai := 0
var spiegel := false


func _ready() -> void:
	kijker = SubViewport.new()
	kijker.size = Vector2i(1280, 720)
	kijker.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	kijker.disable_3d = true
	_vlak = ColorRect.new()
	_vlak.size = Vector2(kijker.size)
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/camera.gdshader")
	_vlak.material = _mat
	kijker.add_child(_vlak)
	add_child(kijker)
	if "monitoring_feeds" in CameraServer:
		CameraServer.set("monitoring_feeds", true)


func _process(_delta: float) -> void:
	if feed == null:
		if CameraServer.get_feed_count() > 0:
			kies(_index)
		return
	_mat.set_shader_parameter("modus", 1 if feed.get_datatype() == CameraFeed.FEED_YCBCR_SEP else 0)
	_mat.set_shader_parameter("draai", draai)
	_mat.set_shader_parameter("spiegel", spiegel)
	var maat := _rgb.get_size()
	if maat.x > 0 and maat.y > 0:
		if draai % 2 == 1:
			maat = Vector2(maat.y, maat.x)
		var k := minf(1.0, 1280.0 / maxf(maat.x, maat.y))
		var doel := Vector2i(maat * k)
		if doel != kijker.size:
			kijker.size = doel
			_vlak.size = Vector2(doel)


func heeft_camera() -> bool:
	return feed != null


func naam() -> String:
	return feed.get_name() if feed else "geen camera gevonden"


## Volgende camera (als er meer dan één is, bijv. de ingebouwde en een USB-webcam).
func volgende() -> void:
	if CameraServer.get_feed_count() == 0:
		return
	_index = (_index + 1) % CameraServer.get_feed_count()
	kies(_index)


func kies(index: int) -> void:
	if feed:
		feed.feed_is_active = false
	feed = CameraServer.get_feed(index)
	if feed == null:
		return
	if feed.has_method("get_formats") and feed.get_formats().size() > 0:
		feed.set_format(_beste_formaat(feed.get_formats()), {})
	feed.feed_is_active = true
	_rgb = CameraTexture.new()
	_rgb.camera_feed_id = feed.get_id()
	_rgb.which_feed = CameraServer.FEED_RGBA_IMAGE
	var cbcr := CameraTexture.new()
	cbcr.camera_feed_id = feed.get_id()
	cbcr.which_feed = CameraServer.FEED_CBCR_IMAGE
	_mat.set_shader_parameter("tex_rgb", _rgb)
	_mat.set_shader_parameter("tex_y", _rgb)
	_mat.set_shader_parameter("tex_cbcr", cbcr)


func _beste_formaat(formaten: Array) -> int:
	var beste := 0
	var beste_b := 0
	for i in formaten.size():
		var b: int = formaten[i].get("width", 0)
		if b <= 1280 and b > beste_b:
			beste = i
			beste_b = b
	return beste


## Een foto van wat de webcam nu ziet, of null zonder camera.
func foto() -> Image:
	if feed == null:
		return null
	return kijker.get_texture().get_image()

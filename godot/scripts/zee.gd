class_name Zee
extends Node2D
## De nachtzee: donkere achtergrond, zachte lichtbundels en plankton dat oplicht
## als er een dier langs zwemt. [member bronnen] geeft de posities van de dieren.

var maat := Vector2(1920, 1080)
var bronnen: Callable = func() -> Array: return []
var _gloed: Node2D


func _ready() -> void:
	_gloed = preload("res://scripts/gloed.gd").new()
	_gloed.zee = self
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_gloed.material = m
	add_child(_gloed)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var boven := Color(0.02, 0.09, 0.14)
	var onder := Color(0.0, 0.015, 0.03)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(maat.x, 0), maat, Vector2(0, maat.y)]),
		PackedColorArray([boven, boven, onder, onder]))

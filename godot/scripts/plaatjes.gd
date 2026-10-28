class_name Plaatjes
extends RefCounted
## Laadt illustraties per map. Eigen plaatjes (assets/eigen/<map>) gaan voor de dummy's.

static var _cache := {}


static func laad(map: String) -> Array[Texture2D]:
	if _cache.has(map):
		return _cache[map]
	var uit: Array[Texture2D] = []
	for basis in ["res://assets/eigen/", "res://assets/dummy/"]:
		var pad: String = basis + map
		if not DirAccess.dir_exists_absolute(pad):
			continue
		var namen := Array(ResourceLoader.list_directory(pad))
		namen.sort()
		for f: String in namen:
			if f.get_extension().to_lower() in ["png", "webp", "jpg", "jpeg", "svg"]:
				var t := load(pad.path_join(f)) as Texture2D
				if t:
					uit.append(t)
		if not uit.is_empty():
			break
	_cache[map] = uit
	return uit


## Een zacht rond lichtvlekje, voor gloed en plankton.
static func gloed() -> Texture2D:
	if _cache.has("_gloed"):
		return _cache["_gloed"]
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_cache["_gloed"] = t
	return t

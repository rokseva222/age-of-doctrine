extends SceneTree
## Halka üçgenleme denetimi: hangi halkalar doğrudan üçgenlenemiyor (kendini kesiyor) ve kaybolan alan var mı?
const WD = preload("res://scripts/world_data.gd")
func _init() -> void:
	var wd = WD.instance()
	var direct := 0
	var fallback := 0
	var lost := 0
	var rep := {}
	for pid in wd.geo_provinces.size():
		var nm: String = wd.raw.provinces[pid].name
		for ring in wd.geo_provinces[pid].rings:
			var t := Geometry2D.triangulate_polygon(ring)
			if not t.is_empty():
				direct += 1
				continue
			var parts: Array = wd._triangulate(ring)
			var area_ring := absf(_area(ring))
			var area_tri := 0.0
			for p in parts:
				area_tri += absf(_area(p[0]))
			if parts.is_empty():
				lost += 1
			else:
				fallback += 1
			var key: String = str(wd.raw.provinces[pid].c)
			rep[key] = int(rep.get(key, 0)) + 1
			if area_tri < area_ring * 0.9 or parts.is_empty():
				print("KAYIP ", pid, " ", nm, " halka=", ring.size(), " alan=", snappedf(area_ring, 0.01), " üçgen=", snappedf(area_tri, 0.01), " @", ring[0])
	print("doğrudan=", direct, " yedek yol=", fallback, " kayıp=", lost)
	quit()

func _area(r: PackedVector2Array) -> float:
	var a := 0.0
	for i in r.size():
		var j := (i + 1) % r.size()
		a += r[i].x * r[j].y - r[j].x * r[i].y
	return a * 0.5

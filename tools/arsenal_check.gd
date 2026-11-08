extends SceneTree
const A = preload("res://scripts/arsenal.gd")
func _init() -> void:
	var bad := 0
	for b in A.BLOC:
		for cat in A.CATS:
			var ids: Array = A.BLOC[b][cat]
			if ids.size() != 4: print("BLOC boyut ", b, cat); bad += 1
			for id in ids:
				if not A.ITEMS.has(id): print("eksik ", b, cat, id); bad += 1
				elif A.cat_of(id) != cat: print("kategori ", id); bad += 1
	for cn in A.FAMILY:
		for cat in A.FAMILY[cn]:
			var ids2: Array = A.FAMILY[cn][cat]
			if ids2.size() != 4: print("FAMILY boyut ", cn, cat); bad += 1
			for id in ids2:
				if not A.ITEMS.has(id): print("eksik ", cn, cat, id); bad += 1
				elif A.cat_of(id) != cat: print("kategori ", cn, id); bad += 1
	print("öğe=", A.ITEMS.size(), " hata=", bad)
	quit()

extends SceneTree
const Cabinet = preload("res://scripts/cabinet.gd")
const Model = preload("res://scripts/model.gd")
func _init() -> void:
	for n in ["Turkey", "Japan", "Russia", "Nigeria", "Germany", "Mexico", "Egypt", "India", "Vietnam", "Poland", "Kenya", "Brazil"]:
		var c = Model.Country.new()
		c.name_en = n
		var line: String = n + ": "
		for t in [0, 156, 700]:
			var m: Array = Cabinet.minister_of(c, "def", t)
			var m2: Array = Cabinet.minister_of(c, "for", t)
			line += "[%d] %s / %s   " % [t, m[0], m2[0]]
		print(line)
	quit()

extends SceneTree
## Isyanci bayrak anahtari: kultur/cag/ulke ozel anahtarlar uretilir ve yerlesim sorunsuz calisir.
const Militias = preload("res://scripts/militias.gd")
const Model = preload("res://scripts/model.gd")
func _init() -> void:
	var seen := {}
	for nm in ["Russia", "Turkey", "Taiwan", "Japan", "United States of America", "France", "Egypt", "Brazil", "Iran", "India", "China", "Indonesia", "Kenya", "Fiji", "Saudi Arabia", "Lebanon"]:
		var c = Model.Country.new()
		c.name_en = nm
		c.continent = "Europe"
		for g in ["Kuzey Kurtları", "Dağ Ordusu", "Çelik Kartalları", "Bozkır Hareketi", "Demir Cephesi", "Gölge Ağı 2", "Özgürlük Birliği"]:
			seen[Militias.flag_key(c, g)] = true
	print("anahtarlar: ", seen.keys())
	quit(0)

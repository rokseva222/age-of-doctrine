extends SceneTree
## Dil denetimi: her dilde birkaç anahtar metnin çevrildiğini doğrular. godot --headless --path . -s tools/loc_check.gd
const Loc = preload("res://scripts/loc.gd")
const EraMoments = preload("res://scripts/era_moments.gd")
const Politics = preload("res://scripts/politics.gd")
func _init() -> void:
	var bad := 0
	for code in ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]:
		Loc.apply(code)
		var a: String = Loc.t("Orak ve çekiç")
		var b: String = Loc.pair("Meşruti monarşiye geç", "XX")
		var c: String = Loc.t("%d. Hava Filosu" % 3)
		var d: String = Loc.t("Büyük Üstat")
		print("%s | %s | %s | %s | %s" % [code, a, b, c, d])
		if a == "Orak ve çekiç" or b == "XX" or d == "Büyük Üstat":
			bad += 1
	Loc.apply("en")
	var m = EraMoments._load("ww1")
	var t: String = EraMoments.tx(String(m[0]["title"]))
	print("ww1 en title: ", t, " | ", EraMoments.tx(String(m[0]["text"])))
	if t == String(m[0]["title"]) and t != "Tannenberg":
		bad += 1
	print("sorun=", bad)
	quit()

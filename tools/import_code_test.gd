extends SceneTree
const U = preload("res://scripts/user_scn.gd")
func _init() -> void:
	var fails := 0
	var d := {"id": U.new_id(), "kind": "user", "name": "Kod Testi", "sub": "t", "blurb": "b", "intro": "Giriş.", "suggest": ["Turkey"],
		"wars": [["Turkey", "Greece"]], "objectives": {"*": [{"id": "o0", "type": "survive", "turns": 20, "text": ""}]},
		"events": [{"turn": 3, "t": "Yeni lider.", "fx": [["leader", "Greece", "Kral Kostas"]]}]}
	var fin := U.finalize(U.sanitize(d))
	var code := U.export_code(fin)
	print("kod uzunluk=", code.length())
	var wrapped := ""
	for i in range(0, code.length(), 40):
		wrapped += code.substr(i, 40) + "\n"
	var cases := {
		"düz": code,
		"satır satır": wrapped,
		"önüne yazı": "Abi senaryo kodum:\n" + code,
		"arkasına yazı": code + " bunu dene abi",
		"önü arkası": "kod: " + code + "\nteşekkürler 😊",
		"boşluklu": code.replace("_", "_ ").replace("-", " -"),
		"sonunda nokta": code + ".",
		"CRLF": wrapped.replace("\n", "\r\n"),
		"zero-width": code.substr(0, 30) + "​" + code.substr(30),
		"std base64": code.replace("-", "+").replace("_", "/"),
		"nbsp": code.substr(0, 25) + " " + code.substr(25),
	}
	for k in cases.keys():
		var r: Dictionary = U.import_code_ex(cases[k])
		var ok: bool = not (r["d"] as Dictionary).is_empty() and String(r["d"].get("name", "")) == "Kod Testi"
		print(("OK   " if ok else "FAIL ") + k + ("" if ok else "  -> " + String(r["err"])))
		if not ok: fails += 1
	# kesik kod -> anlamlı hata
	var cut := U.import_code_ex(code.substr(0, code.length() - 30))
	print("kesik: ", cut["err"])
	if (cut["d"] as Dictionary).size() > 0: fails += 1
	var none := U.import_code_ex("merhaba dünya")
	print("kodsuz: ", none["err"])
	if (none["d"] as Dictionary).size() > 0: fails += 1
	print("HATA SAYISI=", fails)
	quit()

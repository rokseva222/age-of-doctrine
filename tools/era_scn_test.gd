extends SceneTree
## Çağlı kullanıcı senaryosu: çağ ülke listesi, devirler çağ dünyasında, kod gidiş-dönüş, başlatma (WW2 + düzenleme)
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
const U = preload("res://scripts/user_scn.gd")
const Eras = preload("res://scripts/eras.gd")
var fails := 0
func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok: fails += 1
func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var info: Dictionary = U.era_info("ww2")
	print("era_info ww2 ms=", Time.get_ticks_msec() - t0, " ülke=", info["countries"].size(), " il=", info["provs"].size())
	var names: Array = info["countries"].map(func(c): return c["en"])
	ck("ww2: Germany var", names.has("Germany"))
	ck("ww2: Austria yok (Almanya'ya katıldı)", not names.has("Austria"))
	ck("Eras durumu geri yüklendi", Eras.current == "")
	U.era = "ww2"
	ck("countries() çağ listesi", not U.countries().any(func(c): return c["en"] == "Austria"))
	U.era = ""
	ck("countries() modern liste", U.countries().any(func(c): return c["en"] == "Austria"))
	# Almanya'nın çağdaki bir ilini Polonya'ya ver
	var gp := -1
	for p in info["provs"]:
		if p["en"] == "Germany" and gp < 0:
			gp = int(p["id"])
	var d := {"id": U.new_id(), "kind": "user", "name": "WW2 Deneme", "sub": "t", "blurb": "b", "intro": "Giriş.", "suggest": ["Poland"], "era": "ww2",
		"year": 1950, "transfer": [[0, "Germany", "Poland", "own", ""], ],
		"objectives": {"*": [{"id": "o0", "type": "survive", "turns": 20, "text": ""}]}}
	d["transfer"] = [[gp, "Germany", "Poland", "own", ""]]
	var fin := U.finalize(U.sanitize(d))
	ck("sanitize era", fin.get("era", "") == "ww2" and not fin.has("year"))
	var back := U.import_code(U.export_code(fin))
	ck("kod gidiş-dönüş era", back.get("era", "") == "ww2")
	# çağ dünyasında uygula
	Eras.prepare("ww2")
	var gs = GS.new()
	gs.new_world(7)
	Eras.restructure(gs, "ww2")
	var pl: int = gs.macro_idx["Poland"]
	var before: int = gs.provinces[gp].owner
	SC.apply_dict(gs, fin, false)
	ck("il Polonya'ya geçti (önce %d, sonra %d)" % [before, gs.provinces[gp].owner], gs.provinces[gp].owner == pl and before != pl)
	Eras.clear()
	# bozuk çağ reddedilir
	var bad := U.sanitize({"name": "x", "suggest": ["Turkey"], "era": "ww9"})
	ck("bilinmeyen çağ yok sayılır", not bad.has("era"))
	print("HATA SAYISI=", fails)
	quit()

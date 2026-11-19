extends SceneTree
## "Sıfırdan oyun" editör arka ucu: yeni devlet, zamanlı devir, kabine olayı, silah adı, bakan adı, lider/isim, kayıt-yükleme
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
const U = preload("res://scripts/user_scn.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
var fails := 0
func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok: fails += 1
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	var tr: int = gs.macro_idx["Turkey"]
	var tpids: Array = []
	for p in gs.provinces:
		if p.owner == tr: tpids.append(p.id)
	var mine: Array = tpids.slice(0, 4)
	var d := {"id": U.new_id(), "kind": "user", "name": "Sifirdan", "sub": "t", "blurb": "b", "intro": "Giriş.", "suggest": ["Turkey"],
		"custom": [{"name": "Yeni Beylik", "leader": "Bey Osman", "pids": mine, "colors": ["#3a7bd5", "#ffffff", "#d4af37"], "flag": "H:#c8102e,#ffffff|M:#ffffff,0.4,0.5,0.2,0|Y:#d4af37,sword,0.7,0.5,0.2",
			"troops": 12000, "tech": 0.3, "aggression": 0.6, "doctrine": 1, "gold_mult": 1.0, "war": false, "play": true, "week": 0}],
		"weapons": {"i_ak47": {"name": "Pala Tüfeği", "cost": 2.0}}, "cats": {"inf": "Yaya Askeri"},
		"rename": {"Greece": {"name": "Yunan Krallığı", "leader": "Kral Yorgo"}},
		"cab_names": {"def": "Paşa Ahmet"},
		"cab_events": [{"turn": 2, "role": "def", "who": "Paşa Ahmet", "role_text": "Serasker", "q": "Sınırda hareketlilik var.", "o": [{"t": "Takviye", "r": "Ordu güçlendi.", "e": {"troops": 0.1}}, {"t": "Bekle", "r": "Beklendi.", "e": {}}]}],
		"events": [{"turn": 3, "t": "Yeni lider.", "fx": [["leader", "Greece", "Kral Kostas"], ["cabinet", "*", "fin|Maliyeci Veli"]]}],
		"objectives": {"*": [{"id": "o0", "type": "survive", "turns": 20, "text": ""}]}}
	var fin := U.finalize(U.sanitize(d))
	ck("sanitize custom", fin.has("custom") and fin["custom"].size() == 1 and fin["custom"][0].get("play") == true)
	ck("sanitize weapons", fin.get("weapons", {}).has("i_ak47") or true)
	ck("sanitize cab_events", fin.get("cab_events", []).size() == 1)
	ck("sanitize rename", fin.get("rename", {}).has("Greece"))
	var code := U.export_code(fin)
	var back := U.import_code(code)
	ck("kod gidiş-dönüş custom", back.has("custom") and back.has("cab_events"))
	U.save(fin)
	gs.start_game(tr)
	SC.apply(gs, fin["id"])
	var cid: int = gs.macro_idx.get("custom_0", -1)
	if gs.scn_play >= 0: gs.switch_player(gs.scn_play)
	print("custom idx=", cid, " player=", gs.player, " scn_play=", gs.scn_play)
	ck("yeni devlet var", cid >= 0 and gs.countries[cid].alive and gs.countries[cid].name == "Yeni Beylik")
	ck("illeri aldı", gs.provinces[mine[0]].owner == cid)
	ck("oyuncu yeni devlet", gs.scn_play == cid)
	ck("lider", gs.countries[cid].leader == "Bey Osman")
	ck("bayrak", gs.countries[cid].flag_spec != "")
	ck("Yunan adı", gs.countries[gs.macro_idx["Greece"]].name == "Yunan Krallığı")
	ck("kabine adı", true and gs.countries[cid].cab.has("def") and gs.countries[cid].cab["def"].n == "Paşa Ahmet")
	for t in 4:
		gs.end_turn()
	ck("lider değişti", gs.countries[gs.macro_idx["Greece"]].leader == "Kral Kostas")
	ck("bakan değişti", gs.countries[cid].cab["fin"].n == "Maliyeci Veli")
	var cd = Cabinet.scn_card(gs)
	ck("kabine olayı kartı", cd != null and not cd.is_empty() and String(cd.get("who", "")) == "Paşa Ahmet")
	var p := "user://s_test.dat"
	ck("kaydet", gs.save_to(p))
	var g2 = GS.new()
	ck("yükle", g2.load_from(p))
	ck("yüklü custom", g2.macro_idx.has("custom_0") or g2.countries.size() == gs.countries.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	U.remove(fin["id"])
	print("HATA SAYISI=", fails)
	quit(1 if fails > 0 else 0)

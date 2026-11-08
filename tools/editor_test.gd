extends SceneTree
## Senaryo oluşturucu: sanitize / paylaşım kodu / kaydet / oyunda uygulama
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
const U = preload("res://scripts/user_scn.gd")
const Obj = preload("res://scripts/objectives.gd")
var fails := 0
func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok: fails += 1
func _init() -> void:
	var d := {"id": U.new_id(), "kind": "user", "name": "Deneme Krizi", "sub": "test", "blurb": "b", "intro": "Başlangıç haberi.",
		"suggest": ["Turkey"], "wars": [["Greece", "Turkey"], ["Foo", "Bar"]], "embargo": [["Turkey", "Greece"]], "cold": [],
		"blocs": [{"name": "Test Paktı", "members": ["Turkey", "Azerbaijan", "Pakistan"]}, {"name": "Kötü", "members": ["Turkey"]}],
		"troops_mult": {"Turkey": 1.4, "Greece": 9.0}, "stability": {"Greece": -15},
		"objectives": {"*": [{"id": "o0", "type": "survive", "turns": 30, "text": ""}, {"id": "o1", "type": "alliances", "n": 2, "text": ""}, {"id": "x", "type": "hack", "n": 1}]},
		"deadline": 120}
	var fin := U.finalize(U.sanitize(d))
	ck("sanitize ad", fin.get("name") == "Deneme Krizi")
	ck("sanitize geçersiz savaş atıldı", fin.get("wars", []).size() == 1)
	ck("sanitize 1 üyeli blok atıldı", fin.get("blocs", []).size() == 1)
	ck("sanitize çarpan sıkıştırıldı", fin.get("troops_mult", {}).get("Greece") == 2.0)
	ck("sanitize bilinmeyen hedef atıldı", fin["objectives"]["*"].size() == 2)
	ck("en bloğu hedefler", fin["en"]["objectives"].size() == 2)
	var code := U.export_code(fin)
	var back := U.import_code(code)
	ck("kod gidiş-dönüş", back.get("name") == "Deneme Krizi" and back.get("wars", []).size() == 1 and back["id"] != fin["id"])
	ck("bozuk kod reddedildi", U.import_code("AOD1.99.xxxx").is_empty() and U.import_code("merhaba").is_empty())
	ck("kod önekli kötü json", U.import_code(U.CODE_PREFIX + "20." + Marshalls.raw_to_base64("{}".to_utf8_buffer())).is_empty())
	ck("kaydet", U.save(fin))
	ck("listede", U.list_ids().has(fin["id"]))
	ck("Scenarios kullanıcı senaryosu", SC.is_user(fin["id"]))
	var gs = GS.new()
	gs.new_world(5)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	SC.apply(gs, fin["id"])
	ck("savaş kuruldu", gs.at_war(gs.macro_idx["Greece"], gs.macro_idx["Turkey"]))
	ck("hedefler yüklendi", Obj.list(gs).size() == 2)
	for t in 35:
		gs.end_turn()
	ck("survive hedefi bitti", Obj.is_done(gs, Obj.list(gs)[0]))
	var p := "user://ed_test.dat"
	ck("oyun kaydı", gs.save_to(p))
	var g2 = GS.new()
	ck("oyun yükü", g2.load_from(p) and Obj.list(g2).size() == 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	U.remove(fin["id"])
	ck("silindi", not U.list_ids().has(fin["id"]))
	print("HATA SAYISI=", fails)
	quit()

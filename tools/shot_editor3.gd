extends SceneTree
## Uçtan uca: editörde olay + savaş etkisi ekle, kaydet, senaryoyu seç, oyunu başlat, olayın tetiklenmesini doğrula.
const ScenarioEditor = preload("res://scripts/scenario_editor.gd")
var main
var out := "/tmp/shots_editor3"
var n := 0
var saved_id := ""

func _shot(tag: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	print("shot ", tag)

func _btn(pred: Callable) -> Button:
	for b in get_root().find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and pred.call(String(b.text).to_lower()):
			return b
	return null

func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	ScenarioEditor.open(main.menu.root, {}, func(id): saved_id = id; print("done ", id))
	await create_timer(0.8).timeout
	for le in get_root().find_children("*", "LineEdit", true, false):
		if le.is_visible_in_tree() and le.placeholder_text.to_lower().find("scenario name") >= 0:
			le.text = "E2E Test"
			le.text_changed.emit(le.text)
	var nxt := _btn(func(t): return t.find("next") >= 0 or t.find("ileri") >= 0)
	for i in 5: nxt.pressed.emit()          # sayfa 6
	await create_timer(0.4).timeout
	var txt: LineEdit = null
	for le in get_root().find_children("*", "LineEdit", true, false):
		if le.is_visible_in_tree() and le.placeholder_text.to_lower().find("news text") >= 0:
			txt = le
	print("haber kutusu: ", txt != null)
	txt.text = "E2E olayi tetiklendi"
	var wk: SpinBox = null
	for sb in get_root().find_children("*", "SpinBox", true, false):
		if sb.is_visible_in_tree() and String(sb.prefix).length() > 0 and sb.value == 8:
			wk = sb
	wk.value = 3
	var tp: OptionButton = null
	for ob in get_root().find_children("*", "OptionButton", true, false):
		if ob.is_visible_in_tree() and ob.item_count > 4:
			var has_war := false
			for i in ob.item_count:
				if ob.get_item_text(i).to_lower().find("war") >= 0 or ob.get_item_text(i).to_lower().find("savaş") >= 0:
					has_war = true
					ob.select(i)
					ob.item_selected.emit(i)
					break
			if has_war:
				tp = ob
	print("etki secici: ", tp != null, " -> ", tp.get_item_text(tp.selected) if tp else "")
	await create_timer(0.3).timeout
	await _shot("olay_formu")
	var add := _btn(func(t): return t.find("add event") >= 0 or t.find("olayı ekle") >= 0)
	add.pressed.emit()
	await create_timer(0.4).timeout
	await _shot("olay_eklendi")
	var sv := _btn(func(t): return t == "save" or t == "kaydet")
	print("kaydet: ", sv != null)
	sv.pressed.emit()
	await create_timer(1.0).timeout
	print("kayitli id: ", saved_id)
	var Scn = load("res://scripts/scenarios.gd")
	var sc: Dictionary = Scn.get_sc(saved_id)
	print("senaryo bulundu: ", not sc.is_empty(), " events=", sc.get("events", []).size())
	main.menu.set_scenario(saved_id)
	await create_timer(0.5).timeout
	var cid := -1
	for c in main.gs.countries:
		if c.name_en == "Turkey": cid = c.id
	main._on_start_requested(cid)
	await create_timer(1.5).timeout
	var gs = main.gs
	print("oyun basladi, tur=", gs.turn, " senaryo=", gs.scenario_id if "scenario_id" in gs else "?")
	var before_wars: int = gs.wars.size()
	for i in 6:
		gs.end_turn()
	var found := false
	for nw in gs.news_log:
		if String(nw.get("text", nw.get("t", ""))).find("E2E olayi") >= 0:
			found = true
	print("olay haberi dustu mu: ", found, "  savaslar ", before_wars, " -> ", gs.wars.size())
	print("E2E_BITTI")
	quit()

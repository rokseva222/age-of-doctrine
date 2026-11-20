extends SceneTree
## UI fuzz: görünür düğmelere rastgele basar; çökme/hata stderr'de aranır. kullanım: -- <seed> <adim> <career|era|free>
var main
var rng := RandomNumberGenerator.new()
const SKIP := ["QUIT", "EXIT", "ÇIK", "DELETE", "SİL", "MAIN MENU", "ANA MENÜ", "RESTART", "NEW GAME"]
func _collect(n: Node, out: Array) -> void:
	if n is Button and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
		var t := (n as Button).text.to_upper()
		var ok := true
		for s in SKIP:
			if t.find(s) >= 0: ok = false
		if ok: out.append(n)
	for c in n.get_children(): _collect(c, out)
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	rng.seed = int(a[0]); var steps := int(a[1]); var mode: String = a[2]
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	var st = load("res://scripts/settings.gd")
	st.seen_howto = true; st.seen_update = "1.2.20"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	if mode == "career":
		main._start_career("ott1520", {"host_en": "Turkey", "bg": "cavalry", "name": "Kemal Bey"})
	elif mode == "era":
		main._start_era("ww2"); await create_timer(1.0).timeout
		main.menu.call("_on_start_pressed") if main.menu.has_method("_on_start_pressed") else null
	await create_timer(1.5).timeout
	var presses := 0
	for i in steps:
		var bs: Array = []
		_collect(get_root(), bs)
		if bs.is_empty():
			main.gs.end_turn() if main.gs != null else null
			await create_timer(0.3).timeout
			continue
		var b: Button = bs[rng.randi_range(0, bs.size() - 1)]
		b.pressed.emit()
		presses += 1
		await create_timer(0.12).timeout
		if i % 25 == 24 and main.gs != null and main.mode == "game":
			main.gs.end_turn()
	print("FUZZ bitti presses=", presses, " mode=", main.mode)
	quit()

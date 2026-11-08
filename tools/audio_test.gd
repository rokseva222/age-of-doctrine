extends SceneTree
const Sfx = preload("res://scripts/sfx.gd")

func _init() -> void:
	var s = Sfx.new()
	root.add_child(s)
	await process_frame
	print("sfx bank: ", s._bank.size())
	var bad := 0
	for m in Sfx.MOODS:
		var st = s._music_stream(m)
		if st == null:
			bad += 1
			print("EKSİK müzik: ", m)
		else:
			print(m, " süre=", snappedf(st.get_length(), 0.1), " loop=", st.loop)
	var amb = s._amb.stream
	print("amb: ", amb != null)
	var ctx := {"mode": "game", "era": "", "war": false}
	s.context_cb = func(): return ctx
	await create_timer(1.0).timeout
	print("mood peace? ", s._mood)
	ctx["war"] = true
	await create_timer(1.0).timeout
	print("mood war? ", s._mood, " amb=", s._amb_on)
	ctx["war"] = false
	ctx["era"] = "ww2"
	await create_timer(1.0).timeout
	print("mood ww2? ", s._mood)
	ctx["mode"] = "menu"
	await create_timer(1.0).timeout
	print("mood menu? ", s._mood, " amb=", s._amb_on)
	for n in ["click", "tick", "tock", "cannon", "stamp", "news", "order"]:
		s.play(n)
	s.turn_tick(1)
	s.news_kind("battle")
	print("TAMAM eksik=", bad)
	quit()

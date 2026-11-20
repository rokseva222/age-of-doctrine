extends RefCounted
## Sandbox paneli: dene-oyna araçları (hazine, asker, eyalet verme/alma, savaş/barış, ilişkiler).
## Yalnızca Ayarlar > Sandbox modu açıkken oyun menüsünde görünür.

const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")
const Settings = preload("res://scripts/settings.gd")


static func open(ui, gs) -> void:
	if gs == null or gs.player < 0:
		return
	var sh = ui._open_sheet("Sandbox", 760, true, true, "Deneme araçları")
	var c = gs.countries[gs.player]
	var pid: int = ui._card_pid
	var sel_owner := -1
	var tgt_txt := Loc.t("Haritada bir eyalete dokunup menüyü yeniden aç: eyalet araçları açılır.")
	if pid >= 0:
		sel_owner = gs.provinces[pid].owner
		tgt_txt = "%s  /  %s" % [gs.provinces[pid].name, gs.countries[sel_owner].name]
	var hint := TK.t(Loc.t("Bu paneldeki değişiklikler oyun dengesini bozar; öğrenmek ve denemek içindir."), "small", TK.FAINT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(hint)
	_h(sh, "Kaynaklar")
	_b(ui, sh, "Hazine +1000 haftalık gelir", "coins", func():
		c.gold += 1000.0 * maxf(c.income, 1.0)
		ui.refresh_top())
	_b(ui, sh, "+100.000 asker (en büyük ordu)", "swords", func():
		var best = null
		for a in gs.armies.values():
			if a.owner == gs.player and (best == null or a.size > best.size):
				best = a
		if best != null:
			best.size += 100000
			gs.refresh_stats()
			gs.armies_changed.emit())
	_b(ui, sh, "İstikrar, sanayi, lojistik %100", "stability", func():
		c.stability = 100.0
		c.industry = 100.0
		c.logistics = 100.0)
	_b(ui, sh, "Savaş sisini kapat", "eye", func():
		Settings.fog = 0
		Settings.save_all())
	_h(sh, "Diplomasi")
	_b(ui, sh, "Tüm ülkelerle ilişki +50", "handshake", func():
		for o in gs.countries:
			if o.alive and o.id != c.id:
				c.relation[o.id] = minf(100.0, float(c.relation.get(o.id, 50.0)) + 50.0)
				o.relation[c.id] = minf(100.0, float(o.relation.get(c.id, 50.0)) + 50.0))
	_b(ui, sh, "Dünya tepkisini sıfırla", "shield", func(): gs.infamy = 0.0)
	_b(ui, sh, "Tüm savaşlarda barış yap", "handshake", func():
		for w in gs.wars.duplicate():
			if w.involves(gs.player):
				gs.finish_peace(w, -1, [])
		gs.state_changed.emit())
	_h(sh, "Dünya")
	_b(ui, sh, "Dünya barışı (tüm savaşları bitir)", "handshake", func():
		for w in gs.wars.duplicate():
			gs.finish_peace(w, -1, [])
		gs.state_changed.emit())
	_b(ui, sh, "Tüm komşularla ittifak kur", "handshake", func():
		var seen := {}
		for q in gs.provinces:
			if q.owner != gs.player:
				continue
			for nb in q.neighbors:
				var o: int = gs.provinces[nb].owner
				if o != gs.player and o >= 0 and not seen.has(o) and gs.countries[o].alive and not gs.countries[o].is_rebel and not gs.at_war(gs.player, o):
					seen[o] = true
					gs.make_alliance(gs.player, o)
		gs.state_changed.emit())
	_b(ui, sh, "Komşular arasında savaş çıkar", "swords", func():
		var pairs: Array = []
		for q in gs.provinces:
			for nb in q.neighbors:
				var a: int = q.owner
				var b: int = gs.provinces[nb].owner
				if a != b and a >= 0 and b >= 0 and a != gs.player and b != gs.player and a < b and gs.countries[a].alive and gs.countries[b].alive and not gs.countries[a].is_rebel and not gs.countries[b].is_rebel and not gs.at_war(a, b):
					pairs.append([a, b])
		pairs.shuffle()
		var n := 0
		for pr in pairs:
			if n >= 4:
				break
			if not gs.at_war(pr[0], pr[1]) and gs.declare_war(pr[0], pr[1]):
				n += 1
		gs.state_changed.emit())
	_b(ui, sh, "Rastgele olay tetikle", "news", func():
		gs._random_event())
	_b(ui, sh, "Rastgele 5 olay tetikle", "news", func():
		for i in 5:
			gs._random_event())
	_h(sh, "Ordu")
	_b(ui, sh, "Nükleer bekleme süresini sıfırla", "bomb", func():
		gs.nuke_cd = 0)
	_b(ui, sh, "Tüm eyaletlerim gelişim +2", "factory", func():
		for q in gs.provinces:
			if q.owner == gs.player:
				q.dev = mini(q.dev + 2, 9)
				q.defense = mini(q.defense + 2, 9)
		gs.state_changed.emit())
	_h(sh, "Eyalet:  " + tgt_txt)
	if pid >= 0:
		var pn: String = gs.provinces[pid].name
		if sel_owner != gs.player:
			_b(ui, sh, "Bu eyaleti bana ver", "flag", func():
				gs.sandbox_give(pid, gs.player))
			_b(ui, sh, "Bu ülkenin tüm eyaletlerini bana kat", "crown", func():
				gs.sandbox_annex_country(sel_owner, gs.player))
			if not gs.at_war(gs.player, sel_owner):
				_b(ui, sh, "Bu ülkeye savaş ilan et", "swords", func():
					gs.declare_war(gs.player, sel_owner)
					gs.state_changed.emit())
			else:
				_b(ui, sh, "Bu ülkeyle barış yap", "handshake", func():
					var w = gs.get_war(gs.player, sel_owner)
					if w != null:
						gs.finish_peace(w, -1, [])
					gs.state_changed.emit())
		else:
			_b(ui, sh, "Eyalet gelişimini artır", "factory", func():
				gs.provinces[pid].dev = mini(gs.provinces[pid].dev + 2, 9)
				gs.provinces[pid].defense = mini(gs.provinces[pid].defense + 2, 9)
				gs.province_changed.emit(pid))
		if sel_owner == gs.player:
			_b(ui, sh, "Bu eyalete 20.000 asker yerleştir", "swords", func():
				gs._spawn_army(gs.player, pid, 20000)
				gs.refresh_stats()
				gs.armies_changed.emit())
			if not gs.provinces[pid].is_capital:
				_b(ui, sh, "Başkenti bu eyalete taşı", "crown", func():
					var old: int = c.capital
					if old >= 0:
						gs.provinces[old].is_capital = false
					c.capital = pid
					gs.provinces[pid].is_capital = true
					gs.province_changed.emit(pid)
					gs.state_changed.emit())
		else:
			_b(ui, sh, "Bu ülkenin ordusunu yarıya indir", "shield", func():
				for a in gs.armies.values():
					if a.owner == sel_owner:
						a.size = maxi(100, a.size / 2)
				gs.refresh_stats()
				gs.armies_changed.emit())
		_b(ui, sh, "Bu eyalette isyan çıkar", "flag", func():
			gs.provinces[pid].unrest = 20
			gs._spawn_rebels(gs.provinces[pid])
			gs.state_changed.emit())
	sh.add_button("Kapat", func(): pass, "", true, "x", 160)


static func _h(sh, text: String) -> void:
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t(Loc.t(text) if not text.begins_with("Eyalet:") else Loc.t("Eyalet") + text.substr(6), "kicker", TK.GOLD))


static func _b(ui, sh, text: String, icon: String, cb: Callable) -> void:
	var b := TK.button(text, "", icon, Vector2(0, 88), 17)
	b.pressed.connect(func():
		ui._click()
		cb.call()
		ui.toast(Loc.t("Tamam"))
		ui.refresh_top())
	sh.body.add_child(b)

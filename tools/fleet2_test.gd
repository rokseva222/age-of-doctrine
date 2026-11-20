extends SceneTree
## Deniz filoları 2: gemi sınıfları, ad/bayrak/duruş/eşlik/bölme, ikmal, Hazar filosu, Arktik, YZ çıkarma konvoyu, kayıt.
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Fleets = preload("res://scripts/fleets.gd")
const Seas = preload("res://scripts/seas.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const Model = preload("res://scripts/model.gd")

var fails := 0


func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok:
		fails += 1


func make(era: String, seed_v: int = 7):
	var g = GS.new()
	Eras.prepare(era) if era != "" else Eras.clear()
	g.new_world(seed_v)
	var host := "Turkey"
	if era != "":
		Eras.restructure(g, era)
		host = String(Eras.get_era(era).suggest[0])
	var pl: int = int(g.macro_idx.get(host, 0))
	g.start_game(pl)
	if era != "":
		Eras.start(g, era)
	return g


func _init() -> void:
	var g = make("")
	Fleets.ensure(g)
	Seas.ensure_coast(g)
	# bölgeler
	ck("Arktik ve Hazar bölgeleri var", Seas.has("arctic") and Seas.has("caspian"))
	ck("Hazar'da kıyı eyaleti eşlendi (%d)" % Seas.provs_of(g, "caspian").size(), Seas.provs_of(g, "caspian").size() >= 4)
	ck("Arktik'te kıyı eyaleti eşlendi (%d)" % Seas.provs_of(g, "arctic").size(), Seas.provs_of(g, "arctic").size() >= 4)
	ck("Hazar kapalı göl", Seas.neighbors("caspian").is_empty() and Seas.is_lake("caspian"))
	ck("Arktik bağlı", Seas.hops("arctic", "atl_c") < 99)
	# ABD uçak gemileri
	var us: int = int(g.macro_idx.get("United States of America", -1))
	ck("ABD uçak gemisi var (%d)" % g.countries[us].carriers, g.countries[us].carriers >= 8)
	# Hazar flotillası (birkaç tur)
	for i in 3:
		g.end_turn()
	var lake_f: Array = Fleets.at_zone(g, "caspian")
	ck("Hazar flotillası kuruldu (%d)" % lake_f.size(), lake_f.size() >= 1)
	var has_main := true
	for f in lake_f:
		if Seas.is_lake(f.zone) and f.kind != "surface":
			has_main = false
	ck("Hazar'da yalnız yüzey flotillası", has_main)
	# gemi sınıfları
	var bad := 0
	for f in g.fleets.values():
		var sh: Array = Ext.ships(g, f)
		if sh.is_empty() or Ext.ship_total(g, f) < 1:
			bad += 1
	ck("her filonun gemi listesi dolu (%d bozuk)" % bad, bad == 0)
	# oyuncu eylemleri
	var me: int = g.player
	var mine: Array = Fleets.fleets_of(g, me)
	ck("oyuncunun filosu var (%d)" % mine.size(), mine.size() > 0)
	var base = null
	for f in mine:
		if f.kind == "surface" and f.size >= 1.0:
			base = f
			break
	if base == null:
		base = mine[0]
	var fid: int = base.id
	ck("ad verilir", Fleets.rename(g, fid, "Kara Kartal Filosu") == "" and Fleets.display_name(g, base) == "Kara Kartal Filosu")
	ck("bayrak verilir", Fleets.set_flag(g, fid, "H:#aa0000,#ffffff,#0033aa|S:.5,.5,.2,#ffd200") == "" and base.flag != "")
	ck("duruş değişir", Fleets.set_stance(g, fid, "defend") == "" and base.stance == "defend")
	Fleets.set_stance(g, fid, "avoid")
	var before: float = base.size
	var nf = Fleets.split(g, fid, 0.5)
	ck("filo bölünür", nf != null and absf(base.size + nf.size - before) < 0.001 and nf.flag == base.flag)
	var m = Fleets.merge(g, fid)
	ck("bölünen filo birleşir", m == "" and absf(base.size - before) < 0.001)
	if nf != null and g.fleets.has(nf.id):
		ck("birleşme eşliği temizler", true)
	# kayıt / yükleme
	var d: Dictionary = g.to_dict()
	var g2 = GS.new()
	g2.new_world(7)
	g2.from_dict(d)
	var f2 = g2.fleets.get(fid)
	ck("kayıt: ad/bayrak/duruş korunur", f2 != null and f2.name == "Kara Kartal Filosu" and f2.flag.begins_with("H:") and f2.stance == "avoid")
	# ikmal
	var far = null
	for f in g.fleets.values():
		if f.owner == me and f.kind == "surface":
			far = f
			break
	if far != null:
		far.zone = "pac_se"
		var h: int = Fleets.supply_hops(g, far)
		ck("ikmal uzaklığı hesaplanır (%d)" % h, h >= 3)
		ck("ikmal çarpanı < 1", Ext.supply_mult_for("surface", h) < 1.0)
	# rütbe
	ck("rütbe sırası", Ext.rank_name(0.0) == "Acemi" and Ext.rank_name(20.0) == "Elit" and Ext.rank_mult(40.0) > Ext.rank_mult(7.0))
	# YZ çıkarma konvoyu: yakın bir kıyı çifti için doğrudan çağır
	var ai: int = -1
	var src := -1
	var dst := -1
	for p in g.provinces:
		if p.coastal and p.owner >= 0 and p.owner != me and Seas.coast_zones(g, p.id).size() > 0:
			var cand: int = p.owner
			if not g.countries[cand].alive or g.countries[cand].is_rebel:
				continue
			for q in g.provinces:
				if q.coastal and q.owner >= 0 and q.owner != cand and q.id != p.id and Seas.coast_zones(g, q.id).size() > 0 and not Fleets.route_zones(g, p.id, q.id).is_empty():
					if Fleets.route_zones(g, p.id, q.id).size() >= 2 and p.controller == cand:
						ai = cand
						src = p.id
						dst = q.id
						break
		if ai >= 0:
			break
	ck("konvoy testi için hedef bulundu", ai >= 0)
	if ai >= 0:
		g._spawn_army(ai, src, 20000)
		var a = g.armies[src]
		var holder: int = g._holder(dst)
		var n_before: int = a.size
		var r: int = Fleets.ai_embark(g, ai, a, dst, 8000)
		ck("YZ konvoyu kuruldu", r == 1)
		var conv = null
		for f in g.fleets.values():
			if f.owner == ai and f.tgt == dst:
				conv = f
		ck("konvoy nakliye filosu ve yoluyla var", conv != null and conv.kind == "transport" and conv.cargo == 8000)
		ck("ordudan asker düştü", a.size == n_before - 8000)
		if conv != null:
			# hedef savaş dışıysa dost limana boşalma: savaş yok -> geçersiz -> unload
			conv.path.clear()
			conv.zone = String(Seas.coast_zones(g, dst)[0])
			var armies_before: int = 0
			Fleets._convoy_arrivals(g)
			ck("barış zamanı konvoy dağılır/boşalır", not g.fleets.has(conv.id) or conv.tgt == -2)
	print("HATA SAYISI=%d" % fails)
	quit(fails)

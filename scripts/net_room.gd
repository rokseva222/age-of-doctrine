extends RefCounted
## Çok oyunculu oda mantığı (ağdan bağımsız): sunucu bu sınıfı kullanır, testler ağsız çalıştırır.
## Eşzamanlı tur: herkes emirlerini gönderir, hepsi "hazır" deyince (ya da süre dolunca) tur işlenir.

const GS = preload("res://scripts/game_state.gd")
const Cmd = preload("res://scripts/cmd.gd")
const Mp = preload("res://scripts/mp.gd")
const FleetsM = preload("res://scripts/fleets.gd")
const AirM = preload("res://scripts/air.gd")
const Macro = preload("res://scripts/macro.gd")

var gs = null
var cmds: Dictionary = {}       # cid -> bekleyen komutlar (Array)
var ready: Dictionary = {}      # cid -> bool
var afk: Dictionary = {}        # cid -> bool (yapay zekâ devraldı)
var missed: Dictionary = {}     # cid -> üst üste kaçırılan tur sayısı
var last_report: Dictionary = {}
var rng := RandomNumberGenerator.new()


## Dünya durumundan oda kurar (gs: başlamış oyun; picks: insan ülkeleri).
func setup(g, picks: Array) -> void:
	gs = g
	gs.humans = picks.duplicate()
	gs.hs_i = 0
	gs.cmd_log = null
	FleetsM.ensure(gs)       # filo/uçak kimlikleri ilk görüntüden önce sabitlensin (istemciler aynı kimlikleri görsün)
	AirM.ensure(gs)
	for h in picks:
		gs.countries[h].is_player = true
		cmds[h] = []
		ready[h] = false
		afk[h] = false
	gs.player = -1


func is_human(cid: int) -> bool:
	return gs.humans.has(cid)


## Oyuncunun o tura ait komutlarını (kayıt listesi) ekler; yinelenen gönderimde öncekini değiştirir.
func submit(cid: int, list: Array) -> bool:
	if not is_human(cid) or not gs.countries[cid].alive:
		return false
	cmds[cid] = list.duplicate(true)
	return true


func set_ready(cid: int, v: bool) -> void:
	if is_human(cid):
		ready[cid] = v


func set_afk(cid: int, v: bool) -> void:
	if is_human(cid):
		afk[cid] = v


## Yaşayan ve AFK olmayan herkes hazır mı?
func all_ready() -> bool:
	var any := false
	for h in gs.humans:
		if not gs.countries[h].alive:
			continue
		if bool(afk.get(h, false)):
			continue
		any = true
		if not bool(ready.get(h, false)):
			return false
	return any


## Yaşayan ve yapay zekâ devralmamış insan sayısı.
func active_count() -> int:
	var n := 0
	for h in gs.humans:
		if gs.countries[h].alive and not bool(afk.get(h, false)):
			n += 1
	return n


func waiting_for() -> Array:
	var r: Array = []
	for h in gs.humans:
		if gs.countries[h].alive and not bool(afk.get(h, false)) and not bool(ready.get(h, false)):
			r.append(h)
	return r


## Turu işler: komutlar rastgele sırayla yeniden oynatılır (adil sıra), sonra dünya tur hesabı.
## AFK oyuncuların ülkesini yapay zekâ yönetir. Dönüş: {"turn": yeni tur, "results": {cid: [sonuçlar]}, "rejected": n}
func process_round() -> Dictionary:
	var order: Array = gs.humans.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	var results: Dictionary = {}
	var rejected := 0
	gs.news_bias = 1            # emirlerin haberleri bu turun (yeni tur) raporunda görünsün
	for cid in order:
		if not gs.countries[cid].alive:
			continue
		var res: Array = []
		for c in cmds.get(cid, []):
			var ctx: Dictionary = _pre(cid, c)
			var r: Dictionary = Cmd.replay(gs, cid, c)
			if r.ok:
				_notify_cmd(cid, c, r.res, ctx)
			res.append({"n": c.get("n", ""), "ok": r.ok, "res": r.res if (r.res is String or r.res is int or r.res is float or r.res is bool) else null})
			if not r.ok:
				rejected += 1
		results[cid] = res
	# AFK ülkeler: yapay zekâ oynasın
	var humans_keep: Array = gs.humans
	var afk_ids: Array = []
	for h in gs.humans:
		if bool(afk.get(h, false)):
			afk_ids.append(h)
	if not afk_ids.is_empty():
		var rest: Array = []
		for h in gs.humans:
			if not afk_ids.has(h):
				rest.append(h)
		gs.humans = rest
	gs.news_bias = 0
	gs.player = -1
	gs.end_turn()
	gs.humans = humans_keep
	gs.player = -1
	for h in gs.humans:
		cmds[h] = []
		ready[h] = false
	return {"turn": gs.turn, "results": results, "rejected": rejected, "over": Mp.check_end(gs)}


# ------------------------------------------------------------------ oyuncular arası bildirimler

func _nm(cid: int) -> String:
	return String(gs.countries[cid].name) if cid >= 0 and cid < gs.countries.size() else "?"


func _arg_int(c: Dictionary, i: int, def: int = -1) -> int:
	var a: Array = c.get("a", [])
	if i < a.size() and (a[i] is int or a[i] is float):
		return int(a[i])
	return def


func _arg_str(c: Dictionary, i: int) -> String:
	var a: Array = c.get("a", [])
	return String(a[i]) if i < a.size() and a[i] is String else ""


func _arg_bool(c: Dictionary, i: int) -> bool:
	var a: Array = c.get("a", [])
	return bool(a[i]) if i < a.size() else false


## Emri yeniden oynatmadan önce gereken bağlam (ör. cevaplanan teklifin sahibi, para miktarı).
func _pre(cid: int, c) -> Dictionary:
	var ctx := {}
	if not (c is Dictionary):
		return ctx
	var n: String = String(c.get("n", ""))
	match n:
		"respond_offer":
			var oid: int = _arg_int(c, 0)
			for o in gs.offers:
				if int(o.id) == oid and int(o.to) == cid:
					ctx["from"] = int(o.from)
					ctx["kind"] = String(o.kind)
		"player_gas", "player_nuke":
			var pid: int = _arg_int(c, 0)
			if pid >= 0 and pid < gs.provinces.size():
				ctx["victim"] = gs.provinces[pid].owner
		"Fleets.player_torpedo":
			var f = gs.fleets.get(_arg_int(c, 1))
			if f != null:
				ctx["victim"] = f.owner
		"player_aid_gold", "player_improve_relations":
			var keep: int = gs.player
			if cid >= 0 and cid < gs.countries.size():
				gs.switch_player(cid)
				var kind: String = "gold" if n == "player_aid_gold" else _arg_str(c, 1)
				if kind == "gold":
					ctx["amt"] = gs.aid_gold_cost() * 0.8
				elif gs.DIPLO_ACTS.has(kind):
					ctx["amt"] = gs.diplo_cost(kind) * float(gs.DIPLO_ACTS[kind].gift)
				gs.switch_player(keep)
	return ctx


## Başarılı bir emrin etkilediği insan oyuncuya haber yazar (yapay zekâ ülkeler haber almaz).
func _notify_cmd(cid: int, c, res, ctx: Dictionary) -> void:
	if not (c is Dictionary):
		return
	var me: String = _nm(cid)
	var n: String = String(c.get("n", ""))
	var t: int = _arg_int(c, 0)
	var sres: String = String(res) if res is String else ""
	var d: Dictionary = res if res is Dictionary else {}
	var amt: float = float(ctx.get("amt", 0.0))
	match n:
		"player_improve_relations":
			if sres != "":
				return
			var kind: String = _arg_str(c, 1)
			if kind == "envoy":
				gs.notify_human(t, "%s sana bir elçi gönderdi; ilişkiler ısındı." % me)
			elif kind == "gift":
				gs.notify_human(t, "%s sana hediye gönderdi: hazineye +%s." % [me, Macro.money(amt)])
			else:
				gs.notify_human(t, "%s seninle ticaret ve kültür anlaşması imzaladı: hazineye +%s." % [me, Macro.money(amt)])
		"player_worsen_relations":
			if sres != "":
				return
			var k2: String = _arg_str(c, 1)
			if k2 == "protest":
				gs.notify_human(t, "%s sana protesto notası verdi." % me)
			elif k2 == "smear":
				gs.notify_human(t, "%s aleyhinde karalama kampanyası yürütüyor." % me)
			else:
				gs.notify_human(t, "%s sınırında kışkırtma yaptı; ilişkiler bozuldu." % me)
		"player_sign_trade":
			if sres == "":
				gs.notify_human(t, "%s seninle ticaret anlaşması imzaladı." % me)
		"player_cancel_trade":
			gs.notify_human(t, "%s ticaret anlaşmasını tek taraflı sonlandırdı." % me)
		"player_set_embargo":
			if _arg_bool(c, 1):
				gs.notify_human(t, "%s sana ambargo uyguladı: karşılıklı ticaret durdu." % me)
			else:
				gs.notify_human(t, "%s sana uyguladığı ambargoyu kaldırdı." % me)
		"player_request_passage":
			if sres == "":
				gs.notify_human(t, "%s ordularına topraklarından geçiş izni verildi." % me)
		"player_covert":
			if not bool(d.get("ok", false)):
				return
			match _arg_str(c, 1):
				"spy":
					gs.notify_human(t, "Savunma planlarının çalındığı anlaşıldı: %s'nın ajanları işin içinde." % me)
				"prop":
					gs.notify_human(t, "Ülkende %s kaynaklı propaganda var: istikrar düştü." % me)
				"sab":
					gs.notify_human(t, "Fabrikalarında sabotaj: %s'nın ajanları suçlanıyor. Sanayi sarsıldı." % me)
				"emb":
					gs.notify_human(t, "%s elçilik açtı; ilişkiler ısındı." % me)
		"player_aid_gold":
			if sres == "":
				gs.notify_human(t, "%s sana mali yardım gönderdi: hazineye +%s." % [me, Macro.money(amt)])
		"player_aid_join":
			if sres == "":
				gs.notify_human(t, "%s savaşında yanında yer aldı." % me)
		"player_break_alliance":
			gs.notify_human(t, "%s ittifakı bozdu." % me)
		"player_invite":
			if sres == "":
				gs.notify_human(t, "%s seni kendi bloğuna davet etti." % me)
		"player_surrender":
			if sres == "":
				gs.notify_human(t, "%s sana teslim oldu: savaş bitti." % me)
		"player_request_aid":
			if bool(d.get("ok", false)):
				gs.notify_human(t, "%s yardım çağrısıyla seni savaşa çekti." % me)
		"player_join_war":
			gs.notify_human(t, "%s müttefik çağrısıyla sana savaş açtı." % me)
		"player_gas":
			if sres == "":
				gs.notify_human(int(ctx.get("victim", -1)), "KİMYASAL SALDIRI! %s eyaletlerinde zehirli gaz kullandı." % me)
		"player_nuke":
			if sres == "":
				gs.notify_human(int(ctx.get("victim", -1)), "NÜKLEER SALDIRI! %s ülkene nükleer silah kullandı." % me)
		"player_launch_assault":
			var pid1: int = _arg_int(c, 0)
			if pid1 >= 0 and pid1 < gs.provinces.size() and String(d.get("err", "")) == "":
				var o1: int = gs.provinces[pid1].owner
				if o1 != cid:
					gs.notify_human(o1, "%s %s eyaletine büyük çaplı saldırı başlattı." % [me, gs.provinces[pid1].name], pid1)
		"Air.player_strike":
			if String(d.get("err", "")) == "":
				_notify_strike(cid, _arg_int(c, 1), "%s uçakları %s eyaletini vurdu.", d)
		"Carriers.strike":
			if String(d.get("err", "")) == "":
				_notify_strike(cid, _arg_int(c, 0), "%s uçak gemileri %s eyaletini vurdu.", d)
		"Fleets.player_bombard":
			if String(d.get("err", "")) == "":
				_notify_strike(cid, _arg_int(c, 1), "%s donanması %s kıyılarını bombaladı.", d)
		"Fleets.player_torpedo":
			if String(d.get("err", "")) == "":
				gs.notify_human(int(ctx.get("victim", -1)), "%s denizaltıları filona torpido saldırısı yaptı." % me)
		"Fleets.debark":
			if sres == "":
				var pid2: int = _arg_int(c, 1)
				if pid2 >= 0 and pid2 < gs.provinces.size() and gs.provinces[pid2].owner != cid:
					gs.notify_human(gs.provinces[pid2].owner, "%s %s eyaletine çıkarma yaptı!" % [me, gs.provinces[pid2].name], pid2)
		"Ultimatum.deliver":
			var tu: int = _arg_int(c, 1)
			if bool(d.get("ok", false)):
				if bool(d.get("accepted", false)):
					gs.notify_human(tu, "%s sana ültimatom verdi; kabul ettin." % me)
				else:
					gs.notify_human(tu, "%s sana ültimatom verdi; reddettin ve savaş başladı." % me)
		"GrandOp.launch":
			if String(d.get("err", "")) == "":
				gs.notify_human(_arg_int(c, 0), "%s ülkene karşı büyük bir harekât başlattı." % me)
		"UN.propose":
			if bool(d.get("ok", false)):
				gs.notify_human(_arg_int(c, 2), "%s Birleşmiş Milletler'de seninle ilgili bir önerge verdi." % me)
		"respond_offer":
			var from: int = int(ctx.get("from", -1))
			if from >= 0:
				var ally: bool = String(ctx.get("kind", "")) == "alliance"
				if _arg_bool(c, 1):
					gs.notify_human(from, ("%s ittifak teklifini kabul etti." if ally else "%s barış teklifini kabul etti.") % me)
				else:
					gs.notify_human(from, ("%s ittifak teklifini reddetti." if ally else "%s barış teklifini reddetti.") % me)


func _notify_strike(cid: int, pid: int, fmt: String, d: Dictionary) -> void:
	if pid < 0 or pid >= gs.provinces.size():
		return
	var holder: int = gs._holder(pid)
	var victim: int = holder if holder >= 0 else gs.provinces[pid].owner
	if victim == cid:
		return
	gs.notify_human(victim, fmt % [_nm(cid), gs.provinces[pid].name], pid)

extends RefCounted
## Komut katmanı. Çok oyunculu online modda oyuncunun her emri serileştirilebilir bir komut olarak kaydedilir
## (gs.cmd_log); sunucu aynı emri kendi durumunda yeniden oynatır. Tek oyunculuda gs.cmd_log == null: maliyet sıfır.
##
## Kullanım (emir fonksiyonunun ilk satırı):
##   var _c := Cmd.Scope.new(self, "player_build", [pid, kind])          # GameState yöntemi
##   var _c := Cmd.Scope.new(gs, "Fleets.order_move", [f, zone])        # modül (gs ilk argüman değil, hedef gs)
## İç içe çağrılarda yalnızca en dıştaki emir kaydedilir (derinlik sayacı).

const Model = preload("res://scripts/model.gd")

## Çevrimiçi istemcinin yerel oyun durumu (gs parametresi almayan modül fonksiyonları için, örn. Macro.set_budget)
static var rec_gs = null

## gs'yi ilk argüman olarak ALMAYAN modül emirleri (yeniden oynatırken gs eklenmez)
const NOGS := ["Macro.set_budget", "Macro.set_front"]

## Modül adı → betik (statik fonksiyonları çağırmak için)
const MODULES := {
	"Fleets": "res://scripts/fleets.gd", "Air": "res://scripts/air.gd", "Cabinet": "res://scripts/cabinet.gd",
	"Macro": "res://scripts/macro.gd", "UN": "res://scripts/un.gd", "Focus": "res://scripts/focus.gd",
	"Politics": "res://scripts/politics.gd", "Carriers": "res://scripts/carriers.gd", "Chokepoints": "res://scripts/chokepoints.gd",
	"Formables": "res://scripts/formables.gd", "GrandOp": "res://scripts/grand_op.gd", "Ultimatum": "res://scripts/ultimatum.gd",
	"Propaganda": "res://scripts/propaganda.gd", "Faith": "res://scripts/faith.gd",
}


class Scope extends RefCounted:
	var _gs = null
	var _on := false

	func _init(gs, name: String, args: Array) -> void:
		if gs == null or gs.cmd_log == null or gs.cmd_replay:
			return
		_gs = gs
		_on = true
		if gs.cmd_depth == 0:
			gs.cmd_log.append({"n": name, "a": encode(args)})
		gs.cmd_depth += 1

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE and _on and _gs != null:
			_gs.cmd_depth = maxi(0, _gs.cmd_depth - 1)

	static func encode(args: Array) -> Array:
		var out: Array = []
		for v in args:
			out.append(_enc(v))
		return out

	static func _enc(v):
		if v is Model.Army:
			return {"$a": v.id}
		if v is Model.Fleet:
			return {"$f": v.id}
		if v is Model.Wing:
			return {"$w": v.id}
		if v is Model.Country:
			return {"$c": v.id}
		if v is Model.War:
			return {"$war": [v.a, v.b]}
		if v is Array:
			var r: Array = []
			for x in v:
				r.append(_enc(x))
			return r
		if v is Dictionary:
			var d := {}
			for k in v:
				d[k] = _enc(v[k])
			return d
		if v is Object:
			return null
		return v


static func _dec(gs, v):
	if v is Dictionary:
		if v.size() == 1:
			if v.has("$a"):
				for a in gs.armies.values():
					if a.id == int(v["$a"]):
						return a
				return null
			if v.has("$f"):
				return gs.fleets.get(int(v["$f"]))
			if v.has("$w"):
				return gs.wings.get(int(v["$w"]))
			if v.has("$c"):
				var ci: int = int(v["$c"])
				return gs.countries[ci] if ci >= 0 and ci < gs.countries.size() else null
			if v.has("$war"):
				var ab: Array = v["$war"]
				return gs.get_war(int(ab[0]), int(ab[1]))
		var d := {}
		for k in v:
			d[k] = _dec(gs, v[k])
		return d
	if v is Array:
		var r: Array = []
		for x in v:
			r.append(_dec(gs, x))
		return r
	return v


const COUNTRY_PARAMS := ["target", "foe", "ally", "enemy", "v", "cid", "owner", "country", "a", "b"]
const PROV_PARAMS := ["pid", "prov", "dest"]
const GS_CMDS := ["hire_merc", "respond_offer"]
## Sunucunun istemciden kabul ettiği modül emirleri (beyaz liste): iç yardımcı fonksiyonlar çağrılamaz.
const MODULE_CMDS := ["Air.player_strike", "Air.rebase", "Air.airlift", "Air.rename", "Air.set_flag", "Air.set_stance",
	"Cabinet.appoint", "Cabinet.dismiss", "Cabinet.apply", "Carriers.build_ship", "Carriers.buy", "Carriers.strike",
	"Chokepoints.set_mode", "Fleets.order_move", "Fleets.stop", "Fleets.merge", "Fleets.blockade", "Fleets.player_bombard",
	"Fleets.player_torpedo", "Fleets.embark", "Fleets.debark", "Fleets.rename", "Fleets.set_flag", "Fleets.set_stance",
	"Fleets.set_escort", "Fleets.split", "Focus.start", "Focus.cancel", "Formables.form", "GrandOp.launch",
	"Macro.set_front", "Macro.set_budget", "Macro.set_doctrine", "Macro.mobilize", "Macro.buy",
	"Politics.choose", "Politics.do_action", "Ultimatum.deliver", "UN.propose", "UN.player_vote"]
const OBJ_PARAMS := ["a", "f", "w", "army", "fleet", "wing", "fid", "c", "me", "country_obj"]
static var _sigs: Dictionary = {}


## Yöntem imzası (ad, tür, varsayılan sayısı); sunucu bozuk/kötü niyetli komutları çalıştırmadan reddetsin diye.
static func _sig(key: String, obj, fn: String) -> Dictionary:
	if _sigs.has(key):
		return _sigs[key]
	var info := {}
	var lst: Array = obj.get_script_method_list() if obj is Script else obj.get_method_list()
	for m in lst:
		if m["name"] == fn:
			info = {"args": m["args"], "defs": m.get("default_args", []).size()}
			break
	_sigs[key] = info
	return info


## Argümanlar imzaya uyuyor mu? Hata metni ("" = geçerli). Aralık dışı ülke/il, eksik nesne ve tür uyuşmazlığı çalıştırılmaz.
static func _validate(gs, sig: Dictionary, args: Array, skip: int) -> String:
	if sig.is_empty():
		return "imza yok"
	var params: Array = sig["args"].slice(skip)
	if args.size() > params.size() or args.size() < params.size() - int(sig["defs"]):
		return "argüman sayısı"
	for i in args.size():
		var pn: String = String(params[i]["name"])
		var pt: int = int(params[i]["type"])
		var v = args[i]
		if v == null and (OBJ_PARAMS.has(pn) or pt != TYPE_NIL):
			if pt != TYPE_NIL or OBJ_PARAMS.has(pn):
				return "boş argüman: %s" % pn
		if pt == TYPE_INT and not (v is int):
			return "tür: %s" % pn
		if pt == TYPE_FLOAT and not (v is float or v is int):
			return "tür: %s" % pn
		if pt == TYPE_STRING and not (v is String):
			return "tür: %s" % pn
		if pt == TYPE_ARRAY and not (v is Array):
			return "tür: %s" % pn
		if pt == TYPE_DICTIONARY and not (v is Dictionary):
			return "tür: %s" % pn
		if v is int and pt == TYPE_INT:
			if COUNTRY_PARAMS.has(pn) and (v < 0 or v >= gs.countries.size()):
				return "ülke aralığı: %s" % pn
			if PROV_PARAMS.has(pn) and (v < 0 or v >= gs.provinces.size()):
				return "il aralığı: %s" % pn
	return ""


## Komutu "cid" ülkesi adına yeniden oynatır. Dönüş: {"ok": bool, "res": sonuç, "err": metin}
static func replay(gs, cid: int, cmd) -> Dictionary:
	if not (cmd is Dictionary) or not (cmd.get("n", "") is String) or not (cmd.get("a", []) is Array):
		return {"ok": false, "res": null, "err": "bozuk komut"}
	var name: String = String(cmd.get("n", ""))
	var raw: Array = cmd.get("a", [])
	var args: Array = []
	for v in raw:
		args.append(_dec(gs, v))
	if cid < 0 or cid >= gs.countries.size():
		return {"ok": false, "res": null, "err": "geçersiz oyuncu"}
	var verr := ""
	var scr = null
	var skip := 0
	if name.contains("."):
		var mod: String = name.get_slice(".", 0)
		var fn0: String = name.get_slice(".", 1)
		if not MODULES.has(mod) or not MODULE_CMDS.has(name):
			return {"ok": false, "res": null, "err": "bilinmeyen modül"}
		scr = load(MODULES[mod])
		if not scr.has_method(fn0) and not _sig("m:" + name, scr, fn0).has("args"):
			return {"ok": false, "res": null, "err": "bilinmeyen komut"}
		skip = 0 if NOGS.has(name) else 1
		verr = _validate(gs, _sig("m:" + name, scr, fn0), args, skip)
	else:
		# yalnız oyuncu emirleri çalışır: sunucunun iç yöntemleri (tur sonu, yükleme...) istemciden çağrılamaz
		if not (name.begins_with("player_") or GS_CMDS.has(name)) or not gs.has_method(name):
			return {"ok": false, "res": null, "err": "bilinmeyen komut"}
		verr = _validate(gs, _sig("g:" + name, gs, name), args, 0)
	if verr == "" and skip == 0 and scr != null and NOGS.has(name):
		# Macro.set_budget/set_front: yalnız kendi ülken (başkasının bütçesini değiştiremezsin)
		if args.is_empty() or not (args[0] is Model.Country) or args[0].id != cid:
			verr = "başkasının ülkesi"
	if verr != "":
		return {"ok": false, "res": null, "err": verr}
	var gerr: String = _guard(gs, cid, name, args)
	if gerr != "":
		return {"ok": false, "res": null, "err": gerr}
	var keep: int = gs.player
	gs.switch_player(cid)
	if name == "Cabinet.appoint":
		var cerr: String = _guard_cabinet(gs, args)
		if cerr != "":
			gs.switch_player(keep)
			return {"ok": false, "res": null, "err": cerr}
	gs.cmd_replay = true
	var res = null
	var ok := true
	var err := ""
	if scr != null:
		var fn: String = name.get_slice(".", 1)
		var full: Array = [] if NOGS.has(name) else [gs]
		full.append_array(args)
		res = scr.callv(fn, full)
	else:
		res = gs.callv(name, args)
	gs.cmd_replay = false
	gs.switch_player(keep)
	return {"ok": ok, "res": res, "err": err}


static func _own_country(args: Array, cid: int, idx: int) -> bool:
	return args.size() > idx and args[idx] is Model.Country and args[idx].id == cid


## Sunucu tarafı sahiplik/aralık denetimi: istemci başkası adına ya da kasadan fazlasını harcayamaz.
static func _guard(gs, cid: int, name: String, args: Array) -> String:
	match name:
		"Macro.buy":
			if not _own_country(args, cid, 0):
				return "başkasının ülkesi"
			if args.size() < 4 or int(args[3]) < 1 or int(args[3]) > 100000:
				return "miktar"
		"Macro.mobilize", "Macro.set_doctrine":
			if not _own_country(args, cid, 0):
				return "başkasının ülkesi"
		"UN.propose":
			if args.size() < 3 or int(args[1]) != cid:
				return "önerge sahibi"
			if args.size() > 3:
				args[3] = {}                      # oy sonuçlarını istemci dayatamaz
		"hire_merc":
			if args.is_empty() or int(args[0]) != cid:
				return "başkası adına"
			if args.size() > 2:
				args[2] = true                    # sözleşme bedeli her zaman ödenir
		"Cabinet.apply":
			if args.is_empty() or not (args[0] is Dictionary):
				return "bozuk etki"
			var eff: Dictionary = args[0]
			for k in eff.keys():
				var v = eff[k]
				if not (v is int or v is float):
					eff.erase(k)
					continue
				var f: float = float(v)
				match String(k):
					"g":
						f = clampf(f, -3.0, 3.0)
					"troops", "tech":
						f = clampf(f, -0.05, 0.05)
					"mit":
						f = clampf(f, 0.0, 1.0)
					"nbtruce":
						f = clampf(f, 0.0, 52.0)
					_:
						f = clampf(f, -10.0, 10.0)
				eff[k] = f
	return ""


## Kabine atamasında aday ve bedel sunucuda yeniden hesaplanır (istemci bedeli 0 yazamaz).
static func _guard_cabinet(gs, args: Array) -> String:
	if args.size() < 2 or not (args[1] is Dictionary):
		return "bozuk aday"
	var Cab = load("res://scripts/cabinet.gd")
	var role: String = String(args[0])
	if not Cab.APPOINT.has(role):
		return "bilinmeyen rol"
	for cand in Cab.candidates(gs, role):
		if String(cand.n) == String(args[1].get("n", "")):
			args[1] = cand
			return ""
	return "aday bulunamadı"

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


## Komutu "cid" ülkesi adına yeniden oynatır. Dönüş: {"ok": bool, "res": sonuç, "err": metin}
static func replay(gs, cid: int, cmd: Dictionary) -> Dictionary:
	var name: String = String(cmd.get("n", ""))
	var raw: Array = cmd.get("a", [])
	var args: Array = []
	for v in raw:
		args.append(_dec(gs, v))
	var keep: int = gs.player
	gs.switch_player(cid)
	gs.cmd_replay = true
	var res = null
	var ok := true
	var err := ""
	if name.contains("."):
		var mod: String = name.get_slice(".", 0)
		var fn: String = name.get_slice(".", 1)
		if not MODULES.has(mod):
			ok = false
			err = "bilinmeyen modül"
		else:
			var scr = load(MODULES[mod])
			var full: Array = [] if NOGS.has(name) else [gs]
			full.append_array(args)
			res = scr.callv(fn, full)
	else:
		if not gs.has_method(name):
			ok = false
			err = "bilinmeyen komut"
		else:
			res = gs.callv(name, args)
	gs.cmd_replay = false
	gs.switch_player(keep)
	return {"ok": ok, "res": res, "err": err}

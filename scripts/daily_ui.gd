extends RefCounted
## Günlük Meydan Okuma arayüzü: menü penceresi ve oyun içi durum penceresi.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Icons = preload("res://scripts/icons.gd")
const D = preload("res://scripts/daily.gd")


## on_start: Callable(cfg: Dictionary)
static func open(parent: Node, on_start: Callable) -> void:
	var day: int = D.today()
	var cfg: Dictionary = D.cfg(day)
	var sh = Sheet.open(parent, "Günlük Meydan Okuma", 780, false, true, "Herkes için aynı")
	var intro := TK.t("Her gün herkes aynı ülkeyle, aynı dünyada başlar. 52 hafta sonunda skorun hesaplanır; büyümeye ve istikrara göre puan alırsın. Günün ilk bitirişinde AP kazanırsın, istediğin kadar tekrar deneyebilirsin.", "body", TK.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(intro)
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Bugünün ülkesi", "kicker", TK.GOLD))
	sh.body.add_child(TK.t(Loc.t(String(cfg.country)), "h2", TK.TEXT))
	sh.body.add_child(TK.t("Günün çarpıtması", "kicker", TK.GOLD))
	sh.body.add_child(TK.t(D.twist_name(String(cfg.twist)), "caps", TK.TEXT))
	var dl := TK.t(D.twist_desc(String(cfg.twist)), "small", TK.MUTED)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(dl)
	sh.body.add_child(TK.hsep())
	var best: int = D.best_today(day)
	var st: Array = []
	st.append(Loc.t("Bugünkü en iyi skor: %d") % best if best > 0 else Loc.t("Bugün henüz denemedin."))
	var s: int = D.streak_now()
	if s > 0:
		st.append(Loc.t("Seri: %d gün") % s)
	var all_best: int = int(D_best_all())
	if all_best > 0:
		st.append(Loc.t("Tüm zamanların en iyisi: %d") % all_best)
	for ln in st:
		var sl: String = String(ln)
		if s > 0 and sl == Loc.t("Seri: %d gün") % s:
			sh.body.add_child(TK.chip(Icons.pick("streak_flame", "star"), sl, TK.TEXT, TK.GOLD))
		else:
			sh.body.add_child(TK.t(sl, "small", TK.TEXT))
	sh.add_button("Başla", func(): on_start.call(cfg), "primary", true, "play", 220)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


static func D_best_all() -> int:
	return int(preload("res://scripts/settings.gd").daily.get("best_all", 0))

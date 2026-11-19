extends RefCounted
## Propaganda ve hükümete güven: halk hükümete ne kadar inanıyor, yasalara ne kadar uyuyor.
## Güven (0..100) kendiliğinden istikrara doğru kayar; propaganda yöntemi onu yukarı iter.
## Yöntemlerin gücü mevcut güvene bağlıdır: güvenin düşük olduğu yerde afiş inandırmaz, meydan konuşması işe yarar;
## güven yüksekken yazılı basın en etkilisidir.

const MODES := {
	"": {"name": "Propaganda yok", "cost": 0.0, "g0": 0.0, "g1": 0.0,
		"info": "Hazine harcanmaz. Güven yalnızca istikrar ve savaş durumuna göre kayar."},
	"oral": {"name": "Sözlü (miting, radyo, minber)", "cost": 0.010, "g0": 0.55, "g1": 0.35,
		"info": "Pahalı ama düşük güvende de işe yarar: insanlar yüz yüze ikna olur."},
	"press": {"name": "Yazılı (gazete, kitap, matbaa)", "cost": 0.012, "g0": 0.12, "g1": 0.75,
		"info": "Güven düşükken neredeyse hiç inandırmaz; güven yüksekken en güçlü yöntem."},
	"poster": {"name": "Afiş ve slogan", "cost": 0.004, "g0": 0.20, "g1": 0.30,
		"info": "Ucuz ve her yere yayılır; etkisi küçüktür ama sabit."},
}
const ORDER := ["", "oral", "press", "poster"]


static func target(gs, c) -> float:
	var t: float = 28.0 + c.stability * 0.55
	if not c.enemies.is_empty():
		t -= 6.0
	if gs.turn < c.sanction_until:
		t -= 5.0
	return clampf(t, 5.0, 95.0)


static func gain(mode: String, trust: float) -> float:
	var m: Dictionary = MODES.get(mode, MODES[""])
	return lerpf(float(m.g0), float(m.g1), clampf(trust / 100.0, 0.0, 1.0))


## haftalık: gideri öder (yalnız oyuncu), güveni günceller
static func weekly(gs, c, rev: float) -> void:
	var t: float = c.trust
	t += (target(gs, c) - t) * 0.04
	if c.prop != "" and c.id == gs.player:
		var cost: float = rev * float(MODES[c.prop].cost)
		if c.gold >= cost:
			c.gold -= cost
			t += gain(c.prop, t)
	c.trust = clampf(t, 0.0, 100.0)


## gelir çarpanı: yasalara uyum / vergi ahlakı
static func income_mult(c) -> float:
	return 0.94 + 0.12 * c.trust / 100.0


## haftalık istikrar katkısı
static func stability_delta(c) -> float:
	return (c.trust - 50.0) * 0.004


static func label(trust: float) -> String:
	if trust >= 80.0:
		return "Halk size bağlı"
	if trust >= 60.0:
		return "Güven yüksek"
	if trust >= 40.0:
		return "Kararsız"
	if trust >= 20.0:
		return "Güvensizlik"
	return "Halk hükümete inanmıyor"


static func weekly_cost(c, rev: float) -> float:
	return rev * float(MODES[c.prop].cost) if c.prop != "" else 0.0

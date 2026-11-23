extends RefCounted
## Veri modeli: eyalet, ülke, ordu, savaş.

const BLD := {
	"farm": {"name": "Tarım çiftliği", "bonus": 0.25, "mult": 8.0, "icon": "bld_farm", "info": "Gelir +%25"},
	"mine": {"name": "Maden ocağı", "bonus": 0.40, "mult": 12.0, "icon": "bld_mine", "info": "Gelir +%40"},
	"oil": {"name": "Petrol tesisi", "bonus": 0.55, "mult": 16.0, "icon": "bld_oil", "info": "Gelir +%55"},
	"wood": {"name": "Kereste atölyesi", "bonus": 0.20, "mult": 6.0, "icon": "bld_factory", "info": "Gelir +%20, kereste üretimi"},
	"school": {"name": "Okul ve kütüphane", "bonus": 0.08, "mult": 9.0, "icon": "bld_university", "info": "Gelir +%8, teknolojiyi hızlandırır"},
	"refinery": {"name": "Rafineri", "bonus": 0.25, "mult": 14.0, "icon": "bld_refinery", "info": "Gelir +%25, petrol satışı +%8"},
	"export": {"name": "İhracat limanı", "bonus": 0.15, "mult": 10.0, "icon": "bld_harbor", "info": "Gelir +%15, tüm mal satışları +%6"},
	"press": {"name": "Kağıt fabrikası ve matbaa", "bonus": 0.20, "mult": 7.0, "icon": "bld_press", "info": "Gelir +%20, huzursuzluğu azaltır"},
}
const BLD_WEEKS := 8
## O5: bölgesel kaynaklar. Ülke bazında bilinen üreticilerde eyaletlerin bir kısmı o kaynakta zengindir: o bina %35 ucuz, getirisi %30 fazla.
## Yatak seçimi eyalet kimliğinden deterministik türetilir (kayda girmez); gs.ensure_rich() ülke bantlarını kurar.
const RichStore = preload("res://scripts/rich_store.gd")
const RICH_NAMES := {"farm": "Verimli tarım ovası", "mine": "Zengin maden yatağı", "oil": "Petrol ve gaz sahası", "wood": "Zengin orman"}
const RICH_COST := 0.65
const RICH_BONUS := 1.3
## Eski çağda (pre) petrol tesisi / matbaa yok: dönem adları
const BLD_PRE_NAME := {"oil": "Neft ocağı", "press": "Kâğıt atölyesi ve medrese"}


static func bld_name(kind: String, pre: bool = false) -> String:
	if pre and BLD_PRE_NAME.has(kind):
		return String(BLD_PRE_NAME[kind])
	return String(BLD[kind].name)


class Province:
	var id := 0
	var name := ""
	var city := ""
	var rings: Array = []                    # Array[PackedVector2Array] dış halkalar (dünya koordinatı)
	var bbox := Rect2()
	var label_pos := Vector2.ZERO
	var label_r := 0.0
	var area_km2 := 0
	var pop := 1.0                           # milyon
	var gdp := 0.0                           # milyon USD
	var dev := 1
	var defense := 0
	var neighbors: Array = []
	var sea_links: Array = []
	var owner := -1
	var controller := -1
	var siege := 0
	var siege_by := -1
	var landmass := 0
	var grp := -1                            # bölünmüş eyaletlerde ana (eski) eyalet id'si; çağ/senaryo kodu parçaları birlikte taşır
	var is_capital := false
	var coastal := false
	var core := -1
	var unrest := 0
	var acquired := 0
	var home := -1                           # başlangıç sahibi
	var found := ""                          # keşif: "" aranmadı, "-" arandı/bulunamadı, aksi halde bulunan kaynak (oil/mine/wood)
	var bld := ""                            # tamamlanmış gelir binası ("farm","mine","oil","press"; boş = yok)
	var bld_wip := ""                        # inşaat halindeki bina
	var bld_until := 0                       # inşaatın biteceği tur

	func income() -> int:
		return 1 + dev + int(sqrt(maxf(pop, 0.0)) * 0.6)

	func rich() -> String:
		if found != "" and found != "-":
			return found
		var b: Dictionary = RichStore.bands.get(home, {})
		if b.is_empty():
			return ""
		var h: int = int((id * 2654435761) % 100)
		var lo := 0
		for k in ["oil", "mine", "farm"]:
			var w: int = int(b.get(k, 0))
			if h >= lo and h < lo + w:
				return k
			lo += w
		var ww: int = int(b.get("wood", 0))
		if ww > 0 and int((id * 40503 + 17) % 100) < ww:
			return "wood"
		return ""

	func rev() -> float:
		var bonus: float = BLD.get(bld, {}).get("bonus", 0.0)
		if bld != "" and bld == rich():
			bonus *= RICH_BONUS
		return gdp * 0.17 / 52.0 * (1.0 + bonus)   # haftalık devlet geliri, milyon $

	func base_rev() -> float:
		return gdp * 0.17 / 52.0

	func bld_cost(kind: String) -> float:
		return maxf(12.0, base_rev() * float(BLD[kind].mult)) * (1.0 + 0.4 * float(is_capital)) * (RICH_COST if kind == rich() else 1.0)

	func value() -> int:
		return 1 + int(dev * 0.5) + (4 if is_capital else 0) + (1 if pop >= 25.0 else 0)

	func siege_needed() -> int:
		return 4 + int(defense * 1.5) + (2 if is_capital else 0) + (1 if pop >= 6.0 else 0) + (1 if pop >= 30.0 else 0)

	func peace_cost() -> int:
		return value() * 6

	func title() -> String:
		return name if city == "" or city == name else "%s (%s)" % [name, city]


class Country:
	var id := 0
	var a3 := ""
	var iso := ""
	var name := ""
	var name_en := ""
	var origin_en := ""          # fief/isyancı devletin çıktığı ülke (kültür: isim, siluet, kabine)
	var continent := ""
	var pop := 0.0                           # milyon
	var gdp := 0.0                           # milyon USD
	var color := Color.WHITE
	var color2 := Color.WHITE
	var color3 := Color.WHITE
	var flag_pattern := 0
	var formed := ""                         # formlanan devletin kimliği (formables.json)
	var flag_spec := ""                      # formlanınca geçerli bayrak tanımı
	var capital := -1
	var gold := 0.0
	var is_player := false
	var alive := true
	var aggression := 0.5
	var enemies: Array = []
	var truce: Dictionary = {}
	var allies: Array = []
	var relation: Dictionary = {}            # diğer ülke id -> ilişki puanı (0-100, varsayılan 50)
	var peace_req_turn: Dictionary = {}      # düşman id -> en son barış/ateşkes teklifi götürülen tur (spam engeli)
	var alliance_req_turn: Dictionary = {}   # hedef id -> en son ittifak teklifi götürülen tur (spam engeli)
	var ult_turn: Dictionary = {}              # hedef id -> en son ültimatom verilen tur
	var passage_req_turn: Dictionary = {}    # hedef id -> en son geçiş izni istenen tur
	var passage: Dictionary = {}             # misafir ülke id -> bu ülkenin topraklarından geçiş iznin bitiş turu
	var is_rebel := false
	var born := 0
	var label_pos := Vector2.ZERO
	var label_w := 0.0
	var total_area := 0
	# her tur yeniden hesaplanan önbellek
	var prov_owned := 0
	var prov_held := 0
	var income := 0.0
	var troops := 0
	var owned_ids: Array = []
	var held_ids: Array = []
	# ---- makro yönetim (macro.gd yönetir)
	var budget: Dictionary = {"mil": 22, "ind": 22, "cyber": 8, "logi": 12, "stab": 14, "res": 10, "edu": 7, "agri": 5}   # yüzde, toplam 100
	var doctrine := 0
	var doctrine_turn := -99
	var industry := 55.0                     # sanayi / fabrika sağlığı 0..100
	var cyber := 20.0                        # siber olgunluk 0..100 (saldırı ve savunma)
	var logistics := 50.0                    # tedarik ağı 0..100
	var stability := 70.0                    # 0..100
	var capacity := 0.8                      # kalkınma düzeyi çarpanı (kişi başı gelirden)
	var trade_income := 0.0
	var trade_share := 0.0                   # aktif ticaret payı 0..1
	var trade_block := 0                     # siber saldırıyla ticaret kesintisi (kalan hafta)
	var embargo: Array = []
	var covert_cd: Dictionary = {}           # hedef ülke id -> yeniden kullanılabileceği tur
	var fronts: Dictionary = {}              # düşman id -> {stance, cyber}
	var recruit_acc := 0.0
	var gold_delta := 0.0
	var fund := 0.0                          # savunma fonu (M$): askerlik + silah alımı bu havuzdan
	var draft := 1                           # askerlik düzeni: 0 gönüllü, 1 normal, 2 zorunlu
	var tax := 1                             # vergi oranı: 0 düşük, 1 normal, 2 yüksek, 3 savaş vergisi
	var mres: Dictionary = {}                # askeri Ar-Ge (milres.gd)
	var goods: Dictionary = {}               # mal ekonomisi (scripts/goods.gd)
	var tech := 0.5                          # silah teknolojisi düzeyi 0..1
	var bloc := "us"
	var inv: Dictionary = {}                 # silah kimliği -> adet
	var orders: Array = []                   # bekleyen teslimatlar [{id, qty, due}]
	var auto_buy := true
	var auto_cmd := false                    # oyuncu: ordular otomatik komuta edilsin mi
	var pri: Dictionary = {"inf": 1.0, "tank": 1.0, "afv": 1.0, "arty": 1.0, "air": 1.0, "sub": 1.0}
	var base_troops := 0
	var mob_until := -1                      # seferberlik bitiş turu (-1: yok)
	var mob_cd := -1                         # seferberlik yeniden ilan edilebilir tur
	var eq_land := 1.0
	var air_pow := 0.0
	var naval_pow := 0.0
	var carriers := -1                       # uçak gemisi grubu sayısı (-1: henüz hesaplanmadı)
	var carrier_extra := 0                   # oyuncunun satın aldıkları (bakım gideri)
	var ship_extra := 0                      # oyuncunun inşa ettirdiği muharebe gemisi grupları (bakım gideri)
	var carrier_cd := -1                     # uçak gemisi saldırısı bekleme turu
	var ratios: Dictionary = {}
	var equip_value := 0.0
	var blockade := 0.0
	var fleet_block := 0.0                   # filo ablukası baskısı 0..0.7 (her tur yeniden hesaplanır, kaydedilmez)
	var sanction_until := -1                 # BM yaptırımı bitiş turu (gelir -%25)
	var partners: Array = []
	var fin: Dictionary = {}                 # son haftalık mali tablo (arayüz için)
	var alliance := -1                       # ittifak bloğu kimliği
	var leader := ""
	var cab: Dictionary = {}                 # oyuncunun kabinesi: rol -> {n,f,q,until,real,why}
	var elect_turn := -1                     # sonraki seçim turu (oyuncu)
	var buffs: Dictionary = {}   # tarihî an/karar etkileri: {"att": [çarpan, bitiş_turu], "def": ..., "recruit": ...}
	var trust := 60.0                        # hükümete güven 0..100 (propaganda.gd)
	var prop := ""                           # seçili propaganda yöntemi ("", oral, press, poster)
	var tech_set := -1.0                     # >=0 ise teknoloji düzeyi sabitlenir (senaryo grupları)


class Army:
	var id := 0
	var owner := 0
	var prov := 0
	var size := 10
	var path: Array = []
	var leaving := false
	var prev_prov := -1
	var op := ""                 # taarruz harekâtı türü (varışta uygulanır)
	var sp_size := 0             # >0: ordunun yalnızca bu kadar askeri yola çıkacak (tur başında ayrılır)
	var sp_path: Array = []
	var sp_op := ""
	var merc := ""               # paralı asker birliği adı (boşsa düzenli ordu)
	var merc_until := -1         # sözleşme bitiş turu
	var hold := false            # oyuncu elle konuşlandırdı: otomatik komut bu orduya dokunmaz
	var sp_hold := false         # ayrılacak müfreze elle konuşlandırılıyor mu
	var splits: Array = []       # ek müfrezeler (ilk müfrezeden sonra): [{n, path, op, hold}] — tek turda 2-4 farklı hedefe bölme
	var cmd_lvl := 0             # komutan seviyesi (0 = komutansız); her seviye +%5 saldırı/savunma
	var cmd_name := ""
	var cmd_wins := 0


class Fleet:
	var id := 0
	var owner := 0
	var zone := ""               # deniz bölgesi kimliği (seas.gd)
	var kind := "surface"        # surface | sub | carrier | transport
	var size := 1.0              # güç (sub: deniz gücü birimi; carrier: grup sayısı; surface: güç; transport: gemi sayısı)
	var path: Array = []         # gidilecek bölge kimlikleri
	var hold := false            # oyuncu elle komuta etti: otomatik komut dokunmaz
	var cargo := 0               # denizde taşınan asker
	var cargo_lvl := 0           # taşınan ordunun komutanı
	var cargo_name := ""
	var cargo_wins := 0
	var cd := 0                  # bombardıman/torpido yeniden kullanılabileceği tur
	var seen := -1               # bu tura kadar açığa çıkmış (denizaltı ateş edince)
	var mission := ""            # "" | "blockade"
	var born := 0
	var name := ""               # oyuncunun verdiği ad ("" = varsayılan "N. Muharebe Filosu")
	var flag := ""               # filo bayrağı (flags.gd tanım dizgesi; "" = ülke bayrağı)
	var xp := 0.0                # muharebe tecrübesi (rütbe: Acemi/Tecrübeli/Elit/Efsane)
	var stance := "attack"       # attack | defend | avoid
	var escort := -1             # eşlik edilen nakliye/filo kimliği (-1 yok)
	var tgt := -1                # YZ çıkarma hedefi (eyalet) ya da -2: dönüyor


class Wing:
	var id := 0
	var owner := 0
	var base := -1               # üs eyaleti
	var kind := "fighter"        # fighter | bomber | drone | transport | recon
	var size := 1.0              # uçak sayısı (ülkenin hava gücünden türetilir)
	var cd := 0                  # yeniden kullanılabileceği tur
	var xp := 0.0
	var stance := "attack"       # attack | defend
	var name := ""
	var flag := ""
	var born := 0
	var tgt := -1                # son saldırı hedefi (çizim için)
	var tgt_turn := -99          # son saldırı turu


class War:
	var a := 0
	var b := 0
	var score_a := 0
	var score_b := 0
	var start := 0

	func other(c: int) -> int:
		return b if c == a else a

	func score_of(c: int) -> int:
		return score_a if c == a else score_b

	func add(c: int, pts: int) -> void:
		if c == a:
			score_a += pts
		else:
			score_b += pts

	func involves(c: int) -> bool:
		return c == a or c == b

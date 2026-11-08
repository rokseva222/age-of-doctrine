extends RefCounted
## Veri modeli: eyalet, ülke, ordu, savaş.

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
	var is_capital := false
	var coastal := false
	var core := -1
	var unrest := 0
	var acquired := 0
	var home := -1                           # başlangıç sahibi

	func income() -> int:
		return 1 + dev + int(sqrt(maxf(pop, 0.0)) * 0.6)

	func rev() -> float:
		return gdp * 0.17 / 52.0                # haftalık devlet geliri, milyon $

	func value() -> int:
		return 1 + int(dev * 0.5) + (4 if is_capital else 0) + (1 if pop >= 25.0 else 0)

	func siege_needed() -> int:
		return 6 + defense * 2 + (3 if is_capital else 0) + (1 if pop >= 6.0 else 0) + (1 if pop >= 30.0 else 0)

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
	var continent := ""
	var pop := 0.0                           # milyon
	var gdp := 0.0                           # milyon USD
	var color := Color.WHITE
	var color2 := Color.WHITE
	var color3 := Color.WHITE
	var flag_pattern := 0
	var capital := -1
	var gold := 0.0
	var is_player := false
	var alive := true
	var aggression := 0.5
	var enemies: Array = []
	var truce: Dictionary = {}
	var allies: Array = []
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
	var budget: Dictionary = {"mil": 25, "ind": 25, "cyber": 10, "logi": 15, "stab": 15, "res": 10}   # yüzde, toplam 100
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
	var tech := 0.5                          # silah teknolojisi düzeyi 0..1
	var bloc := "us"
	var inv: Dictionary = {}                 # silah kimliği -> adet
	var orders: Array = []                   # bekleyen teslimatlar [{id, qty, due}]
	var auto_buy := true
	var auto_cmd := false                    # oyuncu: ordular otomatik komuta edilsin mi
	var pri: Dictionary = {"inf": 1.0, "tank": 1.0, "afv": 1.0, "arty": 1.0, "air": 1.0, "sub": 1.0}
	var base_troops := 0
	var eq_land := 1.0
	var air_pow := 0.0
	var naval_pow := 0.0
	var carriers := -1                       # uçak gemisi grubu sayısı (-1: henüz hesaplanmadı)
	var carrier_extra := 0                   # oyuncunun satın aldıkları (bakım gideri)
	var carrier_cd := -1                     # uçak gemisi saldırısı bekleme turu
	var ratios: Dictionary = {}
	var equip_value := 0.0
	var blockade := 0.0
	var sanction_until := -1                 # BM yaptırımı bitiş turu (gelir -%25)
	var partners: Array = []
	var fin: Dictionary = {}                 # son haftalık mali tablo (arayüz için)
	var alliance := -1                       # ittifak bloğu kimliği
	var leader := ""
	var cab: Dictionary = {}                 # oyuncunun kabinesi: rol -> {n,f,q,until,real,why}
	var elect_turn := -1                     # sonraki seçim turu (oyuncu)
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
	var cmd_lvl := 0             # komutan seviyesi (0 = komutansız); her seviye +%5 saldırı/savunma
	var cmd_name := ""
	var cmd_wins := 0


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

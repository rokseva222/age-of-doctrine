extends RefCounted
## Tarihî dönemlerde (I. ve II. Dünya Savaşı) gerçek olaylar tarihinde haber olarak düşer ve (varsa) etkisini uygular.
## Efekt: ["war", A, B] savaş ilanı, ["peace", A, B] barış, ["ally", A, B] ittifak, ["stab", A, delta] istikrar.
## Oyuncunun ülkesine barış/ittifak/istikrar uygulanmaz (oyuncu karar verir); oyuncuya yönelik saldırı uygulanır.

const EraExt = preload("res://scripts/era_ext.gd")

const EVENTS := [
	{"era": "ww1", "y": 1914, "m": 10, "t": "Osmanlı Devleti Karadeniz'de Rus limanlarını bombalayarak savaşa girdi.", "fx": [["war","Turkey","Russia"]]},
	{"era": "ww1", "y": 1914, "m": 12, "t": "Batı Cephesi'nde Noel ateşkesi: siperlerdeki askerler bir gün silah bıraktı.", "fx": []},
	{"era": "ww1", "y": 1915, "m": 3, "t": "Çanakkale Boğazı'na büyük bir donanma saldırısı: Boğaz'ın kaderi tehlikede.", "fx": []},
	{"era": "ww1", "y": 1915, "m": 5, "t": "İtalya, Avusturya-Macaristan'a savaş ilan ederek İtilaf Devletleri safına geçti.", "fx": [["war","Italy","Austria"]]},
	{"era": "ww1", "y": 1915, "m": 10, "t": "Bulgaristan Merkezi Güçler'e katıldı ve Sırbistan'a saldırdı.", "fx": [["war","Bulgaria","Serbia"]]},
	{"era": "ww1", "y": 1916, "m": 2, "t": "Verdun Muharebesi başladı: Fransa ve Almanya aylarca sürecek bir kan gölüne girdi.", "fx": []},
	{"era": "ww1", "y": 1916, "m": 8, "t": "Romanya İtilaf safında savaşa girdi ve Avusturya-Macaristan'a saldırdı.", "fx": [["war","Romania","Austria"]]},
	{"era": "ww1", "y": 1917, "m": 3, "t": "Rusya'da Şubat Devrimi: çarlık yıkıldı, ülke karışıklığa sürüklendi.", "fx": [["stab","Russia",-25]]},
	{"era": "ww1", "y": 1917, "m": 4, "t": "ABD, Almanya'ya savaş ilan ederek savaşa girdi.", "fx": [["war","United States of America","Germany"]]},
	{"era": "ww1", "y": 1917, "m": 6, "t": "Yunanistan İtilaf safında Merkezi Güçler'e savaş ilan etti.", "fx": [["war","Greece","Bulgaria"]]},
	{"era": "ww1", "y": 1917, "m": 11, "t": "Rusya'da Ekim Devrimi: Bolşevikler iktidarı ele geçirdi.", "fx": [["stab","Russia",-15]]},
	{"era": "ww1", "y": 1918, "m": 3, "t": "Brest-Litovsk Antlaşması: Sovyet Rusya Almanya ile ayrı barış imzaladı.", "fx": [["peace","Russia","Germany"],["peace","Russia","Austria"],["peace","Russia","Turkey"],["peace","Russia","Bulgaria"]]},
	{"era": "ww1", "y": 1918, "m": 11, "t": "11 Kasım Mütarekesi: Batı Cephesi'nde silahlar susuyor.", "fx": [["peace","Germany","France"],["peace","Germany","United Kingdom"],["peace","Germany","Belgium"]]},
	{"era": "ww1", "y": 1919, "m": 6, "t": "Versay Antlaşması imzalandı: savaş sonrası düzen yeniden çiziliyor.", "fx": []},
	{"era": "ww1", "y": 1929, "m": 10, "t": "New York Borsası çöktü: Büyük Buhran dünyayı sarsıyor.", "fx": [["stab","United States of America",-12],["stab","Germany",-10],["stab","United Kingdom",-6]]},
	{"era": "ww1", "y": 1933, "m": 1, "t": "Almanya'da Hitler başbakan oldu.", "fx": [["stab","Germany",-4]]},
	{"era": "ww1", "y": 1939, "m": 9, "t": "Almanya Polonya'ya saldırdı: yeni bir dünya savaşı başlıyor.", "fx": []},
	{"era": "ww2", "y": 1939, "m": 10, "t": "Polonya düştü; Almanya ile SSCB ülkeyi paylaştı.", "fx": []},
	{"era": "ww2", "y": 1940, "m": 4, "t": "Almanya Danimarka ve Norveç'e saldırdı.", "fx": [["war","Germany","Denmark"],["war","Germany","Norway"]]},
	{"era": "ww2", "y": 1940, "m": 5, "t": "Almanya Batı'da büyük taarruz başlattı: Hollanda ve Belçika saldırı altında.", "fx": [["war","Germany","Netherlands"],["war","Germany","Belgium"]]},
	{"era": "ww2", "y": 1940, "m": 6, "t": "Fransa'nın düşüşü: İtalya da Fransa ve Britanya'ya savaş ilan etti.", "fx": [["war","Italy","France"],["war","Italy","United Kingdom"],["stab","France",-20]]},
	{"era": "ww2", "y": 1940, "m": 8, "t": "Britanya Muharebesi: Luftwaffe İngiliz göklerinde.", "fx": []},
	{"era": "ww2", "y": 1940, "m": 9, "t": "Üçlü Pakt imzalandı: Almanya, İtalya ve Japonya ittifak kurdu.", "fx": [["ally","Germany","Japan"],["ally","Italy","Japan"]]},
	{"era": "ww2", "y": 1941, "m": 6, "t": "Barbarossa Harekâtı: Almanya ve müttefikleri SSCB'ye saldırdı.", "fx": [["war","Germany","Russia"],["war","Romania","Russia"],["war","Hungary","Russia"],["war","Finland","Russia"]]},
	{"era": "ww2", "y": 1941, "m": 12, "t": "Pearl Harbor: Japonya ABD ve Britanya'ya saldırdı, Almanya ABD'ye savaş ilan etti.", "fx": [["war","Japan","United States of America"],["war","Japan","United Kingdom"],["war","Japan","Netherlands"],["war","Germany","United States of America"]]},
	{"era": "ww2", "y": 1942, "m": 6, "t": "Midway Muharebesi: Japon donanmasının saldırı gücü kırıldı.", "fx": []},
	{"era": "ww2", "y": 1942, "m": 8, "t": "Stalingrad Muharebesi başladı.", "fx": []},
	{"era": "ww2", "y": 1943, "m": 9, "t": "İtalya ateşkes istedi; Müttefikler Sicilya'dan sonra İtalya'ya çıktı.", "fx": [["peace","Italy","United Kingdom"],["peace","Italy","United States of America"],["stab","Italy",-20]]},
	{"era": "ww2", "y": 1944, "m": 6, "t": "D-Day: Müttefikler Normandiya'ya çıktı.", "fx": []},
	{"era": "ww2", "y": 1944, "m": 8, "t": "Romanya taraf değiştirdi ve Almanya'ya savaş açtı.", "fx": [["peace","Romania","Russia"],["war","Romania","Germany"]]},
	{"era": "ww2", "y": 1944, "m": 9, "t": "Bulgaristan ve Finlandiya Almanya'ya karşı çıktı.", "fx": [["peace","Bulgaria","Russia"],["war","Bulgaria","Germany"],["peace","Finland","Russia"],["war","Finland","Germany"]]},
	{"era": "ww2", "y": 1945, "m": 2, "t": "Türkiye sembolik olarak Almanya ve Japonya'ya savaş ilan etti.", "fx": [["war","Turkey","Germany"],["war","Turkey","Japan"]]},
	{"era": "ww2", "y": 1945, "m": 5, "t": "Avrupa'da savaş sona eriyor: Almanya koşulsuz teslim oldu.", "fx": [["peace","Germany","United Kingdom"],["peace","Germany","Russia"],["peace","Germany","United States of America"],["peace","Germany","France"]]},
	{"era": "ww2", "y": 1945, "m": 8, "t": "Hiroşima ve Nagasaki'ye atom bombaları atıldı; SSCB Japonya'ya savaş açtı.", "fx": [["war","Russia","Japan"],["stab","Japan",-20]]},
	{"era": "ww2", "y": 1945, "m": 9, "t": "Japonya teslim oldu: II. Dünya Savaşı sona erdi.", "fx": [["peace","Japan","United States of America"],["peace","Japan","United Kingdom"],["peace","Japan","Russia"],["peace","Japan","China"]]},
	{"era": "ww2", "y": 1949, "m": 4, "t": "NATO kuruldu: Batı ittifakı şekilleniyor.", "fx": []},
	{"era": "ww2", "y": 1950, "m": 6, "t": "Kore Savaşı başladı.", "fx": []},
]


static func _id(gs, name_en: String) -> int:
	return int(gs.macro_idx.get(name_en, -1))


## ay değiştiğinde o aya düşen olayları uygular
static func tick(gs, era: String, prev_ym: Array, ym: Array) -> void:
	var key: int = int(ym[0]) * 12 + int(ym[1]) - 1
	if prev_ym.size() == 2 and int(prev_ym[0]) * 12 + int(prev_ym[1]) - 1 == key:
		return
	var pool: Array = EraExt.events(era) if EraExt.has_era(era) else EVENTS
	if EraExt.has_era(era) and EraExt.raw(era).has("inherit_until"):
		pool = pool.duplicate()
		pool.append_array(_inherited(era))
	for e in pool:
		if e["era"] != era or int(e["y"]) * 12 + int(e["m"]) - 1 != key:
			continue
		var cap := -1
		for f in e["fx"]:
			_apply(gs, f)
		gs.post_news(String(e["t"]), cap, "event")


## Alternatif çağ: ayrışma tarihine ("inherit_until": [yıl, ay]) kadar base çağın gerçek olayları geçerli
static func _inherited(era: String) -> Array:
	var out: Array = []
	var until: Array = EraExt.raw(era).get("inherit_until", [])
	if until.size() < 2:
		return out
	var ukey: int = int(until[0]) * 12 + int(until[1]) - 1
	var excl: Array = EraExt.raw(era).get("inherit_exclude", [])
	var b: String = EraExt.base_of(era)
	var src: Array = EraExt.events(b) if EraExt.has_era(b) else EVENTS
	for e in src:
		if String(e["era"]) != b or int(e["y"]) * 12 + int(e["m"]) - 1 >= ukey:
			continue
		var skip := false
		for x in excl:
			if String(e["t"]).contains(String(x)):
				skip = true
				break
		if skip:
			continue
		var c: Dictionary = (e as Dictionary).duplicate()
		c["era"] = era
		out.append(c)
	return out


## Dışarıdan (senaryo olayları) da kullanılır
static func apply_fx(gs, f: Array) -> void:
	_apply(gs, f)


static func _apply(gs, f: Array) -> void:
	var a: int = _id(gs, String(f[1]))
	if a < 0 or not gs.countries[a].alive:
		return
	match String(f[0]):
		"stab":
			if a != gs.player:
				gs.countries[a].stability = clampf(gs.countries[a].stability + float(f[2]), 5.0, 100.0)
		"war":
			var b: int = _id(gs, String(f[2]))
			if b >= 0 and gs.countries[b].alive and a != gs.player:
				gs.declare_war(a, b)
		"peace":
			var b2: int = _id(gs, String(f[2]))
			if b2 >= 0 and a != gs.player and b2 != gs.player:
				var w = gs.get_war(a, b2)
				if w != null:
					gs.finish_peace(w, -1, [])
		"ally":
			var b3: int = _id(gs, String(f[2]))
			if b3 >= 0 and gs.countries[b3].alive and a != gs.player and b3 != gs.player and not gs.is_allied(a, b3) and not gs.at_war(a, b3):
				gs.make_alliance(a, b3)

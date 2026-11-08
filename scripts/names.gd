extends RefCounted
const Loc = preload("res://scripts/loc.gd")
## Kurgusal isim üretimi ve "Cihan Bülteni" haber şablonları.
## Not: Ülke/eyalet isimlerine ek getirmemek için (X'e, X'ı...) şablonlar ek almayan kalıplarla yazıldı.

const MONTHS := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
const MONTH_DAYS := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const STEMS := ["Kar", "Vel", "Dor", "Mir", "Zan", "Tur", "Nor", "Sal", "Ben", "Kor", "Ves", "Tal", "Mor", "Ish", "Bra", "Sar", "Lun", "Gar", "Tev", "Hal", "Zen", "Fal", "Dar", "Min", "Pol", "Ayd", "Bor", "Cer", "Dal", "Erz", "Fen", "Gor", "Hav", "Ibr", "Jav", "Kel", "Lor", "Mak", "Nav", "Orm", "Par", "Rav", "Sol", "Tarn", "Ul", "Vor", "Yar", "Zul", "Kara", "Bela", "Sera", "Nora", "Tola", "Mira", "Vala", "Dora", "Kasa", "Ruma", "Teka", "Sova"]
const REBEL_NAMES := ["Bağımsızlık Cephesi", "Gölge Ağı", "Dağ Milisleri", "Halk Birliği", "Özgürlük Ordusu", "Kuzey Direnişi", "Yeraltı Hareketi", "Şafak Tugayı", "Sınır Muhafızları"]
const VOWELS := "aeiou"
const SUF_AFTER_CONS := ["ia", "ora", "onia", "ika", "ium", "land", "stan", "ea", "ovia", "esh", "aria"]
const SUF_AFTER_VOWEL := ["stan", "nia", "ria", "land", "mark", "dor", "nya", "via"]
const PROV_END := ["a", "en", "os", "ar", "ik", "ova", "grad", "pol", "ton", "burg", "heim", "dan", "kent", "abad", "ia", "um", "esh", "ara"]


static func pick(arr: Array, rng: RandomNumberGenerator):
	return arr[rng.randi_range(0, arr.size() - 1)]


static func country_name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	for attempt in 40:
		var stem: String = pick(STEMS, rng)
		var last := stem.substr(stem.length() - 1, 1)
		var suf: String
		if VOWELS.contains(last):
			suf = pick(SUF_AFTER_VOWEL, rng)
		else:
			suf = pick(SUF_AFTER_CONS, rng)
		var nm := stem + suf
		if not used.has(nm):
			used[nm] = true
			return nm
	var fallback := "Ülke%d" % used.size()
	used[fallback] = true
	return fallback


static func province_name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	for attempt in 60:
		var stem: String = pick(STEMS, rng)
		var last := stem.substr(stem.length() - 1, 1)
		var end: String = pick(PROV_END, rng)
		if VOWELS.contains(last) and VOWELS.contains(end.substr(0, 1)):
			continue
		var nm := stem + end
		if not used.has(nm):
			used[nm] = true
			return nm
	var fallback := "Bölge%d" % used.size()
	used[fallback] = true
	return fallback


static var start_year := 2027
static var start_doy := 0                  # yılın kaçıncı günü (0 = 1 Ocak)


static func date_string(turn: int) -> String:
	# Her tur 1 hafta. Varsayılan başlangıç: 1 Ocak 2027 (tarihî kiplerde değişir).
	var days := turn * 7 + start_doy
	var year := start_year + days / 365
	var doy := days % 365
	var m := 0
	while m < 11 and doy >= MONTH_DAYS[m]:
		doy -= MONTH_DAYS[m]
		m += 1
	match Loc.lang:
		"zh", "ja":
			return "%d年%s%d日" % [year, Loc.months[m], doy + 1]
		"ko":
			return "%d년 %s %d일" % [year, Loc.months[m], doy + 1]
	return "%d %s %d" % [doy + 1, Loc.months[m], year]


## [yıl, ay(1-12)]
static func year_month(turn: int) -> Array:
	var days := turn * 7 + start_doy
	var year := start_year + days / 365
	var doy := days % 365
	var m := 0
	while m < 11 and doy >= MONTH_DAYS[m]:
		doy -= MONTH_DAYS[m]
		m += 1
	return [year, m + 1]


# ---------------- Haber şablonları ----------------

static func war_declared(rng: RandomNumberGenerator, a: String, b: String) -> String:
	return pick([
		"%s, %s devletine savaş ilan etti!",
		"Cihan şokta: %s ile %s arasında savaş başladı.",
		"SON DAKİKA: %s orduları %s sınırında harekete geçti.",
		"Diplomasi çöktü: %s, %s devletine cepheyi açtı.",
	], rng) % [a, b]


static func war_on_player(rng: RandomNumberGenerator, a: String) -> String:
	return pick([
		"DİKKAT: %s sana savaş ilan etti!",
		"%s orduları sınırına dayandı. Savaş başladı!",
		"Cihan Bülteni: %s ile savaştasın. Sınırlar ateş altında.",
	], rng) % a


static func war_by_player(rng: RandomNumberGenerator, b: String) -> String:
	return pick([
		"Savaş ilan ettin: %s ile savaştasın.",
		"Cihan senden söz ediyor: %s devletine savaş açtın!",
		"Orduların harekete geçti, hedef: %s.",
	], rng) % b


static func province_captured(rng: RandomNumberGenerator, prov: String, by: String) -> String:
	match rng.randi_range(0, 2):
		0:
			return "%s eyaleti düştü! %s bayrağı dalgalanıyor." % [prov, by]
		1:
			return "%s ordusu %s eyaletini ele geçirdi." % [by, prov]
		_:
			return "Cepheden haber: %s eyaleti artık %s kontrolünde." % [prov, by]


static func player_captured(rng: RandomNumberGenerator, prov: String) -> String:
	return pick([
		"Zafer! %s eyaleti ele geçirildi.",
		"Ordun %s eyaletine girdi, halk şaşkın.",
		"Cihan senden bahsediyor: %s eyaleti artık senin kontrolünde!",
	], rng) % prov


static func player_lost(rng: RandomNumberGenerator, prov: String) -> String:
	return pick([
		"Kayıp: %s eyaleti düşmanın eline geçti!",
		"%s eyaleti işgal edildi, kurtarmalısın!",
		"Kötü haber: %s eyaleti düştü.",
	], rng) % prov


static func peace(rng: RandomNumberGenerator, a: String, b: String) -> String:
	return pick([
		"%s ile %s arasında barış imzalandı.",
		"Silahlar sustu: %s ve %s barışa ulaştı.",
	], rng) % [a, b]


static func annexed(rng: RandomNumberGenerator, winner: String, count: int, names: String) -> String:
	return pick([
		"%s barış masasından %d eyaletle kalktı: %s.",
		"Anlaşma gereği %s, %d eyalet kazandı: %s.",
	], rng) % [winner, count, names]


static func big_battle(rng: RandomNumberGenerator, winner: String, loser: String, prov: String) -> String:
	if rng.randi_range(0, 1) == 0:
		return "Kanlı çatışma! %s ordusu, %s ordusunu %s eyaletinde bozguna uğrattı." % [winner, loser, prov]
	return "%s eyaletinde büyük muharebe: %s galip, %s ağır kayıp verdi." % [prov, winner, loser]


static func eliminated(rng: RandomNumberGenerator, c: String) -> String:
	return pick([
		"%s devleti haritadan silindi.",
		"Tarihe karıştı: %s artık yok.",
	], rng) % c


static func ranking(rng: RandomNumberGenerator, rich: String, army: String, land: String) -> String:
	return "Çeyrek raporu: En güçlü ekonomi %s, en büyük ordu %s, en geniş topraklar %s." % [rich, army, land]


static func event_boom(rng: RandomNumberGenerator, c: String, amount: String) -> String:
	return pick([
		"%s ekonomisinde patlama: hazineye %s girdi.",
		"Borsalar uçuşta! %s hazinesi %s kazandı.",
	], rng) % [c, amount]


static func event_crisis(rng: RandomNumberGenerator, c: String, amount: String) -> String:
	return pick([
		"Ekonomik kriz %s ülkesini vurdu: %s kayıp.",
		"%s hazinesinde açık: %s buharlaştı.",
	], rng) % [c, amount]


static func event_resource(rng: RandomNumberGenerator, prov: String, c: String) -> String:
	return pick([
		"%s eyaletinde zengin maden yatağı bulundu! (%s)",
		"%s eyaletinde petrol rezervi keşfedildi. (%s)",
	], rng) % [prov, c]


static func event_volunteers(rng: RandomNumberGenerator, c: String, n: String) -> String:
	return pick([
		"%s halkı seferber oldu: %s gönüllü orduya katıldı.",
		"Vatan çağrısı! %s ordusuna %s gönüllü yazıldı.",
	], rng) % [c, n]


static func event_quake(rng: RandomNumberGenerator, prov: String, c: String) -> String:
	return "%s eyaletinde deprem! Üretim düştü. (%s)" % [prov, c]


static func rebel_name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	var base: String = pick(REBEL_NAMES, rng)
	var n: int = used.get(base, 0) + 1
	used[base] = n
	return base if n == 1 else "%s %d" % [base, n]


static func rebel_uprising(rng: RandomNumberGenerator, group: String, prov: String, c: String) -> String:
	match rng.randi_range(0, 2):
		0:
			return "İSYAN! %s eyaletinde %s ayaklandı. (%s)" % [prov, group, c]
		1:
			return "%s, %s eyaletinin kontrolünü ele geçirdi. (%s)" % [group, prov, c]
		_:
			return "Huzursuzluk patladı: %s eyaleti %s elinde. (%s)" % [prov, group, c]


static func rebel_crushed(rng: RandomNumberGenerator, group: String) -> String:
	return pick(["%s bastırıldı, direniş sona erdi.", "İsyan bitti: %s dağıldı."], rng) % group


static func independence(rng: RandomNumberGenerator, group: String, country: String, former: String) -> String:
	if rng.randi_range(0, 1) == 0:
		return "%s bağımsızlığını ilan etti! Yeni devlet: %s. (Eski sahibi: %s)" % [group, country, former]
	return "Haritada yeni bir bayrak: %s, %s adıyla devlet kurdu. (Eski sahibi: %s)" % [group, country, former]


static func alliance(rng: RandomNumberGenerator, a: String, b: String) -> String:
	return pick([
		"%s ile %s ittifak kurdu.",
		"Yeni cephe: %s ve %s ittifak imzaladı.",
	], rng) % [a, b]


static func bloc_name(rng: RandomNumberGenerator, country: String, used: Dictionary) -> String:
	var opts := ["%s Paktı", "%s Savunma Birliği", "%s Dayanışma İttifakı", "%s Güvenlik Konseyi", "%s Ortaklığı"]
	for i in 8:
		var n: String = opts[rng.randi_range(0, opts.size() - 1)] % country
		if not used.has(n):
			return n
	return "%s Paktı %d" % [country, used.size() + 1]


static func crisis_start(rng: RandomNumberGenerator, kind: String, weeks: int) -> String:
	return "Dünya krizi: %s başladı; etkileri yaklaşık %d hafta sürecek." % [kind, weeks]


static func crisis_end(rng: RandomNumberGenerator, kind: String) -> String:
	return "%s sona erdi; dünya ekonomisi toparlanıyor." % kind


static func alliance_broken(rng: RandomNumberGenerator, a: String, b: String) -> String:
	return "%s ile %s arasındaki ittifak sona erdi." % [a, b]


static func ally_joined(rng: RandomNumberGenerator, ally: String, friend: String, foe: String) -> String:
	return pick([
		"%s, müttefiki %s için %s ile savaşa girdi.",
		"İttifak devrede: %s, %s uğruna %s devletine karşı cepheyi açtı.",
	], rng) % [ally, friend, foe]


static func independent_name(region: String, used: Dictionary) -> String:
	var base := "%s Cumhuriyeti" % region
	if not used.has(base):
		return base
	var i := 2
	while used.has("%s %d" % [base, i]):
		i += 1
	return "%s %d" % [base, i]

## Yeni olay türleri: {c}=ülke, {p}=eyalet, {a}=miktar
const EVENT_LINES := {
	"virus": [
		"{c} ülkesinde salgın yayılıyor: hastaneler doldu, istikrar sarsıldı.",
		"{p} eyaletinde bulaşıcı hastalık! {c} karantina ilan etti.",
	],
	"flood": [
		"{p} eyaletinde sel felaketi! Altyapı zarar gördü. ({c})",
		"Taşan nehirler {p} eyaletini bastı. ({c})",
	],
	"drought": [
		"{c} ülkesinde kuraklık: hasat çöktü, {a} kayıp.",
		"Kıtlık uyarısı! {c} tarım üretimi düştü, {a} zarar.",
	],
	"storm": [
		"Şiddetli fırtına {c} kıyılarını vurdu: limanlarda {a} hasar.",
		"{p} açıklarında kasırga! {c} liman trafiği durdu.",
	],
	"protest": [
		"{p} eyaletinde büyük protesto! Halk sokakta. ({c})",
		"{c}: hükümet karşıtı gösteriler {p} eyaletinde şiddetlendi.",
	],
	"coup": [
		"Darbe girişimi! {c} yönetimi güçlükle kontrolü korudu.",
		"{c} başkentinde silah sesleri: darbe girişimi bastırıldı.",
	],
	"refugees": [
		"Sınırda mülteci akını: {c} yardım için {a} harcadı.",
		"{p} eyaletine toplu göç! {c} geçici kamplar kurdu.",
	],
	"harvest": [
		"Rekor hasat! {c} çiftçileri {a} ek gelir sağladı.",
		"Bereketli bir yıl: {c} tahıl ihracatı patladı.",
	],
	"science": [
		"{c} bilim insanları teknolojik atılım duyurdu!",
		"{c} araştırma merkezinde çığır açan buluş.",
	],
	"summit": [
		"{c} ev sahipliğinde zirve: diplomatik itibar yükseldi.",
		"Uluslararası zirvede {c} lehine yumuşama. İstikrar arttı.",
	],
}


static func event_line(key: String, rng: RandomNumberGenerator, c: String, prov: String = "", amount: String = "") -> String:
	var t: String = pick(EVENT_LINES[key], rng)
	return t.replace("{c}", c).replace("{p}", prov).replace("{a}", amount)

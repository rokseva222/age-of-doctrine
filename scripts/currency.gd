const Settings = preload("res://scripts/settings.gd")
## Ülkeye göre para birimi gösterimi. İç hesap hep dolar (mn) kalır; yalnızca ekranda oyuncunun ülkesinin parasına çevrilir.
## Kurlar: 1 USD karşılığı, Kasım 2026 başı güncel piyasa verileri (APK'da internet izni yok, bu yüzden gömülü).
## "~" ile başlayan yorumlu olanlar yaklaşık değerdir. Zamanla ±%3 yavaş dalgalanır (deterministik).

static var code := "USD"
static var era_fam := ""            # tarihî çağ ailesi: "" = modern, "pre" = altın, diğerleri USD
static var turn := 0

const RATES := {
	"USD": 1.0, "TRY": 50.455, "EUR": 0.9092, "GBP": 0.7582, "JPY": 159.43, "RUB": 82.60, "CNY": 6.6646,
	"INR": 93.92, "CHF": 0.8396, "CAD": 1.4294, "AUD": 1.4844, "BRL": 5.7838, "MXN": 18.528, "KRW": 1335.29,
	"SAR": 3.7521, "AED": 3.6735, "EGP": 53.69, "ZAR": 16.957, "PLN": 4.003, "SEK": 10.10, "NOK": 9.654,
	"DKK": 6.797, "CZK": 22.20, "HUF": 331.45, "RON": 4.860, "UAH": 45.50, "IDR": 18258.0, "PKR": 276.77,
	"BDT": 124.62, "THB": 33.88, "VND": 25764.0, "MYR": 4.095, "SGD": 1.2881, "PHP": 63.88, "NGN": 1345.7,
	"KES": 130.18, "ARS": 1549.8, "CLP": 999.1, "COP": 3307.7, "PEN": 3.4077, "ILS": 3.2473, "IRR": 44637.0,
	# ~ yaklaşık
	"ETB": 155.0, "TZS": 2600.0, "UGX": 3700.0, "DZD": 132.0, "MAD": 9.9, "GHS": 11.0, "KZT": 520.0, "UZS": 12500.0,
	"IQD": 1310.0, "AFN": 70.0, "JOD": 0.709, "KWD": 0.307, "QAR": 3.64, "OMR": 0.385, "BHD": 0.376, "BGN": 1.778,
	"RSD": 106.0, "MKD": 56.0, "ALL": 85.0, "BAM": 1.778, "MDL": 17.5, "GEL": 2.7, "AMD": 385.0, "AZN": 1.7,
	"BYN": 3.3, "TJS": 10.0, "KGS": 87.0, "TMT": 3.5, "MNT": 3600.0, "LKR": 300.0, "NPR": 150.0, "MMK": 2100.0,
	"KHR": 4050.0, "LAK": 21500.0, "TWD": 31.0, "NZD": 1.7, "ISK": 138.0, "VES": 400.0, "CUP": 24.0, "HTG": 131.0,
	"DOP": 63.0, "GTQ": 7.7, "HNL": 26.0, "NIO": 36.8, "CRC": 500.0, "BOB": 6.9, "PYG": 7500.0, "UYU": 40.0,
	"JMD": 157.0, "TTD": 6.8, "SDG": 600.0, "SSP": 4500.0, "YER": 250.0, "SYP": 13000.0, "LYD": 5.4, "TND": 3.0,
	"MZN": 63.9, "AOA": 912.0, "ZMW": 23.0, "MWK": 1750.0, "ZWG": 26.0, "MGA": 4500.0, "XAF": 596.4, "XOF": 596.4,
	"RWF": 1450.0, "BIF": 2950.0, "CDF": 2300.0, "SOS": 571.0, "ERN": 15.0, "DJF": 177.7, "GNF": 8650.0,
	"SLE": 22.8, "LRD": 190.0, "GMD": 72.0, "MUR": 45.0, "SCR": 14.0, "CVE": 100.7, "STN": 22.8, "MRU": 40.0,
	"BWP": 13.5, "FJD": 2.25, "PGK": 4.1, "SBD": 8.4, "VUV": 120.0, "WST": 2.7, "TOP": 2.4, "XCD": 2.7,
	"BBD": 2.0, "BZD": 2.0, "BSD": 1.0, "GYD": 209.0, "SRD": 38.0, "KPW": 900.0, "KMF": 447.0, "MVR": 15.4,
	"BTN": 93.92, "BND": 1.2881,
}
const SYMBOL := {"USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "CNY": "¥"}   # öbürleri kod olarak yazılır (yazı tipi simge desteği yok)

const EURO := ["de", "fr", "it", "es", "nl", "be", "at", "pt", "gr", "ie", "fi", "sk", "lu", "si", "lv", "lt", "ee", "cy", "mt", "hr",
	"ad", "mc", "sm", "xk", "me"]
const ISO := {
	"tr": "TRY", "us": "USD", "gb": "GBP", "jp": "JPY", "ru": "RUB", "cn": "CNY", "in": "INR", "ch": "CHF", "li": "CHF",
	"ca": "CAD", "au": "AUD", "nr": "AUD", "ki": "AUD", "tv": "AUD", "br": "BRL", "mx": "MXN", "kr": "KRW", "sa": "SAR",
	"ae": "AED", "eg": "EGP", "za": "ZAR", "na": "ZAR", "ls": "ZAR", "sz": "ZAR", "pl": "PLN", "se": "SEK", "no": "NOK",
	"dk": "DKK", "gl": "DKK", "cz": "CZK", "hu": "HUF", "ro": "RON", "ua": "UAH", "id": "IDR", "pk": "PKR", "bd": "BDT",
	"th": "THB", "vn": "VND", "my": "MYR", "sg": "SGD", "bn": "BND", "ph": "PHP", "ng": "NGN", "ke": "KES", "ar": "ARS",
	"cl": "CLP", "co": "COP", "pe": "PEN", "il": "ILS", "ps": "ILS", "ir": "IRR", "et": "ETB", "tz": "TZS", "ug": "UGX",
	"dz": "DZD", "ma": "MAD", "eh": "MAD", "gh": "GHS", "kz": "KZT", "uz": "UZS", "iq": "IQD", "af": "AFN", "jo": "JOD",
	"kw": "KWD", "qa": "QAR", "om": "OMR", "bh": "BHD", "bg": "BGN", "rs": "RSD", "mk": "MKD", "al": "ALL", "ba": "BAM",
	"md": "MDL", "ge": "GEL", "am": "AMD", "az": "AZN", "by": "BYN", "tj": "TJS", "kg": "KGS", "tm": "TMT", "mn": "MNT",
	"lk": "LKR", "np": "NPR", "mm": "MMK", "kh": "KHR", "la": "LAK", "tw": "TWD", "nz": "NZD", "is": "ISK", "ve": "VES",
	"cu": "CUP", "ht": "HTG", "do": "DOP", "gt": "GTQ", "hn": "HNL", "ni": "NIO", "cr": "CRC", "bo": "BOB", "py": "PYG",
	"uy": "UYU", "jm": "JMD", "tt": "TTD", "sd": "SDG", "ss": "SSP", "ye": "YER", "sy": "SYP", "ly": "LYD", "tn": "TND",
	"mz": "MZN", "ao": "AOA", "zm": "ZMW", "mw": "MWK", "zw": "ZWG", "mg": "MGA", "rw": "RWF", "bi": "BIF", "cd": "CDF",
	"so": "SOS", "er": "ERN", "dj": "DJF", "gn": "GNF", "sl": "SLE", "lr": "LRD", "gm": "GMD", "mu": "MUR", "sc": "SCR",
	"cv": "CVE", "st": "STN", "mr": "MRU", "bw": "BWP", "fj": "FJD", "pg": "PGK", "sb": "SBD", "vu": "VUV", "ws": "WST",
	"to": "TOP", "ag": "XCD", "dm": "XCD", "gd": "XCD", "kn": "XCD", "lc": "XCD", "vc": "XCD", "bb": "BBD", "bz": "BZD",
	"bs": "BSD", "gy": "GYD", "sr": "SRD", "kp": "KPW", "km": "KMF", "mv": "MVR", "bt": "BTN",
	"cm": "XAF", "td": "XAF", "cf": "XAF", "cg": "XAF", "ga": "XAF", "gq": "XAF",
	"ci": "XOF", "sn": "XOF", "ml": "XOF", "bf": "XOF", "ne": "XOF", "bj": "XOF", "tg": "XOF", "gw": "XOF",
}


static func for_iso(iso: String) -> String:
	if EURO.has(iso):
		return "EUR"
	return ISO.get(iso, "USD")


## Oyuncunun ülkesine göre ekran para birimini ayarlar. Ayar kapalıysa USD.
static func sync(gs) -> void:
	if gs == null:
		code = "USD"
		return
	turn = gs.turn
	var c = gs.countries[gs.player] if gs.player >= 0 and gs.player < gs.countries.size() else null
	code = for_iso(str(c.iso)) if c != null and "iso" in c else "USD"


static func active() -> String:
	if era_fam != "":
		return "GOLD" if era_fam == "pre" else "USD"     # tarihî çağda yerel para kuru anlamsız: eski çağda altın, yakın çağda dolar
	return code if Settings.currency else "USD"


## 1 USD'nin şu anki değeri (yavaşça dalgalanan).
static func rate(cur: String = "") -> float:
	if cur == "":
		cur = active()
	var base: float = RATES.get(cur, 1.0)
	if cur == "USD" or cur == "GOLD":
		return 1.0
	var h := absi(hash(cur))
	var ph := float(h % 628) / 100.0
	var amp := 0.015 + float((h >> 8) % 20) / 1000.0     # %1,5 – %3,5
	return base * (1.0 + amp * sin(float(turn) * 0.045 + ph) + amp * 0.4 * sin(float(turn) * 0.13 + ph * 2.0))


## Dolar (mn) → ekran para birimi (mn)
static func conv(usd_mn: float) -> float:
	return usd_mn * rate()


static func symbol_front() -> String:
	return str(SYMBOL.get(active(), ""))


static func suffix() -> String:
	if active() == "GOLD":
		return " altın"
	return "" if SYMBOL.has(active()) else " " + active()

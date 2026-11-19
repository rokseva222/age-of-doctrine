extends RefCounted
## Ülke renkleri: bayrağın/kimliğin akla getirdiği sakin ("soylu") tonlar. Listede olmayan ülkeler
## kara paletinden, komşularından en uzak tonla boyanır. Komşu ülkeler birbirine yakın olmasın diye
## IDENT sabitleri tools/color_test.gd ile denetlenir.

const IDENT := {
	# Avrupa
	"Russia": "7fb4d6", "Ukraine": "e2c24a", "Belarus": "86a05f", "Poland": "c8727a", "Germany": "7b7f88", "France": "5679b8",
	"United Kingdom": "a8505f", "Ireland": "4f9a66", "Spain": "cf9a45", "Portugal": "3f8a62", "Italy": "55a08a", "Netherlands": "dc8a3e",
	"Belgium": "b9a14a", "Switzerland": "d65a52", "Austria": "b54f56", "Hungary": "7fa35e", "Czechia": "4f80b4", "Slovakia": "6b91c8",
	"Romania": "d8b43c", "Bulgaria": "5f9a5a", "Serbia": "a8506f", "Croatia": "c4605f", "Greece": "4a88cc", "Turkey": "cf4a47",
	"Sweden": "3f7fb8", "Norway": "b34d5c", "Denmark": "c8636a", "Finland": "93b9d4", "Iceland": "5a7fa0", "Estonia": "6a9bb8",
	"Latvia": "8f4455", "Lithuania": "d0b04a", "Moldova": "d9a252", "Albania": "a63f48", "North Macedonia": "d4863a", "Montenegro": "7a6a8f",
	"Bosnia and Herz.": "6a79b0", "Slovenia": "5a8fb0", "Kosovo": "7088b8", "Luxembourg": "6aa5c8", "Cyprus": "c09a6a", "N. Cyprus": "b8574f",
	"Malta": "c05a5a", "Monaco": "c05050", "Liechtenstein": "5a6fa8", "Andorra": "7a6aa0", "San Marino": "7fb0d0", "Greenland": "c0d0d8",
	# Asya
	"China": "bf4b3f", "India": "e08c3e", "Japan": "d9bfb8", "South Korea": "6a90c8", "North Korea": "8d4a4a", "Taiwan": "5f8fb0",
	"Mongolia": "4fa3c2", "Kazakhstan": "58b4cc", "Uzbekistan": "4fa6a0", "Turkmenistan": "5f8f50", "Kyrgyzstan": "c46a5a", "Tajikistan": "a07a5a",
	"Azerbaijan": "4f9aa8", "Armenia": "d1703a", "Georgia": "a8566a", "Iran": "5ea36a", "Iraq": "7a8a5a", "Syria": "8d5f5f", "Lebanon": "4f9a6a",
	"Israel": "6593d4", "Palestine": "5f8a5a", "Jordan": "a85f4a", "Saudi Arabia": "2f8f5a", "Yemen": "9a4f4f", "Oman": "b04f4f", "United Arab Emirates": "4f7a5a",
	"Qatar": "8a3f5a", "Kuwait": "6a9a6a", "Bahrain": "b04a55", "Afghanistan": "6a6a6a", "Pakistan": "3f8a52", "Bangladesh": "3f9a7a", "Sri Lanka": "c09a3a",
	"Nepal": "b0485a", "Bhutan": "d08a3a", "Maldives": "4a8a8a", "Myanmar": "c2a43a", "Thailand": "7a5ea5", "Laos": "b05a6a", "Cambodia": "a84a5f",
	"Vietnam": "d04f3f", "Malaysia": "5a6fb8", "Singapore": "d86a6a", "Indonesia": "c2463f", "Philippines": "3f6fb8", "Brunei": "d4b43a", "Timor-Leste": "a8503f",
	"Papua New Guinea": "7a5a3f", "Somaliland": "5f9a8a",
	# Afrika
	"Egypt": "cfa862", "Libya": "4a8a50", "Tunisia": "c85a5a", "Algeria": "3f8f6a", "Morocco": "b04a50", "W. Sahara": "c0a070", "Mauritania": "5a9a4a",
	"Mali": "c2a43a", "Niger": "d08a4a", "Chad": "4a6aa8", "Sudan": "c27a4a", "S. Sudan": "5f8f50", "Ethiopia": "b9c04a", "Eritrea": "6aa0c8", "Somalia": "5a9ad0",
	"Djibouti": "6aaeca", "Kenya": "6a3f3f", "Uganda": "c8a03a", "Tanzania": "4a9a7a", "Rwanda": "5a8fb8", "Burundi": "a85a4a", "Dem. Rep. Congo": "4a8fc4",
	"Congo": "7aa03f", "Gabon": "4a9a8f", "Eq. Guinea": "7a9a50", "Cameroon": "5aa05a", "Central African Rep.": "a07a9a", "Nigeria": "3f9a5a", "Benin": "c2b04a",
	"Togo": "5a9a5f", "Ghana": "d0a03a", "Côte d'Ivoire": "d98a3a", "Burkina Faso": "b0584a", "Senegal": "7aa84a", "Gambia": "5a7ab0", "Guinea": "b0764a",
	"Guinea-Bissau": "a04a5a", "Sierra Leone": "4a9aa8", "Liberia": "9a4a6a", "Angola": "9a3f3f", "Zambia": "5aa04f", "Zimbabwe": "c2a03a", "Mozambique": "4a8a6a",
	"Malawi": "b0504a", "Namibia": "4a7fb0", "Botswana": "6aa5d0", "South Africa": "c9a03f", "eSwatini": "7a5a9a", "Lesotho": "4a7a9a", "Madagascar": "c05a6a",
	"Mauritius": "b0505f", "Seychelles": "4a8fb0", "Comoros": "6aa07a", "Cabo Verde": "4f7ab0", "São Tomé and Principe": "6aa04f",
	# Amerika
	"United States of America": "6c5ba8", "Canada": "dc7a3a", "Mexico": "4a9a5a", "Guatemala": "6aa5cf", "Belize": "5a7ab0", "Honduras": "4a7fb8", "El Salvador": "5a8fc0",
	"Nicaragua": "6a9ab0", "Costa Rica": "c2606a", "Panama": "b0504f", "Cuba": "4a6ab4", "Haiti": "5a5fa8", "Dominican Rep.": "b04f6a", "Jamaica": "c0a43a",
	"Bahamas": "4aa0a8", "Barbados": "5a6ab0", "Trinidad and Tobago": "b04a4a", "Colombia": "d4b341", "Venezuela": "c8a640", "Guyana": "5aa05a", "Suriname": "6aa05a",
	"Ecuador": "e0b24a", "Peru": "c25a55", "Bolivia": "5a9a5a", "Brazil": "6fae4a", "Paraguay": "b04a6a", "Uruguay": "7ab0d8", "Argentina": "6ab5e2", "Chile": "b84f5e",
	"Antigua and Barb.": "b04a5a", "Saint Lucia": "5a9ad0", "Grenada": "5a9a50", "St. Kitts and Nevis": "5a9a6a", "St. Vin. and Gren.": "5a9a7a", "Dominica": "4a9a5f",
	# Okyanusya
	"Australia": "3f78b4", "New Zealand": "2f5a80", "Fiji": "6aa5c8", "Solomon Is.": "5a8f5a", "Vanuatu": "b0584a", "Samoa": "b04a5a", "Tonga": "c05a5a",
	"Micronesia": "5a90c8", "Palau": "5aa0c8", "Marshall Is.": "5a6fb0", "Kiribati": "c05a5a", "Nauru": "5a7ab0", "Tuvalu": "6aa0c8",
}

## Kimlik rengi AYNEN korunan ülkeler (adı geçen / büyük devletler). Diğerlerinin rengi, komşularıyla çakışırsa
## kendi tonuna en yakın ayırt edilebilir tona kaydırılır.
const ANCHORS := ["Russia", "Ukraine", "Turkey", "Greece", "China", "India", "United States of America", "Canada", "Brazil", "Germany", "France", "United Kingdom",
	"Japan", "Italy", "Spain", "Poland", "Saudi Arabia", "Egypt", "Australia", "Argentina", "Mexico", "Israel", "South Africa", "Pakistan", "Nigeria", "Sweden", "Norway",
	"Netherlands", "Indonesia", "Thailand", "South Korea", "Ethiopia", "Algeria", "Colombia", "Peru"]

## Listede olmayan ülkeler için sakin palet (H, S, V)
const MUTED := [
	[8, 0.45, 0.72], [28, 0.50, 0.78], [44, 0.45, 0.78], [72, 0.38, 0.66], [130, 0.36, 0.60], [168, 0.44, 0.60], [195, 0.40, 0.72],
	[215, 0.42, 0.74], [240, 0.34, 0.74], [272, 0.32, 0.70], [318, 0.34, 0.70], [350, 0.38, 0.78], [34, 0.36, 0.60], [48, 0.20, 0.72],
]


static func ident(name_en: String) -> Color:
	return Color(IDENT[name_en]) if IDENT.has(name_en) else Color(0, 0, 0, 0)


static func has(name_en: String) -> bool:
	return IDENT.has(name_en)


## İki rengin algısal uzaklığı (basit ağırlıklı RGB)
static func dist(a: Color, b: Color) -> float:
	var rm: float = (a.r + b.r) * 0.5
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt((2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db)

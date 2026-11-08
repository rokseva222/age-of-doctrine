extends RefCounted
## Tarihî dönemlerde (I. ve II. Dünya Savaşı) liderler rastgele değişmez: gerçek halef zinciri tarihine göre işler.
## Zincir bitince (ufuk yılı) normal rastgele değişim devam eder.
## Biçim: ülke (name_en) -> [[yıl, ay, "Unvan|İsim"], ...]  (başlangıç lideri eras.gd DEFS içindedir)

const EraExt = preload("res://scripts/era_ext.gd")

const HORIZON := {"ww1": 1940, "ww2": 1952}

const CHAIN := {
	"ww1": {
		"Germany": [[1918, 11, "Şansölye|Friedrich Ebert"], [1919, 2, "Cumhurbaşkanı|Friedrich Ebert"], [1925, 5, "Cumhurbaşkanı|Paul von Hindenburg"], [1934, 8, "Reich Şansölyesi|Adolf Hitler"]],
		"Austria": [[1916, 11, "İmparator|I. Karl"], [1918, 11, "Başkan|Karl Seitz"], [1920, 12, "Cumhurbaşkanı|Michael Hainisch"], [1928, 12, "Cumhurbaşkanı|Wilhelm Miklas"]],
		"Turkey": [[1918, 7, "Sultan|VI. Mehmed Vahdeddin"], [1922, 11, "Halife|II. Abdülmecid"], [1923, 10, "Cumhurbaşkanı|Mustafa Kemal Atatürk"], [1938, 11, "Cumhurbaşkanı|İsmet İnönü"]],
		"Russia": [[1917, 3, "Başbakan|Georgi Lvov"], [1917, 7, "Başbakan|Aleksandr Kerenski"], [1917, 11, "Halk Komiserleri Başkanı|Vladimir Lenin"], [1924, 1, "Genel Sekreter|Josef Stalin"]],
		"United Kingdom": [[1916, 12, "Başbakan|David Lloyd George"], [1922, 10, "Başbakan|Bonar Law"], [1923, 5, "Başbakan|Stanley Baldwin"], [1924, 1, "Başbakan|Ramsay MacDonald"],
			[1924, 11, "Başbakan|Stanley Baldwin"], [1929, 6, "Başbakan|Ramsay MacDonald"], [1935, 6, "Başbakan|Stanley Baldwin"], [1937, 5, "Başbakan|Neville Chamberlain"]],
		"France": [[1920, 2, "Cumhurbaşkanı|Paul Deschanel"], [1920, 9, "Cumhurbaşkanı|Alexandre Millerand"], [1924, 6, "Cumhurbaşkanı|Gaston Doumergue"], [1931, 6, "Cumhurbaşkanı|Paul Doumer"],
			[1932, 5, "Cumhurbaşkanı|Albert Lebrun"], [1938, 4, "Başbakan|Édouard Daladier"]],
		"Italy": [[1922, 10, "Başbakan|Benito Mussolini"]],
		"Japan": [[1926, 12, "İmparator|Hirohito"]],
		"United States of America": [[1921, 3, "Başkan|Warren G. Harding"], [1923, 8, "Başkan|Calvin Coolidge"], [1929, 3, "Başkan|Herbert Hoover"], [1933, 3, "Başkan|Franklin D. Roosevelt"]],
		"Serbia": [[1921, 8, "Kral|I. Aleksandar"], [1934, 10, "Naip|Prens Paul"]],
		"Belgium": [[1934, 2, "Kral|III. Leopold"]],
		"Bulgaria": [[1918, 10, "Çar|III. Boris"]],
		"Romania": [[1914, 10, "Kral|I. Ferdinand"], [1927, 7, "Kral|I. Mihai"], [1930, 6, "Kral|II. Carol"]],
		"Greece": [[1917, 6, "Kral|I. Aleksandros"], [1920, 12, "Kral|I. Konstantinos"], [1922, 9, "Kral|II. Georgios"], [1924, 3, "Cumhurbaşkanı|Pavlos Kountouriotis"],
			[1929, 12, "Cumhurbaşkanı|Alexandros Zaimis"], [1935, 11, "Kral|II. Georgios"], [1936, 4, "Başbakan|Ioannis Metaxas"]],
		"China": [[1916, 6, "Başkan|Li Yuanhong"], [1917, 8, "Başkan|Feng Guozhang"], [1918, 10, "Başkan|Xu Shichang"], [1922, 6, "Başkan|Li Yuanhong"], [1923, 10, "Başkan|Cao Kun"],
			[1924, 11, "Başkan|Duan Qirui"], [1927, 6, "Başkomutan|Zhang Zuolin"], [1928, 10, "Başkomutan|Çan Kay-şek"]],
		"Spain": [[1923, 9, "Diktatör|Miguel Primo de Rivera"], [1930, 1, "Başbakan|Dámaso Berenguer"], [1931, 4, "Cumhurbaşkanı|Niceto Alcalá-Zamora"],
			[1936, 5, "Cumhurbaşkanı|Manuel Azaña"], [1939, 4, "Caudillo|Francisco Franco"]],
		"Sweden": [[1932, 9, "Başbakan|Per Albin Hansson"]],
		"Norway": [],
		"Denmark": [[1929, 4, "Başbakan|Thorvald Stauning"]],
		"Portugal": [[1915, 5, "Başkan|Teófilo Braga"], [1915, 10, "Başkan|Bernardino Machado"], [1917, 12, "Başkan|Sidónio Pais"], [1918, 12, "Başkan|João do Canto e Castro"],
			[1919, 10, "Başkan|António José de Almeida"], [1923, 10, "Başkan|Manuel Teixeira Gomes"], [1925, 12, "Başkan|Bernardino Machado"], [1926, 5, "Başkan|Mendes Cabeçadas"],
			[1926, 6, "Başkan|Gomes da Costa"], [1926, 7, "Başkan|Óscar Carmona"], [1932, 7, "Başbakan|António de Oliveira Salazar"]],
		"Canada": [[1920, 7, "Başbakan|Arthur Meighen"], [1921, 12, "Başbakan|William Lyon Mackenzie King"], [1926, 6, "Başbakan|Arthur Meighen"], [1926, 9, "Başbakan|William Lyon Mackenzie King"],
			[1930, 8, "Başbakan|R. B. Bennett"], [1935, 10, "Başbakan|William Lyon Mackenzie King"]],
		"Australia": [[1914, 9, "Başbakan|Andrew Fisher"], [1915, 10, "Başbakan|Billy Hughes"], [1923, 2, "Başbakan|Stanley Bruce"], [1929, 10, "Başbakan|James Scullin"],
			[1932, 1, "Başbakan|Joseph Lyons"], [1939, 4, "Başbakan|Robert Menzies"]],
		"New Zealand": [[1925, 5, "Başbakan|Gordon Coates"], [1928, 12, "Başbakan|Joseph Ward"], [1930, 5, "Başbakan|George Forbes"], [1935, 12, "Başbakan|Michael Joseph Savage"]],
		"South Africa": [[1919, 9, "Başbakan|Jan Smuts"], [1924, 6, "Başbakan|J. B. M. Hertzog"], [1939, 9, "Başbakan|Jan Smuts"]],
		"Iran": [[1925, 12, "Şah|Rıza Pehlevi"]],
		"Thailand": [[1925, 11, "Kral|Prajadhipok"], [1932, 6, "Başbakan|Phraya Manopakorn"], [1933, 6, "Başbakan|Phraya Phahon"], [1938, 12, "Başbakan|Plaek Phibunsongkhram"]],
		"Brazil": [[1914, 11, "Başkan|Venceslau Brás"], [1918, 11, "Başkan|Delfim Moreira"], [1919, 7, "Başkan|Epitácio Pessoa"], [1922, 11, "Başkan|Artur Bernardes"],
			[1926, 11, "Başkan|Washington Luís"], [1930, 11, "Başkan|Getúlio Vargas"]],
		"Argentina": [[1916, 10, "Başkan|Hipólito Yrigoyen"], [1922, 10, "Başkan|Marcelo T. de Alvear"], [1928, 10, "Başkan|Hipólito Yrigoyen"], [1930, 9, "Başkan|José Félix Uriburu"],
			[1932, 2, "Başkan|Agustín P. Justo"], [1938, 2, "Başkan|Roberto Ortiz"]],
	},
	"ww2": {
		"Germany": [[1945, 5, "Devlet Başkanı|Karl Dönitz"], [1949, 9, "Şansölye|Konrad Adenauer"]],
		"Russia": [],
		"United Kingdom": [[1940, 5, "Başbakan|Winston Churchill"], [1945, 7, "Başbakan|Clement Attlee"], [1951, 10, "Başbakan|Winston Churchill"]],
		"France": [[1940, 3, "Başbakan|Paul Reynaud"], [1940, 7, "Devlet Başkanı|Philippe Pétain"], [1944, 8, "Başbakan|Charles de Gaulle"], [1946, 1, "Başbakan|Félix Gouin"],
			[1946, 6, "Başbakan|Georges Bidault"], [1947, 1, "Cumhurbaşkanı|Vincent Auriol"]],
		"Italy": [[1943, 7, "Başbakan|Pietro Badoglio"], [1944, 6, "Başbakan|Ivanoe Bonomi"], [1945, 12, "Başbakan|Alcide De Gasperi"]],
		"Japan": [],
		"United States of America": [[1945, 4, "Başkan|Harry S. Truman"]],
		"China": [],
		"Poland": [[1939, 10, "Cumhurbaşkanı|Władysław Raczkiewicz"], [1947, 2, "Cumhurbaşkanı|Bolesław Bierut"]],
		"Serbia": [[1941, 3, "Kral|II. Petar"], [1945, 11, "Başbakan|Josip Broz Tito"]],
		"Netherlands": [[1948, 9, "Kraliçe|Juliana"]],
		"Belgium": [[1944, 9, "Naip|Prens Charles"], [1951, 7, "Kral|I. Baudouin"]],
		"Spain": [],
		"Turkey": [[1950, 5, "Cumhurbaşkanı|Celal Bayar"]],
		"Romania": [[1940, 9, "Başbakan|Ion Antonescu"], [1944, 8, "Başbakan|Constantin Sănătescu"], [1944, 12, "Başbakan|Nicolae Rădescu"], [1945, 3, "Başbakan|Petru Groza"]],
		"Canada": [[1948, 11, "Başbakan|Louis St. Laurent"]],
		"Australia": [[1941, 8, "Başbakan|Arthur Fadden"], [1941, 10, "Başbakan|John Curtin"], [1945, 7, "Başbakan|Ben Chifley"], [1949, 12, "Başbakan|Robert Menzies"]],
		"New Zealand": [[1940, 4, "Başbakan|Peter Fraser"], [1949, 12, "Başbakan|Sidney Holland"]],
		"South Africa": [[1948, 6, "Başbakan|D. F. Malan"]],
		"Denmark": [[1942, 5, "Başbakan|Vilhelm Buhl"], [1942, 11, "Başbakan|Erik Scavenius"], [1945, 5, "Başbakan|Vilhelm Buhl"], [1945, 11, "Başbakan|Knud Kristensen"],
			[1947, 11, "Başbakan|Hans Hedtoft"], [1950, 10, "Başbakan|Erik Eriksen"]],
		"Sweden": [[1946, 10, "Başbakan|Tage Erlander"]],
		"Finland": [[1940, 12, "Cumhurbaşkanı|Risto Ryti"], [1944, 8, "Cumhurbaşkanı|Carl Gustaf Mannerheim"], [1946, 3, "Cumhurbaşkanı|Juho Kusti Paasikivi"]],
		"Hungary": [[1944, 10, "Ulus Önderi|Ferenc Szálasi"], [1944, 12, "Başbakan|Béla Miklós"], [1946, 2, "Cumhurbaşkanı|Zoltán Tildy"], [1948, 8, "Cumhurbaşkanı|Árpád Szakasits"],
			[1950, 4, "Devlet Başkanı|Sándor Rónai"]],
		"Bulgaria": [[1943, 8, "Naip|Prens Kiril"], [1944, 9, "Başbakan|Kimon Georgiev"], [1946, 11, "Başbakan|Georgi Dimitrov"], [1949, 7, "Başbakan|Vasil Kolarov"], [1950, 2, "Başbakan|Vulko Chervenkov"]],
		"Greece": [[1941, 1, "Başbakan|Alexandros Koryzis"], [1941, 4, "Başbakan|Emmanouil Tsouderos"], [1944, 4, "Başbakan|Georgios Papandreou"], [1945, 1, "Başbakan|Nikolaos Plastiras"],
			[1945, 11, "Başbakan|Themistoklis Sophoulis"], [1946, 4, "Başbakan|Konstantinos Tsaldaris"], [1947, 9, "Başbakan|Themistoklis Sophoulis"]],
		"Norway": [],
		"Portugal": [],
		"Iran": [[1941, 9, "Şah|Muhammed Rıza Pehlevi"]],
		"Egypt": [],
		"Iraq": [],
		"Saudi Arabia": [],
		"Thailand": [[1944, 8, "Başbakan|Khuang Aphaiwong"], [1945, 9, "Başbakan|Seni Pramoj"], [1946, 1, "Başbakan|Khuang Aphaiwong"], [1946, 3, "Başbakan|Pridi Banomyong"],
			[1946, 8, "Başbakan|Thawan Thamrongnawasawat"], [1947, 11, "Başbakan|Khuang Aphaiwong"], [1948, 4, "Başbakan|Plaek Phibunsongkhram"]],
		"Brazil": [[1945, 10, "Başkan|José Linhares"], [1946, 1, "Başkan|Eurico Gaspar Dutra"], [1951, 1, "Başkan|Getúlio Vargas"]],
		"Argentina": [[1940, 7, "Başkan|Ramón Castillo"], [1943, 6, "Başkan|Pedro Pablo Ramírez"], [1944, 3, "Başkan|Edelmiro Farrell"], [1946, 6, "Başkan|Juan Perón"]],
		"Mexico": [[1940, 12, "Başkan|Manuel Ávila Camacho"], [1946, 12, "Başkan|Miguel Alemán"]],
		"Mongolia": [],
		"Ireland": [[1948, 2, "Taoiseach|John A. Costello"], [1951, 6, "Taoiseach|Éamon de Valera"]],
		"Slovakia": [[1945, 4, "Cumhurbaşkanı|Edvard Beneš"], [1948, 6, "Cumhurbaşkanı|Klement Gottwald"]],
	},
}


## Tarihî zincir bu turda hâlâ geçerli mi? (rastgele değişim bu sürede kapalı)
static func chain_active(era: String, year: int) -> bool:
	return era != "" and horizon_of(era) > 0 and year < horizon_of(era)


static func horizon_of(era: String) -> int:
	var src: String = EraExt.leaders_src(era)
	if EraExt.has_era(src):
		return EraExt.horizon(src)
	return int(HORIZON.get(src, -1))


static func chain_of(era: String) -> Dictionary:
	var src: String = EraExt.leaders_src(era)
	return EraExt.chain(src) if EraExt.has_era(src) else CHAIN.get(src, {})


## Bu turda ayına giren (ayın ilk turu) liderler değişir. Değişen ülkelerin id listesini döndürür.
static func tick(gs, era: String, prev_ym: Array, ym: Array) -> Array:
	var changed: Array = []
	var chains: Dictionary = chain_of(era)
	if chains.is_empty():
		return changed
	var key: int = int(ym[0]) * 12 + int(ym[1]) - 1
	if prev_ym.size() == 2 and int(prev_ym[0]) * 12 + int(prev_ym[1]) - 1 == key:
		return changed
	for c in gs.countries:
		if not c.alive or c.id == gs.player or c.is_rebel:
			continue
		var ch: Array = chains.get(c.name_en, [])
		var pick := ""
		for e in ch:
			if int(e[0]) * 12 + int(e[1]) - 1 == key:
				pick = String(e[2])      # aynı ay birden çok kayıt varsa sonuncu geçerli
		if pick != "" and pick != c.leader:
			c.leader = pick
			changed.append(c.id)
	return changed

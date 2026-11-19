extends RefCounted
## Eski çağ (Timur 1380, Osmanlı 1520 gibi "pre" ailesi) kabine kartları: divan, tımar, ulufe, veba, haraç, kale, elçi...
## Biçim cabinet.gd CARDS ile aynıdır. Modern kartlar (siber, basın, borsa, seçim) bu çağlarda çıkmaz.

const CARDS := [
	# ------------------------------------------------------------ ORDU
	{"id": "p_camp", "role": "def", "w": 1.0, "war": 0,
	 "q": "Hükümdarım, {nb} sınırında büyük bir ordugâh kurup atlıları seyrü sefer ettirelim mi? Gövde gösterisi düşmanı ürkütür.",
	 "o": [
		{"t": "Büyük ordugâh", "e": {"g": -0.8, "stab": 2, "aggr": 0.08}, "r": "Bayraklar açıldı, davullar vurdu. Askerin morali yükseldi, komşular tedirgin."},
		{"t": "Küçük akın", "e": {"g": -0.3, "stab": 1}, "r": "Birkaç bin atlı sınırda gezdirildi."},
		{"t": "Gerek yok", "e": {"g": 0.2, "stab": -1}, "r": "Ordu kışlasında kaldı; hazine korundu, sipahiler homurdandı."}]},
	{"id": "p_cannon", "role": "def", "w": 1.0, "war": 0,
	 "q": "Tophane'de yeni bir döküm ocağı kurulabilir. Toplar kuşatmada kaleleri eritir ama demircilere çok altın gider.",
	 "o": [
		{"t": "Büyük döküm", "e": {"g": -1.2, "tech": 0.03, "ind": 3}, "r": "Ocaklar gece gündüz yandı; ilk toplar surların önüne çekildi."},
		{"t": "Birkaç top", "e": {"g": -0.5, "tech": 0.012}, "r": "Birkaç top döküldü, ustalar yetiştiriliyor."},
		{"t": "Ertele", "e": {}, "r": "Döküm ocağı kurulmadı."}]},
	{"id": "p_levy", "role": "def", "w": 0.9, "war": 0,
	 "q": "Tımarlı sipahileri sefere çağırırsak ordu büyür, ama ekin zamanı köyler boşalır.",
	 "o": [
		{"t": "Ferman çıkar", "e": {"troops": 0.06, "stab": -4}, "r": "Atlılar bayraklarının altında toplandı; köylerde buğday yerde kaldı."},
		{"t": "Gönüllü topla", "e": {"g": -0.6, "troops": 0.03}, "r": "Ganimet vaadiyle yiğitler yazıldı."},
		{"t": "Dokunma", "e": {}, "r": "Her şey olduğu gibi kaldı."}]},
	{"id": "p_ulufe", "role": "def", "w": 1.0, "war": 0, "stab_lt": 48,
	 "q": "Kapıkulu ocaklarında ulufe gecikti, kazanlar devrilmeye hazır. Askerlerin gözü ağzında.",
	 "o": [
		{"t": "Ulufeyi öde", "e": {"g": -1.0, "stab": 3}, "r": "Kese kese altın dağıtıldı, ocaklar yatıştı."},
		{"t": "Elebaşıları astır", "e": {"stab": -5}, "r": "Birkaç ağa darağacına çekildi; kışlalarda öfke büyüdü.",
		 "fatal": {"p": 0.08, "k": 0.006, "text": "Askerler kazan kaldırdı, sarayı bastı. Tahttan indirildin."}},
		{"t": "Sözle oyala", "e": {"g": -0.2, "stab": 1}, "r": "Ağalar vaatlerle yatıştırıldı."}]},
	{"id": "p_fort", "role": "def", "w": 0.8, "war": 0,
	 "q": "{nb} sınırındaki kale surları çatlamış, burçlar yıkılmak üzere. Onarım pahalı ama kale sınırın anahtarı.",
	 "o": [
		{"t": "Yeniden yaptır", "e": {"g": -1.0, "stab": 1, "aggr": -0.06}, "r": "Taş ustaları sürülerek surlar ve burçlar yenilendi."},
		{"t": "Yamala", "e": {"g": -0.3}, "r": "Çatlaklar geçici olarak kapatıldı."},
		{"t": "Boş ver", "e": {"aggr": 0.05}, "r": "Kale kaderine terk edildi; komşuların iştahı kabardı."}]},
	{"id": "p_deserters", "role": "def", "w": 1.1, "war": 1,
	 "q": "Kuşatma uzadı, hastalık çıktı. Gece gece askerler bayrak bırakıp köylerine kaçıyor.",
	 "o": [
		{"t": "Ganimet vaat et", "e": {"g": -0.8, "troops": 0.02, "stab": 1}, "r": "Fethedilen şehrin yağması vaadiyle ordu toparlandı."},
		{"t": "Kaçanı astır", "e": {"stab": -3, "troops": -0.01}, "r": "Firarilerin başları kale önüne dizildi; ordu sustu."},
		{"t": "Göz yum", "e": {"troops": -0.04}, "r": "Kaçanlar kaçtı; ordu seyreldi."}]},
	{"id": "p_ammo", "role": "def", "w": 1.3, "war": 1,
	 "q": "Barut ve gülle azalıyor. Cephe için acilen barut değirmenlerinin çalıştırılması lazım.",
	 "o": [
		{"t": "Değirmenleri hızlandır", "e": {"g": -1.0, "ind": 2}, "r": "Barut değirmenleri iki vardiya çalıştı, kağnılar cepheye yola çıktı."},
		{"t": "Ganimetle idare et", "e": {"g": -0.2, "troops": -0.02}, "r": "Eksik mühimmatla savaş sürüyor."}]},
	# ------------------------------------------------------------ DIŞİŞLERİ
	{"id": "p_envoy", "role": "for", "w": 1.0, "war": 0,
	 "q": "{nb} elçisi armağanlarla geldi: hediyeleşme, ticaret izni, belki bir hanedan evliliği. Heyeti nasıl karşılayalım?",
	 "o": [
		{"t": "Şölen ver", "e": {"g": -0.4, "aggr": -0.1, "nbrel": 12, "stab": 1}, "r": "Üç gün şölen verildi, iki saray arasında ipek ve hediye gidip geldi."},
		{"t": "Soğuk karşıla", "e": {"nbrel": -5, "aggr": 0.04}, "r": "Elçi kapıda bekletildi; heyet kırgın döndü."},
		{"t": "Evlilik öner", "e": {"g": -0.8, "aggr": -0.15, "nbrel": 20, "nbtruce": 26}, "r": "Hanedan evliliği ilan edildi; iki sınır boyu şenlik yapıldı."}]},
	{"id": "p_tribute", "role": "for", "w": 0.9, "war": 0,
	 "q": "{nb} hükümdarı haraç istiyor; vermezsek ordu göndereceğini söylüyor. Yanıtımız ne olsun?",
	 "o": [
		{"t": "Haraç öde", "e": {"g": -1.0, "aggr": -0.1, "nbrel": 10, "nbtruce": 26}, "r": "Haraç yüklü kervan yola çıktı; sınır sessiz."},
		{"t": "Reddet", "e": {"stab": 1, "aggr": 0.12, "nbrel": -12}, "r": "Elçi haraçsız ve hakaretle geri gönderildi."},
		{"t": "Pazarlık et", "e": {"g": -0.4, "aggr": -0.04}, "r": "Haraç yarıya düşürüldü, süre uzatıldı."}]},
	{"id": "p_border", "role": "for", "w": 1.1, "war": 0,
	 "q": "{nb} sınır beyleriyle bizimkiler otlak yüzünden çatışmış. Köyler yağmalanmış, iki yanda da kan var.",
	 "o": [
		{"t": "Hakem gönder", "e": {"g": -0.2, "aggr": -0.06, "nbrel": 6}, "r": "Kadılar ve ihtiyarlar bir araya getirildi; sınır yeniden çizildi."},
		{"t": "Karşılık ver", "e": {"stab": 2, "aggr": 0.14, "nbrel": -10}, "r": "Sınır boyu akınlar düzenlendi; komşu öfkeli."},
		{"t": "Görmezden gel", "e": {"stab": -2, "aggr": 0.05}, "r": "Sınır köyleri yerlerini terk etti."}]},
	{"id": "p_peace", "role": "for", "w": 1.2, "war": 1,
	 "q": "Düşman elçisi beyaz bayrakla geldi, barış ve esir mübadelesi istiyor. Dinleyelim mi?",
	 "o": [
		{"t": "Dinle", "e": {"stab": 2, "aggr": -0.1, "nbrel": 8}, "r": "Divan toplandı, elçi saygıyla ağırlandı; barışın yolu açıldı."},
		{"t": "Elçiyi geri çevir", "e": {"stab": -1, "aggr": 0.08}, "r": "Savaş sürecek, elçi eli boş döndü."}]},
	# ------------------------------------------------------------ İÇİŞLERİ
	{"id": "p_tax", "role": "int", "w": 1.2, "war": 0,
	 "q": "Vergi yükü ağırlaştı; köylüler tarlayı bırakıp dağlara kaçıyor, şehirlerde ekmek kuyruğu var.",
	 "o": [
		{"t": "Vergiyi hafiflet", "e": {"g": -0.8, "stab": 4}, "r": "Fermanla vergi hafifletildi; köyler yeniden ekime çıktı."},
		{"t": "Tahsildarlar gönder", "e": {"g": 0.8, "stab": -4, "unrest": 1}, "r": "Tahsildarlar köy köy gezdi; hazine doldu ama köylü kırgın."},
		{"t": "Şükran yılı ilan et", "e": {"g": -0.3, "stab": 2}, "r": "Bir yıl boyunca bazı vergiler indirildi."}]},
	{"id": "p_celali", "role": "int", "w": 1.0, "war": 0,
	 "q": "Dağlarda eşkıya çeteleri türedi, kervanlar soyuluyor. Başlarında eski bir sipahi var.",
	 "o": [
		{"t": "Sürgün avı", "e": {"g": -0.6, "stab": 2, "troops": -0.01}, "r": "Birlikler dağlara çıktı; çete dağıtıldı, reisi yakalandı."},
		{"t": "Af çıkar", "e": {"stab": 1, "unrest": 1, "troops": 0.02}, "r": "Eşkıyaya af çıkarıldı, bir kısmı orduya yazıldı."},
		{"t": "Boş ver", "e": {"stab": -3, "unrest": 2}, "r": "Çeteler büyüdü, kervan yolları ıssız kaldı.",
		 "fatal": {"p": 0.04, "k": 0.006, "text": "Eşkıya ordusu başkente yürüdü. Saray düştü."}}]},
	{"id": "p_fire", "role": "int", "w": 1.0, "war": 0,
	 "q": "Başkentin ahşap mahallelerinde yangın çıktı! Rüzgâr çarşıya doğru esiyor.",
	 "o": [
		{"t": "Askerleri seferber et", "e": {"g": -0.5, "stab": 1, "dev": -1}, "r": "Yeniçeri tulumbacıları yangını çarşıya geçmeden boğdu."},
		{"t": "Yeniden imar", "e": {"g": -1.2, "dev": 1, "stab": 3}, "r": "Yanan mahalleler taştan yeniden yapıldı."},
		{"t": "Kaderine bırak", "e": {"stab": -4, "dev": -1}, "r": "Yarım şehir kül oldu, halk ağıt yakıyor."}]},
	{"id": "p_kadi", "role": "int", "w": 1.0, "war": 0,
	 "q": "Taşradaki kadıların rüşvetle hüküm verdiği söyleniyor. Halk 'adalet' diye feryat ediyor.",
	 "o": [
		{"t": "Müfettiş gönder", "e": {"g": -0.4, "stab": 3}, "r": "Birkaç kadı azledildi, yerlerine yenileri atandı."},
		{"t": "Kapat", "e": {"g": 0.3, "stab": -2}, "r": "Dosya kapatıldı; rüşvet çarkı döndü."},
		{"t": "Divan-ı Mezalim kur", "e": {"g": -0.7, "stab": 5}, "r": "Hükümdar haftada bir şikâyet dinlemeye başladı; halk gözyaşlarıyla dua etti."}]},
	{"id": "p_nomad", "role": "int", "w": 0.8, "war": 0,
	 "q": "Göçebe aşiretler yaylaklarda vergiden kaçıyor ve ordu çağrısına gelmiyor.",
	 "o": [
		{"t": "Yerleştir", "e": {"g": -0.4, "stab": -1, "dev": 1}, "r": "Bazı aşiretler ovaya yerleştirildi, tarım genişledi."},
		{"t": "Ağır vergi koy", "e": {"g": 0.6, "stab": -3, "unrest": 1}, "r": "Aşiretlerin bir kısmı ayaklandı."},
		{"t": "Serbest bırak", "e": {"troops": 0.02}, "r": "Aşiret beyleri özerklik karşılığı süvari yolladı."}]},
	# ------------------------------------------------------------ DEFTERDAR (MALİYE)
	{"id": "p_coin", "role": "fin", "w": 1.2, "war": 0,
	 "q": "Hazinede altın azaldı. Darphane sikkenin ayarını düşürüp daha çok akçe basabilir, ama çarşıda fiyatlar kabarır.",
	 "o": [
		{"t": "Ayarı düşür", "e": {"g": 1.2, "stab": -3}, "r": "Yeni akçeler basıldı; esnaf dükkânları fiyat etiketiyle doldurdu."},
		{"t": "Vergileri tahsil et", "e": {"g": 0.5, "stab": -1}, "r": "Geriye kalan vergiler toplandı."},
		{"t": "Saray masrafını kıs", "e": {"g": 0.3, "stab": 1}, "r": "Saray harcamaları kısıldı."}]},
	{"id": "p_caravan", "role": "fin", "w": 1.0, "war": 0,
	 "q": "Büyük bir tüccar kervanı vergi muafiyeti istiyor; karşılığında yol boyu hanları yenileyecek.",
	 "o": [
		{"t": "Muafiyet ver", "e": {"g": -0.3, "dev": 1, "stab": 1}, "r": "Kervan yolları işlek, hanlar yeni; çarşı canlandı."},
		{"t": "Vergi al", "e": {"g": 0.7}, "r": "Gümrük sandıkları doldu."},
		{"t": "İpek tekeli ver", "e": {"g": 1.0, "stab": -1}, "r": "Tekel verildi; tüccar zenginleşti, esnaf söyleniyor."}]},
	{"id": "p_mine", "role": "fin", "w": 0.9, "war": 0,
	 "q": "Dağlarda gümüş damarı bulunduğu söyleniyor. Maden ocağı açılırsa hazine büyür ama başta büyük masraf var.",
	 "o": [
		{"t": "Ocağı aç", "e": {"g": -1.0, "ind": 2, "dev": 1}, "r": "Madenciler dağa yerleşti, ocaklar açıldı."},
		{"t": "Ortaklıkla aç", "e": {"g": -0.3, "ind": 1}, "r": "Bir tüccarla ortaklık yapıldı."},
		{"t": "Vazgeç", "e": {}, "r": "Maden bir sonraki hükümdara kaldı."}]},
	# ------------------------------------------------------------ HEKİMBAŞI
	{"id": "p_plague", "role": "hlt", "w": 1.0, "war": 0,
	 "q": "Limanda veba görüldü! Şehirler ardı ardına ölüm haberi alıyor.",
	 "o": [
		{"t": "Karantina", "e": {"g": -0.6, "stab": 1, "unrest": 0}, "r": "Şehir kapıları kapatıldı, hastalar karantinaya alındı; veba sınırlandı."},
		{"t": "Hekimler gönder", "e": {"g": -0.9, "stab": 2}, "r": "Saray hekimleri şehirlere dağıtıldı."},
		{"t": "Dualarla idare et", "e": {"stab": -4, "troops": -0.03}, "r": "Veba yayıldı; her sokakta cenaze var."}]},
	{"id": "p_hunger", "role": "hlt", "w": 0.9, "war": 0,
	 "q": "Kuraklık yüzünden buğday cılız, tahıl fiyatları uçtu. Halk aç, dilenciler şehirlere doldu.",
	 "o": [
		{"t": "Tahıl ambarlarını aç", "e": {"g": -0.9, "stab": 4}, "r": "Devlet ambarları açıldı, çarşıda ucuz ekmek satıldı."},
		{"t": "İthal et", "e": {"g": -1.2, "stab": 2}, "r": "Gemiler ve kervanlar buğday getirdi."},
		{"t": "Hiçbir şey yapma", "e": {"stab": -5, "unrest": 2}, "r": "Aç halk fırınları bastı."}]},
	# ------------------------------------------------------------ CASUS / DİVAN ÇAVUŞU
	{"id": "p_plot", "role": "spy", "w": 1.0, "war": 0, "stab_lt": 55,
	 "q": "Saray'da suikast planı kokusu var. Vezirlerden biri gizli toplantılar yapıyor.",
	 "o": [
		{"t": "Hepsini yakala", "e": {"stab": -3}, "r": "Gece baskınıyla şüpheliler zindana atıldı.",
		 "fatal": {"p": 0.05, "k": 0.006, "text": "Bir vezirin hançeri seni buldu. Hanedan sona erdi."}},
		{"t": "Gizlice izle", "e": {"g": -0.3, "stab": 1}, "r": "Casuslar vezirin peşine takıldı; plan boşa çıktı."},
		{"t": "Sürgüne yolla", "e": {"stab": 1}, "r": "Şüpheliler uzak bir sancağa sürüldü."}]},
	{"id": "p_spy", "role": "spy", "w": 0.9, "war": 0,
	 "q": "{nb} sarayına bir casus yerleştirme fırsatı var. Hançerli bir hizmetkâr gerekiyor, masrafı küçük değil.",
	 "o": [
		{"t": "Yerleştir", "e": {"g": -0.6, "aggr": -0.08, "nbrel": 4}, "r": "Sarayda adamımız var; komşunun planlarından haberdarız."},
		{"t": "Rüşvetle satın al", "e": {"g": -0.4, "aggr": -0.04}, "r": "Bir vezir altınla bizim safa çekildi."},
		{"t": "Boşver", "e": {}, "r": "Hiçbir şey yapılmadı."}]},
	{"id": "p_prince", "role": "spy", "w": 0.8, "war": 0, "stab_lt": 60,
	 "q": "Kardeşin sancağında ordu topluyor, bayrak açmaya hazırlanıyor. Casuslar mektupları ele geçirdi.",
	 "o": [
		{"t": "Sarayına çağır", "e": {"stab": 2, "g": -0.2}, "r": "Kardeşin zorla saraya getirildi, nezaret altına alındı."},
		{"t": "Ordusunu dağıt", "e": {"stab": -2, "troops": -0.02}, "r": "Sancağa bir kol ordu yollanıp ordu dağıtıldı."},
		{"t": "Bağışla", "e": {"stab": 1, "g": -0.3, "unrest": 1}, "r": "Kardeşine bağış verildi; ama güveniniz zedelendi."}]},
]

extends RefCounted
## Kabine kartları: bakanlar (gerçek isimler yalnızca metin) oyuncuya karar soruları sorar.
## Seçime göre bütçe, istikrar, ordu, komşu tutumu değişir; bazı riskli seçimler oyunu bitirebilir.
## Ayarlardan kapatılabilir (Settings.cabinet).

const Macro = preload("res://scripts/macro.gd")
const Names = preload("res://scripts/names.gd")
const NameGen = preload("res://scripts/name_gen.gd")
const Politics = preload("res://scripts/politics.gd")

const ROLE_TITLE := {"def": "Savunma Bakanı", "for": "Dışişleri Bakanı", "int": "İçişleri Bakanı", "fin": "Maliye Bakanı",
	"hlt": "Sağlık Bakanı", "spy": "İstihbarat Başkanı", "amb": "Büyükelçi",
	"trd": "Gölge Tüccarı", "spt": "Spor Federasyonu Başkanı", "ele": "Seçim Kurulu Başkanı"}

static var _names: Dictionary = {}
static var _loaded := false

# Etki anahtarları:
#   g     altın (haftalık net gelirin katı)        stab  istikrar        cyb/ind/log  siber, sanayi, lojistik
#   tech  silah teknolojisi (0..1)             troops ordu mevcudu oranı   unrest  rastgele N eyalette huzursuzluk
#   aggr  komşu/düşman yapay zekâ saldırganlığı  dev  başkentte kalkınma
# Seçenek: {"t": düğme, "e": etkiler, "r": sonuç metni, "fatal": {"p": taban, "k": istikrar etkisi, "text": ...}}
# Cümleler: {m} bakan  {nb} komşu  {en} düşman/komşu  {c} ülke  {cap} başkent
const CARDS := [
	# ------------------------------------------------------------ SAVUNMA
	{"id": "d_drill", "role": "def", "w": 1.0, "war": 0,
	 "q": "Efendim, {nb} sınırı boyunca büyük bir tatbikat planlıyoruz. Gövde gösterisi mi yapalım, yoksa temkinli mi kalalım?",
	 "o": [
		{"t": "Büyük tatbikat", "e": {"g": -0.8, "stab": 2, "aggr": 0.08}, "r": "Birlikler sınıra yığıldı. Ordunun moral sesi yükseldi, komşular tedirgin."},
		{"t": "Sınırlı tatbikat", "e": {"g": -0.3, "stab": 1}, "r": "Küçük ölçekli, dikkat çekmeyen bir tatbikat yapıldı."},
		{"t": "İptal et", "e": {"g": 0.2, "stab": -1}, "r": "Tatbikat iptal edildi; bütçe korundu, subaylar homurdandı."}]},
	{"id": "d_rifle", "role": "def", "w": 1.0, "war": 0,
	 "q": "Yerli tüfek ve zırhlı araç projesi bütçe bekliyor. Tam destek verirsek sanayi de canlanır.",
	 "o": [
		{"t": "Tam destek", "e": {"g": -1.2, "tech": 0.03, "ind": 3}, "r": "Prototipler teslim alındı, fabrikalar üç vardiya çalışıyor."},
		{"t": "Kısmi destek", "e": {"g": -0.5, "tech": 0.012}, "r": "Proje yavaş ama düzenli ilerliyor."},
		{"t": "Ertele", "e": {}, "r": "Proje rafa kalktı."}]},
	{"id": "d_draft", "role": "def", "w": 0.9, "war": 0,
	 "q": "Ordu mevcudunu hızla büyütmek için zorunlu hizmet süresini uzatmayı öneriyorum.",
	 "o": [
		{"t": "Süreyi uzat", "e": {"troops": 0.06, "stab": -4}, "r": "Kışlalar doldu ama aileler hoşnut değil."},
		{"t": "Gönüllüyü teşvik et", "e": {"g": -0.6, "troops": 0.03}, "r": "Prim ve burslarla gönüllü sayısı arttı."},
		{"t": "Dokunma", "e": {}, "r": "Mevcut sistem sürüyor."}]},
	{"id": "d_pay", "role": "def", "w": 1.0, "war": 0, "stab_lt": 48,
	 "q": "Subaylar arasında maaşlar yüzünden kıpırdanma var. Bazı garnizonlarda toplantılar yapılıyor.",
	 "o": [
		{"t": "Zam ver", "e": {"g": -1.0, "stab": 3}, "r": "Maaşlar artırıldı, subaylar sakinleşti."},
		{"t": "Gözaltıları başlat", "e": {"stab": -5}, "r": "Birkaç albay tutuklandı; ordu içinde soğukluk büyüdü.",
		 "fatal": {"p": 0.08, "k": 0.006, "text": "Subayların sabrı taştı: ordu yönetime el koydu. Hükümetin sona erdi."}},
		{"t": "Görüş", "e": {"g": -0.2, "stab": 1}, "r": "Komutanlarla yemekli bir toplantı yapıldı."}]},
	{"id": "d_base", "role": "def", "w": 0.8, "war": 0,
	 "q": "{nb} topraklarımızda ortak bir üs kurmak istiyor. Karşılığında ciddi bir ödeme teklif ediyor.",
	 "o": [
		{"t": "Kabul et", "e": {"g": 1.2, "stab": -2, "aggr": 0.05}, "r": "Anlaşma imzalandı; muhalefet 'egemenlik satıldı' diye bağırıyor."},
		{"t": "Reddet", "e": {"stab": 1}, "r": "Teklif nazikçe geri çevrildi."}]},
	{"id": "d_cyber", "role": "def", "w": 0.9, "war": 0,
	 "q": "Siber komutanlık kurulmasını öneriyorum. Savunma da saldırı da buradan yürüyecek.",
	 "o": [
		{"t": "Tam komutanlık kur", "e": {"g": -0.9, "cyb": 6}, "r": "Yüzlerce genç mühendis ordunun siber kanadına katıldı."},
		{"t": "Küçük birim", "e": {"g": -0.4, "cyb": 3}, "r": "Ordu içinde küçük bir siber birim kuruldu."},
		{"t": "Gereksiz", "e": {}, "r": "Öneri reddedildi."}]},
	{"id": "d_ammo", "role": "def", "w": 1.3, "war": 1,
	 "q": "{en} cephesinde cephane stokları azalıyor. Hızlı bir karar gerek.",
	 "o": [
		{"t": "Acil dış sipariş", "e": {"g": -1.2, "log": 4, "troops": 0.02}, "r": "Havai nakliyatla cephane ulaştı; cepheler yeniden dirençli."},
		{"t": "Sivil fabrikaları dönüştür", "e": {"ind": -3, "log": 3, "troops": 0.03}, "r": "Sivil üretim hatları silah üretimine çevrildi."},
		{"t": "Dayanın", "e": {"stab": -2}, "r": "Cephedeki birlikler kendi imkânlarıyla idare etti."}]},
	{"id": "d_deserters", "role": "def", "w": 1.1, "war": 1,
	 "q": "Savaş uzadıkça cephede firarlar artıyor. Disiplini nasıl sağlayalım?",
	 "o": [
		{"t": "Af ilan et", "e": {"stab": 2, "troops": -0.01}, "r": "Firariler affedildi; bir kısmı geri döndü."},
		{"t": "Sıkı ceza", "e": {"stab": -3, "troops": 0.02}, "r": "Disiplin sertleşti; ordu toparlandı ama halk huzursuz."},
		{"t": "Moral kampanyası", "e": {"g": -0.5, "stab": 1, "troops": 0.01}, "r": "Gazete, radyo ve şarkılarla cephede moral yükseltildi."}]},
	{"id": "d_nuke", "role": "def", "w": 0.5, "war": 0,
	 "q": "Gizli bir ileri silah programı için bilim insanları kaynak bekliyor. Yakalanırsak yaptırım gelebilir.",
	 "o": [
		{"t": "Gizlice başlat", "e": {"g": -2.0, "tech": 0.05, "aggr": 0.2}, "r": "Program başladı. Yabancı istihbarat bir şeyler sezmiş gibi."},
		{"t": "Sivil kanaldan ilerle", "e": {"g": -0.8, "tech": 0.018, "ind": 2}, "r": "Araştırma 'sivil' etiketiyle sürdü."},
		{"t": "Vazgeç", "e": {"stab": 1}, "r": "Proje iptal edildi."}]},
	# ------------------------------------------------------------ DIŞİŞLERİ
	{"id": "f_summit", "role": "for", "w": 1.0, "war": 0,
	 "q": "{nb} lideri bir zirve toplantısı istiyor. Katılmak ilişkileri rahatlatabilir.",
	 "o": [
		{"t": "Bizzat git", "e": {"g": -0.3, "stab": 2, "aggr": -0.1}, "r": "Zirve sıcak geçti; iki taraf da ortak bildiri yayımladı."},
		{"t": "Elçi gönder", "e": {"g": -0.1, "aggr": -0.04}, "r": "Orta düzey bir heyet gönderildi."},
		{"t": "Reddet", "e": {"stab": 1, "aggr": 0.08}, "r": "Davet reddedildi; basın cesur bir duruş olarak yorumladı."}]},
	{"id": "f_embassy", "role": "for", "w": 1.0, "war": 0,
	 "q": "{nb} ile elçilik ilişkilerini yükseltmeyi öneriyorum: büyükelçilik, ticaret ofisi, vize anlaşması.",
	 "o": [
		{"t": "Büyükelçilik aç", "e": {"g": -0.5, "aggr": -0.08, "stab": 1}, "r": "Yeni büyükelçilik açıldı, ticari heyetler gidip gelmeye başladı."},
		{"t": "Sadece ticaret ofisi", "e": {"g": -0.2, "aggr": -0.03}, "r": "Ticaret ofisi açıldı."},
		{"t": "Gerek yok", "e": {}, "r": "Mevcut düzey korundu."}]},
	{"id": "f_sanction", "role": "for", "w": 0.9, "war": 0,
	 "q": "{nb} bir üçüncü ülkeye yaptırım uygulamamızı istiyor ve bize destek sözü veriyor.",
	 "o": [
		{"t": "Katıl", "e": {"stab": 1, "g": -0.3, "aggr": 0.08}, "r": "Yaptırım kararı onaylandı; hedef ülke sert tepki verdi."},
		{"t": "Tarafsız kal", "e": {}, "r": "Hükümet tarafsızlığını açıkladı."},
		{"t": "Karşı çık", "e": {"stab": -1, "aggr": 0.04}, "r": "Yaptırıma karşı olduğun duyuruldu; bir süre soğukluk yaşanacak."}]},
	{"id": "f_mediate", "role": "for", "w": 0.8, "war": 0,
	 "q": "Komşu iki ülke arasında gerginlik büyüyor ve bizi arabuluculuğa çağırıyorlar.",
	 "o": [
		{"t": "Arabuluculuğu üstlen", "e": {"g": -0.3, "stab": 3, "aggr": -0.06}, "r": "Zirve ev sahibi olarak prestiji büyüttün; gerginlik azaldı."},
		{"t": "Kenarda dur", "e": {}, "r": "Taraflar kendi yollarını buldu."}]},
	{"id": "f_spy", "role": "for", "w": 0.9, "war": 0,
	 "q": "Büyükelçimiz {nb} tarafından casusluk suçlamasıyla sınır dışı edildi. Nasıl karşılık verelim?",
	 "o": [
		{"t": "Resmen protesto et", "e": {"stab": 1, "aggr": 0.05}, "r": "Nota verildi; iki ülke karşılıklı elçi çağırdı."},
		{"t": "Sessiz kal", "e": {"stab": -1}, "r": "Olay basında kısa sürede unutuldu."},
		{"t": "Karşılık ver", "e": {"stab": 2, "aggr": 0.12}, "r": "Karşı hamle yapıldı; ilişkiler dondu."}]},
	{"id": "f_aid", "role": "for", "w": 0.9, "war": 0,
	 "q": "{nb} afet nedeniyle uluslararası yardım istiyor. Cömert davranmak itibarımızı yükseltir.",
	 "o": [
		{"t": "Büyük yardım", "e": {"g": -0.6, "stab": 2, "aggr": -0.12}, "r": "Yardım konvoyları yola çıktı; dünya kamuoyu seni övdü."},
		{"t": "Sembolik yardım", "e": {"g": -0.1, "aggr": -0.02}, "r": "Küçük bir yardım paketi gönderildi."},
		{"t": "Reddet", "e": {"stab": -1}, "r": "Yardım isteği yanıtsız kaldı."}]},
	{"id": "f_leak", "role": "for", "w": 0.8, "war": 0,
	 "q": "Gizli diplomatik yazışmalar basına sızdı. Bazı ülkelerle ilişkilerimiz zorlanabilir.",
	 "o": [
		{"t": "Belgeleri yalanla", "e": {"stab": -2}, "r": "Yalanlama inandırıcı bulunmadı."},
		{"t": "Soruşturma aç", "e": {"g": -0.2, "stab": 1}, "r": "Bakanlıkta kapsamlı bir soruşturma başladı."},
		{"t": "Bir müsteşar feda et", "e": {"stab": 1}, "r": "Sorumlu bürokrat istifa etti; olay kapandı."}]},
	{"id": "f_border", "role": "for", "w": 1.1, "war": 0,
	 "q": "{nb} sınır hattındaki bir bölgeyi kendi toprağı ilan ediyor. Tepkimiz ne olsun?",
	 "o": [
		{"t": "Sınıra birlik gönder", "e": {"g": -0.4, "stab": 2, "aggr": 0.15}, "r": "Karşı karşıya duran birlikler gerginliği tırmandırdı."},
		{"t": "Müzakere masası", "e": {"g": -0.2, "aggr": -0.05}, "r": "Diplomatik görüşmeler başladı."},
		{"t": "Taviz ver", "e": {"stab": -4, "aggr": -0.15}, "r": "Taviz kabul edildi; halk bunu zayıflık olarak gördü."}]},
	{"id": "f_peacepush", "role": "for", "w": 1.2, "war": 1,
	 "q": "{en} ile savaşta üçüncü ülkeler ateşkes için baskı yapıyor. Dünya kamuoyu savaştan yoruldu.",
	 "o": [
		{"t": "Ateşkes görüşmelerine otur", "e": {"stab": 3, "aggr": -0.08}, "r": "Gizli kanallar açıldı. Savaş kamuoyu sakinleşti."},
		{"t": "Savaşa devam", "e": {"stab": -2, "aggr": 0.05}, "r": "Savaş kararlılıkla sürüyor; diplomatik baskı sertleşti."},
		{"t": "Üçüncü ülkeyi kendi yanımıza çek", "e": {"g": -0.5, "stab": 1}, "r": "Yeni bir mali destek paketiyle bir ülke yanımızda durdu."}]},
	# ------------------------------------------------------------ İÇİŞLERİ
	{"id": "i_protest", "role": "int", "w": 1.2, "war": 0,
	 "q": "{cap} sokaklarında büyük bir protesto var; ekonomik talepler dile getiriliyor. Kalabalık her saat büyüyor.",
	 "o": [
		{"t": "Ödenek ver", "e": {"g": -1.0, "stab": 4}, "r": "Bir destek paketi açıklandı; kalabalık dağıldı."},
		{"t": "Gözaltı ve gaz", "e": {"stab": -5, "unrest": 2}, "r": "Polis müdahale etti; öfke tüm şehirlere yayıldı.",
		 "fatal": {"p": 0.07, "k": 0.007, "text": "Sokaklar ayaklandı, hükümet devrildi. Yönetim elinden alındı."}},
		{"t": "Müzakere et", "e": {"g": -0.3, "stab": 1}, "r": "Sendika ve öğrenci temsilcileriyle görüşüldü."}]},
	{"id": "i_terror", "role": "int", "w": 1.0, "war": 0,
	 "q": "İstihbarat, büyük bir şehirde bombalı saldırı planı ihbar etti. Zaman kısıtlı.",
	 "o": [
		{"t": "Baskın operasyonu", "e": {"g": -0.4, "stab": 2}, "r": "Hücre çökertildi; basın seni şahin ilan etti."},
		{"t": "Sokağa çıkma yasağı", "e": {"stab": -2, "ind": -1}, "r": "Şehir bir gece durdu, plan bozuldu ama halk bunaldı."},
		{"t": "İhbar abartı", "e": {"stab": -12}, "r": "Saldırı gerçekleşti. Ağır bir yas ve öfke dalgası var."}]},
	{"id": "i_corrupt", "role": "int", "w": 1.0, "war": 0,
	 "q": "Üst düzey bürokratlar kayırmacılık ve yolsuzlukla suçlanıyor. Yargı seni bekliyor.",
	 "o": [
		{"t": "Tasfiye et", "e": {"stab": 3, "g": 0.3}, "r": "Birkaç isim görevden alındı; kamuoyu rahatladı."},
		{"t": "Örtbas et", "e": {"stab": -3, "g": 0.8}, "r": "Dosya kapatıldı. Para korundu ama güven zedelendi."},
		{"t": "Bağımsız soruşturma", "e": {"g": -0.2, "stab": 1}, "r": "Bağımsız bir kurul çalışmaya başladı."}]},
	{"id": "i_migration", "role": "int", "w": 0.9, "war": 0,
	 "q": "Sınırda yeni bir göç dalgası var. Binlerce kişi kapıda bekliyor.",
	 "o": [
		{"t": "Kabul et, kamp kur", "e": {"g": -0.8, "stab": -1, "ind": 1}, "r": "Kamplar kuruldu; yeni iş gücü piyasaya girmeye başladı."},
		{"t": "Sınırı kapat", "e": {"stab": 1, "aggr": 0.05}, "r": "Sınır kapatıldı; komşu hükümet seni eleştiriyor."},
		{"t": "Uluslararası yardım iste", "e": {"g": -0.3, "stab": 1}, "r": "Yardım örgütleri ortak bir çözüm bulmak için masaya oturdu."}]},
	{"id": "i_election", "role": "int", "w": 0.6, "war": 0, "stab_lt": 52,
	 "q": "Muhalefet erken seçim istiyor. Sokaklarda sandık sloganları duyuluyor.",
	 "o": [
		{"t": "Erken seçime git", "e": {"stab": 5}, "r": "Seçim yapıldı: mevcut yönetim güvenini tazeledi.",
		 "fatal": {"p": 0.12, "k": 0.01, "text": "Seçimi kaybettin. İktidar el değiştirdi, yeni hükümet kuruldu."}},
		{"t": "Reddet", "e": {"stab": -4}, "r": "Talep reddedildi; muhalefet sokağa dökülmek için hazırlık yapıyor."},
		{"t": "Referandum öner", "e": {"stab": 2, "g": -0.3}, "r": "Referandum kampanyası başladı."}]},
	{"id": "i_press", "role": "int", "w": 0.8, "war": 0,
	 "q": "Bazı gazeteciler hükümeti sert eleştiriyor. Kanal sahiplerine baskı yapmamı ister misin?",
	 "o": [
		{"t": "Basına dokunma", "e": {"stab": 1}, "r": "Basın özgürlüğü korundu; eleştiriler sürüyor."},
		{"t": "Sansür", "e": {"stab": -2, "cyb": 2}, "r": "Kanallara talimat gitti; dijital izleme güçlendirildi."},
		{"t": "Kanalları kapat", "e": {"stab": -5, "cyb": 3}, "r": "Birkaç kanal kapatıldı; dışarıdan sert tepki geldi."}]},
	{"id": "i_disaster", "role": "int", "w": 1.0, "war": 0,
	 "q": "Büyük bir deprem/sel felaketi yaşandı; yüz binlerce kişi etkilendi.",
	 "o": [
		{"t": "Ulusal seferberlik", "e": {"g": -1.0, "stab": 3, "dev": 1}, "r": "Ordu ve sivil toplum seferber oldu; şehirler yeniden inşa ediliyor."},
		{"t": "Kısmi yardım", "e": {"g": -0.4, "stab": 1}, "r": "Yardım gecikmeli geldi."},
		{"t": "Özel sektöre bırak", "e": {"g": 0.2, "stab": -4}, "r": "Yardım örgütsüz kaldı; halk öfkeli."}]},
	# ------------------------------------------------------------ MALİYE
	{"id": "fn_deficit", "role": "fin", "w": 1.2, "war": 0,
	 "q": "Bütçe açığı büyüyor. Rezervler hızla azalıyor.",
	 "o": [
		{"t": "Vergileri artır", "e": {"g": 1.2, "stab": -3}, "r": "Yeni vergiler kasayı doldurdu, halk homurdandı."},
		{"t": "Borçlan", "e": {"g": 1.8, "ind": -1}, "r": "Uluslararası piyasalardan borç alındı; faiz yükü gelecek haftalara kaldı."},
		{"t": "Harcama kıs", "e": {"g": 0.6, "ind": -2, "log": -1}, "r": "Kamu yatırımları dondurulduktan sonra kasa toparlandı."}]},
	{"id": "fn_invest", "role": "fin", "w": 1.0, "war": 0,
	 "q": "Yabancı bir yatırımcı ülkende dev bir fabrika kurmak istiyor. Teşvik şartları var.",
	 "o": [
		{"t": "Vergi teşviki ver", "e": {"g": -0.5, "ind": 4}, "r": "Fabrika temelleri atıldı; binlerce kişi iş buldu."},
		{"t": "Şartlı kabul", "e": {"ind": 2}, "r": "Pazarlıkla küçük bir tesis kuruldu."},
		{"t": "Reddet", "e": {"stab": 1}, "r": "Milli duygular okşandı."}]},
	{"id": "fn_inflation", "role": "fin", "w": 1.0, "war": 0,
	 "q": "Enflasyon yükseliyor ve halk fiyatlardan şikâyetçi.",
	 "o": [
		{"t": "Faizi artır", "e": {"g": 0.4, "stab": -2}, "r": "Para sıkılaştı; krediler pahalandı."},
		{"t": "Fiyat tavanı koy", "e": {"g": -0.6, "stab": 2, "ind": -1}, "r": "Raflardaki fiyatlar durdu ama üretici zorlanıyor."},
		{"t": "Merkez bankasına güven", "e": {"stab": -1}, "r": "Sorun kendi dinamiğiyle sürdü."}]},
	{"id": "fn_trade", "role": "fin", "w": 1.0, "war": 0,
	 "q": "{nb} ile geniş kapsamlı bir ticaret anlaşması masada. Ek olarak tarım ve enerji de var.",
	 "o": [
		{"t": "İmzala", "e": {"g": 1.0, "aggr": -0.05}, "r": "Anlaşma imzalandı; limanlarda yoğunluk arttı."},
		{"t": "Pazarlık et", "e": {"g": 0.5}, "r": "Kısmi bir anlaşma yapıldı."},
		{"t": "Reddet", "e": {"stab": 1}, "r": "Yerli üretici koruması gerekçesiyle ret kararı verildi."}]},
	{"id": "fn_mega", "role": "fin", "w": 0.9, "war": 0,
	 "q": "Dev bir altyapı projesi için onay bekliyoruz: köprü, hızlı tren, liman.",
	 "o": [
		{"t": "Hepsini yap", "e": {"g": -1.5, "log": 5, "ind": 2, "stab": 2}, "r": "Şantiyeler kuruldu; projeler halkın gururu oldu."},
		{"t": "Sadece liman", "e": {"g": -0.6, "log": 3}, "r": "Liman genişletildi; ticaret hızlandı."},
		{"t": "Ertele", "e": {"stab": -1}, "r": "Projeler gelecek bütçeye kaldı."}]},
	{"id": "fn_crash", "role": "fin", "w": 0.7, "war": 0,
	 "q": "Küresel piyasalar çöküyor ve ülkemizin borsası %20 düştü.",
	 "o": [
		{"t": "Kurtarma paketi", "e": {"g": -1.5, "stab": 2}, "r": "Devlet bankalara destek verdi; panik durdu."},
		{"t": "Kemer sıkma", "e": {"g": 0.8, "stab": -4}, "r": "Sert tasarruf önlemleri alındı.",
		 "fatal": {"p": 0.03, "k": 0.008, "text": "Ekonomik çöküş ve sokak ayaklanmaları hükümeti yıktı."}},
		{"t": "Rezerv sat", "e": {"g": 1.2, "stab": -1, "ind": -1}, "r": "Rezervler satıldı; piyasa nefes aldı."}]},
	# ------------------------------------------------------------ SAĞLIK
	{"id": "h_epidemic", "role": "hlt", "w": 1.0, "war": 0,
	 "q": "Yeni bir salgın dalgası var. Hastaneler dolmaya başladı.",
	 "o": [
		{"t": "Karantina uygula", "e": {"g": -0.6, "stab": -2, "ind": -2}, "r": "Şehirler kapandı, salgın kontrol altına alındı."},
		{"t": "Aşı kampanyası", "e": {"g": -1.0, "stab": 2}, "r": "Seferberlik gibi bir aşı kampanyası yürütüldü."},
		{"t": "Görmezden gel", "e": {"stab": -8, "troops": -0.02}, "r": "Salgın yayıldı; üretim ve ordu zayıfladı."}]},
	{"id": "h_hospital", "role": "hlt", "w": 1.0, "war": 0,
	 "q": "Şehir hastaneleri programı onayını bekliyor: yeni yataklar, yeni doktorlar.",
	 "o": [
		{"t": "Büyük program", "e": {"g": -1.0, "stab": 4}, "r": "Yeni hastaneler açıldı; halk memnun."},
		{"t": "Kısmi program", "e": {"g": -0.4, "stab": 2}, "r": "Önce en acil bölgelerde başlandı."},
		{"t": "Ertele", "e": {"stab": -1}, "r": "Program ertelendi."}]},
	{"id": "h_pharma", "role": "hlt", "w": 0.8, "war": 0,
	 "q": "Yerli ilaç ve tıbbi cihaz sanayisini kurmak için bir plan sundum.",
	 "o": [
		{"t": "Devlet ortaklığı", "e": {"g": -0.7, "ind": 3, "stab": 1}, "r": "Yerli ilaç fabrikaları ilk ürünlerini çıkardı."},
		{"t": "Özel sektörü teşvik et", "e": {"g": -0.3, "ind": 2}, "r": "Girişimciler harekete geçti."},
		{"t": "İthal etmeye devam", "e": {"g": 0.2}, "r": "Mevcut tedarik düzeni korundu."}]},
	{"id": "h_military", "role": "hlt", "w": 1.0, "war": 1,
	 "q": "Cephede yaralı sayısı arttı. Sahra hastaneleri yetersiz.",
	 "o": [
		{"t": "Sahra hastaneleri kur", "e": {"g": -0.8, "troops": 0.02, "stab": 1}, "r": "Yaralılar daha hızlı tedavi edilip cepheye döndü."},
		{"t": "Sivil hastaneleri kullan", "e": {"stab": -2, "troops": 0.01}, "r": "Şehir hastaneleri cephenin yükünü aldı."},
		{"t": "Kaynak yok", "e": {"troops": -0.02, "stab": -2}, "r": "Yaralı kayıpları arttı."}]},
	{"id": "h_famine", "role": "hlt", "w": 0.8, "war": 0,
	 "q": "Kıtlık uyarısı var. Gıda stokları kritik seviyede.",
	 "o": [
		{"t": "Acil gıda ithali", "e": {"g": -0.8, "stab": 2}, "r": "Gemiler liman liman buğday taşıdı."},
		{"t": "Karne uygula", "e": {"stab": -2, "ind": -1}, "r": "Karne sistemi getirildi; kuyruklar uzadı."},
		{"t": "Piyasaya bırak", "e": {"stab": -5}, "r": "Fiyatlar uçtu, öfke arttı."}]},
	# ------------------------------------------------------------ İSTİHBARAT
	{"id": "s_coup", "role": "spy", "w": 1.0, "war": 0, "stab_lt": 55,
	 "q": "Bir grup subayın darbe planladığına dair güvenilir bilgi aldık.",
	 "o": [
		{"t": "Hemen tutuklat", "e": {"stab": -3}, "r": "Operasyon yapıldı, planlar bozuldu. Ordu içinde güven zedelendi."},
		{"t": "İzlemeye devam", "e": {"cyb": 1}, "r": "Gözetim artırıldı.",
		 "fatal": {"p": 0.14, "k": 0.01, "text": "Darbe gerçekleşti: birlikler başkenti kuşattı ve yönetim el değiştirdi."}},
		{"t": "Subayları ödüllendir", "e": {"g": -0.8, "stab": 2}, "r": "Terfi ve zamlarla sadakat satın alındı."}]},
	{"id": "s_cyberhit", "role": "spy", "w": 1.2, "war": 0,
	 "q": "Ülkenin enerji ve bankacılık ağlarına yönelik büyük bir siber saldırı tespit ettik.",
	 "o": [
		{"t": "Karşı saldırı", "e": {"g": -0.6, "cyb": 3, "aggr": 0.1}, "r": "Saldırgan sunucular çökertildi; uluslararası gerginlik arttı."},
		{"t": "Sadece savun", "e": {"g": -0.4, "cyb": 4}, "r": "Savunma ağları güçlendirildi."},
		{"t": "Görmezden gel", "e": {"ind": -3, "stab": -1}, "r": "Birkaç gün hizmet kesintisi yaşandı."}]},
	{"id": "s_defector", "role": "spy", "w": 0.8, "war": 0,
	 "q": "{nb} ordusundan bir albay sığınma talep ediyor; önemli bilgiler getirmiş.",
	 "o": [
		{"t": "Kabul et", "e": {"tech": 0.02, "aggr": 0.1}, "r": "Albay bilgi paylaştı; komşu hükümet seni suçluyor."},
		{"t": "Reddet", "e": {"stab": 1}, "r": "Albay sınırdan geri gönderildi."}]},
	{"id": "s_ring", "role": "spy", "w": 0.9, "war": 0,
	 "q": "{nb} içindeki casus ağımızın açığa çıkmak üzere olduğu anlaşıldı.",
	 "o": [
		{"t": "Ağı çek", "e": {"g": -0.2}, "r": "Ajanlar sessizce geri çekildi."},
		{"t": "Devam et", "e": {"cyb": 2, "aggr": 0.2}, "r": "Ağ yakalandı ama bazı sırlar kaçırıldı; ilişkiler gerildi."}]},
	{"id": "s_wargame", "role": "spy", "w": 1.1, "war": 1,
	 "q": "{en} planlarını ele geçirmek üzereyiz ama bedeli yüksek.",
	 "o": [
		{"t": "Operasyonu başlat", "e": {"g": -0.9, "troops": 0.02, "stab": 1}, "r": "Planlar ele geçti; komutanlar cephe hatlarını güncelledi."},
		{"t": "Sadece dinle", "e": {"cyb": 2}, "r": "Gizli haberleşme izlendi."},
		{"t": "İptal", "e": {}, "r": "Operasyon iptal edildi."}]},
	# ------------------------------------------------------------ BÜYÜKELÇİ
	{"id": "a_trade", "role": "amb", "w": 0.9, "war": 0,
	 "q": "Efendim, {nb} ile ticaret ve vize anlaşması masada. İmzalarsak iki ülke de kazanır, ama iç sanayi şikâyet edecek.",
	 "o": [
		{"t": "Anlaşmayı imzala", "e": {"g": 0.4, "log": 3, "aggr": -0.06, "stab": -1}, "r": "Anlaşma imzalandı; ticaret hacmi arttı, yerli üreticiler homurdandı."},
		{"t": "Şartları sertleştir", "e": {"g": 0.1, "aggr": 0.03}, "r": "Müzakere uzadı; küçük bir tavizle yetinildi."},
		{"t": "Reddet", "e": {"stab": 1, "aggr": 0.05}, "r": "Anlaşma reddedildi; iç kamuoyu memnun, komşu soğuk."}]},
	{"id": "a_scandal", "role": "amb", "w": 0.9, "war": 0,
	 "q": "Büyükelçimiz {nb}'de bir skandalın ortasında; yerel basın peşimizde. Geri çağıralım mı?",
	 "o": [
		{"t": "Geri çağır", "e": {"stab": 1, "aggr": 0.04}, "r": "Büyükelçi geri çağrıldı; ilişkilerde kısa bir soğukluk oldu."},
		{"t": "Savun", "e": {"stab": -2, "aggr": -0.02}, "r": "Büyükelçi görevinde tutuldu; muhalefet hükümeti eleştirdi."},
		{"t": "Sessizce değiştir", "e": {"g": -0.1}, "r": "Yeni büyükelçi atandı; olay unutuldu."}]},
	{"id": "a_leak", "role": "amb", "w": 0.8, "war": 0,
	 "q": "Büyükelçilik, {nb} yönetiminin gizli bir görüşme kaydını ele geçirdi. Ne yapalım?",
	 "o": [
		{"t": "Kamuoyuna açıkla", "e": {"stab": 2, "aggr": 0.1}, "r": "Kayıt basına sızdı; iç kamuoyunda destek arttı, komşu öfkeli."},
		{"t": "Koz olarak sakla", "e": {"tech": 0.01, "cyb": 1}, "r": "Kayıt kasada bekliyor; müzakerelerde elin güçlendi."},
		{"t": "Karşı tarafa geri ver", "e": {"g": 0.3, "aggr": -0.08}, "r": "Kayıt iade edildi; karşılığında ekonomik tavizler geldi."}]},
	{"id": "a_summit", "role": "amb", "w": 0.8, "war": 0,
	 "q": "{nb} liderleri bir zirve düzenlemek istiyor; büyükelçimiz hazırlıkları tamamladı. Ev sahipliği yapalım mı?",
	 "o": [
		{"t": "Ev sahipliği yap", "e": {"g": -0.4, "stab": 2, "aggr": -0.1}, "r": "Zirve görkemli geçti; ülkenin itibarı yükseldi."},
		{"t": "Sadece katıl", "e": {"stab": 1, "aggr": -0.03}, "r": "Zirveye katıldın; sıradan bir görüşme oldu."},
		{"t": "Katılma", "e": {"aggr": 0.04}, "r": "Davet geri çevrildi; basın bunu kibir olarak yorumladı."}]},

	# ------------------------------------------------------------ GÖLGE TÜCCARI (gizemli sandıklar: şans oyunu)
	{"id": "t_crates", "role": "trd", "w": 0.8, "war": 0, "style": "eu",
	 "q": "Limanda parlak gözlü bir adam: 'Gümrüğe kayıtsız üç sandığım var, efendim. İçini ben bile bilmiyorum. Hangisini istersiniz?'",
	 "o": [
		{"t": "Küçük sandık", "e": {"g": -0.3}, "gamble": {"p": 0.65, "win": {"g": 1.0}, "lose": {},
		 "wr": "Sandıktan külçe altın çıktı! Tüccar çoktan ortadan kayboldu.", "lr": "Sandık kumla doluydu. Tüccar el sallayarak uzaklaştı."}},
		{"t": "Orta sandık", "e": {"g": -0.8}, "gamble": {"p": 0.5, "win": {"tech": 0.02, "g": 0.6}, "lose": {"stab": -2},
		 "wr": "Sandığın içinde eski bir laboratuvar defteri vardı; bilim insanları bayram etti.", "lr": "Sandıktan çıkan sahte parayı basın duydu. Rezil olduk."}},
		{"t": "Büyük sandık", "e": {"g": -1.6}, "gamble": {"p": 0.35, "win": {"tech": 0.04, "ind": 4, "log": 3, "g": 1.2}, "lose": {"stab": -3, "aggr": 0.05},
		 "wr": "Büyük sandık dolusu prototip ve şema! Fabrikalar şenlendi.", "lr": "Sandıktan çıkan şey komşunun kayıp malıymış. Diplomatik sorun çıktı."}},
		{"t": "Gönder gitsin", "e": {}, "r": "Tüccar omuz silkip bir sonraki limana gitti."}]},
	{"id": "t_arms", "role": "trd", "w": 0.7, "war": 0, "style": "eu",
	 "q": "Tüccar kısık sesle: 'Elimde ucuz bir silah partisi var, sicili biraz kirli ama fiyatı gönül alıcı...'",
	 "o": [
		{"t": "Hepsini al", "e": {"g": -1.0}, "gamble": {"p": 0.55, "win": {"troops": 0.05}, "lose": {"stab": -3, "troops": 0.01},
		 "wr": "Silahlar yeni gibi çıktı; birlikler güçlendi.", "lr": "Namlular tutukluk yaptı. Subaylar çıldırdı."}},
		{"t": "Yarısını al", "e": {"g": -0.5}, "gamble": {"p": 0.7, "win": {"troops": 0.025}, "lose": {},
		 "wr": "Yarım parti sorunsuz teslim edildi.", "lr": "Parti kayıp çıktı; tüccar 'ya, olur böyle şeyler' dedi."}},
		{"t": "Sicilini araştır", "e": {"g": -0.2}, "gamble": {"p": 0.5, "win": {"cyb": 3}, "lose": {},
		 "wr": "Tüccarın ağı çözüldü; istihbaratımız çok şey öğrendi.", "lr": "Tüccar izini kaybettirdi."}}]},
	{"id": "t_tea", "role": "trd", "w": 0.5, "war": 0, "style": "eu",
	 "q": "Tüccar küçük bir kutu uzatıyor: 'Efsanevi çay, efendim. Üç yıl dağda kurutuldu. Halka dağıtırsanız sevilirsiniz.'",
	 "o": [
		{"t": "Halka dağıt", "e": {"g": -0.4, "stab": 2}, "r": "Çay kuyruğu şehir meydanını doldurdu. Şükranlar yağdı."},
		{"t": "Kendin iç", "e": {"stab": 1}, "r": "Çay gerçekten çok güzelmiş. Kimse bunu bilmiyor."},
		{"t": "Reddet", "e": {}, "r": "Tüccar çayı başkasına sattı."}]},
	# ------------------------------------------------------------ SPOR (dört yılda bir)
	{"id": "s_cup", "role": "spt", "w": 6.0, "war": 0, "style": "eu", "yr": [4, 2], "months": [5, 7],
	 "q": "Dünya Kupası finalleri başladı ve {c} milli takımı grupları geçti! Takıma prim vaat edelim mi?",
	 "o": [
		{"t": "Dev prim", "e": {"g": -1.0}, "gamble": {"p": 0.42, "win": {"stab": 8, "g": 0.4}, "lose": {"stab": -1},
		 "wr": "{c} DÜNYA ŞAMPİYONU! Sokaklar bayram yeri.", "lr": "Penaltılarda elendik. Sokak sessiz.",
		 "news": "{c} Dünya Kupası'nı kazandı! Ülke bayram yapıyor."}},
		{"t": "Sade prim", "e": {"g": -0.3}, "gamble": {"p": 0.2, "win": {"stab": 8}, "lose": {},
		 "wr": "Mucize! Takım kupayı kaldırdı.", "lr": "Çeyrek finalde elendik; teknik direktör istifa etti.",
		 "news": "{c} sürpriz şekilde Dünya Kupası'nı kazandı!"}},
		{"t": "Prim yok", "e": {}, "gamble": {"p": 0.08, "win": {"stab": 8}, "lose": {"stab": -2},
		 "wr": "Karşılıksız kupa! Futbolcular parasız şampiyon oldu.", "lr": "Futbolcular küstü, ilk turda elendik.",
		 "news": "{c}, primsiz Dünya Kupası şampiyonu!"}}]},
	{"id": "s_games", "role": "spt", "w": 6.0, "war": 0, "style": "eu", "yr": [4, 0], "months": [6, 8],
	 "q": "Olimpiyat oyunları başladı! Sporcularımız madalya peşinde. Kampa ne kadar yatırım yapalım?",
	 "o": [
		{"t": "Tam destek", "e": {"g": -0.9}, "gamble": {"p": 0.55, "win": {"stab": 6, "g": 0.3}, "lose": {"stab": 1},
		 "wr": "Madalya yağmuru! Gazeteler manşet yaptı.", "lr": "Birkaç bronz aldık; neyse ki katılım yeterli oldu.",
		 "news": "{c} Olimpiyatlar'ı madalya sıralamasında zirvede bitirdi!"}},
		{"t": "Kısmi destek", "e": {"g": -0.3}, "gamble": {"p": 0.28, "win": {"stab": 5}, "lose": {},
		 "wr": "Atletimiz altın aldı, halk ağladı.", "lr": "Madalya yok ama halk yine de gururlu."}},
		{"t": "Bütçe yok", "e": {}, "r": "Sporcular kendi imkânlarıyla gitti. Kimse bir şey demedi."}]},
	# ------------------------------------------------------------ MUHBİR
	{"id": "r_coup", "role": "spy", "w": 0.9, "war": 0,
	 "q": "Güvenilir bir kaynağımıza göre {nb}'de subaylar hükümetten bıkmış durumda. Küçük bir kıvılcım yeter. Ne yapalım?",
	 "o": [
		{"t": "Gizlice destekle", "e": {"g": -0.8}, "gamble": {"p": 0.6, "win": {"nbstab": -14}, "lose": {"aggr": 0.1, "stab": -1},
		 "wr": "Subaylar harekete geçti: {nb}'de hükümet sarsıldı. Parmak izimiz yok.", "lr": "İşlem sızdı; {nb} yönetimi bize karşı öfkeli."}},
		{"t": "Bilgiyi paylaş", "e": {"aggr": -0.05}, "r": "{nb} yönetimi bilgiyi minnetle aldı; gerginlik düştü."},
		{"t": "Dinle ve unut", "e": {}, "r": "Dosya arşive kaldırıldı."}]},
	{"id": "r_leak", "role": "spy", "w": 0.8, "war": 0,
	 "q": "Bir gazetecinin elinde {nb} liderine dair utanç verici belgeler var. Bize satmak istiyor.",
	 "o": [
		{"t": "Satın al ve yay", "e": {"g": -0.6, "nbstab": -7}, "r": "Belgeler yayıldı; {nb} hükümeti sallanıyor."},
		{"t": "Sakla (şantaj kozu)", "e": {"g": -0.6, "aggr": -0.07}, "r": "Belgeler kasada. {nb} artık biraz daha nazik."},
		{"t": "Reddet", "e": {}, "r": "Gazeteci başka alıcı buldu."}]},
	# ------------------------------------------------------------ SEÇİM (takvimle gelir)
	{"id": "e_vote", "role": "ele", "w": 0.0, "war": 0, "style": "eu", "sched": true,
	 "q": "Seçim günü geldi çattı! Halk sandığa gidiyor. Kampanyayı nasıl yürütelim?",
	 "o": [
		{"t": "Dev kampanya", "e": {"g": -1.5, "elect": 12}, "r": ""},
		{"t": "Sahada çalış", "e": {"g": -0.5, "elect": 5}, "r": ""},
		{"t": "Sessiz kampanya", "e": {"elect": 0}, "r": ""},
		{"t": "Seçimi ertele", "e": {"stab": -8}, "r": "Seçim 'olağanüstü koşullar' gerekçesiyle ertelendi. Basın tepkili.",
		 "fatal": {"p": 0.1, "k": 0.006, "text": "Seçimin ertelenmesi halkı sokağa döktü. Hükümetin düştü."}}]},
]

# nasıl tetiklenir: ilk 2. turda, sonra ~her 4-9 turda bir
const FIRST_TURN := 2
const MIN_GAP := 4


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open("res://data/cabinet.json", FileAccess.READ)
	if f == null:
		return
	var j = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(j) == TYPE_DICTIONARY and j.has("ministers"):
		_names = j["ministers"]


## [isim, kadın mı]. Gerçek isimler (Kasım 2026) birkaç yıl geçerli; sonra ülkenin isim kültürüne göre
## deterministik rastgele isimler gelir. Tarihî kiplerde ve gerçek isim bulunmayan görevlerde de üretilir.
static func minister_of(c, role: String, turn: int = 0) -> Array:
	if role in ["trd", "spt", "ele"]:
		return _guest_of(c, role, turn)
	if c.is_player and role in APPOINT:
		if c.cab.is_empty():
			init_cabinet(c, turn)
		if c.cab.has(role):
			return [c.cab[role].n, c.cab[role].f]
	return _base_minister(c, role, turn)


## Kabine dışı konuklar (tüccar, federasyon, seçim kurulu): tur başına sabit rastgele isim.
static func _guest_of(c, role: String, turn: int) -> Array:
	var key := "%s|%s|%d" % [c.name_en, role, turn]
	var fem := NameGen.is_female(key, 0.3)
	var cul: String = NameGen.culture_of(c)
	if role == "trd":
		var ks: Array = NameGen.POOLS.keys()
		cul = ks[absi(hash(key)) % ks.size()]
	return [NameGen.person(cul, key, fem), fem]


static func _base_real(c, role: String) -> String:
	_load()
	var e: Dictionary = _names.get(c.name_en, {})
	return e.get(role, "") if (not Macro.era_on and role != "amb") else ""


static func _base_minister(c, role: String, turn: int = 0) -> Array:
	var real: String = _base_real(c, role)
	var ye: float = float(turn * 7 + Names.start_doy) / 365.0
	var life: float = 2.0 + float(hash(c.name_en + role) % 3)       # gerçek bakan 2-4 yıl görevde kalır
	if real != "" and ye < life:
		var parts: PackedStringArray = real.split("|")
		return [parts[0], parts.size() > 1 and parts[1] == "f"]
	var term: int
	if real != "":
		term = 1 + int((ye - life) / 4.0)
	else:
		term = int((ye + float(hash(role + c.name_en) % 4)) / 4.0)
	var key := "%s|%s|%d" % [c.name_en, role, term]
	var fem := NameGen.is_female(key, 0.25 if role != "def" else 0.12)
	return [NameGen.person(NameGen.culture_of(c), key, fem), fem]


# ===================================================================== kabine kadrosu (oyuncu)
# Bakanlar görev süresi dolunca/istifa edince/skandalla düşünce yerine 3 aday gelir:
# en usta pahalı, en acemi ucuz (ama skandal riskli), ortadaki orta. Seçilen bakan her hafta küçük bir bonus verir.

const APPOINT := ["def", "for", "int", "fin", "hlt", "spy"]
const Q_NAME := ["Acemi", "Kıdemli", "Usta"]
const Q_COST := [0.15, 0.7, 2.2]               # haftalık net gelirin katı
const ROLE_FX := {
	"def": ["Ordu mevcudu büyümez", "Ordu mevcudu yavaş büyür", "Ordu mevcudu hızla büyür"],
	"for": ["Komşular değişmez", "Komşular yavaşça yumuşar", "Komşular belirgin biçimde yumuşar"],
	"int": ["İstikrar hafifçe aşınır", "İstikrar hafifçe artar", "İstikrar düzenli artar"],
	"fin": ["Her hafta gelirden pay kaçar", "Hazine hafifçe büyür", "Hazine her hafta kâr eder"],
	"hlt": ["Huzursuzluk kendi hâline", "Huzursuzluk ara sıra azalır", "Huzursuzluk sık sık azalır"],
	"spy": ["Siber savunma durağan", "Siber olgunluk yavaş artar", "Siber olgunluk hızla artar"],
}
const BIOS := [
	["Eniştesi eski bakan. Özgeçmişi tek sayfa, o da büyük puntolu.", "Her toplantıda 'bunu daha önce görmüştüm' diyor; görmemiş.",
	 "Maaşını az istiyor; bunun bir nedeni olmalı.", "Parti gençlik kolundan. Enerjik, hevesli, biraz da tehlikeli.",
	 "Kimse tanımıyor, bu yüzden kimse itiraz etmiyor.", "Referansları arasında bir hemşehri derneği var.",
	 "Öğle yemeğinde uyuyor ama bütçeye sadık (şimdilik)."],
	["Yirmi yıllık bürokrat. Sürpriz yok, skandal yok.", "Sakin, düzenli; dosyalarını hiç kaybetmez.",
	 "Muhalefet bile ona 'ciddi' diyor.", "Her kabinede olan, kimsenin hatırlamadığı kişi.",
	 "İş bilen, iddiasız bir teknisyen.", "Orta yollu: kimseyi kızdırmıyor, kimseyi uçurmuyor."],
	["Ödüllü teknokrat; diplomaları cüzdanından daha ağır.", "Savaş ve barış tecrübeli bir efsane; maaşı da efsane.",
	 "Üç ülkede danışmanlık yaptı, hepsi geri çağırıyor.", "Dünya basını ona 'kabinenin beyni' diyor.",
	 "Yalnızca en iyisiyle çalışır; bunun faturası var.", "Hem halkın hem ordunun sevdiği nadir isimlerden."],
]


## Oyuncunun ilk kadrosunu kurar: gerçek (veya üretilmiş) isimler, hepsi "Kıdemli".
static func init_cabinet(c, turn: int) -> void:
	c.cab = {}
	var days: float = float(turn * 7 + Names.start_doy)
	for role in APPOINT:
		var real: String = _base_real(c, role)
		var life: float = 2.0 + float(hash(c.name_en + role) % 3)
		var is_real := false
		var until: int
		if real != "" and days / 365.0 < life:
			is_real = true
			until = turn + maxi(10, int((life * 365.0 - days) / 7.0))
		else:
			until = turn + 52 * (1 + absi(hash(role + c.name_en)) % 4) + 10
		var nm: Array = _base_minister(c, role, turn)
		c.cab[role] = {"n": nm[0], "f": nm[1], "q": 1, "since": turn, "until": until, "real": is_real, "why": ""}


## Görevi boşalan roller (süre doldu, istifa, skandal, azil).
static func vacancies(gs) -> Array:
	var c = gs.countries[gs.player]
	if c.cab.is_empty():
		init_cabinet(c, gs.turn)
	var out: Array = []
	for role in APPOINT:
		if c.cab.has(role) and gs.turn >= int(c.cab[role].until):
			out.append(role)
	return out


static func _income_unit(gs, c) -> float:
	return maxf(Macro.net_income(gs, c), maxf(c.income, 1.0) * 0.12)


static func candidates(gs, role: String) -> Array:
	var c = gs.countries[gs.player]
	var unit: float = _income_unit(gs, c)
	var out: Array = []
	var fems: Array = []
	for q in 3:
		fems.append(NameGen.is_female("%s|cand|%d|%s|%d" % [c.name_en, gs.turn, role, q], 0.3 if role != "def" else 0.15))
	if fems[0] == fems[1] and fems[1] == fems[2] and role != "def":
		fems[1] = not fems[1]                      # üç aday aynı cinsiyette görünmesin (portre çeşitliliği)
	for q in 3:
		var key := "%s|cand|%d|%s|%d" % [c.name_en, gs.turn, role, q]
		var fem: bool = fems[q]
		var bios: Array = BIOS[q]
		var cost: float = unit * Q_COST[q]
		if q == 0:
			cost = minf(cost, c.gold)
		out.append({"n": NameGen.person(NameGen.culture_of(c), key, fem), "f": fem, "q": q,
			"bio": bios[absi(hash(key)) % bios.size()], "cost": cost, "afford": c.gold >= cost})
	return out


static func appoint(gs, role: String, cand: Dictionary) -> void:
	var c = gs.countries[gs.player]
	c.gold = maxf(0.0, c.gold - float(cand.cost))
	var term: int = 52 * (3 + absi(hash(cand.n)) % 3)
	c.cab[role] = {"n": cand.n, "f": cand.f, "q": int(cand.q), "since": gs.turn, "until": gs.turn + term, "real": false, "why": ""}
	gs.post_news("%s: %s göreve başladı. (%s)" % [ROLE_TITLE[role], cand.n, Q_NAME[int(cand.q)]], -1, "info", "badge")


## Bakanı görevden alır; istikrar bedeli. Sonraki kabine toplantısında yerine aday gelir.
static func dismiss(gs, role: String) -> void:
	var c = gs.countries[gs.player]
	if not c.cab.has(role):
		return
	c.cab[role].until = gs.turn
	c.cab[role].why = "fired"
	c.stability = clampf(c.stability - 2.0, 5.0, 100.0)


static func vacancy_text(gs, role: String) -> String:
	var c = gs.countries[gs.player]
	var e: Dictionary = c.cab[role]
	match String(e.get("why", "")):
		"scandal":
			return "%s %s yolsuzluk iddialarıyla görevden düştü. Yerine kimi atayalım?" % [ROLE_TITLE[role], e.n]
		"resign":
			return "%s %s istifa etti. Yerine kimi atayalım?" % [ROLE_TITLE[role], e.n]
		"fired":
			return "%s %s görevden alındı. Yerine kimi atayalım?" % [ROLE_TITLE[role], e.n]
		"gov":
			return "Yeni hükümet kuruluyor: %s %s görevini bırakıyor. Yerine kimi atayalım?" % [ROLE_TITLE[role], e.n]
	return "%s %s görev süresini tamamladı. Yerine kimi atayalım?" % [ROLE_TITLE[role], e.n]


## Her hafta: bakanların bonusu, skandal/istifa riski (gerçek isimler ayrı tutulur: onlara asla skandal yazılmaz).
static func weekly(gs) -> void:
	if gs.player < 0:
		return
	var c = gs.countries[gs.player]
	if not c.alive:
		return
	if c.cab.is_empty():
		init_cabinet(c, gs.turn)
	var rng: RandomNumberGenerator = gs.rng
	for role in APPOINT:
		if not c.cab.has(role):
			continue
		var e: Dictionary = c.cab[role]
		if gs.turn >= int(e.until):
			continue
		var q: int = int(e.q)
		match role:
			"fin":
				c.gold = maxf(0.0, c.gold + c.income * [-0.01, 0.01, 0.035][q])
			"int":
				c.stability = clampf(c.stability + [-0.04, 0.02, 0.07][q], 5.0, 100.0)
			"def":
				var g: float = [0.0, 0.0003, 0.0012][q]
				if g > 0.0:
					for a in gs.armies_of(c.id):
						a.size += int(a.size * g)
			"for":
				var d: float = [0.0, 0.0003, 0.0012][q]
				if d > 0.0:
					for n in gs.neighbor_countries(c.id):
						var cc = gs.countries[n]
						if cc.alive and not cc.is_rebel:
							cc.aggression = clampf(cc.aggression - d, 0.05, 0.98)
			"hlt":
				if rng.randf() < [0.0, 0.08, 0.25][q]:
					var ids: Array = gs.country_province_ids(c.id)
					if not ids.is_empty():
						var p = gs.provinces[ids[rng.randi_range(0, ids.size() - 1)]]
						p.unrest = maxi(0, p.unrest - 1)
			"spy":
				c.cyber = clampf(c.cyber + [0.0, 0.015, 0.05][q], 0.0, 100.0)
		if bool(e.real):
			continue
		if q == 0 and rng.randf() < 0.004:
			e.until = gs.turn
			e.why = "scandal"
			var loss: float = maxf(c.income, 1.0) * rng.randf_range(1.0, 2.0)
			c.gold = maxf(0.0, c.gold - loss)
			c.stability = clampf(c.stability - 3.0, 5.0, 100.0)
			gs.post_news("SKANDAL: %s %s zimmet iddialarıyla sarsıldı; kasadan %s kayboldu." % [ROLE_TITLE[role], e.n, Macro.money(loss)], c.capital, "event_player", "megaphone")
		elif rng.randf() < 0.0005:
			e.until = gs.turn
			e.why = "resign"
			gs.post_news("%s %s istifa etti." % [ROLE_TITLE[role], e.n], -1, "info", "badge")
	# seçim takvimi
	if c.elect_turn < 0:
		c.elect_turn = gs.turn + 70 + absi(hash(c.name_en)) % 60


static func election_due(gs) -> bool:
	var c = gs.countries[gs.player]
	return c.elect_turn >= 0 and gs.turn >= c.elect_turn and not Macro.era_on and Politics.has_elections(gs, gs.player)


static var _nb_name := ""
static var _nb_id := -1
static var _en_name := ""
static var outcome_text := ""


static func _random_neighbor(gs, cid: int, rng: RandomNumberGenerator) -> String:
	if _nb_name != "":
		return _nb_name
	var nbs: Array = gs.neighbor_countries(cid)
	var cands: Array = []
	for n in nbs:
		var cc = gs.countries[n]
		if cc.alive and not cc.is_rebel:
			cands.append(cc)
	if cands.is_empty():
		for cc2 in gs.countries:
			if cc2.alive and not cc2.is_rebel and cc2.id != cid:
				cands.append(cc2)
				if cands.size() > 6:
					break
	if cands.is_empty():
		return "komşu ülke"
	var pick_c = cands[rng.randi_range(0, cands.size() - 1)]
	_nb_name = pick_c.name
	_nb_id = pick_c.id
	return _nb_name


static func _enemy_name(gs, c, rng: RandomNumberGenerator) -> String:
	for e in c.enemies:
		var ec = gs.countries[e]
		if ec.alive:
			return ec.name
	return _random_neighbor(gs, c.id, rng)


## Bu tur gösterilecek bir kart seç (yoksa boş sözlük). last_turn: son kart turu, recent: son kimlikler.
static func pick(gs, last_turn: int, recent: Array, rng: RandomNumberGenerator, force: bool = false) -> Dictionary:
	var c = gs.countries[gs.player]
	_nb_name = ""
	_nb_id = -1
	if not force:
		if gs.turn < FIRST_TURN or gs.turn - last_turn < MIN_GAP:
			return {}
		var chance := 0.22 + 0.04 * float(gs.turn - last_turn - MIN_GAP)
		if gs.turn == FIRST_TURN:
			chance = 1.0
		if rng.randf() > minf(chance, 0.8):
			return {}
	var at_war: bool = not c.enemies.is_empty()
	var pool: Array = []
	var tot := 0.0
	for card in CARDS:
		if recent.has(card.id) or card.get("sched", false):
			continue
		if Macro.era_on and (card.id == "d_cyber" or card.id == "i_press" or card.id == "s_cyberhit"):
			continue
		if card.has("yr"):
			var ym: Array = Names.year_month(gs.turn)
			if ym[0] % int(card.yr[0]) != int(card.yr[1]) or ym[1] < int(card.months[0]) or ym[1] > int(card.months[1]):
				continue
		var wcond: int = card.get("war", 0)
		if wcond == 1 and not at_war:
			continue
		if wcond == 0 and at_war and rng.randf() < 0.5:
			continue
		if card.has("stab_lt") and c.stability >= float(card.stab_lt):
			continue
		var w: float = card.get("w", 1.0)
		if at_war and card.role in ["def", "spy"]:
			w *= 1.4
		pool.append([card, w])
		tot += w
	if pool.is_empty():
		return {}
	var r := rng.randf() * tot
	for it in pool:
		r -= it[1]
		if r <= 0.0:
			return it[0]
	return pool[pool.size() - 1][0]


## Takvimle gelen kart (seçim) varsa onu döndürür.
static func scheduled(gs) -> Dictionary:
	_nb_name = ""
	_nb_id = -1
	if election_due(gs):
		for card in CARDS:
			if card.id == "e_vote":
				return card
	return {}


static func fill(gs, text: String, rng: RandomNumberGenerator) -> String:
	var c = gs.countries[gs.player]
	var cap: String = gs.provinces[c.capital].name if c.capital >= 0 else "başkent"
	return text.replace("{nb}", _random_neighbor(gs, c.id, rng)).replace("{en}", _enemy_name(gs, c, rng)).replace("{c}", c.name).replace("{cap}", cap)


## Etkileri uygular ve arayüz için [{ic, txt, good}] listesi döndürür.
static func apply(gs, eff: Dictionary) -> Array:
	var c = gs.countries[gs.player]
	var out: Array = []
	# birim: haftalık net gelir (en az brüt gelirin %12'si); kasa farkı oyuncuya anlamlı kalsın
	var inc: float = maxf(Macro.net_income(gs, c), maxf(c.income, 1.0) * 0.12)
	for k in eff:
		var v: float = float(eff[k])
		match k:
			"g":
				var amt: float = inc * v
				c.gold = maxf(0.0, c.gold + amt)
				out.append({"ic": "coins", "txt": ("%s%s" % ["+" if amt >= 0 else "−", Macro.money(absf(amt))]), "good": v >= 0})
			"stab":
				c.stability = clampf(c.stability + v, 5.0, 100.0)
				out.append({"ic": "stability", "txt": "%s%d İstikrar" % ["+" if v >= 0 else "−", int(absf(v))], "good": v >= 0})
			"cyb":
				c.cyber = clampf(c.cyber + v, 0.0, 100.0)
				out.append({"ic": "cyber", "txt": "%s%d Siber" % ["+" if v >= 0 else "−", int(absf(v))], "good": v >= 0})
			"ind":
				c.industry = clampf(c.industry + v, 0.0, 100.0)
				out.append({"ic": "industry", "txt": "%s%d Sanayi" % ["+" if v >= 0 else "−", int(absf(v))], "good": v >= 0})
			"log":
				c.logistics = clampf(c.logistics + v, 0.0, 100.0)
				out.append({"ic": "truck", "txt": "%s%d Lojistik" % ["+" if v >= 0 else "−", int(absf(v))], "good": v >= 0})
			"tech":
				c.tech = clampf(c.tech + v, 0.0, 1.0)
				out.append({"ic": "flask", "txt": "%s%.1f Teknoloji" % ["+" if v >= 0 else "−", absf(v) * 100.0], "good": v >= 0})
			"troops":
				var added := 0
				for a in gs.armies_of(c.id):
					var d := int(a.size * v)
					a.size = maxi(10, a.size + d)
					added += d
				gs.armies_changed.emit()
				out.append({"ic": "infantry", "txt": "%s%s Asker" % ["+" if added >= 0 else "−", Macro.num(absf(added))], "good": added >= 0})
			"unrest":
				var pids: Array = gs.country_province_ids(c.id)
				for i in int(v):
					if pids.is_empty():
						break
					var p = gs.provinces[pids[gs.rng.randi_range(0, pids.size() - 1)]]
					p.unrest = mini(p.unrest + 2, 12)
				out.append({"ic": "unrest", "txt": "Huzursuzluk", "good": false})
			"aggr":
				for n in gs.neighbor_countries(c.id):
					var cc = gs.countries[n]
					if cc.alive and not cc.is_rebel:
						cc.aggression = clampf(cc.aggression + v, 0.05, 0.98)
				out.append({"ic": "flag", "txt": ("Komşular sertleşti" if v > 0 else "Komşular yumuşadı"), "good": v < 0})
			"nbstab":
				if _nb_id >= 0 and _nb_id < gs.countries.size():
					var nc = gs.countries[_nb_id]
					nc.stability = clampf(nc.stability + v, 5.0, 100.0)
					out.append({"ic": "spy", "txt": "%s sarsıldı" % nc.name, "good": v < 0})
			"mit":
				if gs.crisis_active_for_card():
					gs.crisis["mit"] = v
					out.append({"ic": "shield", "txt": ("Kriz etkisi azaldı" if v < 1.0 else "Kriz tam etkili"), "good": v < 1.0})
			"elect":
				out.append_array(_election(gs, c, v))
			"dev":
				if c.capital >= 0:
					var cp = gs.provinces[c.capital]
					cp.dev = mini(cp.dev + int(v), 6)
				out.append({"ic": "city", "txt": "+Kalkınma", "good": true})
	return out


static func _election(gs, c, bonus: float) -> Array:
	var share: float = 30.0 + c.stability * 0.40 + bonus + gs.rng.randf_range(-7.0, 7.0)
	share = clampf(share, 22.0, 78.0)
	var out: Array = []
	c.elect_turn = gs.turn + 208
	if share >= 50.0:
		c.stability = clampf(c.stability + 4.0, 5.0, 100.0)
		outcome_text = "Sandıklar açıldı: %%%d oyla seçimi kazandın! Halk seninle." % int(share)
		gs.post_news("%s seçimlerinde iktidar %%%d oyla güven tazeledi." % [c.name, int(share)], c.capital, "event_player", "ballot")
		out.append({"ic": "ballot", "txt": "Seçim: %%%d" % int(share), "good": true})
		out.append({"ic": "stability", "txt": "+4 İstikrar", "good": true})
	else:
		c.stability = clampf(c.stability - 6.0, 5.0, 100.0)
		var cur: Array = Macro.leader_of(c)
		var key := "%s|elect|%d" % [c.name_en, gs.turn]
		var fem: bool = NameGen.is_female(key, 0.25)
		var nm: String = NameGen.person(NameGen.culture_of(c), key, fem)
		if cur[0] != "":
			c.leader = "%s|%s" % [cur[0], nm]
		var roles: Array = APPOINT.duplicate()
		roles.shuffle()
		for i in 2:
			if c.cab.has(roles[i]):
				c.cab[roles[i]].until = gs.turn
				c.cab[roles[i]].why = "gov"
		outcome_text = "Sandıklar açıldı: yalnızca %%%d oy aldın. Muhalefet iktidara geliyor; yeni lider %s. Kabinenin bir kısmı değişecek." % [int(share), nm]
		gs.post_news("%s'de seçimi muhalefet kazandı; yeni lider %s göreve başladı." % [c.name, nm], c.capital, "event_player", "ballot")
		out.append({"ic": "ballot", "txt": "Seçim: %%%d" % int(share), "good": false})
		out.append({"ic": "stability", "txt": "−6 İstikrar", "good": false})
	return out


## Seçeneği çözer: şans oyunu (gamble) ve takvim etkileri dahil. {r, chips, win} döndürür.
static func resolve(gs, rng: RandomNumberGenerator, card: Dictionary, opt: Dictionary) -> Dictionary:
	var e: Dictionary = opt.e.duplicate()
	var r: String = String(opt.get("r", ""))
	var win := true
	var news := ""
	if opt.has("gamble"):
		var g: Dictionary = opt.gamble
		win = rng.randf() < float(g.p)
		var add: Dictionary = g.win if win else g.lose
		for k in add:
			e[k] = float(e.get(k, 0.0)) + float(add[k])
		r = g.wr if win else g.lr
		if win and g.has("news"):
			news = g.news
	outcome_text = ""
	var chips: Array = apply(gs, e)
	if outcome_text != "":
		r = outcome_text
	var c = gs.countries[gs.player]
	if card.get("sched", false) and not e.has("elect"):
		c.elect_turn = gs.turn + 52
	if news != "":
		gs.post_news(fill(gs, news, rng), c.capital, "event_player", "trophy")
	return {"r": fill(gs, r, rng), "chips": chips, "win": win}


## Seçeneğin oyunu bitirme olasılığı (0..1). Arayüz ☠ ile uyarır.
static func fatal_chance(gs, opt: Dictionary) -> float:
	if not opt.has("fatal"):
		return 0.0
	var c = gs.countries[gs.player]
	var f: Dictionary = opt.fatal
	var extra: float = maxf(0.0, 55.0 - c.stability) * float(f.get("k", 0.006))
	return clampf(float(f.get("p", 0.1)) + extra, 0.0, 0.6)

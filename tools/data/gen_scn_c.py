#!/usr/bin/env python3
"""Kalan senaryolar için olay kartları: cyprus27, kara, reich, balt, napol, siber -> data/scn_moments/<id>.json. Çalıştır: python3 tools/data/gen_scn_c.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scn_kit import Scn

US = "United States of America"; RU = "Russia"; TR = "Turkey"; GR = "Greece"; CY = "Cyprus"; NC = "N. Cyprus"; FR = "France"; IL = "Israel"; EG = "Egypt"
SY = "Syria"; IQ = "Iraq"; IR = "Iran"; DE = "Germany"; PL = "Poland"; CZ = "Czechia"; UK = "United Kingdom"; ES = "Spain"; IT = "Italy"
EE = "Estonia"; LV = "Latvia"; FI = "Finland"; LT = "Lithuania"; BY = "Belarus"; CN = "China"; JP = "Japan"; IN = "India"; NL = "Netherlands"; DK = "Denmark"
KP = "North Korea"; KR = "South Korea"; SA = "Saudi Arabia"

# ------------------------------------------------------------ cyprus27
s = Scn("cyprus27")
s.m("sondaj", 6, "Sondaj Gemileri Karşı Karşıya || Drill Ships Face to Face",
    "Doğu Akdeniz'de gaz ruhsat sahalarında bir Türk sondaj gemisi ile Kıbrıs-Fransız konsorsiyumunun gemisi karşılaştı; iki tarafın savaş gemileri sahada. Her taraf kendi deniz yetki alanını savunuyor. || A Turkish drill ship and a Cypriot-French consortium vessel met in the contested gas blocks of the Eastern Mediterranean; warships of both sides are on the scene. Each side defends its own maritime zone.",
    [["rel", TR, GR, -3], ["rel", TR, FR, -2], ["stab", CY, -1]],
    {TR: s.r("Ankara 'Mavi Vatan' tezini savunuyor; gemiyi çekmek geri adım olarak görülebilir. || Ankara defends its 'Blue Homeland' thesis; pulling the ship back could look like a retreat.",
            s.o("Sondaja devam et || Keep drilling", "Türkiye gemiyi sahada tuttu; donanma eşlik etti. || Turkey kept the ship on site under naval escort.", [["rel", TR, GR, -4], ["rel", TR, FR, -3], ["stab", TR, 2]]),
            s.o("Gemiyi çek ve masaya otur || Withdraw and talk", "Türkiye gemiyi geri çekip diyalog önerdi. || Turkey pulled the ship back and offered dialogue.", [["rel", TR, GR, 4], ["stab", TR, -1]])),
     GR: s.r("Atina Brüksel ve Paris'in desteğini topluyor; ama savaş gemilerinin sahada olması kazaya açık. || Athens is gathering support from Brussels and Paris, but warships at close range invite an accident.",
            s.o("AB ve Fransa'dan destek iste || Request EU and French backing", "Atina AB ve Fransa'dan açık destek aldı. || Athens secured clear backing from the EU and France.", [["rel", GR, FR, 4], ["rel", GR, TR, -3]]),
            s.o("Doğrudan görüşme öner || Propose direct talks", "Atina Ankara'ya istikşafi görüşme önerdi. || Athens proposed exploratory talks to Ankara.", [["rel", GR, TR, 4], ["stab", GR, -1]])),
     FR: s.r("Fransız konsorsiyum projesi tehdit altında; Paris sahaya fırkateyn gönderebilir. || The French consortium's project is under threat; Paris could send a frigate.",
            s.o("Fırkateyn gönder || Send a frigate", "Paris bölgeye bir fırkateyn gönderdi. || Paris sent a frigate to the region.", [["rel", FR, TR, -4], ["rel", FR, GR, 3]]),
            s.o("Diplomasiyi tercih et || Favour diplomacy", "Fransa AB aracılığıyla çözüm aradı. || France sought a solution through the EU.", [["rel", FR, TR, 2]]), minor=True)},
    icon="ship", scene="naval")
s.m("kablo", 22, "Deniz Altı Kablo Kesildi || An Undersea Cable Is Cut",
    "Kıbrıs–Mısır arasındaki enerji ve veri kablosunda arıza oluştu; iki taraf da birbirini suçluyor. Ada çevresinde denizaltı hatlarının güvenliği ilk kez bu kadar büyük bir gündem. || A fault hit the Cyprus–Egypt energy and data cable; both sides blame each other. The safety of undersea lines around the island has never been so high on the agenda.",
    [["rel", EG, TR, -2], ["rel", CY, TR, -3], ["stab", CY, -2]],
    {CY: s.r("Kablo projesi AB için de stratejik; ama delil yok. İddia mı, soruşturma mı? || The cable project is strategic for the EU too, but there is no proof. Accuse or investigate?",
            s.o("Uluslararası soruşturma iste || Demand an international inquiry", "Lefkoşa AB ve BM'den soruşturma talep etti. || Nicosia called for an EU and UN inquiry.", [["rel", CY, GR, 3], ["rel", CY, FR, 2]]),
            s.o("Doğrudan Ankara'yı suçla || Blame Ankara directly", "Kıbrıs hükûmeti kablo arızasından Türkiye'yi sorumlu tuttu. || The Cypriot government blamed Turkey for the fault.", [["rel", CY, TR, -5], ["stab", CY, 1]])),
     TR: s.r("Ankara olayla ilgisi olmadığını söylüyor; ama kablo hattının geçtiği deniz yetki alanı tartışmalı. || Ankara says it is unconnected, but the sea zone the cable crosses is disputed.",
            s.o("Ortak teknik inceleme öner || Offer a joint technical review", "Türkiye ortak teknik inceleme önerdi. || Turkey offered a joint technical review.", [["rel", TR, CY, 3], ["rel", TR, EG, 3]]),
            s.o("Suçlamaları reddet, donanmayı artır || Reject the claims and raise naval presence", "Ankara suçlamaları reddedip denizde varlığını artırdı. || Ankara rejected the claims and raised its naval presence.", [["rel", TR, CY, -3], ["troops", TR, 2]]))},
    icon="warning", scene="crisis")
s.m("bm", 44, "BM Müzakereleri Zirvesi || The UN Summit on the Island",
    "BM Genel Sekreteri adadaki Türk ve Rum liderleri yeniden görüşmeye çağırdı. İki devletli çözüm, federasyon ve işbirliği başlıklarında yeni formüller konuşuluyor; ama güvenlik garantileri ve sondaj hakları tıkanıklık yaratıyor. || The UN Secretary-General invited the leaders of the two communities back to the table. New formulas on a two-state solution, federation and cooperation are in play, but security guarantees and drilling rights remain sticking points.",
    [["rel", TR, GR, 2], ["rel", CY, NC, 1]],
    {TR: s.r("Ankara 'egemen eşitlik' diyor; KKTC ile birlikte hareket etmek şart. || Ankara insists on 'sovereign equality' and must coordinate with the TRNC.",
            s.o("Egemen eşitlik şartı koş || Insist on sovereign equality", "Türkiye masada iki devletli çözüm vurgusu yaptı. || Turkey stressed a two-state solution at the table.", [["rel", TR, NC, 5], ["rel", TR, GR, -2]]),
            s.o("Esnek formüle açık ol || Be open to a flexible formula", "Türkiye işbirliği temelli yeni formülü dinlemeye razı oldu. || Turkey agreed to listen to a cooperation-based formula.", [["rel", TR, GR, 4], ["rel", TR, NC, -2], ["stab", TR, 1]])),
     CY: s.r("Lefkoşa AB üyeliğini ve garanti sistemini koruyor; federasyon için taviz verecek mi? || Nicosia guards its EU membership and the guarantee system; will it concede on federation?",
            s.o("Federasyon önerisine evet || Say yes to a federation proposal", "Kıbrıs liderliği güçlendirilmiş federasyon önerisine açık davrandı. || The Cypriot leadership was open to a strengthened federation proposal.", [["rel", CY, NC, 4], ["rel", CY, TR, 3], ["stab", CY, -1]]),
            s.o("Mevcut düzeni savun || Defend the status quo", "Rum yönetimi mevcut düzeni savundu. || The Greek Cypriot side defended the status quo.", [["rel", CY, NC, -3], ["stab", CY, 1]])),
     NC: s.r("KKTC tanınma ve doğrudan ticaret talep ediyor; Ankara'nın ve BM'nin dengesi kritik. || The TRNC wants recognition and direct trade; the balance between Ankara and the UN is critical.",
            s.o("Tanınma kampanyası başlat || Launch a recognition campaign", "KKTC uluslararası tanınma diplomasisini hızlandırdı. || The TRNC stepped up its recognition diplomacy.", [["rel", NC, TR, 4], ["rel", NC, CY, -3]]),
            s.o("Doğrudan ticaret için pazarlık et || Bargain for direct trade", "KKTC AB ile sınırlı ticaret görüşmesi yürüttü. || The TRNC held limited trade talks with the EU.", [["rel", NC, CY, 3], ["gold", NC, 0.5]]), minor=True)},
    icon="dove", scene="peace")
s.save()

# ------------------------------------------------------------ kara
s = Scn("kara")
s.m("sehir", 5, "Çöl Şehri Düştü || A Desert City Falls",
    "Kara Sancak savaşçıları Suriye ve Irak çölünde stratejik bir şehri ele geçirdi; yerel güçler dağıldı. Binlerce sivil kaçıyor, sınır kapıları doluyor. Bölge devletleri mültecilerle ve sınır güvenliğiyle uğraşıyor. || Black Banner fighters took a strategic desert city in Syria and Iraq; local forces dissolved. Thousands of civilians are fleeing and border crossings are overwhelmed. Regional states face refugees and border security at once.",
    [["stab", SY, -2], ["stab", IQ, -2], ["stab", TR, -1]],
    {TR: s.r("Sınır boyunca mülteci akını ve olası terör tehdidi var. Müdahale mi, sınırı kapatmak mı? || There is a refugee influx and potential terror threat along the border. Intervene or seal it?",
            s.o("Sınır güvenlik hattı kur || Establish a border security belt", "Türkiye sınır boyunca güvenlik hattı kurdu. || Turkey set up a border security belt.", [["troops", TR, 2], ["stab", TR, 1], ["gold", TR, -0.5]]),
            s.o("Sınır ötesi operasyon yap || Launch a cross-border operation", "Türk birlikleri sınır ötesinde sınırlı bir operasyon başlattı. || Turkish troops began a limited cross-border operation.", [["troops", TR, -2], ["rel", TR, IQ, -2], ["rel", TR, US, 2]])),
     IQ: s.r("Bağdat'ın ordusu dağınık; milisler ve Kürt güçleriyle ortak savunma kurmak şart. || Baghdad's army is fragmented; joint defence with militias and Kurdish forces is essential.",
            s.o("Ortak savunma koalisyonu kur || Form a joint defence coalition", "Bağdat Kürt ve milis güçlerle ortak savunma kurdu. || Baghdad formed a joint defence with Kurdish and militia forces.", [["troops", IQ, 3], ["stab", IQ, 2], ["rel", IQ, IR, 3]]),
            s.o("ABD'den hava desteği iste || Ask for US air support", "Bağdat ABD'den hava ve istihbarat desteği istedi. || Baghdad asked the US for air and intelligence support.", [["rel", IQ, US, 5], ["rel", IQ, IR, -3]])),
     IR: s.r("İran sınırın hemen yanında yeni bir Sünni aşırılıkçı yapı görüyor; Şii kutsal kentler tehdit altında. || Iran sees a new Sunni extremist entity next door; Shia holy cities are at risk.",
            s.o("Danışman ve silah gönder || Send advisers and arms", "Tahran Irak'a danışman ve silah gönderdi. || Tehran sent advisers and arms to Iraq.", [["rel", IR, IQ, 5], ["troops", IR, -1], ["gold", IR, -0.5]]),
            s.o("Sınırı tahkim et || Fortify the border", "İran sınır birliklerini tahkim etti. || Iran reinforced its border units.", [["troops", IR, 2], ["stab", IR, 1]]), minor=True)},
    icon="flag", scene="crisis")
s.m("koalisyon", 24, "Bölgesel Koalisyon Çağrısı || A Call for a Regional Coalition",
    "Kara Sancak ilerlemesini sürdürüyor. Büyük güçler ve bölge ülkeleri bir koalisyon kurulması için çağrı yaptı; ama kimin liderlik edeceği, hangi ülkenin güç göndereceği belirsiz. || Black Banner continues to advance. The great powers and regional states have called for a coalition, but who will lead and who will send forces remains unclear.",
    [["rel", US, TR, 1], ["rel", US, IQ, 2]],
    {US: s.r("Washington hava harekâtı ve özel kuvvetlerle sınırlı bir rol önerebilir; kara birliği siyaseten pahalı. || Washington can offer air power and special forces; ground troops are politically costly.",
            s.o("Hava harekâtı koalisyonu kur || Lead an air-campaign coalition", "ABD hava harekâtı koalisyonu kurdu. || The US formed an air-campaign coalition.", [["rel", US, TR, 3], ["rel", US, IQ, 4], ["gold", US, -1.0]]),
            s.o("Bölge ülkelerine bırak || Leave it to regional states", "Washington öncelikle bölge ülkelerinin sorumluluk almasını istedi. || Washington asked regional states to take responsibility.", [["rel", US, TR, -2], ["stab", US, 1]])),
     TR: s.r("Ankara koalisyonda ağırlık istiyor; ama müttefikinin Kürt gruplarla ittifakı sorun. || Ankara wants weight in the coalition, but its ally's ties to Kurdish groups are a problem.",
            s.o("Koalisyona katıl ama şart koş || Join with conditions", "Türkiye koalisyona şartlı olarak katıldı. || Turkey joined the coalition on conditions.", [["rel", TR, US, 4], ["troops", TR, -1]]),
            s.o("Tek başına hareket et || Act alone", "Ankara bağımsız bir sınır ötesi plan yürüttü. || Ankara pursued an independent cross-border plan.", [["rel", TR, US, -4], ["stab", TR, 1]])),
     IL: s.r("İsrail yeni bir kuzey cephesi istemiyor; ama aşırılıkçı bir yapı sınırdan çok uzak da değil. || Israel does not want a new northern front, but an extremist entity is not far from the border.",
            s.o("Gizli istihbarat paylaş || Share intelligence quietly", "İsrail koalisyona gizli istihbarat sağladı. || Israel quietly supplied the coalition with intelligence.", [["rel", IL, US, 3], ["rel", IL, IR, -2]]),
            s.o("Hava savunmasını güçlendir || Reinforce air defences", "İsrail kuzey hava savunmasını güçlendirdi. || Israel reinforced its northern air defences.", [["troops", IL, 2], ["gold", IL, -0.5]]))},
    icon="treaty", scene="crisis")
s.m("baraj", 54, "Baraj ve Petrol Sahaları || Dams and Oil Fields",
    "Kara Sancak Fırat üzerindeki bir barajı ve petrol sahalarını ele geçirdi. Su ve enerji kontrolü hem finansmanı hem de siyasi baskıyı güçlendiriyor; koalisyon bu altyapıyı vurup vurmamayı tartışıyor. || Black Banner seized a dam on the Euphrates and oil fields. Control of water and energy strengthens both its funding and its leverage; the coalition debates whether to strike the infrastructure.",
    [["gold", TR, -0.5], ["stab", SY, -2], ["stab", IQ, -2]],
    {IQ: s.r("Su ve petrol gelirinin kaybı ekonomiyi sarsıyor. Baraj saldırısı sivilleri de etkiler. || Losing water and oil revenue shakes the economy. A strike on the dam would also hurt civilians.",
            s.o("Barajı geri almak için kara harekâtı || Ground operation to retake the dam", "Irak birlikleri barajı geri almak için harekât başlattı. || Iraqi troops launched an operation to retake the dam.", [["troops", IQ, -3], ["stab", IQ, 2], ["buff", IQ, "att", 1.1, 6]]),
            s.o("Müzakereyle baraj yönetimini ele al || Negotiate over dam management", "Bağdat yerel aşiretlerle baraj için pazarlık yaptı. || Baghdad bargained with local tribes over the dam.", [["stab", IQ, 1], ["gold", IQ, -0.5]])),
     TR: s.r("Fırat'ın suyu Türkiye için de kritik; barajda yaşanacak bir kriz tarım ve enerjiyi etkiler. || The Euphrates is vital to Turkey too; a dam crisis would affect agriculture and energy.",
            s.o("Hava saldırısı destekle || Back an air strike", "Türkiye barajın geri alınması için hava desteği verdi. || Turkey provided air support to retake the dam.", [["rel", TR, IQ, 4], ["troops", TR, -1]]),
            s.o("Su akışını yönet || Manage river flows", "Ankara Fırat akışını düzenleyerek baskı kurdu. || Ankara regulated the Euphrates flow to apply pressure.", [["rel", TR, IQ, -2], ["gold", TR, 0.5]]), minor=True)},
    icon="dam", scene="crisis", major=False)
s.save()

# ------------------------------------------------------------ reich
s = Scn("reich")
s.m("ilan", 4, "Doğuda Ayrılık İlanı || The Eastern Secession",
    "Almanya'nın doğusunda otoriter bir hareket ayrılığını ilan etti ve modern bir ordu kurdu. Hükûmet olağanüstü toplandı; komşuların sınır güvenliği alarmda. || An authoritarian movement in eastern Germany declared secession and raised a modern army. The government met in emergency session; neighbours put their borders on alert.",
    [["stab", DE, -3], ["rel", PL, DE, 3], ["troops", PL, 2]],
    {DE: s.r("Berlin ne hareketi ezmek için orduyu mu kullanacak, yoksa siyasi bir çözüm mü arayacak? || Will Berlin use the army to crush the movement, or seek a political settlement?",
            s.o("Orduyu seferber et || Mobilise the army", "Almanya orduyu doğu sınırında seferber etti. || Germany mobilised the army on its eastern border.", [["buff", DE, "def", 1.15, 10], ["stab", DE, -1], ["gold", DE, -1.0]]),
            s.o("Müzakere ve yasal yolu dene || Try negotiation and the courts", "Berlin hareketle müzakere kanalı açtı. || Berlin opened a negotiation channel with the movement.", [["stab", DE, -2], ["rel", DE, FR, 2]])),
     PL: s.r("Varşova doğudaki yeni yapıyı kendi güvenliği için tehdit görüyor; NATO'dan destek istiyor. || Warsaw sees the new entity as a threat to its security and wants NATO backing.",
            s.o("Sınırı tahkim et || Fortify the border", "Polonya sınırını tahkim etti. || Poland fortified its border.", [["troops", PL, 3], ["buff", PL, "def", 1.15, 10]]),
            s.o("Almanya ile ortak savunma kur || Form a joint defence with Germany", "Varşova ve Berlin ortak savunma planı hazırladı. || Warsaw and Berlin drew up a joint defence plan.", [["rel", PL, DE, 6], ["stab", PL, 1]])),
     FR: s.r("Fransa Avrupa savunma çemberini toplamaya çalışıyor; ama kendi iç siyaseti bölünmüş. || France tries to assemble a European defence circle, but domestic politics are divided.",
            s.o("Avrupa Savunma Çemberi'ni destekle || Back the European Defence Circle", "Paris ortak savunma çemberine tam destek verdi. || Paris fully backed the joint defence circle.", [["rel", FR, DE, 5], ["rel", FR, PL, 4], ["troops", FR, -1]]),
            s.o("Arabuluculuk öner || Offer mediation", "Paris iki taraf arasında arabuluculuk önerdi. || Paris offered mediation between the sides.", [["stab", FR, 1]]), minor=True)},
    icon="warning", scene="crisis")
s.m("sinir", 20, "Sınırda Çatışma || Fighting on the Border",
    "Ayrılıkçı güçlerle Çek ve Polonya sınır birlikleri arasında ilk silahlı çatışma yaşandı. Bölgesel savunma çemberinin Madde 5 benzeri taahhüdü ilk kez sınanıyor. || The first armed clash broke out between the separatist forces and Czech and Polish border units. The Article 5-style pledge of the regional defence circle is tested for the first time.",
    [["troops", CZ, -2], ["troops", PL, -2], ["stab", CZ, -2]],
    {CZ: s.r("Prag küçük bir ülke; yardım gelene kadar sınırı tutmak zorunda. || Prague is a small country and must hold the border until help arrives.",
            s.o("Çemberden yardım iste || Invoke the defence circle", "Prag Avrupa Savunma Çemberi'nden acil yardım istedi. || Prague requested emergency help from the European Defence Circle.", [["rel", CZ, DE, 4], ["rel", CZ, PL, 4], ["stab", CZ, 1]]),
            s.o("Sınırı tek başına tut || Hold the border alone", "Çek birlikleri sınırda yalnız direndi. || Czech troops held the border alone.", [["buff", CZ, "def", 1.2, 8], ["troops", CZ, -2]])),
     DE: s.r("Çatışma yayılmadan karşılık verilmeli; ama sivil kayıp riski var. || A response must come before the fighting spreads, but there is a risk to civilians.",
            s.o("Sınırlı karşı saldırı || A limited counteroffensive", "Alman birlikleri sınırlı bir karşı saldırıya geçti. || German units launched a limited counteroffensive.", [["buff", DE, "att", 1.15, 8], ["troops", DE, -2]]),
            s.o("Savunmada kal || Hold defensively", "Berlin savunma hattını güçlendirip bekledi. || Berlin reinforced its defensive line and waited.", [["buff", DE, "def", 1.2, 10]])),
     PL: s.r("Sınır çatışması Polonya topraklarına sıçrayabilir. || The border fighting could spill onto Polish territory.",
            s.o("Hava ve topçu desteği ver || Provide air and artillery support", "Polonya Çek müttefikine hava ve topçu desteği verdi. || Poland gave its Czech ally air and artillery support.", [["rel", PL, CZ, 5], ["troops", PL, -1]]),
            s.o("Kendi sınırına odaklan || Focus on your own border", "Varşova kendi sınırını güvenceye aldı. || Warsaw secured its own frontier.", [["buff", PL, "def", 1.15, 8]]), minor=True)},
    icon="border_clash", scene="border")
s.m("diplomasi", 46, "Ortak Avrupa Zirvesi || A Joint European Summit",
    "Avrupa liderleri olağanüstü zirvede; Yeni Reich'in tanınmaması, ekonomik yaptırımlar ve ortak orduya katkı tartışılıyor. Bazı ülkeler siyasi çözüm istiyor, bazıları kesin sonuç. || European leaders gathered for an emergency summit; non-recognition of the New Reich, economic sanctions and contributions to a joint force are on the agenda. Some want a political settlement, others a decisive result.",
    [["rel", DE, UK, 2], ["rel", DE, FR, 2]],
    {DE: s.r("Berlin yük paylaşımı istiyor; ama ortak ordu için egemenlik tartışması çıkıyor. || Berlin wants burden sharing, but a joint force raises sovereignty disputes.",
            s.o("Ortak komuta öner || Propose a joint command", "Almanya ortak Avrupa komutası önerdi. || Germany proposed a joint European command.", [["rel", DE, FR, 4], ["rel", DE, PL, 3], ["stab", DE, 1]]),
            s.o("Ulusal komutayı koru || Keep national command", "Berlin ulusal komuta çizgisini korudu. || Berlin kept its national command line.", [["rel", DE, FR, -2], ["stab", DE, 1]])),
     UK: s.r("Londra kıtadaki bir savaşa ne kadar bulaşmak istiyor? Hava gücü ve istihbarat öne çıkabilir. || How deeply will London commit to a continental war? Air power and intelligence stand out.",
            s.o("Hava gücü ve istihbarat gönder || Send air power and intelligence", "Londra Avrupa çemberine hava ve istihbarat desteği verdi. || London gave the European circle air and intelligence support.", [["rel", UK, DE, 4], ["rel", UK, PL, 4], ["gold", UK, -0.5]]),
            s.o("Sadece yaptırım uygula || Apply sanctions only", "Britanya Yeni Reich'e ekonomik yaptırım uyguladı. || Britain imposed economic sanctions on the New Reich.", [["gold", UK, -0.2], ["stab", UK, 1]])),
     FR: s.r("Fransa nükleer şemsiye ve liderlik rolü sunabilir. || France can offer a nuclear umbrella and a leadership role.",
            s.o("Avrupa'ya güvenlik şemsiyesi sun || Offer a European security umbrella", "Fransa komşularına savunma güvencesi verdi. || France gave its neighbours a defence guarantee.", [["rel", FR, DE, 5], ["rel", FR, PL, 5], ["stab", FR, -1]]),
            s.o("Müzakere kapısını aralık tut || Keep the door open for talks", "Paris diyalog yolunu açık tuttu. || Paris kept dialogue open.", [["stab", FR, 1]]), minor=True)},
    icon="treaty", scene="peace")
s.save()

# ------------------------------------------------------------ balt
s = Scn("balt")
s.m("madde5", 3, "NATO Madde 5 Devrede || NATO Invokes Article 5",
    "Rus birlikleri Estonya ve Letonya sınırını aştı; NATO müttefikleri Madde 5'i devreye aldı. Baltık'ta hava sahası kapanıyor; Finlandiya ve Polonya acil istişare istiyor. || Russian troops crossed the Estonian and Latvian borders; NATO allies invoked Article 5. Airspace over the Baltic is closing; Finland and Poland call for urgent consultations.",
    [["rel", RU, US, -6], ["rel", RU, PL, -4], ["stab", EE, -2], ["stab", LV, -2]],
    {EE: s.r("Tallinn'in birlikleri sınırda direniyor; NATO takviyesi birkaç gün uzakta. || Tallinn's troops resist on the border; NATO reinforcements are days away.",
            s.o("Narva hattında savun || Defend at the Narva line", "Estonya birlikleri Narva hattında savundu. || Estonian troops defended the Narva line.", [["buff", EE, "def", 1.3, 10], ["stab", EE, 2]]),
            s.o("Gerillaya geç ve yedekleri seferber et || Switch to guerrilla and mobilise reserves", "Tallinn yedek kuvvetleri seferber etti. || Tallinn mobilised its reserves.", [["mob", EE], ["troops", EE, 3]])),
     RU: s.r("Moskova 'sınır ihlali' gerekçesini yineliyor; ama NATO müttefik hava gücü devreye giriyor. || Moscow repeats its 'border violation' rationale, but allied NATO air power is arriving.",
            s.o("Baltık'ta ilerlemeyi sürdür || Press on in the Baltics", "Rus birlikleri Baltık'ta ilerlemeye devam etti. || Russian troops pressed on in the Baltics.", [["buff", RU, "att", 1.15, 8], ["rel", RU, US, -4], ["troops", RU, -2]]),
            s.o("Durma noktası ilan et || Declare a pause", "Moskova 'sınırlı bir operasyon' dedi ve duraksadı. || Moscow called it 'a limited operation' and paused.", [["rel", RU, US, 2], ["stab", RU, -1]])),
     US: s.r("Washington Madde 5 taahhüdünü yerine getirecek mi, yoksa müttefiklerden yük paylaşımı mı isteyecek? || Will Washington honour Article 5, or ask allies to share the burden?",
            s.o("Hızlı Tepki Gücü gönder || Send the Rapid Reaction Force", "ABD Baltık'a hızlı tepki gücü gönderdi. || The US sent a rapid reaction force to the Baltics.", [["rel", US, EE, 6], ["rel", US, RU, -4], ["troops", US, -2]]),
            s.o("Hava ve füze savunması ver || Provide air and missile defence", "Washington Baltık'a hava ve füze savunması kaydırdı. || Washington shifted air and missile defence to the Baltics.", [["rel", US, EE, 4], ["gold", US, -0.5]])),
     FI: s.r("Finlandiya sınırında Rus birlikleri yığınağı var; ama yeni NATO üyesisin. || Russian troops are massing on Finland's border, but you are a new NATO member.",
            s.o("Sınırı tahkim et || Fortify the border", "Finlandiya Rusya sınırını tahkim etti. || Finland fortified its Russian border.", [["troops", FI, 3], ["buff", FI, "def", 1.2, 10]]),
            s.o("Müttefiklere destek ver || Support the allies", "Helsinki Baltık müttefiklerine hava ve istihbarat desteği verdi. || Helsinki gave its Baltic allies air and intelligence support.", [["rel", FI, EE, 5], ["rel", FI, RU, -4]]))},
    icon="warning", scene="pre_war")
s.m("suvalki", 18, "Suwałki Koridoru || The Suwałki Gap",
    "Rus ve Belarus birlikleri, Polonya ile Litvanya'yı ayıran dar Suwałki Koridoru'na yöneldi. Burası kesilirse Baltık ülkeleri NATO'dan kopar. || Russian and Belarusian forces headed for the narrow Suwałki Gap between Poland and Lithuania. If it is cut, the Baltic states are severed from NATO.",
    [["troops", PL, -2], ["troops", LT, -2], ["troops", BY, -2], ["stab", LT, -2]],
    {PL: s.r("Koridor Polonya'nın sorumluluğunda. Yetişen takviye olursa kapanmaz; olmazsa Baltık kopar. || The gap is Poland's responsibility. If reinforcements arrive it stays open; if not, the Baltics are cut off.",
            s.o("Koridoru tahkim et (tarihî) || Fortify the gap", "Polonya koridoru ağır silahlarla tahkim etti. || Poland fortified the gap with heavy weapons.", [["buff", PL, "def", 1.3, 12], ["troops", PL, -2], ["stab", PL, 2]]),
            s.o("Belarus'a önleyici saldırı || Pre-empt into Belarus", "Polonya Belarus sınırında önleyici bir saldırı düzenledi. || Poland launched a pre-emptive strike on the Belarusian border.", [["buff", PL, "att", 1.2, 6], ["rel", PL, BY, -8], ["troops", PL, -4]])),
     LT: s.r("Litvanya'nın ordusu küçük; Rus-Belarus kıskacı gerçek bir tehdit. || Lithuania's army is small; the Russian–Belarusian pincer is a real threat.",
            s.o("NATO takviyesini bekle || Wait for NATO reinforcements", "Vilnius NATO takviyesini bekleyerek hatlarını tuttu. || Vilnius held its lines awaiting NATO reinforcements.", [["buff", LT, "def", 1.2, 8], ["rel", LT, US, 4]]),
            s.o("Sınırı kapatıp seferber ol || Close the border and mobilise", "Litvanya sınırı kapatıp seferberlik ilan etti. || Lithuania sealed the border and mobilised.", [["mob", LT], ["rel", LT, BY, -6]])),
     DE: s.r("Alman tugayı Litvanya'da; ancak ana güç haftalar sonra gelebilir. || A German brigade is in Lithuania, but the main force may arrive only in weeks.",
            s.o("Ek tugay gönder || Send an extra brigade", "Almanya Baltık'a ek bir tugay gönderdi. || Germany sent an extra brigade to the Baltics.", [["rel", DE, LT, 5], ["troops", DE, -2], ["gold", DE, -0.5]]),
            s.o("Arabuluculuk ve yaptırım || Mediation and sanctions", "Berlin yaptırım ve arabuluculuk çağrısı yaptı. || Berlin called for sanctions and mediation.", [["rel", DE, RU, -2], ["stab", DE, 1]]), minor=True)},
    icon="tank", scene="pre_assault")
s.m("ateskes", 45, "Ateşkes Girişimi || A Ceasefire Initiative",
    "Çin ve Türkiye ortak bir ateşkes önerisiyle devreye girdi. Cepheler dondurulursa Rusya kazanımlarını koruyabilir; NATO ise geri çekilme şartı koşuyor. || China and Turkey stepped in with a joint ceasefire proposal. If fronts are frozen, Russia keeps its gains; NATO demands a pullback as a condition.",
    [["rel", CN, RU, 1], ["rel", TR, RU, 1]],
    {RU: s.r("Cephe dondurulursa kazançlar korunur; ama yaptırımlar ve NATO hava gücü maliyet yaratıyor. || A freeze preserves gains, but sanctions and NATO air power are costly.",
            s.o("Cepheyi dondurmayı kabul et || Accept a freeze", "Rusya cephe hattında ateşkesi kabul etti. || Russia accepted a ceasefire along the front.", [["peace", RU, EE], ["peace", RU, LV], ["stab", RU, 2], ["rel", RU, US, 2]]),
            s.o("Zaferi sonuna kadar sürdür || Press for victory", "Moskova ateşkesi reddedip taarruza devam etti. || Moscow rejected the ceasefire and kept attacking.", [["buff", RU, "att", 1.1, 6], ["stab", RU, -2], ["rel", RU, CN, -2]])),
     US: s.r("NATO kazanımın geri alınmasını istiyor; ateşkes bir tehlikeli emsal olabilir. || NATO wants the gains reversed; a ceasefire could set a dangerous precedent.",
            s.o("Geri çekilme şartı koş || Demand a pullback", "Washington Rus çekilmesi şartı koştu. || Washington demanded a Russian pullback.", [["rel", US, RU, -3], ["rel", US, EE, 3]]),
            s.o("Ateşkesi kabul et || Accept the ceasefire", "ABD ateşkes önerisine esneklik gösterdi. || The US showed flexibility on the ceasefire.", [["peace", US, RU], ["rel", US, RU, 3], ["rel", US, EE, -2]])),
     EE: s.r("Tallinn dondurulmuş bir cepheyle işgal altındaki topraklara razı olmak zorunda mı? || Must Tallinn accept a frozen front with its land under occupation?",
            s.o("Geri çekilmeden barış yok || No peace without a pullback", "Estonya geri çekilme olmadan barışı reddetti. || Estonia rejected peace without a pullback.", [["stab", EE, 2], ["rel", EE, US, 3]]),
            s.o("Geçici ateşkesi kabul et || Accept a temporary truce", "Estonya geçici ateşkese razı oldu. || Estonia agreed to a temporary truce.", [["peace", EE, RU], ["stab", EE, -2]]))},
    icon="dove", scene="peace")
s.save()

# ------------------------------------------------------------ napol
s = Scn("napol")
s.m("ilan", 3, "Yeni İmparatorluk İlan Edildi || The New Empire Is Proclaimed",
    "Paris çevresinde general önderliğindeki asi birlikler 'Yeni İmparatorluk'u ilan etti. Ordu ikiye bölündü; Elysée Sarayı kuşatma altında. Avrupa başkentleri yeni bir Napolyon hayaletinden endişeli. || Rebel units led by a general around Paris proclaimed the 'New Empire'. The army has split; the Élysée is under siege. European capitals fear a new Napoleonic spectre.",
    [["stab", FR, -4], ["rel", UK, FR, 2], ["troops", DE, 2]],
    {FR: s.r("Cumhuriyet ordusu bölünmüş; Paris tehlikede. Sadık birlikleri toplamak mı, başkenti terk etmek mi? || The Republican army is split and Paris is in danger. Rally loyal troops or leave the capital?",
            s.o("Paris'i savun || Defend Paris", "Cumhuriyetçi güçler Paris çevresinde savunma kurdu. || Republican forces set up a defence around Paris.", [["buff", FR, "def", 1.25, 10], ["stab", FR, 1]]),
            s.o("Hükûmeti Loire'a taşı || Move the government to the Loire", "Fransız hükûmeti Paris'ten Loire'a taşındı. || The French government relocated from Paris to the Loire.", [["stab", FR, -3], ["troops", FR, 2]])),
     DE: s.r("Berlin Fransız iç savaşının sınıra yayılmasından çekiniyor. || Berlin fears the French civil war spilling over the border.",
            s.o("Sınırı koru || Guard the frontier", "Almanya Fransa sınırını güçlendirdi. || Germany reinforced the French border.", [["troops", DE, 2], ["buff", DE, "def", 1.1, 8]]),
            s.o("Cumhuriyeti destekle || Back the Republic", "Berlin Fransız hükûmetine siyasi ve mali destek verdi. || Berlin gave the French government political and financial backing.", [["rel", DE, FR, 5], ["gold", DE, -0.5]])),
     UK: s.r("Londra Kanal'ın öbür yakasındaki gelişmeleri tarihî dersleri hatırlayarak izliyor. || London watches across the Channel, mindful of history's lessons.",
            s.o("Donanmayı Kanal'a gönder || Send the fleet to the Channel", "Kraliyet Donanması Manş'ta devriye başladı. || The Royal Navy began Channel patrols.", [["rel", UK, FR, 2], ["troops", UK, 1]]),
            s.o("Tarafsız kal ve izle || Stay neutral and watch", "Britanya kararsız kalıp gelişmeleri izledi. || Britain stayed neutral and watched.", [["stab", UK, 1]]), minor=True)},
    icon="flag", scene="crisis")
s.m("ordu", 22, "Grande Armée'nin Yürüyüşü || The March of the New Grande Armée",
    "Yeni İmparatorluk Belçika ve Ren sınırına doğru yürüyor. İmparator 'Avrupa'yı yeniden düzenleyeceğini' ilan etti; İspanya ve İtalya tarafsızlık arayışında. || The New Empire is marching toward Belgium and the Rhine. The Emperor proclaimed he will 'reorder Europe'; Spain and Italy seek neutrality.",
    [["troops", DE, -2], ["rel", DE, FR, -3], ["stab", ES, -1], ["stab", IT, -1]],
    {DE: s.r("Alman ordusu Ren'de hazır; ama yeni İmparatorluk piyade ve topçuda üstün. || The German army is ready on the Rhine, but the New Empire is superior in infantry and artillery.",
            s.o("Ren'de savun || Defend on the Rhine", "Almanya Ren hattında savunma kurdu. || Germany set up a defence on the Rhine.", [["buff", DE, "def", 1.3, 10], ["troops", DE, 1]]),
            s.o("Önleyici saldırı yap || Strike pre-emptively", "Alman birlikleri Elzas'a önleyici saldırı yaptı. || German troops struck pre-emptively into Alsace.", [["buff", DE, "att", 1.15, 6], ["troops", DE, -4]])),
     ES: s.r("Madrid Napolyon çağının acı hatıralarını biliyor; ama İmparator sınırda. || Madrid knows the bitter memories of the Napoleonic age, but the Emperor is at the border.",
            s.o("Pireneler'i tahkim et || Fortify the Pyrenees", "İspanya Pireneler'de tahkimat kurdu. || Spain built fortifications in the Pyrenees.", [["troops", ES, 3], ["buff", ES, "def", 1.2, 10]]),
            s.o("Tarafsızlık ilan et || Declare neutrality", "Madrid tarafsızlık ilan etti. || Madrid declared neutrality.", [["stab", ES, 1], ["rel", ES, FR, 2]])),
     IT: s.r("Roma Alpler hattında tehdit altında; İmparator İtalya'yı 'özgürleştirmek' istiyor. || Rome is threatened along the Alps; the Emperor wants to 'liberate' Italy.",
            s.o("Alp geçitlerini kapat || Close the Alpine passes", "İtalya Alp geçitlerini tahkim etti. || Italy fortified the Alpine passes.", [["troops", IT, 2], ["buff", IT, "def", 1.2, 8]]),
            s.o("Müzakere et || Negotiate", "Roma Yeni İmparatorluk'la gizli görüşmeler yaptı. || Rome held secret talks with the New Empire.", [["rel", IT, FR, 3], ["stab", IT, -1]]))},
    icon="tank", scene="pre_assault")
s.m("koalisyon", 48, "Yeni Koalisyon || The New Coalition",
    "Britanya, Almanya ve Rusya Yeni İmparatorluk'a karşı yeni bir koalisyon kurma çabasında. Napolyon çağının yedinci koalisyonu gibi; ama bu kez modern silahlar var. || Britain, Germany and Russia are trying to form a new coalition against the New Empire. Like the seventh coalition of the Napoleonic age, but this time with modern weapons.",
    [["rel", UK, DE, 3], ["rel", UK, RU, 2], ["rel", DE, RU, 1]],
    {UK: s.r("Londra koalisyonun finansörü ve donanma gücü olabilir. Büyük bir kara taahhüdü ise riskli. || London can be the coalition's paymaster and naval power. A large land commitment is risky.",
            s.o("Koalisyona mali ve deniz desteği ver || Provide funds and naval support", "Londra koalisyona finans ve donanma desteği verdi. || London gave the coalition funding and naval support.", [["rel", UK, DE, 4], ["gold", UK, -1.0], ["buff", UK, "att", 1.05, 8]]),
            s.o("Sadece denizden abluka kur || A blockade at sea only", "Britanya Fransa'ya deniz ablukası kurdu. || Britain blockaded France at sea.", [["gold", FR, -1.0], ["stab", UK, 1]])),
     DE: s.r("Almanya koalisyonun kara gücü; ama ortak komuta konusunda görüş ayrılığı var. || Germany is the coalition's land power, but there is disagreement over joint command.",
            s.o("Ortak komutayı kabul et || Accept joint command", "Berlin ortak komutayı kabul etti. || Berlin accepted joint command.", [["rel", DE, UK, 4], ["rel", DE, RU, 3], ["buff", DE, "att", 1.1, 8]]),
            s.o("Ulusal komutada ısrar et || Insist on national command", "Almanya bağımsız komuta çizgisini korudu. || Germany kept its independent command line.", [["rel", DE, UK, -2], ["stab", DE, 1]])),
     FR: s.r("Cumhuriyet koalisyonla birlikte Yeni İmparatorluk'u geri püskürtebilir. || The Republic, together with the coalition, can push back the New Empire.",
            s.o("Koalisyona katıl || Join the coalition", "Fransız Cumhuriyeti koalisyonla ortak plan yaptı. || The French Republic coordinated plans with the coalition.", [["rel", FR, UK, 5], ["rel", FR, DE, 4], ["buff", FR, "def", 1.1, 8]]),
            s.o("Fransa'yı kendin kurtar || Save France yourself", "Cumhuriyet yabancı yardımı reddetti. || The Republic refused foreign aid.", [["stab", FR, 2], ["rel", FR, UK, -3]]))},
    icon="treaty", scene="peace")
s.save()

# ------------------------------------------------------------ siber
s = Scn("siber")
s.m("sebeke", 4, "Elektrik Şebekesi Vuruldu || A Power Grid Is Hit",
    "Büyük bir şehrin elektrik şebekesi gizemli bir siber saldırıyla çöktü. Hastaneler jeneratörle çalışıyor; kimse saldırıyı üstlenmedi, ama herkes birbirini suçluyor. || A major city's power grid collapsed in a mysterious cyberattack. Hospitals run on generators; nobody claimed the attack but everyone blames everyone else.",
    [["stab", US, -2], ["rel", US, CN, -3], ["rel", US, RU, -3]],
    {US: s.r("Atıf zor; yanlış suçlama krizi büyütür, geç karşılık zayıf görünür. || Attribution is hard; a wrong accusation inflates the crisis, a late response looks weak.",
            s.o("Siber karşı saldırı yap || Launch a cyber counterstrike", "Washington şüpheli ağlara karşı misilleme yaptı. || Washington retaliated against suspected networks.", [["rel", US, CN, -4], ["rel", US, RU, -4], ["stab", US, 1]]),
            s.o("Müttefiklerle ortak atıf yap || Attribute jointly with allies", "ABD müttefikleriyle ortak bir atıf açıklaması yaptı. || The US issued a joint attribution with allies.", [["rel", US, UK, 3], ["rel", US, DE, 3], ["rel", US, CN, -2]])),
     CN: s.r("Pekin suçlamaları reddediyor; ama kendi kritik şebekelerini de güçlendirmek zorunda. || Beijing denies the accusations but must harden its own critical grids.",
            s.o("Suçlamaları reddet, savunmayı artır || Deny and strengthen defences", "Çin suçlamaları reddedip siber savunmasını artırdı. || China denied the claims and boosted its cyber defences.", [["gold", CN, -0.5], ["stab", CN, 1]]),
            s.o("Ortak soruşturma öner || Offer a joint inquiry", "Pekin uluslararası ortak soruşturma önerdi. || Beijing offered a joint international inquiry.", [["rel", CN, US, 3], ["rel", CN, DE, 2]]), minor=True),
     RU: s.r("Moskova şebeke vuruşunu hem inkâr ediyor hem de caydırıcı bir mesaj olarak değerlendiriyor. || Moscow denies the grid strike while treating it as a deterrent message.",
            s.o("Belirsiz kal || Stay ambiguous", "Rusya olayı inkâr etti ama belirsizliği sürdürdü. || Russia denied it but kept the ambiguity.", [["rel", RU, US, -2], ["stab", RU, 1]]),
            s.o("Karşı atıf yap || Counter-accuse", "Moskova ABD ve müttefiklerini suçladı. || Moscow accused the US and its allies.", [["rel", RU, US, -4], ["rel", RU, UK, -2]]))},
    icon="warning", scene="crisis")
s.m("liman", 20, "Liman Otomasyonu Çöktü || Port Automation Collapses",
    "Dünyanın en büyük konteyner limanlarından birinde yazılım saldırısı konteyner takibini kilitledi; gemiler kuyruğa girdi. Küresel tedarik zinciri günlerce aksadı, fiyatlar fırladı. || A software attack at one of the world's biggest container ports locked cargo tracking; ships queued up. The global supply chain stalled for days and prices jumped.",
    [["gold", JP, -1.0], ["gold", DE, -1.0], ["gold", CN, -1.0], ["rel", US, CN, -2]],
    {DE: s.r("Alman sanayisi ithal parçalara bağımlı; liman krizi fabrikaları durdurabilir. || German industry depends on imported parts; the port crisis could stop factories.",
            s.o("Stratejik stoklara başvur || Tap strategic stockpiles", "Almanya stratejik parça stoklarını devreye soktu. || Germany released strategic parts stockpiles.", [["gold", DE, -0.5], ["stab", DE, 1]]),
            s.o("Alternatif limanlara yönel || Reroute to alternative ports", "Berlin gemileri alternatif limanlara yönlendirdi. || Berlin rerouted ships to alternative ports.", [["gold", DE, -1.0], ["rel", DE, NL, 3]])),
     JP: s.r("Japonya ihracata bağımlı; liman gecikmesi doğrudan büyümeyi vuruyor. || Japan depends on exports; port delays hit growth directly.",
            s.o("Ticaret ortaklarıyla ortak siber savunma || Joint cyber defence with trade partners", "Tokyo ticaret ortaklarıyla ortak savunma planı kurdu. || Tokyo formed a joint defence plan with trading partners.", [["rel", JP, US, 4], ["gold", JP, -0.5]]),
            s.o("Gemi rotalarını çeşitlendir || Diversify shipping routes", "Japonya gemi rotalarını çeşitlendirdi. || Japan diversified its shipping routes.", [["gold", JP, -0.5], ["stab", JP, 1]])),
     CN: s.r("Çin limanları dünya ticaretinin kalbi; saldırıdan zarar görenlerden biri de sensin. || Chinese ports are the heart of world trade; you are among the victims too.",
            s.o("Limanları yeniden başlat ve ihracatı koru || Restart ports and protect exports", "Çin limanları hızla yeniden başlattı. || China restarted its ports quickly.", [["gold", CN, 0.5], ["stab", CN, 1]]),
            s.o("Rakip liman ağlarına siber baskı yap || Retaliate against rival port networks", "Pekin rakip liman ağlarına baskı yaptı. || Beijing pressed rival port networks.", [["rel", CN, US, -3], ["rel", CN, JP, -2]]))},
    icon="ship", scene="trade", major=False)
s.m("borsa", 42, "Borsa Çöküşü ve Yapay Zekâ Manipülasyonu || A Market Crash and AI Manipulation",
    "Sahte haber ve yapay zekâ üretimi dezenformasyon dalgası dünya borsalarını yarım gün içinde yüzde 12 düşürdü. Hükûmetler piyasaları durdurup ortak bir 'siber barış' önerisi arıyor. || A wave of fake news and AI-generated disinformation knocked world stock markets down 12% in half a day. Governments halt trading and look for a joint 'cyber peace' proposal.",
    [["gold", US, -1.0], ["gold", CN, -1.0], ["gold", DE, -1.0], ["stab", US, -2]],
    {US: s.r("Başkan piyasaya güven vermek zorunda; ama sorumluları hâlâ kesin bilmiyorsun. || The President must reassure markets, yet you still do not know who is responsible.",
            s.o("Siber barış zirvesi çağır || Call a cyber peace summit", "ABD büyük güçleri siber barış zirvesine çağırdı. || The US convened the great powers for a cyber peace summit.", [["rel", US, CN, 3], ["rel", US, RU, 2], ["stab", US, 1]]),
            s.o("Piyasayı destekle ve yaptırım uygula || Support markets and sanction", "Washington piyasaya likidite sağlayıp yaptırımları artırdı. || Washington injected liquidity and stepped up sanctions.", [["gold", US, -0.5], ["rel", US, CN, -3], ["rel", US, RU, -3]])),
     CN: s.r("Pekin kendi piyasa istikrarını korumalı; ortak anlaşmaya mı gidecek? || Beijing must protect its own market stability; will it go for a joint agreement?",
            s.o("Siber barış önerisini destekle || Support the cyber peace proposal", "Çin siber barış önerisine destek verdi. || China backed the cyber peace proposal.", [["rel", CN, US, 4], ["stab", CN, 1]]),
            s.o("Kendi finans ağını kapat || Wall off your own financial network", "Çin finans ağını dış dünyadan yalıttı. || China walled off its financial network from the world.", [["rel", CN, US, -2], ["stab", CN, 1]])),
     RU: s.r("Moskova yaptırımlar altında; piyasa çöküşü Rusya'ya göre bir fırsat da olabilir. || Moscow lives under sanctions; a market crash could also look like an opportunity.",
            s.o("Alternatif ödeme sistemi kur || Build an alternative payment system", "Rusya alternatif ödeme ağını hızlandırdı. || Russia accelerated an alternative payment network.", [["rel", RU, CN, 4], ["gold", RU, 0.5]]),
            s.o("Zirveye katıl || Join the summit", "Moskova siber barış zirvesine katıldı. || Moscow joined the cyber peace summit.", [["rel", RU, US, 3], ["stab", RU, 1]]))},
    icon="trade", scene="trade")
s.save()
print("tamam")

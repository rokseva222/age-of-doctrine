#!/usr/bin/env python3
"""Dış senaryolar için olay kartları: arctic, essequibo, korea, kuraklik, nile, redsea, sahel, scs -> data/scn_moments/<id>.json.
Gerçek dünya senaryoları 2024-2026 gelişmelerinden esinlenir; kurgusal olanlar (kuraklik, sahel) açıkça kurgusaldır."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scn_kit import Scn

US = "United States of America"; RU = "Russia"; CN = "China"; TW = "Taiwan"; JP = "Japan"; KR = "South Korea"; KP = "North Korea"
IR = "Iran"; IL = "Israel"; SA = "Saudi Arabia"; IN = "India"; PK = "Pakistan"; TR = "Turkey"; EG = "Egypt"; ET = "Ethiopia"; SD = "Sudan"; ER = "Eritrea"
YE = "Yemen"; CA = "Canada"; NO = "Norway"; DK = "Denmark"; GY = "Guyana"; VE = "Venezuela"; BR = "Brazil"; PH = "Philippines"; VN = "Vietnam"; MY = "Malaysia"
ML = "Mali"; NE = "Niger"; DZ = "Algeria"; NG = "Nigeria"; FR = "France"; BF = "Burkina Faso"; IQ = "Iraq"

# ---------------------------------------------------------------- arctic
s = Scn("arctic")
s.m("grenland", 8, "Grönland Sorusu || The Greenland Question",
    "Washington Grönland'ın 'ulusal güvenlik için gerekli' olduğunu söylüyor; Danimarka ve Nuuk satılık olmadığını yineliyor. Kutup ticaret yolları, nadir toprak elementleri ve erken uyarı radarları adayı stratejik bir ödül yapıyor. || Washington says Greenland is 'necessary for national security'; Copenhagen and Nuuk repeat that it is not for sale. Polar trade routes, rare earths and early-warning radars make the island a strategic prize.",
    [["rel", US, DK, -4], ["stab", DK, -1]],
    {DK: s.r("Kopenhag müttefiklerin baskısı altında; Avrupa size destek verirken NATO içi çatlak büyüyor. || Copenhagen is under pressure from an ally; Europe backs you while a rift grows inside NATO.",
            s.o("Avrupa desteğini topla || Rally European support", "Danimarka AB ve Kuzey ülkelerinden destek bildirisi aldı. || Denmark gathered a statement of support from the EU and the Nordics.", [["rel", DK, NO, 4], ["rel", DK, US, -3], ["stab", DK, 2]]),
            s.o("Daha fazla ABD üssü ve yatırım öner || Offer more US basing and investment", "Danimarka ABD'ye Grönland'da genişletilmiş savunma anlaşması önerdi. || Denmark offered the US an expanded defence deal in Greenland.", [["rel", DK, US, 4], ["stab", DK, -1]])),
     US: s.r("Başkan Grönland için 'her yolu denemeyi' istiyor; ama NATO müttefiki bir ülkeyi zorlamak ittifakı sarsar. || The President wants to 'try every route' for Greenland, but pressuring a NATO ally would shake the alliance.",
            s.o("Ekonomik ve diplomatik baskı || Economic and diplomatic pressure", "ABD Danimarka'ya gümrük ve yatırım teklifleriyle baskı kurdu. || The US pressed Denmark with tariffs and investment offers.", [["rel", US, DK, -5], ["rel", US, NO, -1]]),
            s.o("Üs anlaşmasıyla yetin || Settle for a basing deal", "Washington Pituffik'teki varlığını genişleten bir anlaşmaya razı oldu. || Washington agreed to a deal widening its Pituffik presence.", [["rel", US, DK, 4], ["stab", US, 1]])),
     CA: s.r("Ottawa Kuzey Kutbu egemenliğini güçlendirmek için buzkıranlar ve denizaltılar planlıyor. || Ottawa plans icebreakers and submarines to assert Arctic sovereignty.",
            s.o("Kuzey savunma yatırımı || Invest in northern defence", "Kanada Kuzey Kutbu'na radar, buzkıran ve denizaltı programı duyurdu. || Canada announced radar, icebreaker and submarine programmes for the Arctic.", [["gold", CA, -0.5], ["troops", CA, 3], ["rel", CA, US, -1]]),
            s.o("ABD ile ortak savunma (NORAD) || Joint defence with the US (NORAD)", "Kanada NORAD modernizasyonunu hızlandırdı. || Canada sped up NORAD modernisation.", [["rel", CA, US, 3]]), minor=True)},
    icon="treaty", scene="crisis")
s.m("kuzeyyol", 32, "Kuzey Deniz Yolu Açılıyor || The Northern Sea Route Opens",
    "Yaz buzulları rekor düzeyde çekildi; Çin yük gemileri Rus buzkıranları eşliğinde Kuzey Deniz Yolu'ndan Avrupa'ya geçti. Süveyş'e alternatif yeni bir ticaret kuşağı doğuyor; Norveç ve NATO Kutup radarlarını izliyor. || Summer ice receded to record levels; Chinese freighters crossed the Northern Sea Route to Europe under Russian icebreaker escort. A new trade belt rivals Suez; Norway and NATO watch the polar radars.",
    [["gold", RU, 1.0], ["rel", RU, CN, 3], ["rel", NO, RU, -2]],
    {RU: s.r("Kutup rotası Rusya'ya gelir ve nüfuz getiriyor; ama yaptırımlar teknoloji erişimini kısıtlıyor. || The polar route brings income and leverage, but sanctions limit access to technology.",
            s.o("Rota ücreti ve Kuzey Filosu'nu güçlendir || Charge transit fees and boost the Northern Fleet", "Rusya Kuzey Deniz Yolu'nda geçiş ücreti ve deniz devriyesi artırdı. || Russia raised transit fees and naval patrols on the route.", [["gold", RU, 1.5], ["rel", RU, NO, -3], ["rel", RU, US, -2]]),
            s.o("Çin ile ortak yatırım || Joint investment with China", "Moskova ve Pekin kutup LNG ve liman projelerine ortak oldu. || Moscow and Beijing partnered on polar LNG and port projects.", [["gold", RU, 1.0], ["rel", RU, CN, 4]])),
     NO: s.r("Svalbard ve Barents Denizi'ndeki ağırlığınız büyük; Rusya ile komşuluğu sakin tutmak istiyorsunuz. || You carry weight around Svalbard and the Barents Sea and want a calm border with Russia.",
            s.o("NATO ile Kuzey devriyesi || NATO patrols in the north", "Norveç NATO'nun Kuzey devriye ve tatbikatlarını artırdı. || Norway increased NATO patrols and drills in the north.", [["rel", NO, US, 3], ["rel", NO, RU, -4], ["troops", NO, 3]]),
            s.o("Barents işbirliğini koru || Preserve Barents cooperation", "Oslo balıkçılık ve arama-kurtarma işbirliğini sürdürdü. || Oslo kept fisheries and search-and-rescue cooperation.", [["rel", NO, RU, 3], ["stab", NO, 1]]))},
    icon="ship", scene="trade", major=False)
s.m("denizalti", 70, "Kutup Altı Denizaltı Karşılaşması || A Submarine Encounter Under the Ice",
    "Buzun altında bir Rus ve bir NATO denizaltısı tehlikeli şekilde yakın geçti; iki taraf da sonarla izlendiğini söylüyor. Kutup, silahsız bir bölge değil: kıta sahanlığı iddiaları da masada. || A Russian and a NATO submarine passed dangerously close under the ice; both say they were being tracked by sonar. The pole is no disarmed zone: continental-shelf claims are on the table as well.",
    [["rel", RU, US, -3], ["stab", RU, -1]],
    {RU: s.r("Kutup denizaltı filonuz caydırıcılığınızın temeli; bir kaza kriz çıkarabilir. || Your polar submarine fleet is the core of deterrence; an accident could spark a crisis.",
            s.o("Sessizce geri çekil || Quietly withdraw", "Moskova olayı büyütmedi, devriyeleri azalttı. || Moscow did not inflate the incident and reduced patrols.", [["rel", RU, US, 1]]),
            s.o("Kıta sahanlığı iddiasını sertleştir || Harden the continental-shelf claim", "Rusya BM'ye genişletilmiş kıta sahanlığı iddiası sundu. || Russia filed an extended continental-shelf claim at the UN.", [["rel", RU, NO, -3], ["rel", RU, CA, -3], ["rel", RU, DK, -3]])),
     US: s.r("Kutup caydırıcılığı için buzkıran filosu ve denizaltı gerekli; bütçeyi nereye ayıracaksın? || Polar deterrence needs icebreakers and submarines; where will you spend?",
            s.o("Buzkıran ve denizaltı yatırımı || Invest in icebreakers and submarines", "ABD Kutup Güvenlik Kesicisi programını hızlandırdı. || The US sped up its Polar Security Cutter programme.", [["gold", US, -0.5], ["rel", US, RU, -2], ["rel", US, CA, 2]]),
            s.o("Diplomasi ve Arktik Konseyi || Diplomacy and the Arctic Council", "ABD Arktik Konseyi'nde kriz yönetimi kanalı önerdi. || The US proposed a crisis channel in the Arctic Council.", [["rel", US, RU, 2]]), minor=True)},
    icon="submarine", scene="naval")
s.save()

# ---------------------------------------------------------------- essequibo
s = Scn("essequibo")
s.m("secim", 8, "Esequibo'da 'Seçim' ve Haritalar || 'Elections' and Maps over Essequibo",
    "Venezuela, tartışmalı Esequibo bölgesi için valilik ve meclis seçimi ilan etti; Guyana buna 'yasa dışı' dedi ve Uluslararası Adalet Divanı'na gitti. Büyük açık deniz petrol sahaları Guyana'yı zengin, Karakas'ı ise sabırsız yapıyor. || Venezuela called a governor and assembly election for the disputed Essequibo; Guyana called it unlawful and went to the International Court of Justice. Big offshore oil fields make Guyana rich and Caracas impatient.",
    [["rel", VE, GY, -4], ["rel", GY, US, 2]],
    {GY: s.r("UAD size dayanak veriyor; ama ordunuz küçük ve sınır ormanları geniş. Petrol geliri savunmaya yatırım fırsatı. || The ICJ is your backstop, but your army is small and the border jungle is wide. Oil revenue is a chance to invest in defence.",
            s.o("ABD ve İngiliz Milletler Topluluğu desteği iste || Seek US and Commonwealth backing", "Guyana ABD ile ortak devriye ve eğitim anlaşması imzaladı. || Guyana signed a joint patrol and training deal with the US.", [["rel", GY, US, 5], ["rel", GY, VE, -3], ["troops", GY, 5]]),
            s.o("Brezilya ile arabuluculuk || Mediation with Brazil", "Georgetown Brezilya ve Karayip topluluğu aracılığıyla görüşme istedi. || Georgetown sought talks through Brazil and the Caribbean community.", [["rel", GY, BR, 4], ["rel", GY, VE, 1]])),
     VE: s.r("Karakas iç ekonomik sıkıntıyı dış davayla örtmek istiyor; ama ABD donanması Karayipler'de devriyede. || Caracas wants to mask domestic hardship with a foreign cause, yet a US naval force patrols the Caribbean.",
            s.o("Esequibo'yu eyalet ilan et || Declare Essequibo a state", "Venezuela Esequibo'yu 'Guayana Esekiba eyaleti' ilan etti. || Venezuela declared Essequibo the state of 'Guayana Esequiba'.", [["rel", VE, GY, -6], ["rel", VE, US, -4], ["stab", VE, 2]]),
            s.o("Diplomatik yolu koru || Stay on the diplomatic track", "Karakas Brezilya ve BM aracılığıyla görüşmeye razı oldu. || Caracas agreed to talks via Brazil and the UN.", [["rel", VE, GY, 3], ["rel", VE, BR, 3], ["stab", VE, -1]])),
     BR: s.r("Brezilya'nın kuzey sınırı ve Amazon yolu tehlikede; arabuluculuk rolünü üstlenebilirsiniz. || Brazil's northern border and Amazon routes are at stake; you can take the mediator's role.",
            s.o("Arabuluculuk teklif et || Offer mediation", "Brasilia iki tarafı ortak masaya çağırdı. || Brasília invited both sides to a joint table.", [["rel", BR, GY, 3], ["rel", BR, VE, 3]]),
            s.o("Sınıra birlik yığ || Mass units at the border", "Brezilya Roraima'daki birliklerini artırdı. || Brazil reinforced its units in Roraima.", [["troops", BR, 2], ["rel", BR, VE, -2]]), minor=True)},
    icon="flag", scene="border")
s.m("petrol", 30, "Açık Deniz Petrolü ve Bir Olay || Offshore Oil and an Incident",
    "Guyana'nın Stabroek sahasındaki üretim rekor kırarken Venezuela devriye botları sulara girdi; bir petrol platformu çevresinde tehlikeli bir yaklaşma yaşandı. İki taraf da 'savunma' diyor. || As Guyana's Stabroek output hits records, Venezuelan patrol boats entered the waters; a dangerous approach occurred near an oil platform. Both sides say 'defensive'.",
    [["gold", GY, 1.0], ["rel", VE, GY, -3]],
    {GY: s.r("Platformlarınız ekonominizin kalbi; bir kaza sizi bir anda savaşa çekebilir. || Your platforms are the heart of the economy; one accident could drag you into war.",
            s.o("Sahil güvenliği ve hava savunmasını güçlendir || Reinforce coast guard and air defence", "Guyana platformlarını korumak için sahil güvenliğini genişletti. || Guyana expanded its coast guard to protect the platforms.", [["troops", GY, 4], ["gold", GY, -0.5], ["rel", GY, VE, -2]]),
            s.o("Şikâyet et, tırmandırma || Complain without escalating", "Georgetown olayı BM'ye bildirdi. || Georgetown reported the incident to the UN.", [["rel", GY, VE, 0], ["rel", GY, US, 2]])),
     VE: s.r("Petrol sahalarına karşı tavır sert ama ABD'nin tepkisi belirsiz. || You are hard on the oil fields, but the US response is unclear.",
            s.o("Baskıyı sürdür || Keep the pressure on", "Venezuela deniz devriyesini artırdı. || Venezuela increased naval patrols.", [["rel", VE, GY, -4], ["rel", VE, US, -3]]),
            s.o("Gerilimi düşür || Lower the temperature", "Karakas devriyeleri geri çekti. || Caracas pulled back its patrols.", [["rel", VE, GY, 3], ["stab", VE, -1]]))},
    icon="ship", scene="naval", major=False)
s.m("sinir2", 64, "Ormanda Sınır Çatışması || A Jungle Border Clash",
    "Cuyuní Nehri çevresinde silahlı çete saldırısı ve karşı ateş: bir sınır karakolu vuruldu. Venezuela 'Guyana ordusu provokasyon yaptı' diyor. || Armed gangs and return fire around the Cuyuní River: a border post was hit. Venezuela claims the Guyanese army provoked it.",
    [["stab", GY, -1], ["rel", VE, GY, -5]],
    {GY: s.r("Küçük ama iyi eğitilmiş birlikleriniz var; ABD'nin desteği hayati. || Your small units are well trained; US backing is vital.",
            s.o("Sınırda direniş, ABD'yi çağır || Hold the line and call on the US", "Guyana birliklerini Cuyuní hattına kaydırıp ABD'den yardım istedi. || Guyana moved troops to the Cuyuní line and asked the US for help.", [["buff", GY, "def", 1.2, 8], ["rel", GY, US, 4]]),
            s.o("BM Güvenlik Konseyi'ne git || Go to the UN Security Council", "Georgetown olayı BMGK'ya taşıdı. || Georgetown took the incident to the Security Council.", [["rel", GY, VE, -1], ["stab", GY, 1]])),
     VE: s.r("Çatışma iç siyasi malzeme; ama savaş ABD'yi doğrudan sahaya çekebilir. || The clash is domestic political material, but war could pull the US in directly.",
            s.o("Sınırı aş || Cross the border", "Venezuela sınırı aşıp Esequibo'ya girdi. || Venezuela crossed into Essequibo.", [["war", VE, GY, "solo"], ["buff", VE, "att", 1.1, 6], ["rel", VE, US, -6]]),
            s.o("Operasyonu durdur || Stand down", "Venezuela sınır birliklerini çekti. || Venezuela pulled back its border units.", [["rel", VE, GY, 2], ["stab", VE, -1]]))},
    icon="border_clash", scene="border")
s.save()

# ---------------------------------------------------------------- korea (yarımada senaryosu)
s = Scn("korea")
s.m("pazarlik", 7, "Kim–Trump Zirvesi Söylentisi || Kim–Trump Summit Rumours",
    "Washington Kim ile bir zirvenin kapısını açık tuttuğunu söylüyor; Pyongyang ise ancak 'nükleer statüsünün tanınması' halinde konuşacağını belirtiyor. Seul, kendisinin atlanmasından endişeli. || Washington says it keeps the door open to a summit with Kim; Pyongyang says it will talk only if its nuclear status is recognised. Seoul fears being bypassed.",
    [["rel", KP, US, 1]],
    {KP: s.r("Silahlı Rus ortaklığınız var, ABD ile masaya oturmak size ekonomik rahatlama getirebilir. || With a Russian partnership in hand, sitting with the US could bring economic relief.",
            s.o("Zirve için şart koş: nükleer tanınma || Demand nuclear recognition as the price", "Pyongyang zirveyi nükleer statünün tanınmasına bağladı. || Pyongyang tied a summit to recognition of its nuclear status.", [["rel", KP, US, -2], ["stab", KP, 1]]),
            s.o("Koşulsuz görüşmeye razı ol || Agree to talks without conditions", "Kuzey Kore ABD ile üst düzey görüşmeye hazır olduğunu bildirdi. || North Korea said it was ready for top-level talks with the US.", [["rel", KP, US, 5], ["gold", KP, 1.0]])),
     KR: s.r("Güney Kore 'barış ve caydırıcılık' dengesinde; ABD ile gümrük ve güvenlik pazarlıkları sürüyor. || South Korea balances 'peace and deterrence'; talks with the US on tariffs and security continue.",
            s.o("Seul'ü masaya sok || Insist on a seat at the table", "Seul müzakerede 'Kore'siz Kore kararı olmaz' dedi. || Seoul said there would be 'no decision about Korea without Korea'.", [["rel", KR, US, 2], ["rel", KR, KP, 1]]),
            s.o("Müttefik koordinasyonu || Coordinate with allies", "Seul, Tokyo ve Washington ortak bir pozisyon yayımladı. || Seoul, Tokyo and Washington issued a joint position.", [["rel", KR, US, 3], ["rel", KR, JP, 3], ["rel", KR, KP, -2]])),
     CN: s.r("Pekin Yarımada'da denge istiyor: kimse tek başına belirleyici olmamalı. || Beijing wants balance on the peninsula: nobody should decide alone.",
            s.o("Altılı görüşme öner || Propose multilateral talks", "Çin çok taraflı müzakere önerdi. || China proposed multilateral talks.", [["rel", CN, US, 1], ["rel", CN, KR, 2], ["rel", CN, KP, 1]]),
            s.o("Pyongyang'ı destekle || Back Pyongyang", "Çin Kuzey Kore'ye yakıt ve gıda yardımı gönderdi. || China sent fuel and food aid to North Korea.", [["rel", CN, KP, 4], ["rel", CN, KR, -2]]), minor=True)},
    icon="treaty", scene="peace")
s.m("denizalti", 36, "Nükleer Denizaltı Tartışması || The Nuclear Submarine Debate",
    "Güney Kore, ABD'nin onayıyla nükleer yakıtlı denizaltı yapmak istiyor; Kuzey Kore ve Çin tepkili, Japonya ise endişeli. Bölgede deniz silahlanması hızlanıyor. || South Korea wants to build nuclear-powered submarines with US approval; North Korea and China object and Japan is uneasy. A naval arms build-up is quickening in the region.",
    [["rel", KP, KR, -3], ["rel", CN, KR, -3]],
    {KR: s.r("Nükleer denizaltı caydırıcılığı artırır, ama komşuların tepkisini ve silahsızlanma baskısını da getirir. || Nuclear subs raise deterrence but bring neighbours' reactions and non-proliferation pressure.",
            s.o("Denizaltı programını başlat || Launch the submarine programme", "Seul nükleer yakıtlı denizaltı programını başlattı. || Seoul launched its nuclear-powered submarine programme.", [["gold", KR, -1.0], ["rel", KR, US, 3], ["rel", KR, CN, -4], ["rel", KR, KP, -3]]),
            s.o("Konvansiyonel güçle yetin || Stay with conventional forces", "Güney Kore konvansiyonel denizaltı ve füze savunmasına yöneldi. || South Korea chose conventional subs and missile defence.", [["rel", KR, CN, 1], ["stab", KR, 1]])),
     KP: s.r("Kuzey Kore 'karşı önlem' diyor: yeni füze ve denizaltı gövdesi gösterisi planlıyor. || North Korea says 'countermeasures': it plans to show new missiles and a submarine hull.",
            s.o("Askerî geçit töreni ve test || Parade and test", "Kuzey Kore yeni füzelerini geçit törenine çıkardı. || North Korea paraded new missiles.", [["rel", KP, US, -3], ["rel", KP, KR, -3], ["buff", KP, "att", 1.05, 6]]),
            s.o("Sessiz kal, Rusya'dan teknoloji al || Stay quiet and take Russian technology", "Pyongyang Rus teknolojisi karşılığı yeni anlaşmalar yaptı. || Pyongyang struck new deals in exchange for Russian technology.", [["gold", KP, 1.0], ["rel", KP, RU, 3]])),
     JP: s.r("Tokyo komşusunun nükleer denizaltısından rahatsız ama ittifakı bozmak istemiyor. || Tokyo is uneasy about its neighbour's nuclear sub but does not want to harm the alliance.",
            s.o("Üçlü savunma işbirliği || Trilateral defence cooperation", "Japonya Güney Kore ve ABD ile deniz istihbaratı paylaşımını artırdı. || Japan increased naval intelligence sharing with South Korea and the US.", [["rel", JP, KR, 3], ["rel", JP, US, 2]]),
            s.o("Kendi deniz bütçesini artır || Raise its own naval budget", "Tokyo deniz savunma bütçesini artırdı. || Tokyo raised its naval defence budget.", [["gold", JP, -0.5], ["troops", JP, 2]]), minor=True)},
    icon="submarine", scene="naval", major=False)
s.m("cephe", 80, "Sınırda Ateş Değişimi || An Exchange of Fire at the Border",
    "Batı Denizi'ndeki Kuzey Sınır Hattı'nda iki tarafın donanması birbirine ateş açtı; olay kazaen mi başladı, kimse bilmiyor. Hotline hâlâ cevap vermiyor. || The two navies exchanged fire along the Northern Limit Line in the West Sea; nobody knows whether it began by accident. The hotline is still unanswered.",
    [["stab", KP, -1], ["stab", KR, -1], ["rel", KP, KR, -5]],
    {KR: s.r("Orantılı misilleme caydırıcılık; ama tırmanma tüm yarımadayı yakar. || Proportional retaliation is deterrence, but escalation could burn the whole peninsula.",
            s.o("Sınırlı karşılık ve diplomatik kanal || Limited response and a diplomatic channel", "Seul sınırlı karşılık verip ABD ve Çin üzerinden mesaj gönderdi. || Seoul responded in limited fashion and sent messages via the US and China.", [["rel", KR, KP, -2], ["stab", KR, 1], ["rel", KR, CN, 1]]),
            s.o("Tam misilleme || Full retaliation", "Güney Kore Kuzey Kore kıyı bataryalarını vurdu. || South Korea struck North Korean coastal batteries.", [["war", KR, KP, "solo"], ["buff", KR, "att", 1.1, 6], ["rel", KR, KP, -8]])),
     KP: s.r("Olay sizin lehinize bir koz ya da kontrol dışı bir tırmanma olabilir. || The incident can be leverage or an escalation out of control.",
            s.o("Sınırı tırmandır || Escalate on the line", "Kuzey Kore kıyı topçusuyla ateş açtı. || North Korea opened fire with coastal artillery.", [["war", KP, KR, "solo"], ["buff", KP, "att", 1.1, 6], ["rel", KP, KR, -8]]),
            s.o("Olayı kapat || Close the incident", "Pyongyang hotline'ı açıp olayı 'kaza' diye kapattı. || Pyongyang opened the hotline and closed the incident as an accident.", [["rel", KP, KR, 2], ["stab", KP, 1]]))},
    icon="ship", scene="naval")
s.save()

# ---------------------------------------------------------------- nile
s = Scn("nile")
s.m("acilis", 6, "Rönesans Barajı Resmen Açıldı || The Renaissance Dam Is Inaugurated",
    "Etiyopya, Büyük Etiyopya Rönesans Barajı'nın açılışını yaptı: 5.150 MW ile Afrika'nın en büyük hidroelektrik santrali. Mısır ve Sudan 'tek taraflı' diyerek tepki gösterdi; Mavi Nil'de ani su salınımı Sudan'da sel yarattı. || Ethiopia inaugurated the Grand Ethiopian Renaissance Dam: at 5,150 MW it is Africa's largest hydropower plant. Egypt and Sudan reacted against the 'unilateral' step; a sudden release on the Blue Nile caused flooding in Sudan.",
    [["rel", EG, ET, -5], ["rel", SD, ET, -3], ["gold", ET, 1.0]],
    {ET: s.r("Baraj bir ulusal zafer ve gelir kaynağı; ama Mısır'ın yardımı olmadan Nil'de barış olmaz. || The dam is a national triumph and a source of income, but there is no Nile peace without Egypt.",
            s.o("Elektrik satışı ve ortak işletme öner || Offer power sales and joint operation", "Addis Ababa komşulara elektrik satışı ve ortak işletme önerdi. || Addis Ababa offered power sales and joint operation to neighbours.", [["rel", ET, EG, 4], ["rel", ET, SD, 4], ["gold", ET, 1.0]]),
            s.o("Su kontrolünü tek elde tut || Keep control of the water", "Etiyopya baraj işletmesini tek taraflı sürdürdü. || Ethiopia kept running the dam unilaterally.", [["rel", ET, EG, -5], ["stab", ET, 2]])),
     EG: s.r("Su 'hayat meselesi'; ama savaş çok maliyetli ve Etiyopya uzak. Diplomasi, hukuk ve baskı yolları var. || Water is 'existential', but war is very costly and Ethiopia is far away. Diplomacy, law and pressure are the options.",
            s.o("BM Güvenlik Konseyi ve hukuki yol || Security Council and legal track", "Kahire meseleyi BMGK'ya taşıdı. || Cairo took the issue to the Security Council.", [["rel", EG, ET, -2], ["rel", EG, US, 2]]),
            s.o("Eritre ve Somali ile ittifak ara || Build a bloc with Eritrea and Somalia", "Kahire Eritre ile savunma ve istihbarat anlaşması imzaladı. || Cairo signed a defence and intelligence deal with Eritrea.", [["rel", EG, ER, 5], ["rel", EG, ET, -5], ["ally", EG, ER]])),
     SD: s.r("İç savaş ve selin ortasındaki Sudan, her iki tarafa da muhtaç. || Sudan, amid civil war and floods, needs both sides.",
            s.o("Mısır'a yakın dur || Lean toward Egypt", "Hartum Kahire ile ortak su açıklaması yaptı. || Khartoum issued a joint water statement with Cairo.", [["rel", SD, EG, 4], ["rel", SD, ET, -3]]),
            s.o("Etiyopya'dan elektrik al || Buy electricity from Ethiopia", "Sudan Etiyopya'dan elektrik ithal etmeyi kabul etti. || Sudan agreed to import electricity from Ethiopia.", [["rel", SD, ET, 4], ["gold", SD, 0.5]]), minor=True)},
    icon="dam", scene="crisis")
s.m("kuraklik", 34, "Kuraklık Yılı || A Year of Drought",
    "Muson yağmurları düşük gelince Nil'in debisi azaldı; Mısır'da buğday ve pirinç ekimi su sınırına dayandı. Baraj gölünün doldurulma takvimi yeniden tartışma konusu. || Low monsoon rains cut the Nile's flow; Egypt's wheat and rice planting hit the water limit. The filling schedule of the reservoir is again a point of dispute.",
    [["stab", EG, -2], ["gold", EG, -0.5]],
    {EG: s.r("Su yetersizliği ekmek fiyatına ve sokağa yansıyor. || The water shortage shows up in bread prices and on the street.",
            s.o("Su tasarrufu ve tuzdan arındırma || Water saving and desalination", "Kahire tuzdan arındırma ve damla sulama yatırımını artırdı. || Cairo expanded desalination and drip irrigation.", [["gold", EG, -1.0], ["stab", EG, 2]]),
            s.o("Etiyopya'ya sıkı baskı || Press Ethiopia hard", "Mısır, ABD ve Körfez üzerinden baraj işletmesi için baskı yaptı. || Egypt pressed over the dam's operation via the US and the Gulf.", [["rel", EG, ET, -4], ["rel", EG, SA, 2]])),
     ET: s.r("Siz de kuraklıktan etkileniyorsunuz; ortak bir su yönetimi sizi küresel saygıya taşıyabilir. || You are hit by drought too; joint water management could bring you global respect.",
            s.o("Ortak bir veri paylaşımı kabul et || Accept joint data sharing", "Etiyopya Mısır ve Sudan'la su verisi paylaşımına razı oldu. || Ethiopia agreed to share water data with Egypt and Sudan.", [["rel", ET, EG, 4], ["rel", ET, SD, 3], ["stab", ET, -1]]),
            s.o("Baraj gölünü doldurmaya devam et || Keep filling the reservoir", "Addis Ababa gölü doldurma programını sürdürdü. || Addis Ababa kept to its filling programme.", [["rel", ET, EG, -4], ["gold", ET, 1.0]]))},
    icon="drought", scene="crisis", major=False)
s.m("sinirdaki", 66, "Hartum'da Vekâlet Savaşı || Proxy War in Khartoum",
    "Sudan'daki hizipler Mısır ve Etiyopya'nın desteğini alıyor; Eritre sınırında asker yığınağı var. Nil artık yalnız bir su sorunu değil, bölgesel bir güç mücadelesi. || Factions in Sudan receive Egyptian and Ethiopian backing; troops mass on the Eritrean border. The Nile is no longer just a water issue but a regional power struggle.",
    [["rel", EG, ET, -3], ["stab", SD, -2]],
    {EG: s.r("Sudan'ın düşmesi sizin güney kapınızı açabilir. || Sudan's collapse could open your southern door.",
            s.o("Sudan ordusuna destek || Back the Sudanese army", "Kahire Sudan ordusuna silah ve istihbarat sağladı. || Cairo supplied arms and intelligence to the Sudanese army.", [["rel", EG, SD, 5], ["rel", EG, ET, -3], ["stab", SD, 1]]),
            s.o("Arabuluculuk ve ateşkes || Mediation and ceasefire", "Mısır Cidde formülünde yeni bir ateşkes çağrısı yaptı. || Egypt called for a new ceasefire under the Jeddah format.", [["rel", EG, SD, 2], ["rel", EG, SA, 2]])),
     ET: s.r("Sınırdaki gerilim iç siyasetteki Tigray ve Amhara sorunlarıyla birleşiyor. || Border tension combines with Tigray and Amhara problems at home.",
            s.o("Sınırı sağlamlaştır || Secure the border", "Addis Ababa sınır birliklerini güçlendirdi. || Addis Ababa strengthened its border units.", [["troops", ET, 3], ["rel", ET, ER, -3]]),
            s.o("Eritre ile diyalog || Dialogue with Eritrea", "Etiyopya Eritre ile liman ve sınır görüşmesi başlattı. || Ethiopia opened port and border talks with Eritrea.", [["rel", ET, ER, 4], ["stab", ET, 1]]))},
    icon="border_clash", scene="border")
s.save()

# ---------------------------------------------------------------- redsea
s = Scn("redsea")
s.m("husiler", 5, "Husilerin Gemi Saldırıları || Houthi Attacks on Shipping",
    "Yemen'deki Husiler Kızıldeniz'den geçen ticaret gemilerine füze ve dron saldırıları düzenliyor; Süveyş geçişleri sert düştü, armatörler Ümit Burnu'na yöneliyor. Gazze ateşkesi gerilimi azalttıysa da saldırı tehdidi bitmedi. || The Houthis in Yemen launch missile and drone attacks on merchant ships in the Red Sea; Suez transits fell sharply and shipowners turn toward the Cape of Good Hope. The Gaza ceasefire eased tension, but the attack threat has not ended.",
    [["gold", EG, -1.0], ["rel", YE, US, -3], ["rel", YE, IL, -4]],
    {EG: s.r("Süveyş gelirleri, ekonominizin can damarı, çöktü. Hem Husilerden hem Batı'dan uzak durmanız gerek. || Suez revenue, a lifeline for your economy, has collapsed. You must keep your distance from both the Houthis and the West.",
            s.o("Denizcilik güvenliği koalisyonu kur || Form a maritime security coalition", "Kahire Körfez ve Avrupa ile Kızıldeniz devriye koalisyonu kurdu. || Cairo built a Red Sea patrol coalition with Gulf states and Europe.", [["rel", EG, SA, 4], ["rel", EG, US, 3], ["gold", EG, 0.5]]),
            s.o("Süveyş'e indirim ve teşvik || Suez discounts and incentives", "Süveyş Kanalı Otoritesi armatörlere indirim sundu. || The Suez Canal Authority offered discounts to shipowners.", [["gold", EG, -0.5], ["stab", EG, 1]])),
     YE: s.r("Husiler Kızıldeniz'i koz olarak kullanıyor; ama hava saldırıları ve ablukanın bedeli ağır. || The Houthis use the Red Sea as leverage, but air strikes and the blockade are costly.",
            s.o("Saldırıları sürdür || Continue the attacks", "Husiler yeni gemi saldırıları ilan etti. || The Houthis announced new attacks on ships.", [["rel", YE, US, -5], ["rel", YE, IL, -5], ["rel", YE, SA, -2]]),
            s.o("Ateşkesi koru || Keep the truce", "Sana Gazze ateşkesine uyumlu bir saldırı ara verdi. || Sanaa paused attacks in line with the Gaza ceasefire.", [["rel", YE, US, 2], ["rel", YE, SA, 3], ["stab", YE, 1]])),
     IL: s.r("Eilat limanı ve hava savunması hedefte; Husilere vuruş mu, ABD ile koordinasyon mu? || The port of Eilat and your air defences are targets; strike the Houthis, or coordinate with the US?",
            s.o("Hudeyde limanını vur || Strike Hodeidah port", "İsrail Hudeyde limanı ve elektrik santrallerini vurdu. || Israel struck Hodeidah port and power stations.", [["rel", IL, YE, -6], ["rel", IL, IR, -2]]),
            s.o("Savunmaya odaklan || Focus on defence", "İsrail çok katmanlı hava savunmasını yeniledi. || Israel renewed its layered air defence.", [["stab", IL, 1]]), minor=True)},
    icon="ship", scene="naval")
s.m("sigorta", 28, "Sigorta Primleri ve Konvoylar || Insurance Premiums and Convoys",
    "Savaş riski primleri deniz sigortasını ikiye katladı; konteyner navlunu yükseldi, Avrupa limanlarında gecikmeler başladı. Donanmalar konvoy eskortu için yarışıyor. || War-risk premiums doubled marine insurance; container freight rose and Europe's ports saw delays. Navies compete to escort convoys.",
    [["gold", EG, -0.5], ["rel", SA, IR, -2]],
    {SA: s.r("Cidde ve Yanbu limanlarınız Kızıldeniz'e bağlı; Vizyon 2030 de güvenli bir deniz ister. || Jeddah and Yanbu ports depend on the Red Sea; Vision 2030 also needs a safe sea.",
            s.o("Husilerle yeni bir barış anlaşması || A new peace deal with the Houthis", "Riyad Husilerle yol haritası görüşmelerini canlandırdı. || Riyadh revived roadmap talks with the Houthis.", [["rel", SA, YE, 4], ["rel", SA, IR, 2]]),
            s.o("Deniz gücünü artır || Build up naval power", "Suudi Arabistan Kızıldeniz filosunu güçlendirdi. || Saudi Arabia strengthened its Red Sea fleet.", [["troops", SA, 3], ["gold", SA, -0.5], ["rel", SA, YE, -3]])),
     IR: s.r("Husiler sizin vekil gücünüz; ama baskı ABD yaptırımlarını sıkılaştırıyor. || The Houthis are your proxy, but pressure is tightening US sanctions.",
            s.o("Husilere desteği sürdür || Keep supporting the Houthis", "İran Husilere silah ve istihbarat akışını sürdürdü. || Iran kept up arms and intelligence flow to the Houthis.", [["rel", IR, US, -3], ["rel", IR, SA, -2]]),
            s.o("Gerilimi düşür || De-escalate", "Tahran Husileri sakinleştirmek için Umman kanalını kullandı. || Tehran used the Omani channel to calm the Houthis.", [["rel", IR, US, 2], ["rel", IR, SA, 2]])),
     EG: s.r("Süveyş geliri neredeyse yarı yarıya düştü; borç ve kur baskısı büyüyor. || Suez revenue nearly halved; debt and currency pressure mounts.",
            s.o("Körfez'den acil finansman || Seek emergency Gulf finance", "Kahire Körfez fonlarından acil kredi aldı. || Cairo got an emergency loan from Gulf funds.", [["gold", EG, 1.5], ["rel", EG, SA, 3]]),
            s.o("IMF programını aç || Open the IMF programme", "Mısır IMF ile yeni bir program görüşmesi yaptı. || Egypt held talks on a new IMF programme.", [["gold", EG, 0.8], ["stab", EG, -1]]), minor=True)},
    icon="trade", scene="trade", major=False)
s.m("abluka", 62, "Hudeyde Savaşı || The Battle for Hodeidah",
    "Yemen'in kuzeybatı limanı Hudeyde için kara ve deniz harekâtı sürüyor; Husilerin füze stokları ve Kızıldeniz'in kaderi bu limanda düğümleniyor. || A land and sea operation for Hodeidah, Yemen's northwest port, is under way; the Houthis' missile stocks and the fate of the Red Sea hinge on this port.",
    [["stab", YE, -3], ["rel", IR, SA, -2]],
    {SA: s.r("Liman düşerse Husilerin deniz tehdidi büyük ölçüde kırılır; ama insani felaket ve uluslararası baskı da artar. || If the port falls, the Houthi sea threat is largely broken, but the humanitarian toll and global pressure grow.",
            s.o("Harekâtı destekle || Support the operation", "Riyad koalisyonun Hudeyde harekâtına hava desteği verdi. || Riyadh gave air support to the coalition's Hodeidah operation.", [["war", SA, YE, "solo"], ["buff", SA, "att", 1.1, 6], ["rel", SA, IR, -4]]),
            s.o("İnsani koridor ve müzakere || Humanitarian corridor and talks", "Suudi Arabistan Hudeyde'de insani koridor önerdi. || Saudi Arabia proposed a humanitarian corridor at Hodeidah.", [["rel", SA, YE, 3], ["stab", SA, 1]])),
     YE: s.r("Husi hâkimiyetindeki liman hayatî; kaybı hem para hem silah akışını keser. || The Houthi-held port is vital; losing it would cut both money and the arms flow.",
            s.o("Limanı sonuna dek savun || Defend the port to the end", "Husiler Hudeyde'de mayın ve füzelerle savunma kurdu. || The Houthis built a defence of mines and missiles at Hodeidah.", [["buff", YE, "def", 1.2, 8], ["rel", YE, SA, -3]]),
            s.o("Ateşkes için taviz ver || Concede for a ceasefire", "Sana Hudeyde'de BM gözetimi önerdi. || Sanaa offered UN supervision at Hodeidah.", [["peace", YE, SA], ["rel", YE, SA, 3]])),
     IR: s.r("Hudeyde düşerse Körfez'deki vekâlet zinciriniz zayıflar. || If Hodeidah falls, your proxy chain in the Gulf weakens.",
            s.o("Denizden ikmal kanalı aç || Open a sea supply line", "İran gizlice Husilere deniz yoluyla silah gönderdi. || Iran covertly shipped arms to the Houthis by sea.", [["rel", IR, SA, -3], ["rel", IR, US, -3]]),
            s.o("Arabuluculuk için Umman'ı kullan || Use Oman for mediation", "Tahran Umman aracılığıyla ateşkes çağrısı yaptı. || Tehran called for a ceasefire via Oman.", [["rel", IR, SA, 2]]), minor=True)},
    icon="landing", scene="pre_landing")
s.save()

# ---------------------------------------------------------------- sahel (kurgusal)
s = Scn("sahel")
s.m("ablukabam", 6, "Başkent Abluka Altında (Kurgusal) || The Capital Under Blockade (Fictional)",
    "Kurgusal silahlı gruplar yakıt konvoylarını yakıp ana yolları keserek başkenti sıkıştırıyor; okullar kapalı, elektrik kesintileri günlük. Hükümet 'dış destek'i arıyor: Rus paralı timleri mi, Fransız hava gücü mü, yoksa bölgesel ittifak mı? Bu bir kurgudur. || Fictional armed groups burn fuel convoys and cut main roads, squeezing the capital; schools are shut, power cuts are daily. The government seeks outside help: Russian contractors, French air power or a regional alliance? This is fiction.",
    [["stab", ML, -3], ["stab", BF, -2]],
    {ML: s.r("Başkent boğuluyor; ordu moralsiz ve yakıt yok. Hangi dış güce yaslanacaksınız? || The capital is suffocating; the army has poor morale and no fuel. Which outside power will you lean on?",
            s.o("Rus yardımına yönel || Turn to Russian help", "Bamako Rus askerî danışman ve silah talep etti. || Bamako requested Russian advisers and arms.", [["rel", ML, RU, 6], ["rel", ML, FR, -4], ["troops", ML, 3]]),
            s.o("Bölgesel ittifak kur || Form a regional alliance", "Mali, Nijer ve Burkina Faso ortak bir kuvvet açıkladı. || Mali, Niger and Burkina Faso announced a joint force.", [["rel", ML, NE, 5], ["rel", ML, BF, 5], ["ally", ML, NE]])),
     FR: s.r("Fransa bölgeden çekildi ama çıkarları ve vatandaşları risk altında; Paris yeniden müdahale eder mi? || France has left the region, but its interests and nationals are at risk; will Paris intervene again?",
            s.o("Hava desteği ve istihbarat ver || Offer air support and intelligence", "Paris sınırlı hava desteği ve istihbarat önerdi. || Paris offered limited air support and intelligence.", [["rel", FR, ML, 3], ["rel", FR, DZ, -2]]),
            s.o("Uzak dur || Stay away", "Fransa yeniden müdahale etmeyi reddetti. || France refused to intervene again.", [["rel", FR, ML, -2], ["stab", FR, 1]]), minor=True),
     DZ: s.r("Cezayir kuzey sınırı ve Tuareg meselesi nedeniyle duruma çok duyarlı; Mali ile ilişkiler gergin. || Algeria is very sensitive because of its southern border and the Tuareg question; ties with Mali are strained.",
            s.o("Arabuluculuk ve sınır güvenliği || Mediation and border security", "Cezayir tarafları görüşmeye çağırıp sınır devriyelerini artırdı. || Algiers invited the parties to talks and increased border patrols.", [["rel", DZ, ML, 3], ["troops", DZ, 2]]),
            s.o("Sert tepki ver || React sharply", "Cezayir Mali'yi 'komşuluğa aykırı' davranmakla suçladı. || Algiers accused Mali of 'un-neighbourly conduct'.", [["rel", DZ, ML, -4]]), minor=True)},
    icon="warning", scene="crisis")
s.m("darbe", 30, "Bir Darbe Söylentisi (Kurgusal) || A Coup Rumour (Fictional)",
    "Kurgusal bir cuntanın içinde çatlak var: genç subaylar liderliği 'yetersiz' buluyor. Dış güçler hangi cenahın destekleneceğini tartışıyor; bölgesel örgütler yaptırım tehdidinde bulunuyor. || There is a crack in a fictional junta: young officers find the leadership 'inadequate'. Outside powers debate which camp to back; regional bodies threaten sanctions.",
    [["stab", ML, -2], ["stab", NE, -2], ["stab", BF, -2]],
    {NE: s.r("Üranyum ve petrol gelirleri hanenizi besliyor; ama içerideki rakipler de sabırsız. || Uranium and oil revenues sustain you, but rivals at home are impatient.",
            s.o("Güvenlik güçlerini sıkılaştır || Tighten the security forces", "Niamey ordu ve istihbaratta kadro değişikliğine gitti. || Niamey reshuffled the army and intelligence.", [["stab", NE, 3], ["rel", NE, NG, -2]]),
            s.o("Siyasi açılım sözü ver || Promise a political opening", "Nijer geçiş takvimi ve seçim sözü verdi. || Niger promised a transition timetable and elections.", [["stab", NE, 1], ["rel", NE, NG, 3], ["rel", NE, FR, 1]])),
     NG: s.r("Nijerya sınırdaki istikrarsızlığa karşı ECOWAS'ı mı çağıracak, yoksa tek başına mı hareket edecek? || Will Nigeria call on ECOWAS against instability on its border, or act alone?",
            s.o("ECOWAS yaptırımı ve diplomasi || ECOWAS sanctions and diplomacy", "Abuja ECOWAS üzerinden yaptırım tehdidi yaptı. || Abuja threatened sanctions via ECOWAS.", [["rel", NG, NE, -3], ["rel", NG, FR, 2]]),
            s.o("Doğrudan diyalog || Direct dialogue", "Abuja Niamey ile doğrudan güvenlik görüşmesi yaptı. || Abuja held direct security talks with Niamey.", [["rel", NG, NE, 4]]), minor=True),
     BF: s.r("Burkina Faso'da kırsal alanların büyük kısmı silahlı grupların elinde; ordunun dayanıklılığı zayıf. || Much of rural Burkina Faso is held by armed groups; the army's endurance is weak.",
            s.o("Gönüllü milis genişlet || Expand volunteer militias", "Ouagadougou gönüllü savunma milislerini genişletti. || Ouagadougou expanded its volunteer defence militias.", [["troops", BF, 4], ["stab", BF, -1]]),
            s.o("Rus danışman ve dron al || Add Russian advisers and drones", "Burkina Faso Rus danışman ve dron anlaşması yaptı. || Burkina Faso signed a deal for Russian advisers and drones.", [["rel", BF, RU, 4], ["rel", BF, FR, -3], ["troops", BF, 2]]))},
    icon="protest", scene="crisis", major=False)
s.m("bolgeselsavas", 70, "Bölgesel Savaşın Eşiği (Kurgusal) || On the Brink of a Regional War (Fictional)",
    "Kurgusal silahlı grupların ilerleyişi sınır devletlerini tehdit ediyor: mülteciler, silah akışı ve altın madenleri bölgesel savaş riskini büyütüyor. Dış güçler masada ya da sahada. || The advance of fictional armed groups threatens neighbouring states: refugees, arms flows and gold mines raise the risk of a regional war. Outside powers are at the table or in the field.",
    [["stab", ML, -2], ["stab", DZ, -1]],
    {DZ: s.r("Cezayir Sahra güvenliği için sınırlı müdahale seçeneğini tartışıyor. || Algeria weighs a limited intervention for Saharan security.",
            s.o("Sınırlı sınır ötesi operasyon || Limited cross-border operation", "Cezayir sınırda sınırlı bir operasyon başlattı. || Algeria launched a limited operation on the border.", [["rel", DZ, ML, -4], ["troops", DZ, 2], ["stab", DZ, 1]]),
            s.o("Diplomatik kriz masası || Diplomatic crisis desk", "Cezayir Afrika Birliği ile ortak kriz masası önerdi. || Algiers proposed a joint crisis desk with the African Union.", [["rel", DZ, ML, 2], ["rel", DZ, NG, 2]])),
     ML: s.r("Hükümetiniz ayakta ama kontrolünüz haritanın küçük bir kısmında. || Your government stands, but your control covers a small part of the map.",
            s.o("Rus güçlerine tam bağlan || Fully commit to Russian forces", "Bamako Rus güçlerine yeni üsler verdi. || Bamako granted the Russian forces new bases.", [["rel", ML, RU, 5], ["rel", ML, FR, -3], ["buff", ML, "def", 1.1, 8]]),
            s.o("Müzakere ve af || Negotiation and amnesty", "Mali silahlı gruplarla müzakere ve af önerdi. || Mali offered negotiation and amnesty to armed groups.", [["stab", ML, 2], ["rel", ML, DZ, 3]]))},
    icon="border_clash", scene="border")
s.save()

# ---------------------------------------------------------------- scs
s = Scn("scs")
s.m("scarborough", 6, "Scarborough Şoalı Doğa Koruma Alanı || Scarborough Shoal 'Nature Reserve'",
    "Çin, Scarborough Şoalı'nı 'ulusal doğa koruma alanı' ilan etti; Filipinler bunu bir ele geçirme adımı olarak görüyor. Sahil güvenlik gemileri su topu ve çarpışma teknikleriyle karşı karşıya. || China declared Scarborough Shoal a 'national nature reserve'; the Philippines sees it as a step toward seizure. Coast guard ships meet with water cannon and ramming manoeuvres.",
    [["rel", CN, PH, -4], ["stab", PH, -1]],
    {PH: s.r("Ayungin ve Scarborough için ikmal misyonlarınız tehlikede; ABD ile savunma anlaşmanız var. || Your resupply missions to Second Thomas Shoal and Scarborough are at risk; you have a defence treaty with the US.",
            s.o("ABD ve Japonya ile ortak devriye || Joint patrols with the US and Japan", "Manila ABD ve Japonya ile ortak deniz devriyesi yaptı. || Manila held joint maritime patrols with the US and Japan.", [["rel", PH, US, 4], ["rel", PH, JP, 4], ["rel", PH, CN, -4]]),
            s.o("Uluslararası tahkim ve ASEAN || International arbitration and ASEAN", "Manila 2016 tahkim kararına yeniden atıf yaptı ve ASEAN desteği istedi. || Manila cited the 2016 arbitration again and sought ASEAN backing.", [["rel", PH, VN, 3], ["rel", PH, MY, 2], ["rel", PH, CN, -1]])),
     CN: s.r("Sahil güvenlik kontrolün aracı; ama Filipinler ile krizi aşırı tırmandırmak ABD'yi sahaya çeker. || The coast guard is your instrument, but escalating too far with the Philippines draws in the US.",
            s.o("Devriye ve su topuyla baskı yap || Press with patrols and water cannon", "Çin sahil güvenliği Scarborough'da devriyeleri artırdı. || China's coast guard added patrols at Scarborough.", [["rel", CN, PH, -5], ["rel", CN, US, -2], ["buff", CN, "att", 1.05, 6]]),
            s.o("Balıkçılık çerçevesi öner || Offer a fisheries framework", "Pekin Filipinler'e sınırlı balıkçılık çerçevesi önerdi. || Beijing offered Manila a limited fisheries framework.", [["rel", CN, PH, 2], ["rel", CN, VN, 1]])),
     VN: s.r("Hanoi kendi adacıklarını sessizce genişletiyor; Pekin ve Manila krizinde taraf tutmak istemiyor. || Hanoi quietly expands its own islets and does not want to take sides in the Beijing–Manila crisis.",
            s.o("Sessiz inşaata devam et || Continue quiet construction", "Vietnam Spratly'deki yapılaşmayı sürdürdü. || Vietnam continued building in the Spratlys.", [["rel", VN, CN, -2], ["gold", VN, -0.3]]),
            s.o("Çin ile temas kanalını koru || Keep the channel with China", "Hanoi Pekin'le Güney Çin Denizi diyalog hattını yeniledi. || Hanoi renewed its South China Sea hotline with Beijing.", [["rel", VN, CN, 2]]), minor=True)},
    icon="ship", scene="naval")
s.m("ayungin", 34, "Ayungin Şoalı İkmali || The Second Thomas Shoal Resupply",
    "BRP Sierra Madre'ye giden ikmal botu Çin sahil güvenliği tarafından engellendi; bir Filipinli denizci yaralandı. Savunma anlaşmasının 'silahlı saldırı' tanımı yeniden gündemde. || A resupply boat bound for the BRP Sierra Madre was blocked by Chinese coast guard; a Filipino sailor was wounded. The 'armed attack' definition in the defence treaty is back on the table.",
    [["rel", PH, CN, -5], ["rel", US, CN, -2]],
    {PH: s.r("Mutabakat kâğıt üzerinde; sahada rotayı korumanız lazım. || The understanding exists on paper; at sea you must protect the route.",
            s.o("Eskortlu ikmal (ABD desteği) || Escorted resupply (with US support)", "Manila ikmali eskortlu yaptı ve ABD gemileri bölgede kaldı. || Manila ran the resupply under escort with US ships nearby.", [["rel", PH, US, 4], ["rel", PH, CN, -3], ["troops", PH, 2]]),
            s.o("Gizli ikmal ve diplomasi || Discreet resupply and diplomacy", "Manila Çin'le geçici bir ikmal mutabakatını kabul etti. || Manila accepted a provisional resupply understanding with China.", [["rel", PH, CN, 2], ["stab", PH, -1]])),
     CN: s.r("Sierra Madre çürüyor; bir inşaat malzemesi ikmali 'statükoyu bozmak' sayılır. || The Sierra Madre is rusting; a delivery of building materials counts as 'altering the status quo'.",
            s.o("Gemiyi engelle || Block the ship", "Çin sahil güvenliği ikmal botlarını durdurdu. || Chinese coast guard stopped the supply boats.", [["rel", CN, PH, -4], ["rel", CN, US, -3]]),
            s.o("Sınırlı ikmale izin ver || Allow limited resupply", "Pekin insani ikmale izin verdi. || Beijing permitted a humanitarian resupply.", [["rel", CN, PH, 3], ["rel", CN, US, 1]])),
     US: s.r("Savunma Anlaşması'nın 4. maddesi sizi bağlıyor mu? Cevabınız tüm bölge için bir sinyal. || Does Article IV of the Mutual Defense Treaty bind you? Your answer is a signal for the region.",
            s.o("Tam bağlılık beyanı || A full statement of commitment", "Washington Manila'ya 'demir gibi' güvence verdi. || Washington gave Manila 'ironclad' assurances.", [["rel", US, PH, 5], ["rel", US, CN, -4]]),
            s.o("Belirsizliği koru || Keep strategic ambiguity", "ABD ittifak yükümlülüğünü açık etmedi. || The US kept its alliance obligations vague.", [["rel", US, PH, -2], ["rel", US, CN, 1]]), minor=True)},
    icon="border_clash", scene="border")
s.m("davranis", 70, "Davranış Kuralları Müzakeresi || Code of Conduct Talks",
    "ASEAN dönem başkanı Manila, Çin ile 'bağlayıcı' Davranış Kuralları metnini bitirmek istiyor; Pekin hukuken bağlayıcılığa ve üçüncü ülke hükümlerine karşı. Müzakere çıkmaza giriyor. || ASEAN chair Manila wants to finish a 'binding' Code of Conduct with China; Beijing resists legal bindingness and third-party clauses. The talks stall.",
    [["rel", CN, PH, 1], ["stab", PH, 1]],
    {PH: s.r("Manila ASEAN başkanı: metni imzalatırsanız tarihe geçersiniz; ama Çin'in çekincesi tüm anlaşmayı zayıflatabilir. || Manila chairs ASEAN: if you get the text signed you make history, but China's reservations could hollow out the deal.",
            s.o("Bağlayıcı metin için diren || Insist on a binding text", "Manila bağlayıcı metin için ısrar etti. || Manila insisted on a binding text.", [["rel", PH, CN, -2], ["rel", PH, VN, 2], ["rel", PH, MY, 2]]),
            s.o("Esnek bir ara metin kabul et || Accept a flexible interim text", "Manila bağlayıcı olmayan bir ara metni kabul etti. || Manila accepted a non-binding interim text.", [["rel", PH, CN, 3], ["stab", PH, -1]])),
     CN: s.r("Pekin ASEAN'ı bölmek ve metinden yararlanmak istiyor; ama kriz Filipinler'i ABD'ye yaklaştırdı. || Beijing wants to divide ASEAN and benefit from the text, yet the crisis pushed the Philippines closer to the US.",
            s.o("Üçüncü ülke şartına itiraz et || Reject the third-party clause", "Pekin üçüncü ülke şartına itiraz etti ve metni yavaşlattı. || Beijing objected to the third-party clause and slowed the text.", [["rel", CN, PH, -2], ["rel", CN, VN, -1]]),
            s.o("Metni imzala || Sign the text", "Çin Davranış Kuralları metnini imzalamaya hazır olduğunu söyledi. || China said it was ready to sign the Code of Conduct.", [["rel", CN, PH, 4], ["rel", CN, VN, 3], ["rel", CN, US, 1]]))},
    icon="treaty", scene="peace", major=False)
s.save()
print("tamam: arctic essequibo korea nile redsea sahel scs")

# ---------------------------------------------------------------- kuraklik (kurgusal)
s = Scn("kuraklik")
s.m("nehir", 10, "Nehirler Çekiliyor (Kurgusal) || The Rivers Are Receding (Fictional)",
    "Kurgusal bir kuraklık dalgası Fırat, Dicle, Nil ve İndus'un debisini düşürdü; barajlar rekor düşük seviyede. Su paylaşım anlaşmaları yeniden okunuyor ve her başkent 'önce kendi halkım' diyor. Bu bir kurgudur. || A fictional drought wave cut the flow of the Euphrates, Tigris, Nile and Indus; reservoirs sit at record lows. Water-sharing treaties are being re-read, and every capital says 'my own people first'. This is fiction.",
    [["stab", TR, -1], ["stab", IQ, -2], ["stab", EG, -2], ["stab", PK, -2]],
    {TR: s.r("Barajlarınız komşuların suyunu elinizde tutuyor; hem büyük bir koz hem büyük bir sorumluluk. || Your dams hold your neighbours' water: both great leverage and great responsibility.",
            s.o("Salımı artır, ticaret karşılığı su || Release more water in exchange for trade", "Ankara Irak'a daha fazla su salımı ve karşılığında enerji-ticaret anlaşması önerdi. || Ankara offered Iraq more water in exchange for an energy–trade deal.", [["rel", TR, IQ, 5], ["gold", TR, 0.5]]),
            s.o("Barajları tut, iç ihtiyacı önce karşıla || Hold the dams and serve home needs first", "Türkiye baraj salımlarını azalttı; Irak ve Suriye tepki gösterdi. || Turkey reduced dam releases; Iraq and Syria reacted.", [["rel", TR, IQ, -4], ["stab", TR, 1]])),
     IQ: s.r("Irak'ta tarım ve bataklıklar kuruyor; göçler başladı. || Farming and marshlands are drying in Iraq; migration has begun.",
            s.o("Ankara ile su anlaşması || A water deal with Ankara", "Bağdat Türkiye ile su-enerji paketi imzaladı. || Baghdad signed a water-and-energy package with Turkey.", [["rel", IQ, TR, 5], ["stab", IQ, 1]]),
            s.o("Uluslararası baskı yap || Seek international pressure", "Bağdat meseleyi BM'ye taşıdı. || Baghdad took the issue to the UN.", [["rel", IQ, TR, -3], ["rel", IQ, US, 2]]), minor=True),
     IN: s.r("Hindistan'da muson başarısız; İndus ve Brahmaputra kontrolü stratejik bir mesele. || The monsoon failed in India; control of the Indus and Brahmaputra is a strategic issue.",
            s.o("Su altyapısını hızlandır || Speed up water infrastructure", "Delhi nehir bağlantı ve baraj projelerini hızlandırdı. || Delhi accelerated river-linking and dam projects.", [["gold", IN, -1.0], ["stab", IN, 2], ["rel", IN, PK, -2]]),
            s.o("Komşularla su görüşmesi || Water talks with neighbours", "Hindistan Pakistan ve Bangladeş'le su görüşmesi önerdi. || India proposed water talks with Pakistan and Bangladesh.", [["rel", IN, PK, 3], ["stab", IN, -1]]), minor=True)},
    icon="drought", scene="crisis")
s.m("gida", 40, "Gıda Fiyatları Fırlıyor (Kurgusal) || Food Prices Soar (Fictional)",
    "Buğday, pirinç ve mısır fiyatları kurak sezonla ikiye katlandı; ihracat yasakları ve stok yapma yarışı başladı. Ekmek kuyrukları siyasi bir güvenlik sorununa dönüşüyor. || Wheat, rice and maize prices doubled with the dry season; export bans and a stockpiling race began. Bread queues are turning into a political security problem.",
    [["stab", EG, -2], ["stab", ET, -2], ["stab", PK, -2], ["gold", EG, -0.5]],
    {EG: s.r("Dünyanın en büyük buğday ithalatçılarındansınız; ekmek sübvansiyonu bütçeyi eritiyor. || You are among the biggest wheat importers; bread subsidies drain the budget.",
            s.o("Stok ve uzun vadeli ithalat anlaşması || Stockpiles and long-term import deals", "Kahire Rusya ve Ukrayna ile uzun vadeli tahıl anlaşması yaptı. || Cairo signed long-term grain deals with Russia and Ukraine.", [["gold", EG, -1.0], ["stab", EG, 3], ["rel", EG, TR, 2]]),
            s.o("Sübvansiyonu kıs || Cut the subsidy", "Mısır ekmek sübvansiyonunu azalttı; protestolar çıktı. || Egypt trimmed bread subsidies; protests broke out.", [["gold", EG, 1.0], ["stab", EG, -4]])),
     PK: s.r("Pencap'ın buğday ambarı kurudu; ihracat yerine iç tüketim mi? || Punjab's granary is dry; domestic supply instead of export?",
            s.o("İhracat yasağı koy || Impose an export ban", "İslamabad buğday ve pirinç ihracatını yasakladı. || Islamabad banned wheat and rice exports.", [["stab", PK, 2], ["gold", PK, -0.5], ["rel", PK, IN, -1]]),
            s.o("Uluslararası yardım iste || Appeal for international aid", "Pakistan BM ve Körfez'den gıda yardımı istedi. || Pakistan appealed to the UN and the Gulf for food aid.", [["stab", PK, 1], ["rel", PK, SA, 3]]), minor=True),
     ET: s.r("Etiyopya'da kuraklık ve iç çatışma birleşiyor; milyonlarca insan gıda yardımına muhtaç. || Drought and internal conflict combine in Ethiopia; millions need food aid.",
            s.o("Sulama ve yardım programı || Irrigation and relief programme", "Addis Ababa büyük bir sulama ve gıda yardımı programı başlattı. || Addis Ababa launched a large irrigation and food-relief programme.", [["stab", ET, 2], ["gold", ET, -1.0]]),
            s.o("Barajı elektrik ve tarım için kullan || Use the dam for power and farming", "Etiyopya baraj gölünü sulama için kullandı. || Ethiopia used its reservoir for irrigation.", [["gold", ET, 1.0], ["rel", ET, EG, -3]]), minor=True)},
    icon="drought", scene="trade", major=False)
s.m("savas", 90, "Su Savaşı Eşiğinde (Kurgusal) || On the Edge of Water War (Fictional)",
    "Kurak yıl üçüncü yılına girdi: baraj kapakları, nehir yönlendirmeleri ve sınır geçişleri çatışma nedeni oldu. Bir ülke 'su yoluyla savaş' demeye hazır; diğerleri arabuluculuk arıyor. Bu bir kurgudur. || The drought enters its third year: dam gates, river diversions and border crossings have become flashpoints. One country is ready to say 'war over water'; others seek mediation. This is fiction.",
    [["rel", EG, ET, -3], ["rel", IN, PK, -3], ["rel", IQ, TR, -3]],
    {IN: s.r("Su bir güvenlik mesele; ama savaş nükleer bir gölgede. || Water is a security matter, but war lies under a nuclear shadow.",
            s.o("Kontrollü baskı: su akışını sınırla || Controlled pressure: limit the flow", "Hindistan sınır ötesi su akışını sınırladı. || India limited cross-border water flow.", [["rel", IN, PK, -5], ["rel", IN, CN, -1]]),
            s.o("Ortak su komisyonu || A joint water commission", "Delhi ortak su komisyonu ve veri paylaşımı önerdi. || Delhi proposed a joint water commission and data sharing.", [["rel", IN, PK, 4], ["stab", IN, 1]])),
     PK: s.r("Suyun kesilmesi 'savaş eylemi' diye ilan edilebilir; ama ekonomi ve ordu hazır mı? || Cutting off water can be declared 'an act of war', but are the economy and army ready?",
            s.o("Sınırda gövde gösterisi || A show of force at the border", "Pakistan sınır hattına birlik kaydırdı. || Pakistan moved units to the border line.", [["troops", PK, 3], ["rel", PK, IN, -4]]),
            s.o("Tahkim ve Çin aracılığı || Arbitration and Chinese mediation", "İslamabad uluslararası tahkim ve Pekin arabuluculuğu istedi. || Islamabad requested international arbitration and Beijing's mediation.", [["rel", PK, CN, 3], ["rel", PK, IN, -1]])),
     EG: s.r("Nil'in aşağı mecrasında son kelime sizde olmayabilir; ama diplomasi bitmedi. || You may not hold the last word on the lower Nile, but diplomacy is not over.",
            s.o("Etiyopya ile bağlayıcı su anlaşması || A binding water deal with Ethiopia", "Kahire Etiyopya'ya bağlayıcı doldurma ve işletme kuralları önerdi. || Cairo proposed binding filling and operating rules to Ethiopia.", [["rel", EG, ET, 4], ["stab", EG, 1]]),
            s.o("Güç gösterisi ve ittifak || Show of force and alliances", "Mısır Eritre ve Somali ile ortak tatbikat yaptı. || Egypt held joint drills with Eritrea and Somalia.", [["rel", EG, ET, -5], ["rel", EG, ER, 4], ["troops", EG, 2]]), minor=True)},
    icon="border_clash", scene="border")
s.save()
print("tamam: kuraklik")

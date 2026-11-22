#!/usr/bin/env python3
"""Mevcut 14 senaryoya 2'şer ek olay kartı (turn 16-120 haftalık aralıkta). Var olan data/scn_moments/<id>.json dosyasına ekler (yinelenen id atlanır).
Çalıştır: python3 tools/data/gen_scn_d.py"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scn_kit import Scn, ROOT

US = "United States of America"; RU = "Russia"; UA = "Ukraine"; PL = "Poland"; TR = "Turkey"; DE = "Germany"; CN = "China"; TW = "Taiwan"; JP = "Japan"
KR = "South Korea"; KP = "North Korea"; IR = "Iran"; IL = "Israel"; SA = "Saudi Arabia"; IN = "India"; PK = "Pakistan"; AZ = "Azerbaijan"; AM = "Armenia"
EG = "Egypt"; ET = "Ethiopia"; SD = "Sudan"; YE = "Yemen"; CA = "Canada"; NO = "Norway"; DK = "Denmark"; GY = "Guyana"; VE = "Venezuela"; BR = "Brazil"
PH = "Philippines"; VN = "Vietnam"; ML = "Mali"; NE = "Niger"; DZ = "Algeria"; NG = "Nigeria"; FR = "France"; BF = "Burkina Faso"; IQ = "Iraq"


def S(sid):
    s = Scn(sid)
    p = os.path.join(ROOT, "data/scn_moments/%s.json" % sid)
    old = json.load(open(p, encoding="utf-8"))
    s.ms = list(old["moments"]); s.k.en.update(old.get("moments_en", {}))
    s._have = {m["id"] for m in old["moments"]}
    return s


def done(s):
    p = os.path.join(ROOT, "data/scn_moments/%s.json" % s.sid)
    seen = set(); out = []
    for m in s.ms:
        if m["id"] in seen: continue
        seen.add(m["id"]); out.append(m)
    out.sort(key=lambda m: m.get("turn", 0))
    json.dump({"moments": out, "moments_en": s.k.en}, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(p, "a").write("\n")
    print(s.sid, len(out))


# ---------------- ukr
s = S("ukr")
s.m("dron", 30, "Dron Duvarı || The Drone Wall",
    "Avrupa'nın doğu sınırı boyunca dron ve hava savunma sistemleri örülüyor; Polonya ve Baltık ülkeleri hava sahası ihlallerine karşı ortak bir 'dron duvarı' istiyor. Rusya bunu provokasyon sayıyor. || A mesh of drones and air defences is being woven along Europe's eastern border; Poland and the Baltics want a joint 'drone wall' against airspace violations. Russia calls it a provocation.",
    [["rel", PL, RU, -3], ["rel", PL, DE, 2]],
    {PL: s.r("Varşova hava ihlallerine sert karşılık vermek ve ortak sistemi hızlandırmak istiyor. || Warsaw wants a firm answer to airspace violations and to speed up the joint system.",
            s.o("Dron duvarını başlat || Launch the drone wall", "Polonya ve komşuları ortak dron ve radar ağını devreye aldı. || Poland and its neighbours activated a joint drone and radar network.", [["rel", PL, DE, 4], ["buff", PL, "def", 1.15, 10], ["gold", PL, -0.5]]),
            s.o("Sadece diplomatik protesto || Diplomatic protest only", "Varşova ihlaller için Moskova'ya nota verdi. || Warsaw sent Moscow a note over the violations.", [["stab", PL, 1]])),
     RU: s.r("Moskova duvarı tehdit olarak görüyor; ama dron savaşında sınır ötesi tırmanış riski büyük. || Moscow sees the wall as a threat, but cross-border escalation is risky in a drone war.",
            s.o("Hava savunma tatbikatı yap || Stage an air-defence drill", "Rusya sınırda büyük bir hava savunma tatbikatı yaptı. || Russia held a major air-defence drill at the border.", [["rel", RU, PL, -3], ["troops", RU, 1]]),
            s.o("İhlalleri sınırla || Curb the violations", "Rusya sınır ihlallerini azalttı. || Russia reduced airspace violations.", [["rel", RU, PL, 2]]))},
    icon="missile", scene="air", major=False)
s.m("yeniden", 100, "Yeniden İnşa Fonu || The Reconstruction Fund",
    "Savaş sonrası için Avrupa, ABD ve Körfez ülkeleri milyarlarca dolarlık bir yeniden inşa fonu önerdi. Dondurulmuş Rus varlıklarının kullanımı ve Ukrayna'nın AB yolu masada. || Europe, the US and Gulf states proposed a multi-billion reconstruction fund for after the war. The use of frozen Russian assets and Ukraine's EU path are on the table.",
    [["gold", UA, 2.0], ["rel", UA, DE, 3], ["rel", RU, DE, -3]],
    {UA: s.r("Fon kalkınmayı hızlandırır ama şartları siyasi: yolsuzlukla mücadele ve reformlar. || The fund can speed development but comes with political conditions: anti-corruption and reforms.",
            s.o("Reform şartlarını kabul et || Accept reform conditions", "Kiev reform takvimini kabul etti; fon serbest bırakıldı. || Kyiv accepted a reform timetable; the fund was released.", [["gold", UA, 3.0], ["rel", UA, DE, 4], ["stab", UA, 1]]),
            s.o("Şartsız yardım iste || Demand no-strings aid", "Kiev şartsız yardım talep etti. || Kyiv demanded aid without conditions.", [["rel", UA, DE, -3], ["stab", UA, 1]])),
     RU: s.r("Moskova dondurulmuş varlıkların fona aktarılmasına karşı. || Moscow opposes transferring frozen assets into the fund.",
            s.o("Hukuki karşı hamle yap || File a legal counter-move", "Rusya varlıklara el koymanın hukuka aykırı olduğunu savundu. || Russia argued that seizing assets is unlawful.", [["rel", RU, DE, -3], ["stab", RU, 1]]),
            s.o("Müzakereyle çözüm ara || Seek a negotiated solution", "Moskova varlıklar için müzakere teklif etti. || Moscow offered talks on the assets.", [["rel", RU, DE, 2], ["gold", RU, 0.5]]))},
    icon="trade", scene="peace", major=False)
done(s)

# ---------------- twn
s = S("twn")
s.m("yarimiletken", 18, "Yarı İletken Gerilimi || The Chip Standoff",
    "Çin gümrük kontrolleri Tayvan'ın çip ihracatını yavaşlattı; ABD ve Japonya ortak tedarik zinciri güvenliği istiyor. TSMC fabrikaları dünyanın kilit noktası. || Chinese customs checks slowed Taiwan's chip exports; the US and Japan want joint supply-chain security. TSMC fabs are the world's chokepoint.",
    [["gold", TW, -1.0], ["gold", CN, -0.5], ["rel", US, CN, -3]],
    {TW: s.r("Çip ihracatı sorunu doğrudan ekonomik güvenliğin parçası. || The chip export problem is part of core economic security.",
            s.o("ABD ve Japonya ile tedarik ittifakı kur || Form a supply alliance with the US and Japan", "Taipei ortak yarı iletken güvenlik anlaşmasına gitti. || Taipei joined a joint semiconductor security pact.", [["rel", TW, US, 5], ["rel", TW, JP, 5], ["rel", TW, CN, -3]]),
            s.o("Pekin'le ticaret kanalı aç || Open a trade channel with Beijing", "Tayvan Çin'le ticari kanal arayışına girdi. || Taiwan sought a trade channel with Beijing.", [["rel", TW, CN, 3], ["gold", TW, 0.5]])),
     CN: s.r("Pekin teknoloji bağımlılığını azaltmak istiyor ama kendi sanayisi de çipe bağlı. || Beijing wants less dependence but its own industry relies on chips.",
            s.o("Kontrolleri sürdür || Maintain the checks", "Çin kontrolleri sürdürdü; fiyatlar yükseldi. || China kept the checks; prices rose.", [["rel", CN, TW, -3], ["rel", CN, US, -2]]),
            s.o("Kontrolleri gevşet || Ease the checks", "Pekin gümrük kontrollerini gevşetti. || Beijing eased the customs checks.", [["rel", CN, TW, 2], ["gold", CN, 0.5]]))},
    icon="trade", scene="trade", major=False)
s.m("kablo2", 96, "Deniz Altı Kablo Kesintisi || An Undersea Cable Cut",
    "Tayvan'ı dünyaya bağlayan deniz altı kablolarından ikisi aynı gün kesildi; sorumlular belirsiz, ama bir Çin bayraklı gemi bölgede izlendi. İletişimde yavaşlama, borsada düşüş yaşandı. || Two of the undersea cables linking Taiwan to the world were cut on the same day; the culprits are unclear, but a Chinese-flagged vessel was tracked in the area. Communications slowed and markets fell.",
    [["stab", TW, -2], ["gold", TW, -0.5], ["rel", TW, CN, -3]],
    {TW: s.r("Kablo sabotajı bir abluka provasının işareti olabilir. || Cable sabotage may be a rehearsal for a blockade.",
            s.o("Gemiyi yakala || Seize the vessel", "Tayvan sahil güvenliği şüpheli gemiyi yakaladı. || Taiwan's coast guard seized the suspect ship.", [["rel", TW, CN, -4], ["stab", TW, 2]]),
            s.o("Yedek hat kur ve izle || Set up backup lines and monitor", "Taipei yedek iletişim hatlarını devreye aldı. || Taipei activated backup communication lines.", [["gold", TW, -0.5], ["stab", TW, 1]])),
     CN: s.r("Pekin suçlamaları reddediyor; ama ek ihlaller baskı aracı olabilir. || Beijing denies the claims; but further incidents could serve as leverage.",
            s.o("Suçlamayı reddet || Deny the allegations", "Çin kablo kesintisinden sorumlu olmadığını söyledi. || China said it was not responsible for the cable cut.", [["stab", CN, 1]]),
            s.o("Ek deniz devriyesi gönder || Send extra naval patrols", "Çin Tayvan Boğazı'nda devriyeyi artırdı. || China stepped up patrols in the Taiwan Strait.", [["rel", CN, TW, -4], ["troops", CN, 1]]))},
    icon="submarine", scene="naval")
done(s)

# ---------------- irn
s = S("irn")
s.m("yaptirim", 20, "Yaptırım Pazarlığı || The Sanctions Bargain",
    "Umman ve Katar arabuluculuğunda yaptırım gevşetmesi karşılığında zenginleştirme sınırı pazarlığı yapılıyor. Washington ve Tel Aviv ikna olmuş değil; Tahran ekonomik baskı altında. || Oman and Qatar are mediating a bargain: sanctions relief for enrichment limits. Washington and Tel Aviv are unconvinced; Tehran is under economic pressure.",
    [["rel", IR, US, 2], ["rel", IL, US, -1]],
    {IR: s.r("Ekonomi sıkışıyor; ama müzakere taviz olarak görülebilir. || The economy is squeezed, but negotiation could look like a concession.",
            s.o("Sınırlı anlaşmayı kabul et || Accept a limited deal", "İran sınırlı bir ara anlaşmayı kabul etti. || Iran accepted a limited interim deal.", [["gold", IR, 1.5], ["rel", IR, US, 4], ["stab", IR, -1]]),
            s.o("Direniş ekonomisini sürdür || Stay with the resistance economy", "Tahran taviz vermeyi reddetti. || Tehran refused to concede.", [["rel", IR, US, -3], ["stab", IR, 1]])),
     US: s.r("Washington müzakereden yana ama İsrail ve Körfez ülkelerinin güvenlik kaygıları var. || Washington favours talks, but Israel and Gulf states have security concerns.",
            s.o("Müzakereyi destekle || Support the talks", "ABD arabuluculuğu açıkça destekledi. || The US openly backed the mediation.", [["rel", US, IR, 3], ["rel", US, IL, -3]]),
            s.o("Maksimum baskıyı sürdür || Keep maximum pressure", "Washington yaptırımları sıkılaştırdı. || Washington tightened sanctions.", [["rel", US, IR, -4], ["rel", US, IL, 3]]))},
    icon="treaty", scene="peace", major=False)
s.m("vekil", 76, "Vekil Çatışmaları || Proxy Clashes",
    "Irak ve Suriye'de İran bağlantılı gruplar ile ABD üsleri arasında drone ve roket saldırıları arttı. Bölgesel savaşın eşiğinde bir tırmanış riski var. || Drone and rocket attacks between Iran-linked groups and US bases in Iraq and Syria have intensified. There is a risk of escalation on the verge of regional war.",
    [["stab", IQ, -2], ["rel", IR, US, -3]],
    {IR: s.r("Vekillerin denetimi sınırlı; ama saldırılar siyasi koz sağlıyor. || Control over proxies is limited, but the attacks provide leverage.",
            s.o("Vekilleri dizginle || Rein in the proxies", "Tahran vekil gruplara itidal çağrısı yaptı. || Tehran urged restraint on the proxy groups.", [["rel", IR, US, 3], ["stab", IR, -1]]),
            s.o("Baskıyı artır || Raise the pressure", "İran bağlantılı gruplar saldırıları artırdı. || Iran-linked groups increased attacks.", [["rel", IR, US, -4], ["rel", IR, IQ, 2]])),
     US: s.r("Üslerde can kaybı riski var. Misilleme mi, geri çekilme mi? || There is a risk of casualties at the bases. Retaliate or pull back?",
            s.o("Hedefli misilleme yap || Strike back in a targeted way", "ABD vekil gruplara hedefli hava saldırıları yaptı. || The US launched targeted strikes on proxy groups.", [["rel", US, IR, -4], ["rel", US, IQ, -2]]),
            s.o("Üsleri azalt || Draw down the bases", "Washington bazı üsleri küçülttü. || Washington scaled down some bases.", [["rel", US, IQ, 3], ["stab", US, 1]]))},
    icon="missile", scene="air")
done(s)

# ---------------- ind
s = S("ind")
s.m("sinir", 22, "Hat Boyunca Gerilim || Tension Along the Line of Control",
    "Kontrol Hattı'nda yeniden topçu atışları başladı; iki taraf da sivil köyleri boşaltıyor. Nükleer güçler arasında nadiren görülen bir doğrudan hat konuşması yapılıyor. || Artillery fire resumed along the Line of Control; both sides are evacuating civilian villages. A rare direct hotline call is held between the two nuclear powers.",
    [["rel", IN, PK, -2], ["stab", PK, -1]],
    {IN: s.r("Delhi iç siyasi baskı altında; ama tırmanış hesapları riskli. || Delhi faces domestic pressure, but escalation calculations are risky.",
            s.o("Sınırlı misilleme yap || Make a limited retaliation", "Hindistan hat boyunca sınırlı karşılık verdi. || India made a limited response along the line.", [["rel", IN, PK, -4], ["buff", IN, "att", 1.1, 6]]),
            s.o("Hot-line'dan yatıştır || De-escalate by hotline", "Delhi askerî hat üzerinden itidal mesajı verdi. || Delhi sent a message of restraint over the military hotline.", [["rel", IN, PK, 2], ["stab", IN, 1]])),
     PK: s.r("İslamabad ekonomik kırılganlıkla mücadele ediyor; tırmanış maliyetli. || Islamabad struggles with economic fragility; escalation is costly.",
            s.o("Aynı ölçüde karşılık ver || Respond in kind", "Pakistan topçu ateşiyle karşılık verdi. || Pakistan answered with artillery fire.", [["rel", PK, IN, -4], ["stab", PK, 1]]),
            s.o("BM'ye başvur || Appeal to the UN", "İslamabad meseleyi BM'ye taşıdı. || Islamabad took the matter to the UN.", [["rel", PK, IN, 1], ["rel", PK, CN, 2]]))},
    icon="border_clash", scene="border")
s.m("su", 90, "Nehir Suyu Anlaşmazlığı || The River Water Dispute",
    "Hindistan baraj ve kanal projelerini hızlandırdı; Pakistan bunu 'su silahı' olarak nitelendiriyor. Tarım sezonu yaklaşırken su akışı siyasi koz haline geldi. || India sped up dam and canal projects; Pakistan calls it a 'water weapon'. With the farming season near, river flow has become political leverage.",
    [["gold", PK, -1.0], ["rel", PK, IN, -3]],
    {PK: s.r("Tarım ve elektrik üretimi suya bağlı; hukuki yol mu, askerî tehdit mi? || Farming and power depend on water; a legal path or a military threat?",
            s.o("Uluslararası hakem başvurusu yap || File for international arbitration", "Pakistan uluslararası tahkime başvurdu. || Pakistan filed for international arbitration.", [["rel", PK, CN, 2], ["stab", PK, 1]]),
            s.o("Sert uyarı yap || Issue a stern warning", "İslamabad suyun kesilmesini 'savaş sebebi' ilan etti. || Islamabad called a water cut a 'cause for war'.", [["rel", PK, IN, -4], ["stab", PK, 2]])),
     IN: s.r("Delhi su projelerini 'meşru kalkınma' sayıyor. || Delhi calls the water projects 'legitimate development'.",
            s.o("Projeleri sürdür || Continue the projects", "Hindistan projelerini sürdürdü. || India continued its projects.", [["gold", IN, 1.0], ["rel", IN, PK, -3]]),
            s.o("Su paylaşımı görüşmesi öner || Offer talks on water sharing", "Delhi su paylaşımı görüşmelerini önerdi. || Delhi offered water-sharing talks.", [["rel", IN, PK, 3], ["stab", IN, -1]]))},
    icon="dam", scene="crisis")
done(s)

# ---------------- kor
s = S("kor")
s.m("fuze", 18, "Kıtalararası Füze Testi || An ICBM Test",
    "Kuzey Kore yeni bir kıtalararası balistik füzeyi Japon Denizi'ne doğru fırlattı; füze Japon münhasır ekonomik bölgesine düştü. Güvenlik Konseyi toplanıyor. || North Korea fired a new intercontinental ballistic missile toward the Sea of Japan; it landed in Japan's exclusive economic zone. The Security Council is convening.",
    [["rel", KP, US, -3], ["rel", KP, JP, -3], ["stab", KR, -1]],
    {KR: s.r("Seul savunma ittifakını güçlendirirken diyalog kanalını da korumak istiyor. || Seoul strengthens its defence alliance while trying to keep a dialogue channel open.",
            s.o("Ortak tatbikat yap || Hold joint drills", "Seul ABD ve Japonya ile ortak füze savunma tatbikatı yaptı. || Seoul held joint missile-defence drills with the US and Japan.", [["rel", KR, US, 4], ["rel", KR, JP, 3], ["rel", KR, KP, -3]]),
            s.o("Diyalog teklif et || Offer dialogue", "Seul Pyongyang'a doğrudan görüşme önerdi. || Seoul offered direct talks to Pyongyang.", [["rel", KR, KP, 3], ["stab", KR, -1]])),
     KP: s.r("Kim rejimi testi caydırıcılık olarak sunuyor; yaptırımlar ağırlaşıyor. || The Kim regime frames the test as deterrence; sanctions are growing heavier.",
            s.o("Yeni test için hazırlan || Prepare another test", "Pyongyang yeni bir füze testi hazırlığına girdi. || Pyongyang began preparing another missile test.", [["rel", KP, US, -3], ["stab", KP, 2]]),
            s.o("Moratoryum öner || Offer a moratorium", "Kuzey Kore sınırlı bir test moratoryumu önerdi. || North Korea floated a limited test moratorium.", [["rel", KP, US, 3], ["rel", KP, KR, 2]]))},
    icon="missile", scene="air")
s.m("siber", 72, "Kripto Hırsızlığı || The Crypto Heist",
    "Kuzey Kore bağlantılı bir hacker grubu uluslararası bir kripto borsasından yüz milyonlarca dolar çaldı. Fonlar silah programına gidiyor olabilir; borsa sahibi ülkeler tepkili. || A North Korea-linked hacking group stole hundreds of millions of dollars from an international crypto exchange. The funds may go to the weapons programme; exchange-host countries are angry.",
    [["gold", KP, 2.0], ["rel", KP, US, -2], ["rel", KP, JP, -2]],
    {KP: s.r("Kripto gelir yaptırımlara karşı bir can simidi; tespiti zor. || Crypto income is a lifeline against sanctions and hard to trace.",
            s.o("Operasyonu genişlet || Expand the operation", "Pyongyang siber operasyonlarını genişletti. || Pyongyang expanded its cyber operations.", [["gold", KP, 2.0], ["rel", KP, US, -3]]),
            s.o("Kamuoyundan uzak dur || Keep a low profile", "Pyongyang açıklama yapmadı. || Pyongyang made no statement.", [["stab", KP, 1]])),
     US: s.r("Washington bu para akışını durdurmak için yaptırım ve istihbarat operasyonu planlıyor. || Washington plans sanctions and an intelligence operation to stop the flows.",
            s.o("Yaptırım ve siber operasyon yap || Sanction and run a cyber operation", "ABD borsa ağlarına yönelik ortak operasyon yürüttü. || The US ran a joint operation against exchange networks.", [["rel", US, KP, -3], ["rel", US, JP, 2], ["gold", KP, -1.0]]),
            s.o("Diplomatik baskı yap || Apply diplomatic pressure", "Washington Çin ve Rusya'ya baskı kurdu. || Washington pressed China and Russia.", [["rel", US, CN, -2], ["rel", US, RU, -2]]))},
    icon="warning", scene="crisis", major=False)
done(s)

# ---------------- cau
s = S("cau")
s.m("tcm", 18, "Ortak Ticaret Koridoru || A Joint Trade Corridor",
    "Bakü ve Erivan, Türkiye üzerinden Orta Asya'ya uzanan ortak bir demiryolu ve boru hattı koridoru üzerinde çalışıyor. ABD ve AB projeyi destekliyor; Rusya ve İran kaygılı. || Baku and Yerevan are working on a joint rail and pipeline corridor stretching via Turkey to Central Asia. The US and EU back the project; Russia and Iran are uneasy.",
    [["rel", AZ, AM, 3], ["rel", AZ, TR, 3], ["rel", AM, US, 2]],
    {AM: s.r("Koridor Ermenistan için ekonomik fırsat; ama egemenlik kaygısı var. || The corridor is an economic opportunity for Armenia, but there are sovereignty concerns.",
            s.o("Koridora katıl || Join the corridor", "Erivan koridor anlaşmasını imzaladı. || Yerevan signed the corridor agreement.", [["gold", AM, 1.5], ["rel", AM, AZ, 3], ["rel", AM, RU, -3]]),
            s.o("Şartları görüş || Negotiate conditions", "Erivan egemenlik güvencesi talep etti. || Yerevan demanded sovereignty guarantees.", [["stab", AM, 1], ["rel", AM, AZ, -1]])),
     AZ: s.r("Bakü tarihsel bir fırsat görüyor; ama Ermenistan'ın şartları sert. || Baku sees a historic opportunity, but Armenia's conditions are tough.",
            s.o("Esnek ol || Be flexible", "Bakü bazı taleplerde esnek davrandı. || Baku showed flexibility on some demands.", [["rel", AZ, AM, 3], ["gold", AZ, 1.0]]),
            s.o("Zangezur hattı iste || Insist on the Zangezur line", "Bakü kesintisiz bir geçiş hattı talep etti. || Baku demanded an uninterrupted transit line.", [["rel", AZ, AM, -3], ["rel", AZ, TR, 3]]))},
    icon="trade", scene="trade", major=False)
s.m("sinirci", 90, "Sınır Komisyonu Çıkmazı || Border Commission Deadlock",
    "Sınır komisyonu haritalar üzerinde anlaşamıyor; sınır köyleri ve su kaynakları kilit noktalar. Yeniden bir silahlı olay riski belirdi. || The border commission cannot agree on maps; border villages and water sources are the key issues. The risk of another armed incident has appeared.",
    [["rel", AZ, AM, -2], ["stab", AM, -1]],
    {AM: s.r("Erivan kayıp köylerini ve su kaynaklarını savunmak istiyor. || Yerevan wants to defend its border villages and water sources.",
            s.o("Sınırı güçlendir || Reinforce the border", "Ermenistan sınır birliklerini güçlendirdi. || Armenia reinforced its border troops.", [["troops", AM, 2], ["rel", AM, AZ, -2]]),
            s.o("Üçüncü taraf arabulucu iste || Ask for a third-party mediator", "Erivan AB ve ABD'den arabuluculuk istedi. || Yerevan requested EU and US mediation.", [["rel", AM, US, 3], ["stab", AM, 1]])),
     AZ: s.r("Bakü kazanımlarını pekiştirmek istiyor; yeni bir çatışma uluslararası tepki çeker. || Baku wants to consolidate its gains; a new clash would draw international reaction.",
            s.o("Sınırda sabırlı kal || Stay patient on the border", "Bakü sınırda itidal gösterdi. || Baku showed restraint on the border.", [["stab", AZ, 1], ["rel", AZ, AM, 1]]),
            s.o("Gözdağı ver || Apply pressure", "Bakü sınır hattında tatbikat yaptı. || Baku held drills along the border.", [["rel", AZ, AM, -3], ["troops", AZ, 1]]))},
    icon="border_clash", scene="border")
done(s)

# ---------------- arctic
s = S("arctic")
s.m("buzkiran", 50, "Buzkıran Yarışı || The Icebreaker Race",
    "Rusya, Çin ve Kanada yeni nükleer ve konvansiyonel buzkıran filoları yapıyor; ABD'nin eski buzkıran filosu yetersiz. Kutup güvenliği bir donanma yarışına dönüşüyor. || Russia, China and Canada are building new nuclear and conventional icebreaker fleets; the US icebreaker fleet is outdated. Polar security is turning into a naval race.",
    [["gold", RU, -0.5], ["gold", US, -0.5], ["rel", US, RU, -2]],
    {US: s.r("Kongre buzkıran bütçesini artırmak için baskı görüyor. || Congress faces pressure to raise icebreaker spending.",
            s.o("Buzkıran programı başlat || Start an icebreaker programme", "ABD yeni buzkıran filosu için bütçe ayırdı. || The US funded a new icebreaker fleet.", [["gold", US, -1.0], ["buff", US, "att", 1.05, 10], ["rel", US, CA, 3]]),
            s.o("Müttefiklerden kirala || Lease from allies", "Washington müttefiklerden buzkıran kiralamayı seçti. || Washington opted to lease icebreakers from allies.", [["rel", US, CA, 2], ["rel", US, NO, 2]])),
     RU: s.r("Rusya en büyük buzkıran filosuna sahip; üstünlük ticaret ve askerî nüfuz demek. || Russia has the largest icebreaker fleet; dominance means trade and military influence.",
            s.o("Filoyu genişlet || Expand the fleet", "Rusya yeni nükleer buzkıranlar ekledi. || Russia added new nuclear icebreakers.", [["gold", RU, -1.0], ["rel", RU, NO, -2], ["troops", RU, 1]]),
            s.o("Çin ile ortak program kur || Set up a joint programme with China", "Moskova ve Pekin ortak buzkıran projesi duyurdu. || Moscow and Beijing announced a joint icebreaker project.", [["rel", RU, CN, 4], ["gold", RU, 0.5]]))},
    icon="ship", scene="naval", major=False)
s.m("nadir", 110, "Nadir Toprak Madenleri || Rare-Earth Mines",
    "Grönland ve Kuzey Kanada'daki nadir toprak madenleri için uluslararası ihale açıldı. Çin ve ABD şirketleri yarışırken yerli halklar ve çevre örgütleri itiraz ediyor. || An international tender opened for rare-earth mines in Greenland and northern Canada. Chinese and US firms compete while Indigenous communities and environmental groups object.",
    [["gold", DK, 1.0], ["gold", CA, 1.0], ["rel", DK, US, 1]],
    {DK: s.r("Madenler gelir ve nüfuz getirir; ama Grönland'ın özerkliği hassas. || The mines bring income and leverage, but Greenland's autonomy is sensitive.",
            s.o("Müttefik şirketlere ver || Award to allied firms", "Kopenhag ihaleyi müttefik şirketlere verdi. || Copenhagen awarded the tender to allied firms.", [["rel", DK, US, 4], ["gold", DK, 1.0]]),
            s.o("Yerel yönetime yetki ver || Give authority to local government", "Nuuk madenler üzerinde karar yetkisi aldı. || Nuuk gained decision authority over the mines.", [["stab", DK, -1], ["rel", DK, US, -1]])),
     CA: s.r("Ottawa yerli halklarla istişare yapmak ve çevresel standartları korumak zorunda. || Ottawa must consult Indigenous peoples and uphold environmental standards.",
            s.o("Sıkı çevre standartları koy || Impose strict environmental standards", "Kanada sıkı çevre koşulları getirdi. || Canada imposed strict environmental conditions.", [["stab", CA, 2], ["gold", CA, -0.2]]),
            s.o("Madenciliği hızlandır || Speed up mining", "Ottawa maden izinlerini hızlandırdı. || Ottawa fast-tracked mining permits.", [["gold", CA, 1.5], ["stab", CA, -1]]))},
    icon="trade", scene="trade", major=False)
done(s)

# ---------------- essequibo
s = S("essequibo")
s.m("uydu", 24, "Uydu Görüntüleri || Satellite Images",
    "Uydu görüntüleri Venezuela'nın sınır bölgesinde yeni yollar ve asker yığınağı gösteriyor. Guyana BM ve komşularından destek istiyor; Brezilya sınırında devriye artırıyor. || Satellite images show new roads and a troop build-up on Venezuela's side of the frontier. Guyana seeks UN and neighbour support; Brazil boosts border patrols.",
    [["stab", GY, -1], ["rel", GY, VE, -3], ["rel", BR, VE, -1]],
    {GY: s.r("Küçük ordun var, ama petrol geliri ve uluslararası destek sende. || You have a small army, but oil revenue and international support.",
            s.o("BM ve ABD'den güvence iste || Seek UN and US assurances", "Georgetown BM ve Washington'dan güvence aldı. || Georgetown secured assurances from the UN and Washington.", [["rel", GY, US, 5], ["stab", GY, 2]]),
            s.o("Ordu modernizasyonu başlat || Launch military modernisation", "Guyana petrol gelirini savunmaya ayırdı. || Guyana put oil revenue into defence.", [["troops", GY, 3], ["gold", GY, -1.0]])),
     VE: s.r("Caracas iç siyaseti için Essequibo'yu bir ulusal dava olarak kullanıyor. || Caracas uses Essequibo as a national cause for domestic politics.",
            s.o("Yığınağı sürdür || Continue the build-up", "Caracas sınırdaki askerî varlığını artırdı. || Caracas increased its military presence at the frontier.", [["troops", VE, 2], ["rel", VE, GY, -4], ["rel", VE, BR, -2]]),
            s.o("Müzakere öner || Offer talks", "Caracas Guyana'ya müzakere önerdi. || Caracas offered talks to Guyana.", [["rel", VE, GY, 2], ["stab", VE, -1]]))},
    icon="border_clash", scene="border")
s.m("tahkim", 100, "Uluslararası Adalet Divanı || The International Court of Justice",
    "Adalet Divanı sınır uyuşmazlığına ilişkin esas kararı için duruşma tarihi belirledi. Guyana 1899 tahkim kararına dayanıyor; Venezuela Cenevre Anlaşması'nı savunuyor. || The ICJ set a hearing date for its final ruling on the border dispute. Guyana relies on the 1899 arbitral award; Venezuela defends the Geneva Agreement.",
    [["rel", GY, VE, -2], ["rel", GY, US, 2]],
    {GY: s.r("Hukuki süreç lehinize ama karar sonrası riskler var. || The legal process favours you but post-ruling risks exist.",
            s.o("Karara bağlı kal || Commit to abide by the ruling", "Georgetown Divan kararına uyacağını açıkladı. || Georgetown said it would abide by the ICJ ruling.", [["stab", GY, 2], ["rel", GY, US, 2], ["rel", GY, BR, 2]]),
            s.o("Kararı beklemeden hak iddia et || Press claims ahead of the ruling", "Guyana bölgede varlık gösterdi. || Guyana made a show of presence in the region.", [["troops", GY, 1], ["rel", GY, VE, -3]])),
     VE: s.r("Caracas Divan'ın yetkisini tanımıyor; karar sonrası ne olacak? || Caracas does not recognise the Court's jurisdiction; what happens after the ruling?",
            s.o("Divan'ı reddet || Reject the Court", "Venezuela Divan'ın yetkisini reddetti. || Venezuela rejected the Court's jurisdiction.", [["rel", VE, GY, -4], ["rel", VE, US, -3], ["stab", VE, 1]]),
            s.o("Müzakereye devam et || Continue negotiations", "Caracas ikili görüşme yolunu açık tuttu. || Caracas kept the bilateral channel open.", [["rel", VE, GY, 3], ["stab", VE, -1]]))},
    icon="treaty", scene="pre_court")
done(s)

# ---------------- korea
s = S("korea")
s.m("ittifak", 22, "Seul–Tokyo–Vaşington Üçlü Zirvesi || The Seoul–Tokyo–Washington Summit",
    "Üç müttefik füze uyarı verilerini gerçek zamanlı paylaşma ve ortak tatbikat konusunda anlaştı. Pyongyang bunu 'Asya NATO'su' olarak niteliyor. || The three allies agreed to share missile-warning data in real time and hold joint drills. Pyongyang calls it an 'Asian NATO'.",
    [["rel", KR, JP, 4], ["rel", KR, US, 3], ["rel", KP, KR, -2]],
    {KR: s.r("Seul tarihsel anlaşmazlıklara rağmen Tokyo ile işbirliğini derinleştiriyor. || Seoul deepens cooperation with Tokyo despite historic disputes.",
            s.o("Üçlü işbirliğini derinleştir || Deepen trilateral cooperation", "Seul üçlü işbirliğini kurumsallaştırdı. || Seoul institutionalised the trilateral cooperation.", [["rel", KR, JP, 4], ["rel", KR, US, 3], ["rel", KR, KP, -3]]),
            s.o("Pyongyang ile kanalı koru || Preserve the channel to Pyongyang", "Seul diyalog kanalını açık tuttu. || Seoul kept its dialogue channel open.", [["rel", KR, KP, 3], ["rel", KR, JP, -1]])),
     JP: s.r("Tokyo savunma bütçesini artırıyor; bölgesel ittifak için fırsat. || Tokyo raises defence spending; an alliance chance.",
            s.o("Ortak füze savunması kur || Build joint missile defence", "Tokyo ortak füze savunma sistemini hızlandırdı. || Tokyo accelerated joint missile defence.", [["rel", JP, KR, 4], ["rel", JP, US, 3], ["gold", JP, -0.5]]),
            s.o("Ayrı savunma hattı kur || Build a separate defence line", "Tokyo bağımsız savunma planına odaklandı. || Tokyo focused on its own defence plan.", [["troops", JP, 2], ["rel", JP, KR, -1]]))},
    icon="treaty", scene="peace", major=False)
s.m("aci", 100, "İnsani Yardım Koridoru || A Humanitarian Corridor",
    "Kuzey Kore'deki gıda kıtlığı BM'yi alarma geçirdi; Güney Kore ve Çin yardım koridoru önerdi. Siyasi bir yumuşama için nadir bir fırsat. || Food shortages in North Korea alarmed the UN; South Korea and China proposed an aid corridor. A rare chance for political thaw.",
    [["stab", KP, -2], ["rel", KR, KP, 2]],
    {KP: s.r("Rejim yardımı kabul ederse dışa bağımlılık görünür; reddederse kıtlık büyür. || If the regime accepts aid, dependence shows; if it refuses, famine grows.",
            s.o("Yardımı kabul et || Accept the aid", "Pyongyang insani yardım koridorunu kabul etti. || Pyongyang accepted the humanitarian corridor.", [["stab", KP, 2], ["rel", KP, KR, 3], ["rel", KP, CN, 3]]),
            s.o("Yardımı reddet || Refuse the aid", "Pyongyang yardımı reddetti. || Pyongyang refused the aid.", [["stab", KP, -2], ["rel", KP, KR, -2]])),
     KR: s.r("Seul yardımı politik koz olarak kullanmak ya da saf insani bir jest yapmak seçebilir. || Seoul can use aid as leverage or make a purely humanitarian gesture.",
            s.o("Şartsız yardım yap || Give unconditional aid", "Seul şartsız yardım önerdi. || Seoul offered unconditional aid.", [["rel", KR, KP, 4], ["gold", KR, -0.5]]),
            s.o("Siyasi şart öne sür || Attach political conditions", "Seul yardım için askerî güven artırıcı adım istedi. || Seoul sought confidence-building steps in exchange for aid.", [["rel", KR, KP, -1], ["stab", KR, 1]]))},
    icon="dove", scene="peace", major=False)
done(s)

# ---------------- nile
s = S("nile")
s.m("enerji", 20, "Baraj Elektriği Dağıtımı || Dam Electricity Distribution",
    "Etiyopya barajın elektriğini komşulara satmaya başladı; Sudan ve Kenya ilgili. Mısır ise 'su güvenliği için bağlayıcı anlaşma' ısrarını sürdürüyor. || Ethiopia began selling the dam's electricity to its neighbours; Sudan and Kenya are interested. Egypt keeps insisting on a 'binding agreement for water security'.",
    [["gold", ET, 1.5], ["rel", ET, SD, 3], ["rel", EG, ET, -2]],
    {ET: s.r("Elektrik Etiyopya'ya gelir ve bölgesel nüfuz getiriyor. || Electricity brings Ethiopia income and regional influence.",
            s.o("Komşulara elektrik sat || Sell electricity to neighbours", "Addis Ababa Sudan ve Kenya'ya elektrik satışını artırdı. || Addis Ababa expanded power sales to Sudan and Kenya.", [["gold", ET, 2.0], ["rel", ET, SD, 3], ["rel", ET, EG, -2]]),
            s.o("Mısır'a su garantisi ver || Offer Egypt a water guarantee", "Etiyopya Mısır'a doldurma programı güvencesi verdi. || Ethiopia gave Egypt a filling-schedule assurance.", [["rel", ET, EG, 4], ["stab", ET, 1]])),
     EG: s.r("Kahire barajın sonuçlarına karşı hukuki ve diplomatik hamle arıyor. || Cairo seeks legal and diplomatic moves against the dam's effects.",
            s.o("BM Güvenlik Konseyi'ne başvur || Go to the UN Security Council", "Kahire meseleyi BM Güvenlik Konseyi'ne taşıdı. || Cairo took the matter to the UN Security Council.", [["rel", EG, US, 2], ["rel", EG, ET, -2]]),
            s.o("Sudan'la ortak tutum belirle || Coordinate with Sudan", "Mısır ve Sudan ortak su tutumunda anlaştı. || Egypt and Sudan agreed a joint water position.", [["rel", EG, SD, 4], ["rel", EG, ET, -1]]))},
    icon="dam", scene="crisis", major=False)
s.m("arabulucu", 100, "Tahkim Teklifi || An Arbitration Offer",
    "Afrika Birliği ve Körfez ülkeleri barajın işleyişine dair bağlayıcı bir tahkim önerdi. Mısır masaya oturabilir; Etiyopya tahkimin egemenliğini kısıtlamasından çekiniyor. || The African Union and Gulf states proposed binding arbitration on the dam's operation. Egypt may take a seat; Ethiopia fears it would limit its sovereignty.",
    [["rel", EG, ET, 1], ["rel", ET, SD, 1]],
    {EG: s.r("Tahkim yolu Mısır'a hukuki güvence verebilir; ama zaman alır. || Arbitration may give Egypt legal assurance, but it takes time.",
            s.o("Tahkimi kabul et || Accept arbitration", "Kahire tahkimi kabul etti. || Cairo accepted arbitration.", [["rel", EG, ET, 3], ["rel", EG, SA, 3], ["stab", EG, 1]]),
            s.o("Doğrudan anlaşma iste || Demand a direct agreement", "Kahire doğrudan bağlayıcı anlaşmada ısrar etti. || Cairo insisted on a direct binding agreement.", [["rel", EG, ET, -2], ["stab", EG, 1]])),
     ET: s.r("Addis Ababa egemenlik hakkını koruma gerekçesiyle tahkime mesafeli. || Addis Ababa is wary of arbitration on sovereignty grounds.",
            s.o("Tahkimi kabul et, esnek ol || Accept arbitration and stay flexible", "Etiyopya tahkimi kabul etti. || Ethiopia accepted arbitration.", [["rel", ET, EG, 4], ["stab", ET, -1], ["gold", ET, 1.0]]),
            s.o("Tahkimi reddet || Reject arbitration", "Etiyopya tahkimi reddetti. || Ethiopia rejected arbitration.", [["rel", ET, EG, -3], ["stab", ET, 2]]))},
    icon="treaty", scene="peace")
done(s)

# ---------------- redsea
s = S("redsea")
s.m("konvoy", 18, "Uluslararası Deniz Konvoyu || An International Naval Convoy",
    "Kızıldeniz'de ticari gemiler için çok uluslu bir deniz konvoyu kuruldu. Mısır, Süveyş gelirlerini korumak için kritik; Husiler saldırıları sürdürüyor. || A multinational naval convoy was set up for merchant ships in the Red Sea. Egypt, protecting Suez income, is key; the Houthis keep up attacks.",
    [["gold", EG, 1.0], ["rel", YE, US, -2]],
    {EG: s.r("Süveyş gelirleri düşüyor; konvoya katılmak siyasi risk. || Suez revenue is falling; joining the convoy is politically risky.",
            s.o("Konvoya liman desteği ver || Offer port support to the convoy", "Kahire konvoya liman ve lojistik destek verdi. || Cairo gave the convoy port and logistics support.", [["gold", EG, 1.5], ["rel", EG, US, 3], ["rel", EG, YE, -2]]),
            s.o("Tarafsız kal || Stay neutral", "Mısır konvoyun dışında kaldı. || Egypt stayed out of the convoy.", [["stab", EG, 1], ["gold", EG, -0.5]])),
     YE: s.r("Husiler konvoyu 'saldırganlık' sayıyor; denizdeki varlık gücü korunmalı. || The Houthis call the convoy 'aggression'; sea presence must be preserved.",
            s.o("Saldırıları artır || Escalate attacks", "Husiler konvoya karşı saldırıları artırdı. || The Houthis escalated attacks on the convoy.", [["rel", YE, US, -4], ["gold", EG, -1.0]]),
            s.o("Gemilere geçiş izni ver || Allow selective passage", "Husiler seçili ülke gemilerine geçiş izni verdi. || The Houthis allowed selective passage to some flags.", [["rel", YE, SA, 2], ["gold", YE, 0.5]]))},
    icon="ship", scene="naval")
s.m("liman", 100, "Cibuti–Berbera Rekabeti || The Djibouti–Berbera Rivalry",
    "Kızıldeniz kıyısında yeni limanlar ve deniz üsleri açılıyor: Cibuti, Berbera ve Port Sudan. Körfez ülkeleri, Çin ve Türkiye bölgesel nüfuz için yarışıyor. || New ports and naval bases are opening on the Red Sea coast: Djibouti, Berbera and Port Sudan. Gulf states, China and Turkey compete for regional influence.",
    [["gold", SA, -0.5], ["rel", SA, EG, 1]],
    {SA: s.r("Riyad Kızıldeniz'de ekonomik ve güvenlik sahalarını genişletmek istiyor. || Riyadh wants to widen its economic and security presence in the Red Sea.",
            s.o("Liman ve yatırım ortaklıkları kur || Build port and investment partnerships", "Riyad Kızıldeniz'de liman ortaklıkları kurdu. || Riyadh formed port partnerships on the Red Sea.", [["gold", SA, -1.0], ["rel", SA, EG, 3], ["stab", SA, 1]]),
            s.o("Doğrudan deniz üssü aç || Open a naval base directly", "Suudi Arabistan Kızıldeniz'de deniz üssü açtı. || Saudi Arabia opened a naval base on the Red Sea.", [["troops", SA, 2], ["gold", SA, -1.0]])),
     EG: s.r("Süveyş'in rakipsiz konumu yeni limanlarla zayıflayabilir. || Suez's unrivalled position could weaken with new ports.",
            s.o("Süveyş'i modernize et || Modernise Suez", "Kahire Süveyş'i genişletmeye ve ücretleri indirmeye gitti. || Cairo widened Suez and cut fees.", [["gold", EG, -0.5], ["stab", EG, 1]]),
            s.o("Ortaklık kur || Form partnerships", "Mısır yeni limanlarla ortak işletme planları yaptı. || Egypt drew up joint operation plans with the new ports.", [["gold", EG, 1.0], ["rel", EG, SA, 3]]))},
    icon="trade", scene="trade", major=False)
done(s)

# ---------------- sahel
s = S("sahel")
s.m("wagner", 22, "Yabancı Güvenlik Şirketleri || Foreign Security Contractors",
    "Sahel hükûmetleri Fransa'yı çıkarıp yabancı güvenlik şirketleriyle çalışmaya başladı. Köy katliamları ve insan hakları ihlalleri haberleri BM'yi harekete geçirdi. || Sahel governments expelled France and began working with foreign security contractors. Reports of village massacres and rights abuses prompted UN action.",
    [["rel", ML, FR, -2], ["stab", ML, -1]],
    {ML: s.r("Bamako cihatçılarla savaşmak için dış destek istiyor; ama maliyet siyasi. || Bamako wants outside help against jihadists, but the cost is political.",
            s.o("Yabancı şirketle çalışmaya devam et || Keep the contractor partnership", "Bamako yabancı güvenlik şirketiyle çalışmaya devam etti. || Bamako kept working with the foreign contractor.", [["troops", ML, 2], ["rel", ML, FR, -3], ["rel", ML, DZ, -1]]),
            s.o("Bölgesel güçlerle ortak ordu kur || Build a joint force with regional states", "Mali komşularla ortak güç kurulmasını önerdi. || Mali proposed a joint force with neighbours.", [["rel", ML, BF, 3], ["rel", ML, NE, 3]])),
     FR: s.r("Paris'in Sahel'deki nüfuzu azalıyor; üsler kapanırken ne yapılacak? || Paris's Sahel influence is waning; what to do as bases close?",
            s.o("Üsleri Gine Körfezi'ne kaydır || Shift bases to the Gulf of Guinea", "Fransa askerlerini kıyı ülkelerine kaydırdı. || France shifted forces to coastal states.", [["rel", FR, NG, 3], ["troops", FR, 1]]),
            s.o("Sahel ülkeleriyle diyaloğu koru || Keep dialogue with Sahel states", "Paris Sahel ülkeleriyle diplomatik kanalı açık tuttu. || Paris kept a diplomatic channel open to Sahel states.", [["rel", FR, ML, 2], ["stab", FR, 1]]))},
    icon="warning", scene="crisis")
s.m("yardim", 100, "Kıtlık ve Mülteci Akını || Famine and Refugee Flows",
    "Çatışma ve kuraklık milyonlarca insanı yerinden etti; BM acil insani yardım çağrısı yaptı. Komşu ülkeler sınırlarında mülteci kamplarıyla karşı karşıya. || Conflict and drought displaced millions; the UN issued an urgent humanitarian appeal. Neighbouring countries face refugee camps at their borders.",
    [["stab", NE, -2], ["stab", BF, -2], ["gold", NG, -0.5]],
    {NG: s.r("Nijerya yük paylaşımı için bölgesel bir fon önerebilir. || Nigeria can propose a regional fund for burden sharing.",
            s.o("Bölgesel yardım fonu başlat || Launch a regional aid fund", "Abuja bölgesel insani yardım fonu önerdi. || Abuja proposed a regional humanitarian fund.", [["gold", NG, -1.0], ["rel", NG, NE, 3], ["rel", NG, BF, 3]]),
            s.o("Sınırı kapat || Close the border", "Nijerya sınırı kapattı. || Nigeria closed its border.", [["stab", NG, 1], ["rel", NG, NE, -3]])),
     DZ: s.r("Cezayir kuzey sınırında istikrar istiyor; insani koridora destek verebilir. || Algeria wants stability on its southern border and could support a humanitarian corridor.",
            s.o("İnsani koridor aç || Open a humanitarian corridor", "Cezayir sınırında insani yardım koridoru açtı. || Algeria opened an aid corridor at its border.", [["rel", DZ, ML, 4], ["gold", DZ, -0.5]]),
            s.o("Sınır güvenliğini artır || Raise border security", "Cezayir sınır birliklerini artırdı. || Algeria increased border troops.", [["troops", DZ, 2], ["rel", DZ, ML, -1]]))},
    icon="drought", scene="crisis", major=False)
done(s)

# ---------------- scs
s = S("scs")
s.m("kod", 24, "Davranış Kuralları Müzakeresi || Code of Conduct Talks",
    "ASEAN ve Çin, Güney Çin Denizi'nde bağlayıcı bir davranış kuralları metni üzerinde yeniden görüşüyor. Filipinler ve Vietnam bağlayıcılık ve tahkim hakkında ısrarcı; Pekin esnek metin istiyor. || ASEAN and China are talking again about a binding code of conduct in the South China Sea. The Philippines and Vietnam insist on binding terms and arbitration; Beijing wants a flexible text.",
    [["rel", PH, CN, 1], ["rel", VN, CN, 1]],
    {PH: s.r("Manila 2016 tahkim kararına dayanarak bağlayıcı bir metin istiyor. || Manila wants a binding text anchored in the 2016 arbitral award.",
            s.o("Bağlayıcı metin iste || Demand a binding text", "Manila bağlayıcı metin talep etti. || Manila demanded a binding text.", [["rel", PH, CN, -2], ["rel", PH, US, 2], ["rel", PH, VN, 3]]),
            s.o("Esnek metne razı ol || Settle for a flexible text", "Manila esnek bir metni kabul etti. || Manila accepted a flexible text.", [["rel", PH, CN, 3], ["stab", PH, -1]])),
     CN: s.r("Pekin ikili görüşme ve esnek bir metin istiyor; tahkim kararını tanımıyor. || Beijing wants bilateral talks and a flexible text; it does not recognise the arbitral ruling.",
            s.o("İkili müzakereyi öner || Offer bilateral talks", "Pekin ikili müzakereler önerdi. || Beijing offered bilateral talks.", [["rel", CN, PH, 2], ["rel", CN, VN, 2]]),
            s.o("Tahkim kararını reddet, devriye artır || Reject the ruling and raise patrols", "Pekin tahkim kararını reddedip devriyeyi artırdı. || Beijing rejected the ruling and raised patrols.", [["rel", CN, PH, -4], ["rel", CN, VN, -3], ["troops", CN, 1]]))},
    icon="treaty", scene="peace", major=False)
s.m("balik", 100, "Balıkçılık ve Petrol Rekabeti || The Fishing and Oil Contest",
    "Vietnam ve Malezya yeni petrol sahalarına sondaj yapıyor; Çin sahil güvenliği ve balıkçı filoları bölgede varlık gösteriyor. Balık stokları azalırken gerilim artıyor. || Vietnam and Malaysia are drilling new oil fields; Chinese coast guard and fishing fleets maintain a presence. Fish stocks decline and tensions rise.",
    [["gold", VN, 1.0], ["rel", CN, VN, -3]],
    {VN: s.r("Hanoi hem Çin'le ekonomik bağları korumak hem de petrol haklarını savunmak istiyor. || Hanoi wants to protect economic ties with China and defend its oil rights.",
            s.o("Sondajı sürdür || Continue drilling", "Vietnam sondaj faaliyetini sürdürdü. || Vietnam continued drilling.", [["gold", VN, 1.5], ["rel", VN, CN, -3]]),
            s.o("Ortak geliştirme öner || Propose joint development", "Hanoi ortak geliştirme önerdi. || Hanoi proposed joint development.", [["rel", VN, CN, 3], ["gold", VN, 0.5]])),
     CN: s.r("Pekin 'dokuz çizgi' iddiasına dayanıyor; ama komşularla ticaret değerli. || Beijing relies on its 'nine-dash line' but trade with neighbours is valuable.",
            s.o("Sahil güvenliği gönder || Send the coast guard", "Çin sahil güvenliği sondaj bölgesine gitti. || The Chinese coast guard moved to the drilling zone.", [["rel", CN, VN, -4], ["troops", CN, 1]]),
            s.o("Ortak sondaj görüşmesi başlat || Open joint-drilling talks", "Pekin ortak sondaj görüşmeleri başlattı. || Beijing opened joint drilling talks.", [["rel", CN, VN, 3], ["gold", CN, 0.5]]))},
    icon="ship", scene="naval")
done(s)

# ---------------- kuraklik
s = S("kuraklik")
s.m("kitlik", 20, "Hasat Kaybı || The Harvest Failure",
    "İkinci yıl kuraklık: buğday ve pirinç rekoltesi yüzde 30 düştü. Tahıl ihracatçıları ihracatı kısıyor; fiyatlar uçtu. Büyük şehirlerde gıda protestoları başladı. || A second year of drought: wheat and rice yields fell 30%. Grain exporters are curbing exports; prices soared. Food protests began in major cities.",
    [["gold", EG, -1.0], ["gold", PK, -1.0], ["stab", EG, -2], ["stab", PK, -2]],
    {EG: s.r("Mısır dünyanın en büyük buğday ithalatçılarından; ekmek sübvansiyonu tehlikede. || Egypt is among the world's biggest wheat importers; bread subsidies are in danger.",
            s.o("Stratejik stokları kullan || Use strategic stocks", "Kahire stratejik tahıl stoklarını piyasaya sürdü. || Cairo released strategic grain stocks.", [["stab", EG, 2], ["gold", EG, -0.5]]),
            s.o("Uzun vadeli tedarik anlaşması yap || Sign long-term supply deals", "Kahire uzun vadeli tahıl tedarik anlaşmaları yaptı. || Cairo signed long-term grain supply deals.", [["gold", EG, -1.0], ["rel", EG, RU, 3]])),
     IN: s.r("Hindistan ihracat yasağıyla yurt içi fiyatı koruyabilir; ama ihracatçı ülkelerle ilişkiler zorlanır. || India can protect domestic prices with an export ban but strain ties with importers.",
            s.o("İhracat yasağı koy || Impose an export ban", "Hindistan pirinç ihracatını yasakladı. || India banned rice exports.", [["stab", IN, 2], ["rel", IN, EG, -3], ["rel", IN, PK, -1]]),
            s.o("Kota ile ihracata izin ver || Allow quota-based exports", "Delhi kotalı ihracata izin verdi. || Delhi allowed quota-based exports.", [["rel", IN, EG, 2], ["gold", IN, 0.5]]))},
    icon="drought", scene="crisis")
s.m("goc", 120, "Büyük Göç Dalgası || The Great Migration Wave",
    "Kuraklıktan kaçanlar sınırlara yöneldi; milyonlarca iklim mültecisi yeni topraklar arıyor. Ülkeler sınırları kapatırken uluslararası bir mülteci anlaşması çağrısı yükseliyor. || People fleeing the drought headed for borders; millions of climate refugees look for new lands. Countries close their frontiers as calls for an international refugee compact grow.",
    [["stab", TR, -2], ["stab", EG, -2], ["stab", IN, -1]],
    {TR: s.r("Türkiye hem transit hem hedef ülke; kapasite zorlanıyor. || Turkey is both a transit and destination state; capacity is strained.",
            s.o("Sınırları kontrollü aç || Open borders in a controlled way", "Ankara sınırları kontrollü açıp uluslararası mali destek istedi. || Ankara opened borders in a controlled way and asked for international funding.", [["gold", TR, 0.5], ["rel", TR, DE, 3], ["stab", TR, -1]]),
            s.o("Sınırı güçlendir || Reinforce the border", "Türkiye sınır güvenliğini artırdı. || Turkey strengthened border security.", [["troops", TR, 2], ["rel", TR, DE, -2]])),
     IN: s.r("Hindistan kendi nüfusu ve komşu göçüyle karşı karşıya. || India faces its own population pressure and cross-border migration.",
            s.o("Bölgesel göç anlaşması öner || Propose a regional migration compact", "Delhi bölgesel göç anlaşması önerdi. || Delhi proposed a regional migration compact.", [["rel", IN, PK, 2], ["rel", IN, EG, 1], ["stab", IN, 1]]),
            s.o("Sınır çitlerini güçlendir || Reinforce border fencing", "Hindistan sınır çitlerini güçlendirdi. || India reinforced border fencing.", [["troops", IN, 2], ["rel", IN, PK, -2]]))},
    icon="drought", scene="border", major=False)
done(s)
print("tamam")

#!/usr/bin/env python3
"""Yerleşik gerçek-dünya senaryoları için olay kartları: ukr, twn, irn, ind, kor, cau -> data/scn_moments/<id>.json
2024-2026 gelişmelerinden (müzakere turları, enerji altyapısı saldırıları, Hürmüz, Tayvan tatbikatları, Hindistan-Pakistan krizi,
Güney Kafkasya barış süreci) esinlenir; 2027 başlangıçlı hayalî ileri sarma olarak yazılmıştır. Çalıştır: python3 tools/data/gen_scn_a.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scn_kit import Scn

US = "United States of America"; RU = "Russia"; UA = "Ukraine"; PL = "Poland"; TR = "Turkey"; DE = "Germany"; CN = "China"; TW = "Taiwan"
JP = "Japan"; KR = "South Korea"; KP = "North Korea"; IR = "Iran"; IL = "Israel"; SA = "Saudi Arabia"; IN = "India"; PK = "Pakistan"
AZ = "Azerbaijan"; AM = "Armenia"

# ------------------------------------------------------------------ ukr: Doğu Cephesi
s = Scn("ukr")
s.m("abudabi", 6, "Abu Dabi Görüşmeleri || The Abu Dhabi Talks",
    "ABD arabuluculuğunda Rusya ve Ukrayna heyetleri Abu Dabi'de yeniden masaya oturdu; esir takası ve 'gerilimi azaltma adımları' konuşuluyor, ama Moskova toprak ve NATO taleplerinden vazgeçmiyor. Avrupalı güçler masadan dışlandı. || Russian and Ukrainian delegations sat down again in Abu Dhabi under US mediation; prisoner swaps and 'de-escalation steps' are on the table, but Moscow will not drop its territorial and NATO demands. The European powers were left out of the room.",
    [["rel", RU, UA, 3], ["stab", UA, 1]],
    {UA: s.r("Kiev masada ama güvenlik garantisi şartı net: NATO 5. madde benzeri bağlayıcı bir taahhüt. ABD 'NATO'ya benzer bir şey' öneriyor. || Kyiv is at the table but its condition is clear: a binding Article 5-style guarantee. Washington offers 'something similar to NATO'.",
            s.o("Garantisiz anlaşmayı reddet || Refuse a deal without guarantees", "Bağlayıcı güvenlik garantisi olmadan Ukrayna toprak vermeyecek. || Ukraine will cede no land without a binding security guarantee.", [["stab", UA, 2], ["rel", UA, RU, -4]]),
            s.o("ABD formülüne evet de || Accept the US formula", "Kiev ABD'nin güvenlik taahhüdünü kabul etti; müzakereler hız kazandı. || Kyiv accepted the US security pledge; talks gained speed.", [["rel", UA, US, 6], ["rel", UA, RU, 2], ["stab", UA, -1]])),
     RU: s.r("Rus heyeti 'ancak kendi şartlarımızla kazanınca barış' diyor; cephe ise yerinde sayıyor ve rafineri vuruşları bütçeyi zorluyor. || The Russian delegation says 'peace only on our terms'; the front is stalling and refinery strikes strain the budget.",
            s.o("Maksimalist talepleri sürdür || Keep the maximalist demands", "Moskova toprak ve NATO geri çekilmesi talebinde ısrar etti. || Moscow insisted on territory and a NATO rollback.", [["rel", RU, US, -3], ["stab", RU, 1]]),
            s.o("Ateşkes için taviz ver || Offer concessions for a ceasefire", "Rusya sınırlı bir ateşkes ve enerji saldırılarına ara önerdi. || Russia proposed a limited ceasefire and a pause in energy strikes.", [["rel", RU, US, 5], ["rel", RU, UA, 3], ["stab", RU, 1]])),
     US: s.r("Washington arabulucu ama Avrupa'yı ve Kongre'yi de idare etmek zorunda; yaptırımlar mı gevşesin, sıkılaşsın mı? || Washington mediates but must handle Europe and Congress too: should sanctions ease or tighten?",
            s.o("Yaptırımları sıkılaştır || Tighten sanctions", "ABD, Rus enerjisine yönelik yaptırımları artırdı. || The US stepped up sanctions on Russian energy.", [["rel", US, RU, -6], ["rel", US, UA, 4]]),
            s.o("Anlaşma için esneklik göster || Show flexibility for a deal", "Beyaz Saray Moskova'ya yaptırım gevşetmesinin kapısını aralık tuttu. || The White House kept the door open to sanctions relief.", [["rel", US, RU, 5], ["rel", US, UA, -3]]), minor=True)},
    icon="treaty", scene="peace")
s.m("enerji", 20, "Enerji Altyapısı Vuruluyor || Strikes on the Power Grid",
    "Rusya balistik füze ve yüzlerce dronla Ukrayna enerji santrallerini ve trafo merkezlerini vurdu; Ukrayna'nın uzun menzilli dronları da Rus rafinerilerini ve limanlarını hedef alıyor. Kış yaklaşırken iki taraf da birbirinin ekonomisine zarar vermeye çalışıyor. || Russia hit Ukrainian power plants and substations with ballistic missiles and hundreds of drones, while Ukraine's long-range drones strike Russian refineries and ports. With winter approaching, each side tries to hurt the other's economy.",
    [["stab", UA, -3], ["stab", RU, -2], ["gold", RU, -1.0]],
    {UA: s.r("Karanlık şehirler, yarım kalan ısıtma: halk dayanıklı ama enerji kıtlığı moral ve sanayiyi vuruyor. || Dark cities and half-working heating: the public is resilient, but the energy shortage hits morale and industry.",
            s.o("Hava savunmasını şehirlere yığ || Mass air defence on the cities", "Hava savunması şehirlere kaydırıldı; cephede açıklar doğdu. || Air defence shifted to the cities, opening gaps at the front.", [["stab", UA, 2], ["troops", UA, -3]]),
            s.o("Rus rafinerilerine misilleme || Retaliate against Russian refineries", "Ukrayna dronları rafineri ve petrol depolarını vurdu. || Ukrainian drones hit refineries and oil depots.", [["gold", RU, -1.5], ["stab", UA, -1], ["rel", UA, US, -1]])),
     RU: s.r("Rafineri vuruşları yakıt kıtlığına ve bütçe açığına yol açıyor; ama enerji saldırıları da Ukrayna'yı yıpratıyor. || Refinery strikes cause fuel shortages and a budget gap, but the energy campaign wears Ukraine down.",
            s.o("Enerji saldırılarını artır || Escalate the energy strikes", "Rus füzeleri Ukrayna şebekesini yeniden vurdu. || Russian missiles struck the Ukrainian grid again.", [["stab", UA, -3], ["rel", RU, US, -3], ["stab", RU, -1]]),
            s.o("Rafineri savunmasını güçlendir || Reinforce refinery defences", "Rusya hava savunmasını rafinerilere kaydırdı. || Russia moved air defences to its refineries.", [["stab", RU, 2], ["gold", RU, -0.5]])),
     PL: s.r("Polonya sınırında dron parçaları düşüyor; NATO'nun doğu kanadı alarmda. || Drone debris falls on Polish soil; NATO's eastern flank is on alert.",
            s.o("NATO 4. maddeyi tetikle || Invoke NATO Article 4", "Varşova NATO istişaresi çağrısı yaptı. || Warsaw called for NATO consultations.", [["rel", PL, RU, -6], ["rel", PL, US, 3]]),
            s.o("Hava sahasını kapat, sakin kal || Close the airspace and stay calm", "Polonya sınır hava savunmasını artırdı. || Poland reinforced border air defence.", [["stab", PL, 1]]), minor=True)},
    icon="missile", scene="air")
s.m("doktor", 44, "Doğu Dönüm Noktası: Donbas'ın Son Çeyreği || The Last Quarter of Donbas",
    "Rusya Donbas'ın Ukrayna elindeki son bölümünü almak için kış taarruzuna hazırlanıyor; kayıp rakamları rekor kırıyor ama net kazanım küçük. Kiev ise dron duvarı ve tahkimatlarla direniyor. || Russia prepares a winter offensive for the last part of Donbas still held by Ukraine; casualty figures hit records while net gains stay small. Kyiv holds on with a drone wall and fortified lines.",
    [["buff", RU, "att", 1.1, 8], ["troops", RU, -2], ["troops", UA, -2]],
    {RU: s.r("Kış taarruzu pahalı olacak; yine de siyasî olarak 'kazanıyoruz' görüntüsü gerekiyor. || The winter offensive will be costly, yet politics demand a picture of winning.",
            s.o("Genel taarruz || Launch the general offensive", "Rus piyadesi Donbas'ta çok cepheli saldırıya geçti. || Russian infantry attacked on several axes in Donbas.", [["buff", RU, "att", 1.15, 8], ["troops", RU, -3], ["stab", RU, -1]]),
            s.o("Kuşatma ve topçu ile yıpratma || Grind with artillery and encirclement", "Rusya yavaş ilerleyip topçu yığınağıyla yıpratma taktiğini seçti. || Russia chose a slow advance and an artillery grind.", [["troops", RU, -1], ["stab", RU, 1]])),
     UA: s.r("Cephe hattı iyi tahkim edildi ama yedek askerler azalıyor; dron duvarı Rus piyadesini hâlâ durduruyor. || The line is well fortified but reserves are thin; the drone wall still stops Russian infantry.",
            s.o("Esnek savunma: gerektiğinde geri çekil || Elastic defence: trade space for lives", "Ukrayna birliklerini kayıp vermeden geri çekmeyi tercih etti. || Ukraine chose to pull back rather than take losses.", [["buff", UA, "def", 1.1, 8], ["stab", UA, -1]]),
            s.o("Her mevziyi tut || Hold every position", "Kiev geri çekilme emri vermedi; kayıplar arttı. || Kyiv refused to order withdrawals; losses rose.", [["buff", UA, "def", 1.2, 8], ["troops", UA, -3], ["stab", UA, 1]]))},
    icon="tank", scene="pre_assault")
s.m("takas", 80, "Büyük Esir Takası || The Great Prisoner Swap",
    "Binlerce esirin değiştirildiği yeni bir takas yapıldı; iki başkent de 'ilerleme' dedi ama ateşkes hâlâ yok. Müzakerecilere göre bir sonraki aşama enerji ateşkesi. || A new swap exchanged thousands of prisoners; both capitals spoke of 'progress', yet there is still no ceasefire. Negotiators say the next step is an energy truce.",
    [["rel", RU, UA, 4], ["stab", UA, 1], ["stab", RU, 1]],
    {UA: s.r("Takas halkı rahatlattı; şimdi enerji ateşkesi ve güvenlik garantileri için baskı zamanı. || The swap eased the public; now is the time to press for an energy truce and security guarantees.",
            s.o("Enerji ateşkesi öner || Propose an energy truce", "Kiev karşılıklı enerji ateşkesi önerdi. || Kyiv proposed a mutual energy truce.", [["peace", UA, RU], ["rel", UA, RU, 4]]),
            s.o("Cepheyi güçlendirmeye devam et || Keep reinforcing the front", "Ukrayna Batı'dan yeni silah talebini artırdı. || Ukraine pressed the West for more weapons.", [["troops", UA, 3], ["rel", UA, US, 2]])),
     RU: s.r("Takas pazarlıkta koz; Moskova enerji ateşkesini 'yaptırım gevşetmesi' karşılığı kabul edebilir. || The swap is a bargaining chip; Moscow might accept an energy truce for sanctions relief.",
            s.o("Enerji ateşkesine razı ol || Accept an energy truce", "Rusya geçici bir enerji ateşkesini kabul etti. || Russia accepted a temporary energy truce.", [["peace", RU, UA], ["rel", RU, US, 4], ["stab", RU, 2]]),
            s.o("Reddet, savaşı sürdür || Refuse and fight on", "Kremlin, ateşkesi 'oyalama' diye niteledi. || The Kremlin called the truce a 'stalling tactic'.", [["rel", RU, US, -3]]))},
    icon="dove", scene="peace", major=False)
s.save()

# ------------------------------------------------------------------ twn: Boğaz Krizi
s = Scn("twn")
s.m("tatbikat", 5, "Adalet Misyonu Tatbikatı || Joint Exercise 'Justice Mission'",
    "Çin ordusu Tayvan'ı çevreleyen iki günlük büyük bir tatbikat başlattı: kara, deniz, hava ve roket birlikleri ablukayı prova ediyor; adaya yaklaşan Çin gemi ve uçak sayısı rekor. ABD silah satışı Pekin'i öfkelendirdi. || China's military launched a two-day exercise ringing Taiwan: army, navy, air and rocket forces rehearse a blockade, and the number of ships and aircraft near the island hit a record. A US arms sale had angered Beijing.",
    [["stab", TW, -2], ["rel", CN, US, -3], ["rel", CN, TW, -4]],
    {TW: s.r("Limanlar ve hava sahası saatlerce kısıtlandı; borsa düştü. Savunma bakanlığı seferberlik hazırlığı soruyor. || Ports and airspace were restricted for hours and stocks fell. The defence ministry asks about mobilisation.",
            s.o("Alarma geç, yedekleri çağır || Raise the alert and call reservists", "Tayvan alarm seviyesini yükseltti. || Taiwan raised its alert level.", [["troops", TW, 4], ["stab", TW, 1], ["rel", TW, CN, -3]]),
            s.o("Soğukkanlı kal, diplomasi || Stay calm and use diplomacy", "Taipei gerginliği tırmandırmamak için temkinli konuştu. || Taipei spoke cautiously to avoid escalation.", [["stab", TW, 1], ["rel", TW, CN, 1]])),
     CN: s.r("Tatbikat 'bağımsızlıkçı güçlere' mesaj; ama aşırı baskı Japonya ve ABD'yi daha da yakınlaştırıyor. || The drill is a message to 'separatist forces'; but too much pressure pushes Japan and the US closer.",
            s.o("Ablukayı prova et (tarihî) || Rehearse the blockade (historical)", "PLA Tayvan çevresinde kara, deniz, hava ve roket tatbikatı yaptı. || The PLA drilled army, navy, air and rocket forces around Taiwan.", [["buff", CN, "att", 1.05, 6], ["rel", CN, US, -4], ["rel", CN, JP, -4]]),
            s.o("Tatbikatı sınırlı tut || Keep the drill limited", "Pekin tatbikatı kısa tuttu ve diplomatik kanalı açık bıraktı. || Beijing kept the drill short and left diplomacy open.", [["rel", CN, US, 2], ["rel", CN, TW, 1]])),
     US: s.r("Kongre Tayvan'a yeni bir silah paketi onayladı; Beyaz Saray Pekin'le ticaret görüşmelerini de korumak istiyor. || Congress approved a new Taiwan arms package; the White House also wants to protect trade talks with Beijing.",
            s.o("Silah satışını sürdür || Keep the arms sales going", "ABD Tayvan'a yeni silah teslimatını onayladı. || The US cleared new weapon deliveries to Taiwan.", [["rel", US, TW, 5], ["rel", US, CN, -4]]),
            s.o("Pekin'le zirve için sessiz kal || Stay quiet ahead of a summit with Beijing", "Washington açıklamaları yumuşattı. || Washington toned down its statements.", [["rel", US, CN, 4], ["rel", US, TW, -3]]), minor=True)},
    icon="jet", scene="pre_war")
s.m("ablukaprova", 28, "Karantina Kuşatması || The 'Quarantine' Blockade",
    "Çin sahil güvenliği Tayvan limanlarına gelen kargo gemilerini 'denetlemeye' başladı; resmen abluka değil ama enerji sevkiyatı yavaşlıyor. Tayvan'ın LNG stoku haftalık hesaba bağlı. || The Chinese coast guard began 'inspecting' cargo ships heading for Taiwan's ports; it is not a formal blockade, yet energy deliveries slow down. Taiwan's LNG stocks are counted in weeks.",
    [["gold", TW, -1.5], ["stab", TW, -3], ["rel", CN, US, -3]],
    {TW: s.r("LNG ve gıda gemileri bekliyor. Karantina 'savaş eylemi' mi, yoksa polis işlemi mi? Cevabın tüm dünyayı ilgilendiriyor. || LNG and food ships are waiting. Is the 'quarantine' an act of war or a police action? Your answer concerns the whole world.",
            s.o("Müttefiklerden eskort iste || Ask allies for escorts", "Tayvan, ABD ve Japonya'dan konvoy eskortu istedi. || Taiwan asked the US and Japan for convoy escorts.", [["rel", TW, US, 4], ["rel", TW, JP, 4], ["rel", TW, CN, -4]]),
            s.o("Denetimi kabul et, pazarlık yap || Accept inspections and bargain", "Taipei geçici bir denetim düzenini kabul etti. || Taipei accepted a temporary inspection regime.", [["stab", TW, -1], ["rel", TW, CN, 3]])),
     CN: s.r("Kuşatma kontrollü bir baskı; ama bir kaza (çarpışma, vurulma) krizi savaşa çevirebilir. || The squeeze is controlled pressure; but an accident (a collision or a shot) could turn the crisis into war.",
            s.o("Baskıyı artır || Raise the pressure", "Çin sahil güvenliği devriyelerini artırdı. || China's coast guard added patrols.", [["gold", TW, -1], ["rel", CN, JP, -3], ["rel", CN, US, -3]]),
            s.o("Gevşet ve müzakere iste || Ease off and ask for talks", "Pekin denetimleri azaltıp 'çerçeve görüşme' önerdi. || Beijing eased inspections and offered 'framework talks'.", [["rel", CN, TW, 3], ["rel", CN, US, 2]])),
     JP: s.r("Tokyo 'Tayvan olası bir kriz Japonya'nın da krizi' diyor; Yonaguni'ye füze bataryası konuyor. || Tokyo says a Taiwan contingency is a Japan contingency; missile batteries go to Yonaguni.",
            s.o("Yonaguni'yi güçlendir || Reinforce Yonaguni", "Japonya Güneybatı Adaları'na füze ve radar yığdı. || Japan moved missiles and radar to the Southwest Islands.", [["rel", JP, CN, -5], ["rel", JP, US, 3], ["stab", JP, 1]]),
            s.o("Çin'le temas kanalı aç || Open a channel with China", "Tokyo Pekin'le krizi azaltma görüşmesi önerdi. || Tokyo proposed crisis-reduction talks with Beijing.", [["rel", JP, CN, 4]]), minor=True)},
    icon="border_clash", scene="pre_siege")
s.m("secim", 70, "Seçim ve Çıkmaz || Elections and Stalemate",
    "Tayvan'da yerel seçimler yaklaşırken Pekin hem sopa hem havuç gösteriyor: ticaret kolaylıkları ile askerî baskıyı birlikte uyguluyor. Boğaz'da iki taraf da ilk vuran olmak istemiyor. || As local elections approach in Taiwan, Beijing uses both stick and carrot: trade concessions along with military pressure. In the Strait neither side wants to be the first to fire.",
    [["stab", TW, -1], ["rel", CN, TW, 2]],
    {TW: s.r("Halk bölünmüş: bir kesim savunma harcamasını, diğer kesim Pekin'le ticareti istiyor. || The public is split: some want more defence spending, others want trade with Beijing.",
            s.o("Savunma bütçesini artır || Raise the defence budget", "Taipei savunma harcamasını GSYH'nin %3,5'ine çıkarmayı vaat etti. || Taipei pledged defence spending of 3.5% of GDP.", [["troops", TW, 3], ["gold", TW, -0.5], ["rel", TW, US, 3]]),
            s.o("Ticaret ve temas çizgisi || Trade and contact line", "Taipei Pekin'le ekonomik temas kanalı önerdi. || Taipei proposed an economic contact channel with Beijing.", [["gold", TW, 1.0], ["rel", TW, CN, 4], ["rel", TW, US, -2]]))},
    icon="flag", scene="trade", major=False)
s.save()

# ------------------------------------------------------------------ irn: Körfez Ateşi
s = Scn("irn")
s.m("hurmuz", 5, "Hürmüz'de Gemi Vuruldu || Ships Hit in Hormuz",
    "Basra Körfezi'nde bir tanker saldırıya uğradı; sigorta primleri tırmandı ve Hürmüz Boğazı'ndan geçen günlük petrol sevkiyatı azaldı. İran 'boğaz bizim kontrolümüzde' diyor; ABD ve Körfez ülkeleri deniz eskortunu artırıyor. || A tanker was attacked in the Gulf; insurance premiums soared and daily oil flows through the Strait of Hormuz fell. Iran says the strait is under its control; the US and Gulf states are adding naval escorts.",
    [["gold", IR, -0.5], ["rel", IR, US, -4], ["stab", SA, -1]],
    {IR: s.r("Boğazdaki baskı en güçlü kozun; ama tam kapama hem ekonomini hem Çin'le ilişkini vurur. Elektrik şebekesi savaş hasarıyla zaten kırılgan. || Pressure in the strait is your strongest card, but a full closure hits your own economy and ties with China. The grid is already fragile after war damage.",
            s.o("Boğazı kısmen kapat || Partially close the strait", "İran Hürmüz'de geçişleri kısıtladı; petrol fiyatları fırladı. || Iran restricted transit in Hormuz; oil prices jumped.", [["rel", IR, US, -6], ["rel", IR, SA, -4], ["stab", IR, -2], ["gold", IR, 1.0]]),
            s.o("Arabulucular aracılığıyla müzakere || Negotiate through mediators", "Katar ve Umman heyetleri Tahran'a gitti. || Qatari and Omani envoys travelled to Tehran.", [["rel", IR, US, 3], ["rel", IR, SA, 2], ["stab", IR, 1]])),
     US: s.r("Donanman boğazı açık tutmaya çalışıyor; enflasyon ve benzin fiyatları iç siyasette yük. || Your navy tries to keep the strait open; inflation and fuel prices weigh on domestic politics.",
            s.o("Deniz eskortu ve abluka || Escorts and a naval blockade", "ABD donanması konvoy eskortu başlattı ve İran limanlarına baskı uyguladı. || The US Navy began convoy escorts and pressed Iranian ports.", [["rel", US, IR, -6], ["rel", US, SA, 3], ["gold", US, -0.5]]),
            s.o("Müzakere masasını aç || Open the negotiating table", "Washington dolaylı müzakereye razı oldu. || Washington agreed to indirect talks.", [["rel", US, IR, 4], ["stab", US, 1]])),
     SA: s.r("Körfez altyapınız İran füzelerinin ve dronlarının menzilinde; ABD üsleriyle ilişkiniz hassas. || Your Gulf infrastructure is within range of Iranian missiles and drones; ties with US bases are delicate.",
            s.o("ABD ile savunma ortaklığını artır || Deepen the US defence partnership", "Riyad hava savunmasını ABD ile entegre etti. || Riyadh integrated its air defence with the US.", [["rel", SA, US, 4], ["rel", SA, IR, -4]]),
            s.o("Tarafsız kal, arabuluculuk yap || Stay neutral and mediate", "Riyad Tahran'la doğrudan temas kurdu. || Riyadh opened direct contact with Tehran.", [["rel", SA, IR, 4], ["rel", SA, US, -2], ["stab", SA, 1]]), minor=True)},
    icon="warning", scene="crisis")
s.m("nukleer", 24, "Zenginleştirilmiş Uranyumun Kaderi || The Fate of the Enriched Uranium",
    "Müzakerelerin tıkandığı nokta: İran'ın zenginleştirilmiş uranyum stoku nerede ve kimin elinde? Tahran 'konu gündemde değil' diyor, ABD ve İsrail ise stok çıkarılana dek baskıyı sürdüreceğini söylüyor. || The sticking point in talks: where is Iran's enriched uranium and who holds it? Tehran says it is 'not on the agenda'; the US and Israel say they will keep up pressure until the stockpile is removed.",
    [["rel", IR, IL, -3], ["rel", IR, US, -2]],
    {IR: s.r("Stok sizin pazarlık gücünüz; yurtdışına çıkarmak yaptırım gevşemesi getirir ama caydırıcılığınızı azaltır. || The stockpile is your leverage; shipping it out brings sanctions relief but weakens deterrence.",
            s.o("Stoku yurtdışına gönder || Ship the stock abroad", "İran, stokun üçüncü bir ülkeye devri için ilkesel onay verdi. || Iran agreed in principle to transfer the stock to a third country.", [["rel", IR, US, 6], ["rel", IR, IL, 2], ["gold", IR, 2.0], ["stab", IR, -1]]),
            s.o("Reddet ve pazarlığı uzat || Refuse and drag on", "Tahran stok konusunu görüşme dışı bıraktı. || Tehran put the stockpile off the table.", [["rel", IR, US, -4], ["rel", IR, IL, -4], ["stab", IR, 1]])),
     IL: s.r("Siz stoğun çıkarılmasını ya da yok edilmesini istiyorsunuz; yeni saldırı ABD'yi bağlar mı? || You want the stockpile removed or destroyed; would a new strike bind the US?",
            s.o("Yeni saldırı planı hazırla || Prepare a new strike plan", "İsrail yeni bir hava harekâtı planını ABD'ye sundu. || Israel presented a new air-strike plan to Washington.", [["rel", IL, IR, -6], ["rel", IL, US, -1], ["buff", IL, "att", 1.05, 8]]),
            s.o("ABD müzakeresine güven || Trust the US negotiation", "Kudüs Washington'a zaman tanıdı. || Jerusalem gave Washington time.", [["rel", IL, US, 3], ["rel", IL, IR, -1]])),
     US: s.r("Başkan 'kalıcı bir anlaşma' istiyor; Kongre ve müttefikler farklı yönlere çekiyor. || The President wants a 'permanent deal'; Congress and allies pull in different directions.",
            s.o("Kalıcı anlaşma için tavizler ver || Offer concessions for a permanent deal", "ABD yaptırımların kademeli gevşemesini önerdi. || The US offered phased sanctions relief.", [["rel", US, IR, 6], ["rel", US, IL, -3], ["rel", US, SA, -2]]),
            s.o("Maksimum baskıyı sürdür || Keep up maximum pressure", "Washington yeni yaptırımlar ilan etti. || Washington announced new sanctions.", [["rel", US, IR, -5], ["rel", US, IL, 3]]), minor=True)},
    icon="treaty", scene="pre_court")
s.m("sebeke", 52, "Şebeke Çöküyor || The Grid Falters",
    "İran'da elektrik rasyonu başladı: savaş hasarı, yaptırımlar ve yaz sıcağı şebekeyi çökertiyor; fabrikalar kapanıyor ve sokak protestoları artıyor. Tahran'da yeni lider kadrosu iç kontrolü sıkılaştırıyor. || Electricity rationing began in Iran: war damage, sanctions and summer heat are crippling the grid; factories shut and street protests grow. The new leadership in Tehran tightens internal control.",
    [["stab", IR, -4], ["gold", IR, -1.0]],
    {IR: s.r("Halk ışıksız ve susuz; ordu ve Devrim Muhafızları iç düzeni mi sağlayacak yoksa yatırım mı? || The public lacks light and water; will the army and the Guards police the interior, or will you invest?",
            s.o("Güvenlik güçleriyle bastır || Suppress with security forces", "Gösteriler sert biçimde dağıtıldı; ihtilal söylentileri arttı. || Demonstrations were dispersed harshly; revolt rumours grew.", [["stab", IR, 1], ["stab", IR, -2]]),
            s.o("Enerji yatırımı ve dışarıdan elektrik || Energy investment and imported power", "Tahran Türkiye ve Irak'tan elektrik ithalatı için anlaştı. || Tehran agreed to import electricity from Turkey and Iraq.", [["gold", IR, -1.5], ["stab", IR, 3], ["rel", IR, TR, 4]]))},
    icon="protest", scene="crisis", major=False)
s.save()

# ------------------------------------------------------------------ ind: Himalaya Gölgesi
s = Scn("ind")
s.m("pahalgam", 4, "Pehelgam Saldırısı ve 'Sindoor' || The Pahalgam Attack and 'Sindoor'",
    "Keşmir'de turistlere yönelik silahlı saldırı 26 kişinin ölümüne yol açtı. Yeni Delhi İndus Suları Antlaşması'nı askıya aldı, sınırı kapattı ve misilleme yolunu açık tuttu; İslamabad 'su akışının durdurulması savaş eylemidir' dedi. || An armed attack on tourists in Kashmir killed 26 people. New Delhi suspended the Indus Waters Treaty, closed the border and kept retaliation open; Islamabad said stopping the water would be an act of war.",
    [["rel", IN, PK, -8], ["stab", PK, -1]],
    {IN: s.r("Halk karşılık istiyor. Hava ve füze vuruşları kontrollü kalırsa tırmanma sınırlı olabilir; ama nükleer gölge hep orada. || The public wants retaliation. Air and missile strikes can stay limited, but the nuclear shadow is always there.",
            s.o("Sınır ötesi hava harekâtı (tarihî) || Cross-border air strikes (historical)", "Hindistan Pakistan'daki 9 hedefe füze ve hava saldırısı yaptı. || India struck nine targets in Pakistan with missiles and aircraft.", [["war", IN, PK, "solo"], ["buff", IN, "att", 1.1, 6], ["rel", IN, PK, -10], ["stab", IN, 2]]),
            s.o("Su ve ticaret yaptırımları || Water and trade sanctions", "Delhi İndus'taki baraj işlemlerini sınırladı, ticareti kesti. || Delhi curtailed dam operations on the Indus and cut trade.", [["rel", IN, PK, -6], ["gold", PK, -1.0], ["rel", IN, CN, -1]])),
     PK: s.r("Orduyu ve halkı birleştiren dış tehdit; ama ekonomi kırılgan ve IMF programı gölgede. Çin'in desteği kritik. || An external threat unites army and public; yet the economy is fragile with an IMF programme in the background. Chinese support is critical.",
            s.o("Sert karşılık ver || Retaliate firmly", "Pakistan topçu ve insansız hava araçlarıyla misilleme yaptı. || Pakistan retaliated with artillery and drones.", [["war", PK, IN, "solo"], ["buff", PK, "def", 1.1, 6], ["rel", PK, IN, -8], ["rel", PK, CN, 3]]),
            s.o("Soruşturma teklif et, tırmanma önle || Offer an inquiry and avoid escalation", "İslamabad tarafsız soruşturma önerdi ve Körfez'den arabuluculuk istedi. || Islamabad offered a neutral inquiry and sought Gulf mediation.", [["rel", PK, IN, 2], ["rel", PK, US, 3], ["stab", PK, -1]])),
     CN: s.r("Pekin Pakistan'ın yakın müttefiki; ama Hindistan'la ilişkileri düzeltme çabasında. || Beijing is Pakistan's close ally but is trying to mend ties with India.",
            s.o("Pakistan'a diplomatik ve askerî destek || Back Pakistan diplomatically and militarily", "Çin Pakistan'a istihbarat ve hava savunma desteği verdi. || China gave Pakistan intelligence and air-defence support.", [["rel", CN, PK, 6], ["rel", CN, IN, -5]]),
            s.o("İki tarafa sakin ol çağrısı || Call on both sides to calm down", "Pekin iki tarafı da itidale çağırdı. || Beijing urged restraint on both.", [["rel", CN, IN, 2], ["rel", CN, PK, -1]]), minor=True)},
    icon="border_clash", scene="border")
s.m("ateskes", 10, "Dört Günlük Savaşın Ateşkesi || The Four-Day War Ceasefire",
    "Karşılıklı hava ve füze vuruşlarının ardından, ABD'nin telefon diplomasisi ve Körfez arabuluculuğuyla ateşkes ilan edildi; ancak her iki taraf da 'zaferi' kendine yazdı. Su sorunu ve Keşmir çözümsüz. || After exchanges of air and missile strikes, a ceasefire was declared through US telephone diplomacy and Gulf mediation; yet both sides claimed victory. The water issue and Kashmir remain unresolved.",
    [["peace", IN, PK], ["rel", IN, PK, 3], ["rel", IN, US, -2]],
    {IN: s.r("Ateşkes iç kamuoyunda 'yarım kalan iş' algısı yaratabilir; ama ekonomi büyüme hedefine odaklı. || The ceasefire may look like unfinished business at home, but the economy is focused on growth.",
            s.o("Ateşkesi kabul et (tarihî) || Accept the ceasefire (historical)", "Hindistan ateşkesi kabul etti ve 'harekât sürüyor' dedi. || India accepted the ceasefire, saying the operation continues.", [["peace", IN, PK], ["stab", IN, 1]]),
            s.o("Baskıyı sürdür || Keep the pressure on", "Delhi ateşkese rağmen su ve ticaret baskısını sürdürdü. || Delhi kept up water and trade pressure despite the truce.", [["rel", IN, PK, -4], ["stab", IN, 1], ["rel", IN, US, -2]])),
     PK: s.r("Mareşal rütbesine terfi eden komutan çevresinde ordu kenetlendi; ama ekonomi toparlanmaya muhtaç. || The army rallied around its newly promoted field marshal; but the economy needs recovery.",
            s.o("Ateşkesi kabul et, zaferi ilan et (tarihî) || Accept the ceasefire and claim victory (historical)", "Pakistan ateşkesi kabul etti; ordu zafer kutlaması yaptı. || Pakistan accepted the ceasefire and the army celebrated victory.", [["peace", PK, IN], ["stab", PK, 3], ["rel", PK, US, 4]]),
            s.o("Su meselesini uluslararasılaştır || Internationalise the water dispute", "İslamabad İndus sorununu BM ve Dünya Bankası'na taşıdı. || Islamabad took the Indus issue to the UN and the World Bank.", [["rel", PK, IN, -3], ["rel", PK, CN, 2]]))},
    icon="dove", scene="peace")
s.m("indus", 48, "İndus Suları ve Ekim Hasadı || The Indus Waters and the Autumn Harvest",
    "Hindistan İndus kolları üzerinde yeni barajlar ve su yönlendirmeleri planlarken Pakistan 'su kesilirse savaş' diyor. Muson sonrası kuraklık Pencap'ta gerilimi artırıyor. || India plans new dams and diversions on the Indus tributaries while Pakistan says cutting water means war. A post-monsoon drought raises tension in Punjab.",
    [["rel", IN, PK, -3], ["stab", PK, -1]],
    {PK: s.r("Pencap'ın tarımı İndus'a bağlı; suyun azalması iç huzursuzluk getirebilir. || Punjab's farming depends on the Indus; falling water could bring unrest.",
            s.o("Uluslararası tahkim iste || Seek international arbitration", "Pakistan Daimi Tahkim Divanı'na başvurdu. || Pakistan went to the Permanent Court of Arbitration.", [["rel", PK, US, 2], ["rel", PK, IN, -2]]),
            s.o("Sınırda gövde gösterisi || Show force at the border", "Pakistan birliklerini Pencap sınırına kaydırdı. || Pakistan moved units to the Punjab frontier.", [["troops", PK, 3], ["rel", PK, IN, -4]])),
     IN: s.r("Baraj yatırımları uzun vadeli; kısa vadede kuraklık Hindistan'ın kendi çiftçilerini de vuruyor. || Dam investments are long-term; in the short term drought also hits Indian farmers.",
            s.o("Barajları hızlandır || Speed up the dams", "Delhi Chenab üzerindeki projeleri hızlandırdı. || Delhi accelerated its Chenab projects.", [["rel", IN, PK, -4], ["gold", IN, -0.5], ["stab", IN, 1]]),
            s.o("Su görüşmelerini yeniden başlat || Restart water talks", "Hindistan Pakistan'la teknik su görüşmelerine razı oldu. || India agreed to technical water talks with Pakistan.", [["rel", IN, PK, 4], ["stab", IN, -1]]))},
    icon="warning", scene="trade", major=False)
s.save()

# ------------------------------------------------------------------ kor: 38. Paralel
s = Scn("kor")
s.m("kale", 6, "Sınırı Aşılmaz Kale Yap || Make the Border an Impregnable Fortress",
    "Kim Jong Un orduya Güney Kore sınırını 'aşılmaz bir kale'ye çevirme emri verdi; Pyongyang Seul'ü 'en düşman devlet' ilan etti ve tehdit edilirse Güney'i yok edebileceğini söyledi. Seul ise 'dron savaşçıları' yetiştiriyor. || Kim Jong Un ordered the army to turn the South Korean border into an 'impregnable fortress'; Pyongyang declared Seoul its 'most hostile state' and said it could destroy the South if threatened. Seoul, meanwhile, is training 'drone warriors'.",
    [["stab", KR, -1], ["rel", KP, KR, -4]],
    {KP: s.r("Rusya ile askerî ortaklık sizi cesaretlendirdi; ama yaptırımlar ve elektrik açığı sürüyor. || The military partnership with Russia has emboldened you; yet sanctions and power shortages persist.",
            s.o("Sınırı tahkim et, füze testlerini artır || Fortify the border and test more missiles", "Kuzey Kore sınır boyunca tahkimat kurdu ve füze testi yaptı. || North Korea fortified the border and tested missiles.", [["buff", KP, "def", 1.1, 8], ["rel", KP, KR, -5], ["rel", KP, US, -3]]),
            s.o("ABD'ye diyalog kapısı aç || Open a door to dialogue with the US", "Pyongyang ABD ile müzakereye 'koşullu' açık olduğunu söyledi. || Pyongyang said it is 'conditionally' open to talks with the US.", [["rel", KP, US, 4], ["rel", KP, KR, -1]])),
     KR: s.r("Seul caydırıcılıkta kararlı ama tırmanma istemiyor; yeni hükûmet diyalog çağrısı yapıyor. || Seoul is firm on deterrence but does not want escalation; the new government calls for dialogue.",
            s.o("Gerilimi azaltma çağrısı || Call for de-escalation", "Seul propaganda hoparlörlerini susturup görüşme önerdi. || Seoul silenced propaganda loudspeakers and proposed talks.", [["rel", KR, KP, 3], ["stab", KR, 1]]),
            s.o("Dron ve füze savunmasını artır || Boost drone and missile defence", "Güney Kore dron birimlerini ve füze savunmasını güçlendirdi. || South Korea strengthened its drone units and missile defence.", [["troops", KR, 3], ["rel", KR, US, 3], ["rel", KR, KP, -3]])),
     US: s.r("Washington Kore'de iki cephe istemiyor; ama müttefiklerine güven vermek zorunda. || Washington wants no second front in Korea, yet must reassure its allies.",
            s.o("Ortak tatbikat ve genişletilmiş caydırıcılık || Joint drills and extended deterrence", "ABD ve Güney Kore ortak tatbikat yaptı. || The US and South Korea held joint drills.", [["rel", US, KR, 4], ["rel", US, KP, -4]]),
            s.o("Doğrudan görüşme önerisi || Offer direct talks", "Beyaz Saray Kim'le zirve ihtimalini açık bıraktı. || The White House left the door open for a summit with Kim.", [["rel", US, KP, 4], ["rel", US, KR, -2]]), minor=True)},
    icon="missile", scene="pre_war")
s.m("tatbikatlar", 30, "Yaz Tatbikatları ve Rus Mühimmatı || Summer Drills and Russian Munitions",
    "Seul, Tokyo ve Washington üçlü tatbikat yaparken Kuzey Kore'nin Rusya'ya mühimmat ve asker gönderdiği, karşılığında teknoloji ve yakıt aldığı biliniyor. Pyongyang tatbikatları 'işgal provası' diye niteliyor. || As Seoul, Tokyo and Washington hold trilateral drills, North Korea is known to send munitions and troops to Russia in exchange for technology and fuel. Pyongyang calls the drills an 'invasion rehearsal'.",
    [["rel", KP, US, -3], ["rel", KP, JP, -3], ["buff", KP, "att", 1.05, 6]],
    {KP: s.r("Rusya ittifakı size askerî deneyim ve gelir getirdi; ama çok sayıda asker kaybı da var. || The Russian alliance brought combat experience and income, but also heavy troop losses.",
            s.o("Moskova'yla ittifakı derinleştir || Deepen the Moscow alliance", "Kuzey Kore ve Rusya yeni bir savunma işbirliği protokolü imzaladı. || North Korea and Russia signed a new defence cooperation protocol.", [["gold", KP, 1.5], ["troops", KP, 2], ["rel", KP, US, -3]]),
            s.o("Çin'e yaklaş, dengeyi koru || Lean toward China to keep balance", "Pyongyang Pekin'le ticaret ve yakıt anlaşmalarını yeniledi. || Pyongyang renewed trade and fuel deals with Beijing.", [["gold", KP, 1.0], ["rel", KP, CN, 5], ["stab", KP, 1]])),
     JP: s.r("Tokyo balistik füze alarmlarıyla yaşıyor; üçlü tatbikat Çin'i de rahatsız ediyor. || Tokyo lives with ballistic-missile alerts; the trilateral drill also bothers China.",
            s.o("Üçlü ittifakı derinleştir || Deepen the trilateral alignment", "Japonya, ABD ve Güney Kore füze uyarı verilerini paylaşmaya başladı. || Japan, the US and South Korea began sharing missile-warning data.", [["rel", JP, KR, 4], ["rel", JP, US, 3], ["rel", JP, CN, -3]]),
            s.o("Bölgesel diyalog önder ol || Lead regional dialogue", "Tokyo Kuzey Kore'yle temas ve Çin'le istişare önerdi. || Tokyo proposed contact with Pyongyang and consultations with China.", [["rel", JP, CN, 3], ["rel", JP, KP, 1]]), minor=True)},
    icon="jet", scene="air", major=False)
s.m("sinir", 64, "Sınırda Silah Sesi || Shots at the Border",
    "DMZ'de bir uyarı ateşi kazaya dönüştü: bir askerî devriye mayına bastı, iki tarafın topçusu ateş açtı. Hotline sessiz kalırsa tırmanma kaçınılmaz. || A warning shot in the DMZ turned into an accident: a patrol hit a mine and artillery on both sides opened fire. If the hotline stays silent, escalation is unavoidable.",
    [["stab", KP, -1], ["stab", KR, -1], ["rel", KP, KR, -5]],
    {KR: s.r("Karşılık vermezsen zayıf görünürsün, verirsen savaşa kayabilirsin. || If you do not respond you look weak; if you do, you may slide into war.",
            s.o("Orantılı karşılık, sıcak hat || Proportional response and the hotline", "Seul topçu ile sınırlı karşılık verip sıcak hattı açtı. || Seoul answered with limited artillery fire and opened the hotline.", [["rel", KR, KP, -2], ["stab", KR, 1]]),
            s.o("Sert vuruş || Hit back hard", "Güney Kore sınır karakollarına yoğun topçu ateşi açtı. || South Korea heavily shelled border posts.", [["war", KR, KP, "solo"], ["buff", KR, "att", 1.1, 6], ["rel", KR, KP, -8]])),
     KP: s.r("Olayı fırsat sayıp 'misilleme' diyebilirsiniz; ya da kontrolü kaybetmeden durdurursunuz. || You can use the incident as a pretext for 'retaliation', or stop it before losing control.",
            s.o("Misilleme yap || Retaliate", "Kuzey Kore sınırda topçu ve roketatarlarla ateş açtı. || North Korea opened fire with artillery and rocket launchers.", [["war", KP, KR, "solo"], ["buff", KP, "att", 1.1, 6], ["rel", KP, KR, -8]]),
            s.o("Olayı kapat, kınama yayınla || Close the incident with a statement", "Pyongyang olayı 'provokasyon' diye kınayıp tırmandırmadı. || Pyongyang condemned a 'provocation' without escalating.", [["rel", KP, KR, 1], ["stab", KP, 1]]))},
    icon="border_clash", scene="border")
s.save()

# ------------------------------------------------------------------ cau: Kafkas Düğümü
s = Scn("cau")
s.m("washington", 5, "Washington Zirvesi: Barış Metni || The Washington Summit: A Peace Text",
    "Ağustos 2025'te Beyaz Saray'da Aliyev ve Paşinyan barış anlaşması metnini paraf etti; ABD, Ermenistan'dan geçerek Azerbaycan'ı Nahçıvan'a bağlayacak 'Trump Rotası' (TRIPP) kurulmasını öngörüyor. Anayasa değişikliği ve Rusya'nın tepkisi ise sürecin önündeki engeller. || In August 2025 Aliyev and Pashinyan initialled a peace deal at the White House; the US envisions the 'Trump Route' (TRIPP), linking Azerbaijan to Nakhchivan through Armenia. A constitutional change and Russia's reaction remain obstacles.",
    [["rel", AZ, AM, 5], ["rel", AM, US, 3], ["rel", AM, RU, -3]],
    {AM: s.r("Barış, ablukanın kalkması ve ticaret demek; ama anayasa referandumu ve Karabağ yenilgisinin hatıraları iç siyaseti kaynatıyor. || Peace means the end of the blockade and trade, but a constitutional referendum and memories of the Karabakh defeat stir domestic politics.",
            s.o("Barışı ve Rota'yı onayla (tarihî) || Endorse peace and the Route (historical)", "Erivan barış metnini ve ABD'nin yönettiği geçiş koridorunu kabul etti. || Yerevan accepted the peace text and the US-run transit corridor.", [["rel", AM, AZ, 6], ["rel", AM, US, 4], ["rel", AM, RU, -4], ["stab", AM, -1]]),
            s.o("Önce anayasa ve güvenlik garantisi iste || Demand constitutional and security guarantees first", "Paşinyan imzayı koşullara bağladı; süreç yavaşladı. || Pashinyan tied his signature to conditions; the process slowed.", [["rel", AM, AZ, -2], ["stab", AM, 1]])),
     AZ: s.r("Zafer sizde; barış metnini ve Zengezur koridorunu istiyorsunuz. Rusya ile ilişkiler gergin, Türkiye tam destekçi. || The victory is yours; you want the peace text and the Zangezur corridor. Ties with Russia are tense; Turkey is a full backer.",
            s.o("Barışı imzala, sınırı aç (tarihî) || Sign peace and open the border (historical)", "Bakü barış metnini paraf etti ve Ermenistan'a transit izni verdi. || Baku initialled the peace text and allowed transit to Armenia.", [["rel", AZ, AM, 6], ["rel", AZ, US, 4], ["rel", AZ, TR, 1]]),
            s.o("Koridor için baskıyı artır || Press harder for the corridor", "Bakü Zengezur koridoru için baskıyı sürdürdü. || Baku kept pressing for the Zangezur corridor.", [["rel", AZ, AM, -5], ["troops", AZ, 2]])),
     RU: s.r("Rusya'nın Güney Kafkasya'daki etkisi azalıyor: Ermenistan CSTO'yu dondurdu, ABD koridor kuruyor. || Russia's influence in the South Caucasus is shrinking: Armenia froze its CSTO role and the US builds a corridor.",
            s.o("Ermenistan'a baskı yap || Pressure Armenia", "Moskova Ermeni mallarına kısıtlama ve gaz fiyatı baskısı uyguladı. || Moscow restricted Armenian goods and pressed on gas prices.", [["rel", RU, AM, -6], ["gold", AM, -0.5], ["rel", RU, US, -2]]),
            s.o("Barış sürecine uyum sağla || Adapt to the peace process", "Rusya koridorun sınır denetimine katkı önerdi. || Russia offered to help with border control on the corridor.", [["rel", RU, AM, 2], ["rel", RU, AZ, 2]]), minor=True)},
    icon="treaty", scene="peace")
s.m("rota", 26, "Zengezur Rotası İnşaatı || Building the Zangezur Route",
    "Ermenistan'ın güneyinden geçen demiryolu ve karayolu hattı için fizibilite çalışması bitti; Türkiye Kars–Nahçıvan bağlantısını hızlandırıyor, İran ise sınırlarının yakınında ABD varlığından rahatsız. || Feasibility is complete for the rail and road line through southern Armenia; Turkey accelerates a Kars–Nakhchivan link, while Iran is uneasy about a US presence near its border.",
    [["rel", AZ, TR, 3], ["rel", IR, US, -2], ["gold", AZ, 1.0]],
    {IR: s.r("Güney Ermenistan'daki koridor sizi Kafkasya'dan izole edebilir; ama Hürmüz krizi önceliğiniz. || A corridor through southern Armenia could isolate you from the Caucasus; yet the Hormuz crisis is your priority.",
            s.o("Sert itiraz, sınıra birlik || Object sharply and move units to the border", "Tahran sınır bölgesine birlik kaydırdı ve koridora itiraz etti. || Tehran moved units to the border and objected to the corridor.", [["rel", IR, AZ, -4], ["rel", IR, US, -3], ["troops", IR, 2]]),
            s.o("Ticarete ortak ol || Join the trade", "İran koridora kuzey-güney ticaretinde ortaklık önerdi. || Iran offered partnership in north–south trade along the corridor.", [["rel", IR, AZ, 3], ["rel", IR, AM, 2]])),
     TR: s.r("Ankara Ermenistan sınırını açmaya hazır; Azerbaycan'la 'tek millet iki devlet' bağı güçlü. || Ankara is ready to open the Armenian border; the 'one nation, two states' bond with Azerbaijan is strong.",
            s.o("Sınırı aç, diplomatik ilişki kur || Open the border and establish relations", "Türkiye Ermenistan'la diplomatik ilişki kurma yolunu açtı. || Turkey opened the way to diplomatic relations with Armenia.", [["rel", TR, AM, 6], ["rel", TR, AZ, -1], ["rel", TR, US, 2]]),
            s.o("Azerbaycan'ın önceliğine uy || Follow Azerbaijan's priority", "Ankara sınırı Bakü'nün şartlarına bağladı. || Ankara tied the border to Baku's conditions.", [["rel", TR, AZ, 4], ["rel", TR, AM, -2]]), minor=True)},
    icon="trade", scene="trade", major=False)
s.m("referandum", 60, "Anayasa Referandumu || The Constitutional Referendum",
    "Ermenistan'da Karabağ'a atıf yapan anayasa maddesinin kaldırılması referanduma gidiyor; muhalefet ve kilise karşı, Bakü ise bu değişikliği barışın ön şartı sayıyor. || In Armenia a referendum on removing the Karabakh reference from the constitution is looming; the opposition and the church are opposed, while Baku sees the change as a precondition for peace.",
    [["stab", AM, -2]],
    {AM: s.r("Referandum barışın sigortası ama kaybederseniz hükûmet çökebilir. || The referendum is peace insurance, but losing could bring down the government.",
            s.o("Referandumu yap || Hold the referendum", "Erivan anayasa referandumunu takvime aldı. || Yerevan scheduled the constitutional referendum.", [["stab", AM, -2], ["rel", AM, AZ, 4], ["rel", AM, US, 3]]),
            s.o("Ertele, toplumsal mutabakat ara || Postpone and seek consensus", "Hükûmet referandumu erteleyip kilise ve muhalefetle görüştü. || The government postponed the vote and talked to the church and opposition.", [["stab", AM, 1], ["rel", AM, AZ, -3]])),
     AZ: s.r("Anayasa şartı barışın son engeli gibi görünüyor; baskı yaparsanız Paşinyan zayıflar, ama beklerseniz süreç donar. || The constitutional condition looks like the last obstacle; pressure weakens Pashinyan, but waiting freezes the process.",
            s.o("Sabırlı ol, ticareti aç || Be patient and open trade", "Bakü Ermenistan'a kısmi ticaret ve transit izni verdi. || Baku granted Armenia partial trade and transit.", [["rel", AZ, AM, 4], ["gold", AZ, 0.5]]),
            s.o("Süre koy ve baskı yap || Set a deadline and press", "Aliyev anayasa değişikliği için son tarih verdi. || Aliyev set a deadline for the constitutional change.", [["rel", AZ, AM, -4], ["rel", AZ, US, -1]]))},
    icon="flag", scene="pre_court", major=False)
s.save()
print("tamam: ukr twn irn ind kor cau")

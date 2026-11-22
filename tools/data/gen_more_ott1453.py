import os
os.environ["ERA"] = "ott1453"
from gen_more_ww1 import *

M("constantinople_1453", 1453, 5, "İstanbul'un Fethi || The Fall of Constantinople",
  "II. Mehmed devasa toplarla Theodosius Surları'nı dövüyor; 29 Mayıs'taki genel taarruz sonucu şehir düştü. Bizans'ın bin yıllık hikâyesi bitiyor, bir çağ kapanıyor. || Mehmed II is pounding the Theodosian Walls with giant cannons; the general assault of 29 May brought the city down. A thousand-year Byzantine story ends and an age closes.",
  [["occupy", "Turkey", "Greece"], ["stab", "Turkey", 8], ["stab", "Greece", -12], ["rel", "Italy", "Turkey", -10]],
  {"Turkey": R("Surlar delindi; son taarruz için hazırsın. Şehri ele geçirince ne yapacaksın? || The walls are breached; you are ready for the final assault. What will you do once the city is yours?",
               O("Genel taarruz (tarihî) || General assault (historical)", "Şehir sizin olsun || The city is yours", "Osmanlı ordusu İstanbul'a girdi; Ayasofya camiye çevrildi. || The Ottoman army entered Constantinople; Hagia Sophia became a mosque.", [["buff", "Turkey", "att", 1.2, 10], ["stab", "Turkey", 8], ["gold", "Turkey", 2.0]]),
               O("Muhasarayı sürdür || Prolong the siege", "Daha az kayıp || Fewer losses", "Muhasara sürdü; Venedik filosu yaklaşıyor. || The siege continued as the Venetian fleet approached.", [["troops", "Turkey", -3], ["rel", "Italy", "Turkey", -4]])),
   "Greece": R("Giustiniani yaralandı; Haliç zinciri tutuyor ama sayı çok az. İmparator son savunmada. || Giustiniani is wounded; the Golden Horn chain holds but numbers are few. The emperor makes a last stand.",
               O("Surlarda son savunma (tarihî) || Last stand on the walls (historical)", "Şan ve onur || Glory and honour", "Konstantinos surlarda düştü; şehir düştü. || Constantine fell on the walls; the city fell.", [["buff", "Greece", "def", 1.5, 4], ["stab", "Greece", 4]]),
               O("Şehri bırak, Mora'ya kaç || Abandon the city, flee to the Morea", "Mora'da ayakta kal || Survive in the Morea", "İmparator Mora'ya çekildi. || The emperor withdrew to the Morea.", [["stab", "Greece", -8], ["troops", "Greece", 2]])),
   "Italy": R("Venedik ve Cenova İstanbul'daki ticaretini kaybediyor; Papa haçlı çağrısı yapıyor. || Venice and Genoa are losing their Constantinople trade; the Pope is calling for a crusade.",
               O("Osmanlı ile ticaret antlaşması yap (tarihî) || Seek a trade treaty with the Ottomans (historical)", "Ticaret yollarını koru || Protect trade routes", "Venedik Osmanlı ile yeni bir ticaret anlaşması yaptı. || Venice signed a new trade agreement with the Ottomans.", [["rel", "Italy", "Turkey", 8], ["gold", "Italy", 1.0]]),
               O("Haçlı ittifakı kur || Build a crusader league", "Savaş riski || Risk of war", "Roma bir haçlı ittifakı kurmaya çalıştı. || Rome tried to assemble a crusader league.", [["rel", "Italy", "Turkey", -10], ["rel", "Italy", "Hungary", 6]]))},
  icon="flag", scene="pre_siege")

M("belgrade_1456", 1456, 7, "Belgrad Kuşatması || The Siege of Belgrade",
  "Fatih, Tuna'nın anahtarı Belgrad'ı kuşattı. Hunyadi János ve Capistrano'nun haçlı gönüllüleri nehirdeki Osmanlı filosunu yardı; Fatih yaralandı ve kuşatma kalktı. || Mehmed besieged Belgrade, the key to the Danube. John Hunyadi and Capistrano's crusader volunteers broke the Ottoman river fleet; Mehmed was wounded and the siege lifted.",
  [["troops", "Turkey", -8], ["stab", "Turkey", -3], ["stab", "Hungary", 8]],
  {"Turkey": R("Surlar kırıldı ama haçlı takviyesi nehri açtı. Askerler yorgun. || The walls are breached but crusader reinforcements opened the river. The troops are exhausted.",
               O("Kuşatmayı sürdür || Keep pressing", "Şehri al veya kaybet || Take it or lose it", "Osmanlı ordusu son bir taarruz yaptı ve ağır kayıp verdi. || The Ottoman army made a last assault and took heavy losses.", [["troops", "Turkey", -6], ["buff", "Turkey", "att", 1.1, 4]]),
               O("Kuşatmayı kaldır (tarihî) || Lift the siege (historical)", "Orduyu koru || Preserve the army", "Fatih kuşatmayı kaldırıp geri çekildi. || Mehmed lifted the siege and withdrew.", [["buff", "Turkey", "def", 1.1, 8], ["stab", "Turkey", -2]])),
   "Hungary": R("Hunyadi Belgrad'da; haçlı gönüllüleri köylülerden oluşuyor. Nehir savaşı kaderi belirleyecek. || Hunyadi is at Belgrade; the crusaders are mostly peasants. The river battle will decide the day.",
               O("Osmanlı filosunu yar (tarihî) || Break the Ottoman fleet (historical)", "Belgrad'ı kurtar || Save Belgrade", "Macarlar Osmanlı filosunu Tuna'da dağıttı; Belgrad kurtuldu. || The Hungarians scattered the Ottoman fleet on the Danube; Belgrade was saved.", [["buff", "Hungary", "def", 1.3, 14], ["stab", "Hungary", 8], ["rel", "Hungary", "Italy", 6]]),
               O("Kaleye kapan || Hold behind the walls", "Kuşatmayı bekle || Weather the siege", "Macarlar kalenin arkasında savundu. || The Hungarians defended from behind the walls.", [["buff", "Hungary", "def", 1.2, 8]])),
   "Serbia": R("Belgrad Macarlara bağlı; Despot Đurađ ölü, ülke bölünmüş durumda. || Belgrade is held for Hungary; Despot Đurađ is dead and the land is divided.",
               O("Macarlara bağlı kal (tarihî) || Stay with Hungary (historical)", "Haçlı ittifakı || The crusader alliance", "Sırp beyleri Macaristan'ın yanında kaldı. || Serbian lords stayed with Hungary.", [["rel", "Serbia", "Hungary", 8], ["rel", "Serbia", "Turkey", -6]]),
               O("Osmanlı'ya haraç ver || Pay tribute to the Ottomans", "Barışı koru || Preserve peace", "Sırp Despotluğu Osmanlı'ya haraç vermeye devam etti. || The Serbian Despotate kept paying tribute to the Ottomans.", [["rel", "Serbia", "Turkey", 6], ["stab", "Serbia", -2]]))},
  icon="helmet_ww1", scene="pre_siege")

M("morea_1460", 1460, 5, "Mora Despotluğu'nun Sonu || The End of the Morea",
  "Bizans'ın son parçası Mora'daki Palaiologos kardeşlerin kavgası Fatih'e fırsat verdi. Osmanlı ordusu Mistra'yı aldı; Mora'nın kalan kalesi düşüyor. || The last Byzantine remnant, the Morea, was weakened by the Palaiologos brothers' feud. The Ottoman army took Mistra; the remaining fortresses are falling.",
  [["occupy", "Turkey", "Greece"], ["stab", "Turkey", 4], ["stab", "Greece", -8]],
  {"Turkey": R("Mora despotları vergi vermedi ve birbirine düştü. Seferi başlatma zamanı. || The Morean despots stopped paying tribute and fell to quarrelling. Time to launch the campaign.",
               O("Mora'yı fethet (tarihî) || Conquer the Morea (historical)", "Yarımadayı ele geçir || Take the peninsula", "Osmanlı ordusu Mora'yı ele geçirdi. || The Ottoman army conquered the Morea.", [["buff", "Turkey", "att", 1.15, 8], ["gold", "Turkey", 1.0]]),
               O("Haraç al, savaşma || Take tribute and stay out", "Daha az masraf || Lower cost", "Osmanlı Mora'dan haraçla yetindi. || The Ottomans settled for tribute from the Morea.", [["gold", "Turkey", 0.5]])),
   "Greece": R("Thomas ve Demetrios birbirine düşman; Osmanlı ordusu kapıda. || Thomas and Demetrios are enemies; the Ottoman army is at the gates.",
               O("Papalık'tan yardım iste (tarihî) || Appeal to the Papacy (historical)", "Haçlı çağrısı || A crusade call", "Mora despotları Roma'dan yardım istedi; yardım gelmedi. || The Morean despots appealed to Rome; no help came.", [["rel", "Greece", "Italy", 8], ["stab", "Greece", -3]]),
               O("Osmanlı'ya bağlan || Submit to the Ottomans", "Hayatta kal || Survive", "Despotlar Osmanlı egemenliğini kabul etti. || The despots accepted Ottoman suzerainty.", [["peace", "Greece", "Turkey"], ["stab", "Greece", -6]]))},
  icon="flag", scene="pre_siege")

M("vlad_1462", 1462, 6, "Kazıklı Voyvoda || Vlad the Impaler",
  "Eflak Voyvodası Vlad Dracula haracı reddetti ve Osmanlı elçilerini idam etti; Fatih Tuna'yı geçti. Vlad gece baskını yaptı; kazıklı cesetlerle dolu bir orman Osmanlı ordusunu dehşete düşürdü. || Wallachian prince Vlad Dracula refused tribute and executed Ottoman envoys; Mehmed crossed the Danube. Vlad launched a night raid; a forest of impaled bodies horrified the Ottoman army.",
  [["war", "Turkey", "Romania"], ["troops", "Turkey", -4], ["stab", "Romania", 3]],
  {"Romania": R("Osmanlı ordusu Eflak'a girdi; yakıp yıkma taktiğiyle karşı koyabilirsin. || The Ottoman army has entered Wallachia; you can resist with scorched earth.",
               O("Yakıp yık ve gece baskını yap (tarihî) || Scorched earth and night raids (historical)", "Direniş || Resistance", "Vlad gece baskınıyla Osmanlı ordusunu yıprattı. || Vlad's night raid wore down the Ottoman army.", [["buff", "Romania", "def", 1.4, 8], ["troops", "Turkey", -4], ["stab", "Romania", 4]]),
               O("Macaristan'dan yardım iste || Ask Hungary for help", "İttifak || An alliance", "Vlad Macaristan'dan yardım istedi; Mátyás onu tutukladı. || Vlad asked Hungary for help; Matthias had him imprisoned.", [["rel", "Romania", "Hungary", 6], ["stab", "Romania", -4]])),
   "Turkey": R("Vlad'ın korku taktiği ordunun morali için tehlike. Seferi sürdür mü? || Vlad's terror tactic threatens morale. Press on or withdraw?",
               O("Radu'yu tahta çıkar (tarihî) || Install Radu (historical)", "Kardeşi vasal yap || Make his brother a vassal", "Osmanlı Vlad'ın kardeşi Radu'yu Eflak tahtına oturttu. || The Ottomans installed Vlad's brother Radu on the Wallachian throne.", [["rel", "Turkey", "Romania", 6], ["gold", "Turkey", 1.0]]),
               O("Seferi sürdür || Press on", "Zorlu arazi || Difficult terrain", "Osmanlı birlikleri Eflak'ta ilerlemeye çalıştı. || Ottoman troops pushed on through Wallachia.", [["troops", "Turkey", -6], ["buff", "Turkey", "att", 1.1, 4]]))},
  icon="flame", scene="crisis")

M("negroponte_1470", 1470, 7, "Eğriboz'un Fethi || The Fall of Negroponte",
  "Osmanlı donanması ve ordusu Venedik'in Ege'deki en önemli üssü Eğriboz'u (Negroponte) kuşattı. Şehir kuşatmanın 17. gününde düştü; Venedik-Osmanlı savaşı sürüyor. || The Ottoman fleet and army besieged Negroponte, Venice's most important Aegean base. The city fell on the 17th day; the Venetian-Ottoman war goes on.",
  [["war", "Turkey", "Italy"], ["occupy", "Turkey", "Italy"], ["stab", "Italy", -6]],
  {"Italy": R("Eğriboz kuşatıldı; Venedik donanması yetişemiyor. Büyük bir kayıp. || Negroponte is under siege and the fleet cannot arrive in time. A major loss.",
               O("Uzun Hasan ile ittifak kur (tarihî) || Ally with Uzun Hasan (historical)", "Doğu cephesi aç || Open an eastern front", "Venedik Akkoyunlu Uzun Hasan'la ittifak aradı. || Venice sought an alliance with Uzun Hasan of the Akkoyunlu.", [["rel", "Italy", "Iran", 8], ["rel", "Italy", "Turkey", -4]]),
               O("Barış iste || Sue for peace", "Ticareti koru || Keep trade", "Venedik Osmanlı ile barış görüşmelerine başladı. || Venice opened peace talks with the Ottomans.", [["peace", "Italy", "Turkey"], ["gold", "Italy", -1.0]])),
   "Turkey": R("Eğriboz Ege'nin anahtarı. Donanma ve ordu ortak harekâtla şehri ele geçirebilir. || Negroponte is the key to the Aegean. Fleet and army can take it in a joint operation.",
               O("Şehri fethet (tarihî) || Capture the city (historical)", "Ege'de üstünlük || Supremacy in the Aegean", "Osmanlı Eğriboz'u aldı; Venedik'in Ege üstünlüğü bitti. || The Ottomans took Negroponte; Venice's Aegean dominance ended.", [["buff", "Turkey", "att", 1.15, 10], ["gold", "Turkey", 1.5], ["stab", "Turkey", 4]]),
               O("Venedik'le barış yap || Make peace with Venice", "Ticaret kazancı || Trade gains", "Osmanlı Venedik'le ticaret antlaşmasına yöneldi. || The Ottomans turned to a trade treaty with Venice.", [["peace", "Turkey", "Italy"], ["gold", "Turkey", 1.0]]))},
  icon="landing", scene="landing")

M("otranto_1480", 1480, 8, "Otranto Çıkarması || The Landing at Otranto",
  "Gedik Ahmed Paşa'nın donanması Otranto'ya çıktı ve şehri aldı; Roma'ya yürüyüş korkusu Avrupa'yı sarstı. Fatih'in ölümü seferi kesecek. || Gedik Ahmed Pasha's fleet landed at Otranto and took the city; fear of a march on Rome shook Europe. Mehmed's death will cut the campaign short.",
  [["war", "Turkey", "Italy"], ["occupy", "Turkey", "Italy"], ["stab", "Italy", -4]],
  {"Turkey": R("İtalya'da köprübaşı kuruldu. Bu üssü kalıcı yapmak veya Roma'yı tehdit etmek mümkün. || A bridgehead in Italy is established. You can make it permanent or threaten Rome.",
               O("Otranto'yu tahkim et (tarihî) || Fortify Otranto (historical)", "İtalya'da üs || A base in Italy", "Osmanlı Otranto'yu güçlendirdi; Fatih'in ölümüyle seferi yarım kaldı. || The Ottomans strengthened Otranto; Mehmed's death left the campaign unfinished.", [["buff", "Turkey", "def", 1.1, 10], ["rel", "Italy", "Turkey", -8]]),
               O("Roma'ya yürü || March on Rome", "Büyük hedef || A grand objective", "Osmanlı ordusu İtalya içlerine ilerlemeye çalıştı. || The Ottoman army tried to advance inland.", [["buff", "Turkey", "att", 1.15, 8], ["troops", "Turkey", -5]])),
   "Italy": R("Otranto düştü; Napoli ve Roma panikte. Papa Sixtus haçlı çağrısı yapıyor. || Otranto has fallen; Naples and Rome are in a panic. Pope Sixtus calls for a crusade.",
               O("Otranto'yu geri al (tarihî) || Retake Otranto (historical)", "İtalyan birliği || Italian unity", "İtalyan devletleri birleşip Otranto'yu geri aldı. || The Italian states united and retook Otranto.", [["buff", "Italy", "att", 1.2, 8], ["stab", "Italy", 4], ["rel", "Italy", "Spain", 6]]),
               O("Osmanlı ile müzakere et || Negotiate with the Ottomans", "Savaştan kaçın || Avoid war", "İtalyan şehir devletleri Osmanlı ile görüşmeleri açtı. || The Italian city-states opened talks with the Ottomans.", [["rel", "Italy", "Turkey", 4], ["stab", "Italy", -3]]))},
  icon="landing", scene="landing")
save()

import os
os.environ["ERA"] = "ott1520"
from gen_more_ww1 import *

M("baghdad_1534", 1534, 11, "Irakeyn Seferi: Bağdat'ın Fethi || The Campaign of the Two Iraqs",
  "Kanuni Safevî Şahı'nın üzerine yürüdü; Bağdat ve Irak topraklarını aldı. Doğu cephesi Osmanlı'nın uzun vadeli mücadelesine dönüyor. || Suleiman marched against the Safavid Shah and took Baghdad and the Iraqi lands. The eastern front becomes a long-term Ottoman struggle.",
  [["occupy", "Turkey", "Iran"], ["stab", "Turkey", 4], ["stab", "Iran", -4]],
  {"Turkey": R("Tebriz alındı; Safevî Şahı savaştan kaçıyor. Bağdat'a inmek mi, Tebriz'de kalmak mı? || Tabriz is taken; the Safavid Shah avoids battle. Descend on Baghdad or stay in Tabriz?",
               O("Bağdat'ı al (tarihî) || Take Baghdad (historical)", "Irak ve Basra yolu || Iraq and the road to Basra", "Osmanlı Bağdat'ı aldı; Irak Osmanlı'ya bağlandı. || The Ottomans took Baghdad; Iraq joined the empire.", [["buff", "Turkey", "att", 1.15, 8], ["gold", "Turkey", 2.0]]),
               O("Tebriz'i tut || Hold Tabriz", "İran içlerine ilerle || Push into Persia", "Osmanlı ordusu Tebriz'de kaldı; kış zorlaştırdı. || The Ottoman army stayed at Tabriz; winter hindered it.", [["troops", "Turkey", -4], ["buff", "Turkey", "def", 1.1, 8]])),
   "Iran": R("Osmanlı ordusu kıştan önce geldi; açık savaş riskli. Tahmasb geri çekilip yıpratma taktiği mi uygulasın? || The Ottoman army arrived before winter; open battle is risky. Should Tahmasp retreat and wear them down?",
               O("Yakıp çekil (tarihî) || Scorched-earth retreat (historical)", "Osmanlı'yı yıprat || Wear the Ottomans down", "Şah Tahmasb yakıp yıkarak çekildi. || Shah Tahmasp withdrew, scorching the land.", [["buff", "Iran", "def", 1.3, 10], ["stab", "Iran", -3]]),
               O("Savaş ver || Give battle", "Büyük risk || A big risk", "Safevî ordusu Osmanlı'yla karşı karşıya geldi. || The Safavid army met the Ottomans in battle.", [["troops", "Iran", -8], ["buff", "Iran", "att", 1.1, 4]]))},
  icon="flag", scene="pre_siege")

M("tunis_1535", 1535, 7, "Tunus Seferi || The Conquest of Tunis",
  "Barbaros Hayreddin Tunus'u ele geçirdi; V. Karl Akdeniz'de karşılık verdi. Habsburg donanması Tunus'a çıkarma yaptı, Hafsî Sultanı'nı geri getirdi. || Barbarossa seized Tunis; Charles V struck back. A Habsburg fleet landed at Tunis and restored the Hafsid Sultan.",
  [["war", "Spain", "Algeria"], ["occupy", "Spain", "Tunisia"], ["stab", "Spain", 4]],
  {"Spain": R("Hafsî tahtı Barbaros'a düştü. İmparator bizzat sefere çıkmak istiyor. || The Hafsid throne has fallen to Barbarossa. The Emperor wants to lead the expedition himself.",
               O("Tunus'a çıkarma yap (tarihî) || Land at Tunis (historical)", "La Goulette'i al || Take La Goulette", "Habsburg ordusu Tunus'u aldı ve Hafsî Sultanı'nı tahta çıkardı. || The Habsburg army took Tunis and restored the Hafsid Sultan.", [["buff", "Spain", "att", 1.2, 8], ["stab", "Spain", 4], ["rel", "Spain", "Turkey", -6]]),
               O("Donanma harcamasından kaçın || Avoid naval spending", "Kaynak tasarrufu || Save resources", "Habsburg donanmasını Akdeniz'de sınırlı kullandı. || The Habsburgs used their fleet sparingly.", [["gold", "Spain", 1.0]])),
   "Turkey": R("Barbaros Tunus'u almış ama Habsburg donanması geliyor. Takviye mi, geri çekilme mi? || Barbarossa took Tunis but the Habsburg fleet is coming. Reinforce or withdraw?",
               O("Cezayir'e çekil (tarihî) || Pull back to Algiers (historical)", "Donanmayı koru || Preserve the fleet", "Barbaros Tunus'u terk edip Cezayir'e çekildi. || Barbarossa abandoned Tunis for Algiers.", [["buff", "Turkey", "def", 1.1, 8], ["rel", "Turkey", "Algeria", 4]]),
               O("Donanmayı gönder || Send the fleet", "Akdeniz mücadelesi || Mediterranean struggle", "Osmanlı donanması Tunus'a yöneldi. || The Ottoman fleet headed for Tunis.", [["buff", "Turkey", "att", 1.1, 6], ["troops", "Turkey", -3]]))},
  icon="landing", scene="landing")

M("djerba_1560", 1560, 5, "Cerbe Deniz Savaşı || The Battle of Djerba",
  "Piyale Paşa'nın donanması Cerbe Adası açıklarında Habsburg ve Malta müttefik donanmasını bozguna uğrattı. Akdeniz'in doğu ve ortası Osmanlı üstünlüğüne geçti. || Piyale Pasha's fleet routed the combined Habsburg and Maltese fleet off Djerba. The eastern and central Mediterranean fell under Ottoman supremacy.",
  [["troops", "Spain", -8], ["stab", "Spain", -4], ["buff", "Turkey", "att", 1.1, 10]],
  {"Turkey": R("Trablus'u kurtarmak için Piyale Paşa donanmayla Cerbe'de. Habsburg donanması hâlâ adada. || Piyale Pasha is at Djerba with the fleet to save Tripoli. The Habsburg fleet is still at the island.",
               O("Müttefik donanmaya saldır (tarihî) || Attack the allied fleet (historical)", "Akdeniz'e hükmet || Rule the Mediterranean", "Osmanlı donanması Cerbe'de Habsburg donanmasını yok etti. || The Ottoman fleet destroyed the Habsburg fleet at Djerba.", [["buff", "Turkey", "att", 1.2, 12], ["stab", "Turkey", 5], ["gold", "Turkey", 1.5]]),
               O("Trablus'a git, savaşma || Go to Tripoli without a fight", "Donanmayı koru || Preserve the fleet", "Osmanlı donanması Trablus'u korudu ama savaşmaktan kaçındı. || The Ottoman fleet protected Tripoli but avoided battle.", [["stab", "Turkey", 1]])),
   "Spain": R("Cerbe'deki kale kuşatıldı. Donanma kaybedildi; Filip II intikam isteyecek. || The fort at Djerba is besieged. The fleet is lost; Philip II will seek revenge.",
               O("Yeni donanma inşa et (tarihî) || Build a new fleet (historical)", "Akdeniz'de geri dönüş || A Mediterranean comeback", "Habsburg yeni bir donanma inşa etmeye başladı. || The Habsburgs began building a new fleet.", [["gold", "Spain", -1.5], ["buff", "Spain", "att", 1.1, 14]]),
               O("Barış yap || Make peace", "Atlantik'e odaklan || Focus on the Atlantic", "Madrid Osmanlı'yla ateşkes arayışına girdi. || Madrid sought a truce with the Ottomans.", [["peace", "Spain", "Turkey"], ["stab", "Spain", -2]]))},
  icon="carrier", scene="carrier")

M("malta_1565", 1565, 5, "Malta Büyük Kuşatması || The Great Siege of Malta",
  "Osmanlı donanması ve ordusu Malta'daki Aziz Yuhanna Şövalyeleri'ni kuşattı. Sant'Elmo bir ayda düştü ama La Valette Birgu ve Senglea'yı tuttu; kuşatma dört ay sürdü. || The Ottoman fleet and army besieged the Knights of St John on Malta. Fort St Elmo fell in a month but La Valette held Birgu and Senglea; the siege lasted four months.",
  [["war", "Turkey", "Malta"], ["troops", "Turkey", -8], ["troops", "Malta", -6]],
  {"Malta": R("Sant'Elmo düştü; elinde Birgu ve Senglea var. Habsburg yardım filosu Sicilya'da bekliyor. || St Elmo has fallen; you hold Birgu and Senglea. The Habsburg relief fleet waits in Sicily.",
               O("Sonuna kadar savun (tarihî) || Defend to the last (historical)", "La Valette ruhu || The spirit of La Valette", "Şövalyeler iki mevzii tuttu; yardım ordusu geldi, Osmanlı çekildi. || The Knights held two positions; the relief army arrived and the Ottomans withdrew.", [["buff", "Malta", "def", 1.5, 14], ["stab", "Malta", 6]]),
               O("Teslim şartlarını görüş || Negotiate terms", "Şerefli teslim || Honourable surrender", "Büyük Üstat teslim şartlarını görüşmeyi reddetti. || The Grand Master refused to negotiate terms.", [["stab", "Malta", -4]])),
   "Turkey": R("Dragut'un ölümü komuta birliğini bozdu; Habsburg yardım donanması yaklaşıyor. || Dragut's death broke the unity of command; the Habsburg relief fleet is approaching.",
               O("Kuşatmayı sürdür || Continue the siege", "Büyük taarruz || A grand assault", "Osmanlı kuvvetleri yeni taarruzlar yaptı ve ağır kayıp verdi. || Ottoman forces made fresh assaults and took heavy losses.", [["troops", "Turkey", -8], ["buff", "Turkey", "att", 1.1, 4]]),
               O("Kuşatmayı kaldır (tarihî) || Lift the siege (historical)", "Donanmayı koru || Save the fleet", "Osmanlı donanması Malta'dan çekildi. || The Ottoman fleet withdrew from Malta.", [["stab", "Turkey", -3], ["buff", "Turkey", "def", 1.1, 8]]))},
  icon="landing", scene="pre_siege")

M("szigetvar_1566", 1566, 9, "Zigetvar Seferi || The Siege of Szigetvár",
  "Yaşlı Kanuni son seferinde Zigetvar'ı kuşattı; Zrinyi'nin küçük garnizonu dayanıyor. Sultan kuşatma sırasında öldü; haber ordudan saklandı. || The ageing Suleiman besieged Szigetvár on his last campaign; Zrinyi's small garrison held out. The Sultan died during the siege; the news was hidden from the army.",
  [["troops", "Turkey", -6], ["troops", "Hungary", -4], ["stab", "Turkey", -3]],
  {"Turkey": R("Sultan hasta ve kale hâlâ direniyor. Sadrazam Sokollu ne yapacak? || The Sultan is ill and the fortress still resists. What will Grand Vizier Sokollu do?",
               O("Ölümü gizle, kaleyi al (tarihî) || Hide the death, take the fortress (historical)", "Taht mücadelesini önle || Prevent a succession struggle", "Sokollu Padişah'ın ölümünü gizleyip kaleyi aldı. || Sokollu hid the Sultan's death and took the fortress.", [["buff", "Turkey", "att", 1.15, 6], ["stab", "Turkey", 3]]),
               O("Kuşatmayı kaldır || Lift the siege", "Orduyu koru || Save the army", "Osmanlı ordusu geri çekildi; taht krizi başladı. || The Ottoman army withdrew; a succession crisis began.", [["stab", "Turkey", -6]])),
   "Hungary": R("Zrinyi tahkimatı terk etmeden çıkış savaşı mı yapacak? || Will Zrinyi fight a sortie rather than abandon the fort?",
               O("Çıkış savaşı yap (tarihî) || Make a sortie (historical)", "Şan || Glory", "Zrinyi son çıkışı yaptı; kale düştü ama Osmanlı yıprandı. || Zrinyi made a last sortie; the fort fell but the Ottomans were worn down.", [["buff", "Hungary", "def", 1.3, 8], ["stab", "Hungary", 4], ["troops", "Hungary", -4]]),
               O("Teslim ol || Surrender", "Can kurtar || Save lives", "Zigetvar garnizonu teslim şartlarını kabul etti. || The garrison accepted terms of surrender.", [["stab", "Hungary", -4]]))},
  icon="flag", scene="pre_siege")

M("cyprus_1570", 1570, 7, "Kıbrıs Seferi || The Conquest of Cyprus",
  "II. Selim Venedik'in elindeki Kıbrıs'a sefer başlattı. Lala Mustafa Paşa Lefkoşa ve Mağusa'yı kuşattı; Mağusa bir yıl direndi. Venedik Papa ve Habsburg'dan ittifak arıyor. || Selim II launched a campaign against Venetian Cyprus. Lala Mustafa Pasha besieged Nicosia and Famagusta; Famagusta held for a year. Venice seeks an alliance with the Pope and the Habsburgs.",
  [["war", "Turkey", "Italy"], ["stab", "Italy", -5], ["rel", "Italy", "Spain", 8]],
  {"Turkey": R("Kıbrıs Doğu Akdeniz'in kilidi; Venedik'in ticaret ve haçlı ittifakı riski var. || Cyprus is the lock of the eastern Mediterranean; Venice and a crusader league are a risk.",
               O("Kıbrıs'ı fethet (tarihî) || Conquer Cyprus (historical)", "Doğu Akdeniz bizim || The eastern Mediterranean is ours", "Osmanlı Kıbrıs'ı ele geçirdi; Mağusa 1571'de düştü. || The Ottomans conquered Cyprus; Famagusta fell in 1571.", [["buff", "Turkey", "att", 1.15, 10], ["gold", "Turkey", 2.0]]),
               O("Venedik'le barış yap || Make peace with Venice", "Ticaret kazancı || Trade gains", "Osmanlı Venedik'le yeni ticaret şartları yaptı. || The Ottomans agreed new trade terms with Venice.", [["peace", "Turkey", "Italy"], ["gold", "Turkey", 1.0]])),
   "Italy": R("Kıbrıs kuşatıldı. Papa ve Habsburg ile Kutsal Birlik kurmak şart. || Cyprus is besieged. A Holy League with the Pope and the Habsburgs is vital.",
               O("Kutsal Birlik'i kur (tarihî) || Form the Holy League (historical)", "Haçlı donanması || A crusader fleet", "Venedik, Papa ve Habsburg Kutsal Birlik'i kurdu. || Venice, the Pope and the Habsburgs formed the Holy League.", [["rel", "Italy", "Spain", 10], ["buff", "Italy", "att", 1.1, 10]]),
               O("Tek başına direniş || Resist alone", "Gururlu ama riskli || Proud but risky", "Venedik Kıbrıs'ı yalnız savunmaya çalıştı. || Venice tried to defend Cyprus alone.", [["troops", "Italy", -5], ["stab", "Italy", -3]]))},
  icon="landing", scene="landing")

M("lepanto_1571", 1571, 10, "İnebahtı Deniz Savaşı || The Battle of Lepanto",
  "Kutsal Birlik donanması, Ali Paşa'nın Osmanlı donanmasını İnebahtı Körfezi'nde yendi. Kadırgalar birbirine yaklaştı ve savaş çarpışma, top ve arkebüzle sürdü. Osmanlı kayıp verdi ama bir yılda donanmayı yeniledi. || The Holy League fleet defeated Ali Pasha's Ottoman fleet in the Gulf of Patras. The galleys closed together and the battle went on with boarding, cannon and arquebus. The Ottomans lost heavily but rebuilt their fleet within a year.",
  [["troops", "Turkey", -10], ["stab", "Turkey", -3], ["stab", "Spain", 5], ["stab", "Italy", 3]],
  {"Turkey": R("Ali Paşa Kutsal Birlik donanmasına saldırmak üzere. Donanma sayıca üstün ama topçu zayıf. || Ali Pasha is about to engage the Holy League fleet. You have more ships but weaker gunnery.",
               O("Saldır (tarihî) || Attack (historical)", "Kadırga savaşı || A galley battle", "Osmanlı donanması İnebahtı'da yenildi; ama bir yılda yenilendi. || The Ottoman fleet was beaten at Lepanto but rebuilt within a year.", [["troops", "Turkey", -8], ["buff", "Turkey", "att", 1.1, 4], ["gold", "Turkey", -1.0]]),
               O("Limanda bekle || Wait in port", "Donanma korunur || Fleet preserved", "Osmanlı donanması limanda kaldı. || The Ottoman fleet stayed in port.", [["stab", "Turkey", -2]])),
   "Spain": R("Don Juan komutanlığında Kutsal Birlik hazır. Osmanlı donanmasına saldırmak mı? || The Holy League stands ready under Don Juan. Attack the Ottoman fleet?",
               O("Saldır (tarihî) || Attack (historical)", "Hristiyan zaferi || A Christian victory", "Kutsal Birlik İnebahtı'da büyük zafer kazandı. || The Holy League won a great victory at Lepanto.", [["buff", "Spain", "att", 1.2, 10], ["stab", "Spain", 5], ["rel", "Spain", "Italy", 6]]),
               O("İttifaktan çekil || Leave the League", "Maliyet azalt || Cut costs", "Habsburg ittifaktan sessizce çekildi. || The Habsburgs quietly withdrew from the League.", [["rel", "Spain", "Italy", -8], ["gold", "Spain", 1.0]])),
   "Italy": R("Venedik Kıbrıs'ı kaybetti; Kutsal Birlik ise Venedik'in sonuçları için savaşıyor. || Venice lost Cyprus; the League fights for Venice's interests.",
               O("Birlikle savaş (tarihî) || Fight with the League (historical)", "Donanmayı yenile || Renew the fleet", "Venedik gemileri İnebahtı'da kilit rol oynadı. || Venetian ships played a key role at Lepanto.", [["buff", "Italy", "att", 1.15, 8], ["stab", "Italy", 4]]),
               O("Osmanlı'yla ayrı barış || A separate peace with the Ottomans", "Ticareti kurtar || Save trade", "Venedik 1573'te Osmanlı'yla ayrı barış imzaladı. || Venice signed a separate peace with the Ottomans in 1573.", [["peace", "Italy", "Turkey"], ["rel", "Italy", "Spain", -8]]))},
  icon="carrier", scene="carrier")
save()

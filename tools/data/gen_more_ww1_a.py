from gen_more_ww1 import *

M("july_crisis", 1914, 7, "Temmuz Krizi || The July Crisis",
  "Saraybosna'da Arşidük Franz Ferdinand vuruldu. Viyana Sırbistan'a ağır bir ültimatom hazırlıyor; Berlin 'açık çek' verdi, Rusya Sırp kardeşliğini bırakmak istemiyor. Avrupa ittifaklar ağıyla kaymaya başladı. || Archduke Franz Ferdinand was shot in Sarajevo. Vienna is preparing a harsh ultimatum to Serbia; Berlin has given a 'blank cheque' and Russia will not abandon Serbia. Europe begins to slide along its web of alliances.",
  [["rel", "Austria", "Russia", -8], ["rel", "Germany", "Russia", -5]],
  {"Austria": R("Ültimatom 48 saat süreli, Sırbistan'ın egemenliğini zedeleyecek maddeler içeriyor. Ya Sırbistan'ı cezalandıracaksın ya da imparatorluğun itibarı çökecek. || The ultimatum is limited to 48 hours and includes clauses that violate Serbian sovereignty. Either you punish Serbia or the empire's prestige collapses.",
                O("Ültimatomu ver (tarihî) || Deliver the ultimatum (historical)", "Savaş neredeyse kaçınılmaz || War is almost inevitable", "Viyana ültimatomu verdi; Sırbistan reddetti, savaş kapıda. || Vienna delivered the ultimatum; Serbia refused and war is at the door.", [["buff", "Austria", "att", 1.1, 8], ["rel", "Austria", "Russia", -10], ["rel", "Austria", "Germany", 8]]),
                O("Konferans iste || Ask for a conference", "Diplomasi, ama Almanya hayal kırıklığına uğrar || Diplomacy, but Germany will be disappointed", "Viyana sakin kalmayı seçti; kriz sürüyor. || Vienna chose calm; the crisis drags on.", [["rel", "Austria", "Germany", -6], ["stab", "Austria", 3]])),
   "Germany": R("Kayzer Viyana'ya 'açık çek' verdi. Genelkurmay Rusya'nın seferberliği tamamlamadan harekete geçmeyi istiyor. || The Kaiser gave Vienna a 'blank cheque'. The General Staff wants to move before Russia completes mobilization.",
                O("Avusturya'yı sonuna dek destekle (tarihî) || Back Austria to the hilt (historical)", "İttifak sağlam, ama kriz tırmanıyor || The alliance is firm, but the crisis escalates", "Berlin Viyana'ya tam destek verdi. || Berlin gave Vienna full support.", [["rel", "Germany", "Austria", 10], ["rel", "Germany", "Russia", -8], ["rel", "Germany", "United Kingdom", -5]]),
                O("Viyana'yı dizginle || Restrain Vienna", "Savaşı önlemeye çalış || Try to prevent war", "Berlin Viyana'ya itidal çağrısı yaptı. || Berlin urged Vienna to show restraint.", [["rel", "Germany", "Austria", -5], ["rel", "Germany", "United Kingdom", 6], ["stab", "Germany", -2]])),
   "Russia": R("Çar Sırbistan'ı yalnız bırakmak istemiyor; seferberlik ise Almanya'yı da savaşa çekebilir. || The Tsar does not want to leave Serbia alone; yet mobilization could drag Germany into the war too.",
               O("Kısmi seferberlik, sonra genel (tarihî) || Partial then general mobilization (historical)", "Sırbistan'ı koru, Almanya'yı kızdır || Protect Serbia, anger Germany", "Rusya seferberlik ilan etti. || Russia declared mobilization.", [["troops", "Russia", 6], ["rel", "Russia", "Germany", -10], ["rel", "Russia", "France", 6]]),
               O("Arabuluculuk iste || Ask for mediation", "Zaman kazan || Buy time", "Petersburg uluslararası arabuluculuk istedi. || St Petersburg asked for international mediation.", [["rel", "Russia", "Germany", 3], ["stab", "Russia", 2]]))},
  icon="warning", scene="crisis")

M("christmas_truce", 1914, 12, "Noel Ateşkesi || The Christmas Truce",
  "Batı Cephesi'nde Noel gecesi bazı hatlarda silahlar sustu; askerler 'kimsenin toprağı'nda buluşup hediyeleşti. Komutanlar bunun tekrarlanmasını yasaklamak istiyor. || On Christmas Eve on parts of the Western Front the guns fell silent; soldiers met in no man's land and exchanged gifts. Commanders want to forbid a repeat.",
  [["stab", "Germany", 2], ["stab", "France", 2], ["stab", "United Kingdom", 2]],
  {"Germany": R("Askerler Noel şarkıları söylüyor. Bu yakınlaşma savaş azmini kemirebilir. || Soldiers sing carols. This fraternisation could erode the will to fight.",
                O("Yasakla, disiplin uygula (tarihî) || Forbid it and enforce discipline", "Savaş azmi korunur || The fighting spirit is preserved", "Berlin yasak getirdi; cephede disiplin sıkılaştı. || Berlin forbade it; discipline tightened at the front.", [["stab", "Germany", -1], ["buff", "Germany", "att", 1.05, 6]]),
                O("Göz yum || Turn a blind eye", "Moral artar ama ordu yumuşar || Morale rises but the army softens", "Cephede moral yükseldi. || Morale rose at the front.", [["stab", "Germany", 3], ["buff", "Germany", "att", 0.95, 6]])),
   "United Kingdom": R("Yüksek komuta 'dostluk' haberlerinden rahatsız; ama askerin moraline de ihtiyaç var. || High Command is uneasy about 'fraternisation', yet the men's morale matters too.",
                O("Yasakla (tarihî) || Forbid it (historical)", "Disiplin korunur || Discipline is preserved", "Londra emir verdi: bir daha ateşkes yok. || London ordered: no more truces.", [["buff", "United Kingdom", "att", 1.05, 6], ["stab", "United Kingdom", -1]]),
                O("Göz yum || Turn a blind eye", "Moral ve itibar || Morale and prestige", "Askerler Noel'i rahat geçirdi. || The troops enjoyed a calmer Christmas.", [["stab", "United Kingdom", 3]]))},
  icon="dove", scene="peace", major=False)

M("dardanelles_navy", 1915, 3, "Boğaz'a Donanma Saldırısı || The Naval Attack on the Straits",
  "Müttefik donanması 18 Mart'ta Çanakkale Boğazı'nı zorlamaya girişti; mayın hattı ve sahil bataryaları üç zırhlıyı batırdı. Osmanlı cephanesi tükenmek üzereydi. || On 18 March the Allied fleet tried to force the Dardanelles; the minefield and shore batteries sank three battleships. Ottoman ammunition was nearly exhausted.",
  [["stab", "Turkey", 6], ["stab", "United Kingdom", -2]],
  {"Turkey": R("Donanma saldırısı püskürtüldü ama cephane azaldı. Müttefikler kara harekâtına geçebilir. || The naval attack was repelled but ammunition is low. The Allies may turn to a land campaign.",
               O("Mayın hatlarını yenile (tarihî) || Renew the minefields (historical)", "Boğaz'ı kapalı tut || Keep the Straits closed", "Yeni mayınlar döşendi; Boğaz geçilmez kaldı. || New mines were laid; the Straits stayed impassable.", [["buff", "Turkey", "def", 1.15, 20], ["gold", "Turkey", -1]]),
               O("Almanya'dan cephane iste || Ask Germany for ammunition", "Bağımlılık artar || Dependence grows", "Berlin cephane gönderdi. || Berlin sent ammunition.", [["rel", "Turkey", "Germany", 8], ["buff", "Turkey", "def", 1.1, 20]])),
   "United Kingdom": R("Churchill donanmanın başarısız olduğunu kabul etmek istemiyor; kayıplar ağır. || Churchill does not want to admit the fleet failed; the losses are heavy.",
               O("Kara çıkarması planla (tarihî) || Plan a land invasion (historical)", "Büyük kumar || A great gamble", "Londra Gelibolu çıkarması için emir verdi. || London ordered the Gallipoli landing.", [["troops", "United Kingdom", -3], ["rel", "United Kingdom", "Turkey", -5]]),
               O("Vazgeç || Give up", "Kayıplar durur, itibar sarsılır || Losses stop, prestige suffers", "Londra Boğaz planından vazgeçti. || London abandoned the Straits plan.", [["stab", "United Kingdom", -2], ["gold", "United Kingdom", 1]]), )},
  icon="ship", scene="naval")

M("isonzo", 1915, 6, "İzonzo Cephesi Açıldı || The Isonzo Front Opens",
  "İtalya Londra Antlaşması ile İtilaf safında savaşa girdi ve Avusturya'ya saldırdı. Alp dağlarında ve İzonzo Nehri boyunca yıllarca sürecek kanlı bir mevzi savaşı başlıyor. || Italy joined the Entente under the Treaty of London and attacked Austria. A bloody positional war begins in the Alps and along the Isonzo river that will last for years.",
  [["war", "Italy", "Austria"], ["stab", "Austria", -1]],
  {"Italy": R("Cadorna ilk taarruzu Trieste'ye yönlendirmek istiyor; dağlık arazi savunmacıyı avantajlı kılıyor. || Cadorna wants the first offensive to head for Trieste; the mountains favour the defender.",
              O("İzonzo'ya yüklen (tarihî) || Press on the Isonzo (historical)", "Çok kayıp, az kazanç || Heavy losses, little gain", "İtalyan ordusu İzonzo'da ilk taarruzunu başlattı. || The Italian army launched its first attack on the Isonzo.", [["war", "Italy", "Austria"], ["buff", "Italy", "att", 1.1, 10], ["troops", "Italy", -5], ["rel", "Italy", "United Kingdom", 6]]),
              O("Savunmada kal, ordunu hazırla || Stay on the defensive and prepare", "Zaman kazan || Buy time", "Roma taarruzu erteledi. || Rome postponed the offensive.", [["stab", "Italy", 2], ["rel", "Italy", "United Kingdom", -3]])),
   "Austria": R("İkinci cephe sizi zorluyor; Galiçya'dan takviye çekmek gerekebilir. || A second front strains you; you may have to pull reinforcements from Galicia.",
              O("Dağ hatlarını tahkim et || Fortify the mountain lines", "Savunmacı avantajı kullan || Use the defender's advantage", "Avusturya İzonzo hattını tahkim etti. || Austria fortified the Isonzo line.", [["buff", "Austria", "def", 1.2, 20], ["gold", "Austria", -1]]),
              O("Galiçya'dan birlik çek || Pull units from Galicia", "Doğuyu zayıflat || Weaken the East", "Birlikler İtalyan cephesine kaydırıldı. || Units were shifted to the Italian front.", [["troops", "Austria", 3], ["buff", "Russia", "att", 1.05, 8]]))},
  icon="flag", scene="pre_border")

M("kut_siege", 1916, 4, "Kut Kuşatması || The Siege of Kut",
  "Irak'ta Kut-ül-Amâre'de kuşatılan İngiliz-Hint garnizonu açlıkla karşı karşıya. Kurtarma girişimleri başarısız; Halil Paşa'nın ordusu ablukayı sıkılaştırıyor. || The British-Indian garrison besieged at Kut al-Amara in Iraq faces starvation. Relief attempts have failed; Halil Pasha's army tightens the blockade.",
  [["stab", "Turkey", 4], ["stab", "United Kingdom", -3]],
  {"Turkey": R("Kut teslim olmak üzere. Mezopotamya cephesinin kaderini belirleyecek bir zafer. || Kut is about to surrender. A victory that could decide the fate of the Mesopotamian front.",
               O("Kuşatmayı sürdür (tarihî) || Maintain the siege (historical)", "Zaferi kesinleştir || Seal the victory", "Kut teslim oldu; on binlerce esir alındı. || Kut surrendered; thousands of prisoners were taken.", [["buff", "Turkey", "def", 1.1, 20], ["stab", "Turkey", 6], ["rel", "Turkey", "Germany", 3]]),
               O("Şartlı teslim teklif et || Offer terms", "Daha az kayıp || Fewer losses", "Garnizon müzakereli teslim oldu. || The garrison surrendered by agreement.", [["stab", "Turkey", 2], ["rel", "Turkey", "United Kingdom", 2]])),
   "United Kingdom": R("Kut'a ikmal ulaşmıyor; kurtarma ordusu bataklıkta çaresiz. || Supplies do not reach Kut; the relief force is stuck in the marshes.",
               O("Kurtarma için büyük taarruz || Launch a great relief attack", "Ağır kayıp riski || High risk of losses", "İngiliz kurtarma ordusu bir kez daha saldırdı. || The British relief force attacked once more.", [["troops", "United Kingdom", -4], ["stab", "United Kingdom", -2]]),
               O("Müzakere et, teslim ol (tarihî) || Negotiate and surrender (historical)", "Büyük prestij kaybı || A big loss of prestige", "Londra'da Kut'un düşüşü hayal kırıklığı yarattı. || Kut's fall caused dismay in London.", [["stab", "United Kingdom", -4], ["rel", "United Kingdom", "Turkey", -3]]))},
  icon="tank", scene="pre_siege")

M("jutland", 1916, 5, "Jutland Deniz Savaşı || The Battle of Jutland",
  "Kuzey Denizi'nde iki dev donanma karşılaştı: Scheer'in Açık Deniz Filosu ile Jellicoe'nun Grand Fleet'i. Kayıp İngiltere'de fazla, ama Alman filosu bir daha limandan çıkmaya cesaret edemeyecek. || Two giant fleets met in the North Sea: Scheer's High Seas Fleet and Jellicoe's Grand Fleet. British losses were higher, yet the German fleet will hardly dare leave harbour again.",
  [["stab", "Germany", 3], ["stab", "United Kingdom", -1]],
  {"United Kingdom": R("Churchill'in sözüyle Jellicoe 'savaşı öğleden sonra kaybedebilecek tek adam'. Riske girmeli misin? || In Churchill's words Jellicoe is 'the only man who could lose the war in an afternoon'. Should you take the risk?",
                O("Temkinli kal, ablukayı koru (tarihî) || Stay cautious, keep the blockade (historical)", "Deniz üstünlüğü sürer || Naval supremacy continues", "Grand Fleet ablukayı sürdürdü. || The Grand Fleet kept up the blockade.", [["buff", "United Kingdom", "def", 1.1, 20], ["gold", "Germany", -1]]),
                O("Kesin muharebeye zorla || Force a decisive battle", "Büyük risk, büyük ödül || High risk, high reward", "Britanya filosu Alman filosunu kovaladı. || The British fleet pursued the German fleet.", [["troops", "United Kingdom", -3], ["buff", "United Kingdom", "att", 1.1, 8]])),
   "Germany": R("Filo İngiliz abluka hattını kırmak istiyor; Scheer ağır ve riskli bir seçimle karşı karşıya. || The fleet wants to break the British blockade line; Scheer faces a heavy and risky choice.",
                O("Eve dön, denizaltıya yüklen (tarihî) || Go home and turn to submarines (historical)", "Yüzey filosu limanda kalır || The surface fleet stays in port", "Alman filosu limanlara döndü; denizaltı harbi öne çıktı. || The German fleet returned to port; submarine warfare came to the fore.", [["stab", "Germany", 2], ["rel", "Germany", "United States of America", -3]]),
                O("Yeniden denize çık || Sail again", "Abluka kırılabilir || The blockade might break", "Alman filosu yeniden denize açıldı. || The German fleet sailed again.", [["troops", "Germany", -3], ["buff", "Germany", "att", 1.05, 8]]))},
  icon="ship", scene="naval")

M("brusilov", 1916, 6, "Brusilov Taarruzu || The Brusilov Offensive",
  "General Brusilov cephenin dar bir kesiminde değil, geniş bir hatta aynı anda saldırdı: Avusturya-Macaristan ordusu çöküyor, Almanya Verdun'dan tümen çekmek zorunda kalıyor. || General Brusilov attacked not at one narrow point but along a broad line: the Austro-Hungarian army is collapsing and Germany has to pull divisions away from Verdun.",
  [["troops", "Austria", -6], ["troops", "Russia", -3], ["stab", "Austria", -3]],
  {"Russia": R("Taarruz beklenmedik bir başarı; ama ikmal ve rezerv sınırlı. Ne kadar ileri gideceksin? || The attack is an unexpected success; but supplies and reserves are limited. How far will you go?",
               O("Zaferi sonuna dek sür (tarihî) || Exploit to the end (historical)", "Kayıplar çok, kazanç büyük || Heavy losses, big gains", "Rus ordusu Galiçya'da yüz kilometre ilerledi. || The Russian army advanced a hundred kilometres in Galicia.", [["buff", "Russia", "att", 1.2, 8], ["troops", "Russia", -6], ["stab", "Russia", -2]]),
               O("Mevzileri tut, orduyu koru || Hold ground, preserve the army", "Zayıf bir başarı || A modest success", "Brusilov durdu; Alman takviyeleri geldi. || Brusilov halted; German reinforcements arrived.", [["stab", "Russia", 1]])),
   "Austria": R("Cephe çöküyor. Alman yardımı mı, geri çekilme mi? || The front is collapsing. German help, or retreat?",
               O("Almanya'dan komuta devri iste || Hand command to Germany", "Bağımsızlık kaybı || Loss of independence", "Alman generaller Avusturya birliklerinin komutasını aldı. || German generals took command of Austrian units.", [["rel", "Austria", "Germany", 8], ["stab", "Austria", -3]]),
               O("Kendi başına geri çekil || Withdraw on your own", "Kayıp az, itibar kaybı || Fewer losses, loss of prestige", "Avusturya hattı geri çekti. || Austria pulled back its line.", [["troops", "Austria", -3], ["stab", "Austria", -2]]))},
  icon="helmet_ww1", scene="ww1_assault")


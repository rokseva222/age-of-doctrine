import os
os.environ["ERA"] = "cw62"
from gen_more_ww1 import *

M("indopak_1965", 1965, 9, "1965 Hint–Pakistan Savaşı || The 1965 Indo-Pakistani War",
  "Pakistan Keşmir'e 'Gibraltar Harekâtı' ile sızmacı gönderdi; Hindistan Lahor yönünde karşılık verdi. Tank savaşları Pencap'ta kızışıyor; BM ateşkes arıyor. || Pakistan sent infiltrators into Kashmir under Operation Gibraltar; India answered with a thrust toward Lahore. Tank battles rage in Punjab; the UN is pressing for a ceasefire.",
  [["war", "India", "Pakistan"], ["troops", "India", -4], ["troops", "Pakistan", -4]],
  {"India": R("Şastri Lahor'a doğru ilerleme emri verdi; ama çatışma uzarsa Çin müdahale edebilir. || Shastri ordered an advance toward Lahore; but a long conflict could draw in China.",
              O("Lahor'a yüklen || Press toward Lahore", "Askerî baskı || Military pressure", "Hint birlikleri Lahor kapılarına dayandı. || Indian troops reached the gates of Lahore.", [["buff", "India", "att", 1.15, 8], ["troops", "India", -4]]),
              O("Ateşkesi kabul et (tarihî) || Accept the ceasefire (historical)", "Taşkent'te müzakere || Talks at Tashkent", "Hindistan ateşkesi kabul etti; Taşkent'te anlaşma imzalandı. || India accepted the ceasefire; the Tashkent agreement was signed.", [["peace", "India", "Pakistan"], ["stab", "India", 3]])),
   "Pakistan": R("Keşmir halk ayaklanması beklentisi gerçekleşmedi; Hint ordusu Pencap'ta. || The hoped-for Kashmiri uprising did not come; the Indian army is in Punjab.",
              O("Savunmada diren || Stand on the defensive", "Lahor'u koru || Defend Lahore", "Pakistan Lahor hattını tuttu. || Pakistan held the Lahore line.", [["buff", "Pakistan", "def", 1.2, 8], ["stab", "Pakistan", 3]]),
              O("Ateşkes iste (tarihî) || Accept the ceasefire (historical)", "Çin ve ABD desteği sınırlı || Limited Chinese and US support", "Pakistan BM ateşkesini kabul etti. || Pakistan accepted the UN ceasefire.", [["peace", "Pakistan", "India"], ["stab", "Pakistan", -3]]))},
  icon="tank", scene="crisis")

M("tet_1968", 1968, 1, "Tet Taarruzu || The Tet Offensive",
  "Kuzey Vietnam ve Vietkong Tet bayramında Güney Vietnam'ın şehirlerine saldırdı; Saygon'daki ABD büyükelçiliği bile vuruldu. Askerî açıdan yenilgi, siyasi açıdan Amerikan kamuoyu için şok. || North Vietnamese and Viet Cong forces struck South Vietnamese cities during Tet; even the US embassy in Saigon was hit. A military defeat for them but a political shock for American opinion.",
  [["stab", "United States of America", -6], ["troops", "Vietnam", -8], ["rel", "United States of America", "Russia", -4]],
  {"United States of America": R("Westmoreland takviye istiyor; Kongre ve halk savaştan bıkıyor. || Westmoreland asks for reinforcements; Congress and the public are tiring of the war.",
              O("Takviye gönder || Send reinforcements", "Savaşı yoğunlaştır || Escalate", "Washington daha fazla asker gönderdi; kamuoyu tepkisi büyüdü. || Washington sent more troops; public backlash grew.", [["buff", "United States of America", "att", 1.1, 10], ["stab", "United States of America", -5]]),
              O("Vietnamlaştırma ve müzakere (tarihî) || Vietnamisation and talks (historical)", "Çıkış stratejisi || An exit strategy", "Johnson yeniden aday olmayacağını açıkladı; Paris görüşmeleri başladı. || Johnson announced he would not seek re-election; the Paris talks began.", [["stab", "United States of America", 3], ["rel", "United States of America", "Russia", 3]])),
   "Vietnam": R("Taarruz şehirlerde halk ayaklanması getirmedi ama Amerikan iradesini kırdı. || The offensive did not spark a popular uprising but cracked American will.",
              O("Uzun savaşı sürdür (tarihî) || Prolong the war (historical)", "Sabır en güçlü silah || Patience is the strongest weapon", "Hanoi uzun savaş stratejisini sürdürdü. || Hanoi continued its protracted-war strategy.", [["buff", "Vietnam", "def", 1.2, 20], ["stab", "Vietnam", 4]]),
              O("Müzakere masasına otur || Go to the negotiating table", "Paris'te pazarlık || Bargaining in Paris", "Hanoi Paris görüşmelerine katıldı. || Hanoi joined the Paris talks.", [["rel", "Vietnam", "United States of America", 6], ["gold", "Vietnam", 0.5]]))},
  icon="helmet_ww2", scene="crisis")

M("bangladesh_1971", 1971, 12, "Bangladeş Kurtuluş Savaşı || The Bangladesh Liberation War",
  "Doğu Pakistan'daki ayaklanma Hindistan'ın müdahalesine dönüştü. Hindistan 14 günde Dakka'yı kuşattı; Pakistan ordusu teslim oldu ve Bangladeş doğdu. || The uprising in East Pakistan became an Indian intervention. India encircled Dhaka in 14 days; the Pakistani army surrendered and Bangladesh was born.",
  [["war", "India", "Pakistan"], ["stab", "Pakistan", -8], ["troops", "Pakistan", -10]],
  {"India": R("Milyonlarca mülteci Hindistan'a aktı; Gandhi Doğu Pakistan'da askerî çözüm arıyor. || Millions of refugees poured into India; Gandhi seeks a military solution in East Pakistan.",
              O("Dakka'ya yüklen (tarihî) || Drive on Dhaka (historical)", "Bağımsız Bangladeş || An independent Bangladesh", "Hint ordusu Dakka'yı kuşattı; Pakistan teslim oldu. || The Indian army surrounded Dhaka; Pakistan surrendered.", [["buff", "India", "att", 1.2, 6], ["stab", "India", 6], ["gold", "India", 1.0]]),
              O("Sadece sınırı koru || Only secure the border", "Çatışma sınırlı kalır || The conflict stays limited", "Hindistan sınırda kaldı. || India stayed at the border.", [["stab", "India", -2]])),
   "Pakistan": R("Yahya Han'ın ordusu iki cephede; ABD ve Çin destek sözü verdi ama gelmedi. || Yahya Khan's army is fighting on two fronts; the US and China promised support that never came.",
              O("Batıda karşı taarruz yap || Counterattack in the West", "İkinci cephe aç || Open a second front", "Pakistan batıda taarruza geçti; sonuç sınırlı kaldı. || Pakistan attacked in the West with limited results.", [["buff", "Pakistan", "att", 1.1, 6], ["troops", "Pakistan", -5]]),
              O("Teslim ol (tarihî) || Surrender (historical)", "Kayıpları durdur || Stop the losses", "Pakistan Dakka'da teslim oldu. || Pakistan surrendered at Dhaka.", [["peace", "Pakistan", "India"], ["stab", "Pakistan", -8]])),
   "Bangladesh": R("Mukti Bahini ve Hindistan'ın desteğiyle bağımsızlık ilan edildi. || Independence was declared with Mukti Bahini and India's backing.",
              O("Bağımsızlığı ilan et (tarihî) || Declare independence (historical)", "Yeni devlet || A new state", "Bangladeş bağımsızlığını ilan etti. || Bangladesh declared independence.", [["stab", "Bangladesh", 6], ["rel", "Bangladesh", "India", 10]]),
              O("Hindistan'a bağımlı olma || Avoid dependence on India", "Bağımsız çizgi || An independent line", "Dakka dengeli bir dış politika izledi. || Dhaka pursued a balanced foreign policy.", [["rel", "Bangladesh", "India", -4], ["stab", "Bangladesh", 2]]))},
  icon="flag", scene="crisis")

M("yom_kippur_1973", 1973, 10, "Yom Kippur Savaşı || The Yom Kippur War",
  "Mısır ve Suriye, Yom Kippur günü Süveyş ve Golan'da sürpriz saldırı başlattı. İsrail ilk günlerde geri adım attı; sonra karşı saldırıya geçti. Arap petrol ambargosu dünya ekonomisini sarsıyor. || Egypt and Syria launched a surprise attack on Yom Kippur at Suez and the Golan. Israel fell back in the first days, then counterattacked. The Arab oil embargo is shaking the world economy.",
  [["war", "Egypt", "Israel"], ["war", "Syria", "Israel"], ["gold", "United States of America", -1.0], ["gold", "Saudi Arabia", 2.0]],
  {"Israel": R("Sürpriz saldırıda ağır kayıp; Golda Meir ABD'den acil silah yardımı istiyor. || Heavy losses in the surprise attack; Golda Meir is asking the US for urgent arms.",
              O("Karşı taarruz (tarihî) || Counterattack (historical)", "Süveyş'i geç, Şam'a yönel || Cross Suez, drive toward Damascus", "İsrail Süveyş'i geçti ve Şam yoluna çıktı. || Israel crossed Suez and pushed toward Damascus.", [["buff", "Israel", "att", 1.2, 8], ["rel", "Israel", "United States of America", 8], ["troops", "Israel", -4]]),
              O("Savunmada kal || Hold the line", "Kayıp azalt || Cut losses", "İsrail savunmada kaldı. || Israel stayed on the defensive.", [["buff", "Israel", "def", 1.2, 8]])),
   "Egypt": R("Sedat ilk günlerde Süveyş'i geçti. Şimdi daha derine mi ilerleyeceksin? || Sadat crossed Suez in the first days. Will you go deeper?",
              O("Bar-Lev Hattı'nı tut (tarihî) || Hold the Bar-Lev line (historical)", "Siyasi hedef || The political goal", "Mısır kazandığı bölgeyi tuttu; ateşkes görüşmeleri başladı. || Egypt held its gains; ceasefire talks began.", [["stab", "Egypt", 6], ["buff", "Egypt", "def", 1.15, 8]]),
              O("Sina geçitlerine ilerle || Advance to the Sinai passes", "Cesur ama riskli || Bold but risky", "Mısır zırhlıları Sina'da ilerledi ve ağır kayıp verdi. || Egyptian armour advanced into Sinai and took heavy losses.", [["troops", "Egypt", -6], ["buff", "Egypt", "att", 1.1, 4]])),
   "Saudi Arabia": R("Faysal petrol silahını kullanabilir; Batı'ya ihracat durdurulabilir. || Faisal could use the oil weapon; exports to the West could be halted.",
              O("Petrol ambargosu uygula (tarihî) || Impose the oil embargo (historical)", "Fiyatlar fırlar || Prices soar", "Suudi Arabistan Batı'ya petrol ambargosu koydu. || Saudi Arabia imposed an oil embargo on the West.", [["gold", "Saudi Arabia", 3.0], ["rel", "Saudi Arabia", "United States of America", -8]]),
              O("Ambargodan kaçın || Avoid the embargo", "Batı ile ilişkiyi koru || Keep Western ties", "Riyad ambargoya katılmadı. || Riyadh stayed out of the embargo.", [["rel", "Saudi Arabia", "United States of America", 6]]))},
  icon="tank", scene="crisis")

M("saigon_1975", 1975, 4, "Saygon'un Düşüşü || The Fall of Saigon",
  "Kuzey Vietnam tankları 30 Nisan'da Saygon'daki Bağımsızlık Sarayı'na girdi. Amerikan helikopterleri büyükelçilikten son kaçanları tahliye ediyor; Vietnam yeniden birleşiyor. || North Vietnamese tanks entered the Independence Palace in Saigon on 30 April. American helicopters evacuate the last escapees from the embassy; Vietnam is reunified.",
  [["stab", "Vietnam", 6], ["stab", "United States of America", -4], ["rel", "United States of America", "Vietnam", -10]],
  {"Vietnam": R("Zafer geldi; ülke yeniden birleşiyor. Kamboçya ve Çin ile sınır sorunları büyüyor. || Victory has come; the country is reunified. Border issues with Cambodia and China loom.",
              O("Yeniden birleşmeyi tamamla (tarihî) || Complete reunification (historical)", "Tek Vietnam || One Vietnam", "Vietnam resmen birleşti. || Vietnam was formally reunified.", [["stab", "Vietnam", 6], ["gold", "Vietnam", 1.0]]),
              O("Sovyet desteğini artır || Deepen Soviet ties", "Güvenlik ittifakı || A security alliance", "Hanoi Moskova ile yakınlaştı. || Hanoi moved closer to Moscow.", [["rel", "Vietnam", "Russia", 10], ["rel", "Vietnam", "China", -6]])),
   "United States of America": R("Vietnam Savaşı sona erdi; Watergate ve ekonomik kriz sonrası Amerika iç meselelerine dönüyor. || The Vietnam War is over; after Watergate and economic crisis America turns inward.",
              O("Askerleri eve getir (tarihî) || Bring the troops home (historical)", "Yara sarma dönemi || Time to heal", "Washington Güneydoğu Asya'dan çekildi. || Washington withdrew from Southeast Asia.", [["stab", "United States of America", 3], ["gold", "United States of America", 1.0]]),
              O("Müttefikleri destekle || Back your allies", "Yeni taahhütler || New commitments", "Amerika bölgesel müttefiklerine güvence verdi. || America reassured regional allies.", [["rel", "United States of America", "South Korea", 6], ["gold", "United States of America", -1.0]]))},
  icon="helmet_ww2", scene="crisis")

M("iran_rev_1979", 1979, 2, "İran Devrimi || The Iranian Revolution",
  "Şah ülkeyi terk etti; Humeyni dönerek İslam Cumhuriyeti'ni ilan etti. ABD'nin Orta Doğu'daki en önemli müttefiki yön değiştirdi; petrol piyasası sarsıldı. || The Shah left the country; Khomeini returned and proclaimed the Islamic Republic. America's key Middle Eastern ally changed course; the oil market was shaken.",
  [["rel", "Iran", "United States of America", -20], ["stab", "Iran", -4], ["gold", "Saudi Arabia", 1.0]],
  {"Iran": R("Halk sokakta; ordu bölünmüş. Devrimin yönü belirsiz: İslamcı, milliyetçi ya da sol. || The people are in the streets; the army is split. The direction of the revolution is uncertain: Islamist, nationalist or left.",
              O("İslam Cumhuriyeti'ni ilan et (tarihî) || Proclaim the Islamic Republic (historical)", "Velayet-i fakih || Guardianship of the jurist", "Humeyni İslam Cumhuriyeti'ni kurdu. || Khomeini founded the Islamic Republic.", [["stab", "Iran", 5], ["rel", "Iran", "United States of America", -10], ["rel", "Iran", "Russia", 2]]),
              O("Seküler bir yönetim kur || Form a secular government", "Liberal geçiş || A liberal transition", "Geçici hükûmet laik bir yol aradı. || The interim government sought a secular path.", [["stab", "Iran", -5], ["rel", "Iran", "United States of America", 4]])),
   "United States of America": R("Carter yönetimi Şah'ın düşüşünü önleyemedi. Yeni rejimle ilişki mi, mesafe mi? || The Carter administration could not prevent the Shah's fall. Engage the new regime or keep your distance?",
              O("Mesafeli kal (tarihî) || Keep your distance (historical)", "Petrolü güvene al || Secure the oil", "Washington İran'la mesafe koydu; Körfez'de varlığını artırdı. || Washington kept its distance from Iran and strengthened its Gulf presence.", [["rel", "United States of America", "Saudi Arabia", 6], ["rel", "United States of America", "Iran", -8]]),
              O("Yeni rejimle temas kur || Reach out to the new regime", "Yumuşama || Detente", "Washington geçici hükûmetle temas kurdu. || Washington made contact with the provisional government.", [["rel", "United States of America", "Iran", 6], ["stab", "United States of America", -2]]))},
  icon="flag", scene="crisis")

M("iran_iraq_1980", 1980, 9, "İran–Irak Savaşı || The Iran–Iraq War",
  "Saddam Hüseyin, İran'ın devrim sonrası zayıflığından yararlanıp Şattülarap ve Hûzistan'ı almak için saldırdı. Sekiz yıl sürecek savaş başladı; Körfez petrolü tehlikede. || Saddam Hussein attacked to seize the Shatt al-Arab and Khuzestan, exploiting Iran's post-revolutionary weakness. A war that will last eight years has begun; Gulf oil is at risk.",
  [["war", "Iraq", "Iran"], ["troops", "Iran", -6], ["troops", "Iraq", -4]],
  {"Iraq": R("Saddam kısa bir zafer bekliyor; İran ordusu ise devrim sonrası dağınık. || Saddam expects a quick victory; Iran's army is in post-revolution disarray.",
              O("Hûzistan'a ilerle (tarihî) || Advance into Khuzestan (historical)", "Hızlı baskın || A quick strike", "Irak ordusu Hûzistan'a girdi ama Horramşehr'de takıldı. || The Iraqi army entered Khuzestan but stalled at Khorramshahr.", [["buff", "Iraq", "att", 1.15, 8], ["troops", "Iraq", -4]]),
              O("Sınırı tahkim et || Fortify the border", "Savunmada kal || Stay defensive", "Irak sınırı tahkim etti. || Iraq fortified the border.", [["buff", "Iraq", "def", 1.15, 12]])),
   "Iran": R("Ordu tasfiye edilmiş; ama Devrim Muhafızları ve halk seferberliği hazır. || The army has been purged; but the Revolutionary Guards and popular mobilisation are ready.",
              O("Halk seferberliği (tarihî) || Mass mobilisation (historical)", "Kutsal Savunma || Sacred Defence", "İran gönüllüleri cepheye akın etti. || Iranian volunteers streamed to the front.", [["mob", "Iran"], ["buff", "Iran", "def", 1.2, 12], ["stab", "Iran", 4]]),
              O("Müzakereye açıl || Open to negotiation", "Taviz || Concessions", "Tahran uluslararası arabuluculuğu aradı. || Tehran sought international mediation.", [["stab", "Iran", -3]])),
   "Saudi Arabia": R("Körfez monarşileri Irak'ı İran'a karşı bir kalkan olarak görüyor. || Gulf monarchies see Iraq as a shield against Iran.",
              O("Irak'ı finanse et (tarihî) || Finance Iraq (historical)", "İran tehdidini dengele || Counter Iran's threat", "Riyad Bağdat'a milyarlarca dolar kredi verdi. || Riyadh lent Baghdad billions of dollars.", [["rel", "Saudi Arabia", "Iraq", 10], ["rel", "Saudi Arabia", "Iran", -8], ["gold", "Saudi Arabia", -1.0]]),
              O("Tarafsız kal || Stay neutral", "Dengeli politika || A balanced policy", "Suudi Arabistan tarafsız kaldı. || Saudi Arabia stayed neutral.", [["stab", "Saudi Arabia", 2]]))},
  icon="tank", scene="crisis")

M("falklands_1982", 1982, 4, "Falkland Savaşı || The Falklands War",
  "Arjantin cuntası 2 Nisan'da Falkland (Malvinas) Adaları'nı işgal etti. Thatcher bir görev filosu gönderdi; deniz ve hava çarpışmaları Güney Atlantik'te sürüyor. || The Argentine junta invaded the Falkland (Malvinas) Islands on 2 April. Thatcher sent a task force; naval and air battles are under way in the South Atlantic.",
  [["war", "Argentina", "United Kingdom"], ["troops", "Argentina", -6], ["stab", "Argentina", -4], ["stab", "United Kingdom", 4]],
  {"United Kingdom": R("Görev filosu 12.000 km uzakta; Exocet füzeleri gemilere tehdit. Adaları geri almak için çıkarma mı? || The task force is 12,000 km away; Exocet missiles threaten the ships. Land to retake the islands?",
              O("Çıkarma yap (tarihî) || Land the force (historical)", "San Carlos çıkarması || The San Carlos landing", "İngiliz birlikleri San Carlos'a çıktı ve Port Stanley'e yürüdü. || British troops landed at San Carlos and marched on Port Stanley.", [["buff", "United Kingdom", "att", 1.2, 10], ["stab", "United Kingdom", 4], ["troops", "United Kingdom", -3]]),
              O("Müzakereyi dene || Try negotiation", "BM arabuluculuğu || UN mediation", "Londra diplomasiyle çözüm aradı. || London sought a diplomatic solution.", [["stab", "United Kingdom", -4], ["rel", "United Kingdom", "Argentina", 4]])),
   "Argentina": R("Galtieri halkın desteğini kazandı; ama İngiliz donanması yaklaşıyor. || Galtieri won popular support; but the British fleet is approaching.",
              O("Adaları tahkim et (tarihî) || Fortify the islands (historical)", "Müdafaa || Defence", "Arjantin adalarda siper kazdı; hava gücüyle karşılık verdi. || Argentina dug in on the islands and responded with air power.", [["buff", "Argentina", "def", 1.2, 10], ["stab", "Argentina", 3]]),
              O("Geri çekil || Withdraw", "Savaştan kaç || Avoid war", "Arjantin birliklerini geri çekmeyi düşündü. || Argentina considered withdrawing its troops.", [["stab", "Argentina", -6], ["troops", "Argentina", 3]]))},
  icon="carrier", scene="carrier")
save()

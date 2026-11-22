#!/usr/bin/env python3
"""Çeçen savaşları: ch94 (Aralık 1994 – 1997, Birinci Çeçen Savaşı), ch99 (Ağustos 1999 – 2009, Terörle Mücadele Harekâtı)
ve "c" varyantları (oyuncu doğrudan Çeçenistan'ı oynar) için data/eras/*.json + data/moments/*.json üretir.
Modern harita/silah tablosu kullanılır (arsenal yok); çağa özel teknoloji düzeyi "tech_ovr" ile verilir.
Çeçenistan, Rusya'dan koparılan tek eyalet olan Chechnya (1851) ile kurulan özel devlettir ("custom_0").
Çalıştır: python3 tools/data/gen_chechnya.py"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from moment_kit import Kit, keep_defaults

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
def rd(p): return json.load(open(os.path.join(ROOT, p), encoding="utf-8"))
def wr(p, d):
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write("\n")

US = "United States of America"; UK = "United Kingdom"; RU = "Russia"; TR = "Turkey"; GE = "Georgia"; AZ = "Azerbaijan"
AM = "Armenia"; UA = "Ukraine"; BY = "Belarus"; KZ = "Kazakhstan"; CH = "custom_0"
P_CH, P_ING, P_DAG, P_STA = 1851, 1850, 230, 1852        # Çeçenistan, İnguşetya, Dağıstan, Stavropol


def P(s):
    """'TR || EN' -> (tr, en)"""
    a, b = s.split(" || ")
    return (a.strip(), b.strip())


k = Kit()
def O(t, d, fx, r, keep=None):
    return k.opt(P(t), P(d), fx, P(r), keep)
def R(text, *opts):
    return k.role(P(text), *opts)
def M(id, y, m, title, text, roles, dfx, icon="tank", scene="crisis", major=True, requires=None, forbid=None):
    t = P(title)
    k.title_en[t[0]] = t[1]
    return k.moment(id, t, P(text), roles, dfx, y=y, m=m, icon=icon, scene=scene, major=major, requires=requires, forbid=forbid)


# ====================================================================== 1994-97: Birinci Çeçen Savaşı
def moments94():
    L = []
    L.append(M("c94_aralik", 1994, 12, "Anayasal Düzenin Yeniden Tesisi || Restoring Constitutional Order",
        "Cahar Dudayev'in Çeçenistan'ı 1991'den beri fiilen bağımsız. 26 Kasım'da Moskova'nın desteklediği muhalefetin Grozni'ye tank saldırısı çöktü, 'gizli' Rus askerleri esir düştü. 9 Aralık'ta Yeltsin'in 2169 sayılı fermanı 'anayasal düzenin yeniden tesisi'ni emretti. || Dzhokhar Dudayev's Chechnya has been de facto independent since 1991. On 26 November a Moscow-backed opposition tank assault on Grozny collapsed and 'undercover' Russian soldiers were captured. On 9 December Yeltsin's decree 2169 ordered the 'restoration of constitutional order'.",
        {RU: R("Savunma Bakanı Graçov 'bir paraşüt alayıyla birkaç saatte' Grozni'yi alacağını söylüyor. Güvenlik Konseyi savaştan yana; ordu hazırlıksız, kış kapıda. || Defence Minister Grachev claims one airborne regiment could take Grozny in hours. The Security Council wants war; the army is unprepared and winter is near.",
                O("Topyekûn harekât (tarihî) || Full-scale operation (historical)", "Üç koldan Grozni'ye; Çeçenistan'la savaş || Three columns on Grozny; war with Chechnya",
                  [["war", RU, CH, "solo"], ["troops", RU, 4], ["buff", RU, "att", 1.15, 6], ["stab", RU, -3], ["flag", "c94_war"]],
                  "11 Aralık'ta Rus zırhlı sütunları Çeçenistan sınırını geçti; savaş başladı. || On 11 December Russian armoured columns crossed into Chechnya; the war has begun."),
                O("Müzakere: Yeltsin–Dudayev görüşmesi || Talks: Yeltsin–Dudayev meeting", "Savaş yok; Dudayev Moskova'ya çağrılır || No war; Dudayev summoned to Moscow",
                  [["rel", RU, CH, 10], ["xstab", RU, -2], ["flag", "c94_talks"]],
                  "Dudayev 'ancak eşit statüde' diyerek Moskova'ya gitmeyi reddetti; kriz sürüyor. || Dudayev refused to go to Moscow except as an equal; the crisis drags on."),
                O("Muhalefeti gizlice silahlandır || Covertly arm the opposition", "Doğrudan savaş yerine vekil güç || A proxy instead of open war",
                  [["rel", RU, CH, -15], ["stab", CH, -4], ["flag", "c94_talks"]],
                  "Kremlin Çeçen muhalefetine para ve silah akıtıyor; Grozni gergin. || The Kremlin pours money and arms to the Chechen opposition; Grozny is tense.")),
         CH: R("Dudayev: 'Rusya bizi yeniden köleleştiremez.' Ordu 15 bin kadar; elde Sovyet kalıntısı silahlar ve uçaklar var, ama uçaklar ilk günlerde yerde vurulabilir. || Dudayev: 'Russia cannot enslave us again.' The army numbers about 15,000, with leftover Soviet arms and aircraft, though the aircraft may be destroyed on the ground in the first days.",
                O("Grozni'yi savun || Defend Grozny", "Şehir savunması, her sokak bir mevzi || City defence, every street a position",
                  [["war", RU, CH, "solo"], ["troops", CH, 40], ["buff", CH, "def", 1.3, 12], ["buff", RU, "att", 0.3, 13], ["xstab", CH, 4], ["flag", "c94_war"]],
                  "Çeçen birlikleri Grozni'de mevzilendi; Rus sütunları şehre yaklaşıyor. || Chechen units dug in around Grozny as Russian columns approach."),
                O("Kafkas halklarından yardım iste || Call on the Caucasian peoples", "Gönüllüler ve para, ama Rus saldırısı durmaz || Volunteers and money, but the attack will come",
                  [["war", RU, CH, "solo"], ["troops", CH, 25], ["buff", RU, "att", 0.3, 13], ["gold", CH, 1.0], ["rel", CH, TR, 10], ["flag", "c94_war"]],
                  "Kuzey Kafkasya ve diasporadan gönüllüler Grozni'ye akıyor. || Volunteers from the North Caucasus and the diaspora flow into Grozny."),
                O("Moskova'ya müzakere teklif et || Offer talks to Moscow", "Savaşı geciktirmeye çalış || Try to delay the war",
                  [["rel", CH, RU, 10], ["xstab", CH, -2], ["flag", "c94_talks"]],
                  "Dudayev barış teklifi gönderdi; Moskova cevap vermiyor. || Dudayev sent a peace offer; Moscow does not answer.")),
         TR: R("Türkiye'de milyonlarca Kafkas kökenli vatandaş var; kamuoyu Çeçenlerin yanında. Çiller hükümeti ise Rusya'yla ticarete ve doğalgaza bağlı. || Millions of Turkish citizens have Caucasian roots and public opinion sides with the Chechens. The Çiller government depends on trade and gas with Russia.",
                O("Rusya'nın iç meselesi || An internal affair of Russia", "Sessiz kal, ticareti koru || Stay quiet, protect trade",
                  [["rel", TR, RU, 5], ["xstab", TR, -2]], "Ankara savaşı 'Rusya'nın iç meselesi' olarak niteledi; diaspora tepkili. || Ankara called the war 'Russia's internal affair'; the diaspora is angry."),
                O("İnsani yardım ve kınama || Humanitarian aid and condemnation", "Kızılay yardımı, diplomatik tepki || Red Crescent aid and a diplomatic protest",
                  [["rel", TR, RU, -8], ["rel", TR, CH, 15], ["xstab", TR, 2]], "Türkiye Çeçen sivillere insani yardım gönderdi ve Moskova'yı uyardı. || Turkey sent humanitarian aid to Chechen civilians and warned Moscow."),
                O("Diasporanın açık desteğine göz yum || Tolerate open diaspora support", "Gönüllüler ve bağış kampanyaları || Volunteers and fundraising",
                  [["rel", TR, RU, -15], ["rel", TR, CH, 25], ["xstab", TR, -1]], "Türkiye'deki dernekler bağış topluyor; Rusya Ankara'yı sert uyardı. || Associations in Turkey collect donations; Russia sharply warned Ankara.")),
         US: R("Clinton, Yeltsin'e siyaseten bağlı: reformların başarısı için Yeltsin lazım. Kongre ise insan hakları ihlalleri konusunda rahatsız. || Clinton is politically tied to Yeltsin: the reforms need him to survive. Congress is uneasy about human rights abuses.",
                O("'İç mesele' çizgisi (tarihî) || 'Internal affair' line (historical)", "Yeltsin'i destekle || Back Yeltsin",
                  [["rel", US, RU, 3]], "Washington savaşı 'Rusya'nın iç meselesi' diye niteledi. || Washington described the war as 'an internal matter of Russia'."),
                O("Sert eleştiri || Sharp criticism", "İnsan hakları baskısı || Human rights pressure",
                  [["rel", US, RU, -8]], "Beyaz Saray bombalamaları 'kabul edilemez' buldu. || The White House called the bombing 'unacceptable'."))},
        [["troops", RU, 3], ["rel", RU, CH, -40], ["stab", RU, -3], ["flag", "c94_war"]]))

    L.append(M("c94_ocak", 1995, 1, "Yılbaşı Taarruzu || The New Year's Storm",
        "31 Aralık'ta Rus zırhlı birlikleri Grozni'ye daldı; Mayköp tugayı şehirde yok edildi. Rusya havadan ve topçuyla şehri dövmeye başladı; 19 Ocak'ta Cumhurbaşkanlığı Sarayı düştü. || On 31 December Russian armour rolled into Grozny; the Maykop brigade was destroyed in the city. Russia began to pound it from the air and with artillery; the Presidential Palace fell on 19 January.",
        {RU: R("Zırhlı sütunlar dar sokaklarda RPG'lerle avlanıyor; zayiat ağır, ordunun morali kırık. Karar: şehri yerle bir etmek mi, kuşatmak mı? || Armoured columns are hunted with RPGs in narrow streets; casualties are heavy and morale is broken. Level the city or encircle it?",
                O("Topçu ve hava bombardımanı (tarihî) || Artillery and air bombardment", "Şehri ezerek ele geçir || Take the city by crushing it",
                  [["buff", RU, "att", 1.15, 8], ["unrest", P_CH, 20], ["rel", RU, US, -4], ["stab", RU, -3]],
                  "Grozni haftalarca topçu ve bombalarla dövüldü; sivil kayıplar uluslararası öfke yarattı. || Grozny was pounded by artillery and bombs for weeks; civilian losses stirred international anger."),
                O("Şehri kuşat, mahalle mahalle ilerle || Encircle and advance block by block", "Yavaş ama düşük kayıp || Slower, fewer losses",
                  [["troops", RU, 2], ["xstab", RU, -2]], "Genelkurmay şehri kuşatıp mahalle mahalle ilerlemeye karar verdi. || The General Staff chose to encircle the city and advance block by block."),
                O("Ateşkes ve görüşme iste || Ask for a ceasefire and talks", "Savaşı durdur || Halt the war",
                  [["peace", RU, CH], ["xstab", RU, -5], ["stab", CH, 3]], "Moskova şaşkın bir ateşkes ilan etti. || Moscow announced a bewildered ceasefire.")),
         CH: R("Şehir sizin: bodrumlar, çatılar, RPG'ler. Basayev'in ve Maskhadov'un adamları zırhlıları yakıyor. Ama bombardıman eşiği aşıyor. || The city is yours: cellars, rooftops, RPGs. Basayev's and Maskhadov's men burn armour. But the bombardment is crossing every limit.",
                O("Sokak savaşı: şehri tutmaya devam et || Street fighting: hold the city", "Her bina bir kale || Every building a fortress",
                  [["buff", CH, "def", 1.3, 10], ["troops", CH, 25], ["xstab", CH, 3]], "Çeçenler her sokakta Rus zırhlılarını avlıyor; Grozni direniyor. || The Chechens hunt Russian armour in every street; Grozny holds out."),
                O("Sivilleri tahliye et, saraydan çekil || Evacuate civilians, leave the palace", "Kayıpları azalt || Cut losses",
                  [["stab", CH, 3], ["troops", CH, 10], ["rel", CH, TR, 8]], "Sivil tahliyesi başladı; Çeçen birlikleri nehrin güneyine çekiliyor. || Civilian evacuation began; Chechen units pull back south of the river.")),
         TR: R("Türkiye'de Kafkas dernekleri sokaklarda; Dışişleri 'bölgesel bütünlük' ve 'insani trajedi' arasında ince bir çizgide. || Caucasian associations are in the streets in Turkey; the Foreign Ministry walks a thin line between territorial integrity and humanitarian tragedy.",
                O("Güvenlik Konseyi / AGİT'e çağrı || Appeal to the UN / OSCE", "Çok taraflı baskı || Multilateral pressure",
                  [["rel", TR, RU, -5], ["rel", TR, US, 3]], "Ankara bombardımanın durdurulması için AGİT ve BM'ye çağrı yaptı. || Ankara appealed to the OSCE and the UN to halt the bombing."),
                O("Ticareti öncele, sessiz kal || Put trade first, stay quiet", "Rusya'yla ilişkiyi koru || Keep relations with Russia",
                  [["rel", TR, RU, 4], ["xstab", TR, -2]], "Ankara resmî tepkiyi sınırlı tuttu; sokaktaki öfke büyüyor. || Ankara kept its official reaction limited; anger in the streets grows."))},
        [["buff", RU, "att", 1.1, 8], ["buff", CH, "def", 1.2, 8], ["stab", RU, -4], ["unrest", P_CH, 15], ["rel", RU, US, -3]],
        icon="flame", scene="crisis"))

    L.append(M("c94_mart", 1995, 3, "Grozni Düştü || Grozny Falls",
        "Mart başında Rus birlikleri Grozni'nin tamamını kontrol etti; Çeçen kuvvetleri güneydeki dağlara (Argun, Şali, Vedeno) çekildi. Moskova 'zafer' ilan etti, ama savaş bitmedi: gerilla dönemi başlıyor. || By early March Russian forces controlled all of Grozny; the Chechens withdrew to the southern mountains (Argun, Shali, Vedeno). Moscow declared victory but the war is not over: the guerrilla phase begins.",
        {RU: R("Başkent elinizde ama köyler elinizde değil. Gece pusuları ve mayınlar her gün zayiat veriyor. || You hold the capital but not the villages. Night ambushes and mines cost casualties every day.",
                O("Dağlara taarruz: Argun, Şali, Vedeno || Offensive into the mountains", "Gerilla üslerini temizle || Clear the guerrilla bases",
                  [["buff", RU, "att", 1.1, 10], ["troops", RU, 2], ["stab", RU, -2]], "Rus birlikleri Argun, Şali ve Vedeno'ya ilerliyor. || Russian forces advance on Argun, Shali and Vedeno."),
                O("Zafer ilan et, müzakereye otur || Claim victory and negotiate", "Savaşı siyasî çözüme çek || Move to a political settlement",
                  [["peace", RU, CH], ["stab", RU, 2]], "Kremlin zaferini ilan edip Çeçen temsilcilerle görüşmeye hazır olduğunu açıkladı. || The Kremlin declared victory and signalled readiness for talks with Chechen representatives.")),
         CH: R("Grozni gitti ama ordunuz sağlam; dağlar sizin. Artık tanklara karşı sokak savaşı değil, pusu ve baskın savaşı veriyorsunuz. || Grozny is lost but your army is intact and the mountains are yours. It is no longer street fighting against tanks but ambush and raid warfare.",
                O("Gerilla savaşı örgütle || Organise guerrilla war", "Pusu, mayın, baskın || Ambush, mines, raids",
                  [["buff", CH, "def", 1.25, 20], ["troops", CH, 25], ["unrest", P_CH, 25]], "Çeçen müfrezeleri dağlara dağıldı; konvoylar her gün pusuya düşüyor. || Chechen detachments dispersed into the mountains; convoys are ambushed daily."),
                O("Kuzey Kafkasya'yı ayaklandır || Raise the North Caucasus", "Dağıstan ve İnguşetya'dan destek || Support from Dagestan and Ingushetia",
                  [["unrest", P_ING, 15], ["unrest", P_DAG, 10], ["troops", CH, 15], ["rel", CH, TR, 8]], "Çeçen elçiler komşu cumhuriyetlerde destek arıyor. || Chechen envoys seek support in the neighbouring republics."))},
        [["occupy", RU, P_CH], ["unrest", P_CH, 35], ["stab", CH, -8], ["troops", CH, -15], ["flag", "c94_grozny_fell"]],
        icon="flag", scene="pre_siege"))

    L.append(M("c94_nisan", 1995, 4, "Samaşki || Samashki",
        "7–8 Nisan'da Rus iç birliklerinin Samaşki köyündeki 'temizlik' operasyonunda yüzlerce sivil öldü. Avrupa Konseyi Rusya'nın üyelik sürecini dondurdu; 'köy temizleme' operasyonları Rusya'nın savaş imajına en ağır darbe. || On 7–8 April Russian interior troops' 'mopping-up' in Samashki killed hundreds of civilians. The Council of Europe froze Russia's membership process; the village sweeps do the most damage to Russia's image.",
        {RU: R("Kamuoyu savaştan yorgun; anneler Komitesi cepheden dönen cesetleri sayıyor. 9 Mayıs 50. Zafer Yıldönümü için dünya liderleri Moskova'ya geliyor. || Public opinion is war-weary; the Committee of Soldiers' Mothers counts returning bodies. World leaders are coming to Moscow for the 50th Victory Day on 9 May.",
                O("Köy temizliklerini sürdür || Continue the village sweeps", "Direniş desteğini kopar || Cut off the resistance's support",
                  [["unrest", P_CH, 15], ["stab", RU, -2], ["rel", RU, US, -3], ["rel", RU, TR, -4]], "Rus birlikleri ovadaki köyleri taramayı sürdürüyor; mülteci akını artıyor. || Russian forces keep sweeping the villages of the plain; the flow of refugees grows."),
                O("Soruşturma aç, ihlalleri durdur || Open an inquiry and halt abuses", "Uluslararası itibarı koru || Protect international standing",
                  [["rel", RU, US, 3], ["rel", RU, TR, 3], ["xstab", RU, -1]], "Moskova Samaşki için resmî soruşturma açtı. || Moscow opened an official inquiry into Samashki.")),
         CH: R("Katliam, Çeçen halkını her zamankinden fazla birleştirdi: her genç dağa çıkıyor. Dünya basını Grozni'ye değil Samaşki'ye bakıyor. || The massacre united the Chechen people as never before: every young man is heading for the hills. The world press looks not at Grozny but at Samashki.",
                O("Dünya basınına çağrı yap || Appeal to the world press", "Diplomatik baskıyı artır || Raise diplomatic pressure",
                  [["rel", CH, TR, 8], ["rel", CH, US, 4], ["stab", CH, 3]], "Çeçen temsilciler Avrupa başkentlerinde Samaşki'yi anlatıyor. || Chechen envoys tell of Samashki in European capitals."),
                O("Genç gönüllüleri silahlandır || Arm the young volunteers", "Direniş büyür || The resistance grows",
                  [["troops", CH, 30], ["buff", CH, "def", 1.15, 10]], "Köylerden yüzlerce genç gerilla birliklerine katıldı. || Hundreds of young men from the villages joined the guerrilla units."))},
        [["stab", RU, -2], ["rel", RU, US, -3], ["rel", RU, TR, -4], ["unrest", P_CH, 20], ["troops", CH, 15]],
        icon="warning", scene="crisis", major=False))

    L.append(M("c94_haziran", 1995, 6, "Budyonnovsk || Budyonnovsk",
        "14 Haziran: Şamil Basayev komutasındaki ~150 savaşçı Stavropol'daki Budyonnovsk'ta hastaneyi bastı ve 1.500 rehine aldı. Rus özel kuvvetlerinin baskını başarısız oldu; Başbakan Çernomırdin Basayev'le telefonla pazarlık etti. || 14 June: about 150 fighters under Shamil Basayev seized the hospital in Budyonnovsk, Stavropol, taking 1,500 hostages. A Russian special forces assault failed; Prime Minister Chernomyrdin negotiated with Basayev by phone.",
        {RU: R("Kremlin ağır bir darbe aldı: 'sonuna kadar savaş' çizgisiyle 1.500 sivilin hayatı arasında seçim yapılıyor. || The Kremlin took a heavy blow: a choice between 'war to the end' and the lives of 1,500 civilians.",
                O("Çernomırdin'in pazarlığı (tarihî) || Chernomyrdin's deal (historical)", "Rehineler için geçit ve ateşkes görüşmesi || Safe passage for hostages and ceasefire talks",
                  [["peace", RU, CH], ["stab", RU, -3], ["buff", CH, "att", 1.1, 8], ["flag", "c94_ceasefire"]], "Çernomırdin–Basayev pazarlığıyla rehineler serbest kaldı; 30 Haziran'da askerî anlaşma imzalandı. || The Chernomyrdin–Basayev bargain freed the hostages; a military accord was signed on 30 June."),
                O("İkinci baskın, pazarlık yok || Second assault, no bargaining", "Sert tutum || Hard line",
                  [["stab", RU, -5], ["unrest", P_STA, 15], ["xstab", RU, -2]], "Moskova pazarlığı reddetti; hastane ikinci kez bombalandı. || Moscow refused to bargain; the hospital was stormed a second time.")),
         CH: R("Basayev'in baskını savaşın seyrini değiştirebilir: Moskova ya geri adım atacak ya da halkına gaddar görünecek. Fakat sivil rehine almak sizi diplomatik olarak yalnızlaştırır. || Basayev's raid may change the course of the war: Moscow will either back down or look brutal to its own people. But taking civilian hostages isolates you diplomatically.",
                O("Basayev'in baskınına sahip çık || Own Basayev's raid", "Pazarlık gücü kazan || Gain bargaining power",
                  [["peace", RU, CH], ["stab", CH, 5], ["buff", CH, "att", 1.15, 10], ["rel", CH, TR, -5], ["flag", "c94_ceasefire"]], "Basayev'in adamları çıkış koridoruyla dağlara döndü; müzakere kapısı aralandı. || Basayev's men returned to the mountains through a corridor; the door to negotiations opened."),
                O("Baskını kınama, rehineleri serbest bırak || Disown the raid, release hostages", "Diplomatik itibarı koru || Protect diplomatic standing",
                  [["rel", CH, TR, 6], ["rel", CH, US, 3], ["stab", CH, -2]], "Dudayev kamuoyuna rehinelerin serbest bırakılması çağrısı yaptı. || Dudayev publicly called for the hostages' release."))},
        [["stab", RU, -5], ["buff", CH, "att", 1.15, 10], ["stab", CH, 5], ["unrest", P_STA, 15], ["flag", "c94_budyonnovsk"]],
        icon="warning", scene="crisis"))

    L.append(M("c94_aralik95", 1995, 12, "Gudermes, Seçimler ve Zavgayev || Gudermes, Elections and Zavgayev",
        "Aralık 1995: Çeçenler Gudermes'i kısa süre ele geçirdi, Rusya Duma seçimi ve Çeçenistan 'yönetim başkanı' seçimini aynı günlere denk getirdi. Moskova'nın adamı Doku Zavgayev seçildi, ama Çeçenlerin çoğu oyu tanımadı. || December 1995: the Chechens briefly held Gudermes while Russia held Duma elections and a 'head of administration' vote in Chechnya. Moscow's man, Doku Zavgayev, 'won', but most Chechens did not recognise the vote.",
        {RU: R("Seçim kampanyası başlıyor. Yeltsin'in reytingi dipte; Zavgayev'in 'Çeçen hükümeti' göstermelik ama bir ara çözüm olabilir. || The election campaign begins. Yeltsin's ratings are at rock bottom; Zavgayev's 'Chechen government' is a facade but may be an interim solution.",
                O("Zavgayev'i destekle (tarihî) || Back Zavgayev (historical)", "Çeçenleştirme ilk deneme || First try at 'Chechenisation'",
                  [["unrest", P_CH, -10], ["stab", RU, 2], ["rel", RU, CH, -5]], "Moskova Zavgayev'in hükümetini tanıdı; Grozni'de güvenlik önlemleri artırıldı. || Moscow recognised Zavgayev's government; security in Grozny was tightened."),
                O("Seçim sonrası yeni taarruz || A new offensive after the elections", "Direnişin kökünü kazı || Root out the resistance",
                  [["buff", RU, "att", 1.1, 8], ["troops", RU, 2], ["stab", RU, -2]], "Genelkurmay kış taarruzu için takviye istedi. || The General Staff requested reinforcements for a winter offensive.")),
         CH: R("Gudermes baskını Rus garnizonunu sarstı ama Zavgayev seçimi Moskova'ya hukuki bir paravan sağlıyor. Köylerde 'seçime katılma' baskısı var. || The Gudermes raid shook the Russian garrison but Zavgayev's vote gives Moscow a legal fig leaf. There is pressure in the villages to 'take part'.",
                O("Seçimi boykot et, direnişi sürdür || Boycott the vote, keep fighting", "Meşruiyeti koru || Keep legitimacy",
                  [["stab", CH, 2], ["buff", CH, "def", 1.1, 10], ["unrest", P_CH, 10]], "Çeçen komutanlar seçimi 'sahte' ilan etti. || Chechen commanders declared the vote a 'sham'."),
                O("Kuzey Kafkasya'ya baskın: Gudermes ve Kızlyar hazırlığı || Raid the North Caucasus: prepare Gudermes and Kizlyar", "Dağıstan'a uzan || Reach into Dagestan",
                  [["unrest", P_DAG, 15], ["troops", CH, 15]], "Salman Radüyev'in müfrezeleri kuzeye hazırlanıyor. || Salman Raduyev's detachments prepare to move north."))},
        [["stab", RU, 2], ["unrest", P_CH, -5], ["rel", RU, CH, -5]],
        icon="treaty", scene="pre_court", major=False))

    L.append(M("c94_ocak96", 1996, 1, "Kızlyar ve Avrasya Feribotu || Kizlyar and the Avrasya Ferry",
        "9 Ocak: Radüyev Dağıstan'ın Kızlyar kentini bastı, 3.000 rehine aldı ve Pervomayskoye köyüne çekildi; Rus topçusu köyü yerle bir etti. 16 Ocak'ta Trabzon–Soçi seferindeki Türk feribotu Avrasya, Çeçen davası adına kaçırıldı; kaçırıcılar 19 Ocak'ta İstanbul'da teslim oldu. || 9 January: Raduyev raided Kizlyar in Dagestan, took 3,000 hostages and fell back on Pervomayskoye, which Russian artillery flattened. On 16 January the Turkish ferry Avrasya (Trabzon–Sochi) was hijacked in the name of the Chechen cause; the hijackers surrendered in Istanbul on 19 January.",
        {TR: R("Karadeniz'de 200 kadar yolcusu ve çok sayıda Rus vatandaşıyla bir Türk feribotu kaçırıldı; Boğaz'a yöneliyor. Hem Rusya'yla ilişki hem iç kamuoyu hassas bir dengede. || A Turkish ferry with some 200 passengers, many of them Russian citizens, was hijacked on the Black Sea and is heading for the Bosphorus. Relations with Russia and domestic opinion are in a delicate balance.",
                O("Pazarlık ve ikna (tarihî) || Negotiate and persuade (historical)", "Kaçırıcıları teslim olmaya ikna et || Persuade the hijackers to surrender",
                  [["rel", TR, RU, 8], ["xstab", TR, 2]], "Müzakere ve diplomasiyle kaçırıcılar 19 Ocak'ta rehineleri bırakıp teslim oldu; Rusya Türkiye'ye teşekkür etti. || Through negotiation the hijackers released the hostages and surrendered on 19 January; Russia thanked Turkey."),
                O("Sert müdahale hazırlığı || Prepare a forced entry", "Boğaz'da operasyon || An operation in the Bosphorus",
                  [["rel", TR, RU, 3], ["xstab", TR, -4], ["rel", TR, CH, -10]], "Ankara komandoları Boğaz'da alarma geçirdi; kriz tehlikeli biçimde gerildi. || Ankara put commandos on alert in the Bosphorus; the crisis grew dangerously tense."),
                O("Çeçen davasına anlayış göster || Show understanding for the Chechen cause", "Kaçırıcılarla görüş, kamuoyu mesajı || Talk to hijackers, send a public message",
                  [["rel", TR, RU, -8], ["rel", TR, CH, 12], ["xstab", TR, -2]], "Ankara kaçırıcıların taleplerini dinleyeceğini duyurdu; Moskova tepki gösterdi. || Ankara said it would hear the hijackers' demands; Moscow reacted angrily.")),
         RU: R("Radüyev'in Kızlyar baskını Dağıstan'ı savaşın içine çekiyor; Pervomayskoye'de rehinelerle birlikte köyü topa tutmak 'başarısız ve kanlı' bir fiyaskoya dönüştü. Yeltsin'in seçim yılı. || Raduyev's Kizlyar raid pulls Dagestan into the war; shelling Pervomayskoye with hostages inside became a bloody fiasco. It is Yeltsin's election year.",
                O("Pervomayskoye'yi top ateşine tut (tarihî) || Shell Pervomayskoye (historical)", "Sert yanıt, ağır eleştiri || Hard response, heavy criticism",
                  [["stab", RU, -4], ["unrest", P_DAG, 15], ["buff", RU, "att", 1.05, 6]], "Rus topçusu köyü haftalarca dövdü; Radüyev yarma yaptı ve kaçtı. || Russian artillery shelled the village for days; Raduyev broke through and escaped."),
                O("Müzakere ve rehine değişimi || Negotiate and exchange hostages", "Daha az kayıp || Fewer losses",
                  [["xstab", RU, -2], ["unrest", P_DAG, 8]], "Moskova Dağıstan hükümeti aracılığıyla pazarlığa oturdu. || Moscow bargained through the Dagestani authorities.")),
         CH: R("Radüyev Dudayev'in akrabası ve 'ordu generali' unvanlı bir şahsiyet; baskın size büyük prestij kazandırdı ama Dağıstan halkını da korkuttu. || Raduyev is Dudayev's relative and a self-styled army general; the raid gave you prestige but frightened the people of Dagestan.",
                O("Baskını sahiplen || Claim the raid", "Moskova'yı köşeye sıkıştır || Corner Moscow",
                  [["buff", CH, "att", 1.1, 8], ["unrest", P_DAG, 15], ["rel", CH, TR, 5], ["stab", CH, 3]], "Çeçen komutanlar baskını 'Rusya'nın kalbine bir mesaj' diye sundu. || Chechen commanders presented the raid as 'a message to the heart of Russia'."),
                O("Dağıstan'a ilişkin sorumluluğu reddet || Distance yourselves from the raid", "Komşulukları koru || Preserve neighbourly ties",
                  [["rel", CH, TR, 4], ["stab", CH, -2]], "Dudayev'in danışmanları baskını 'bağımsız eylem' olarak niteledi. || Dudayev's advisers described the raid as an 'independent action'."))},
        [["unrest", P_DAG, 20], ["rel", RU, TR, -3], ["stab", RU, -3], ["xstab", TR, -1]],
        icon="border_clash", scene="border"))

    L.append(M("c94_nisan96", 1996, 4, "Dudayev Öldürüldü || Dudayev Is Killed",
        "21 Nisan 1996: Cahar Dudayev uydu telefonuyla konuşurken sinyalini izleyen bir Rus savaş uçağının güdümlü füzesiyle öldürüldü. Yerine Zelimhan Yandarbiyev geçti; askerî komuta Maskhadov'da. || 21 April 1996: Dzhokhar Dudayev was killed by a guided missile from a Russian aircraft that tracked his satellite phone call. Zelimkhan Yandarbiyev succeeded him; military command rests with Maskhadov.",
        {RU: R("Dudayev'in ölümü Yeltsin'e seçim öncesi 'başarı' sağlıyor; ama direniş liderin ölümüyle durmuyor. Barış planı için bir pencere açıldı. || Dudayev's death gives Yeltsin a pre-election success; but the resistance does not end with its leader. A window for a peace plan has opened.",
                O("Barış planını ilan et || Announce a peace plan", "Ateşkes ve kademeli çekilme || Ceasefire and gradual withdrawal",
                  [["xstab", RU, 2], ["rel", RU, CH, 10], ["flag", "c94_peace_plan"]], "Yeltsin 31 Mart planını genişletip Çeçenlerle yeni görüşme önerdi. || Yeltsin broadened his 31 March plan and offered fresh talks to the Chechens."),
                O("Baskıyı artır: lidersiz bırak || Press on: leaderless resistance", "Diğer komutanları da hedef al || Target other commanders",
                  [["buff", RU, "att", 1.1, 8], ["stab", CH, -4]], "Rus birlikleri komutanları hedef alan yeni taarruzlar başlattı. || Russian forces began new offensives targeting commanders.")),
         CH: R("Dudayev şehit düştü; halk yastayken Yandarbiyev, Maskhadov ve Basayev arasında nüfuz mücadelesi başlayabilir. || Dudayev is dead; as the people mourn, a struggle for influence among Yandarbiyev, Maskhadov and Basayev may begin.",
                O("Yandarbiyev'e destek ver, birliği koru || Rally behind Yandarbiyev", "Komuta birliği || Unity of command",
                  [["stab", CH, 6], ["buff", CH, "def", 1.1, 10]], "Komutanlar Yandarbiyev'in etrafında birleşti. || The commanders rallied around Yandarbiyev."),
                O("Maskhadov'u askerî komutan yap || Make Maskhadov military commander", "Daha profesyonel savaş || More professional warfare",
                  [["troops", CH, 15], ["buff", CH, "att", 1.1, 10], ["stab", CH, 2]], "Maskhadov bütün sahra komutanlığını üstlendi. || Maskhadov took over all field command."))},
        [["stab", CH, -10], ["xstab", RU, 2], ["flag", "c94_dudayev_dead"]],
        icon="missile", scene="crisis"))

    L.append(M("c94_mayis96", 1996, 5, "Moskova Ateşkesi || The Moscow Ceasefire",
        "27 Mayıs: Yeltsin Kremlin'de Yandarbiyev'le görüştü, ateşkes ve esir değişimi imzalandı; ertesi gün Grozni'ye giderek 'zaferi' ilan etti. Seçim kampanyasının en güçlü sahnesi. || 27 May: Yeltsin met Yandarbiyev in the Kremlin and a ceasefire and prisoner exchange were signed; the next day he flew to Chechnya to declare 'victory'. The strongest scene of his election campaign.",
        {RU: R("Seçime on hafta kala 'savaşı bitiren başkan' imajı değerli. Ordu ateşkesten memnun değil; Çeçenler ise zaman kazanıyor. || Ten weeks before the vote, the 'president who ended the war' image is valuable. The army dislikes the ceasefire and the Chechens are gaining time.",
                O("Ateşkes ve seçim kampanyası (tarihî) || Ceasefire and campaign (historical)", "Savaşı dondur || Freeze the war",
                  [["peace", RU, CH], ["stab", RU, 3], ["rel", RU, CH, 10], ["flag", "c94_ceasefire"]], "Yeltsin Grozni'de askerlere 'zafer' dedi; seçim kampanyası sürüyor. || Yeltsin hailed 'victory' to the troops in Grozny; the campaign goes on."),
                O("Ateşkesi reddet, harekâtı sürdür || Reject the ceasefire", "Askerî çözüm || Military solution",
                  [["stab", RU, -3], ["buff", RU, "att", 1.1, 8]], "Kremlin ateşkesten vazgeçti; Seçim öncesi savaş sürüyor. || The Kremlin dropped the ceasefire; the war continues ahead of the election.")),
         CH: R("Ateşkes dinlenme ve yeniden toparlanma fırsatı; ama Yeltsin imza töreninden sonra seçimi kazanıp ardından saldırabilir. || The ceasefire is a chance to rest and regroup; but Yeltsin may win the election and strike again afterwards.",
                O("Ateşkesi kabul et || Accept the ceasefire", "Zaman kazan || Buy time",
                  [["peace", RU, CH], ["stab", CH, 4], ["troops", CH, 15], ["flag", "c94_ceasefire"]], "Yandarbiyev ateşkesi imzaladı; Çeçen müfrezeleri toparlandı. || Yandarbiyev signed the ceasefire; Chechen units regrouped."),
                O("Ateşkesi reddet, Grozni'ye hazırlan || Reject it and prepare for Grozny", "Taarruz planı || An offensive plan",
                  [["troops", CH, 25], ["buff", CH, "att", 1.15, 12], ["stab", CH, 1]], "Basayev ve Maskhadov gizlice Grozni planı hazırlıyor. || Basayev and Maskhadov are secretly preparing a plan for Grozny."))},
        [["peace", RU, CH], ["stab", RU, 3], ["rel", RU, CH, 10], ["flag", "c94_ceasefire"]],
        icon="dove", scene="peace"))

    L.append(M("c94_agustos96", 1996, 8, "Cihat Harekâtı || Operation Jihad",
        "6 Ağustos: Yeltsin'in yemin töreni günü Çeçen birlikleri Grozni'ye sızarak şehri üç yönden bastı; 12.000'lik Rus garnizonu kuşatıldı. Pulikovski şehri boşaltma ültimatomu verdi, Lebed Güvenlik Konseyi'nde barış yanlısı. || 6 August: on the eve of Yeltsin's inauguration Chechen forces infiltrated and stormed Grozny from three sides, trapping the 12,000-strong Russian garrison. General Pulikovsky issued an ultimatum to evacuate the city; Lebed, at the Security Council, favours peace.",
        {RU: R("Seçimi kazandınız ama Grozni'yi kaybediyorsunuz. Pulikovski kenti bombardımana hazır; Lebed ise ordunun savaşı kazanamayacağını söylüyor. || You won the election but are losing Grozny. Pulikovsky is ready to bomb the city; Lebed says the army cannot win the war.",
                O("Pulikovski'nin ültimatomu: şehri topa tut || Pulikovsky's ultimatum: pound the city", "Direnişi ezmeyi dene || Try to crush the resistance",
                  [["buff", RU, "att", 1.15, 6], ["stab", RU, -5], ["unrest", P_CH, 15]], "Rus topçusu şehre ateş açtı; sivil kayıp, Moskova'da öfke. || Russian artillery opened fire on the city; civilian losses and anger in Moscow."),
                O("Lebed'e tam yetki: müzakere (tarihî) || Full authority to Lebed: negotiate", "Savaşı bitirme girişimi || Try to end the war",
                  [["xstab", RU, 1], ["rel", RU, CH, 5], ["flag", "c94_lebed"]], "Yeltsin Lebed'i Çeçenistan'a gönderdi; ordu şaşkın. || Yeltsin sent Lebed to Chechnya; the army is bewildered.")),
         CH: R("Birkaç yüz savaşçı koca bir şehri geri aldı: bu, orduların sembolik felaketi. Ama müzakere masasına güçlü oturmak için iyi bir fırsat. || A few hundred fighters retook a whole city: a symbolic disaster for the army. It is also a chance to sit at the table from strength.",
                O("Grozni'yi geri al (tarihî) || Retake Grozny (historical)", "Rus garnizonunu kuşat || Trap the Russian garrison",
                  [["occupy", CH, P_CH], ["war", RU, CH, "solo"], ["buff", CH, "att", 1.2, 8], ["stab", CH, 8], ["troops", CH, 20], ["flag", "c94_jihad"]],
                  "Çeçen birlikleri Grozni'yi geri aldı; Rus garnizonu çember içinde. || Chechen forces retook Grozny; the Russian garrison is surrounded."),
                O("Kısmi baskın, görüşme zemini hazırla || Limited raid, prepare for talks", "Güç göster, sonra masaya otur || Show strength, then talk",
                  [["buff", CH, "att", 1.1, 6], ["stab", CH, 3], ["rel", CH, RU, 5]], "Çeçen komutanlar Grozni'de güç gösterip Lebed'le temasa geçti. || Chechen commanders showed strength in Grozny and made contact with Lebed."))},
        [["occupy", CH, P_CH], ["stab", RU, -6], ["stab", CH, 10], ["troops", CH, 15], ["flag", "c94_jihad"]],
        icon="flame", scene="pre_assault"))

    L.append(M("c94_eylul96", 1996, 9, "Hasavyurt Anlaşması || The Khasavyurt Accord",
        "31 Ağustos: Lebed ve Maskhadov Dağıstan'ın Hasavyurt kasabasında ateşkes ve çekilme anlaşmasını imzaladı: Rus birlikleri çekilecek, Çeçenistan'ın statüsü 31 Aralık 2001'e bırakılacak. İlk savaş fiilen sona erdi. || 31 August: Lebed and Maskhadov signed a ceasefire and withdrawal accord in the Dagestani town of Khasavyurt: Russian troops will leave and Chechnya's status is deferred to 31 December 2001. The first war effectively ended.",
        {RU: R("Savaşı kazanamayacağınızı kabul eden bir anlaşma; Yeltsin'in sağlığı kötü, ordu kırgın, ama savaşın bedeli çok yüksek. || An agreement that admits the war cannot be won: Yeltsin's health is poor and the army is embittered, but the war's cost has become too high.",
                O("Hasavyurt'u imzala (tarihî) || Sign Khasavyurt (historical)", "Barış; statü ertelenir || Peace; status deferred",
                  [["peace", RU, CH], ["stab", RU, -3], ["rel", RU, CH, 10], ["flag", "c94_khasavyurt"]], "Lebed–Maskhadov anlaşmasıyla Rus birlikleri Aralık sonuna dek çekildi. || Under the Lebed–Maskhadov deal Russian troops pulled out by the end of December."),
                O("Reddet, harekâta devam || Reject it and continue the war", "Savaşı sürdür || Fight on",
                  [["stab", RU, -4], ["buff", RU, "att", 1.1, 10]], "Genelkurmay anlaşmayı reddetti; Lebed'in nüfuzu zayıfladı. || The General Staff rejected the deal; Lebed's authority weakened.")),
         CH: R("Savaşı fiilen kazandınız: Rus birlikleri çekiliyor, ama bağımsızlık henüz tanınmadı. Ülke harap, ekonomi yok, silahlı komutanlar çok. || You have effectively won: Russian troops are leaving, but independence has not been recognised. The country is ruined, there is no economy and too many armed commanders.",
                O("Hasavyurt'u kabul et (tarihî) || Accept Khasavyurt (historical)", "Çekilme karşılığı statünün ertelenmesi || Withdrawal in exchange for deferred status",
                  [["peace", RU, CH], ["stab", CH, 8], ["rel", CH, RU, 10], ["flag", "c94_khasavyurt"]], "Çeçenistan'da Rus birlikleri ülkeyi terk ediyor; Grozni'de kutlama. || Russian troops are leaving Chechnya; celebrations in Grozny."),
                O("Tam bağımsızlık tanınmadan çekilmeyi reddet || Refuse without recognition", "Savaşı sürdür || Keep fighting",
                  [["buff", CH, "att", 1.1, 10], ["stab", CH, -3]], "Çeçen komutanlar 'statü ertelenemez' diyerek anlaşmayı reddetti. || Chechen commanders refused, saying 'status cannot be deferred'.")),
         GE: R("Çeçenistan'ın güneyindeki sınır Gürcistan'a komşu. Shevardnadze Abhazya ve Güney Osetya sorunları yüzünden Moskova'yla denge kurmak zorunda. || The border south of Chechnya touches Georgia. Because of Abkhazia and South Ossetia, Shevardnadze must balance with Moscow.",
                O("Tarafsız kal || Stay neutral", "Sınır güvenliğini artır || Tighten border security",
                  [["rel", GE, RU, 3]], "Tiflis sınır birliklerini takviye ederek tarafsızlığını ilan etti. || Tbilisi reinforced border units and declared its neutrality."),
                O("Mültecilere kapıyı aç || Open the door to refugees", "İnsani kriz yönetimi || Handle the humanitarian crisis",
                  [["rel", GE, RU, -4], ["rel", GE, TR, 3]], "Gürcistan'a Pankisi vadisinden mülteci akını başladı. || Refugees began to flow into Georgia through the Pankisi Gorge."))},
        [["peace", RU, CH], ["occupy", CH, P_CH], ["stab", RU, -3], ["stab", CH, 8], ["flag", "c94_khasavyurt"]],
        icon="treaty", scene="peace"))

    L.append(M("c94_ocak97", 1997, 1, "Maskhadov Seçildi || Maskhadov Elected",
        "27 Ocak 1997: AGİT gözetiminde yapılan Çeçenistan cumhurbaşkanlığı seçimini askerî komutan Aslan Maskhadov kazandı. Moskova seçimi 'özgür' bulup sonucu kabul etti; ama bağımsızlığı tanımadı. || 27 January 1997: Aslan Maskhadov, the military commander, won the Chechen presidential election held under OSCE observation. Moscow accepted the vote as free but did not recognise independence.",
        {CH: R("Savaşın galibisiniz; şimdi devlet kurma sınavı. Silahlı komutanlar (Basayev, Radüyev) ve radikal Vahhabi gruplar sizinle rekabet edecek. || You are the victors; now comes the test of state-building. Armed commanders (Basayev, Raduyev) and radical Wahhabi groups will compete with you.",
                O("Moskova'yla yapılanma ve ekonomik işbirliği || Rebuild and cooperate with Moscow", "Rusya'yla çerçeve anlaşma || A framework deal with Russia",
                  [["rel", CH, RU, 10], ["stab", CH, 5], ["gold", CH, 0.8]], "Maskhadov Moskova'yla ekonomik işbirliği arayışında. || Maskhadov seeks economic cooperation with Moscow."),
                O("Bağımsızlık söylemini koru, Türkiye ve Körfez'e dön || Insist on independence; turn to Turkey and the Gulf", "Dış destek ara || Seek outside support",
                  [["rel", CH, TR, 12], ["gold", CH, 0.6], ["rel", CH, RU, -5]], "Grozni diaspora ve Körfez bağışçılarıyla temas kuruyor. || Grozny courts the diaspora and Gulf donors."))},
        [["stab", CH, 8], ["rel", CH, RU, 5], ["rel", CH, TR, 8]],
        icon="flag", scene="pre_court", major=False))

    L.append(M("c94_mayis97", 1997, 5, "Barış ve İlişkilerin İlkeleri Antlaşması || Treaty on Peace and the Principles of Relations",
        "12 Mayıs 1997: Yeltsin ve Maskhadov Kremlin'de 'güç kullanmaktan karşılıklı vazgeçme'yi öngören antlaşmayı imzaladı. Yeltsin'e göre savaş bitti; Çeçenler ise Rusya'nın 'bağımsız bir devlet' olarak ilişkiye girdiğini düşünüyor. || 12 May 1997: Yeltsin and Maskhadov signed in the Kremlin a treaty on mutual renunciation of force. For Yeltsin the war is over; the Chechens read the text as Russia treating them as an independent state.",
        {RU: R("Savaş ağır sonuçlandı; ordu yeniden yapılanma ve bütçe sıkıntısında. Antlaşma Moskova için bir tür 'onurlu çıkış'. || The war ended badly; the army is restructuring under budget pressure. The treaty is an 'honourable exit' for Moscow.",
                O("Antlaşmayı imzala (tarihî) || Sign the treaty (historical)", "Barış ve ticaret || Peace and trade",
                  [["peace", RU, CH], ["rel", RU, CH, 20], ["stab", RU, 2]], "Kremlin antlaşmayı imzaladı; bir 'ortak komisyon' kurulacak. || The Kremlin signed; a joint commission will be set up."),
                O("İmzayı geciktir, ekonomik baskıyı artır || Delay and apply economic pressure", "Çeçenistan'ı boğ || Strangle Chechnya",
                  [["rel", RU, CH, -10], ["unrest", P_CH, 10]], "Moskova ödeneklerini kesti; Çeçenistan'da işsizlik artıyor. || Moscow cut subsidies; unemployment in Chechnya is rising.")),
         CH: R("Kremlin'in sizi 'eşit' görmesi büyük sembolik başarı; fakat Rusya sınırı kapalı tutuyor, kaçırma ve çete olayları ülkenin itibarını yıpratıyor. || The Kremlin treating you as 'equal' is a big symbolic win; yet Russia keeps the border shut and kidnappings and bandits damage the country's name.",
                O("Antlaşmayı imzala (tarihî) || Sign the treaty (historical)", "Kısmî tanınma || Partial recognition",
                  [["peace", RU, CH], ["rel", CH, RU, 20], ["stab", CH, 5]], "Maskhadov antlaşmayı imzaladı; Çeçenistan uluslararası alanda 'fiilî devlet' olarak görülüyor. || Maskhadov signed; Chechnya is seen internationally as a de facto state."),
                O("Bağımsızlık olmadan imza atma || Do not sign without recognition", "Sert müzakere || Hold out",
                  [["rel", CH, RU, -5], ["stab", CH, -2]], "Maskhadov imzadan önce tanınma talebini yineledi. || Before signing, Maskhadov repeated his demand for recognition."))},
        [["peace", RU, CH], ["rel", RU, CH, 20], ["stab", CH, 5], ["stab", RU, 2]],
        icon="treaty", scene="peace"))
    return L


# ====================================================================== 1999-2009: Terörle Mücadele
def moments99():
    L = []
    L.append(M("c99_agustos", 1999, 8, "Dağıstan'a Baskın || The Invasion of Dagestan",
        "7 Ağustos 1999: Şamil Basayev ve Arap komutan Hattab komutasında 1.500'e yakın savaşçı Dağıstan'ın dağlık Botlih bölgesine girdi ve 'İslam Devleti' ilan etti. 9 Ağustos'ta Yeltsin Başbakan Stepaşin'i görevden alıp Vladimir Putin'i atadı. || 7 August 1999: about 1,500 fighters under Shamil Basayev and the Arab commander Khattab entered the mountainous Botlikh area of Dagestan and proclaimed an 'Islamic state'. On 9 August Yeltsin dismissed Prime Minister Stepashin and appointed Vladimir Putin.",
        {RU: R("Dağıstan'ın dağlarında köyler elden gidiyor. Yeltsin zayıf, Putin henüz tanınmıyor. Ordu 1996'nın intikamını arıyor. || Villages are slipping away in the mountains of Dagestan. Yeltsin is weak and Putin is barely known. The army wants revenge for 1996.",
                O("Karşı taarruz ve hava harekâtı (tarihî) || Counter-offensive and air strikes (historical)", "Dağıstan'da Basayev'e karşı sert harekât || Hit Basayev's force in Dagestan",
                  [["buff", RU, "att", 1.15, 10], ["troops", RU, 2], ["rel", RU, CH, -20], ["stab", RU, 2], ["flag", "c99_dag"]], "Rus uçakları ve Dağıstan milisleri Botlih'te Basayev'i geri püskürttü. || Russian aircraft and Dagestani militias pushed Basayev back at Botlikh."),
                O("Maskhadov'la müzakere || Negotiate with Maskhadov", "Çeçen hükümetinden Basayev'i durdurmasını iste || Ask Grozny to rein in Basayev",
                  [["rel", RU, CH, 5], ["xstab", RU, -3]], "Moskova Maskhadov'dan Basayev'i kontrol etmesini istedi. || Moscow asked Maskhadov to control Basayev.")),
         CH: R("Maskhadov Basayev'in baskınını kınadı ama kontrol edemiyor. Şura'daki radikaller 'Dağıstan'ı kurtarma' fikrinde; Maskhadov'un otoritesi zayıf. || Maskhadov condemned Basayev's raid but cannot control him. Radicals in the Shura talk of 'liberating Dagestan'; Maskhadov's authority is weak.",
                O("Baskını kınama, Maskhadov'la git (tarihî) || Condemn the raid and distance Grozny (historical)", "Rusya'ya savaş gerekçesi verme || Deny Moscow a pretext",
                  [["rel", CH, RU, 5], ["stab", CH, -3], ["rel", CH, TR, 3]], "Maskhadov Dağıstan baskınını 'Grozni'nin işi değil' diye açıkladı. || Maskhadov said the Dagestan raid was 'not Grozny's business'."),
                O("Şura'ya katıl, Dağıstan'ı destekle || Back Basayev and the Shura", "Savaşa hazırlan || Prepare for war",
                  [["unrest", P_DAG, 25], ["troops", CH, 25], ["rel", CH, RU, -25], ["stab", CH, 2]], "Çeçen gönüllüler Dağıstan'ın Botlih ve Novolak bölgelerine akıyor. || Chechen volunteers flow towards Dagestan's Botlikh and Novolak districts."))},
        [["unrest", P_DAG, 30], ["stab", RU, -3], ["buff", RU, "att", 1.1, 10], ["flag", "c99_dag"]],
        icon="border_clash", scene="border"))

    L.append(M("c99_eylul", 1999, 9, "Apartman Patlamaları || The Apartment Bombings",
        "4–16 Eylül 1999: Buynaksk, Moskova (iki kez) ve Volgodonsk'ta apartmanlara yönelik patlamalarda yaklaşık 300 kişi öldü. Putin 'tuvalette bile avlarız' dedi; sorumlular hâlâ tartışmalı, ama kamuoyu savaş istiyor. || 4–16 September 1999: bombings of apartment blocks in Buynaksk, Moscow (twice) and Volgodonsk killed about 300 people. Putin vowed to 'hunt them down even in the outhouse'; responsibility is still disputed, but the public wants war.",
        {RU: R("Ülke şokta, kamuoyu intikam istiyor. 'Terörle Mücadele Harekâtı' kararı Putin'in kaderini belirleyecek. || The country is in shock and public opinion demands revenge. The decision on a 'counter-terrorist operation' will define Putin.",
                O("Terörle Mücadele Harekâtı'nı başlat (tarihî) || Launch the counter-terrorist operation (historical)", "Çeçenistan'a hava ve kara harekâtı || Air and ground operation into Chechnya",
                  [["war", RU, CH, "solo"], ["troops", RU, 4], ["buff", RU, "att", 1.15, 12], ["stab", RU, 3], ["rel", RU, CH, -35], ["flag", "c99_war"]], "Rus uçakları Çeçenistan'ı bombalıyor; 30 Eylül'de zırhlı sütunlar Terek'i geçti. || Russian aircraft are bombing Chechnya; on 30 September armoured columns crossed the Terek."),
                O("Önce Rusya'da güvenlik, ortak soruşturma || Security at home and a joint inquiry first", "Çeçen hükümetinden işbirliği iste || Ask Grozny to cooperate",
                  [["rel", RU, CH, 5], ["stab", RU, -4], ["flag", "c99_probe"]], "Moskova Maskhadov'la ortak soruşturma önerdi; kamuoyu sabırsız. || Moscow offered Maskhadov a joint inquiry; the public is impatient.")),
         CH: R("Patlamalarla ilgisiniz yok ama Rus basını suçu Çeçenlere atıyor. Maskhadov Moskova'ya ortak soruşturma teklif etti; yine de büyük bir saldırının hazırlandığı belli. || You had nothing to do with the bombings but the Russian press blames the Chechens. Maskhadov offered a joint inquiry to Moscow; a major attack is clearly being prepared.",
                O("Savunmaya geç, seferberlik ilan et || Mobilise for defence", "Rus saldırısı kaçınılmaz || A Russian attack is unavoidable",
                  [["war", RU, CH, "solo"], ["troops", CH, 40], ["buff", CH, "def", 1.25, 14], ["buff", RU, "att", 0.3, 27], ["flag", "c99_war"]], "Maskhadov seferberlik ilan etti; 'gazavat' çağrısı yapıldı. || Maskhadov declared mobilisation; a call for 'ghazavat' was made."),
                O("Ortak soruşturma ve barış çağrısı || Call for a joint inquiry and peace", "Diplomasiyi dene || Try diplomacy",
                  [["rel", CH, RU, 8], ["stab", CH, -2], ["rel", CH, TR, 4]], "Maskhadov Putin'e görüşme önerdi; Moskova yanıt vermedi. || Maskhadov proposed a meeting to Putin; Moscow did not reply.")),
         TR: R("17 Ağustos depremi (17 bin ölü) Türkiye'yi yaraladı; ülke toparlanma çabasında. Çeçenistan'daki gelişmeler yeniden diaspora tepkisini canlandırıyor. || The 17 August earthquake (17,000 dead) wounded Turkey, which is struggling to recover. Developments in Chechnya revive reaction in the diaspora.",
                O("Rusya'yla ilişkileri koru || Keep relations with Russia", "Mavi Akım doğalgazı ve ticaret || Blue Stream gas and trade",
                  [["rel", TR, RU, 6], ["xstab", TR, -1]], "Ankara 'terörle mücadele'yi Rusya'nın hakkı olarak niteledi. || Ankara described counter-terrorism as Russia's right."),
                O("İnsani yardım ve çekimser tutum || Humanitarian aid and caution", "Mültecilere yardım || Aid for refugees",
                  [["rel", TR, RU, -3], ["rel", TR, CH, 10]], "Türkiye Çeçen mültecilere insani yardım gönderdi. || Turkey sent humanitarian aid to Chechen refugees."))},
        [["troops", RU, 3], ["rel", RU, CH, -35], ["stab", RU, 3], ["flag", "c99_war"]],
        icon="flame", scene="crisis"))

    L.append(M("c99_ekim", 1999, 10, "Terek'in Ötesi || Across the Terek",
        "30 Eylül'de Rus zırhlı sütunları Çeçenistan'ın kuzeyini (Nadterechnıy, Naur, Şelkovskaya) işgal etti. 21 Ekim'de Grozni'deki Merkez Pazarı füzelerle vuruldu (yüzlerce sivil ölü). 200 bini aşkın mülteci İnguşetya'ya aktı. || On 30 September Russian armoured columns occupied northern Chechnya (Nadterechny, Naursky, Shelkovskaya). On 21 October the Central Market in Grozny was hit by missiles, killing hundreds of civilians. More than 200,000 refugees poured into Ingushetia.",
        {RU: R("Birinci savaştan farklı: hava ve topçu önce, piyade sonra. Basın serbestçe gezemiyor, kayıp haberleri sınırlı. Putin'in reytingi yükseliyor. || Unlike the first war: air and artillery first, infantry afterwards. The press cannot roam freely and casualty news is limited. Putin's ratings are rising.",
                O("Kuzeyi güvenceye al, Grozni'yi kuşat (tarihî) || Secure the north and encircle Grozny (historical)", "Kademeli ilerleme, düşük zayiat || Gradual advance, low casualties",
                  [["buff", RU, "att", 1.1, 10], ["unrest", P_ING, 10], ["rel", RU, US, -3], ["stab", RU, 2]], "Rus birlikleri Terek'in kuzeyini ele geçirip Grozni'yi çevrelemeye başladı. || Russian troops took the north bank of the Terek and began encircling Grozny."),
                O("İnsani koridor aç, mültecilere yardım et || Open a humanitarian corridor", "Sivil kayıpları azalt || Reduce civilian harm",
                  [["rel", RU, US, 2], ["xstab", RU, -2]], "Moskova İnguşetya sınırında güvenli geçit ilan etti. || Moscow declared a safe passage on the Ingush border.")),
         CH: R("Ordunun kuzeyi kayıpsız aldı; Maskhadov güney dağlarında yeni bir savunma hattı kuruyor. Mülteciler kuzeyden güneye ya da İnguşetya'ya akıyor. || The army took the north without loss; Maskhadov is building a new defence line in the southern mountains. Refugees stream south or into Ingushetia.",
                O("Grozni'yi savunmaya hazırlan || Prepare to defend Grozny", "Şehir savunması || City defence",
                  [["buff", CH, "def", 1.25, 14], ["troops", CH, 20]], "Çeçen birlikleri Grozni'ye tahkimat yapıyor. || Chechen units are fortifying Grozny."),
                O("Dağlarda direnişe geç, şehri boşalt || Shift to the mountains, evacuate Grozny", "Gerilla savaşı || Guerrilla war",
                  [["unrest", P_CH, 15], ["troops", CH, 15], ["buff", CH, "def", 1.15, 20]], "Maskhadov güçlerini güneye ve dağlara kaydırıyor. || Maskhadov is shifting his forces to the south and the mountains.")),
         GE: R("Çeçen mültecilerin bir kısmı Pankisi Vadisi'ne geçiyor; Rusya Gürcistan'ı savaşçılara 'sığınak' olmakla suçluyor. || Some Chechen refugees are crossing into the Pankisi Gorge; Russia accuses Georgia of giving fighters a 'safe haven'.",
                O("Mültecileri kabul et, sınırı kontrol et || Take in refugees, control the border", "İnsani yaklaşım || A humanitarian approach",
                  [["rel", GE, RU, -4], ["rel", GE, US, 3]], "Gürcistan mültecilere sınır kapısını açtı. || Georgia opened its border to refugees."),
                O("Sınırı kapat || Close the border", "Rusya'ya güven ver || Reassure Russia",
                  [["rel", GE, RU, 4], ["xstab", GE, -2]], "Tiflis Çeçenistan sınırını kapattı. || Tbilisi closed the Chechen border."))},
        [["unrest", P_ING, 15], ["stab", CH, -4], ["rel", RU, US, -4], ["rel", RU, TR, -3]],
        icon="tank", scene="pre_assault"))

    L.append(M("c99_kasim", 1999, 11, "İstanbul Zirvesi || The Istanbul Summit",
        "18–19 Kasım 1999: AGİT İstanbul Zirvesi'nde Clinton ve Yeltsin Çeçenistan konusunda karşı karşıya geldi; Uyarlanmış AKKA antlaşması imzalandı, Bakü–Tiflis–Ceyhan boru hattı için hükümetlerarası anlaşma imzalandı. Rusya, Gürcistan'daki üslerini kapatma taahhüdü verdi. || 18–19 November 1999: at the OSCE Istanbul Summit Clinton and Yeltsin clashed over Chechnya; the Adapted CFE Treaty was signed, and an intergovernmental agreement for the Baku–Tbilisi–Ceyhan pipeline was signed. Russia pledged to close its bases in Georgia.",
        {TR: R("Ev sahibisiniz: Clinton, Yeltsin, Şröder, Chirac ve Kafkasya liderleri İstanbul'da. Boru hattı Türkiye'nin enerji koridoru hedefi; Çeçenistan ise sahneyi gölgeliyor. || You are the host: Clinton, Yeltsin, Schröder, Chirac and the Caucasian leaders are in Istanbul. The pipeline serves Turkey's energy-corridor goal while Chechnya casts a shadow over the stage.",
                O("Zirveyi başarıyla topla, nazik uyarı (tarihî) || Run the summit smoothly with a mild warning (historical)", "BTC anlaşmasını imzala || Sign the BTC deal",
                  [["rel", TR, US, 8], ["rel", TR, AZ, 8], ["rel", TR, GE, 8], ["rel", TR, RU, -2], ["xstab", TR, 3]], "Zirvede BTC boru hattı anlaşması imzalandı; Türkiye Kafkasya'da kilit oyuncu oldu. || The BTC pipeline deal was signed at the summit; Turkey became a key Caucasus player."),
                O("Çeçenistan'ı gündemin merkezine koy || Put Chechnya at the centre of the agenda", "Rusya'ya sert mesaj || A sharp message to Russia",
                  [["rel", TR, RU, -10], ["rel", TR, CH, 15], ["rel", TR, US, 4], ["xstab", TR, -1]], "Ankara zirvede Çeçenistan'daki sivil kayıplar için sert dil kullandı. || Ankara used strong language over civilian casualties in Chechnya."),
                O("Boru hattı ve ticaret öncelikli || Pipeline and trade first", "Rusya'yı kızdırma || Do not anger Russia",
                  [["rel", TR, RU, 6], ["rel", TR, AZ, 6], ["rel", TR, GE, 4]], "Ankara zirveyi enerji ve ticaret gündemine odakladı. || Ankara focused the summit on energy and trade.")),
         RU: R("Yeltsin'in son büyük sahnesi: Batı'nın eleştirisine 'iç mesele' diyecek ve Putin'in savaşını savunacak. Gürcistan'daki üsler konusunda taahhüt verirseniz Batı yumuşar. || Yeltsin's last big scene: he will call the criticism interference and defend Putin's war. A commitment on the Georgian bases would soften the West.",
                O("AKKA'yı imzala, Çeçenistan'ı 'iç mesele' say (tarihî) || Sign CFE; call Chechnya an internal matter (historical)", "Zirvede savaşı savun || Defend the war at the summit",
                  [["rel", RU, US, -3], ["rel", RU, TR, 3], ["stab", RU, 1]], "Yeltsin zirvede 'Rusya terörle mücadele ediyor' diyerek eleştirileri reddetti. || Yeltsin dismissed the criticism, saying 'Russia is fighting terrorism'."),
                O("Gürcistan üslerini kapat, Batı'yı yumuşat || Pledge to close Georgian bases to soften the West", "Taviz ver || Make a concession",
                  [["rel", RU, US, 4], ["rel", RU, GE, 6], ["xstab", RU, -1]], "Rusya Gürcistan'daki iki üssünü kapatma sözü verdi. || Russia promised to close two bases in Georgia.")),
         US: R("Clinton, Yeltsin'in 'Çeçenistan'da sivillere saldıran' sertliğini kamuoyu önünde eleştirmeyi düşünüyor; ama Rusya'nın nükleer arsenali ve reformlar hâlâ öncelikli. || Clinton considers publicly criticising Yeltsin's hard line against civilians in Chechnya, yet Russia's nuclear arsenal and reforms remain priorities.",
                O("Kamuoyu önünde eleştiri (tarihî) || Public criticism (historical)", "Çeçenistan'da çözümü siyasî olarak iste || Demand a political solution",
                  [["rel", US, RU, -6], ["rel", US, TR, 4]], "Clinton zirvede Çeçenistan'da siyasî çözüm çağrısı yaptı; Yeltsin öfkelendi. || Clinton called for a political solution in Chechnya; Yeltsin was furious."),
                O("Sessiz diplomasi, AKKA öncelikli || Quiet diplomacy, CFE first", "Rusya'yla kırma || Do not rupture ties",
                  [["rel", US, RU, 3]], "Washington zirvede silah kontrol anlaşmasına odaklandı. || Washington focused on the arms-control deal at the summit."))},
        [["rel", RU, US, -3], ["rel", TR, AZ, 6], ["rel", TR, GE, 6], ["rel", TR, US, 4], ["xstab", TR, 3], ["flag", "c99_istanbul"]],
        icon="treaty", scene="trade"))

    L.append(M("c99_aralik", 1999, 12, "Yeltsin İstifa Etti, Grozni Kuşatıldı || Yeltsin Resigns, Grozny Besieged",
        "6 Aralık: Rusya Grozni sakinlerine şehri 11 Aralık'a kadar boşaltma ültimatomu verdi; sonra topçu ve hava saldırıları başladı. 31 Aralık'ta Boris Yeltsin istifa etti, Putin vekâleten cumhurbaşkanı oldu. || 6 December: Russia gave Grozny's residents an ultimatum to leave by 11 December; artillery and air strikes followed. On 31 December Boris Yeltsin resigned and Putin became acting president.",
        {RU: R("Putin yılbaşı gecesi iktidarı devraldı; ordu Grozni'yi kuşatmış durumda. İlk savaşın hatasını tekrarlamamak için mahalle mahalle girmek yerine tamamen topçu ile ezmek planlanıyor. || Putin took power on New Year's Eve; the army has Grozny encircled. To avoid repeating the first war's mistake, the plan is to crush the city with artillery rather than enter block by block.",
                O("Grozni'ye topyekûn taarruz (tarihî) || All-out assault on Grozny (historical)", "Önce topçu, sonra piyade || Artillery first, infantry later",
                  [["buff", RU, "att", 1.2, 10], ["troops", RU, 2], ["unrest", P_CH, 25], ["rel", RU, US, -3], ["stab", RU, 3]], "Rus topçusu Grozni'yi haftalarca dövdü; şehir enkaza döndü. || Russian artillery pounded Grozny for weeks; the city turned to rubble."),
                O("Güvenli koridor ve pazarlık || Safe corridor and bargaining", "Kuşatmayı hafif tut || Keep the siege lighter",
                  [["xstab", RU, -2], ["rel", RU, US, 3], ["rel", RU, CH, 3]], "Moskova sivillerin çıkışı için güvenli koridor önerdi. || Moscow offered a safe corridor for civilians.")),
         CH: R("Grozni bir ölüm tuzağına dönüşebilir: kuşatılmış şehirde hem silahlı kuvvetler hem de yüz binlerce sivil var. Maskhadov güçlerini kurtarmak için çıkış yolları arıyor. || Grozny may turn into a death trap: besieged, with both armed forces and hundreds of thousands of civilians. Maskhadov looks for exits to save his forces.",
                O("Grozni'yi tutmaya çalış || Try to hold Grozny", "Şehir savunması || City defence",
                  [["buff", CH, "def", 1.3, 10], ["troops", CH, 20], ["stab", CH, -2]], "Basayev ve Gelayev şehirde direnişi örgütledi. || Basayev and Gelayev organised the resistance inside the city."),
                O("Şehri boşalt, güneyde direniş kur || Break out and resist in the south", "Kayıpları azalt || Save the force",
                  [["troops", CH, 10], ["buff", CH, "def", 1.15, 18], ["stab", CH, 2]], "Maskhadov güçlerini şehirden çıkarmayı planlıyor. || Maskhadov plans to withdraw his forces from the city."))},
        [["stab", RU, 4], ["buff", RU, "att", 1.15, 10], ["unrest", P_CH, 25], ["flag", "c99_yeltsin_resigned"]],
        icon="flame", scene="pre_siege"))

    L.append(M("c99_subat", 2000, 2, "Grozni Düştü || Grozny Falls",
        "Ocak sonunda Çeçen kuvvetleri Grozni'den Alhan-Kala yönünde yarma yaptı, ama mayın tarlasında ağır kayıp verdi (Gelayev ve Basayev yaralı, Basayev bir ayağını kaybetti). 6 Şubat'ta Rusya Grozni'nin ele geçirildiğini ilan etti. || At the end of January Chechen forces broke out of Grozny towards Alkhan-Kala but suffered heavy losses in a minefield (Basayev lost a foot). On 6 February Russia declared Grozny captured.",
        {RU: R("Grozni sizin, ama şehrin yarısı enkaz. Direniş dağlarda ve köylerde sürecek; mayınlar ve pusular zayiat verecek. || Grozny is yours but half the city is rubble. The resistance will go on in the mountains and villages; mines and ambushes will cost casualties.",
                O("Dağ harekâtı: Argun Vadisi, Vedeno || Mountain operation: Argun Valley, Vedeno", "Gerilla üslerini yok et || Destroy the guerrilla bases",
                  [["buff", RU, "att", 1.1, 12], ["troops", RU, 2]], "Rus birlikleri güney dağlarına ilerliyor. || Russian forces advance into the southern mountains."),
                O("Siyasî çözüm: yerel yönetim kur || A political solution: set up local authority", "Çeçen yanlısı yönetim || A pro-Moscow Chechen administration",
                  [["unrest", P_CH, -10], ["stab", RU, 2]], "Kremlin Çeçen eşrafıyla yeni bir yönetim kurmak için temas kurdu. || The Kremlin approached Chechen elders to set up a new administration.")),
         CH: R("Şehir kaybedildi; ordunun parçalanması, silahlı çetelerin ve radikal şeflerin etkisini artırır. Maskhadov dağlarda birliği korumaya çalışıyor. || The city is lost; the army's fragmentation increases the sway of warlords and radicals. Maskhadov tries to keep unity in the mountains.",
                O("Gerilla savaşına geç || Switch to guerrilla war", "Pusu, mayın, intihar saldırısı || Ambush, mines, suicide attacks",
                  [["unrest", P_CH, 30], ["buff", CH, "def", 1.2, 25], ["troops", CH, 20], ["flag", "c99_guerrilla"]], "Çeçen müfrezeleri dağlara çekilip köylere dağıldı. || Chechen detachments withdrew into the mountains and dispersed into villages."),
                O("Moskova'ya ateşkes teklif et || Offer a ceasefire to Moscow", "Yeniden müzakere || Seek talks",
                  [["rel", CH, RU, 5], ["stab", CH, -3]], "Maskhadov Putin'e koşulsuz ateşkes önerdi; Kremlin reddetti. || Maskhadov offered Putin an unconditional ceasefire; the Kremlin refused."))},
        [["occupy", RU, P_CH], ["unrest", P_CH, 40], ["stab", CH, -10], ["troops", CH, -20], ["flag", "c99_grozny_fell"]],
        icon="flag", scene="pre_siege"))

    L.append(M("c99_mart", 2000, 3, "Putin Seçildi || Putin Elected",
        "26 Mart 2000: Putin ilk turda %53 oyla cumhurbaşkanı seçildi. Mart başında Komsomolskoye'de Çeçen birlikleri kuşatılıp yok edildi; 1 Mart'ta Ulus-Kert'te Pskov paraşütçüleri ağır zayiat verdi. || 26 March 2000: Putin was elected president in the first round with 53%. In early March Chechen units were encircled and destroyed at Komsomolskoye; on 1 March Pskov paratroopers took heavy losses at Ulus-Kert.",
        {RU: R("Zaferle seçildiniz; Çeçenistan dosyası artık 'terörle mücadele' olarak çerçeveleniyor. Oligarkları ve valileri kontrol altına alma zamanı. || You won decisively; the Chechnya file is now framed as 'fighting terrorism'. It is time to tame oligarchs and governors.",
                O("Dikeyi güçlendir: federal bölgeler (tarihî) || Strengthen the vertical: federal districts", "Merkezî kontrol || Centralise control",
                  [["stab", RU, 4], ["xstab", RU, 3]], "Putin yedi federal bölge kurarak valileri denetim altına aldı. || Putin set up seven federal districts to rein in the governors."),
                O("Çeçen yanlısı bir lider ara || Seek a pro-Moscow Chechen leader", "Çeçenleştirme || Chechenisation",
                  [["stab", RU, 2], ["unrest", P_CH, -5]], "Kremlin Çeçenistan'da yeni bir yönetici adayı arıyor. || The Kremlin is looking for a new administrator in Chechnya."))},
        [["stab", RU, 4], ["xstab", RU, 3], ["unrest", P_CH, -5]],
        icon="flag", scene="pre_court", major=False))

    L.append(M("c99_haziran", 2000, 6, "Doğrudan Yönetim ve Kadirov || Direct Rule and Kadyrov",
        "12 Haziran 2000: Putin eski Çeçen müftüsü Ahmed Kadirov'u Çeçenistan 'yönetim başkanı' atadı. Müftü Maskhadov'un 'cihat' çağrısına karşı çıkmış ve Rusya'nın yanına geçmişti; 'Çeçenleştirme' politikası başladı. || 12 June 2000: Putin appointed Akhmad Kadyrov, the former Chechen mufti, as Chechnya's 'head of administration'. He had opposed Maskhadov's call for jihad and switched to Moscow; the policy of 'Chechenisation' began.",
        {RU: R("Çeçen yanlısı yönetim size iç kamuoyunda 'normalleşme' sağlıyor; ama Kadirov'un özerkliği ileride başka sorunlar doğurabilir. || A pro-Moscow Chechen administration gives you 'normalisation' at home, yet Kadyrov's autonomy may cause trouble later.",
                O("Çeçenleştirme: Kadirov'a yetki ver (tarihî) || Chechenisation: empower Kadyrov (historical)", "Yerel milisler, af ve kimlik değişimi || Local militias, amnesty and defections",
                  [["unrest", P_CH, -20], ["stab", RU, 2], ["rel", RU, CH, -5]], "Kadirov'un milisleri Rus birlikleriyle birlikte operasyon yapmaya başladı. || Kadyrov's militias began operating alongside Russian forces."),
                O("Doğrudan askerî yönetimi sürdür || Keep direct military rule", "Yeterince asker, yerel aracı yok || Plenty of troops, no local broker",
                  [["unrest", P_CH, 10], ["troops", RU, 2], ["stab", RU, -1]], "Genelkurmay yerel aracıları reddetti; operasyonlar sürüyor. || The General Staff rejected local brokers; operations go on.")),
         CH: R("Çeçen toplumunda bölünme: eski müftü Moskova'nın yanına geçti, yerel ailelerin bir kısmı Kadirov'a katılıyor. Direniş, içeriden gelen bir rakiple karşı karşıya. || Division in Chechen society: the former mufti has switched to Moscow and some local clans are joining Kadyrov. The resistance faces a rival from within.",
                O("Kadirov'u 'hain' ilan et, suikast örgütle || Brand Kadyrov a traitor and organise assassinations", "İç savaşı alevlendir || Fuel an internal war",
                  [["stab", CH, -3], ["unrest", P_CH, 15], ["buff", CH, "att", 1.1, 10]], "Maskhadov ve Basayev Kadirov'a karşı ölüm fetvası çıkardı. || Maskhadov and Basayev issued a death sentence against Kadyrov."),
                O("Halkı sahiplen, eşrafla uzlaş || Win over the elders and clans", "Meşruiyeti koru || Protect legitimacy",
                  [["stab", CH, 4], ["troops", CH, 10]], "Maskhadov eşraf ve köy büyüklerini bir araya getiren meclisler topladı. || Maskhadov convened gatherings of elders and village leaders."))},
        [["unrest", P_CH, -15], ["stab", CH, -3], ["stab", RU, 2]],
        icon="treaty", scene="pre_court", major=False))

    L.append(M("c99_eylul01", 2001, 9, "11 Eylül ve Terörle Savaş || 9/11 and the War on Terror",
        "11 Eylül 2001'den sonra Putin Bush'u arayan ilk lider oldu; Batı'nın Çeçenistan eleştirisi yumuşadı. 2001–02'de Rusya, Gürcistan'ın Pankisi Vadisi'ndeki Çeçen ve Arap savaşçıları bahane ederek tepki gösterdi; ABD Gürcistan'a 'Train and Equip' programı başlattı. || After 9/11 Putin was the first leader to call Bush; Western criticism of Chechnya softened. In 2001–02 Russia reacted to Chechen and Arab fighters in Georgia's Pankisi Gorge; the US launched a 'Train and Equip' programme in Georgia.",
        {RU: R("Batı'nın dikkati Afganistan'a kaydı; Çeçenistan artık 'Rusya'nın uluslararası terörizmle savaşı'nın parçası. Orta Asya'da ABD üslerine razı olmak karşılığında Batı'dan ne alabilirsiniz? || The West's attention has turned to Afghanistan; Chechnya is now part of 'Russia's fight against international terrorism'. What can you get from the West in exchange for accepting US bases in Central Asia?",
                O("ABD'yle ortaklık (tarihî) || Partnership with the US (historical)", "Terörle savaşta işbirliği || Cooperate in the war on terror",
                  [["rel", RU, US, 15], ["stab", RU, 2], ["rel", RU, TR, 3]], "Putin Bush'a istihbarat ve hava sahası desteği sundu. || Putin offered Bush intelligence and airspace support."),
                O("Mesafeli kal, bağımsız çizgi || Stay aloof, independent line", "Batı'ya güvenme || Do not rely on the West",
                  [["rel", RU, US, -3], ["xstab", RU, -1]], "Moskova ABD'nin Orta Asya'ya yerleşmesine itiraz etti. || Moscow objected to America settling in Central Asia.")),
         CH: R("Dünya sizi artık 'el-Kaide bağlantılı' görüyor; Hattab'ın ve Arap gönüllülerin varlığı bu algıyı güçlendiriyor. Batı desteği hızla eriyor. || The world now sees you as 'al-Qaeda linked'; the presence of Khattab and Arab volunteers reinforces that view. Western sympathy is melting fast.",
                O("Terörizmi kınadığını ilan et || Condemn terrorism publicly", "İmajı kurtar || Salvage the image",
                  [["rel", CH, US, 4], ["rel", CH, TR, 3], ["stab", CH, -2]], "Maskhadov 11 Eylül'ü kınayıp 'Çeçenistan terör örgütü değil' dedi. || Maskhadov condemned 9/11 and said Chechnya is not a terrorist organisation."),
                O("Yabancı gönüllülere bağlı kal || Stay with the foreign fighters", "Cihat söylemini sürdür || Keep the jihadist line",
                  [["troops", CH, 10], ["rel", CH, US, -8], ["rel", CH, TR, -3]], "Radikal komutanlar cihat söylemini sertleştirdi. || Radical commanders hardened their jihadist rhetoric.")),
         GE: R("Pankisi Vadisi'nde Çeçen mülteciler ve silahlı gruplar var; Rusya 'terörist sığınağı' diye baskı yapıyor. Shevardnadze ABD'ye yaklaşmak için fırsat görüyor. || There are Chechen refugees and armed groups in the Pankisi Gorge; Russia pushes the 'terrorist haven' line. Shevardnadze sees a chance to move closer to the US.",
                O("ABD 'Train and Equip' programını kabul et (tarihî) || Accept the US 'Train and Equip' programme (historical)", "ABD'ye yaklaş || Move toward the US",
                  [["rel", GE, US, 15], ["rel", GE, RU, -8], ["troops", GE, 10]], "ABD Özel Kuvvetleri Gürcü askerlerini eğitmeye başladı. || US Special Forces began training Georgian soldiers."),
                O("Rusya'yla ortak operasyon || A joint operation with Russia", "Pankisi'yi birlikte temizle || Clear Pankisi together",
                  [["rel", GE, RU, 6], ["rel", GE, US, -2]], "Tiflis Moskova'yla Pankisi'de ortak güvenlik operasyonu önerdi. || Tbilisi proposed a joint security operation in Pankisi.")),
         US: R("Bush ve Putin ortaklık kuruyor; Rusya Afganistan'da kritik. Kongre'de ve basında Çeçenistan'daki insan hakları ihlalleri sorgulanıyor. || Bush and Putin are building a partnership; Russia is key in Afghanistan. Human rights abuses in Chechnya are questioned in Congress and the press.",
                O("Putin'le ortaklık (tarihî) || Partnership with Putin (historical)", "Çeçenistan eleştirisini yumuşat || Soften the line on Chechnya",
                  [["rel", US, RU, 15], ["rel", US, GE, 6]], "Bush Putin'i Teksas'taki çiftliğine davet etti. || Bush invited Putin to his Texas ranch."),
                O("Çeçenistan'ı şart koş || Make Chechnya a condition", "İnsan hakları baskısı || Human rights pressure",
                  [["rel", US, RU, -5]], "Kongre'de Rusya yardımına Çeçenistan şartı önerildi. || A Chechnya condition on Russia aid was proposed in Congress."))},
        [["rel", RU, US, 15], ["rel", RU, TR, 3], ["rel", GE, US, 8], ["stab", CH, -3], ["flag", "c99_911"]],
        icon="warning", scene="crisis"))

    L.append(M("c99_ekim02", 2002, 10, "Dubrovka Tiyatro Krizi || The Moscow Theatre Siege",
        "23–26 Ekim 2002: Movsar Barayev komutasında 40 kadar Çeçen Moskova'daki Dubrovka tiyatrosunu bastı, 850 rehine aldı. Rus özel kuvvetleri üçüncü gün uyutucu gaz kullanarak baskın yaptı; yaklaşık 130 rehine öldü. || 23–26 October 2002: about 40 Chechens under Movsar Barayev seized the Dubrovka theatre in Moscow, taking 850 hostages. On the third day Russian special forces stormed it after pumping in an incapacitating gas; about 130 hostages died.",
        {RU: R("Moskova'nın kalbinde rehine krizi; kamuoyu hem çaresiz hem öfkeli. Baskın riskli, müzakere ise 'taviz' demek. || A hostage crisis in the heart of Moscow; the public is both helpless and furious. A raid is risky; negotiation means 'concession'.",
                O("Gaz ve baskın (tarihî) || Gas and storm (historical)", "Askerî çözüm, yüksek risk || Military solution, high risk",
                  [["stab", RU, -2], ["buff", RU, "att", 1.1, 8], ["unrest", P_CH, 10], ["rel", RU, US, -2]], "Rus özel kuvvetleri gaz verip tiyatroya girdi; rehinelerin çoğu kurtuldu ama yüzlercesi hastanelik oldu. || Russian special forces pumped in gas and stormed the theatre; most hostages survived but hundreds were hospitalised."),
                O("Müzakere: Kosachev, Politkovskaya, Aushev || Negotiate through intermediaries", "Hayatları kurtarmaya çalış || Try to save lives",
                  [["xstab", RU, -3], ["rel", RU, CH, 3]], "Moskova arabuluculara izin verdi; ama krizde zaman daralıyor. || Moscow allowed intermediaries, but time is running out.")),
         CH: R("Maskhadov rehine almayı onaylamadığını açıkladı ama saldırıyı Basayev üstlendi. Bu eylem Çeçen davasının uluslararası imajını ağır yaralayabilir. || Maskhadov said he did not approve of hostage-taking, yet Basayev claimed the attack. It may badly damage the international image of the Chechen cause.",
                O("Saldırıyı kınama, rehineleri koruma çağrısı yap || Condemn the raid and urge protection of hostages", "Maskhadov'un 'olumsuz' tutumu || Maskhadov's disavowal",
                  [["rel", CH, US, 3], ["rel", CH, TR, 3], ["stab", CH, -2]], "Maskhadov rehinelerin serbest bırakılması çağrısı yaptı. || Maskhadov called for the hostages' release."),
                O("Basayev'in tarafını tut || Side with Basayev", "Sertlik yanlısı çizgi || The hardline path",
                  [["buff", CH, "att", 1.1, 8], ["rel", CH, US, -6], ["rel", CH, TR, -4]], "Basayev eylemi 'Rusya'ya bir mesaj' olarak sundu. || Basayev presented the action as 'a message to Russia'."))},
        [["stab", RU, -3], ["unrest", P_CH, 10], ["rel", RU, CH, -10]],
        icon="warning", scene="crisis"))

    L.append(M("c99_mart03", 2003, 3, "Çeçen Anayasa Referandumu || The Chechen Constitutional Referendum",
        "23 Mart 2003: Çeçenistan'ın Rusya'nın bir parçası olduğunu öngören anayasa referandumu %96 'evet' ile geçti; savaş yorgunu halk ve ağır askerî varlık altında yapılan oy tartışmalı. 5 Ekim'de Ahmed Kadirov %80 ile 'cumhurbaşkanı' seçildi. || 23 March 2003: a referendum on a constitution declaring Chechnya a part of Russia passed with 96% 'yes'; the vote, held under heavy military presence in a war-weary population, is disputed. On 5 October Akhmad Kadyrov was elected 'president' with 80%.",
        {RU: R("Referandum Çeçenistan'ı 'hukuken' Rusya'ya bağlıyor; Batı tartışmalı oylamayı eleştirse de Putin'in bölgedeki konumu pekişiyor. || The referendum legally ties Chechnya to Russia; though the West criticises the contested vote, Putin's position is strengthened.",
                O("Seçimleri sürdür, Kadirov'u destekle (tarihî) || Press on with Kadyrov (historical)", "Çeçen yönetimi güçlendir || Strengthen Chechen rule",
                  [["unrest", P_CH, -15], ["stab", RU, 2]], "Kremlin referandumu 'normalleşmenin kanıtı' diye sundu. || The Kremlin presented the referendum as 'proof of normalisation'."),
                O("Af ve yeniden yapılanma || Amnesty and reconstruction", "Yeniden inşa fonları || Reconstruction funds",
                  [["unrest", P_CH, -10], ["gold", RU, -0.5], ["stab", RU, 1]], "Moskova Grozni'nin yeniden inşası için yeni fonlar açıkladı. || Moscow announced new funds for rebuilding Grozny.")),
         CH: R("Referandum Rus ordusunun gölgesinde yapıldı; direnişin siyasî kanadı marjinal kalıyor. Maskhadov yeraltından halka seslenmeye çalışıyor. || The referendum was held in the army's shadow; the resistance's political wing is marginalised. Maskhadov tries to address the people from hiding.",
                O("Referandumu 'sahte' ilan et || Declare the vote a sham", "Meşruiyeti sorgulat || Contest legitimacy",
                  [["stab", CH, -1], ["rel", CH, TR, 3]], "Maskhadov referandumu 'işgal altında yapılan bir tiyatro' diye niteledi. || Maskhadov called the referendum 'theatre under occupation'."),
                O("Gerilla operasyonlarını sürdür || Keep up guerrilla operations", "Askerî baskı || Military pressure",
                  [["unrest", P_CH, 10], ["buff", CH, "def", 1.1, 14]], "Çeçen müfrezeleri Rus konvoylarına pusu kurmayı sürdürüyor. || Chechen detachments keep ambushing Russian convoys."))},
        [["unrest", P_CH, -10], ["stab", RU, 2], ["stab", CH, -2]],
        icon="treaty", scene="pre_court", major=False))

    L.append(M("c99_mayis04", 2004, 5, "Kadirov'a Suikast || Kadyrov Assassinated",
        "9 Mayıs 2004: Grozni'de Zafer Günü töreninde stadyumda patlama; Ahmed Kadirov öldü. Haziranda Basayev'in müfrezeleri İnguşetya'nın Nazran kentini bastı (21–22 Haziran), Ağustos'ta Alu Alhanov Çeçenistan başkanı seçildi. || 9 May 2004: a bomb at the Victory Day ceremony in Grozny's stadium killed Akhmad Kadyrov. In June Basayev's units raided Nazran, Ingushetia (21–22 June); in August Alu Alkhanov was elected president of Chechnya.",
        {RU: R("Çeçenleştirme politikasının mimarı öldü; Ramzan Kadirov güç boşluğunu doldurmaya hazır. Direniş İnguşetya'ya taşıyor. || The architect of Chechenisation is dead; Ramzan Kadyrov is ready to fill the vacuum. The insurgency is spreading to Ingushetia.",
                O("Alhanov'u destekle, Ramzan'ı kontrol altına al (tarihî) || Back Alkhanov while restraining Ramzan (historical)", "Siyasî denge || Political balance",
                  [["stab", RU, 1], ["unrest", P_CH, -8]], "Kremlin Alu Alhanov'u 'Çeçen cumhurbaşkanı' olarak destekledi. || The Kremlin backed Alu Alkhanov as 'Chechen president'."),
                O("Ramzan Kadirov'a yetki ver || Empower Ramzan Kadyrov", "Güvenlik güçlerini ona bırak || Hand him the security forces",
                  [["unrest", P_CH, -15], ["unrest", P_ING, 10], ["stab", RU, 1]], "Ramzan'ın 'Kadirovtsi' milisleri güvenlikte öne çıktı. || Ramzan's 'Kadyrovtsy' militias took the lead in security.")),
         CH: R("Suikast direnişin başarısı, ama Rusya'nın misillemesi sertleşecek. Basayev'in hedefi yeni cepheler açmak: İnguşetya, Kabardin-Balkar. || The assassination is a success for the resistance, but Russian retaliation will harden. Basayev aims to open new fronts: Ingushetia and Kabardino-Balkaria.",
                O("İnguşetya'da yeni cephe aç (tarihî) || Open a new front in Ingushetia (historical)", "Nazran baskını || The Nazran raid",
                  [["unrest", P_ING, 30], ["buff", CH, "att", 1.15, 8], ["stab", CH, 2]], "Basayev'in adamları Nazran'da polis ve güvenlik noktalarını bastı. || Basayev's men stormed police and security posts in Nazran."),
                O("Çeçenistan içinde savunmada kal || Stay in defence within Chechnya", "Gücü koru || Preserve strength",
                  [["troops", CH, 10], ["buff", CH, "def", 1.1, 10]], "Maskhadov'un adamları güney dağlarında mevzilerini korudu. || Maskhadov's men held their positions in the southern mountains."))},
        [["stab", CH, -3], ["unrest", P_CH, 15], ["unrest", P_ING, 30], ["stab", RU, -2]],
        icon="missile", scene="crisis", major=False))

    L.append(M("c99_eylul04", 2004, 9, "Beslan || Beslan",
        "1–3 Eylül 2004: Kuzey Osetya'nın Beslan kentinde 1 No'lu okulu bastıkları bir grup (Basayev adına) 1.100 rehine aldı. Üçüncü gün patlamalar ve çatışmayla 334 kişi öldü; yarısına yakını çocuktu. || 1–3 September 2004: a group acting in Basayev's name seized School No. 1 in Beslan, North Ossetia, taking 1,100 hostages. On the third day explosions and gunfire killed 334 people, nearly half of them children.",
        {RU: R("Savaşın en korkunç anı: kamuoyu sarsıldı, Batı sempati gösterdi. Putin'in tepkisi: merkezileşme. || The war's most terrible moment: public shock and Western sympathy. Putin's response: centralisation.",
                O("Valilerin atanması, güvenlik yasası (tarihî) || Appoint governors, tighten security (historical)", "Merkezî kontrol || Centralise control",
                  [["stab", RU, -2], ["xstab", RU, 2], ["unrest", P_ING, -5], ["rel", RU, US, -3]], "Putin valilerin doğrudan seçimini kaldırdı; 'terörle mücadele' yasaları sertleşti. || Putin abolished direct election of governors and hardened counter-terror laws."),
                O("Siyasî çözüm: Maskhadov'la temas || A political track: contact Maskhadov", "Müzakere kapısı || Open the door to talks",
                  [["stab", RU, -4], ["rel", RU, CH, 5], ["xstab", RU, -2]], "Kremlin'in bir kanadı Maskhadov'la gizli temas önerdi; Putin reddetti. || One Kremlin faction proposed secret contact with Maskhadov; Putin refused.")),
         CH: R("Basayev sorumluluk üstlendi; Maskhadov saldırıyı kınadı ama bu artık direnişin imajını kurtaramıyor. Batı ve İslam dünyasında Çeçen davasına destek hızla azalıyor. || Basayev claimed responsibility; Maskhadov condemned the attack, but that can no longer save the resistance's image. Support for the Chechen cause in the West and the Muslim world is falling fast.",
                O("Saldırıyı kınama, Basayev'den ayrıl || Condemn it and distance from Basayev", "Siyasî çizgiyi koru || Preserve the political line",
                  [["rel", CH, TR, 3], ["rel", CH, US, 3], ["stab", CH, -4]], "Maskhadov Beslan'ı kınayıp 'sivil hedeflere karşıyız' dedi. || Maskhadov condemned Beslan, saying he opposes attacks on civilians."),
                O("Basayev'in çizgisine kay || Follow Basayev's line", "Cihatçı çizgi || A jihadist line",
                  [["buff", CH, "att", 1.1, 8], ["rel", CH, TR, -6], ["rel", CH, US, -8]], "Radikal komutanlar saldırıyı 'savaşın doğal sonucu' saydı. || Radical commanders called the attack 'a natural result of the war'."))},
        [["stab", RU, -3], ["xstab", RU, 2], ["rel", RU, US, -3], ["stab", CH, -4]],
        icon="warning", scene="crisis"))

    L.append(M("c99_mart05", 2005, 3, "Maskhadov Öldürüldü || Maskhadov Killed",
        "8 Mart 2005: Çeçen direnişinin seçilmiş lideri Aslan Maskhadov, Tolstoy-Yurt köyünde bir sığınakta Rus özel kuvvetlerince öldürüldü. Yerine Abdulhalim Saydullayev geçti. || 8 March 2005: Aslan Maskhadov, the resistance's elected leader, was killed by Russian special forces in a bunker in Tolstoy-Yurt. Abdul-Halim Sadulayev succeeded him.",
        {RU: R("Putin 'direnişin başı' diye kutladı; Maskhadov'la müzakere kapısı tamamen kapandı. Direniş giderek Basayev ve İslamcılara kayıyor. || Putin hailed 'the head of the resistance'; the door to talks with Maskhadov is shut for good. The insurgency is drifting toward Basayev and the Islamists.",
                O("Tutumu sürdür, af ve milisler (tarihî) || Press on with amnesty and militias (historical)", "Direnişi içeriden böl || Divide the resistance from within",
                  [["unrest", P_CH, -10], ["stab", RU, 1]], "Moskova yeni af ilan etti; Kadirovtsi'ler operasyonları yönetiyor. || Moscow declared a new amnesty; the Kadyrovtsy run operations."),
                O("Sertliği artır || Intensify operations", "Daha fazla temizlik operasyonu || More sweeps",
                  [["buff", RU, "att", 1.1, 8], ["unrest", P_CH, 5], ["rel", RU, US, -2]], "Rus iç birlikleri dağlarda yeni operasyonlar başlattı. || Russian interior troops began new mountain operations.")),
         CH: R("Maskhadov'un ölümü direnişin ılımlı kanadını yok etti. Saydullayev genç bir din adamı, ama sahada komuta Basayev'de. || Maskhadov's death destroyed the moderate wing. Sadulayev is a young cleric but Basayev commands in the field.",
                O("Saydullayev'le sürdür, birliği koru || Rally behind Sadulayev", "Komuta birliği || Unity of command",
                  [["stab", CH, 4], ["buff", CH, "def", 1.05, 12]], "Komutanlar Saydullayev'e bağlılık yemini etti. || Commanders swore allegiance to Sadulayev."),
                O("Basayev'e askerî yetki ver || Hand Basayev military control", "Sert çizgi || The hard line",
                  [["troops", CH, 10], ["buff", CH, "att", 1.1, 10], ["stab", CH, -2], ["rel", CH, TR, -4]], "Basayev bütün askerî harekâtı yönetmeye başladı. || Basayev began directing all military operations."))},
        [["stab", CH, -10], ["unrest", P_CH, 5], ["stab", RU, 1], ["flag", "c99_maskhadov_dead"]],
        icon="missile", scene="crisis", major=False))

    L.append(M("c99_temmuz06", 2006, 7, "Saydullayev ve Basayev'in Sonu || The End of Sadulayev and Basayev",
        "17 Haziran 2006: Saydullayev Argun'da öldürüldü; yerine Doku Umarov geçti. 10 Temmuz'da Basayev İnguşetya'nın Ekajevo köyünde bir patlamada öldü; Rus yetkililer operasyonu üstlendi. İki karizmatik lider kısa sürede ortadan kalktı. || 17 June 2006: Sadulayev was killed in Argun; Doku Umarov succeeded him. On 10 July Basayev died in an explosion in the Ingush village of Ekazhevo; Russian officials claimed the operation. Two charismatic leaders disappeared within weeks.",
        {RU: R("Savaşın iki kilit ismi ortadan kalktı. Kremlin 'savaş bitti' diyecek; ama genç militanlar ve Kafkasya genelinde bir ağ yeniden yapılanıyor. || Two key figures of the war are gone. The Kremlin will say 'the war is over'; but young militants and a network across the Caucasus are rebuilding.",
                O("Zafer ilan et, Çeçenleştirmeyi tamamla (tarihî) || Declare victory and complete Chechenisation (historical)", "Askerî varlığı azalt || Draw down the force",
                  [["unrest", P_CH, -15], ["stab", RU, 3]], "Moskova Çeçenistan'da askerî varlığı azaltıp güvenliği Ramzan Kadirov'a bıraktı. || Moscow reduced its military presence and left security to Ramzan Kadyrov."),
                O("Kafkasya genelinde istihbarat operasyonları || Intelligence operations across the Caucasus", "Ağı tamamen sök || Dismantle the network",
                  [["unrest", P_CH, -8], ["unrest", P_DAG, -5], ["unrest", P_ING, -5]], "Rus servisleri Kuzey Kafkasya'da yeni operasyonlar başlattı. || Russian services began new operations across the North Caucasus.")),
         CH: R("Direniş lidersiz kaldı. Doku Umarov, Kafkasya'nın tümüne yayılan bir İslamî cephe kurmaya çalışıyor; Çeçen milliyetçiliği ikinci plana düşüyor. || The resistance is leaderless. Doku Umarov tries to build an Islamic front across the whole Caucasus; Chechen nationalism recedes.",
                O("Umarov'u destekle, Kafkas cephesi kur || Back Umarov and build a Caucasus front", "Bölgesel ağ || A regional network",
                  [["unrest", P_DAG, 10], ["unrest", P_ING, 10], ["troops", CH, 10], ["stab", CH, 2]], "Umarov Dağıstan, İnguşetya ve Kabardin-Balkar hücrelerini birleştirmeye girişti. || Umarov began joining cells in Dagestan, Ingushetia and Kabardino-Balkaria."),
                O("Siyasî bir çıkış ara || Seek a political exit", "Görüşme ve af || Talks and amnesty",
                  [["rel", CH, RU, 8], ["stab", CH, 3]], "Bazı komutanlar Moskova'nın af tekliflerine kapıyı açtı. || Some commanders opened the door to Moscow's amnesty offers."))},
        [["stab", CH, -8], ["unrest", P_CH, -10], ["stab", RU, 2]],
        icon="missile", scene="crisis", major=False))

    L.append(M("c99_ekim07", 2007, 10, "Kafkas Emirliği || The Caucasus Emirate",
        "15 Şubat 2007: Ramzan Kadirov Çeçenistan cumhurbaşkanı oldu. 31 Ekim'de Doku Umarov 'Kafkas Emirliği'ni ilan etti: Çeçen bağımsızlık davası terk edilip bütün Kuzey Kafkasya'yı kapsayan İslamî bir cihat çerçevesine oturtuldu. || 15 February 2007: Ramzan Kadyrov became president of Chechnya. On 31 October Doku Umarov proclaimed the 'Caucasus Emirate': the Chechen independence cause was dropped in favour of an Islamic jihad covering the whole North Caucasus.",
        {RU: R("Çeçenistan Ramzan'ın kontrolünde 'sakin'; ama şiddet Dağıstan ve İnguşetya'ya kayıyor. Bu, Kremlin'in 'çözülmüş' savaşının yeni, daha dağınık sürümü. || Chechnya is 'calm' under Ramzan, but the violence is moving to Dagestan and Ingushetia. This is a new, more diffuse version of the war the Kremlin claims is solved.",
                O("Ramzan'ı destekle, Dağıstan'da operasyon (tarihî) || Back Ramzan, operate in Dagestan (historical)", "Çeçen modelini komşulara uygula || Apply the Chechen model next door",
                  [["unrest", P_CH, -15], ["unrest", P_DAG, -5], ["stab", RU, 1]], "Moskova Ramzan Kadirov'a Çeçenistan'da geniş yetki verdi. || Moscow gave Ramzan Kadyrov wide powers in Chechnya."),
                O("Ekonomik kalkınma programı || An economic development programme", "Kuzey Kafkasya'ya yatırım || Invest in the North Caucasus",
                  [["gold", RU, -0.5], ["unrest", P_DAG, -8], ["unrest", P_ING, -8]], "Kremlin Kuzey Kafkasya için yeni bir kalkınma fonu açıkladı. || The Kremlin announced a new development fund for the North Caucasus.")),
         CH: R("Umarov bir 'emirlik' ilan etti: Çeçen bağımsızlık fikri bir sonraki aşamaya dönüşüyor. Ama Çeçen toplumu savaştan yorgun ve Kadirov'un baskısı altında. || Umarov proclaimed an 'emirate': the Chechen independence idea has morphed into something else. Yet Chechen society is war-weary and under Kadyrov's pressure.",
                O("Kafkas Emirliği'ne katıl || Join the Caucasus Emirate", "Cihat çerçevesi || A jihadist framework",
                  [["unrest", P_DAG, 15], ["unrest", P_ING, 15], ["troops", CH, 10], ["stab", CH, -2]], "Umarov'un çağrısıyla Dağıstan ve İnguşetya'da yeni hücreler kuruldu. || New cells were set up in Dagestan and Ingushetia at Umarov's call."),
                O("Milliyetçi çizgiyi koru || Keep the nationalist line", "Çeçen bağımsızlığı || Chechen independence",
                  [["rel", CH, TR, 4], ["stab", CH, 2]], "Sürgündeki Çeçen hükümeti Umarov'un 'emirlik' fikrine itiraz etti. || The Chechen government in exile objected to Umarov's 'emirate'."))},
        [["unrest", P_DAG, 20], ["unrest", P_ING, 20], ["stab", CH, -3], ["flag", "c99_emirate"]],
        icon="flag", scene="pre_court", major=False))

    L.append(M("c99_agustos08", 2008, 8, "Gürcistan Savaşı || The Russo-Georgian War",
        "7–12 Ağustos 2008: Gürcistan'ın Güney Osetya'ya taarruzu üzerine Rus birlikleri Gürcistan'a girdi; beş günlük savaşta Abhazya ve Güney Osetya Rusya tarafından tanındı. Gürcistan 2000'lerin başından beri Çeçen mültecileri ve Rus kampanyasına yönelik eleştiriler yüzünden Moskova'nın hedefinde. || 7–12 August 2008: after Georgia's assault on South Ossetia, Russian forces entered Georgia; in the five-day war Abkhazia and South Ossetia were recognised by Russia. Georgia had been a Moscow target since the early 2000s over Chechen refugees and criticism of the Russian campaign.",
        {GE: R("Saakaşvili Güney Osetya'da 'anayasal düzeni' yeniden kurmak istiyor; Batı destek sözü verdi ama Rus ordusu Kafkas Geçidi'nden gelebilir. || Saakashvili wants to restore 'constitutional order' in South Ossetia; the West has given encouragement but the Russian army can come through the Roki tunnel.",
                O("Tskhinvali'ye taarruz (tarihî) || Attack Tskhinvali (historical)", "Rusya'ya karşı savaş || War against Russia",
                  [["war", RU, GE, "solo"], ["troops", GE, 15], ["buff", RU, "att", 1.15, 6], ["rel", GE, US, 5], ["stab", GE, -4]], "Gürcü birlikleri Tskhinvali'ye taarruz etti; Rus zırhlıları Roki Tüneli'nden Gürcistan'a girdi. || Georgian troops attacked Tskhinvali; Russian armour entered through the Roki tunnel."),
                O("Taarruzdan vazgeç, diplomasi || Hold back and use diplomacy", "Savaştan kaçın || Avoid the war",
                  [["rel", GE, US, -2], ["stab", GE, 2], ["rel", GE, RU, 3]], "Tiflis son anda Tskhinvali taarruzunu iptal etti. || Tbilisi called off the Tskhinvali offensive at the last moment.")),
         RU: R("Medvedev cumhurbaşkanı, Putin başbakan; Gürcistan'ın NATO yolundaki ilerleyişi (Nisan 2008 Bükreş zirvesi) Kremlin'i rahatsız ediyor. Güney Osetya'da çatışma çıkarsa tepki hazır. || Medvedev is president, Putin prime minister; Georgia's NATO path (the April 2008 Bucharest summit) bothers the Kremlin. If fighting breaks out in South Ossetia, the response is ready.",
                O("Gürcistan'a karşı sınırlı harekât (tarihî) || A limited campaign against Georgia (historical)", "Barış gücü gerekçesiyle ilerle || Advance under a peacekeeping pretext",
                  [["war", RU, GE, "solo"], ["troops", RU, 2], ["buff", RU, "att", 1.15, 6], ["rel", RU, US, -10], ["rel", RU, GE, -30]], "Rus birlikleri Gori'ye kadar ilerledi; Batı ağır sözler söyledi. || Russian forces advanced to Gori; the West spoke harshly."),
                O("Yalnızca Osetya'yı koru || Defend Ossetia only", "Sınırlı karşılık || A limited reaction",
                  [["rel", RU, GE, -10], ["rel", RU, US, -3]], "Moskova yalnızca Güney Osetya'daki barış gücünü takviye etti. || Moscow only reinforced its peacekeepers in South Ossetia.")),
         TR: R("Türkiye Gürcistan'la (BTC, Kars-Tiflis demiryolu) ve Rusya'yla (doğalgaz, turizm, inşaat) aynı anda ilişkide. 'Kafkasya İstikrar ve İşbirliği Platformu' fikrini ortaya atma zamanı. || Turkey has ties with both Georgia (BTC, Kars–Tbilisi rail) and Russia (gas, tourism, construction). A good moment to float the 'Caucasus Stability and Cooperation Platform'.",
                O("Kafkasya platformu öner (tarihî) || Propose the Caucasus Platform (historical)", "Bölgesel arabuluculuk || Regional mediation",
                  [["rel", TR, RU, 4], ["rel", TR, GE, 4], ["xstab", TR, 2]], "Erdoğan Kafkasya İstikrar ve İşbirliği Platformu'nu önerdi. || Erdoğan proposed the Caucasus Stability and Cooperation Platform."),
                O("Gürcistan'a destek ver || Back Georgia", "Batı'yla hizalan || Align with the West",
                  [["rel", TR, GE, 10], ["rel", TR, RU, -8], ["rel", TR, US, 4]], "Ankara Gürcistan'ın toprak bütünlüğünü destekleyen açıklama yaptı. || Ankara issued a statement backing Georgia's territorial integrity."))},
        [["war", RU, GE, "solo"], ["troops", RU, 2], ["rel", RU, US, -10], ["rel", RU, GE, -30], ["rel", TR, RU, 2], ["flag", "c99_georgia"]],
        icon="border_clash", scene="border"))

    L.append(M("c99_eylul08", 2008, 9, "Sarkozy Ateşkesi || The Sarkozy Ceasefire",
        "12 Ağustos'ta Fransa Cumhurbaşkanı Sarkozy'nin aracılığıyla altı maddelik ateşkes imzalandı; Eylülde Rus birlikleri Gürcistan'ın iç kısımlarından çekilmeye başladı. Moskova'ya yaptırımlar sınırlı kaldı; Küresel finansal kriz gündemi ele geçiriyor. || The six-point ceasefire mediated by French President Sarkozy was signed in August; in September Russian troops began pulling out of the interior of Georgia. Sanctions against Moscow stayed limited as the global financial crisis took over the agenda.",
        {RU: R("Askerî olarak kazandınız, diplomatik olarak yalnızlaşıyorsunuz; Abhazya ve Güney Osetya'nın tanınması çok az ülkeden destek buldu. || You won militarily but are diplomatically isolated; recognition of Abkhazia and South Ossetia found support from very few states.",
                O("Ateşkesi kabul et, çekil (tarihî) || Accept the ceasefire and withdraw (historical)", "İki bölgeyi tanı, yaptırımlardan kaç || Recognise the two regions, avoid sanctions",
                  [["peace", RU, GE], ["rel", RU, US, -3], ["stab", RU, 1]], "Rus birlikleri Gori ve Poti'den çekildi; Abhazya ve Güney Osetya'da kalıcı üsler kurulacak. || Russian forces withdrew from Gori and Poti; permanent bases will be built in Abkhazia and South Ossetia."),
                O("İlerlemeye devam et, Tiflis'e yönel || Keep advancing toward Tbilisi", "Gürcistan'ı çökert || Collapse Georgia",
                  [["buff", RU, "att", 1.1, 6], ["rel", RU, US, -15], ["xstab", RU, -3]], "Moskova ateşkesi ihlal edip Gürcistan içlerine ilerledi; Batı sert tepki gösterdi. || Moscow violated the ceasefire and advanced deeper; the West reacted fiercely.")),
         GE: R("Ordu yenildi, topraklar kaybedildi. Batı sözlü destek verdi ama askerî yardım yok. Saakaşvili için ya savunma yenilenmesi ya da NATO'ya hızlı yaklaşmak. || The army has been beaten and territory lost. The West gave verbal support but no military aid. For Saakashvili: rebuild defences or race toward NATO.",
                O("Ateşkesi kabul et (tarihî) || Accept the ceasefire (historical)", "Kayıpları durdur || Stop the losses",
                  [["peace", RU, GE], ["rel", GE, US, 6], ["stab", GE, -3]], "Saakaşvili altı maddelik ateşkesi imzaladı. || Saakashvili signed the six-point ceasefire."),
                O("Savaşa devam, Batı'dan yardım iste || Fight on and ask for Western help", "Direniş || Resist",
                  [["troops", GE, 20], ["rel", GE, US, 8], ["stab", GE, -2]], "Gürcü yedek birlikleri Tiflis çevresinde mevzilendi. || Georgian reserves dug in around Tbilisi."))},
        [["peace", RU, GE], ["rel", RU, US, -3], ["stab", GE, -3]],
        icon="treaty", scene="peace", major=False))

    L.append(M("c99_nisan09", 2009, 4, "Terörle Mücadele Rejiminin Sonu || The End of the CTO Regime",
        "16 Nisan 2009: Medvedev Çeçenistan'daki 'terörle mücadele operasyonu' rejimini resmen sona erdirdi. Ramzan Kadirov bölgenin tam kontrolünde; Grozni yeniden inşa edildi; ama Dağıstan, İnguşetya ve Kabardin-Balkar'da şiddet sürüyor. || 16 April 2009: Medvedev officially ended the 'counter-terrorist operation' regime in Chechnya. Ramzan Kadyrov has full control of the region; Grozny has been rebuilt; yet violence continues in Dagestan, Ingushetia and Kabardino-Balkaria.",
        {RU: R("On yıllık savaş resmen bitti; bedeli çok büyük, ama Çeçenistan Rusya içinde kaldı. Sorun şimdi Ramzan Kadirov'un Moskova'ya olan bağımlılığı ve diğer cumhuriyetlerde yayılan şiddet. || Ten years of war are officially over; the cost was huge, but Chechnya stayed in Russia. The question now is Ramzan Kadyrov's dependence on Moscow and the violence spreading in other republics.",
                O("Rejimi bitir, Ramzan'ı sürdür (tarihî) || End the regime and keep Ramzan (historical)", "Normalleşme ilan et || Declare normalisation",
                  [["stab", RU, 3], ["unrest", P_CH, -20]], "Kremlin Çeçenistan'da 'normalleşme'yi ilan etti. || The Kremlin declared 'normalisation' in Chechnya."),
                O("Kuzey Kafkasya'ya kalkınma ve güvenlik paketi || A North Caucasus development and security package", "Yayılmayı önle || Contain the spread",
                  [["unrest", P_DAG, -10], ["unrest", P_ING, -10], ["gold", RU, -0.5], ["stab", RU, 2]], "Moskova Kuzey Kafkasya için yeni bir federal kalkınma programı açıkladı. || Moscow announced a new federal development programme for the North Caucasus.")),
         CH: R("Direniş bölünmüş ve zayıf; bağımsızlık fikri Ramzan'ın baskısı altında. Yine de Umarov'un Emirliği Kafkasya'da hâlâ ayakta. || The resistance is divided and weak; the independence idea is under Ramzan's pressure. Yet Umarov's Emirate is still standing in the Caucasus.",
                O("Gerilla savaşını sürdür || Continue the guerrilla war", "Direniş devam || Keep resisting",
                  [["unrest", P_CH, 10], ["troops", CH, 10]], "Dağlarda küçük çeteler Rus ve Kadirovtsi hedeflerine saldırmayı sürdürüyor. || Small bands in the mountains keep attacking Russian and Kadyrovtsy targets."),
                O("Siyasî bir uzlaşıya yönel || Accept a political settlement", "Af ve entegrasyon || Amnesty and integration",
                  [["rel", CH, RU, 15], ["stab", CH, 5], ["unrest", P_CH, -10]], "Çeçen komutanların bir kısmı Kadirov'un afından yararlandı. || Some Chechen commanders took Kadyrov's amnesty."))},
        [["stab", RU, 3], ["unrest", P_CH, -20], ["stab", CH, 2]],
        icon="dove", scene="peace"))
    return L


# ====================================================================== çağ ortak parçaları
def mk_defs(leaders, gdp, mil=None):
    d = {}
    for n, ldr in leaders.items():
        d[n] = {"leader": ldr}
        if n in gdp:
            d[n]["gdp"] = gdp[n]
    for n, m in (mil or {}).items():
        d.setdefault(n, {})["mil"] = m
    return d


def ev_list(rows):
    tr = [{"y": y, "m": m, "t": t, "fx": fx} for y, m, t, _, fx in rows]
    en = {str(i): e for i, (_, _, _, e, _) in enumerate(rows)}
    return tr, en


CUSTOM_BASE = {"name": "Çeçenistan (Içkerya)", "pids": [P_CH], "capital": P_CH, "tech": 0.3, "aggression": 0.4,
               "colors": ["1d6b3a", "ece6d6", "b02a2a"], "war": False}


def build_era(eid, c_variant, start_y, start_doy, name, sub, blurb, intro, suggest, tech, nukes, carriers, leaders_defs, gdp, mil, chain, horizon,
              events, obj, obj_en, custom_extra, garrison, stability, en_name, en_sub, en_blurb, en_intro, pop_f, gdp_default, moments):
    custom = dict(CUSTOM_BASE)
    custom.update(custom_extra)
    custom["play"] = bool(c_variant)
    ev_tr, ev_en = ev_list(events)
    era = {
        "id": eid, "name": name, "sub": sub, "family": "", "icon": "helmet", "mood": "war",
        "start_year": start_y, "start_doy": start_doy, "blurb": blurb, "suggest": suggest,
        "look": {"shadow": [0.06, 0.07, 0.09], "mid": [0.44, 0.46, 0.44], "light": [0.93, 0.9, 0.84], "amount": 0.18, "vignette": 0.14, "grain": 0.01},
        "defs": mk_defs(leaders_defs, gdp, mil), "pop_f": pop_f, "gdp_default": gdp_default,
        "tech_ovr": tech, "nukes": nukes, "carriers": carriers,
        "setup": {"blocs": [], "wars": [], "truce": [], "intro": intro, "custom": [custom], "garrison": garrison, "stability": stability},
        "events": ev_tr, "leaders": {"horizon": horizon, "chain": chain}, "objectives": obj,
        "en": {"name": en_name, "sub": en_sub, "blurb": en_blurb, "setup_intro": en_intro, "events": ev_en, "objectives": obj_en},
    }
    wr("data/eras/%s.json" % eid, era)
    kit_en = dict(k.en)
    wr("data/moments/%s.json" % eid, {"moments": moments, "en": kit_en})


# ---------------------------------------------------------------------------------------- 1994
TECH94 = {RU: 0.45, TR: 0.5, US: 0.95, "Germany": 0.85, "France": 0.85, UK: 0.85, "Israel": 0.85, "Japan": 0.85, "China": 0.3, UA: 0.4,
          GE: 0.15, AZ: 0.2, AM: 0.2, "India": 0.3, "Iran": 0.3, "Saudi Arabia": 0.55, "Poland": 0.4, "Egypt": 0.3, BY: 0.3, KZ: 0.25, "Italy": 0.8}
TECH99 = dict(TECH94, **{RU: 0.42, TR: 0.55, "China": 0.4, "India": 0.4, "Iran": 0.35, GE: 0.2, AZ: 0.25, UA: 0.35})

LEAD94 = {RU: "Cumhurbaşkanı|Boris Yeltsin", US: "Başkan|Bill Clinton", TR: "Başbakan|Tansu Çiller", GE: "Devlet Başkanı|Eduard Şevardnadze",
          AZ: "Cumhurbaşkanı|Haydar Aliyev", AM: "Cumhurbaşkanı|Levon Ter-Petrosyan", UA: "Cumhurbaşkanı|Leonid Kuçma", BY: "Cumhurbaşkanı|Aleksandr Lukaşenko",
          KZ: "Cumhurbaşkanı|Nursultan Nazarbayev", "Germany": "Şansölye|Helmut Kohl", "France": "Cumhurbaşkanı|François Mitterrand", UK: "Başbakan|John Major",
          "China": "Genel Sekreter|Jiang Zemin", "Japan": "Başbakan|Tomiichi Murayama", "Italy": "Başbakan|Silvio Berlusconi", "Israel": "Başbakan|Yitzhak Rabin",
          "Iran": "Cumhurbaşkanı|Ali Ekber Haşimi Rafsancani", "Egypt": "Cumhurbaşkanı|Hüsnü Mübarek", "India": "Başbakan|P. V. Narasimha Rao",
          "Saudi Arabia": "Kral|Fahd bin Abdülaziz", "Poland": "Cumhurbaşkanı|Lech Wałęsa", "Serbia": "Cumhurbaşkanı|Slobodan Milošević",
          CH: "Cumhurbaşkanı|Cahar Dudayev"}
GDP94 = {RU: 400, US: 7300, TR: 180, GE: 3, AZ: 4, AM: 1.6, UA: 50, BY: 17, KZ: 20, "Germany": 2600, "France": 1400, UK: 1100, "China": 560, "Japan": 5200}
MIL94 = {RU: dict(personnel=1700000, tank=15000, afv=20000, arty=14000, air=3200, sub=130),
         TR: dict(personnel=640000, tank=4200, afv=3700, arty=5000, air=500, sub=17),
         US: dict(personnel=1650000, tank=9000, afv=25000, arty=6000, air=5500, sub=95)}

CHAIN94 = {
    "France": [[1995, 5, "Cumhurbaşkanı|Jacques Chirac"]],
    UK: [[1997, 5, "Başbakan|Tony Blair"]],
    TR: [[1996, 3, "Başbakan|Mesut Yılmaz"], [1996, 6, "Başbakan|Necmettin Erbakan"]],
    "Japan": [[1996, 1, "Başbakan|Ryutaro Hashimoto"]],
    "Italy": [[1995, 1, "Başbakan|Lamberto Dini"], [1996, 5, "Başbakan|Romano Prodi"]],
    "Israel": [[1995, 11, "Başbakan|Şimon Peres"], [1996, 6, "Başbakan|Binyamin Netanyahu"]],
    "India": [[1996, 5, "Başbakan|Atal Bihari Vajpayee"], [1996, 6, "Başbakan|H. D. Deve Gowda"], [1997, 4, "Başbakan|I. K. Gujral"]],
    "Poland": [[1995, 12, "Cumhurbaşkanı|Aleksander Kwaśniewski"]],
    CH: [[1996, 4, "Cumhurbaşkanı Vekili|Zelimhan Yandarbiyev"], [1997, 2, "Cumhurbaşkanı|Aslan Maskhadov"]],
}

EV94 = [
 (1994, 12, "Rusya'nın 'anayasal düzeni yeniden tesis' operasyonu Kuzey Kafkasya'da gerginliği tırmandırdı.", "Russia's 'restore constitutional order' operation raises tension in the North Caucasus.", [["stab", RU, -1]]),
 (1995, 1, "Kobe depremi Japonya'yı vurdu; binlerce ölü.", "The Kobe earthquake struck Japan; thousands dead.", [["stab", "Japan", -3]]),
 (1995, 2, "Barings Bankası Asya türev işlemleri yüzünden iflas etti.", "Barings Bank collapsed over derivatives losses in Asia.", [["stab", UK, -1]]),
 (1995, 4, "Oklahoma City'de federal binaya bombalı saldırı: 168 ölü.", "Bomb attack on a federal building in Oklahoma City: 168 dead.", [["stab", US, -2]]),
 (1995, 7, "Srebrenitsa'da Bosna Sırp birlikleri binlerce Boşnak erkeği öldürdü.", "Bosnian Serb forces killed thousands of Bosniak men at Srebrenica.", [["stab", "Serbia", -2]]),
 (1995, 8, "Hırvatistan 'Fırtına' harekâtı ile Sırp Krajina'yı geri aldı.", "Croatia retook the Serb Krajina in Operation Storm.", [["stab", "Serbia", -3]]),
 (1995, 11, "Dayton Barış Anlaşması Bosna Savaşı'nı bitirdi; Rabin suikastle öldürüldü.", "The Dayton Accords ended the Bosnian War; Rabin was assassinated.", [["stab", "Israel", -5]]),
 (1996, 3, "Tayvan Boğazı krizi: ABD iki uçak gemisi gönderdi.", "Taiwan Strait crisis: the US sent two carrier groups.", [["stab", "China", -1]]),
 (1996, 7, "Atlanta Olimpiyatları'nda bombalı saldırı.", "Bomb attack at the Atlanta Olympics.", [["stab", US, -1]]),
 (1996, 11, "Yeltsin kalp ameliyatı geçirdi; Rusya'da iktidar belirsizliği.", "Yeltsin underwent heart surgery; uncertainty about power in Russia.", [["stab", RU, -3]]),
 (1997, 5, "Rusya ve NATO 'Kurucu Senet'i imzaladı.", "Russia and NATO signed the Founding Act.", [["stab", RU, 1]]),
 (1997, 7, "Hong Kong Çin'e devredildi; Tayland'da Asya krizi başladı.", "Hong Kong was handed back to China; the Asian crisis began in Thailand.", [["stab", UK, 0]]),
]

OBJ94 = {
 "*": [{"id": "h1", "type": "survive", "turns": 140, "text": "Ağustos 1996 – Mayıs 1997'ye kadar ayakta kal"},
       {"id": "h2", "type": "stability", "n": 50, "text": "İstikrarı 50 üzerinde tut", "required": False}],
 RU: [{"id": "hr1", "type": "eliminate", "country": CH, "text": "Çeçenistan'ı (Içkerya) ortadan kaldır"},
      {"id": "hr2", "type": "stability", "n": 45, "text": "Savaşa rağmen istikrarı 45 üzerinde tut", "required": False}],
 CH: [{"id": "hc1", "type": "survive", "turns": 140, "text": "Rusya'ya karşı ayakta kal (Mayıs 1997'ye kadar)"},
      {"id": "hc2", "type": "cease_war", "with": RU, "text": "Rusya'yla kalıcı barışı sağla"}],
 TR: [{"id": "ht1", "type": "no_war", "turns": 100, "text": "100 hafta savaşa girmeden Kafkasya'daki dengeyi koru"}],
 GE: [{"id": "hg1", "type": "no_war", "turns": 100, "text": "100 hafta boyunca Rusya'yla savaşa girme"}],
}
OBJ94_EN = {"h1": "Survive until May 1997", "h2": "Keep stability above 50", "hr1": "Eliminate Chechnya (Ichkeria)",
            "hr2": "Keep stability above 45 despite the war", "hc1": "Survive against Russia (until May 1997)", "hc2": "Reach a lasting peace with Russia",
            "ht1": "Keep the Caucasus balance for 100 weeks without going to war", "hg1": "Stay out of war with Russia for 100 weeks"}

# ---------------------------------------------------------------------------------------- 1999
LEAD99 = dict(LEAD94, **{
    RU: "Cumhurbaşkanı|Boris Yeltsin", US: "Başkan|Bill Clinton", TR: "Başbakan|Bülent Ecevit", GE: "Devlet Başkanı|Eduard Şevardnadze",
    AM: "Cumhurbaşkanı|Robert Koçaryan", "Germany": "Şansölye|Gerhard Schröder", "France": "Cumhurbaşkanı|Jacques Chirac", UK: "Başbakan|Tony Blair",
    "China": "Genel Sekreter|Jiang Zemin", "Japan": "Başbakan|Keizo Obuchi", "Italy": "Başbakan|Massimo D'Alema", "Israel": "Başbakan|Ehud Barak",
    "Iran": "Cumhurbaşkanı|Muhammed Hatemi", "India": "Başbakan|Atal Bihari Vajpayee", "Poland": "Cumhurbaşkanı|Aleksander Kwaśniewski",
    CH: "Cumhurbaşkanı|Aslan Maskhadov",
})
GDP99 = {RU: 200, US: 9600, TR: 250, GE: 3, AZ: 4.6, AM: 1.9, UA: 32, BY: 12, KZ: 17, "Germany": 2100, "France": 1500, UK: 1500, "China": 1090, "Japan": 4600}
MIL99 = {RU: dict(personnel=1200000, tank=10000, afv=15000, arty=12000, air=2800, sub=80),
         TR: dict(personnel=639000, tank=4200, afv=3800, arty=5200, air=520, sub=18),
         US: dict(personnel=1400000, tank=8500, afv=24000, arty=5500, air=5000, sub=85)}
CHAIN99 = {
    RU: [[1999, 12, "Cumhurbaşkanı Vekili|Vladimir Putin"], [2000, 5, "Cumhurbaşkanı|Vladimir Putin"], [2008, 5, "Cumhurbaşkanı|Dmitri Medvedev"]],
    US: [[2001, 1, "Başkan|George W. Bush"], [2009, 1, "Başkan|Barack Obama"]],
    UK: [[2007, 6, "Başbakan|Gordon Brown"]],
    "France": [[2007, 5, "Cumhurbaşkanı|Nicolas Sarkozy"]],
    "Germany": [[2005, 11, "Şansölye|Angela Merkel"]],
    TR: [[2002, 11, "Başbakan|Abdullah Gül"], [2003, 3, "Başbakan|Recep Tayyip Erdoğan"]],
    GE: [[2004, 1, "Devlet Başkanı|Mihail Saakaşvili"]],
    AZ: [[2003, 10, "Cumhurbaşkanı|İlham Aliyev"]],
    AM: [[2008, 4, "Cumhurbaşkanı|Serj Sarkisyan"]],
    UA: [[2005, 1, "Cumhurbaşkanı|Viktor Yuşçenko"]],
    "China": [[2003, 3, "Başkan|Hu Jintao"]],
    "Japan": [[2000, 4, "Başbakan|Yoshiro Mori"], [2001, 4, "Başbakan|Junichiro Koizumi"], [2006, 9, "Başbakan|Shinzo Abe"],
              [2007, 9, "Başbakan|Yasuo Fukuda"], [2008, 9, "Başbakan|Taro Aso"]],
    "Italy": [[2000, 4, "Başbakan|Giuliano Amato"], [2001, 6, "Başbakan|Silvio Berlusconi"], [2006, 5, "Başbakan|Romano Prodi"], [2008, 5, "Başbakan|Silvio Berlusconi"]],
    "Israel": [[2001, 3, "Başbakan|Ariel Şaron"], [2006, 5, "Başbakan|Ehud Olmert"], [2009, 3, "Başbakan|Binyamin Netanyahu"]],
    "Iran": [[2005, 8, "Cumhurbaşkanı|Mahmud Ahmedinejad"]],
    "India": [[2004, 5, "Başbakan|Manmohan Singh"]],
    "Saudi Arabia": [[2005, 8, "Kral|Abdullah bin Abdülaziz"]],
    "Poland": [[2005, 12, "Cumhurbaşkanı|Lech Kaczyński"]],
    CH: [[2005, 3, "Cumhurbaşkanı|Abdulhalim Saydullayev"], [2006, 6, "Emir|Doku Umarov"]],
}
EV99 = [
 (1999, 8, "17 Ağustos Marmara depremi Türkiye'yi vurdu: yaklaşık 17 bin ölü.", "The 17 August Marmara earthquake struck Turkey: about 17,000 dead.", [["stab", TR, -6]]),
 (1999, 10, "Pakistan'da General Müşerref darbeyle iktidarı aldı.", "In Pakistan, General Musharraf seized power in a coup.", [["stab", "Pakistan", -5]]),
 (1999, 12, "Y2K korkusu atlatıldı; Panama Kanalı Panama'ya devredildi.", "The Y2K scare passed; the Panama Canal was handed to Panama.", []),
 (2000, 10, "Yugoslavya'da Miloşeviç devrildi.", "Milošević was ousted in Yugoslavia.", [["stab", "Serbia", -5]]),
 (2001, 10, "ABD Afganistan'a girdi: Terörle Savaş başladı.", "The US entered Afghanistan: the War on Terror began.", [["stab", "Afghanistan", -8]]),
 (2003, 3, "ABD öncülüğünde Irak işgali başladı.", "The US-led invasion of Iraq began.", [["stab", "Iraq", -10]]),
 (2003, 11, "Gürcistan'da 'Gül Devrimi': Şevardnadze istifa etti.", "Georgia's 'Rose Revolution': Shevardnadze resigned.", [["stab", GE, -4]]),
 (2004, 5, "AB beş yeni üye kabul etti: doğu genişlemesi.", "The EU admitted new members: eastern enlargement.", [["stab", "Poland", 3]]),
 (2004, 12, "Ukrayna'da 'Turuncu Devrim'; Hint Okyanusu tsunamisi.", "Ukraine's 'Orange Revolution'; the Indian Ocean tsunami.", [["stab", UA, -3]]),
 (2005, 7, "Londra'da metro bombalı saldırıları: 52 ölü.", "London transport bombings: 52 dead.", [["stab", UK, -2]]),
 (2006, 10, "Kuzey Kore ilk nükleer deneyini yaptı.", "North Korea conducted its first nuclear test.", [["stab", "North Korea", -2]]),
 (2008, 9, "Lehman Brothers çöktü: küresel finans krizi başladı.", "Lehman Brothers collapsed: the global financial crisis began.", [["stab", US, -4], ["stab", UK, -3]]),
 (2009, 1, "Barack Obama ABD başkanı olarak yemin etti.", "Barack Obama was sworn in as US president.", []),
]
OBJ99 = {
 "*": [{"id": "j1", "type": "survive", "turns": 260, "text": "Beş yıl boyunca ayakta kal (2004'e kadar)"},
       {"id": "j2", "type": "stability", "n": 50, "text": "İstikrarı 50 üzerinde tut", "required": False}],
 RU: [{"id": "jr1", "type": "eliminate", "country": CH, "text": "Çeçenistan'ı (Içkerya) ortadan kaldır"},
      {"id": "jr2", "type": "stability", "n": 50, "text": "İstikrarı 50 üzerinde tut", "required": False}],
 CH: [{"id": "jc1", "type": "survive", "turns": 260, "text": "Rusya'ya karşı beş yıl ayakta kal"},
      {"id": "jc2", "type": "cease_war", "with": RU, "text": "Rusya'yla ateşkes yap (ve koru)", "required": False}],
 TR: [{"id": "jt1", "type": "stability", "n": 55, "text": "Marmara depremi sonrası istikrarı 55 üzerine çıkar"}],
 GE: [{"id": "jg1", "type": "no_war", "turns": 156, "text": "156 hafta Rusya'yla savaşa girme"}],
 US: [{"id": "ju1", "type": "alliances", "n": 6, "text": "6 müttefik edin"}],
}
OBJ99_EN = {"j1": "Survive five years (until 2004)", "j2": "Keep stability above 50", "jr1": "Eliminate Chechnya (Ichkeria)", "jr2": "Keep stability above 50",
            "jc1": "Survive five years against Russia", "jc2": "Agree and keep a ceasefire with Russia", "jt1": "Raise stability above 55 after the Marmara earthquake",
            "jg1": "Stay out of war with Russia for 156 weeks", "ju1": "Make 6 allies"}

POPF94 = {"Europe": 0.96, "North America": 0.78, "Asia": 0.76, "Africa": 0.55, "South America": 0.68, "Oceania": 0.8}
POPF99 = {"Europe": 0.97, "North America": 0.84, "Asia": 0.8, "Africa": 0.6, "South America": 0.72, "Oceania": 0.84}
GAR94 = [[P_ING, RU, 20000], [P_DAG, RU, 12000], [P_STA, RU, 8000]]
GAR99 = [[P_ING, RU, 45000], [P_DAG, RU, 30000], [P_STA, RU, 25000]]

if __name__ == "__main__":
    all_ids = []
    for variant in (False, True):
        eid = "ch94c" if variant else "ch94"
        k.en.clear(); k.title_en.clear()
        mm = keep_defaults(moments94(), main_roles=(RU, CH))
        build_era(eid, variant, 1994, 335,
                  "Içkerya Direniyor" if variant else "Çeçenistan Savaşı",
                  "Aralık 1994 – Birinci Çeçen Savaşı (Çeçen olarak oyna)" if variant else "Aralık 1994 – Birinci Çeçen Savaşı",
                  "11 Aralık 1994: Yeltsin 'anayasal düzeni yeniden tesis' için orduyu Çeçenistan'a gönderiyor. Cahar Dudayev'in bağımsız Çeçenistan'ı Grozni'de, Rus ordusu Mozdok'ta. Yılbaşı taarruzu, Samaşki, Budyonnovsk, Grozni'nin geri alınması ve Hasavyurt: ilk savaşı yeniden yaz.",
                  "Aralık 1994: Moskova'nın desteklediği Çeçen muhalefetinin tank saldırısı çöktü; Yeltsin Çeçenistan'a girmeye karar verdi. Dudayev'in 15 bin kişilik ordusu Grozni'de bekliyor; Rus birlikleri Mozdok, İnguşetya ve Dağıstan'da toplanıyor.",
                  [RU] if variant else [RU, TR, GE, US, AZ, UA], TECH94, [US, RU, UK, "France", "China", "Israel"], {US: 12, UK: 3, "France": 2, RU: 1, "India": 1, "Italy": 1},
                  LEAD94, GDP94, MIL94, CHAIN94, 1998, EV94, OBJ94, OBJ94_EN,
                  {"leader": "Cumhurbaşkanı|Cahar Dudayev", "troops": 90000, "gold_mult": 1.5}, GAR94, {RU: -6, TR: -3},
                  "Ichkeria Resists" if variant else "The Chechen War",
                  "December 1994 – The First Chechen War (play as Chechnya)" if variant else "December 1994 – The First Chechen War",
                  "11 December 1994: Yeltsin sends the army into Chechnya to 'restore constitutional order'. Dudayev's independent Chechnya holds Grozny while the Russian army masses at Mozdok. The New Year's storm, Samashki, Budyonnovsk, the retaking of Grozny and Khasavyurt: rewrite the first war.",
                  "December 1994: a Moscow-backed Chechen opposition tank assault collapsed and Yeltsin decided to enter Chechnya. Dudayev's army of 15,000 waits in Grozny; Russian forces are massing in Mozdok, Ingushetia and Dagestan.",
                  POPF94, 0.25, mm)
        all_ids.append(eid)
    for variant in (False, True):
        eid = "ch99c" if variant else "ch99"
        k.en.clear(); k.title_en.clear()
        mm = keep_defaults(moments99(), main_roles=(RU, CH, GE) if False else (RU, CH))
        build_era(eid, variant, 1999, 213,
                  "Kafkas Direnişi" if variant else "Çeçenistan Savaşı II",
                  "Ağustos 1999 – Terörle Mücadele Harekâtı (Çeçen olarak oyna)" if variant else "Ağustos 1999 – Terörle Mücadele Harekâtı",
                  "7 Ağustos 1999: Basayev ve Hattab Dağıstan'a girdi; Putin başbakan oldu. Apartman patlamaları, Terek'in ötesi, Grozni'nin düşüşü, Beslan, Maskhadov'un ölümü ve Kafkas Emirliği: on yıllık savaşı yaşa.",
                  "Ağustos 1999: Yeltsin'in sağlığı kötü, Rusya iflasın eşiğinden yeni dönmüş; Maskhadov'un Çeçenistan'ı fiilen bağımsız ama kaos içinde. Dağıstan'ın dağlarında bir çatışma tüm Kafkasya'yı yeniden ateşe verebilir.",
                  [RU] if variant else [RU, TR, GE, US, AZ, UA], TECH99, [US, RU, UK, "France", "China", "Israel", "India", "Pakistan"],
                  {US: 12, UK: 3, "France": 2, RU: 1, "India": 1, "Italy": 2},
                  LEAD99, GDP99, MIL99, CHAIN99, 2010, EV99, OBJ99, OBJ99_EN,
                  {"leader": "Cumhurbaşkanı|Aslan Maskhadov", "troops": 110000, "gold_mult": 1.2}, GAR99, {RU: -8, TR: -4},
                  "Caucasus Resistance" if variant else "The Second Chechen War",
                  "August 1999 – The Counter-Terrorist Operation (play as Chechnya)" if variant else "August 1999 – The Counter-Terrorist Operation",
                  "7 August 1999: Basayev and Khattab enter Dagestan and Putin becomes prime minister. The apartment bombings, across the Terek, the fall of Grozny, Beslan, Maskhadov's death and the Caucasus Emirate: live a ten-year war.",
                  "August 1999: Yeltsin is ailing and Russia has just stepped back from bankruptcy; Maskhadov's Chechnya is independent in practice but in chaos. A clash in the mountains of Dagestan may set the whole Caucasus ablaze again.",
                  POPF99, 0.28, mm)
        all_ids.append(eid)
    idx = rd("data/eras/index.json")
    for eid in all_ids:
        if eid not in idx:
            idx.insert(idx.index("cw74") + 1, eid) if "cw74" in idx else idx.append(eid)
    # index.json tek satırlık liste
    with open(os.path.join(ROOT, "data/eras/index.json"), "w", encoding="utf-8") as f:
        json.dump(idx, f, ensure_ascii=False)
        f.write("\n")
    print("tamam:", all_ids)

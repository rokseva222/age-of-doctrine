#!/usr/bin/env python3
"""Modern senaryo "Ayşe Tatile Tekrar Çıkıyor" (2027, Doğu Akdeniz): data/scenarios/cyprus27.json üretir + index'e ekler.
Çalıştır: python3 tools/data/gen_cyprus27.py"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from moment_kit import Kit, keep_defaults

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TR = "Turkey"; GR = "Greece"; CY = "Cyprus"; NC = "N. Cyprus"; FR = "France"; IL = "Israel"; EG = "Egypt"; US = "United States of America"; EU = "Germany"
k = Kit()
k.title_en = {"Yeni Genel Sekreter, Eski Dosya": "A New Secretary-General, an Old File", "Sondaj Gemisi Krizi": "The Drillship Crisis",
              "Büyük Kablo Hattı": "The Great Cable Route", "Atina'da Seçim Yazı": "Election Summer in Athens", "Maraş'ta Hareket": "Movement in Varosha",
              "Fırkateynler Burun Buruna": "Frigates Nose to Nose", "Yıl Sonu Zirvesi: Güven Paketi": "Year-End Summit: The Confidence Package",
              "Güvenlik Konseyi: Ateşkes Çağrısı": "Security Council: A Call for Ceasefire"}
M = []

# 1 — Ocak: yeni Genel Sekreter, eski dosya
M.append(k.moment("c27_ocak", "Yeni Genel Sekreter, Eski Dosya",
  ("Ocak 2027: BM'nin yeni Genel Sekreteri göreve başladı ve ilk gündemlerinden biri Kıbrıs. Taraflar adadaki yeni geçiş kapıları, güven artırıcı önlemler ve resmî müzakerelerin yeniden başlaması üzerinde pazarlık ediyor.",
   "January 2027: the UN's new Secretary-General has taken office and Cyprus is among the first items on the agenda. The sides haggle over new crossing points, confidence-building measures and a formal restart of negotiations."),
  {TR: k.role(("Ankara 'gerçekçi çözüm' diyor ama yeni dönemin masasını boş bırakmak da istemiyor. Kuzeyde yeni yönetim federasyon dışı seçeneklere mesafeli.",
               "Ankara calls for a 'realistic solution' but does not want to leave the new era's table empty. The new northern administration keeps its distance from non-federal options."),
        k.opt(("Masaya otur: 5+1 formatı", "Take a seat: the 5+1 format"), ("Müzakere kapısı aralanır", "The door to negotiation opens"), [["rel", TR, GR, 8], ["rel", TR, CY, 6], ["xstab", TR, 1], ["flag", "c27_masa"]],
              ("Ankara BM'nin 5+1 formatına katılacağını duyurdu.", "Ankara announced it will join the UN's 5+1 format.")),
        k.opt(("İki devletli çözümü öne sür", "Push the two-state position"), ("Sert duruş", "A hard line"), [["rel", TR, GR, -10], ["rel", TR, CY, -12], ["xstab", TR, 2], ["flag", "c27_sert"]],
              ("Ankara iki egemen devlet mesajını yeniden vurguladı; AB'de tepki var.", "Ankara re-emphasised its two-sovereign-states message; the EU reacts.")),
        k.opt(("Önce kapılar: iki yeni geçiş noktası", "Crossings first: two new checkpoints"), ("Güven artırıcı adım", "A confidence-building step"), [["rel", TR, CY, 10], ["stab", NC, 3], ["flag", "c27_masa"]],
              ("Lefkoşa'da iki yeni geçiş kapısı açıldı; mahalleler arası trafik arttı.", "Two new crossings opened in Nicosia; traffic between the communities grew."))),
   GR: k.role(("Yunanistan seçim yılına giriyor; Atina Kıbrıs'ta 'ilkeli' bir duruşu savunuyor ama Ankara'yla gerginliği düşük tutmak istiyor.",
               "Greece enters an election year; Athens defends a 'principled' stance on Cyprus but wants to keep tension with Ankara low."),
        k.opt(("BM sürecini destekle", "Back the UN process"), ("Federasyon ilkesi", "The federal principle"), [["rel", GR, TR, 6], ["rel", GR, CY, 4], ["xstab", GR, 1]],
              ("Atina BM çerçevesindeki müzakerelere tam destek verdi.", "Athens gave full support to the UN-framed talks.")),
        k.opt(("Sert çizgi: AB baskısı", "Hard line: EU pressure"), ("Brüksel'i devreye sok", "Bring in Brussels"), [["rel", GR, TR, -8], ["rel", GR, FR, 6], ["xstab", GR, 2]],
              ("Atina Kıbrıs konusunu AB zirvesinin gündemine taşıdı.", "Athens put Cyprus on the EU summit agenda."))),
   CY: k.role(("Lefkoşa AB başkanlığının gölgesinden çıktı; hükûmet enerji gelirlerini ve savunma ortaklıklarını güçlendirmek istiyor, ama yeni geçiş kapıları iç kamuoyunda tartışmalı.",
               "Nicosia has stepped out of the shadow of the EU presidency; the government wants to boost energy revenue and defence partnerships, but new crossings are debated at home."),
        k.opt(("Kapıları aç, masaya otur", "Open the crossings, take a seat"), ("Uzlaşma çizgisi", "Conciliatory line"), [["rel", CY, NC, 12], ["rel", CY, TR, 8], ["stab", CY, 2], ["flag", "c27_masa"]],
              ("Lefkoşa yeni kapılar için BM'ye 'evet' dedi.", "Nicosia said 'yes' to the UN on new crossings.")),
        k.opt(("Güvenliği öne al: savunma harcaması", "Security first: defence spending"), ("İsrail/Fransa tedariki", "Israeli/French supplies"), [["troops", CY, 15], ["rel", CY, IL, 8], ["rel", CY, TR, -6]],
              ("Rum Yönetimi hava savunma ve gözetleme sistemlerine yatırım yapıyor.", "The Greek-Cypriot administration is investing in air defence and surveillance."))),
   NC: k.role(("Kuzey yönetimi federal bir çözüme açık ama Ankara ile uyumlu yürümek zorunda. Ekonomi pahalılık ve Türk lirası dalgalanması altında.",
               "The northern administration is open to a federal solution but must move in step with Ankara. The economy suffers from high prices and lira swings."),
        k.opt(("Geçiş kapılarını savun", "Defend the new crossings"), ("Ticaret ve temas", "Trade and contact"), [["stab", NC, 4], ["rel", NC, CY, 10], ["rel", NC, TR, -3]],
              ("Kuzey yönetimi karşılıklı temasların artırılmasını istedi.", "The northern administration asked for more contact between communities.")),
        k.opt(("Ankara ile tam eşgüdüm", "Full coordination with Ankara"), ("Entegrasyon", "Integration"), [["rel", NC, TR, 10], ["rel", NC, CY, -6], ["stab", NC, 1]],
              ("Kuzey yönetimi ekonomik entegrasyon protokollerini hızlandırdı.", "The northern administration sped up economic integration protocols.")))},
  [["rel", TR, GR, 2], ["stab", CY, 1]], turn=1, major=False, icon="handshake", scene="pre_trade"))

# 2 — Şubat: sondaj gemisi krizi
M.append(k.moment("c27_sondaj", "Sondaj Gemisi Krizi",
  ("Şubat 2027: Güney Kıbrıs açıklarındaki ruhsat sahasında yeni bir arama kuyusu için sondaj gemisi geldi. Türkiye NAVTEX ilan etti ve bir savaş gemisi bölgeye yöneldi; Yunan ve Fransız firkateynleri de yola çıktı.",
   "February 2027: a drillship arrived for a new exploration well in a licence block south of Cyprus. Turkey issued a NAVTEX and a warship headed for the area; Greek and French frigates also set sail."),
  {TR: k.role(("Savunma Bakanlığı ruhsat sahasının bir kısmını 'Türk kıta sahanlığı' sayıyor. Filo hazır; ama Avrupa'nın yaptırım tartışması yeniden alevlenebilir.",
               "The Defence Ministry regards part of the block as 'Turkish continental shelf'. The fleet is ready, but the European sanctions debate could flare up again."),
        k.opt(("Gemiyi sahaya gönder, sondajı engelle", "Send the ship, block the drilling"), ("Gösteri ve gerginlik", "Show of force and tension"), [["rel", TR, GR, -15], ["rel", TR, CY, -15], ["rel", TR, FR, -10], ["xstab", TR, 3], ["buff", TR, "def", 1.1, 8], ["flag", "c27_gerilim"]],
              ("Türk savaş gemisi sondaj gemisinin yanına yanaştı; üç donanma sahada.", "A Turkish warship moved alongside the drillship; three navies are on the scene.")),
        k.opt(("NAVTEX'i geri çek, ortak gaz fonu öner", "Withdraw the NAVTEX, propose a joint gas fund"), ("Gelirde adil pay", "A fair share of revenue"), [["rel", TR, CY, 8], ["rel", TR, GR, 5], ["xstab", TR, -2], ["flag", "c27_masa"]],
              ("Ankara ruhsat sahalarında gelirin iki toplum arasında paylaşılmasını önerdi.", "Ankara proposed that revenue from the blocks be shared between the two communities.")),
        k.opt(("Sessiz izle", "Watch quietly"), ("Gerilimi artırmadan", "Without raising tension"), [["xstab", TR, 1], ["rel", TR, GR, -2]],
              ("Ankara sondaj gemisini uzaktan izlemekle yetindi.", "Ankara contented itself with watching the drillship from afar."))),
   GR: k.role(("Atina Kıbrıs'ın münhasır ekonomik bölgesinde sondajı destekliyor; deniz kuvvetleri yola çıkarsa Ege'deki karşılıklı yumuşama bozulabilir.",
               "Athens backs drilling in Cyprus's exclusive economic zone; sending the navy could unravel the Aegean détente."),
        k.opt(("Firkateyn gönder", "Send a frigate"), ("Ortak caydırıcılık", "Joint deterrence"), [["rel", GR, TR, -15], ["rel", GR, CY, 10], ["rel", GR, FR, 8], ["xstab", GR, 3], ["flag", "c27_gerilim"]],
              ("Yunan firkateyni Kıbrıs açıklarına ulaştı.", "A Greek frigate reached the waters off Cyprus.")),
        k.opt(("Diplomasi: AB ve NATO", "Diplomacy: EU and NATO"), ("Gerilimi kanallara taşı", "Take the tension to the institutions"), [["rel", GR, TR, 3], ["xstab", GR, -1]],
              ("Atina konuyu NATO ve AB kanallarından yürütüyor.", "Athens handles the matter through NATO and EU channels."))),
   CY: k.role(("Rum Yönetimi gaz gelirini bütçenin geleceği olarak görüyor; ama sondaj gemisinin etrafı yabancı savaş gemileriyle doldu.",
               "The Greek-Cypriot administration sees gas revenue as the budget's future, but the drillship is ringed by foreign warships."),
        k.opt(("Sondajı sürdür", "Keep drilling"), ("Hak iddiası", "Assert the right"), [["rel", CY, TR, -12], ["rel", CY, FR, 6], ["stab", CY, 3], ["flag", "c27_gerilim"]],
              ("Rum Yönetimi sondajın sürdüğünü ve ruhsatın tam yasal olduğunu açıkladı.", "The Greek-Cypriot administration said drilling continues and the licence is fully lawful.")),
        k.opt(("Sondajı askıya al, müzakere", "Pause drilling, negotiate"), ("Gerilimi düşür", "Lower the tension"), [["rel", CY, TR, 10], ["stab", CY, -3], ["flag", "c27_masa"]],
              ("Lefkoşa sondajı kısa süreliğine askıya aldı; BM arabulucusu memnun.", "Nicosia briefly paused drilling; the UN mediator is pleased."))),
   FR: k.role(("Fransız firkateyni sahada; Paris Doğu Akdeniz'de kalıcı varlık istiyor ama Ankara'yla doğrudan çatışmak istemiyor.",
               "A French frigate is on station; Paris wants a lasting presence in the Eastern Mediterranean but not a direct clash with Ankara."),
        k.opt(("Firkateyni sahada tut", "Keep the frigate on station"), ("Kıbrıs-Yunanistan ile dayanışma", "Solidarity with Cyprus and Greece"), [["rel", FR, TR, -10], ["rel", FR, GR, 8], ["rel", FR, CY, 8]],
              ("Fransız donanması sahada kaldı.", "The French navy stayed on station.")),
        k.opt(("Geri çek, AB düzleminde ele al", "Pull back, handle at EU level"), ("Gerilim düşer", "Tension drops"), [["rel", FR, TR, 5], ["rel", FR, GR, -3]],
              ("Paris firkateyni geri çekti ve konuyu AB'ye taşıdı.", "Paris pulled the frigate back and took the issue to the EU.")))},
  [["rel", TR, GR, -6], ["rel", TR, CY, -6], ["stab", CY, 1], ["flag", "c27_gerilim"]], turn=7, major=False, scene="pre_naval", icon="naval"))

# 3 — Nisan: büyük kablo hattı
M.append(k.moment("c27_kablo", "Büyük Kablo Hattı",
  ("Nisan 2027: Yunanistan–Kıbrıs–İsrail enerji bağlantısı (Great Sea Interconnector) için döşeme gemileri etüt rotasına yaklaştı. Türkiye rotanın kendi deniz yetki alanından geçtiğini savunuyor; AB ve ABD projeyi destekliyor.",
   "April 2027: survey vessels for the Greece–Cyprus–Israel energy link (Great Sea Interconnector) approached the route. Turkey says the route crosses its maritime jurisdiction; the EU and US back the project."),
  {TR: k.role(("Etüt gemilerinin rotası Ankara'nın 'ilgili makamlardan izin' şartını çiğniyor. Deniz Kuvvetleri refakat edebilir; ancak Avrupa ve Washington ağır tepki verebilir.",
               "The survey ships' route ignores Ankara's 'permission from the authorities' condition. The Navy could shadow them, but Europe and Washington may react harshly."),
        k.opt(("Gemileri uzaktan takip et, durdur", "Shadow and stop the vessels"), ("Caydırıcılık", "Deterrence"), [["rel", TR, GR, -12], ["rel", TR, US, -6], ["rel", TR, IL, -10], ["xstab", TR, 2], ["flag", "c27_gerilim"]],
              ("Türk savaş gemileri etüt gemilerini adım adım izledi; proje ertelendi.", "Turkish warships shadowed the survey vessels step by step; the project was postponed.")),
        k.opt(("Rotayı müzakere etmeyi teklif et", "Offer to negotiate the route"), ("Hukuki çerçeve", "A legal framework"), [["rel", TR, GR, 6], ["rel", TR, US, 5], ["xstab", TR, -1], ["flag", "c27_masa"]],
              ("Ankara rota için hukuki çerçeve görüşmesi teklif etti.", "Ankara offered talks on a legal framework for the route.")),
        k.opt(("Enerji koridoruna ortak ol", "Join the energy corridor"), ("Ankara masanın içinde", "Ankara inside the tent"), [["rel", TR, GR, 10], ["rel", TR, CY, 8], ["rel", TR, IL, 5], ["xstab", TR, 2], ["gold", TR, 2], ["flag", "c27_masa"]],
              ("Ankara kabloyu ortak enerji koridoruna dönüştürmeyi önerdi.", "Ankara suggested turning the cable into a joint energy corridor."))),
   GR: k.role(("Kablo, Atina'nın 'Kıbrıs'ı Avrupa şebekesine bağlama' vizyonunun omurgası; ama kredi, yatırım ve güvenlik riski artıyor.",
               "The cable is the backbone of Athens's vision to link Cyprus to the European grid, but credit, investment and security risks are rising."),
        k.opt(("Projeyi sürdür, deniz eskortu", "Press on with a naval escort"), ("Kararlı duruş", "A firm stand"), [["rel", GR, TR, -10], ["rel", GR, FR, 6], ["xstab", GR, 3], ["flag", "c27_gerilim"]],
              ("Atina kablo gemilerine savaş gemisi eskortu sağladı.", "Athens provided warship escorts for the cable vessels.")),
        k.opt(("Ertele, hukuki yola başvur", "Postpone, go legal"), ("Uluslararası hukuk", "International law"), [["rel", GR, TR, 4], ["xstab", GR, -2]],
              ("Atina projeyi ertelemeyi ve hukuki yollara başvurmayı seçti.", "Athens chose to postpone the project and pursue legal avenues."))),
   IL: k.role(("Tel Aviv kablonun ve doğal gaz ortaklığının güvenliği için Yunanistan ve Kıbrıs'la savunma iş birliğini artırıyor.",
               "Tel Aviv is boosting defence cooperation with Greece and Cyprus to protect the cable and gas partnership."),
        k.opt(("Hava savunma ve gözetleme desteği", "Offer air-defence and surveillance support"), ("Güvenlik ortaklığı", "Security partnership"), [["rel", IL, GR, 10], ["rel", IL, CY, 10], ["rel", IL, TR, -10]],
              ("İsrail Doğu Akdeniz ortaklarına gözetleme sistemleri sattı.", "Israel sold surveillance systems to its Eastern Mediterranean partners.")),
        k.opt(("Geri planda kal", "Stay in the background"), ("Gerilimden uzak", "Away from tension"), [["rel", IL, TR, 2]],
              ("Tel Aviv gerilimden uzak durdu.", "Tel Aviv stayed clear of the tension."))),
   EG: k.role(("Kahire Yunanistan'la MEB anlaşması yaptı ve bölgenin gaz merkezi olmak istiyor; Ankara ile ilişkiler ısınmış durumda.",
               "Cairo signed an EEZ deal with Greece and wants to be the region's gas hub; ties with Ankara have been warming."),
        k.opt(("Arabulucu rolü", "Play the mediator"), ("Gaz merkezi Kahire", "Cairo as the gas hub"), [["rel", EG, TR, 6], ["rel", EG, GR, 4], ["xstab", EG, 1]],
              ("Kahire taraflar arasında arabuluculuk önerdi.", "Cairo offered to mediate between the parties.")),
        k.opt(("Yunanistan ile hizalan", "Align with Greece"), ("MEB anlaşması", "The EEZ agreement"), [["rel", EG, GR, 8], ["rel", EG, TR, -6]],
              ("Kahire Atina'nın deniz sınırı tezini destekledi.", "Cairo backed Athens's maritime-boundary thesis.")))},
  [["rel", TR, GR, -4], ["rel", IL, TR, -4]], turn=15, major=False, scene="pre_trade", icon="trade", requires=["c27_gerilim"], forbid=[]))

# 4 — Haziran: Yunanistan seçimleri
M.append(k.moment("c27_secim", "Atina'da Seçim Yazı",
  ("Haziran 2027: Yunanistan'da seçim kampanyası kızıştı. Kıbrıs, Ege ve savunma harcamaları miting konuları; muhalefet hükûmeti 'yumuşaklıkla' suçluyor.",
   "June 2027: the campaign heats up in Greece. Cyprus, the Aegean and defence spending dominate rallies; the opposition accuses the government of 'softness'."),
  {GR: k.role(("Seçim sandığı yaklaşırken iki yol var: Ege'de sert söylem ya da yumuşama diliyle merkez seçmen.", "As the ballot nears there are two roads: tough Aegean rhetoric or détente language for the centre."),
        k.opt(("Sert söylem: ulusal güvenlik", "Tough rhetoric: national security"), ("Milliyetçi oy", "The nationalist vote"), [["xstab", GR, 4], ["rel", GR, TR, -12], ["troops", GR, 8]],
              ("Atina seçim kampanyasında Ege ve Kıbrıs'ta sert bir çizgi izledi.", "Athens ran a hard line on the Aegean and Cyprus during the campaign.")),
        k.opt(("Yumuşama: Atina Bildirgesi'ne dönüş", "Détente: back to the Athens Declaration"), ("Merkez oy", "The centre vote"), [["xstab", GR, 1], ["rel", GR, TR, 12]],
              ("Atina karşılıklı güven artırıcı önlemleri yeniden öne çıkardı.", "Athens put confidence-building measures back at the centre."))),
   TR: k.role(("Atina'daki seçim söylemleri Ankara'da tepki yaratıyor. Karşılık vermek mi, soğukkanlı kalmak mı?", "Election rhetoric in Athens provokes reaction in Ankara. Reply in kind or stay calm?"),
        k.opt(("Aynı dille karşılık ver", "Reply in kind"), ("Sert dil", "Hard language"), [["rel", TR, GR, -10], ["xstab", TR, 3]],
              ("Ankara seçim kampanyasındaki sert açıklamalara aynı dille yanıt verdi.", "Ankara answered the campaign rhetoric in kind.")),
        k.opt(("Soğukkanlı kal", "Stay calm"), ("Seçimi bekle", "Wait for the vote"), [["rel", TR, GR, 3], ["xstab", TR, -1]],
              ("Ankara seçimin sonuçlanmasını bekleme kararı aldı.", "Ankara decided to wait for the vote.")))},
  [["stab", GR, 2], ["rel", TR, GR, -3]], turn=24, major=False, icon="handshake", scene="pre_trade"))

# 5 — Ağustos: Maraş'ta hareket
M.append(k.moment("c27_maras", "Maraş'ta Hareket",
  ("Ağustos 2027: Kuzey yönetimi Maraş (Varosha) bölgesinde yeni açılışlar ve yerleşim planlarını duyurdu; Rum Yönetimi ve BM Güvenlik Konseyi önceki kararlara atıf yaptı.",
   "August 2027: the northern administration announced new openings and settlement plans in Varosha; the Greek-Cypriot administration and the UN Security Council referred to earlier resolutions."),
  {NC: k.role(("Maraş ekonomik canlanma için kozunuz ama Rum mülk sahipleri ve BM kararları açık bir engel.", "Varosha is your card for economic revival but Greek-Cypriot owners and UN resolutions are an obvious obstacle."),
        k.opt(("Açılışı genişlet", "Expand the opening"), ("Ankara'nın desteğiyle", "With Ankara's backing"), [["stab", NC, 4], ["rel", NC, CY, -15], ["rel", NC, TR, 8], ["flag", "c27_gerilim"]],
              ("Maraş'ta yeni bölge halka açıldı; Lefkoşa protesto etti.", "A new area of Varosha opened to the public; Nicosia protested.")),
        k.opt(("Mülkiyet çerçevesi: ortak komisyon", "Property framework: joint commission"), ("Hak sahiplerine yol", "A path for owners"), [["stab", NC, 1], ["rel", NC, CY, 10], ["flag", "c27_masa"]],
              ("Kuzey yönetimi mülkiyet için ortak bir komisyon önerdi.", "The northern administration proposed a joint property commission."))),
   CY: k.role(("Mülkiyet hakları ve BM kararları sizin için kırmızı çizgi; ama tepkiyi ölçmeden yükseltmek istemiyorsunuz.", "Property rights and UN resolutions are your red line, but you do not want to escalate without measuring the reaction."),
        k.opt(("BM Güvenlik Konseyi'ne git", "Go to the UN Security Council"), ("Hukuki zemin", "Legal ground"), [["rel", CY, US, 6], ["rel", CY, FR, 6], ["rel", CY, TR, -8]],
              ("Rum Yönetimi Güvenlik Konseyi'ni olağan dışı toplantıya çağırdı.", "The Greek-Cypriot administration asked for a special Security Council session.")),
        k.opt(("Ortak komisyona yanıt ver", "Respond to the joint commission"), ("Teknik zemin", "Technical ground"), [["rel", CY, NC, 8], ["stab", CY, -2], ["flag", "c27_masa"]],
              ("Lefkoşa mülkiyet komisyonuna teknik düzeyde yanıt verdi.", "Nicosia replied to the property commission at technical level."))),
   TR: k.role(("Kuzeye verdiğiniz desteğin sınırı: Maraş'ta açılış sürsün mü, yoksa BM ile uyum mu?", "The limit of your support for the north: should the opening in Varosha continue or align with the UN?"),
        k.opt(("Kuzeyi destekle", "Back the north"), ("Kıbrıs Türk tarafının hakkı", "The Turkish-Cypriot side's right"), [["rel", TR, NC, 10], ["rel", TR, CY, -8], ["rel", TR, GR, -6], ["xstab", TR, 2]],
              ("Ankara Maraş'ta kuzey yönetiminin yanında durdu.", "Ankara stood with the northern administration on Varosha.")),
        k.opt(("BM'ye uyumu tavsiye et", "Advise alignment with the UN"), ("Arabuluculuk", "Mediation"), [["rel", TR, CY, 5], ["rel", TR, NC, -4], ["rel", TR, FR, 4], ["xstab", TR, -2]],
              ("Ankara kuzey yönetimine BM çerçevesine uyumu tavsiye etti.", "Ankara advised the northern administration to align with the UN framework.")))},
  [["rel", CY, NC, -6], ["stab", CY, -1]], turn=32, major=False, icon="landing", scene="pre_assault"))

# 6 — Ekim: firkateynler burun buruna
M.append(k.moment("c27_firkateyn", "Fırkateynler Burun Buruna",
  ("Ekim 2027: Kıbrıs'ın güney doğusunda bir Türk ve bir Yunan firkateyni arasında 'ucu ucuna' kaçınılan bir çarpışma yaşandı; iki başkent de hava ve deniz birliklerini alarma geçirdi. Dünya tek bir hatanın felakete dönüşebileceğini konuşuyor.",
   "October 2027: off Cyprus's southeast a Turkish and a Greek frigate narrowly avoided a collision; both capitals put air and naval units on alert. The world is talking about one mistake turning into disaster."),
  {TR: k.role(("Ankara'da kriz masası kuruldu. Savaş gemisi kaptanı 'savunma' diyor; Yunan tarafı 'taciz' diyor. Bir gösteri harekâtı mı, yoksa sıcak hat mı?", "A crisis desk was set up in Ankara. The frigate captain says 'defence'; the Greek side says 'harassment'. A show-of-force operation, or the hotline?"),
        k.opt(("Sert yanıt: ada kıyılarında gösteri", "Hard reply: a show of force off the island"), ("Rum Yönetimine baskı", "Pressure on the Greek-Cypriot administration"), [["war", TR, CY, "solo"], ["buff", TR, "att", 1.15, 8], ["rel", TR, GR, -20], ["rel", TR, US, -10], ["xstab", TR, 3], ["flag", "c27_clash"]],
              ("Türk birlikleri Kıbrıs açıklarında harekâta geçti; Rum Yönetimi ile savaş durumu başladı.", "Turkish forces went into action off Cyprus; a state of war with the Greek-Cypriot administration began.")),
        k.opt(("Sıcak hat ve karşılıklı geri çekilme", "Hotline and mutual pull-back"), ("Gerginliği düşür", "Lower the tension"), [["rel", TR, GR, 12], ["rel", TR, US, 5], ["xstab", TR, -1], ["flag", "c27_masa"]],
              ("Ankara ve Atina sıcak hat üzerinden karşılıklı geri çekilmede anlaştı.", "Ankara and Athens agreed on a mutual pull-back via the hotline.")),
        k.opt(("BM ve NATO arabulucusu", "UN and NATO mediators"), ("Çok taraflı çözüm", "Multilateral fix"), [["rel", TR, GR, 6], ["rel", TR, FR, 4], ["xstab", TR, -2], ["flag", "c27_masa"]],
              ("Genel Sekreter ve NATO Genel Sekreteri iki başkente çağrıda bulundu.", "The UN Secretary-General and NATO's chief appealed to both capitals."))),
   GR: k.role(("Savunma Bakanı 'tek bir ateş savaş demek' diyor. Ege adalarında alarm. Askerî kartı mı oynamalı, diplomasiye mi yüklenmeli?", "The Defence Minister says 'one shot means war'. Alarm on the Aegean islands. Play the military card or lean on diplomacy?"),
        k.opt(("Seferberlik ve ortak caydırıcılık", "Mobilise and deter jointly"), ("Fransa ve Kıbrıs ile", "With France and Cyprus"), [["mob", GR, 6], ["rel", GR, TR, -15], ["rel", GR, FR, 8], ["xstab", GR, 2], ["flag", "c27_clash"]],
              ("Atina kısmi seferberlik ilan etti.", "Athens announced a partial mobilisation.")),
        k.opt(("Sıcak hat, AB zirvesi", "Hotline, EU summit"), ("Soğukkanlılık", "Composure"), [["rel", GR, TR, 10], ["xstab", GR, -1], ["flag", "c27_masa"]],
              ("Atina sıcak hattı kullandı ve AB zirvesi çağırdı.", "Athens used the hotline and called an EU summit."))),
   CY: k.role(("Güney kıyılar tehdit altında. Lefkoşa'nın bir hamlesi ya Ankara'yı kışkırtır ya da kendi limanlarını korur.", "The southern coast feels threatened. A move by Nicosia could either provoke Ankara or protect its own ports."),
        k.opt(("Ulusal Muhafız alarmda", "National Guard on alert"), ("Savunma duruşu", "Defensive posture"), [["troops", CY, 20], ["buff", CY, "def", 1.15, 10], ["rel", CY, TR, -8]],
              ("Rum Yönetimi Ulusal Muhafız'ı alarma geçirdi.", "The Greek-Cypriot administration placed the National Guard on alert.")),
        k.opt(("BM'den müdahale iste", "Call for UN intervention"), ("Uluslararası kamuoyu", "International opinion"), [["rel", CY, US, 8], ["rel", CY, FR, 6], ["flag", "c27_masa"]],
              ("Lefkoşa BM Güvenlik Konseyi'ni acil toplantıya çağırdı.", "Nicosia asked for an emergency UN Security Council meeting."))),
   US: k.role(("Washington iki NATO müttefikinin gerilimi için telefon trafiği yürütüyor. Hangi ucundan tutacak?", "Washington runs phone diplomacy over a spat between two NATO allies. Which end to take?"),
        k.opt(("Sessiz arabuluculuk", "Quiet mediation"), ("Hat üzerinden", "By phone"), [["rel", US, TR, 4], ["rel", US, GR, 4], ["xstab", US, 1]],
              ("Washington iki başkentle de telefon diplomasisi yürüttü.", "Washington held phone diplomacy with both capitals.")),
        k.opt(("Yunanistan'ı destekle", "Back Greece"), ("Net saf", "A clear side"), [["rel", US, GR, 10], ["rel", US, TR, -10]],
              ("Washington Atina'nın yanında durdu.", "Washington stood with Athens.")))},
  [["rel", TR, GR, -8], ["stab", GR, -1], ["stab", TR, -1], ["flag", "c27_gerilim"]], turn=41, icon="naval", scene="pre_naval"))

# 7a — Aralık: BM zirvesi (savaş yoksa)
M.append(k.moment("c27_zirve", "Yıl Sonu Zirvesi: Güven Paketi",
  ("Aralık 2027: BM Genel Sekreteri adadaki iki lideri ve garantör ülkeleri bir araya getirdi. Masada ortak gaz fonu, kapı açılışları, Maraş'ın statüsü ve güvenlik düzenlemeleri var.",
   "December 2027: the UN Secretary-General gathered the island's two leaders and the guarantor states. On the table: a joint gas fund, crossing openings, Varosha's status and security arrangements."),
  {TR: k.role(("Zirvede 'güven paketi' sunuluyor: ortak gaz fonu, birkaç yeni kapı ve Maraş'ta ortak yönetim. Bunun karşılığında Ankara'dan kıyılardaki gösterilere ara vermesi bekleniyor.", "A 'confidence package' is on the table: joint gas fund, new crossings and joint management of Varosha — in exchange Ankara is asked to pause shows of force."),
        k.opt(("Paketi kabul et", "Accept the package"), ("İşbirliği dönemi", "An era of cooperation"), [["rel", TR, GR, 15], ["rel", TR, CY, 15], ["rel", TR, FR, 8], ["xstab", TR, 3], ["gold", TR, 3]],
              ("Ankara güven paketini kabul etti; Doğu Akdeniz'de yumuşama dönemi başladı.", "Ankara accepted the confidence package; a thaw began in the Eastern Mediterranean.")),
        k.opt(("Ret: egemen eşitlik şart", "Reject: sovereign equality required"), ("Sert duruş", "A hard line"), [["rel", TR, GR, -8], ["rel", TR, CY, -8], ["xstab", TR, 1]],
              ("Ankara egemen eşitlik şartıyla paketi reddetti.", "Ankara rejected the package, demanding sovereign equality."))),
   GR: k.role(("Atina'nın zirvedeki tutumu seçim sonrası yeni hükûmetin ilk sınavı.", "Athens's stance at the summit is the new government's first test."),
        k.opt(("Paketi destekle", "Back the package"), ("Uzlaşma", "Compromise"), [["rel", GR, TR, 12], ["xstab", GR, 2]], ("Atina pakete 'evet' dedi.", "Athens said 'yes' to the package.")),
        k.opt(("Şartları sertleştir", "Toughen the terms"), ("Kıbrıs'ın güvenliği", "Cyprus's security"), [["rel", GR, TR, -6], ["xstab", GR, 1]], ("Atina yeni şartlar öne sürdü.", "Athens put forward new conditions."))),
   CY: k.role(("Lefkoşa'nın pakete yanıtı iç siyasette büyük çalkantı yaratabilir; 2028 başkanlık seçimi yaklaşıyor.", "Nicosia's reply to the package could stir domestic politics; the 2028 presidential election approaches."),
        k.opt(("Kabul et", "Accept"), ("Ortak gelecek", "A shared future"), [["rel", CY, TR, 15], ["rel", CY, NC, 15], ["stab", CY, 3]], ("Rum Yönetimi paketi kabul etti.", "The Greek-Cypriot administration accepted the package.")),
        k.opt(("Reddet", "Reject"), ("Güvenlik öncelikli", "Security first"), [["rel", CY, TR, -8], ["stab", CY, 1]], ("Lefkoşa paketi reddetti.", "Nicosia rejected the package."))),
   NC: k.role(("Pakette kuzey için ortak yönetim ve yatırım var; ama bağımsız egemenlik talebi gündemden düşüyor.", "The package offers the north joint governance and investment, but the claim to separate sovereignty falls off the agenda."),
        k.opt(("Kabul et", "Accept"), ("Ekonomi ve temas", "Economy and contact"), [["stab", NC, 5], ["rel", NC, CY, 15], ["rel", NC, TR, -4]], ("Kuzey yönetimi pakete olumlu yanıt verdi.", "The northern administration responded positively.")),
        k.opt(("Reddet", "Reject"), ("Ankara çizgisi", "Ankara's line"), [["rel", NC, TR, 8], ["rel", NC, CY, -8]], ("Kuzey yönetimi pakete mesafeli durdu.", "The northern administration stayed distant from the package.")))},
  [["rel", TR, GR, 3], ["stab", CY, 1]], turn=50, icon="handshake", scene="pre_trade", forbid=["c27_clash"]))

# 7b — Aralık: ateşkes çağrısı (savaş çıktıysa)
M.append(k.moment("c27_ateskes", "Güvenlik Konseyi: Ateşkes Çağrısı",
  ("Aralık 2027: Kıbrıs'ta çatışma haftalardır sürüyor. BM Güvenlik Konseyi acil ateşkes ve çekilme çağrısı yaptı; NATO, AB ve ABD arabuluculuk telefonlarını sürdürüyor.",
   "December 2027: fighting on Cyprus has gone on for weeks. The UN Security Council called for an immediate ceasefire and withdrawal; NATO, the EU and the US keep up mediation calls."),
  {TR: k.role(("Savaş boyunca elde edilen mevziler ateşkes çizgisini belirleyecek. Kabul mü, devam mı?", "Positions won during the war will set the ceasefire line. Accept, or continue?"),
        k.opt(("Ateşkesi kabul et", "Accept the ceasefire"), ("Mevzileri koru", "Hold the lines"), [["peace", TR, CY], ["xstab", TR, 3], ["rel", TR, US, 8]], ("Ankara Güvenlik Konseyi'nin ateşkes çağrısını kabul etti.", "Ankara accepted the Security Council's ceasefire call.")),
        k.opt(("Harekâta devam", "Continue the operation"), ("Daha çok mevzi", "More ground"), [["buff", TR, "att", 1.15, 8], ["rel", TR, US, -10], ["rel", TR, FR, -10], ["xstab", TR, -2]], ("Ankara ateşkes çağrısını reddetti.", "Ankara rejected the ceasefire call."))),
   CY: k.role(("Rum Yönetimi yıpranmış durumda; ateşkes savunma çizgisini kurtarabilir ama toprak kaybını tescil edebilir.", "The Greek-Cypriot administration is worn down; a ceasefire could save the defence line but may entrench lost ground."),
        k.opt(("Ateşkesi kabul et", "Accept the ceasefire"), ("Nefes al", "Catch your breath"), [["peace", CY, TR], ["stab", CY, 2]], ("Lefkoşa ateşkesi kabul etti.", "Nicosia accepted the ceasefire.")),
        k.opt(("Direnişi sürdür", "Keep fighting"), ("Yardımı bekle", "Wait for help"), [["buff", CY, "def", 1.15, 8], ["stab", CY, -3]], ("Lefkoşa ateşkesi reddetti; Atina ve Paris'ten destek bekliyor.", "Nicosia rejected the ceasefire, waiting for support from Athens and Paris.")))},
  [["peace", TR, CY], ["stab", CY, -4]], turn=52, icon="handshake", scene="pre_trade", requires=["c27_clash"]))

keep_defaults(M, main_roles=(TR,))

EV = [
 (3, "Kıbrıs Rum Meclisi savunma bütçesini artırdı; İsrail yapımı hava savunma bataryaları için ihale açıldı.", "The Cypriot House raised the defence budget; a tender opened for Israeli-made air-defence batteries.", [["stab", CY, 1]]),
 (11, "Mısır ve Yunanistan Doğu Akdeniz'de ortak deniz tatbikatı yaptı; enerji güvenliği ortak başlık oldu.", "Egypt and Greece held a joint naval exercise in the Eastern Mediterranean; energy security was a shared theme.", [["stab", EG, 1]]),
 (19, "Fransa ile Kıbrıs Rum Yönetimi savunma iş birliği çerçeve anlaşmasını genişletti.", "France and the Greek-Cypriot administration expanded their defence cooperation framework agreement.", []),
 (28, "Türkiye Girne limanı ve Ercan Havalimanı'nda kapasite artırımını duyurdu.", "Turkey announced capacity expansion at Kyrenia port and Ercan Airport.", [["stab", NC, 2]]),
 (37, "AB zirvesinde Doğu Akdeniz'e yönelik yaptırım tartışması: üye devletler bölündü.", "At the EU summit a sanctions debate on the Eastern Mediterranean split the member states.", [["stab", GR, -1], ["stab", TR, -1]]),
 (46, "Doğu Akdeniz'de LNG fiyatları rekor kırdı; ruhsat sahalarının stratejik değeri arttı.", "LNG prices in the Eastern Mediterranean hit a record; the strategic value of the licence blocks rose.", [["stab", CY, 1], ["stab", IL, 1]]),
]

OBJ = {
 "*": [{"id": "x1", "type": "survive", "turns": 104, "text": "İki yıl boyunca ayakta kal"},
       {"id": "x2", "type": "stability", "n": 55, "text": "İstikrarı 55 üzerinde tut", "required": False},
       {"id": "x3", "type": "alliances", "n": 3, "text": "3 müttefik edin", "required": False}],
 TR: [{"id": "xt1", "type": "no_war", "turns": 52, "text": "Doğu Akdeniz'de 52 hafta savaşa girmeden güvenliği koru"},
      {"id": "xt2", "type": "alliances", "n": 3, "text": "3 müttefik edin", "required": False}],
 GR: [{"id": "xg1", "type": "no_war", "turns": 52, "text": "52 hafta savaşa girmeden Kıbrıs'ın güvenliğini sağla"},
      {"id": "xg2", "type": "stability", "n": 60, "text": "Seçim yılında istikrarı 60 üzerinde tut", "required": False}],
 CY: [{"id": "xc1", "type": "own_capital", "country": CY, "text": "Lefkoşa'yı elinde tut"},
      {"id": "xc2", "type": "stability", "n": 55, "text": "İstikrarı 55 üzerinde tut", "required": False}],
 NC: [{"id": "xn1", "type": "own_capital", "country": NC, "text": "Gazimağusa'yı elinde tut"},
      {"id": "xn2", "type": "stability", "n": 50, "text": "İstikrarı 50 üzerinde tut", "required": False}],
 IL: [{"id": "xi1", "type": "alliances", "n": 3, "text": "3 müttefik edin"}],
 FR: [{"id": "xf1", "type": "alliances", "n": 4, "text": "4 müttefik edin"}],
}
OBJ_EN = {"x1": "Survive two years", "x2": "Keep stability above 55", "x3": "Make 3 allies",
          "xt1": "Keep the Eastern Mediterranean secure for 52 weeks without going to war", "xt2": "Make 3 allies",
          "xg1": "Secure Cyprus for 52 weeks without going to war", "xg2": "Keep stability above 60 in an election year",
          "xc1": "Hold Nicosia", "xc2": "Keep stability above 55", "xn1": "Hold Famagusta", "xn2": "Keep stability above 50",
          "xi1": "Make 3 allies", "xf1": "Make 4 allies"}

sc = {
 "id": "cyprus27", "kind": "fiction",
 "name": "Ayşe Tatile Tekrar Çıkıyor", "sub": "2027 – Doğu Akdeniz'de Yaz",
 "blurb": "Kurgusal bir geleceğe dair senaryo: 2027'de Doğu Akdeniz'de gaz sahaları, deniz kablosu ve ada üzerindeki BM müzakereleri aynı anda kaynıyor. Yunanistan seçime gidiyor; Fransa, İsrail, Mısır ve ABD sahada. Ayşe yeniden tatile çıkar mı, yoksa masa mı kurulur?",
 "intro": "2027: Doğu Akdeniz'de sondaj gemileri, enerji kabloları ve adadaki BM müzakereleri aynı anda gündemde. Her hamle bir sonrakini belirliyor.",
 "suggest": [TR, GR, CY, NC, FR, IL, EG, US],
 "blocs": [
   {"name": "Yunanistan–Kıbrıs Savunma Ortaklığı", "members": [GR, CY, FR],
    "emblem": {"shape": 5, "inner": 1, "symbol": "shield", "c1": "2f66b0", "c2": "ece6d6", "c3": "2f66b0"}},
   {"name": "Türkiye–KKTC Güvenlik Ortaklığı", "members": [TR, NC],
    "emblem": {"shape": 2, "inner": 1, "symbol": "star", "c1": "c8444a", "c2": "ece6d6", "c3": "c8444a"}}],
 "cold": [[TR, CY], [TR, GR]],
 "stability": {CY: -4, GR: -5, NC: -3},
 "events": [{"turn": t, "t": tr, "fx": fx} for t, tr, _, fx in EV],
 "moments": M,
 "objectives": OBJ,
 "deadline": 210,
 "moments_en": k.en,
 "en": {
  "name": "Ayşe Goes on Holiday Again", "sub": "2027 – Summer in the Eastern Mediterranean",
  "blurb": "A scenario set in an imagined future: in 2027, gas blocks, an undersea power cable and UN talks on Cyprus all come to the boil at once. Greece heads to an election; France, Israel, Egypt and the US are on the scene. Will Ayşe go on holiday again — or will a table be set?",
  "intro": "2027: drillships, energy cables and the UN talks on the island are on the agenda at the same time. Every move shapes the next.",
  "objectives": OBJ_EN,
  "events": {str(i): e for i, (_, _, e, _) in enumerate(EV)},
 },
}
for key in ("blocs",):
    pass

with open(os.path.join(ROOT, "data/scenarios/cyprus27.json"), "w", encoding="utf-8") as f:
    json.dump(sc, f, ensure_ascii=False, indent=1)
    f.write("\n")
ip = os.path.join(ROOT, "data/scenarios/index.json")
idx = json.load(open(ip, encoding="utf-8"))
if "cyprus27" not in idx:
    idx.append("cyprus27")
    open(ip, "w", encoding="utf-8").write(json.dumps(idx, ensure_ascii=False))
print("cyprus27 yazıldı:", len(M), "an,", len(EV), "olay,", len(k.en), "çeviri")

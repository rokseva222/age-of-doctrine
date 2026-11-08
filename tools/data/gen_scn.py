import json
US="United States of America"; UK="United Kingdom"; RU="Russia"
def emb(shape,inner,sym,c1,c2,c3): return {"shape":shape,"inner":inner,"symbol":sym,"c1":c1,"c2":c2,"c3":c3}
S = []
def add(d, en_obj, en_ev, en):
    en = dict(en); en["objectives"]=en_obj; en["events"]={str(i):t for i,t in enumerate(en_ev)}
    d["en"]=en; S.append(d)

# ---------------------------------------------------------------- nile
add({"id":"nile","kind":"real","name":"Nil'in Suları","sub":"Mısır – Etiyopya – Sudan",
 "blurb":"Etiyopya'nın Büyük Rönesans Barajı Nil'in akışını değiştiriyor. Mısır için su, bir hayat meselesi. Diplomasi çökerse Nil kıyıları cepheye dönebilir.",
 "intro":"Nil Krizi: baraj gölü dolarken Kahire son uyarısını yaptı. Hartum iki arada, bölge gergin.",
 "suggest":["Egypt","Ethiopia","Sudan","Eritrea"],
 "blocs":[{"name":"Nil Havzası Girişimi","members":["Egypt","Sudan","S. Sudan"],"emblem":emb(2,1,"wheat","2f7a5a","ece6d6","e3a92b")}],
 "cold":[["Egypt","Ethiopia"]],"embargo":[["Egypt","Ethiopia"]],
 "troops_mult":{"Egypt":1.2,"Ethiopia":1.1},"stability":{"Sudan":-20,"Ethiopia":-8},"cyber":{"Egypt":15,"Ethiopia":8},
 "events":[{"turn":10,"t":"Baraj gölünün dolum aşaması başladı; Mısır Nil akışındaki düşüşten şikâyetçi.","fx":[["stab","Egypt",-4]]},
  {"turn":26,"t":"Mısır sınırda tatbikat başlattı; Etiyopya hava savunmasını güçlendiriyor.","fx":[["stab","Ethiopia",-3]]},
  {"turn":52,"t":"Arabulucular Nil için müzakere masası kurdu.","fx":[["stab","Egypt",3],["stab","Sudan",3]]}],
 "objectives":{"*":[{"id":"n1","type":"survive","turns":104,"text":"İki yıl ayakta kal"},{"id":"n2","type":"stability","n":55,"text":"İstikrarı 55 üzerine çıkar","required":False}],
  "Egypt":[{"id":"ne1","type":"no_war","turns":52,"text":"Bir yıl savaşsız kal"},{"id":"ne2","type":"alliances","n":3,"text":"3 müttefik edin"}],
  "Ethiopia":[{"id":"nt1","type":"survive","turns":104,"text":"Barajı ve devleti koru: iki yıl ayakta kal"},{"id":"nt2","type":"alliances","n":2,"text":"2 müttefik edin"}]},
 "deadline":208},
 {"n1":"Survive two years","n2":"Raise stability above 55","ne1":"Stay out of war for a year","ne2":"Make 3 allies","nt1":"Protect the dam and the state: survive two years","nt2":"Make 2 allies"},
 ["The reservoir filling phase has begun; Egypt complains of a drop in Nile flow.","Egypt launched border exercises; Ethiopia is reinforcing its air defenses.","Mediators have set up a negotiating table for the Nile."],
 {"name":"Waters of the Nile","sub":"Egypt – Ethiopia – Sudan","blurb":"Ethiopia's Grand Renaissance Dam is changing the Nile's flow. For Egypt, water is a matter of life. If diplomacy collapses, the banks of the Nile could become a front line.","intro":"Nile Crisis: as the reservoir fills, Cairo issues its final warning. Khartoum is caught in between."})

# ---------------------------------------------------------------- scs
add({"id":"scs","kind":"real","name":"Güney Çin Denizi","sub":"Çin – Filipinler – Vietnam",
 "blurb":"Resif ve adacıklar üzerindeki hak iddiaları, dünya ticaretinin üçte birinin geçtiği suları kaynatıyor. Bir küçük çatışma bölgeyi ateşe verebilir.",
 "intro":"Güney Çin Denizi: sahil güvenlik gemileri su topu ve lazerlerle karşı karşıya. ABD donanması bölgeye yöneldi.",
 "suggest":["Philippines","China","Vietnam","Malaysia","Taiwan"],
 "blocs":[{"name":"Hint-Pasifik Güvenlik Ortaklığı","members":[US,"Philippines","Japan","Australia","South Korea"],"emblem":emb(1,1,"anchor","2f4f9a","ece6d6","2f4f9a")}],
 "cold":[["China","Philippines"],["China","Vietnam"],["China","Malaysia"]],"embargo":[],
 "cyber":{"China":30,"Vietnam":10,"Philippines":8},"doctrine":{"China":3},"troops_mult":{"Philippines":1.2},
 "events":[{"turn":8,"t":"Çin sahil güvenliği ile Filipin gemileri bir resif yakınında çarpıştı.","fx":[["stab","Philippines",-3]]},
  {"turn":24,"t":"Vietnam ve Filipinler ortak devriye anlaşması imzaladı.","fx":[["ally","Vietnam","Philippines"]]},
  {"turn":40,"t":"Tayvan Boğazı'nda büyük çaplı Çin tatbikatı.","fx":[["stab","Taiwan",-5]]}],
 "objectives":{"*":[{"id":"s1","type":"survive","turns":104,"text":"İki yıl ayakta kal"},{"id":"s2","type":"alliances","n":3,"text":"3 müttefik edin"}],
  "China":[{"id":"sc1","type":"own_provinces","n":45,"text":"45 eyalete ulaş"}],
  "Philippines":[{"id":"sp1","type":"no_war","turns":78,"text":"1,5 yıl savaşsız kal"}]},
 "deadline":208},
 {"s1":"Survive two years","s2":"Make 3 allies","sc1":"Reach 45 provinces","sp1":"Stay out of war for 1.5 years"},
 ["A Chinese coast guard vessel and a Philippine ship collided near a reef.","Vietnam and the Philippines signed a joint patrol agreement.","Large-scale Chinese exercise in the Taiwan Strait."],
 {"name":"South China Sea","sub":"China – Philippines – Vietnam","blurb":"Claims over reefs and islets are boiling waters that carry a third of world trade. One small clash could set the region ablaze.","intro":"South China Sea: coast guard ships face off with water cannons and lasers. The US Navy is heading to the region."})

# ---------------------------------------------------------------- arctic
add({"id":"arctic","kind":"real","name":"Arktik Yarışı","sub":"Rusya – NATO – Kanada",
 "blurb":"Buzullar çekildikçe yeni deniz yolları ve milyarlarca dolarlık enerji rezervi açığa çıkıyor. Kutup, büyük güçlerin yeni satranç tahtası.",
 "intro":"Arktik: erime hızlandı. Kuzey Deniz Yolu açıldı, kutup üsleri yeniden doluyor.",
 "suggest":[RU,"Canada","Norway",US,"Denmark"],
 "blocs":[{"name":"Kutup Savunma Hattı","members":[US,"Canada","Norway","Denmark","Iceland","Finland","Sweden"],"emblem":emb(0,2,"shield","2f4f9a","ece6d6","2f4f9a")}],
 "cold":[[RU,"Norway"],[RU,"Canada"],[RU,"Denmark"]],"embargo":[[US,RU]],"cyber":{RU:25},
 "troops_mult":{RU:1.1,"Norway":1.2,"Finland":1.2},
 "events":[{"turn":12,"t":"Rusya, Kuzey Deniz Yolu'nda yeni nükleer buzkıranlar hizmete soktu.","fx":[["stab",RU,2]]},
  {"turn":30,"t":"Norveç açıklarında denizaltı kablosu kesildi; şüpheler Moskova'ya çevrildi.","fx":[["stab","Norway",-3]]},
  {"turn":60,"t":"Arktik Konseyi'nde sınır belirleme toplantısı çıkmaza girdi.","fx":[]}],
 "objectives":{"*":[{"id":"a1","type":"survive","turns":104,"text":"İki yıl ayakta kal"},{"id":"a2","type":"gdp_share","pct":6,"text":"Dünya GSYH payını %6'ya çıkar","required":False}],
  "Russia":[{"id":"ar1","type":"alliances","n":3,"text":"3 müttefik edin"}],
  "Canada":[{"id":"ac1","type":"no_war","turns":104,"text":"Savaşsız iki yıl"}]},
 "deadline":208},
 {"a1":"Survive two years","a2":"Raise world GDP share to 6%","ar1":"Make 3 allies","ac1":"Two years without war"},
 ["Russia commissioned new nuclear icebreakers on the Northern Sea Route.","A subsea cable off Norway was cut; suspicion falls on Moscow.","The Arctic Council's border-delimitation meeting hit a deadlock."],
 {"name":"Arctic Race","sub":"Russia – NATO – Canada","blurb":"As the ice recedes, new sea lanes and billions of dollars in energy reserves are emerging. The pole is the great powers' new chessboard.","intro":"Arctic: the melt has accelerated. The Northern Sea Route is open and polar bases are filling up again."})

# ---------------------------------------------------------------- essequibo
add({"id":"essequibo","kind":"real","name":"Esequibo Anlaşmazlığı","sub":"Venezuela – Guyana",
 "blurb":"Petrol zengini Guyana'nın batısındaki Esequibo bölgesi üzerinde Venezuela hak iddia ediyor. Küçük bir ülke, büyük komşu, uzak ama ilgili müttefikler.",
 "intro":"Esequibo: Karakas haritaları yeniden çizdi, birlikleri sınıra yığdı. Georgetown BM'ye başvurdu.",
 "suggest":["Guyana","Venezuela","Brazil",US],
 "transfer":[[1764,"Guyana","Venezuela","occ"]],
 "cold":[["Venezuela","Guyana"]],"embargo":[["Venezuela","Guyana"]],
 "troops_mult":{"Venezuela":1.2,"Guyana":0.9},"stability":{"Venezuela":-10},
 "events":[{"turn":6,"t":"Brezilya sınır boyunca birlik sevk etti ve gerilimin düşürülmesini istedi.","fx":[["stab","Venezuela",-2]]},
  {"turn":20,"t":"ABD Guyana ile ortak tatbikat yaptı.","fx":[["ally",US,"Guyana"]]}],
 "objectives":{"*":[{"id":"e1","type":"survive","turns":78,"text":"1,5 yıl ayakta kal"}],
  "Guyana":[{"id":"eg1","type":"own_province","province":1764,"text":"Potaro-Siparuni eyaletini geri al"},{"id":"eg2","type":"alliances","n":2,"text":"2 müttefik edin"}],
  "Venezuela":[{"id":"ev1","type":"own_provinces","n":22,"text":"22 eyalete ulaş"}]},
 "deadline":208},
 {"e1":"Survive 1.5 years","eg1":"Retake Potaro-Siparuni","eg2":"Make 2 allies","ev1":"Reach 22 provinces"},
 ["Brazil moved troops along the border and urged de-escalation.","The US held a joint exercise with Guyana."],
 {"name":"Essequibo Dispute","sub":"Venezuela – Guyana","blurb":"Venezuela claims the Essequibo region west of oil-rich Guyana. A small country, a large neighbour, distant but interested allies.","intro":"Essequibo: Caracas has redrawn its maps and massed troops on the border. Georgetown appealed to the UN."})

# ---------------------------------------------------------------- redsea
add({"id":"redsea","kind":"real","name":"Kızıldeniz Krizi","sub":"Yemen – Körfez – Süveyş",
 "blurb":"Ticaret gemilerine yönelik saldırılar Süveyş hattını tıkıyor. Deniz ticaretinin can damarı, bölgesel vekâlet savaşlarının cephesi.",
 "intro":"Kızıldeniz: tankerler Ümit Burnu'na yöneliyor, sigorta primleri uçtu. Bölge ülkeleri hamle bekliyor.",
 "suggest":["Egypt","Saudi Arabia","Israel","Iran","Yemen"],
 "blocs":[{"name":"Kızıldeniz Güvenlik Görev Gücü","members":[US,UK,"France","Saudi Arabia","Egypt"],"emblem":emb(1,1,"anchor","2f4f9a","ece6d6","2f4f9a"),}],
 "wars":[["Saudi Arabia","Yemen"]],"cold":[["Iran","Israel"],["Iran","Saudi Arabia"]],"embargo":[["Iran",US]],
 "cyber":{"Iran":20,"Israel":25},"treasury_mult":{"Egypt":0.7},"stability":{"Yemen":-25,"Egypt":-5},
 "events":[{"turn":10,"t":"Süveyş Kanalı gelirleri ciddi biçimde düştü.","fx":[["stab","Egypt",-4]]},
  {"turn":28,"t":"Körfez'de arabuluculuk girişimi: Riyad ve Tahran temaslarını artırdı.","fx":[["stab","Saudi Arabia",2]]}],
 "objectives":{"*":[{"id":"r1","type":"survive","turns":78,"text":"1,5 yıl ayakta kal"},{"id":"r2","type":"stability","n":55,"text":"İstikrarı 55 üzerine çıkar"}],
  "Egypt":[{"id":"re1","type":"alliances","n":3,"text":"3 müttefik edin"},{"id":"re2","type":"hold_choke","choke":"suez","text":"Süveyş Kanalı'nı elinde tut","required":False}],
  "Saudi Arabia":[{"id":"rs1","type":"cease_war","with":"Yemen","text":"Yemen ile barış yap"},{"id":"rs2","type":"hold_choke","choke":"babelmandeb","text":"Babülmendeb'i kontrol et","required":False}]},
 "deadline":208},
 {"r1":"Survive 1.5 years","r2":"Raise stability above 55","re1":"Make 3 allies","re2":"Hold the Suez Canal","rs1":"Make peace with Yemen","rs2":"Control Bab-el-Mandeb"},
 ["Suez Canal revenues have dropped sharply.","A mediation attempt in the Gulf: Riyadh and Tehran increased contacts."],
 {"name":"Red Sea Crisis","sub":"Yemen – Gulf – Suez","blurb":"Attacks on merchant ships are choking the Suez route. The lifeline of sea trade is the front of regional proxy wars.","intro":"Red Sea: tankers are rerouting around the Cape and insurance premiums have soared. Regional powers await a move."})

# ---------------------------------------------------------------- korea
add({"id":"korea","kind":"real","name":"Kore Yarımadası","sub":"Kuzey Kore – Güney Kore",
 "blurb":"Dünyanın en militarize sınırı. Nükleer tehditler, füze denemeleri ve bölgesel güçlerin gölgesi: Seul'ün bir adımı bile tüm bölgeyi etkileyebilir.",
 "intro":"Kore: füze denemesi alarmı verildi, sınırdaki tatbikatlar sürüyor. Çin ve ABD çıkar hesabında.",
 "suggest":["South Korea","North Korea","Japan","China"],
 "blocs":[{"name":"Pasifik Savunma Hattı","members":[US,"South Korea","Japan"],"emblem":emb(0,2,"shield","2f4f9a","ece6d6","2f4f9a")}],
 "cold":[["North Korea","South Korea"],["North Korea","Japan"]],"embargo":[["North Korea",US]],
 "cyber":{"North Korea":35,"South Korea":25},"doctrine":{"North Korea":4},"troops_mult":{"North Korea":1.2},"stability":{"North Korea":-8},
 "events":[{"turn":9,"t":"Kuzey Kore denizde bir balistik füze denemesi yaptı.","fx":[["stab","South Korea",-3],["stab","Japan",-2]]},
  {"turn":36,"t":"Güney Kore, Japonya ve ABD ortak tatbikat yaptı.","fx":[["stab","North Korea",-3]]}],
 "objectives":{"*":[{"id":"k1","type":"survive","turns":104,"text":"İki yıl ayakta kal"}],
  "South Korea":[{"id":"ks1","type":"no_war","turns":104,"text":"İki yıl savaşsız kal"},{"id":"ks2","type":"alliances","n":3,"text":"3 müttefik edin","required":False}],
  "North Korea":[{"id":"kn1","type":"stability","n":50,"text":"İstikrarı 50 üzerinde tut"},{"id":"kn2","type":"alliances","n":2,"text":"2 müttefik edin"}]},
 "deadline":208},
 {"k1":"Survive two years","ks1":"Two years without war","ks2":"Make 3 allies","kn1":"Keep stability above 50","kn2":"Make 2 allies"},
 ["North Korea carried out a ballistic missile test at sea.","South Korea, Japan and the US held a joint exercise."],
 {"name":"Korean Peninsula","sub":"North Korea – South Korea","blurb":"The world's most militarized border. Nuclear threats, missile tests and the shadow of regional powers: even one step by Seoul can affect the whole region.","intro":"Korea: a missile test alert has sounded and drills along the border continue. China and the US are calculating."})

# ---------------------------------------------------------------- kuraklik (fiction)
add({"id":"kuraklik","kind":"fiction","name":"Büyük Kuraklık","sub":"Kurgusal: su krizi",
 "blurb":"Kurgusal bir senaryo: üst üste gelen kuraklıklar nehirleri kurutuyor, tarım çöküyor. Su paylaşım anlaşmaları çatırdıyor; ülkeler barajları, kaynakları ve nehir yataklarını savunuyor.",
 "intro":"Büyük Kuraklık: üç yıldır yağış yok. Nehirler çekiliyor, tahıl fiyatları uçuyor.",
 "suggest":["Turkey","Egypt","India","Iraq","Ethiopia","Pakistan"],
 "cold":[["Egypt","Ethiopia"],["Turkey","Iraq"],["India","Pakistan"],["Iran","Afghanistan"]],
 "embargo":[["Egypt","Ethiopia"]],
 "treasury_mult":{"Egypt":0.7,"Iraq":0.6,"Pakistan":0.7,"India":0.85},"stability":{"Egypt":-10,"Iraq":-15,"Pakistan":-12,"Sudan":-15,"Syria":-15,"Iran":-8},
 "events":[{"turn":6,"t":"Tahıl fiyatları rekor kırdı; birçok ülkede ekmek isyanları başladı.","fx":[["stab","Egypt",-5],["stab","Iraq",-4],["stab","Pakistan",-4]]},
  {"turn":18,"t":"Dicle ve Fırat'ın debisi yarıya indi; Bağdat Ankara'dan su istedi.","fx":[["stab","Iraq",-4]]},
  {"turn":34,"t":"Birleşmiş Milletler, küresel su yönetimi için acil toplantı çağırdı.","fx":[]},
  {"turn":50,"t":"Yağışlar kısmen geri döndü; krizin en kötüsü geride kalmış olabilir.","fx":[["stab","Egypt",3],["stab","Iraq",3],["stab","Pakistan",3]]}],
 "objectives":{"*":[{"id":"d1","type":"survive","turns":104,"text":"İki yıl ayakta kal"},{"id":"d2","type":"stability","n":55,"text":"İstikrarı 55 üzerine çıkar"},{"id":"d3","type":"no_war","turns":52,"text":"Bir yıl savaşsız kal","required":False}]},
 "deadline":208},
 {"d1":"Survive two years","d2":"Raise stability above 55","d3":"Stay out of war for a year"},
 ["Grain prices hit record highs; bread riots began in many countries.","The flow of the Tigris and Euphrates halved; Baghdad asked Ankara for water.","The United Nations called an emergency meeting on global water governance.","Rains partly returned; the worst of the crisis may be behind us."],
 {"name":"The Great Drought","sub":"Fiction: water crisis","blurb":"A fictional scenario: successive droughts dry up the rivers and farming collapses. Water-sharing deals are cracking; countries defend dams, springs and riverbeds.","intro":"The Great Drought: no rain for three years. Rivers are receding and grain prices are soaring."})

# ---------------------------------------------------------------- sahel (fiction factions)
add({"id":"sahel","kind":"fiction","name":"Sahel Ateşi","sub":"Kurgusal: darbeler ve silahlı gruplar",
 "blurb":"Kurgusal bir senaryo: Sahel kuşağında hükümetler çöküyor, kurgusal silahlı gruplar kuzeyden kontrol alıyor. Dış güçler nüfuz için yarışıyor. (Gerçek örgüt adı ve sembolleri kullanılmaz.)",
 "intro":"Sahel Ateşi: Mali ve Nijer'in kuzeyinde Çöl Birliği adlı bir yapı ortaya çıktı; başkentler ayakta kalmaya çalışıyor.",
 "suggest":["Mali","Niger","Algeria","Nigeria","France","Burkina Faso"],
 "factions":[{"name":"Çöl Birliği","leader":"Komutan|Abdelhakim el-Sahri","from":[["Mali",3],["Niger",2]],"dir":"north","troops":30000,"tech":0.2,"doctrine":4,"colors":["8a6a3a","1c1f24","ece6d6"],"pattern":2,"aggression":1.0}],
 "blocs":[{"name":"Sahel Ülkeleri Paktı","members":["Mali","Niger","Burkina Faso"],"emblem":emb(2,1,"shield","d8a05c","1c1f24","ece6d6")}],
 "stability":{"Mali":-20,"Niger":-18,"Burkina Faso":-18,"Chad":-8},"troops_mult":{"Mali":0.8,"Niger":0.8},
 "events":[{"turn":8,"t":"Çöl Birliği sınır kasabalarında kontrolü ele geçirdi; binlerce kişi yerinden oldu.","fx":[]},
  {"turn":24,"t":"Komşu ülkeler ortak güç oluşturmayı görüştü.","fx":[["stab","Nigeria",2]]},
  {"turn":44,"t":"Yabancı güçlerin çekilmesi tartışılıyor; başkentler yeni güvenlik düzeni arıyor.","fx":[["stab","Mali",-3]]}],
 "objectives":{"*":[{"id":"h1","type":"survive","turns":104,"text":"İki yıl ayakta kal"},{"id":"h2","type":"stability","n":50,"text":"İstikrarı 50 üzerine çıkar"}],
  "Mali":[{"id":"hm1","type":"own_provinces","n":10,"text":"10 eyalete ulaş"}]},
 "deadline":208},
 {"h1":"Survive two years","h2":"Raise stability above 50","hm1":"Reach 10 provinces"},
 ["The Desert Union took control of border towns; thousands were displaced.","Neighbouring countries discussed forming a joint force.","The withdrawal of foreign forces is debated; capitals seek a new security order."],
 {"name":"Sahel Fire","sub":"Fiction: coups and armed groups","blurb":"A fictional scenario: governments are collapsing across the Sahel belt and fictional armed groups are taking control in the north. Outside powers race for influence. (No real organization names or symbols are used.)","intro":"Sahel Fire: a body called the Desert Union has emerged in northern Mali and Niger; capitals struggle to survive."})

ids=[]
for d in S:
    json.dump(d,open("data/scenarios/%s.json"%d["id"],"w"),ensure_ascii=False,indent=1)
    ids.append(d["id"])
json.dump(ids,open("data/scenarios/index.json","w"))
print(ids)

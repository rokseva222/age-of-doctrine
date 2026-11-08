import json
R = "Russia"; US = "United States of America"; UK = "United Kingdom"
def mil(p, t, a, y, f, s): return {"personnel": p, "tank": t, "afv": a, "arty": y, "air": f, "sub": s}

absorb = {
 R: ["Ukraine","Belarus","Georgia","Armenia","Azerbaijan","Kazakhstan","Uzbekistan","Turkmenistan","Tajikistan","Kyrgyzstan","Moldova","Estonia","Latvia","Lithuania"],
 "Serbia": ["Croatia","Slovenia","Bosnia and Herz.","North Macedonia","Montenegro","Kosovo"],
 "Czechia": ["Slovakia"],
 UK: ["Kenya","Zimbabwe","Zambia","Malawi","Malta","Bahamas","Belize","Guyana","Fiji","Singapore","Brunei","Botswana","Lesotho","eSwatini","Gambia","Seychelles","Mauritius","Cyprus"],
 "Portugal": ["Angola","Mozambique","Guinea-Bissau","Cabo Verde","Timor-Leste"],
 "France": ["Djibouti","Comoros","Vanuatu"],
 "Netherlands": ["Suriname"],
 "Spain": ["Eq. Guinea","W. Sahara"],
}
east_de = ["Sachsen","Brandenburg","Mecklenburg-Vorpommern","Thüringen","Sachsen-Anhalt"]
split = [[p, "Germany", R, "occ"] for p in east_de] + [[32,"China",UK,"own"],[31,"China",UK,"own"]]

defs = {
 US: {"name":"ABD","color":"7fa65a","leader":"Başkan|John F. Kennedy","gdp":3000,"mil":mil(2800000,10000,12000,15000,15000,150)},
 R: {"name":"SSCB","color":"b53a2e","flag":"R:0,0,1,1,#cc0000|S:.14,.2,.09,#ffd700","leader":"Genel Sekreter|Nikita Hruşçov","gdp":1200,"mil":mil(3600000,30000,25000,30000,10000,380)},
 UK: {"name":"Birleşik Krallık","color":"d98ca0","leader":"Başbakan|Harold Macmillan","gdp":400,"mil":mil(450000,1500,2500,2500,1800,60)},
 "France": {"name":"Fransa","color":"4f74b8","leader":"Cumhurbaşkanı|Charles de Gaulle","gdp":380,"mil":mil(800000,1800,2500,2000,1100,35)},
 "Germany": {"name":"Batı Almanya","color":"5d6068","leader":"Şansölye|Konrad Adenauer","gdp":350,"mil":mil(400000,2000,2500,1500,900,0)},
 "China": {"name":"Çin Halk Cumhuriyeti","color":"d6483a","leader":"Başkan|Mao Zedong","gdp":600,"mil":mil(2500000,1500,500,12000,2500,40)},
 "Cuba": {"name":"Küba","color":"3f9a6e","leader":"Başbakan|Fidel Castro","gdp":15,"mil":mil(250000,300,200,500,150,0)},
 "Turkey": {"name":"Türkiye","color":"c8444a","leader":"Başbakan|Cemal Gürsel","gdp":60,"mil":mil(480000,1500,800,2000,350,12)},
 "Japan": {"name":"Japonya","color":"e2a53a","leader":"Başbakan|Hayato Ikeda","gdp":430,"mil":mil(230000,700,300,500,300,10)},
 "India": {"name":"Hindistan","color":"d8a05c","leader":"Başbakan|Cevaharlal Nehru","gdp":440,"mil":mil(550000,700,300,1500,400,0)},
 "Serbia": {"name":"Yugoslavya","color":"7a8fb0","leader":"Başkan|Josip Broz Tito","gdp":100,"mil":mil(250000,1500,500,2500,600,5)},
 "Czechia": {"name":"Çekoslovakya","color":"8b86b8","leader":"Cumhurbaşkanı|Antonín Novotný","gdp":95,"mil":mil(230000,3000,2500,2000,600,0)},
 "Poland": {"name":"Polonya","color":"b04a4a","leader":"Birinci Sekreter|Władysław Gomułka","gdp":110,"mil":mil(350000,3000,2000,2500,700,5)},
 "Italy": {"name":"İtalya","color":"5f9c6a","leader":"Başbakan|Amintore Fanfani","gdp":330,"mil":mil(380000,1000,1500,1500,400,10)},
 "Egypt": {"name":"Birleşik Arap Cumhuriyeti","color":"c9a24a","leader":"Cumhurbaşkanı|Cemal Abdülnasır","gdp":45,"mil":mil(180000,900,1000,1200,500,8)},
}
setup = {
 "blocs": [
  {"name":"Kuzey Atlantik İttifakı","members":[US,"Canada",UK,"France","Germany","Italy","Belgium","Netherlands","Luxembourg","Denmark","Norway","Iceland","Portugal","Greece","Turkey"],"emblem":{"shape":0,"inner":2,"symbol":"star","c1":"2f4f9a","c2":"ece6d6","c3":"2f4f9a"}},
  {"name":"Varşova Paktı","members":[R,"Poland","Czechia","Hungary","Romania","Bulgaria","Albania"],"emblem":{"shape":4,"inner":1,"symbol":"star","c1":"b53a2e","c2":"e3a92b","c3":"e3a92b"}},
 ],
 "wars": [],
 "truce": [],
 "intro": "Ekim 1962: Küba'daki Sovyet balistik füzeleri keşfedildi. ABD ada çevresinde deniz karantinası ilan etti; dünya nükleer savaşın eşiğinde.",
}
events = [
 {"y":1962,"m":10,"t":"Küba krizi gerginliği artıyor: ABD ve SSCB arasında diplomatik kanallar zorlanıyor.","fx":[["stab",US,-2],["stab",R,-2]]},
 {"y":1962,"m":11,"t":"Sovyet füzeleri Küba'dan çekilmeye başladı; kriz hafifliyor.","fx":[["stab",US,3],["stab",R,2]]},
 {"y":1962,"m":10,"t":"Çin ile Hindistan arasında sınır çatışması başladı.","fx":[["war","China","India"]]},
 {"y":1962,"m":11,"t":"Çin-Hindistan sınır savaşında ateşkes ilan edildi.","fx":[["peace","China","India"]]},
 {"y":1963,"m":8,"t":"ABD, İngiltere ve SSCB atmosferde nükleer denemeleri yasaklayan antlaşmayı imzaladı.","fx":[["stab",US,2],["stab",R,2]]},
 {"y":1965,"m":9,"t":"Hindistan ile Pakistan arasında Keşmir savaşı patlak verdi.","fx":[["war","India","Pakistan"]]},
 {"y":1965,"m":10,"t":"Hindistan-Pakistan savaşı BM'nin devreye girmesiyle sona erdi.","fx":[["peace","India","Pakistan"]]},
 {"y":1967,"m":6,"t":"Altı Gün Savaşı: İsrail, Mısır, Suriye ve Ürdün'e karşı harekete geçti.","fx":[["war","Israel","Egypt"],["war","Israel","Syria"],["war","Israel","Jordan"]]},
 {"y":1967,"m":6,"t":"Altı Gün Savaşı ateşkesle bitti.","fx":[["peace","Israel","Egypt"],["peace","Israel","Syria"],["peace","Israel","Jordan"]]},
 {"y":1968,"m":8,"t":"Varşova Paktı kuvvetleri Çekoslovakya'ya girdi.","fx":[["stab","Czechia",-12]]},
]
leaders = {"horizon":1975,"chain":{
 US: [[1963,11,"Başkan|Lyndon B. Johnson"],[1969,1,"Başkan|Richard Nixon"]],
 R: [[1964,10,"Genel Sekreter|Leonid Brejnev"]],
 UK: [[1963,10,"Başbakan|Alec Douglas-Home"],[1964,10,"Başbakan|Harold Wilson"]],
 "Germany": [[1963,10,"Şansölye|Ludwig Erhard"]],
 "Japan": [[1964,11,"Başbakan|Eisaku Satō"]],
 "India": [[1964,5,"Başbakan|Lal Bahadur Shastri"],[1966,1,"Başbakan|Indira Gandhi"]],
 "Egypt": [[1970,9,"Cumhurbaşkanı|Enver Sedat"]],
 "France": [[1969,6,"Cumhurbaşkanı|Georges Pompidou"]],
}}
objectives = {"*":[
 {"id":"c1","type":"survive","turns":104,"text":"İki yıl boyunca ayakta kal"},
 {"id":"c2","type":"alliances","n":4,"text":"4 müttefik edin"},
 {"id":"c3","type":"stability","n":60,"text":"İstikrarı 60 üzerinde tut","required":False},
]}

# ---- silah tablosu
def it(name,cat,org,tier,price,sale=True): return [name,cat,org,tier,price,sale]
items = {
 # piyade
 "i_m1":it("M1 Garand","inf",US,1,1.0),"i_m14":it("M14 + M60 MG","inf",US,2,1.7),"i_m16":it("M16 (erken seri)","inf",US,3,2.4),
 "i_sks":it("SKS + DPM","inf",R,1,0.8),"i_ak47":it("AK-47 + RPD","inf",R,2,1.3),"i_akm":it("AKM + RPK","inf",R,3,1.8),
 "i_slr":it("L1A1 SLR + Bren","inf",UK,2,1.5),"i_mas49":it("MAS 49/56","inf","France",1,1.0),"i_fn":it("FN FAL + MAG","inf","Belgium",2,1.7),
 "i_g3":it("G3 + MG3","inf","Germany",3,2.0),"i_type56":it("Tip 56 + Tip 53","inf","China",2,0.8),
 # tank
 "t_m47":it("M47 Patton","tank",US,1,0.6),"t_m48":it("M48 Patton","tank",US,2,0.8),"t_m60":it("M60 Patton","tank",US,3,1.1),
 "t_t34":it("T-34/85","tank",R,1,0.5),"t_t54":it("T-54","tank",R,2,0.7),"t_t55":it("T-55","tank",R,3,0.8),"t_t62":it("T-62","tank",R,4,1.1),
 "t_cent":it("Centurion","tank",UK,2,0.9),"t_cheft":it("Chieftain","tank",UK,4,1.5),
 "t_amx13":it("AMX-13","tank","France",1,0.6),"t_amx30":it("AMX-30","tank","France",3,1.1),
 "t_type59":it("Tip 59","tank","China",2,0.5),"t_leo":it("Leopard 1","tank","Germany",4,1.2),
 # afv
 "a_m59":it("M59 TZA","afv",US,1,0.3),"a_m113":it("M113 TZA","afv",US,3,0.5),
 "a_btr152":it("BTR-152","afv",R,1,0.25),"a_btr60":it("BTR-60","afv",R,3,0.4),"a_bmp1":it("BMP-1","afv",R,4,0.7),
 "a_sar":it("Saracen","afv",UK,1,0.3),"a_fv432":it("FV432","afv",UK,3,0.5),
 "a_panhard":it("Panhard AML","afv","France",2,0.3),"a_vci":it("AMX-VCI","afv","France",3,0.5),"a_type63":it("Tip 63 TZA","afv","China",2,0.2),
 # arty
 "y_m101":it("M101 105 mm","arty",US,1,0.4),"y_m114":it("M114 155 mm","arty",US,2,0.6),"y_m110":it("M110 203 mm","arty",US,3,1.0),
 "y_m46":it("M-46 130 mm","arty",R,1,0.5),"y_d30":it("D-30 122 mm","arty",R,2,0.5),"y_bm21":it("BM-21 Grad","arty",R,3,0.8),
 "y_bl55":it("BL 5,5 inç","arty",UK,2,0.5),"y_mle50":it("155 mm Mle 50","arty","France",2,0.5),"y_f3":it("AMX Mk F3","arty","France",3,0.8),"y_type54":it("Tip 54 122 mm","arty","China",2,0.4),
 # air
 "f_f86":it("F-86 Sabre","air",US,1,0.5),"f_f100":it("F-100 Super Sabre","air",US,2,1.0),"f_f4":it("F-4 Phantom II","air",US,3,2.6),
 "f_mig15":it("MiG-15","air",R,1,0.4),"f_mig17":it("MiG-17 / Il-28","air",R,2,0.7),"f_mig21":it("MiG-21F","air",R,3,1.1),"f_su7":it("Su-7 / Tu-16","air",R,4,1.8),
 "f_hunter":it("Hawker Hunter","air",UK,2,0.8),"f_lightning":it("English Electric Lightning","air",UK,3,1.8),
 "f_mystere":it("Mystère IV","air","France",1,0.6),"f_mirage":it("Mirage III","air","France",3,1.6),"f_j5":it("J-5 / J-6","air","China",1,0.35),
 # sub
 "s_guppy":it("Guppy sınıfı","sub",US,1,12.0),"s_skipjack":it("Skipjack (nükleer)","sub",US,3,60.0),"s_gwash":it("George Washington (SSBN)","sub",US,4,110.0),
 "s_whisky":it("Whiskey sınıfı","sub",R,1,8.0),"s_foxtrot":it("Foxtrot (Proje 641)","sub",R,2,12.0),"s_hotel":it("Hotel (SSBN)","sub",R,3,55.0),
 "s_porpoise":it("Porpoise sınıfı","sub",UK,2,14.0),"s_valiant":it("Valiant (nükleer)","sub",UK,4,55.0),
 "s_narval":it("Narval sınıfı","sub","France",2,13.0),"s_romeo":it("Romeo sınıfı","sub","China",2,9.0),
}
def b(inf,tank,afv,arty,air,sub): return {"inf":inf,"tank":tank,"afv":afv,"arty":arty,"air":air,"sub":sub}
bloc = {
 "us": b(["i_m1","i_m1","i_m14","i_m16"],["t_m47","t_m48","t_m48","t_m60"],["a_m59","a_m59","a_m113","a_m113"],["y_m101","y_m114","y_m110","y_m110"],["f_f86","f_f100","f_f4","f_f4"],["s_guppy","s_guppy","s_skipjack","s_gwash"]),
 "su": b(["i_sks","i_ak47","i_akm","i_akm"],["t_t34","t_t54","t_t55","t_t62"],["a_btr152","a_btr152","a_btr60","a_bmp1"],["y_m46","y_d30","y_bm21","y_bm21"],["f_mig15","f_mig17","f_mig21","f_su7"],["s_whisky","s_foxtrot","s_hotel","s_hotel"]),
 "uk": b(["i_slr","i_slr","i_slr","i_slr"],["t_cent","t_cent","t_cent","t_cheft"],["a_sar","a_sar","a_fv432","a_fv432"],["y_bl55","y_bl55","y_bl55","y_bl55"],["f_hunter","f_hunter","f_lightning","f_lightning"],["s_porpoise","s_porpoise","s_porpoise","s_valiant"]),
 "fr": b(["i_mas49","i_mas49","i_fn","i_fn"],["t_amx13","t_amx13","t_amx30","t_amx30"],["a_panhard","a_panhard","a_vci","a_vci"],["y_mle50","y_mle50","y_f3","y_f3"],["f_mystere","f_mystere","f_mirage","f_mirage"],["s_narval","s_narval","s_narval","s_narval"]),
 "cn": b(["i_type56","i_type56","i_type56","i_type56"],["t_type59","t_type59","t_type59","t_type59"],["a_type63","a_type63","a_type63","a_type63"],["y_type54","y_type54","y_type54","y_type54"],["f_j5","f_j5","f_j5","f_j5"],["s_romeo","s_romeo","s_romeo","s_romeo"]),
 "ot": b(["i_fn","i_fn","i_m14","i_g3"],["t_m47","t_m48","t_cent","t_leo"],["a_m59","a_panhard","a_fv432","a_m113"],["y_m101","y_bl55","y_m114","y_m114"],["f_f86","f_hunter","f_f100","f_mirage"],["s_guppy","s_porpoise","s_narval","s_narval"]),
}
bloc_of = {US:"us",R:"su",UK:"uk","France":"fr","China":"cn","Germany":"ot"}
for c in ["Canada","Turkey","Greece","Italy","Japan","South Korea","Taiwan","Philippines","Thailand","Brazil","Mexico","Norway","Denmark","Netherlands","Belgium","Spain","Portugal","Iran","Israel","Saudi Arabia","Argentina","Colombia","Venezuela","Chile","Pakistan","Australia"]: bloc_of[c]="us"
for c in ["Australia","New Zealand","South Africa","India","Ireland","Egypt"]: bloc_of[c]= "uk" if c!="Egypt" else "su"
for c in ["Poland","Czechia","Hungary","Romania","Bulgaria","Albania","Cuba","Syria","Iraq","Mongolia","Indonesia","Serbia","Libya","Algeria","Ethiopia","Yemen"]: bloc_of[c]="su"
for c in ["North Korea","Vietnam","Laos","Cambodia"]: bloc_of[c]="cn"
tech = {US:0.95,R:0.8,UK:0.75,"France":0.65,"Germany":0.6,"China":0.3,"Japan":0.5,"Israel":0.55,"Canada":0.55,"Italy":0.45}
gate = {"i_m16":150,"i_akm":60,"t_m60":60,"t_t62":50,"t_cheft":130,"t_amx30":70,"t_leo":150,"a_bmp1":200,"a_m113":10,"y_m110":120,"y_bm21":20,
        "f_f4":40,"f_su7":120,"f_mig21":10,"f_lightning":20,"f_mirage":20,"s_skipjack":10,"s_gwash":40,"s_hotel":30,"s_valiant":180}

era = {
 "id":"cw62","name":"Soğuk Savaş","sub":"Ekim 1962 – Küba Krizi","family":"cold","icon":"helmet","mood":"war",
 "start_year":1962,"start_doy":290,
 "blurb":"Küba'daki Sovyet füzeleri dünyayı nükleer savaşın kıyısına getirdi. İki süper güç, NATO ve Varşova Paktı, sömürge sonrası yeni devletler: bir hamle yanlış giderse hepsi yanar.",
 "suggest":[US,R,"Cuba","Turkey","Serbia"],
 "look":{"shadow":[0.06,0.07,0.09],"mid":[0.42,0.45,0.42],"light":[0.93,0.90,0.83],"amount":0.28,"vignette":0.14,"grain":0.010},
 "arsenal":{"items":items,"bloc":bloc,"family":{},"bloc_of":bloc_of,"tech":tech,"new":[],"gate":gate},
 "absorb":absorb,"split":split,"capital":{"Turkey":423,"Russia":257,"Brazil":184},
 "defs":defs,"setup":setup,
 "pop_f":{"Europe":0.82,"North America":0.55,"Asia":0.5,"Africa":0.3,"South America":0.4,"Oceania":0.5},
 "gdp_default":0.04,
 "nukes":[US,R,UK,"France"],
 "carriers":{US:12,UK:4,"France":2,R:0},
 "events":events,"leaders":leaders,"objectives":objectives,
}
en_ev = {"0":"Cuban Missile Crisis tension rises: diplomatic channels between the US and USSR are strained.",
 "1":"Soviet missiles begin leaving Cuba; the crisis is easing.",
 "2":"A border clash between China and India has begun.",
 "3":"A ceasefire is declared in the Sino-Indian border war.",
 "4":"The US, UK and USSR sign a treaty banning atmospheric nuclear tests.",
 "5":"War over Kashmir breaks out between India and Pakistan.",
 "6":"The India-Pakistan war ends as the UN steps in.",
 "7":"Six-Day War: Israel moves against Egypt, Syria and Jordan.",
 "8":"The Six-Day War ends in a ceasefire.",
 "9":"Warsaw Pact forces entered Czechoslovakia."}
era["en"]={"name":"Cold War","sub":"October 1962 – Cuban Missile Crisis",
 "blurb":"Soviet missiles in Cuba have pushed the world to the brink of nuclear war. Two superpowers, NATO and the Warsaw Pact, newly independent states: one wrong move and everything burns.",
 "setup_intro":"October 1962: Soviet ballistic missiles have been found in Cuba. The US has declared a naval quarantine around the island; the world stands on the edge of nuclear war.",
 "events":en_ev,
 "objectives":{"c1":"Stay alive for two years","c2":"Make 4 allies","c3":"Keep stability above 60"}}
json.dump(era,open("data/eras/cw62.json","w"),ensure_ascii=False,indent=1)

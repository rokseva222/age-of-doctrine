# Age of Doctrine – Senaryo ve Çağ Veri Şeması (JSON)

Yeni senaryolar `data/scenarios/<id>.json`, yeni tarihî çağlar `data/eras/<id>.json` dosyalarına yazılır.
**Dizin dosyalarına (`index.json`) dokunma**; motor sahibi ekler. Doğrulama:

```
cd /home/claude/cihan
timeout 100 godot --headless --path . -s tools/validate_data.gd -- data/scenarios/<id>.json
timeout 100 godot --headless --path . -s tools/validate_data.gd -- data/eras/<id>.json
```
(`tools/validate_data.gd` motor yazılırken hazırlanıyor; yoksa önce tüm içeriği yaz, sonra tekrar dene.)
Ülke/eyalet arama: `python3 tools/world_find.py Turkey` · `-p İzmir` (eyalet) · `-c Turkey` (ülkenin eyaletleri) · `-n Turkey` (komşular).

## Genel kurallar
- Ülke adları **world.json `name_en`** ile birebir aynı olmalı ("United States of America", "Russia", "Dem. Rep. Congo", "Bosnia and Herz." …). Emin olmadan yazma; `world_find.py` ile doğrula.
- Eyalet kimliği (id) tam sayıdır; ad ile de eşleşir (`"İzmir"`), ama aynı ada sahip eyalet birden çoksa kimlik kullan.
- Metinler **Türkçe**, tarafsız, haber dili; ayrıca her dosyada **`en`** bloğu İngilizce karşılıkları verir (aşağıda).
- **Gerçek terör/aşırılıkçı örgüt adı, bayrağı, sembolü kullanılmaz.** Kurgusal gruplar tamamen uydurma ad, lider ve renk alır. Gerçek devlet ve liderler kullanılabilir (haber tonunda); nefret söylemi, mağduriyet övgüsü, soykırım inkârı yok. Çatışmaların taraflarına saygılı ve olgusal ol.
- Sayılar JSON sayısıdır (tırnak yok). Renkler `"rrggbb"` (# yok) – yalnızca `defs.color`/`factions.colors`/`emblem` içinde.
- Tüm dosyalar UTF-8, geçerli JSON (yorum yok).

## Senaryo (`data/scenarios/<id>.json`)

```json
{
 "id": "nile",                      // küçük harf/rakam/alt çizgi, dosya adıyla aynı
 "kind": "real",                    // "real" (gerçek dünya krizi) | "fiction" (kurgusal)
 "name": "Nil'in Suları", "sub": "Mısır – Etiyopya",
 "blurb": "Menü kartında görünen 2-3 cümle.",
 "intro": "Oyun başında haber olarak düşen cümle.",
 "suggest": ["Egypt", "Ethiopia", "Sudan"],   // önerilen oyuncu ülkeleri (ilki varsayılan seçilir)
 "ally_first": false,               // true: önce ittifaklar, sonra savaşlar kurulur
 "blocs": [ {"name": "...", "members": ["A","B"] , "emblem": {"shape":0-7,"inner":0-2,"symbol":"star","c1":"2f4f9a","c2":"ece6d6","c3":"2f4f9a"}} ],
          // members: ülke listesi ya da "NATO". symbol: star sword swords shield crown globe anchor plane bolt flame castle wheat tank handshake target skull trophy factory
 "wars": [["A","B"]],               // başlangıçta süren savaşlar (A saldırgan taraf)
 "embargo": [["A","B"]],
 "cold": [["A","B"]],               // soğuk savaş/gerginlik çiftleri
 "cyber": {"Country": 30},          // +siber puanı
 "doctrine": {"Country": 5},        // 0..5 (0 savunma … 5 siber; boş bırakmak varsayılan)
 "budget_war": ["Country"],         // bütçesi savaş ekonomisine alınan ülkeler
 "cyber_budget": ["Country"],
 "factions": [ {"name":"Kurgusal Grup Adı","leader":"Unvan|İsim","from":[["Country",3]],"dir":"east|west|north|south|near","troops":40000,"tech":0.3,"doctrine":4,"colors":["1c1f24","e58a3a","ece6d6"],"pattern":0-5,"aggression":1.0} ],
          // from: [ülke, kaç eyalet koparılacağı]; dir: koparılacak eyaletlerin yönü
 "transfer": [ ["İzmir", "Turkey", "Greece", "own"] ],   // [eyalet id|ad, bugünkü sahip, yeni sahip, "own"|"occ"] (own: mülkiyet, occ: işgal)
 "troops_mult": {"Country": 1.3},   // 0.5-2.0 aralığı; başlangıç ordusu çarpanı
 "treasury_mult": {"Country": 0.7}, // kasa çarpanı 0.3-3.0
 "stability": {"Country": -20},     // -40..+20 istikrar farkı
 "rename": {"Country": {"name":"Yeni Ad", "color":"rrggbb", "leader":"Unvan|İsim"}},   // isim/renk/lider değişimi (hepsi isteğe bağlı)
 "events": [ {"turn": 8, "t": "Haber metni.", "fx": [["war","A","B"],["peace","A","B"],["ally","A","B"],["stab","A",-8]]} ],
          // turn: başlangıçtan kaç hafta sonra (1 tur = 1 hafta). fx tipleri: war, peace, ally, stab (oyuncuya uygulanmaz)
 "objectives": {                    // oyuncunun seçtiği ülkeye göre hedefler; "*" varsayılan
   "*":      [ {"id":"o1","type":"own_provinces","n":30,"text":"30 eyalete ulaş"} ],
   "Egypt":  [ {"id":"e1","type":"cease_war","with":"Ethiopia","text":"Etiyopya ile barış yap"} ]
 },
 "deadline": 156,                   // isteğe bağlı: bu tura kadar zorunlu hedefler bitmezse yenilgi
 "en": {"name":"...","sub":"...","blurb":"...","intro":"...",
        "objectives": {"o1":"Reach 30 provinces","e1":"Make peace with Ethiopia"},
        "events": {"0":"English text of events[0].t"}}
}
```

### Hedef (objective) tipleri
Her hedef: `id` (senaryo içinde benzersiz), `type`, `text` (Türkçe), isteğe bağlı `"required": false` (bonus hedef; varsayılan zorunlu). Zorunlu hedeflerin hepsi tamamlanınca **zafer**.
| type | alanlar | koşul |
|---|---|---|
| `own_provinces` | n | oyuncu ≥ n eyalete sahip |
| `own_province` | province (id/ad) | o eyalet oyuncunun |
| `own_capital` | country | o ülkenin (bugünkü) başkent eyaleti oyuncunun |
| `eliminate` | country | o ülke yok edildi |
| `survive` | turns | başlangıçtan beri n tur hayatta |
| `cease_war` | with | o ülkeyle savaşta değil (en az 4 tur) |
| `no_war` | turns | n tur boyunca hiçbir savaşta olma |
| `alliances` | n | ≥ n müttefik |
| `stability` | n | istikrar ≥ n (4 tur üst üste) |
| `gdp_share` | pct | dünya GSYH payı ≥ pct |
| `bloc_members` | n | oyuncunun bloğunda ≥ n üye |
| `hold_choke` | choke | o stratejik geçidin (suez, hormuz, malacca, bosphorus, babelmandeb, gibraltar, panama, danish, channel) kontrolü oyuncuda |

## Tarihî çağ (`data/eras/<id>.json`)

Mevcut I. ve II. Dünya Savaşı çağlarıyla aynı mantık: bugünkü ülkeler **birleştirilir/bölünür**, dönemin renk/ad/bayrağı/lideri verilir.

```json
{
 "id": "cw62", "name": "Soğuk Savaş", "sub": "Ekim 1962",
 "start_year": 1962, "start_doy": 290,           // başlangıç tarihi (yılın günü 0-365)
 "blurb": "...", "suggest": ["United States of America","Russia","Cuba"],
 "look": {"shadow":[0.06,0.07,0.09],"mid":[0.40,0.44,0.40],"light":[0.92,0.90,0.84],"amount":0.30,"vignette":0.14,"grain":0.010},   // renk ayarı (0..1)
 "base": "",                                     // doluysa o çağın tablolarını miras alır (yalnız farkları yaz)
 "arsenal": "ww2",                               // "ww1" | "ww2" | "cw62" ya da kendi tablon (aşağıda)
 "absorb": { "Russia": ["Ukraine","Belarus", "..."] },   // host ülke -> tüm eyaletleriyle birleşen bugünkü ülkeler (host bugünkü adıyla)
 "split": [ ["L'viv","Ukraine","Poland","own"], [788,"Poland","Germany","own"] ],   // [eyalet id|ad, bugünkü sahip, yeni sahip, own|occ]
 "capital": { "Turkey": 423 },                   // dönem başkenti: bugünkü ülke -> eyalet id
 "defs": { "Russia": {"name":"SSCB","color":"b53a2e","flag":"R:0,0,1,1,#cc0000|S:.14,.2,.09,#ffd700","leader":"Genel Sekreter|Nikita Hruşçov","gdp":300,
            "mil":{"personnel":3600000,"tank":20000,"afv":8000,"arty":25000,"air":6000,"sub":380}} },
          // gdp: milyar $ (dönem), mil: kişi/adet; flag: flag_db sözdizimi (docs: scripts/flag_db.gd; boş bırakılabilir)
 "setup": { "blocs":[...aynı biçim...], "wars":[["A","B"]], "truce":[["A","B",90]], "intro":"..." },
 "pop_f": {"Europe":0.8,"North America":0.6,"Asia":0.45,"Africa":0.3,"South America":0.4,"Oceania":0.45},   // bugünkü nüfusa çarpan (kıta)
 "gdp_default": 0.03,                            // defs'te gdp'si olmayan ülkelerin GSYH çarpanı
 "events": [ {"y":1962,"m":10,"t":"Haber.","fx":[["war","A","B"]]} ],     // dönem tarihi (ay bazlı; fx: war,peace,ally,stab)
 "leaders": {"horizon":1975, "chain": {"Russia": [[1964,10,"Genel Sekreter|Leonid Brejnev"]]}},   // [yıl,ay,"Unvan|İsim"]; horizon yılından sonra rastgele değişim
 "objectives": { "*": [ ... ], "United States of America": [ ... ] },    // senaryo hedefleriyle aynı
 "en": {"name":"Cold War","sub":"October 1962","blurb":"...","setup_intro":"...","events":{"0":"..."}}
}
```
Mevcut çağ tabloları örnek olarak `scripts/eras.gd` (ABSORB, SPLIT, DEFS, SETUP), `scripts/era_events.gd`, `scripts/era_leaders.gd`, `scripts/arsenal_era.gd` içinde. Önce oralara bak, aynı biçimi JSON'a çevir.

### Silah tablosu (`arsenal`)
`"ww1"/"ww2"` yeniden kullanılabilir. Yeni tablo gerekirse `scripts/arsenal_era.gd` ile **aynı yapı** JSON olarak yazılır:
`{"items": {"id": ["Ad","kategori","Menşei(name_en)",tier(1-4),fiyat,satılabilir_mi]}, "bloc": {...}, "family": {...}, "bloc_of": {"Country":"us"}, "tech": {"Country":0.6}, "new": [], "gate": {"item_id": hafta}}`.
Kategoriler: `inf`, `tank`, `afv`, `arty`, `air` (fighter/bomber: id önekine bak), `sub`, vb. – arsenal_era.gd'deki ids/öneklerle aynı kategorileri kullan.

## Alternatif tarih çağları (`data/eras/alt_*.json`)
`base` ile ww1/ww2/cw62'nin haritasını, tablolarını ve (yoksa) lider zincirini miras alır; yalnızca farklar yazılır. Üretici: `tools/data/gen_alt.py`.
Ek alanlar:
- `"pack": "alt"` — Alternatif Tarih Paketi'ne bağlı (kilit: `era_pack_alt`); `"free": true` ücretsiz örnek çağ.
- `"setup"`: `blocs`, `wars`, `truce`, `intro` ile birlikte senaryo alanları da yazılabilir: `cold`, `embargo`, `troops_mult`, `treasury_mult`, `stability`, `transfer`, `cyber`…
- `"inherit_until": [yıl, ay]` ve `"inherit_exclude": ["metin parçası"]` — base çağın gerçek olayları ayrışma tarihine kadar akar; hariç tutulan metinler atlanır (`inherit_exclude: []` tüm olayları miras alır).
- `"icon"`, `"mood"`, `"nukes"`, `"carriers"` yoksa ext base'inden okunur.

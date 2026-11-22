# -*- coding: utf-8 -*-
# 2026-11-22 çeviri eki: kodda olup paketlerde eksik kalan arayüz metinleri (13 dil). Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

# ---- amblemler (bayrak düzenleyici)
a("Orak ve çekiç", "Hammer and sickle", "Hammer und Sichel", "Hoz y martillo", "Faucille et marteau", "Falce e martello", "Foice e martelo", "Серп и молот", "المطرقة والمنجل", "چکش و داس", "锤子与镰刀", "鎌とハンマー", "망치와 낫", "हथौड़ा और हंसिया")
a("Çekiç", "Hammer", "Hammer", "Martillo", "Marteau", "Martello", "Martelo", "Молот", "مطرقة", "چکش", "锤子", "ハンマー", "망치", "हथौड़ा")
a("Orak", "Sickle", "Sichel", "Hoz", "Faucille", "Falce", "Foice", "Серп", "منجل", "داس", "镰刀", "鎌", "낫", "हंसिया")
a("Kartal", "Eagle", "Adler", "Águila", "Aigle", "Aquila", "Águia", "Орёл", "نسر", "عقاب", "鹰", "鷲", "독수리", "उकाब")
a("Çift başlı kartal", "Double-headed eagle", "Doppeladler", "Águila bicéfala", "Aigle bicéphale", "Aquila bicipite", "Águia bicéfala", "Двуглавый орёл", "نسر برأسين", "عقاب دوسر", "双头鹰", "双頭の鷲", "쌍두독수리", "दो सिरों वाला उकाब")
a("Aslan", "Lion", "Löwe", "León", "Lion", "Leone", "Leão", "Лев", "أسد", "شیر", "狮子", "ライオン", "사자", "शेर")
a("Buğday başağı", "Wheat ear", "Weizenähre", "Espiga de trigo", "Épi de blé", "Spiga di grano", "Espiga de trigo", "Колос пшеницы", "سنبلة قمح", "خوشه گندم", "麦穗", "麦の穂", "밀 이삭", "गेहूं की बाली")
a("Defne çelengi", "Laurel wreath", "Lorbeerkranz", "Corona de laurel", "Couronne de laurier", "Corona d'alloro", "Coroa de louros", "Лавровый венок", "إكليل الغار", "تاج غار", "月桂花环", "月桂冠", "월계관", "लॉरेल की माला")
a("Zeytin dalı", "Olive branch", "Olivenzweig", "Rama de olivo", "Rameau d'olivier", "Ramo d'ulivo", "Ramo de oliveira", "Оливковая ветвь", "غصن الزيتون", "شاخه زیتون", "橄榄枝", "オリーブの枝", "올리브 가지", "जैतून की टहनी")
a("Çark", "Cogwheel", "Zahnrad", "Engranaje", "Engrenage", "Ingranaggio", "Engrenagem", "Шестерня", "ترس", "چرخ‌دنده", "齿轮", "歯車", "톱니바퀴", "गियर")
a("Ejderha", "Dragon", "Drache", "Dragón", "Dragon", "Drago", "Dragão", "Дракон", "تنين", "اژدها", "龙", "龍", "용", "ड्रैगन")
a("Bozkurt", "Grey wolf", "Grauer Wolf", "Lobo gris", "Loup gris", "Lupo grigio", "Lobo-cinzento", "Серый волк", "الذئب الرمادي", "گرگ خاکستری", "灰狼", "灰色オオカミ", "회색늑대", "ग्रे वुल्फ")
a("Ayı", "Bear", "Bär", "Oso", "Ours", "Orso", "Urso", "Медведь", "دب", "خرس", "熊", "熊", "곰", "भालू")
a("Yumruk", "Fist", "Faust", "Puño", "Poing", "Pugno", "Punho", "Кулак", "قبضة", "مشت", "拳头", "拳", "주먹", "मुट्ठी")
a("Kule", "Tower", "Turm", "Torre", "Tour", "Torre", "Torre", "Башня", "برج", "برج", "塔", "塔", "탑", "मीनार")
a("Üç dişli mızrak", "Trident", "Dreizack", "Tridente", "Trident", "Tridente", "Tridente", "Трезубец", "رمح ثلاثي", "سه‌شاخه", "三叉戟", "三叉槍", "삼지창", "त्रिशूल")
a("Meşale", "Torch", "Fackel", "Antorcha", "Torche", "Torcia", "Tocha", "Факел", "شعلة", "مشعل", "火炬", "たいまつ", "횃불", "मशाल")
a("Kitap", "Book", "Buch", "Libro", "Livre", "Libro", "Livro", "Книга", "كتاب", "کتاب", "书", "本", "책", "किताब")
a("Meşe yaprağı", "Oak leaf", "Eichenblatt", "Hoja de roble", "Feuille de chêne", "Foglia di quercia", "Folha de carvalho", "Дубовый лист", "ورقة بلوط", "برگ بلوط", "橡叶", "オークの葉", "참나무 잎", "बलूत का पत्ता")
a("Zambak", "Lily", "Lilie", "Lirio", "Lys", "Giglio", "Lírio", "Лилия", "زنبق", "سوسن", "百合", "ユリ", "백합", "लिली")
a("Altı köşeli yıldız", "Six-pointed star", "Sechszackiger Stern", "Estrella de seis puntas", "Étoile à six branches", "Stella a sei punte", "Estrela de seis pontas", "Шестиконечная звезда", "نجمة سداسية", "ستاره شش‌پر", "六角星", "六芒星", "육각별", "छह नुकीला तारा")
a("Sekiz köşeli yıldız", "Eight-pointed star", "Achtzackiger Stern", "Estrella de ocho puntas", "Étoile à huit branches", "Stella a otto punte", "Estrela de oito pontas", "Восьмиконечная звезда", "نجمة ثمانية", "ستاره هشت‌پر", "八角星", "八芒星", "팔각별", "आठ नुकीला तारा")
a("Akçaağaç yaprağı", "Maple leaf", "Ahornblatt", "Hoja de arce", "Feuille d'érable", "Foglia d'acero", "Folha de bordo", "Кленовый лист", "ورقة القيقب", "برگ افرا", "枫叶", "カエデの葉", "단풍잎", "मेपल का पत्ता")
a("Palmiye", "Palm tree", "Palme", "Palmera", "Palmier", "Palma", "Palmeira", "Пальма", "نخلة", "نخل", "棕榈", "ヤシの木", "야자나무", "ताड़ का पेड़")
a("Sedir", "Cedar", "Zeder", "Cedro", "Cèdre", "Cedro", "Cedro", "Кедр", "أرز", "سدر", "雪松", "シーダー", "시더", "देवदार")
a("Gül", "Rose", "Rose", "Rosa", "Rose", "Rosa", "Rosa", "Роза", "وردة", "گل سرخ", "玫瑰", "バラ", "장미", "गुलाब")
a("At", "Horse", "Pferd", "Caballo", "Cheval", "Cavallo", "Cavalo", "Конь", "حصان", "اسب", "马", "馬", "말", "घोड़ा")
a("Şahin", "Falcon", "Falke", "Halcón", "Faucon", "Falco", "Falcão", "Сокол", "صقر", "شاهین", "隼", "ハヤブサ", "매", "बाज़")
a("Fil", "Elephant", "Elefant", "Elefante", "Éléphant", "Elefante", "Elefante", "Слон", "فيل", "فیل", "象", "ゾウ", "코끼리", "हाथी")
a("Yılan", "Snake", "Schlange", "Serpiente", "Serpent", "Serpente", "Serpente", "Змея", "ثعبان", "مار", "蛇", "ヘビ", "뱀", "साँप")
a("Balta", "Axe", "Axt", "Hacha", "Hache", "Ascia", "Machado", "Топор", "فأس", "تبر", "斧头", "斧", "도끼", "कुल्हाड़ी")
a("Mızrak", "Spear", "Speer", "Lanza", "Lance", "Lancia", "Lança", "Копьё", "رمح", "نیزه", "长矛", "槍", "창", "भाला")
a("Miğfer", "Helmet", "Helm", "Casco", "Casque", "Elmo", "Elmo", "Шлем", "خوذة", "کلاه‌خود", "头盔", "兜", "투구", "शिरस्त्राण")
a("Dağ", "Mountain", "Berg", "Montaña", "Montagne", "Montagna", "Montanha", "Гора", "جبل", "کوه", "山", "山", "산", "पर्वत")

# ---- genel arayüz
a("%d. Hava Filosu", "Air Wing #%d", "%d. Luftgruppe", "Ala aérea n.º %d", "%de escadre aérienne", "%dª ala aerea", "%dª ala aérea", "%d-е авиакрыло", "الجناح الجوي %d", "ناوگان هوایی %d", "第%d航空联队", "第%d航空団", "제%d 항공단", "%d वायु विंग")
a(" (eskort)", " (escort)", " (Eskorte)", " (escolta)", " (escorte)", " (scorta)", " (escolta)", " (эскорт)", " (مرافقة)", " (اسکورت)", " (护航)", " (護衛)", " (호위)", " (अनुरक्षक)")
a("Çıkarma filomuz denizde düşman donanması tarafından vuruldu: %d asker kaybedildi.",
  "Our landing fleet was hit at sea by the enemy navy: %d troops lost.",
  "Unsere Landungsflotte wurde auf See von der feindlichen Marine getroffen: %d Soldaten verloren.",
  "Nuestra flota de desembarco fue atacada en el mar por la armada enemiga: %d soldados perdidos.",
  "Notre flotte de débarquement a été frappée en mer par la marine ennemie : %d soldats perdus.",
  "La nostra flotta da sbarco è stata colpita in mare dalla marina nemica: %d soldati persi.",
  "Nossa frota de desembarque foi atingida no mar pela marinha inimiga: %d soldados perdidos.",
  "Наш десантный флот был поражён в море вражеским флотом: потеряно %d солдат.",
  "تعرّض أسطول الإنزال لدينا لضربة في البحر من الأسطول المعادي: فُقد %d جندي.",
  "ناوگان پیاده‌سازی ما در دریا توسط نیروی دریایی دشمن مورد حمله قرار گرفت: %d سرباز از دست رفت.",
  "我方登陆舰队在海上遭敌方海军打击:损失 %d 名士兵。",
  "我が上陸艦隊は海上で敵海軍の攻撃を受け、兵士%d名を失った。",
  "아군 상륙 함대가 해상에서 적 해군의 공격을 받아 병력 %d명을 잃었습니다.",
  "हमारा उतरण बेड़ा समुद्र में दुश्मन नौसेना के हमले में घिर गया: %d सैनिक मारे गए।")
a("Uluslararası baskı sonuç verdi: %s ile merkez arasında ateşkes sağlandı.",
  "International pressure worked: a ceasefire was reached between %s and the centre.",
  "Der internationale Druck wirkte: Zwischen %s und der Zentralregierung wurde ein Waffenstillstand erreicht.",
  "La presión internacional dio resultado: se logró un alto el fuego entre %s y el centro.",
  "La pression internationale a porté ses fruits : un cessez-le-feu a été conclu entre %s et le pouvoir central.",
  "La pressione internazionale ha funzionato: è stato raggiunto un cessate il fuoco tra %s e il centro.",
  "A pressão internacional funcionou: foi alcançado um cessar-fogo entre %s e o governo central.",
  "Международное давление сработало: достигнуто перемирие между %s и центром.",
  "نجح الضغط الدولي: تم التوصل إلى وقف لإطلاق النار بين %s والمركز.",
  "فشار بین‌المللی نتیجه داد: میان %s و دولت مرکزی آتش‌بس برقرار شد.",
  "国际压力奏效:%s 与中央之间达成停火。",
  "国際的な圧力が功を奏し、%sと中央政府の間で停戦が成立した。",
  "국제적 압력이 효과를 거두어 %s와(과) 중앙정부 사이에 휴전이 이뤄졌습니다.",
  "अंतरराष्ट्रीय दबाव काम आया: %s और केंद्र के बीच युद्धविराम हो गया।")
a("Oyuncu", "Player", "Spieler", "Jugador", "Joueur", "Giocatore", "Jogador", "Игрок", "لاعب", "بازیکن", "玩家", "プレイヤー", "플레이어", "खिलाड़ी")
a("Sunucu", "Server", "Server", "Servidor", "Serveur", "Server", "Servidor", "Сервер", "الخادم", "سرور", "服务器", "サーバー", "서버", "सर्वर")
a("Önizleme", "Preview", "Vorschau", "Vista previa", "Aperçu", "Anteprima", "Pré-visualização", "Предпросмотр", "معاينة", "پیش‌نمایش", "预览", "プレビュー", "미리보기", "पूर्वावलोकन")
a("Liste alınamadı.", "Could not get the list.", "Liste konnte nicht abgerufen werden.", "No se pudo obtener la lista.", "Impossible de récupérer la liste.", "Impossibile ottenere l'elenco.", "Não foi possível obter a lista.", "Не удалось получить список.", "تعذّر الحصول على القائمة.", "دریافت فهرست ممکن نشد.", "无法获取列表。", "リストを取得できませんでした。", "목록을 가져오지 못했습니다.", "सूची प्राप्त नहीं हो सकी।")
a("Liste okunamadı.", "Could not read the list.", "Liste konnte nicht gelesen werden.", "No se pudo leer la lista.", "Impossible de lire la liste.", "Impossibile leggere l'elenco.", "Não foi possível ler a lista.", "Не удалось прочитать список.", "تعذّرت قراءة القائمة.", "خواندن فهرست ممکن نشد.", "无法读取列表。", "リストを読み取れませんでした。", "목록을 읽지 못했습니다.", "सूची पढ़ी नहीं जा सकी।")
a("sol siper", "left shield", "linker Schild", "escudo izquierdo", "bouclier gauche", "scudo sinistro", "escudo esquerdo", "левый щит", "الدرع الأيسر", "سپر چپ", "左盾", "左の盾", "왼쪽 방패", "बायाँ ढाल")
a("sağ siper", "right shield", "rechter Schild", "escudo derecho", "bouclier droit", "scudo destro", "escudo direito", "правый щит", "الدرع الأيمن", "سپر راست", "右盾", "右の盾", "오른쪽 방패", "दायाँ ढाल")
a("\nHedef: %s (%d hafta).", "\nTarget: %s (%d weeks).", "\nZiel: %s (%d Wochen).", "\nObjetivo: %s (%d semanas).", "\nObjectif : %s (%d semaines).", "\nObiettivo: %s (%d settimane).", "\nAlvo: %s (%d semanas).", "\nЦель: %s (%d нед.).", "\nالهدف: %s (%d أسبوعًا).", "\nهدف: %s (%d هفته).", "\n目标:%s(%d 周)。", "\n目標:%s(%d週)。", "\n목표: %s (%d주).", "\nलक्ष्य: %s (%d सप्ताह)।")
a("\nHareket için gidilecek denize (ya da kıyı eyaletine) dokun.", "\nTap the sea (or coastal province) to move to.", "\nTippe auf das Meer (oder die Küstenprovinz), um dorthin zu fahren.", "\nToca el mar (o la provincia costera) de destino.", "\nTouchez la mer (ou la province côtière) de destination.", "\nTocca il mare (o la provincia costiera) di destinazione.", "\nToque no mar (ou na província costeira) de destino.", "\nНажмите на море (или прибрежную провинцию), куда идти.", "\nاضغط على البحر (أو الإقليم الساحلي) الذي تريد التحرك إليه.", "\nبرای حرکت، روی دریا (یا استان ساحلی) مقصد بزنید.", "\n点击要前往的海域(或沿海省份)。", "\n移動先の海(または沿岸の州)をタップしてください。", "\n이동할 바다(또는 해안 지방)를 누르세요.", "\nजाने के लिए समुद्र (या तटीय प्रांत) को छुएँ।")
a("\nSaldırı için hazırlanıyor: %d hafta.", "\nPreparing for the assault: %d weeks.", "\nBereitet den Angriff vor: %d Wochen.", "\nSe prepara para el asalto: %d semanas.", "\nPréparation de l'assaut : %d semaines.", "\nSi prepara all'assalto: %d settimane.", "\nPreparando o ataque: %d semanas.", "\nГотовится к штурму: %d нед.", "\nيستعد للهجوم: %d أسبوعًا.", "\nدر حال آماده‌سازی برای حمله: %d هفته.", "\n正在准备进攻:%d 周。", "\n攻撃準備中:%d週。", "\n공격 준비 중: %d주.", "\nहमले की तैयारी: %d सप्ताह।")

# ---- yönetim biçimi (Politika)
a("Tek lider, milliyetçi seferberlik: istikrar sağlam, savaş yorgunluğu yok. Dünya tepkisi sert, ekonomi biraz verimsiz.",
  "One leader and nationalist mobilization: firm stability, no war weariness. Harsh world reaction, a slightly inefficient economy.",
  "Ein Führer und nationalistische Mobilmachung: feste Stabilität, keine Kriegsmüdigkeit. Harte Weltreaktion, leicht ineffiziente Wirtschaft.",
  "Un solo líder y movilización nacionalista: estabilidad firme, sin cansancio de guerra. Dura reacción mundial y economía algo ineficiente.",
  "Un seul chef et une mobilisation nationaliste : stabilité solide, pas de lassitude de guerre. Forte réaction mondiale, économie un peu inefficace.",
  "Un solo capo e mobilitazione nazionalista: stabilità solida, nessuna stanchezza di guerra. Dura reazione mondiale, economia poco efficiente.",
  "Um só líder e mobilização nacionalista: estabilidade firme, sem cansaço de guerra. Reação mundial dura e economia um pouco ineficiente.",
  "Один лидер и националистическая мобилизация: прочная стабильность, нет усталости от войны. Резкая реакция мира, экономика немного неэффективна.",
  "زعيم واحد وتعبئة قومية: استقرار متين ولا إرهاق حرب. ردّ فعل عالمي حاد واقتصاد أقل كفاءة قليلًا.",
  "یک رهبر و بسیج ملی‌گرایانه: ثبات استوار و بدون خستگی از جنگ. واکنش شدید جهان و اقتصادی کمی ناکارآمد.",
  "一位领袖与民族主义动员:稳定牢固,没有厌战情绪。世界反应强烈,经济效率略低。",
  "ひとりの指導者と民族主義的動員:安定は堅固で厭戦感はない。世界の反発は強く、経済はやや非効率。",
  "한 명의 지도자와 민족주의적 총동원: 안정이 굳건하고 전쟁 피로가 없습니다. 세계의 반응은 거세고 경제는 다소 비효율적입니다.",
  "एक नेता और राष्ट्रवादी लामबंदी: मज़बूत स्थिरता, युद्ध-थकान नहीं। दुनिया की कड़ी प्रतिक्रिया और थोड़ी अक्षम अर्थव्यवस्था।")
a("Hanedan simgesel, yönetim seçilmiş meclisin elinde: meşruiyet ve ticaret güçlü, darbe riski çok düşük. Savaş yorgunluğu demokrasiden biraz hafif.",
  "A symbolic dynasty with an elected parliament governing: strong legitimacy and trade, very low coup risk. War weariness is a little milder than in a democracy.",
  "Eine symbolische Dynastie, regiert von einem gewählten Parlament: starke Legitimität und Handel, sehr geringes Putschrisiko. Die Kriegsmüdigkeit ist etwas milder als in einer Demokratie.",
  "Una dinastía simbólica con un parlamento electo que gobierna: legitimidad y comercio sólidos, riesgo de golpe muy bajo. El cansancio de guerra es algo menor que en una democracia.",
  "Une dynastie symbolique, gouvernée par un parlement élu : légitimité et commerce solides, risque de coup d'État très faible. La lassitude de guerre est un peu moindre qu'en démocratie.",
  "Una dinastia simbolica con un parlamento eletto al governo: legittimità e commercio solidi, rischio di colpo di stato molto basso. La stanchezza di guerra è un po' più lieve che in una democrazia.",
  "Uma dinastia simbólica com um parlamento eleito no governo: legitimidade e comércio fortes, risco de golpe muito baixo. O cansaço de guerra é um pouco menor que numa democracia.",
  "Династия символична, правит избранный парламент: сильная легитимность и торговля, очень низкий риск переворота. Усталость от войны чуть слабее, чем в демократии.",
  "سلالة رمزية وبرلمان منتخب يحكم: شرعية وتجارة قويتان وخطر انقلاب منخفض جدًا. إرهاق الحرب أخف قليلًا منه في الديمقراطية.",
  "خاندان نمادین است و مجلس منتخب حکومت می‌کند: مشروعیت و تجارت قوی و خطر کودتا بسیار کم. خستگی از جنگ کمی کمتر از دموکراسی است.",
  "王室只具象征意义,由民选议会执政:合法性与贸易强劲,政变风险极低。厌战情绪比民主制略轻。",
  "王室は象徴的で、選挙で選ばれた議会が統治する:正統性と貿易は強く、クーデターの危険は非常に低い。厭戦感は民主制よりやや軽い。",
  "왕조는 상징적이며 선출된 의회가 통치합니다: 정통성과 무역이 강하고 쿠데타 위험이 매우 낮습니다. 전쟁 피로는 민주주의보다 조금 약합니다.",
  "राजवंश प्रतीकात्मक है और निर्वाचित संसद शासन करती है: वैधता और व्यापार मज़बूत, तख्तापलट का जोखिम बहुत कम। युद्ध-थकान लोकतंत्र से थोड़ी हल्की है।")
a("Din adamları yönetir: istikrar sağlam, savaş yorgunluğu çok az. Ekonomi ve dış ticaret verimsiz, laik dünya mesafeli durur.",
  "Clerics rule: firm stability, very little war weariness. The economy and foreign trade are inefficient, and the secular world keeps its distance.",
  "Geistliche regieren: feste Stabilität, sehr geringe Kriegsmüdigkeit. Wirtschaft und Außenhandel sind ineffizient, und die säkulare Welt hält Abstand.",
  "Gobierna el clero: estabilidad firme y muy poco cansancio de guerra. La economía y el comercio exterior son ineficientes y el mundo laico mantiene las distancias.",
  "Le clergé gouverne : stabilité solide, très peu de lassitude de guerre. L'économie et le commerce extérieur sont inefficaces, et le monde laïque garde ses distances.",
  "Governa il clero: stabilità solida, pochissima stanchezza di guerra. Economia e commercio estero sono inefficienti e il mondo laico mantiene le distanze.",
  "O clero governa: estabilidade firme e pouquíssimo cansaço de guerra. A economia e o comércio exterior são ineficientes, e o mundo laico mantém distância.",
  "Правит духовенство: прочная стабильность, очень мало усталости от войны. Экономика и внешняя торговля неэффективны, светский мир держится на расстоянии.",
  "يحكم رجال الدين: استقرار متين وإرهاق حرب ضئيل جدًا. الاقتصاد والتجارة الخارجية غير كفؤين، والعالم العلماني يبقى على مسافة.",
  "روحانیون حکومت می‌کنند: ثبات استوار و خستگی از جنگ بسیار اندک. اقتصاد و تجارت خارجی ناکارآمد است و جهان سکولار فاصله می‌گیرد.",
  "神职人员执政:稳定牢固,厌战情绪极低。经济与对外贸易效率低下,世俗世界保持距离。",
  "聖職者が統治する:安定は堅固で厭戦感はごくわずか。経済と対外貿易は非効率で、世俗の世界は距離を置く。",
  "성직자가 통치합니다: 안정이 굳건하고 전쟁 피로가 매우 적습니다. 경제와 대외 무역은 비효율적이며 세속 세계는 거리를 둡니다.",
  "धर्मगुरु शासन करते हैं: मज़बूत स्थिरता, युद्ध-थकान बहुत कम। अर्थव्यवस्था और विदेशी व्यापार अक्षम हैं और धर्मनिरपेक्ष दुनिया दूरी बनाए रखती है।")
a("Metropolün atadığı valiler yönetir: istikrar yavaş ve sakin, ama gelir düşük ve halk bağımsızlık ister.",
  "Governors appointed by the mother country rule: stability is slow and quiet, but income is low and the people want independence.",
  "Vom Mutterland ernannte Gouverneure regieren: Die Stabilität ist langsam und ruhig, doch das Einkommen ist niedrig und das Volk will Unabhängigkeit.",
  "Gobiernan gobernadores nombrados por la metrópoli: estabilidad lenta y tranquila, pero ingresos bajos y un pueblo que quiere independencia.",
  "Des gouverneurs nommés par la métropole gouvernent : stabilité lente et calme, mais revenus faibles et un peuple qui veut l'indépendance.",
  "Governano i governatori nominati dalla madrepatria: stabilità lenta e tranquilla, ma entrate basse e un popolo che vuole l'indipendenza.",
  "Governam governadores nomeados pela metrópole: estabilidade lenta e calma, mas renda baixa e um povo que quer independência.",
  "Правят губернаторы, назначаемые метрополией: стабильность медленная и спокойная, но доход низкий, а народ хочет независимости.",
  "يحكم حكّام تعيّنهم الدولة الأم: استقرار بطيء وهادئ لكن الدخل منخفض والشعب يريد الاستقلال.",
  "فرمانداران منصوب کشور مادر حکومت می‌کنند: ثبات کند و آرام است، اما درآمد کم است و مردم خواهان استقلال‌اند.",
  "由宗主国任命的总督统治:稳定缓慢而平静,但收入低,民众渴望独立。",
  "本国が任命した総督が統治する:安定は緩やかで穏やかだが、収入は低く、民衆は独立を望む。",
  "본국이 임명한 총독이 통치합니다: 안정은 느리고 조용하지만 수입이 낮고 국민은 독립을 원합니다.",
  "मातृदेश द्वारा नियुक्त गवर्नर शासन करते हैं: स्थिरता धीमी और शांत है, पर आय कम है और जनता स्वतंत्रता चाहती है।")
a("Krala bağlı soylular ve toprak ağaları: istikrar orta, savaş yorgunluğu düşük. Beyler güçlenirse hanedan içi darbe riski vardır.",
  "Nobles and landlords bound to the crown: middling stability, low war weariness. If the barons grow strong, palace coups threaten.",
  "Der Krone verpflichtete Adlige und Grundherren: mittlere Stabilität, geringe Kriegsmüdigkeit. Werden die Barone stark, drohen Palastputsche.",
  "Nobles y terratenientes vinculados a la corona: estabilidad media y poco cansancio de guerra. Si los barones se fortalecen, amenazan los golpes de palacio.",
  "Nobles et propriétaires liés à la couronne : stabilité moyenne, faible lassitude de guerre. Si les barons se renforcent, les coups de palais menacent.",
  "Nobili e proprietari terrieri legati alla corona: stabilità media, bassa stanchezza di guerra. Se i baroni diventano forti, incombono congiure di palazzo.",
  "Nobres e proprietários ligados à coroa: estabilidade mediana e pouco cansaço de guerra. Se os barões se fortalecerem, ameaçam os golpes de palácio.",
  "Дворяне и землевладельцы, связанные с короной: средняя стабильность, низкая усталость от войны. Если бароны усилятся, грозят дворцовые перевороты.",
  "نبلاء وملّاك أراضٍ تابعون للتاج: استقرار متوسط وإرهاق حرب منخفض. إن قوي البارونات فإن انقلابات القصر تلوح في الأفق.",
  "اشراف و زمین‌داران وابسته به تاج: ثبات متوسط و خستگی از جنگ کم. اگر بارون‌ها قدرت بگیرند، کودتای درباری تهدید می‌کند.",
  "贵族与地主依附王室:稳定中等,厌战情绪低。若诸侯坐大,则有宫廷政变之险。",
  "王に従う貴族と地主:安定は中程度で厭戦感は低い。諸侯が力を付ければ宮廷クーデターの恐れがある。",
  "왕에게 속한 귀족과 지주: 안정은 보통이고 전쟁 피로는 낮습니다. 제후가 강해지면 궁정 쿠데타의 위험이 있습니다.",
  "राजा से बँधे सामंत और ज़मींदार: मध्यम स्थिरता, कम युद्ध-थकान। यदि बैरन ताक़तवर हुए तो महल में तख्तापलट का ख़तरा रहता है।")
a("SARAY DARBESİ: %s'de hanedan içi darbe; yeni hükümdar %s.",
  "PALACE COUP: a coup inside the %s court; new ruler %s.",
  "PALASTPUTSCH: Ein Putsch am Hof von %s; neuer Herrscher ist %s.",
  "GOLPE DE PALACIO: un golpe dentro de la corte de %s; nuevo gobernante: %s.",
  "COUP DE PALAIS : un coup d'État au sein de la cour de %s ; nouveau souverain : %s.",
  "COLPO DI PALAZZO: un golpe nella corte di %s; nuovo sovrano: %s.",
  "GOLPE DE PALÁCIO: um golpe dentro da corte de %s; novo soberano: %s.",
  "ДВОРЦОВЫЙ ПЕРЕВОРОТ: переворот при дворе %s; новый правитель — %s.",
  "انقلاب قصر: انقلاب داخل بلاط %s؛ الحاكم الجديد %s.",
  "کودتای درباری: کودتایی درون دربار %s رخ داد؛ فرمانروای جدید %s.",
  "宫廷政变:%s 宫廷内部发生政变;新君主为 %s。",
  "宮廷クーデター:%sの宮廷で政変が起き、新君主は%sとなった。",
  "궁정 쿠데타: %s 궁정 내부에서 쿠데타가 일어났습니다. 새 군주는 %s입니다.",
  "महल तख्तापलट: %s के दरबार में तख्तापलट हुआ; नया शासक %s है।")
a("Hanedanı korurken yetkiyi seçilmiş meclise ver: istikrar −6 şimdi, meşruiyet ve ticaret artar, darbe riski çok düşer.",
  "Keep the dynasty but hand power to an elected parliament: stability −6 now; legitimacy and trade rise, coup risk drops.",
  "Die Dynastie behalten, aber die Macht einem gewählten Parlament übergeben: Stabilität jetzt −6; Legitimität und Handel steigen, das Putschrisiko sinkt.",
  "Conservar la dinastía pero ceder el poder a un parlamento electo: estabilidad −6 ahora; suben la legitimidad y el comercio y baja el riesgo de golpe.",
  "Garder la dynastie mais confier le pouvoir à un parlement élu : stabilité −6 maintenant ; la légitimité et le commerce progressent, le risque de coup d'État baisse.",
  "Mantenere la dinastia ma cedere il potere a un parlamento eletto: stabilità −6 subito; legittimità e commercio crescono, il rischio di colpo di stato cala.",
  "Manter a dinastia, mas entregar o poder a um parlamento eleito: estabilidade −6 agora; legitimidade e comércio sobem e o risco de golpe cai.",
  "Сохранить династию, но передать власть избранному парламенту: стабильность −6 сразу; легитимность и торговля растут, риск переворота падает.",
  "الإبقاء على السلالة مع تسليم السلطة إلى برلمان منتخب: الاستقرار −6 الآن؛ ترتفع الشرعية والتجارة وينخفض خطر الانقلاب.",
  "حفظ خاندان و سپردن قدرت به مجلس منتخب: ثبات اکنون −۶؛ مشروعیت و تجارت بالا می‌رود و خطر کودتا کم می‌شود.",
  "保留王室,把权力交给民选议会:稳定立即 −6;合法性与贸易上升,政变风险下降。",
  "王室は残しつつ権力を選挙で選ばれた議会に委ねる:安定は今すぐ−6、正統性と貿易が上がり、クーデターの危険は下がる。",
  "왕조는 유지하되 권력을 선출된 의회에 넘깁니다: 안정 −6(즉시), 정통성과 무역이 오르고 쿠데타 위험이 줄어듭니다.",
  "राजवंश रखते हुए सत्ता निर्वाचित संसद को सौंपें: स्थिरता अभी −6; वैधता और व्यापार बढ़ते हैं, तख्तापलट का जोखिम घटता है।")
a("Hanedan düzenine dön: istikrar −10 şimdi, sonra yavaş ve sağlam; savaş yorgunluğu düşük, dünya tepkisi hafif artar.",
  "Return to dynastic rule: stability −10 now, then slow and firm; low war weariness, mild world backlash.",
  "Zur dynastischen Herrschaft zurückkehren: Stabilität jetzt −10, danach langsam und fest; geringe Kriegsmüdigkeit, leichte Weltreaktion.",
  "Volver al régimen dinástico: estabilidad −10 ahora, luego lenta y firme; poco cansancio de guerra, reacción mundial leve.",
  "Revenir au régime dynastique : stabilité −10 maintenant, puis lente et solide ; faible lassitude de guerre, légère réaction mondiale.",
  "Tornare al governo dinastico: stabilità −10 subito, poi lenta e solida; bassa stanchezza di guerra, lieve reazione mondiale.",
  "Voltar ao governo dinástico: estabilidade −10 agora, depois lenta e firme; pouco cansaço de guerra, reação mundial leve.",
  "Вернуться к династической власти: стабильность −10 сразу, затем медленная и прочная; низкая усталость от войны, слабая реакция мира.",
  "العودة إلى الحكم الأسري: الاستقرار −10 الآن ثم بطيء ومتين؛ إرهاق حرب منخفض وردّ فعل عالمي خفيف.",
  "بازگشت به حکومت خاندانی: ثبات اکنون −۱۰ و سپس کند و استوار؛ خستگی از جنگ کم و واکنش جهانی اندک.",
  "回归王朝统治:稳定立即 −10,之后缓慢而牢固;厌战情绪低,世界反应轻微。",
  "王朝支配に戻る:安定は今すぐ−10、その後は緩やかで堅固。厭戦感は低く、世界の反発は軽い。",
  "왕조 통치로 돌아갑니다: 안정 −10(즉시), 이후 느리지만 굳건합니다. 전쟁 피로가 낮고 세계의 반발은 약합니다.",
  "राजवंशीय शासन पर लौटें: स्थिरता अभी −10, फिर धीमी और मज़बूत; कम युद्ध-थकान, हल्की वैश्विक प्रतिक्रिया।")
a("Soyluların gücünü kır, yetkiyi tahtta topla: mutlak monarşi. İstikrar +8, savaş yorgunluğu azalır; dünya tepkisi artar.",
  "Break the nobles and gather power in the throne: absolute monarchy. Stability +8, less war weariness; backlash grows.",
  "Den Adel brechen und die Macht auf dem Thron bündeln: absolute Monarchie. Stabilität +8, weniger Kriegsmüdigkeit; die Weltreaktion wächst.",
  "Quebrar a la nobleza y concentrar el poder en el trono: monarquía absoluta. Estabilidad +8, menos cansancio de guerra; crece la reacción mundial.",
  "Briser la noblesse et concentrer le pouvoir sur le trône : monarchie absolue. Stabilité +8, moins de lassitude de guerre ; la réaction mondiale s'accroît.",
  "Spezzare i nobili e concentrare il potere sul trono: monarchia assoluta. Stabilità +8, meno stanchezza di guerra; cresce la reazione mondiale.",
  "Quebrar a nobreza e concentrar o poder no trono: monarquia absoluta. Estabilidade +8, menos cansaço de guerra; a reação mundial cresce.",
  "Сломить знать и сосредоточить власть на троне: абсолютная монархия. Стабильность +8, меньше усталости от войны; реакция мира усиливается.",
  "كسر شوكة النبلاء وجمع السلطة في العرش: ملكية مطلقة. الاستقرار +8 وإرهاق حرب أقل؛ يزداد ردّ الفعل العالمي.",
  "درهم‌شکستن اشراف و تمرکز قدرت در تاج‌وتخت: سلطنت مطلقه. ثبات +۸، خستگی از جنگ کمتر؛ واکنش جهانی بیشتر می‌شود.",
  "削弱贵族,把权力集中于王座:绝对君主制。稳定 +8,厌战情绪下降;世界反应增强。",
  "貴族の力を削ぎ、権力を王座に集める:絶対君主制。安定+8、厭戦感は減り、世界の反発は強まる。",
  "귀족을 꺾고 권력을 왕좌에 모읍니다: 절대군주제. 안정 +8, 전쟁 피로가 줄고 세계의 반발이 커집니다.",
  "सामंतों को तोड़कर सत्ता सिंहासन में केंद्रित करें: निरंकुश राजतंत्र। स्थिरता +8, युद्ध-थकान घटती है; वैश्विक प्रतिक्रिया बढ़ती है।")
a("Tek lider ve milliyetçi seferberlik: istikrar +6, savaş yorgunluğu biter; gelir −%3, dünya tepkisi çok sert artar, demokrasilerle ilişkiler bozulur.",
  "One leader and nationalist mobilization: stability +6, no war weariness; income −3%, a very harsh world backlash and worse ties with democracies.",
  "Ein Führer und nationalistische Mobilmachung: Stabilität +6, keine Kriegsmüdigkeit; Einkommen −3 %, sehr harte Weltreaktion und schlechtere Beziehungen zu Demokratien.",
  "Un solo líder y movilización nacionalista: estabilidad +6, sin cansancio de guerra; ingresos −3 %, durísima reacción mundial y peores lazos con las democracias.",
  "Un seul chef et une mobilisation nationaliste : stabilité +6, plus de lassitude de guerre ; revenus −3 %, très forte réaction mondiale et relations dégradées avec les démocraties.",
  "Un solo capo e mobilitazione nazionalista: stabilità +6, nessuna stanchezza di guerra; entrate −3%, durissima reazione mondiale e rapporti peggiori con le democrazie.",
  "Um só líder e mobilização nacionalista: estabilidade +6, sem cansaço de guerra; renda −3%, reação mundial duríssima e piores laços com as democracias.",
  "Один лидер и националистическая мобилизация: стабильность +6, усталости от войны нет; доход −3%, очень резкая реакция мира и ухудшение отношений с демократиями.",
  "زعيم واحد وتعبئة قومية: الاستقرار +6 ولا إرهاق حرب؛ الدخل −3٪ وردّ فعل عالمي شديد جدًا وتدهور العلاقات مع الديمقراطيات.",
  "یک رهبر و بسیج ملی‌گرایانه: ثبات +۶ و بدون خستگی از جنگ؛ درآمد −۳٪، واکنش بسیار شدید جهان و بدتر شدن روابط با دموکراسی‌ها.",
  "一位领袖与民族主义动员:稳定 +6,没有厌战情绪;收入 −3%,世界反应极为强烈,与民主国家关系恶化。",
  "ひとりの指導者と民族主義的動員:安定+6、厭戦感はなくなる。収入−3%、世界の反発は非常に強く、民主主義国との関係は悪化する。",
  "한 명의 지도자와 민족주의적 총동원: 안정 +6, 전쟁 피로가 사라집니다. 수입 −3%, 세계의 반발이 매우 거세고 민주주의 국가와의 관계가 악화됩니다.",
  "एक नेता और राष्ट्रवादी लामबंदी: स्थिरता +6, युद्ध-थकान ख़त्म; आय −3%, दुनिया की बेहद कड़ी प्रतिक्रिया और लोकतंत्रों से संबंध बिगड़ते हैं।")
a("Tek parti ve planlı ekonomi: istikrar +4, gelir sabit; dünya tepkisi artar, demokrasilerle ilişkiler bozulur.",
  "One party and a planned economy: stability +4, steady income; backlash grows and ties with democracies worsen.",
  "Einparteiensystem und Planwirtschaft: Stabilität +4, stabiles Einkommen; die Weltreaktion wächst und die Beziehungen zu Demokratien verschlechtern sich.",
  "Partido único y economía planificada: estabilidad +4, ingresos estables; crece la reacción mundial y empeoran los lazos con las democracias.",
  "Parti unique et économie planifiée : stabilité +4, revenus stables ; la réaction mondiale s'accroît et les relations avec les démocraties se dégradent.",
  "Partito unico ed economia pianificata: stabilità +4, entrate stabili; cresce la reazione mondiale e peggiorano i rapporti con le democrazie.",
  "Partido único e economia planejada: estabilidade +4, renda estável; a reação mundial cresce e os laços com as democracias pioram.",
  "Одна партия и плановая экономика: стабильность +4, доход стабилен; реакция мира усиливается, отношения с демократиями ухудшаются.",
  "حزب واحد واقتصاد مخطَّط: الاستقرار +4 والدخل ثابت؛ يزداد ردّ الفعل العالمي وتسوء العلاقات مع الديمقراطيات.",
  "تک‌حزبی و اقتصاد برنامه‌ریزی‌شده: ثبات +۴ و درآمد ثابت؛ واکنش جهانی بیشتر می‌شود و روابط با دموکراسی‌ها بدتر.",
  "一党制与计划经济:稳定 +4,收入稳定;世界反应增强,与民主国家关系恶化。",
  "一党体制と計画経済:安定+4、収入は一定。世界の反発は強まり、民主主義国との関係は悪化する。",
  "일당 체제와 계획경제: 안정 +4, 수입은 일정합니다. 세계의 반발이 커지고 민주주의 국가와의 관계가 악화됩니다.",
  "एकदलीय व्यवस्था और नियोजित अर्थव्यवस्था: स्थिरता +4, आय स्थिर; वैश्विक प्रतिक्रिया बढ़ती है और लोकतंत्रों से संबंध बिगड़ते हैं।")
a("Din adamları yönetimi devralır: istikrar +5, savaş yorgunluğu çok azalır; gelir −%3, laik ülkelerle ilişkiler bozulur.",
  "Clerics take over government: stability +5, much less war weariness; income −3%, ties with secular states worsen.",
  "Geistliche übernehmen die Regierung: Stabilität +5, deutlich weniger Kriegsmüdigkeit; Einkommen −3 %, die Beziehungen zu säkularen Staaten verschlechtern sich.",
  "El clero toma el gobierno: estabilidad +5, mucho menos cansancio de guerra; ingresos −3 %, empeoran los lazos con los estados laicos.",
  "Le clergé prend le pouvoir : stabilité +5, bien moins de lassitude de guerre ; revenus −3 %, les relations avec les États laïcs se dégradent.",
  "Il clero assume il governo: stabilità +5, molta meno stanchezza di guerra; entrate −3%, peggiorano i rapporti con gli Stati laici.",
  "O clero assume o governo: estabilidade +5, bem menos cansaço de guerra; renda −3%, os laços com Estados laicos pioram.",
  "Духовенство берёт власть: стабильность +5, усталость от войны заметно падает; доход −3%, отношения со светскими государствами ухудшаются.",
  "يتولى رجال الدين الحكم: الاستقرار +5 وإرهاق الحرب أقل بكثير؛ الدخل −3٪ وتسوء العلاقات مع الدول العلمانية.",
  "روحانیون حکومت را به دست می‌گیرند: ثبات +۵ و خستگی از جنگ بسیار کمتر؛ درآمد −۳٪ و روابط با کشورهای سکولار بدتر می‌شود.",
  "神职人员接管政府:稳定 +5,厌战情绪大幅下降;收入 −3%,与世俗国家关系恶化。",
  "聖職者が政権を握る:安定+5、厭戦感は大きく減る。収入−3%、世俗国家との関係は悪化する。",
  "성직자가 정부를 장악합니다: 안정 +5, 전쟁 피로가 크게 줄고 수입 −3%, 세속 국가와의 관계가 악화됩니다.",
  "धर्मगुरु सरकार संभालते हैं: स्थिरता +5, युद्ध-थकान काफ़ी घटती है; आय −3%, धर्मनिरपेक्ष देशों से संबंध बिगड़ते हैं।")
a("Meşruti monarşiye geç", "Become a constitutional monarchy", "Zur konstitutionellen Monarchie werden", "Pasar a monarquía constitucional", "Devenir une monarchie constitutionnelle", "Passare alla monarchia costituzionale", "Tornar-se monarquia constitucional", "Перейти к конституционной монархии", "التحول إلى ملكية دستورية", "گذار به مشروطه سلطنتی", "改为君主立宪制", "立憲君主制に移行する", "입헌군주제로 전환", "संवैधानिक राजतंत्र बनें")
a("Monarşi ilan et", "Restore the monarchy", "Die Monarchie wiederherstellen", "Restaurar la monarquía", "Restaurer la monarchie", "Restaurare la monarchia", "Restaurar a monarquia", "Восстановить монархию", "استعادة الملكية", "بازگرداندن سلطنت", "恢复君主制", "君主制を復活させる", "군주제 복원", "राजतंत्र बहाल करें")
a("Mutlak monarşi (merkezileştir)", "Absolute monarchy (centralize)", "Absolute Monarchie (zentralisieren)", "Monarquía absoluta (centralizar)", "Monarchie absolue (centraliser)", "Monarchia assoluta (centralizzare)", "Monarquia absoluta (centralizar)", "Абсолютная монархия (централизовать)", "ملكية مطلقة (مركزة)", "سلطنت مطلقه (متمرکزسازی)", "绝对君主制(集权)", "絶対君主制(中央集権化)", "절대군주제(중앙집권)", "निरंकुश राजतंत्र (केंद्रीकरण)")
a("Faşist düzene geç", "Adopt fascist rule", "Faschistische Herrschaft einführen", "Adoptar un régimen fascista", "Adopter un régime fasciste", "Adottare il regime fascista", "Adotar um regime fascista", "Перейти к фашистскому режиму", "اعتماد الحكم الفاشي", "گذار به حکومت فاشیستی", "实行法西斯统治", "ファシズム体制に移行する", "파시즘 체제로 전환", "फ़ासीवादी शासन अपनाएँ")
a("Tek parti rejimine geç", "Adopt one-party rule", "Einparteienherrschaft einführen", "Adoptar el partido único", "Adopter le régime à parti unique", "Adottare il partito unico", "Adotar o partido único", "Перейти к однопартийному правлению", "اعتماد حكم الحزب الواحد", "گذار به حکومت تک‌حزبی", "实行一党制", "一党体制に移行する", "일당 체제로 전환", "एकदलीय शासन अपनाएँ")
a("Teokrasi ilan et", "Declare a theocracy", "Eine Theokratie ausrufen", "Proclamar una teocracia", "Proclamer une théocratie", "Proclamare una teocrazia", "Proclamar uma teocracia", "Провозгласить теократию", "إعلان دولة ثيوقراطية", "اعلام حکومت دینی", "宣布神权政治", "神権政治を宣言する", "신정 국가 선포", "धर्मतंत्र घोषित करें")
a("%s yönetim biçimini değiştirdi: %s.", "%s changed its form of government: %s.", "%s hat seine Regierungsform geändert: %s.", "%s cambió su forma de gobierno: %s.", "%s a changé de forme de gouvernement : %s.", "%s ha cambiato forma di governo: %s.", "%s mudou a sua forma de governo: %s.", "%s сменила форму правления: %s.", "غيّرت %s شكل حكمها: %s.", "%s شکل حکومت خود را تغییر داد: %s.", "%s 更改了政体:%s。", "%sは統治形態を変更した:%s。", "%s이(가) 정부 형태를 바꿨습니다: %s.", "%s ने अपनी शासन प्रणाली बदली: %s।")
a("Yönetim biçimi değişti: %s.", "Form of government changed: %s.", "Regierungsform geändert: %s.", "Forma de gobierno cambiada: %s.", "Forme de gouvernement modifiée : %s.", "Forma di governo cambiata: %s.", "Forma de governo alterada: %s.", "Форма правления изменена: %s.", "تغيّر شكل الحكم: %s.", "شکل حکومت تغییر کرد: %s.", "政体已更改:%s。", "統治形態が変更された:%s。", "정부 형태가 바뀌었습니다: %s.", "शासन प्रणाली बदली: %s।")

# ---- Osmanlı lider unvanları (en değerleri Türkçe kalmıştı)
a("Büyük Üstat", "Grand Master", "Großmeister", "Gran Maestre", "Grand Maître", "Gran Maestro", "Grão-Mestre", "Великий магистр", "السيد الأعظم", "استاد اعظم", "大团长", "総長", "총장", "ग्रैंड मास्टर")
a("Büyük Knez", "Grand Prince", "Großfürst", "Gran Príncipe", "Grand-prince", "Gran Principe", "Grão-Príncipe", "Великий князь", "الأمير الأكبر", "شاهزاده بزرگ", "大公", "大公", "대공", "ग्रैंड प्रिंस")
a("Dük", "Duke", "Herzog", "Duque", "Duc", "Duca", "Duque", "Герцог", "دوق", "دوک", "公爵", "公爵", "공작", "ड्यूक")
a("Büyük Dük", "Grand Duke", "Großherzog", "Gran Duque", "Grand-duc", "Granduca", "Grão-Duque", "Великий герцог", "الدوق الأكبر", "دوک بزرگ", "大公爵", "大公", "대공작", "ग्रैंड ड्यूक")
a("Seçmen Prens", "Prince-Elector", "Kurfürst", "Príncipe elector", "Prince-électeur", "Principe elettore", "Príncipe-eleitor", "Курфюрст", "الأمير الناخب", "شاهزاده‌ی انتخاب‌کننده", "选帝侯", "選帝侯", "선제후", "प्रिंस-इलेक्टर")
a("Şef", "Chief", "Häuptling", "Jefe", "Chef", "Capo", "Chefe", "Вождь", "زعيم", "رئیس", "首领", "長", "족장", "प्रमुख")
a("Üstat", "Master", "Meister", "Maestro", "Maître", "Maestro", "Mestre", "Магистр", "السيد", "استاد", "团长", "騎士団長", "단장", "मास्टर")

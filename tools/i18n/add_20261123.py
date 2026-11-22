# -*- coding: utf-8 -*-
# 2026-11-23: yeni dünya krizi türleri (crises.gd). Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a("Küresel Ticaret Savaşı", "Global Trade War", "Globaler Handelskrieg", "Guerra comercial global", "Guerre commerciale mondiale", "Guerra commerciale globale", "Guerra comercial global", "Глобальная торговая война", "حرب تجارية عالمية", "جنگ تجاری جهانی", "全球贸易战", "世界貿易戦争", "글로벌 무역 전쟁", "वैश्विक व्यापार युद्ध")
a("Küresel Siber Saldırı Dalgası", "Global Cyberattack Wave", "Globale Cyberangriffswelle", "Ola global de ciberataques", "Vague mondiale de cyberattaques", "Ondata globale di attacchi informatici", "Onda global de ataques cibernéticos", "Глобальная волна кибератак", "موجة عالمية من الهجمات الإلكترونية", "موج جهانی حملات سایبری", "全球网络攻击浪潮", "世界的なサイバー攻撃の波", "글로벌 사이버 공격 물결", "वैश्विक साइबर हमलों की लहर")
a("Küresel Göç Dalgası", "Global Migration Wave", "Globale Migrationswelle", "Ola migratoria global", "Vague migratoire mondiale", "Ondata migratoria globale", "Onda migratória global", "Глобальная волна миграции", "موجة هجرة عالمية", "موج جهانی مهاجرت", "全球移民潮", "世界的な移民の波", "글로벌 이주 물결", "वैश्विक प्रवासन लहर")
a("Mülteci Akını", "Refugee Influx", "Flüchtlingsstrom", "Afluencia de refugiados", "Afflux de réfugiés", "Afflusso di profughi", "Afluxo de refugiados", "Наплыв беженцев", "تدفق اللاجئين", "هجوم پناهجویان", "难民潮", "難民の流入", "난민 유입", "शरणार्थियों की आमद")
a("Küresel Kuraklık", "Global Drought", "Weltweite Dürre", "Sequía global", "Sécheresse mondiale", "Siccità globale", "Seca global", "Глобальная засуха", "جفاف عالمي", "خشکسالی جهانی", "全球干旱", "世界的な干ばつ", "글로벌 가뭄", "वैश्विक सूखा")
a("Genel Grev Dalgası", "General Strike Wave", "Generalstreikwelle", "Ola de huelgas generales", "Vague de grèves générales", "Ondata di scioperi generali", "Onda de greves gerais", "Волна всеобщих забастовок", "موجة إضرابات عامة", "موج اعتصاب‌های سراسری", "总罢工浪潮", "ゼネストの波", "총파업 물결", "आम हड़तालों की लहर")
a("Büyük Grev Dalgası", "Great Strike Wave", "Große Streikwelle", "Gran ola de huelgas", "Grande vague de grèves", "Grande ondata di scioperi", "Grande onda de greves", "Великая волна забастовок", "موجة إضرابات كبرى", "موج بزرگ اعتصاب‌ها", "大罢工浪潮", "大規模ストの波", "대규모 파업 물결", "महान हड़ताल लहर")
a("Efendim, büyük ekonomiler birbirine gümrük duvarları örüyor; ihracat ve tedarik zincirleri sarsılıyor. Ne yapalım?",
  "Sir, the great economies are raising tariff walls against each other; exports and supply chains are shaken. What do we do?",
  "Herr Präsident, die großen Volkswirtschaften errichten gegeneinander Zollmauern; Exporte und Lieferketten geraten ins Wanken. Was tun wir?",
  "Señor, las grandes economías levantan muros arancelarios entre sí; las exportaciones y las cadenas de suministro se tambalean. ¿Qué hacemos?",
  "Monsieur, les grandes économies dressent des murs douaniers les unes contre les autres ; les exportations et les chaînes d'approvisionnement vacillent. Que faisons-nous ?",
  "Signore, le grandi economie alzano muri doganali l'una contro l'altra; esportazioni e catene di approvvigionamento vacillano. Che facciamo?",
  "Senhor, as grandes economias erguem muros tarifários umas contra as outras; exportações e cadeias de abastecimento estão abaladas. O que fazemos?",
  "Господин, крупные экономики возводят друг против друга тарифные стены; экспорт и цепочки поставок под ударом. Что делаем?",
  "سيدي، الاقتصادات الكبرى تبني جدراناً جمركية في وجه بعضها؛ والصادرات وسلاسل الإمداد تهتز. ماذا نفعل؟",
  "قربان، اقتصادهای بزرگ در برابر یکدیگر دیوار تعرفه می‌کشند؛ صادرات و زنجیره‌های تأمین متزلزل شده‌اند. چه کنیم؟",
  "阁下，各大经济体正在互相筑起关税壁垒，出口和供应链受到冲击。我们该怎么办？",
  "閣下、大国経済が互いに関税の壁を築いており、輸出とサプライチェーンが揺らいでいます。どうしますか？",
  "각하, 주요 경제권이 서로 관세 장벽을 쌓고 있어 수출과 공급망이 흔들리고 있습니다. 어떻게 할까요?",
  "महोदय, बड़ी अर्थव्यवस्थाएँ एक-दूसरे के खिलाफ शुल्क की दीवारें खड़ी कर रही हैं; निर्यात और आपूर्ति शृंखलाएँ डगमगा रही हैं। हम क्या करें?")
a("Efendim, devlet kurumlarına ve bankalara yönelik büyük bir siber saldırı dalgası başladı; sistemler çöküyor. Ne yapalım?",
  "Sir, a major wave of cyberattacks on government agencies and banks has begun; systems are going down. What do we do?",
  "Herr Präsident, eine große Welle von Cyberangriffen auf Behörden und Banken hat begonnen; Systeme fallen aus. Was tun wir?",
  "Señor, ha comenzado una gran ola de ciberataques contra organismos públicos y bancos; los sistemas se caen. ¿Qué hacemos?",
  "Monsieur, une vague massive de cyberattaques visant les administrations et les banques a commencé ; les systèmes s'effondrent. Que faisons-nous ?",
  "Signore, è iniziata una grande ondata di attacchi informatici contro enti pubblici e banche; i sistemi stanno cedendo. Che facciamo?",
  "Senhor, uma grande onda de ataques cibernéticos contra órgãos públicos e bancos começou; os sistemas estão caindo. O que fazemos?",
  "Господин, началась мощная волна кибератак на госорганы и банки; системы выходят из строя. Что делаем?",
  "سيدي، بدأت موجة كبيرة من الهجمات الإلكترونية على مؤسسات الدولة والبنوك؛ والأنظمة تنهار. ماذا نفعل؟",
  "قربان، موج بزرگی از حملات سایبری علیه نهادهای دولتی و بانک‌ها آغاز شده است؛ سامانه‌ها از کار می‌افتند. چه کنیم؟",
  "阁下，针对政府机构和银行的大规模网络攻击浪潮已经开始，系统正在瘫痪。我们该怎么办？",
  "閣下、政府機関と銀行を狙った大規模なサイバー攻撃の波が始まり、システムが停止しています。どうしますか？",
  "각하, 정부 기관과 은행을 노린 대규모 사이버 공격이 시작되어 시스템이 마비되고 있습니다. 어떻게 할까요?",
  "महोदय, सरकारी संस्थानों और बैंकों पर साइबर हमलों की बड़ी लहर शुरू हो गई है; सिस्टम ठप हो रहे हैं। हम क्या करें?")
a("Efendim, savaş ve yoksulluktan kaçan kitleler sınırlara dayandı; kamplar ve şehirler zorlanıyor. Ne yapalım?",
  "Sir, masses fleeing war and poverty have reached the borders; camps and cities are under strain. What do we do?",
  "Herr Präsident, vor Krieg und Armut fliehende Massen stehen an den Grenzen; Lager und Städte sind überlastet. Was tun wir?",
  "Señor, multitudes que huyen de la guerra y la pobreza han llegado a las fronteras; campamentos y ciudades están al límite. ¿Qué hacemos?",
  "Monsieur, des foules fuyant la guerre et la misère sont arrivées aux frontières ; les camps et les villes sont sous tension. Que faisons-nous ?",
  "Signore, masse in fuga da guerra e povertà sono arrivate ai confini; campi e città sono sotto pressione. Che facciamo?",
  "Senhor, multidões que fogem da guerra e da pobreza chegaram às fronteiras; campos e cidades estão sob pressão. O que fazemos?",
  "Господин, толпы людей, бегущих от войны и нищеты, подошли к границам; лагеря и города перегружены. Что делаем?",
  "سيدي، حشود هاربة من الحرب والفقر وصلت إلى الحدود؛ والمخيمات والمدن تحت الضغط. ماذا نفعل؟",
  "قربان، انبوه گریزان از جنگ و فقر به مرزها رسیده‌اند؛ اردوگاه‌ها و شهرها زیر فشارند. چه کنیم؟",
  "阁下，逃离战争与贫困的大批民众已涌到边境，难民营和城市不堪重负。我们该怎么办？",
  "閣下、戦争と貧困から逃れた人々が国境に押し寄せ、キャンプも都市も限界です。どうしますか？",
  "각하, 전쟁과 빈곤을 피해 온 대규모 인파가 국경에 몰려 수용소와 도시가 한계에 이르렀습니다. 어떻게 할까요?",
  "महोदय, युद्ध और गरीबी से भागते लोग सीमाओं तक आ पहुँचे हैं; शिविर और शहर दबाव में हैं। हम क्या करें?")
a("Efendim, nehirler çekiliyor ve ekinler kuruyor; sulama ve içme suyu sıkıntısı başladı. Ne yapalım?",
  "Sir, rivers are receding and crops are withering; irrigation and drinking water shortages have begun. What do we do?",
  "Herr Präsident, die Flüsse gehen zurück und die Ernten vertrocknen; Bewässerung und Trinkwasser werden knapp. Was tun wir?",
  "Señor, los ríos retroceden y los cultivos se secan; ha comenzado la escasez de agua para riego y consumo. ¿Qué hacemos?",
  "Monsieur, les rivières se retirent et les cultures se dessèchent ; l'eau d'irrigation et l'eau potable viennent à manquer. Que faisons-nous ?",
  "Signore, i fiumi si ritirano e i raccolti seccano; sono iniziate le carenze di acqua per irrigazione e uso potabile. Che facciamo?",
  "Senhor, os rios recuam e as lavouras secam; começou a falta de água para irrigação e consumo. O que fazemos?",
  "Господин, реки мелеют, посевы сохнут; начался дефицит воды для орошения и питья. Что делаем?",
  "سيدي، الأنهار تتراجع والمحاصيل تذبل؛ وبدأ نقص مياه الري والشرب. ماذا نفعل؟",
  "قربان، رودخانه‌ها پس می‌نشینند و محصولات می‌خشکند؛ کمبود آب آبیاری و آشامیدنی آغاز شده است. چه کنیم؟",
  "阁下，河流水位下降，庄稼枯萎，灌溉和饮用水短缺已经出现。我们该怎么办？",
  "閣下、河川の水位が下がり作物が枯れ、灌漑用水と飲料水の不足が始まっています。どうしますか？",
  "각하, 강물이 줄고 작물이 말라 관개용수와 식수 부족이 시작되었습니다. 어떻게 할까요?",
  "महोदय, नदियाँ सिकुड़ रही हैं और फसलें सूख रही हैं; सिंचाई और पेयजल की कमी शुरू हो गई है। हम क्या करें?")
a("Efendim, fabrikalarda ve limanlarda grevler art arda başlıyor; üretim ve ihracat aksıyor. Ne yapalım?",
  "Sir, strikes are breaking out one after another in factories and ports; production and exports are stalling. What do we do?",
  "Herr Präsident, in Fabriken und Häfen brechen Streiks nacheinander aus; Produktion und Export stocken. Was tun wir?",
  "Señor, estallan huelgas una tras otra en fábricas y puertos; la producción y las exportaciones se paralizan. ¿Qué hacemos?",
  "Monsieur, les grèves se succèdent dans les usines et les ports ; la production et les exportations se bloquent. Que faisons-nous ?",
  "Signore, gli scioperi scoppiano uno dopo l'altro in fabbriche e porti; produzione ed esportazioni si bloccano. Che facciamo?",
  "Senhor, greves eclodem uma após a outra em fábricas e portos; produção e exportações estão paradas. O que fazemos?",
  "Господин, на заводах и в портах одна за другой вспыхивают забастовки; производство и экспорт встают. Что делаем?",
  "سيدي، تندلع الإضرابات تباعاً في المصانع والموانئ؛ والإنتاج والتصدير يتعطلان. ماذا نفعل؟",
  "قربان، اعتصاب‌ها یکی پس از دیگری در کارخانه‌ها و بنادر آغاز می‌شود؛ تولید و صادرات متوقف شده است. چه کنیم؟",
  "阁下，工厂和港口的罢工接连爆发，生产和出口陷入停滞。我们该怎么办？",
  "閣下、工場や港でストが相次ぎ、生産と輸出が止まっています。どうしますか？",
  "각하, 공장과 항만에서 파업이 잇따라 일어나 생산과 수출이 멈추고 있습니다. 어떻게 할까요?",
  "महोदय, कारखानों और बंदरगाहों में हड़तालें एक के बाद एक शुरू हो रही हैं; उत्पादन और निर्यात ठप हो रहे हैं। हम क्या करें?")

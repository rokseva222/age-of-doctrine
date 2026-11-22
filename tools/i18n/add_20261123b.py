# -*- coding: utf-8 -*-
# 2026-11-23: hava filosu sipariş kısayolu, ittifaksız başla ayarı, bütçe göstergeleri notu. Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a("Uçak ve İHA siparişi ver", "Order aircraft and drones", "Flugzeuge und Drohnen bestellen", "Pedir aviones y drones", "Commander avions et drones", "Ordina aerei e droni", "Encomendar aviões e drones", "Заказать самолёты и дроны", "اطلب طائرات ومسيّرات", "سفارش هواپیما و پهپاد", "订购飞机和无人机", "航空機とドローンを発注", "항공기와 드론 주문", "विमान और ड्रोन का ऑर्डर दें")
a("Filoyu büyütmek için yeni uçak ve İHA siparişi ver: teslimatta hava gücün ve filoların büyür.",
  "To grow your wing, order new aircraft and drones: on delivery your air power and wings grow.",
  "Um dein Geschwader zu vergrößern, bestelle neue Flugzeuge und Drohnen: Bei Lieferung wachsen deine Luftmacht und deine Geschwader.",
  "Para ampliar tu ala, pide nuevos aviones y drones: al entregarse crecen tu poder aéreo y tus alas.",
  "Pour renforcer ton escadre, commande de nouveaux avions et drones : à la livraison, ta puissance aérienne et tes escadres augmentent.",
  "Per ingrandire lo stormo, ordina nuovi aerei e droni: alla consegna crescono la tua potenza aerea e gli stormi.",
  "Para aumentar sua ala, encomende novos aviões e drones: na entrega seu poder aéreo e suas alas crescem.",
  "Чтобы увеличить авиакрыло, закажи новые самолёты и дроны: после поставки растут твоя авиамощь и крылья.",
  "لتوسيع جناحك الجوي، اطلب طائرات ومسيّرات جديدة: عند التسليم تنمو قوتك الجوية وأجنحتك.",
  "برای بزرگ‌تر کردن ناوگان هوایی، هواپیما و پهپاد جدید سفارش بده: با تحویل، قدرت هوایی و ناوگان‌هایت رشد می‌کند.",
  "要扩大航空联队，请订购新的飞机和无人机：交付后你的空中力量和联队会增长。",
  "航空団を拡大するには新しい航空機とドローンを発注してください。納入時に航空戦力と航空団が増強されます。",
  "항공단을 키우려면 새 항공기와 드론을 주문하세요. 인도되면 공군력과 항공단이 늘어납니다.",
  "अपने वायु बेड़े को बढ़ाने के लिए नए विमान और ड्रोन का ऑर्डर दें: डिलीवरी पर आपकी वायु शक्ति और बेड़े बढ़ते हैं।")
a("İttifaksız başla", "Start without alliances", "Ohne Bündnisse starten", "Empezar sin alianzas", "Commencer sans alliances", "Inizia senza alleanze", "Começar sem alianças", "Начинать без союзов", "ابدأ بلا تحالفات", "بدون اتحاد شروع کن", "无同盟开局", "同盟なしで開始", "동맹 없이 시작", "गठबंधन के बिना शुरू करें")
a("Açıkken yeni oyuna, seçtiğin ülkenin hazır ittifakları olmadan başlarsın; müttefikleri kendin seçersin. Vasal bağları silinmez. Yeni başlayan oyunlarda geçerlidir.",
  "When on, a new game starts without your country's ready-made alliances; you choose your allies yourself. Vassal ties are kept. Applies to newly started games.",
  "Wenn aktiv, startest du ein neues Spiel ohne die vorgegebenen Bündnisse deines Landes; Verbündete wählst du selbst. Vasallenbindungen bleiben. Gilt für neu gestartete Spiele.",
  "Activado, una partida nueva empieza sin las alianzas ya hechas de tu país; tú eliges a tus aliados. Los lazos de vasallaje se mantienen. Vale para partidas nuevas.",
  "Activé, une nouvelle partie commence sans les alliances toutes faites de ton pays ; tu choisis tes alliés. Les liens de vassalité restent. S'applique aux nouvelles parties.",
  "Se attivo, una nuova partita inizia senza le alleanze già pronte del tuo paese; scegli tu gli alleati. I vincoli di vassallaggio restano. Vale per le nuove partite.",
  "Ativado, um novo jogo começa sem as alianças prontas do seu país; você escolhe os aliados. Vínculos de vassalagem permanecem. Vale para jogos novos.",
  "Если включено, новая игра начинается без готовых союзов твоей страны; союзников выбираешь сам. Вассальные связи сохраняются. Действует для новых игр.",
  "عند التفعيل تبدأ اللعبة الجديدة دون التحالفات الجاهزة لبلدك؛ وتختار حلفاءك بنفسك. تبقى روابط التبعية. يسري على الألعاب الجديدة.",
  "در حالت روشن، بازی جدید بدون اتحادهای آماده کشورت آغاز می‌شود؛ متحدان را خودت انتخاب می‌کنی. پیوندهای دست‌نشاندگی می‌ماند. برای بازی‌های تازه اعمال می‌شود。".replace("。", "."),
  "开启后，新游戏开局时不带你所选国家现成的同盟，盟友由你自己选择。附庸关系保留。对新开始的游戏生效。",
  "オンにすると、新しいゲームは選んだ国の既存の同盟なしで始まり、同盟国は自分で選びます。従属関係は残ります。新規ゲームに適用されます。",
  "켜면 새 게임이 선택한 국가의 기존 동맹 없이 시작되며, 동맹은 직접 고릅니다. 속국 관계는 유지됩니다. 새로 시작하는 게임에 적용됩니다.",
  "चालू होने पर नया खेल आपके देश के पहले से बने गठबंधनों के बिना शुरू होता है; सहयोगी आप खुद चुनते हैं। जागीरदारी संबंध बने रहते हैं। नए शुरू किए गए खेलों पर लागू।")
a("Sanayi, siber ve lojistik değerleri ilgili bütçe payını yükselttikçe haftalar içinde artar; istikrar da öyle. Teknoloji ülkenin gelişmişlik düzeyidir, bütçeyle değişmez: hangi seviyede silah alabildiğini ve ordu kalitesini belirler. Üst seviye silahlar için ayrıca yeterli sanayi gerekir: Sanayi payını yükselt.",
  "Industry, cyber and logistics rise over weeks as you raise their budget share; so does stability. Technology is your country's development level and does not change with the budget: it sets which weapon tiers you can buy and your army quality. Top-tier weapons also need enough industry: raise the Industry share.",
  "Industrie, Cyber und Logistik steigen über Wochen, wenn du ihren Haushaltsanteil erhöhst; ebenso die Stabilität. Technologie ist der Entwicklungsstand deines Landes und ändert sich nicht mit dem Haushalt: Sie bestimmt, welche Waffenstufen du kaufen kannst, und die Armeequalität. Hochstufige Waffen brauchen zudem genug Industrie: Erhöhe den Industrieanteil.",
  "Industria, ciber y logística suben en semanas al aumentar su parte del presupuesto; la estabilidad también. La tecnología es el nivel de desarrollo de tu país y no cambia con el presupuesto: define qué niveles de armas puedes comprar y la calidad del ejército. Las armas de alto nivel exigen además suficiente industria: sube la parte de Industria.",
  "L'industrie, le cyber et la logistique montent en quelques semaines quand tu augmentes leur part du budget ; la stabilité aussi. La technologie est le niveau de développement de ton pays et ne change pas avec le budget : elle fixe les niveaux d'armes achetables et la qualité de l'armée. Les armes haut de gamme exigent aussi assez d'industrie : augmente la part Industrie.",
  "Industria, cyber e logistica crescono nel giro di settimane se ne alzi la quota di bilancio; così anche la stabilità. La tecnologia è il livello di sviluppo del tuo paese e non cambia con il bilancio: stabilisce quali livelli di armi puoi comprare e la qualità dell'esercito. Le armi di fascia alta richiedono anche abbastanza industria: aumenta la quota Industria.",
  "Indústria, ciber e logística sobem em semanas conforme você aumenta sua fatia do orçamento; a estabilidade também. A tecnologia é o nível de desenvolvimento do seu país e não muda com o orçamento: define quais níveis de armas você pode comprar e a qualidade do exército. Armas de topo também exigem indústria suficiente: aumente a fatia da Indústria.",
  "Промышленность, кибер и логистика растут в течение недель при увеличении их доли бюджета; стабильность тоже. Технологии — уровень развития страны, от бюджета не зависят: они определяют, какие классы оружия можно купить, и качество армии. Для оружия высшего класса нужна и достаточная промышленность: повысь долю промышленности.",
  "ترتفع الصناعة والسيبراني واللوجستيات خلال أسابيع كلما زدت حصتها من الميزانية؛ وكذلك الاستقرار. أما التكنولوجيا فهي مستوى تطور بلدك ولا تتغير بالميزانية: تحدد مستويات الأسلحة التي يمكنك شراؤها وجودة الجيش. الأسلحة الأعلى مستوى تتطلب صناعة كافية أيضاً: ارفع حصة الصناعة.",
  "با افزایش سهم بودجه، صنعت و سایبری و لجستیک طی چند هفته بالا می‌روند؛ ثبات هم همین‌طور. فناوری سطح توسعه کشور است و با بودجه تغییر نمی‌کند: تعیین می‌کند چه سطحی از سلاح بخری و کیفیت ارتش چقدر است. سلاح‌های رده‌بالا صنعت کافی هم می‌خواهند: سهم صنعت را بالا ببر.",
  "提高相应预算份额后，工业、网络和后勤数值会在数周内上升，稳定度同理。科技是国家的发展水平，不随预算变化：它决定你能购买的武器等级和军队质量。高阶武器还需要足够的工业：请提高工业份额。",
  "予算配分を上げると、産業・サイバー・兵站の値は数週間で上昇し、安定度も同様です。技術は国の発展度で、予算では変わりません。購入できる兵器の等級と軍の質を決めます。上位兵器には十分な産業力も必要です。産業の配分を上げてください。",
  "예산 비중을 올리면 산업·사이버·병참 수치가 몇 주에 걸쳐 오르고, 안정도도 마찬가지입니다. 기술은 국가의 발전 수준으로 예산으로는 변하지 않으며, 살 수 있는 무기 등급과 군의 질을 결정합니다. 상위 무기에는 충분한 산업도 필요합니다. 산업 비중을 높이세요.",
  "संबंधित बजट हिस्सा बढ़ाने पर उद्योग, साइबर और लॉजिस्टिक्स कुछ हफ्तों में बढ़ते हैं; स्थिरता भी। प्रौद्योगिकी आपके देश का विकास स्तर है और बजट से नहीं बदलती: यह तय करती है कि आप किस स्तर के हथियार खरीद सकते हैं और सेना की गुणवत्ता कैसी है। उच्च स्तर के हथियारों के लिए पर्याप्त उद्योग भी चाहिए: उद्योग का हिस्सा बढ़ाएँ।")

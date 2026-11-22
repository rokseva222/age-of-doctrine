# -*- coding: utf-8 -*-
# 2026-11-23: Mihver Dünyası (alt_axis62) isimleri. Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a("Büyük Alman Reich'ı", "Greater German Reich", "Großdeutsches Reich", "Gran Reich Alemán", "Grand Reich allemand", "Grande Reich tedesco", "Grande Reich Alemão", "Великогерманский рейх", "الرايخ الألماني الأكبر", "رایش بزرگ آلمان", "大德意志帝国", "大ドイツ帝国", "대독일 제국", "महान जर्मन रीख")
a("Rus Kalıntı Devleti", "Russian Rump State", "Russischer Reststaat", "Estado residual ruso", "État résiduel russe", "Stato russo residuo", "Estado residual russo", "Остаточное Российское государство", "الدولة الروسية المتبقية", "دولت باقی‌مانده روسیه", "俄罗斯残余国家", "ロシア残存国家", "러시아 잔존국", "रूसी अवशेष राज्य")
a("Japon İmparatorluğu", "Empire of Japan", "Kaiserreich Japan", "Imperio del Japón", "Empire du Japon", "Impero giapponese", "Império do Japão", "Японская империя", "إمبراطورية اليابان", "امپراتوری ژاپن", "大日本帝国", "大日本帝国", "일본 제국", "जापान साम्राज्य")
a("Reich Amerikası", "Reich America", "Reich-Amerika", "América del Reich", "Amérique du Reich", "America del Reich", "América do Reich", "Рейх-Америка", "أمريكا الرايخ", "آمریکای رایش", "帝国美洲", "帝国アメリカ", "제국 아메리카", "रीख अमेरिका")
a("Japon Pasifik Devletleri", "Japanese Pacific States", "Japanische Pazifikstaaten", "Estados japoneses del Pacífico", "États japonais du Pacifique", "Stati giapponesi del Pacifico", "Estados japoneses do Pacífico", "Японские тихоокеанские штаты", "ولايات المحيط الهادئ اليابانية", "ایالت‌های اقیانوس آرام ژاپن", "日本太平洋诸州", "日本太平洋諸州", "일본 태평양 주", "जापानी प्रशांत राज्य")
a("Kayalık Dağlar Tarafsız Bölgesi", "Rocky Mountain Neutral Zone", "Neutrale Zone der Rocky Mountains", "Zona neutral de las Montañas Rocosas", "Zone neutre des Montagnes Rocheuses", "Zona neutrale delle Montagne Rocciose", "Zona neutra das Montanhas Rochosas", "Нейтральная зона Скалистых гор", "المنطقة المحايدة في جبال روكي", "منطقه بی‌طرف کوه‌های راکی", "落基山中立区", "ロッキー山脈中立地帯", "로키산맥 중립 지대", "रॉकी पर्वत तटस्थ क्षेत्र")
a("Mihver Düzeni", "Axis Order", "Achsenordnung", "Orden del Eje", "Ordre de l'Axe", "Ordine dell'Asse", "Ordem do Eixo", "Порядок Оси", "نظام المحور", "نظم محور", "轴心秩序", "枢軸秩序", "추축 질서", "धुरी व्यवस्था")
a("Mihver Dünyası", "The Axis World", "Die Welt der Achse", "El mundo del Eje", "Le monde de l'Axe", "Il mondo dell'Asse", "O mundo do Eixo", "Мир Оси", "عالم المحور", "جهان محور", "轴心世界", "枢軸の世界", "추축의 세계", "धुरी की दुनिया")
a("1962 – Alternatif", "1962 – Alternate", "1962 – Alternativ", "1962 – Alternativo", "1962 – Alternatif", "1962 – Alternativo", "1962 – Alternativo", "1962 – Альтернатива", "1962 – بديل", "۱۹۶۲ – جایگزین", "1962 – 架空", "1962 – もしも", "1962 – 대체역사", "1962 – वैकल्पिक")
a("Reich Valisi", "Reich Governor", "Reichsstatthalter", "Gobernador del Reich", "Gouverneur du Reich", "Governatore del Reich", "Governador do Reich", "Имперский наместник", "حاكم الرايخ", "فرماندار رایش", "帝国总督", "帝国総督", "제국 총독", "रीख गवर्नर")
a("Genel Vali", "Governor-General", "Generalgouverneur", "Gobernador general", "Gouverneur général", "Governatore generale", "Governador-geral", "Генерал-губернатор", "الحاكم العام", "فرماندار کل", "总督", "総督", "총독", "गवर्नर-जनरल")
a("Reich Şansölyesi", "Reich Chancellor", "Reichskanzler", "Canciller del Reich", "Chancelier du Reich", "Cancelliere del Reich", "Chanceler do Reich", "Рейхсканцлер", "مستشار الرايخ", "صدراعظم رایش", "帝国总理", "帝国宰相", "제국 총리", "रीख चांसलर")

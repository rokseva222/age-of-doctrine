# -*- coding: utf-8 -*-
# 2026-11-23: Kuzey Kafkasya cumhuriyetleri adları. Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a("Çeçenistan (Içkerya)", "Chechnya (Ichkeria)", "Tschetschenien (Itschkerien)", "Chechenia (Ichkeria)", "Tchétchénie (Itchkérie)", "Cecenia (Ichkeria)", "Chechênia (Ichkeria)", "Чечня (Ичкерия)", "الشيشان (إشكيريا)", "چچن (ایچکریا)", "车臣（伊奇克里亚）", "チェチェン（イチケリア）", "체첸(이츠케리아)", "चेचन्या (इचकेरिया)")
a("Kabardey-Balkarya", "Kabardino-Balkaria", "Kabardino-Balkarien", "Kabardia-Balkaria", "Kabardino-Balkarie", "Cabardino-Balcaria", "Cabárdia-Balcária", "Кабардино-Балкария", "قباردينو بلقاريا", "کاباردینو-بالکاریا", "卡巴尔达-巴尔卡尔", "カバルダ・バルカル", "카바르디노발카리야", "काबार्डिनो-बल्कारिया")
a("Karaçay-Çerkesya", "Karachay-Cherkessia", "Karatschai-Tscherkessien", "Karacháyevo-Cherkesia", "Karatchaïévo-Tcherkessie", "Karačaj-Circassia", "Karachay-Circássia", "Карачаево-Черкесия", "قراتشاي-شركيسيا", "قره‌چای-چرکس", "卡拉恰伊-切尔克斯", "カラチャイ・チェルケス", "카라차이체르케스", "कराचाय-चर्केसिया")
a("Adigey", "Adygea", "Adygeja", "Adiguesia", "Adyguée", "Adighezia", "Adigueia", "Адыгея", "أديغيا", "آدیگه", "阿迪格", "アディゲ", "아디게야", "अदिगेया")
a("Kuzey Osetya-Alanya", "North Ossetia-Alania", "Nordossetien-Alanien", "Osetia del Norte-Alania", "Ossétie du Nord-Alanie", "Ossezia settentrionale-Alania", "Ossétia do Norte-Alânia", "Северная Осетия — Алания", "أوسيتيا الشمالية-ألانيا", "اوستیای شمالی-آلانیا", "北奥塞梯-阿兰", "北オセチア＝アラニア", "북오세티야알라니야", "उत्तरी ओसेशिया-अलानिया")
a("Kalmıkya", "Kalmykia", "Kalmückien", "Kalmukia", "Kalmoukie", "Calmucchia", "Calmúquia", "Калмыкия", "كالميكيا", "کالمیکیا", "卡尔梅克", "カルムイク", "칼미크", "काल्मिकिया")

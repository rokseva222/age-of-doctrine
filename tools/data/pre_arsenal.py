# -*- coding: utf-8 -*-
"""İlk barut çağı (1520) ve ortaçağ sonu (1380) silah tabloları. Kategoriler oyundaki altı sınıfa eşlenir:
inf = piyade, tank = ağır süvari, afv = hafif süvari, arty = kuşatma/top, air = yok, sub = savaş gemisi."""

CAT_NAMES = {"inf": "Piyade", "tank": "Ağır Süvari", "afv": "Hafif Süvari", "arty": "Top ve Kuşatma", "air": "—", "sub": "Savaş Gemisi"}
NONE = ["f_none"] * 4


def _bloc(inf, tank, afv, arty, sub):
    return {"inf": inf, "tank": tank, "afv": afv, "arty": arty, "air": NONE, "sub": sub}


def ottoman_1520():
    items = {
        # ---- piyade (1.000 kişilik set)
        "i_levy": ["Köylü Mızraklı Milis", "inf", "Poland", 1, 0.08, True],
        "i_azap": ["Azap Yaylı Piyadesi", "inf", "Turkey", 1, 0.12, True],
        "i_pike": ["Pike ve Kılıç Piyadesi", "inf", "Germany", 2, 0.22, True],
        "i_jani": ["Yeniçeri Ocağı (Fitilli Tüfek)", "inf", "Turkey", 3, 0.42, True],
        "i_jani2": ["Yeniçeri Tüfek + Humbara Bölükleri", "inf", "Turkey", 4, 0.55, True],
        "i_lands": ["Landsknecht (Pike + Arkebüz)", "inf", "Germany", 3, 0.38, True],
        "i_tercio": ["Tercio", "inf", "Spain", 4, 0.52, True],
        "i_swiss": ["İsviçre Pikecileri", "inf", "Switzerland", 3, 0.33, True],
        "i_arqfr": ["Arkebüzcü Bölükleri", "inf", "France", 3, 0.36, True],
        "i_longbow": ["Uzun Yay Okçuları", "inf", "United Kingdom", 2, 0.18, True],
        "i_kizil": ["Kızılbaş Piyadesi", "inf", "Iran", 2, 0.18, True],
        "i_tofang": ["Tofangçi Tüfekçileri", "inf", "Iran", 3, 0.36, True],
        "i_ming": ["Ming Mızrak ve Kılıç Piyadesi", "inf", "China", 2, 0.18, True],
        "i_mingf": ["Ming Ateşli Silah Birlikleri", "inf", "China", 3, 0.34, True],
        "i_ashig": ["Aşigaru (Mızrak + Tanegashima)", "inf", "Japan", 3, 0.30, True],
        "i_tribal": ["Kabile Savaşçıları", "inf", "Ethiopia", 1, 0.06, True],
        "i_bow2": ["Kompozit Yaylı Piyade", "inf", "India", 2, 0.14, True],
        "i_mughal": ["Babürlü Tüfekçiler", "inf", "Afghanistan", 3, 0.38, True],
        # ---- ağır süvari (adet)
        "t_sipahi": ["Tımarlı Sipahi", "tank", "Turkey", 2, 0.020, True],
        "t_kapikulu": ["Kapıkulu Süvarisi", "tank", "Turkey", 3, 0.032, True],
        "t_knight": ["Zırhlı Şövalye Süvarisi", "tank", "France", 2, 0.025, True],
        "t_gend": ["Gendarmes (Ağır Şövalye)", "tank", "France", 3, 0.036, True],
        "t_reiter": ["Reiter (Tabancalı Süvari)", "tank", "Germany", 3, 0.030, True],
        "t_hussar": ["Kanatlı Hussar", "tank", "Poland", 3, 0.030, True],
        "t_kizilc": ["Kızılbaş Ağır Süvarisi", "tank", "Iran", 2, 0.022, True],
        "t_ming_c": ["Ming Zırhlı Süvarisi", "tank", "China", 2, 0.020, True],
        "t_samurai": ["Samuray Süvarisi", "tank", "Japan", 2, 0.022, True],
        "t_boyar": ["Boyar Atlıları", "tank", "Russia", 2, 0.018, True],
        "t_eleph": ["Savaş Fili Birlikleri", "tank", "India", 2, 0.050, True],
        "t_tribe_c": ["Kabile Süvari Mızraklıları", "tank", "Mongolia", 1, 0.010, True],
        # ---- hafif süvari (adet)
        "a_akinci": ["Akıncı Süvarisi", "afv", "Turkey", 1, 0.008, True],
        "a_deli": ["Deli ve Tatar Atlıları", "afv", "Turkey", 2, 0.010, True],
        "a_hussar_l": ["Hafif Hussar", "afv", "Hungary", 2, 0.010, True],
        "a_strad": ["Stradyot Hafif Süvarisi", "afv", "Italy", 2, 0.010, True],
        "a_horsearch": ["Atlı Okçular", "afv", "Mongolia", 1, 0.006, True],
        "a_tatar": ["Kırım Tatar Süvarisi", "afv", "Ukraine", 2, 0.008, True],
        "a_ming_l": ["Ming Hafif Süvarisi", "afv", "China", 1, 0.007, True],
        "a_rajput": ["Racput Süvarisi", "afv", "India", 2, 0.010, True],
        # ---- top ve kuşatma (adet)
        "y_catap": ["Mancınık ve Kuşatma Kuleleri", "arty", "Germany", 1, 0.05, True],
        "y_bombard": ["Şahi Bombardı", "arty", "Turkey", 2, 0.15, True],
        "y_darb": ["Darbzen Saha Topu", "arty", "Turkey", 3, 0.22, True],
        "y_basil": ["Balyemez (Ağır Duvar Kıran Top)", "arty", "Turkey", 4, 0.40, True],
        "y_culv": ["Kulevrin", "arty", "France", 3, 0.20, True],
        "y_falc": ["Falkonet ve Sakr", "arty", "Germany", 3, 0.15, True],
        "y_rocket": ["Ateşli Ok ve Roketler", "arty", "China", 1, 0.06, True],
        "y_fo": ["Fo-lang-chi Topu", "arty", "China", 3, 0.18, True],
        # ---- gemiler (adet)
        "s_dhow": ["Kürekli Savaş Gemisi / Dhow", "sub", "Oman", 1, 0.5, True],
        "s_galley": ["Kadırga", "sub", "Turkey", 1, 0.8, True],
        "s_cog": ["Kogge Savaş Gemisi", "sub", "Denmark", 1, 0.6, True],
        "s_carrack": ["Karaka", "sub", "Portugal", 2, 1.2, True],
        "s_kalite": ["Kalite / Kalyon", "sub", "Turkey", 3, 1.4, True],
        "s_galleass": ["Galyas", "sub", "Italy", 3, 1.6, True],
        "s_galleon": ["Galyon", "sub", "Spain", 4, 2.5, True],
        "s_junk": ["Savaş Cunk'ı", "sub", "China", 2, 0.8, True],
        # ---- hava yok
        "f_none": ["—", "air", "Turkey", 1, 0.0, False],
    }
    bloc = {
        "tr": _bloc(["i_azap", "i_azap", "i_jani", "i_jani2"], ["t_sipahi", "t_sipahi", "t_kapikulu", "t_kapikulu"],
                    ["a_akinci", "a_akinci", "a_deli", "a_deli"], ["y_bombard", "y_bombard", "y_darb", "y_basil"],
                    ["s_galley", "s_galley", "s_kalite", "s_kalite"]),
        "eu": _bloc(["i_levy", "i_pike", "i_lands", "i_tercio"], ["t_knight", "t_knight", "t_gend", "t_reiter"],
                    ["a_strad", "a_strad", "a_hussar_l", "a_hussar_l"], ["y_catap", "y_falc", "y_culv", "y_culv"],
                    ["s_cog", "s_carrack", "s_galleass", "s_galleon"]),
        "ir": _bloc(["i_kizil", "i_kizil", "i_tofang", "i_tofang"], ["t_kizilc", "t_kizilc", "t_kizilc", "t_kizilc"],
                    ["a_horsearch", "a_tatar", "a_rajput", "a_deli"], ["y_catap", "y_bombard", "y_bombard", "y_darb"],
                    ["s_dhow", "s_dhow", "s_galley", "s_galley"]),
        "as": _bloc(["i_ming", "i_ming", "i_mingf", "i_ashig"], ["t_ming_c", "t_samurai", "t_ming_c", "t_samurai"],
                    ["a_ming_l", "a_ming_l", "a_horsearch", "a_horsearch"], ["y_rocket", "y_rocket", "y_fo", "y_fo"],
                    ["s_junk", "s_junk", "s_junk", "s_junk"]),
        "ot": _bloc(["i_tribal", "i_bow2", "i_bow2", "i_levy"], ["t_tribe_c", "t_tribe_c", "t_tribe_c", "t_tribe_c"],
                    ["a_horsearch", "a_horsearch", "a_tatar", "a_tatar"], ["y_catap", "y_catap", "y_rocket", "y_rocket"],
                    ["s_dhow", "s_dhow", "s_dhow", "s_dhow"]),
    }
    family = {
        "Poland": {"tank": ["t_hussar"] * 4, "afv": ["a_hussar_l"] * 4},
        "Russia": {"tank": ["t_boyar"] * 4, "afv": ["a_tatar"] * 4},
        "Japan": {"inf": ["i_ming", "i_ming", "i_ashig", "i_ashig"], "tank": ["t_samurai"] * 4},
        "India": {"inf": ["i_bow2", "i_bow2", "i_bow2", "i_bow2"], "tank": ["t_eleph"] * 4, "afv": ["a_rajput"] * 4},
        "Afghanistan": {"inf": ["i_bow2", "i_bow2", "i_mughal", "i_mughal"], "afv": ["a_horsearch", "a_horsearch", "a_rajput", "a_rajput"]},
        "Mongolia": {"tank": ["t_tribe_c"] * 4, "afv": ["a_horsearch"] * 4},
        "Kazakhstan": {"afv": ["a_horsearch"] * 4},
        "Uzbekistan": {"inf": ["i_kizil", "i_kizil", "i_kizil", "i_tofang"], "afv": ["a_horsearch"] * 4},
        "United Kingdom": {"inf": ["i_longbow", "i_longbow", "i_pike", "i_pike"]},
        "Switzerland": {"inf": ["i_swiss"] * 4},
        "Ethiopia": {"inf": ["i_tribal"] * 4},
    }
    bloc_of = {
        "Turkey": "tr", "Algeria": "tr", "Egypt": "tr", "Tunisia": "tr",
        "Spain": "eu", "Germany": "eu", "France": "eu", "Italy": "eu", "Poland": "eu", "Hungary": "eu", "Russia": "eu", "Portugal": "eu",
        "United Kingdom": "eu", "Denmark": "eu", "Sweden": "eu", "Switzerland": "eu", "Romania": "eu", "Latvia": "eu", "Malta": "eu", "Georgia": "eu",
        "Ukraine": "ir", "Iran": "ir", "Uzbekistan": "ir", "Afghanistan": "ir", "India": "ir", "Kazakhstan": "ir", "Pakistan": "ir", "Sri Lanka": "ir",
        "Bangladesh": "ir", "Oman": "ir", "United Arab Emirates": "ir", "Saudi Arabia": "ir", "Yemen": "ir", "Moldova": "ir",
        "China": "as", "Japan": "as", "South Korea": "as", "Vietnam": "as", "Thailand": "as", "Myanmar": "as", "Indonesia": "as", "Malaysia": "as",
        "Cambodia": "as", "Laos": "as", "Philippines": "as", "Mongolia": "ir", "Bhutan": "as",
    }
    tech = {"Turkey": 0.58, "Spain": 0.52, "France": 0.48, "Germany": 0.46, "Italy": 0.52, "China": 0.5, "Iran": 0.38, "Poland": 0.32,
            "Russia": 0.3, "Japan": 0.36, "India": 0.28, "Hungary": 0.34, "United Kingdom": 0.36, "Portugal": 0.44, "Afghanistan": 0.34,
            "Uzbekistan": 0.3, "Algeria": 0.42, "Switzerland": 0.4}
    gate = {"i_jani2": 100, "i_tercio": 60, "y_basil": 90, "s_galleon": 140, "i_mughal": 30, "i_ashig": 1100, "s_kalite": 40, "y_darb": 20,
            "t_reiter": 90, "t_gend": 20, "s_galleass": 30, "i_tofang": 40, "y_fo": 20, "i_mingf": 10}
    return {"items": items, "bloc": bloc, "family": family, "bloc_of": bloc_of, "tech": tech, "new": [], "gate": gate, "cat_names": CAT_NAMES}


def timurid_1380():
    items = {
        # ---- piyade
        "i_levy": ["Köylü Mızraklı Milis", "inf", "Poland", 1, 0.06, True],
        "i_archer": ["Yaya Okçu / Arbaletçi", "inf", "Germany", 2, 0.12, True],
        "i_sword": ["Kılıç ve Kalkan Piyadesi", "inf", "Turkey", 2, 0.14, True],
        "i_halb": ["Teber ve Pike Müfrezeleri", "inf", "Switzerland", 3, 0.20, True],
        "i_guard": ["Muhafız Piyadesi", "inf", "Uzbekistan", 3, 0.24, True],
        "i_firelance": ["Ateş Mızrağı Birlikleri", "inf", "China", 4, 0.30, True],
        "i_longbow": ["Uzun Yay Okçuları", "inf", "United Kingdom", 3, 0.18, True],
        "i_tribal": ["Kabile Savaşçıları", "inf", "Ethiopia", 1, 0.05, True],
        # ---- ağır süvari
        "t_cata": ["Kataphrakt Tipi Zırhlı Atlı", "tank", "Greece", 2, 0.016, True],
        "t_knight": ["Zırhlı Şövalye Süvarisi", "tank", "France", 3, 0.025, True],
        "t_mamluk": ["Memlük Ağır Süvarisi", "tank", "Egypt", 3, 0.026, True],
        "t_timur": ["Timurlu Zırhlı Süvarisi", "tank", "Uzbekistan", 3, 0.022, True],
        "t_keshik": ["Keşik (Muhafız Atlıları)", "tank", "Mongolia", 4, 0.030, True],
        "t_ming_c": ["Ming Zırhlı Süvarisi", "tank", "China", 2, 0.020, True],
        "t_druzhina": ["Druzhina (Knez Atlıları)", "tank", "Russia", 2, 0.017, True],
        "t_lith": ["Litvanya Zırhlı Atlıları", "tank", "Lithuania", 2, 0.017, True],
        "t_eleph": ["Savaş Fili Birlikleri", "tank", "India", 3, 0.050, True],
        "t_tribe_c": ["Kabile Süvari Mızraklıları", "tank", "Mongolia", 1, 0.010, True],
        # ---- hafif süvari
        "a_horsearch": ["Atlı Okçular (Bozkır)", "afv", "Kazakhstan", 2, 0.006, True],
        "a_turkmen": ["Türkmen Atlıları", "afv", "Turkmenistan", 1, 0.006, True],
        "a_akinci": ["Akıncı Süvarisi", "afv", "Turkey", 2, 0.008, True],
        "a_tatar": ["Tatar Süvarisi (Altın Orda)", "afv", "Ukraine", 2, 0.007, True],
        "a_ming_l": ["Ming Hafif Süvarisi", "afv", "China", 1, 0.007, True],
        "a_rajput": ["Racput Süvarisi", "afv", "India", 2, 0.010, True],
        "a_camel": ["Deve ve Bedevi Süvarisi", "afv", "Saudi Arabia", 1, 0.005, True],
        # ---- kuşatma ve top
        "y_catap": ["Mancınık", "arty", "Germany", 1, 0.05, True],
        "y_ram": ["Kuşatma Kulesi ve Koçbaşı", "arty", "Turkey", 1, 0.04, True],
        "y_trebu": ["Karşı Ağırlıklı Mancınık", "arty", "Italy", 2, 0.09, True],
        "y_rocket": ["Ateşli Ok ve Roketler", "arty", "China", 3, 0.07, True],
        "y_bombard": ["İlkel Bombard", "arty", "Italy", 4, 0.20, True],
        # ---- gemiler
        "s_dhow": ["Kürekli Savaş Gemisi / Dhow", "sub", "Oman", 1, 0.5, True],
        "s_galley": ["Kadırga", "sub", "Italy", 2, 0.8, True],
        "s_cog": ["Kogge Savaş Gemisi", "sub", "Denmark", 2, 0.6, True],
        "s_junk": ["Savaş Cunk'ı", "sub", "China", 3, 0.8, True],
        "s_galley2": ["Ağır Kadırga", "sub", "Italy", 4, 1.2, True],
        "f_none": ["—", "air", "Turkey", 1, 0.0, False],
    }
    bloc = {
        "eu": _bloc(["i_levy", "i_archer", "i_halb", "i_halb"], ["t_knight", "t_knight", "t_knight", "t_knight"],
                    ["a_akinci", "a_akinci", "a_tatar", "a_tatar"], ["y_catap", "y_trebu", "y_trebu", "y_bombard"],
                    ["s_cog", "s_cog", "s_galley", "s_galley2"]),
        "tr": _bloc(["i_sword", "i_sword", "i_guard", "i_guard"], ["t_cata", "t_mamluk", "t_mamluk", "t_timur"],
                    ["a_akinci", "a_akinci", "a_turkmen", "a_horsearch"], ["y_ram", "y_trebu", "y_trebu", "y_bombard"],
                    ["s_galley", "s_galley", "s_galley", "s_galley2"]),
        "st": _bloc(["i_sword", "i_archer", "i_guard", "i_guard"], ["t_timur", "t_timur", "t_keshik", "t_keshik"],
                    ["a_horsearch", "a_horsearch", "a_horsearch", "a_horsearch"], ["y_ram", "y_trebu", "y_trebu", "y_rocket"],
                    ["s_dhow", "s_dhow", "s_dhow", "s_dhow"]),
        "as": _bloc(["i_sword", "i_archer", "i_firelance", "i_firelance"], ["t_ming_c", "t_ming_c", "t_ming_c", "t_ming_c"],
                    ["a_ming_l", "a_ming_l", "a_horsearch", "a_horsearch"], ["y_rocket", "y_rocket", "y_rocket", "y_rocket"],
                    ["s_junk", "s_junk", "s_junk", "s_junk"]),
        "ot": _bloc(["i_tribal", "i_levy", "i_archer", "i_archer"], ["t_tribe_c", "t_tribe_c", "t_tribe_c", "t_tribe_c"],
                    ["a_horsearch", "a_camel", "a_camel", "a_horsearch"], ["y_catap", "y_catap", "y_ram", "y_ram"],
                    ["s_dhow", "s_dhow", "s_dhow", "s_dhow"]),
    }
    family = {
        "Russia": {"tank": ["t_druzhina"] * 4},
        "Lithuania": {"tank": ["t_lith"] * 4},
        "Poland": {"tank": ["t_knight"] * 4},
        "India": {"inf": ["i_levy", "i_archer", "i_archer", "i_archer"], "tank": ["t_eleph"] * 4, "afv": ["a_rajput"] * 4},
        "United Kingdom": {"inf": ["i_levy", "i_longbow", "i_longbow", "i_longbow"]},
        "Greece": {"tank": ["t_cata"] * 4},
        "Mongolia": {"tank": ["t_keshik", "t_keshik", "t_keshik", "t_keshik"]},
        "Egypt": {"tank": ["t_mamluk"] * 4},
        "Uzbekistan": {"tank": ["t_timur", "t_timur", "t_keshik", "t_keshik"]},
    }
    bloc_of = {
        "Germany": "eu", "France": "eu", "United Kingdom": "eu", "Spain": "eu", "Italy": "eu", "Poland": "eu", "Hungary": "eu", "Lithuania": "eu",
        "Russia": "eu", "Denmark": "eu", "Sweden": "eu", "Portugal": "eu", "Latvia": "eu", "Belgium": "eu", "Greece": "tr", "Bulgaria": "tr", "Serbia": "eu",
        "Turkey": "tr", "Egypt": "tr", "Azerbaijan": "tr", "Iran": "st", "Afghanistan": "st", "Uzbekistan": "st", "Kazakhstan": "st", "Kyrgyzstan": "st",
        "Mongolia": "st", "Ukraine": "st", "India": "tr", "Pakistan": "tr", "Bangladesh": "tr", "Sri Lanka": "tr",
        "China": "as", "Japan": "as", "South Korea": "as", "Vietnam": "as", "Thailand": "as", "Myanmar": "as", "Indonesia": "as", "Malaysia": "as",
        "Cambodia": "as", "Laos": "as", "Philippines": "as", "Bhutan": "as", "Morocco": "tr", "Algeria": "tr", "Tunisia": "tr",
    }
    tech = {"Uzbekistan": 0.36, "China": 0.48, "Egypt": 0.36, "Turkey": 0.38, "France": 0.38, "Italy": 0.42, "Germany": 0.38, "Azerbaijan": 0.32,
            "Kazakhstan": 0.3, "Russia": 0.24, "Poland": 0.28, "Hungary": 0.3, "India": 0.28, "Iran": 0.3, "Greece": 0.26}
    gate = {"i_firelance": 60, "t_keshik": 0, "y_bombard": 160, "s_galley2": 200, "i_guard": 0, "y_trebu": 0}
    return {"items": items, "bloc": bloc, "family": family, "bloc_of": bloc_of, "tech": tech, "new": [], "gate": gate, "cat_names": CAT_NAMES}

# -*- coding: utf-8 -*-
# 2026-11-23: O5 bölgesel kaynaklar. Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ["en", "de", "es", "fr", "it", "pt", "ru", "ar", "fa", "zh", "ja", "ko", "hi"]
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a("Kaynak", "Resource", "Ressource", "Recurso", "Ressource", "Risorsa", "Recurso", "Ресурс", "المورد", "منبع", "资源", "資源", "자원", "संसाधन")
a("Verimli tarım ovası", "Fertile farmland", "Fruchtbares Ackerland", "Llanura agrícola fértil", "Plaine agricole fertile", "Pianura agricola fertile", "Planície agrícola fértil", "Плодородная пашня", "سهل زراعي خصب", "دشت کشاورزی حاصلخیز", "肥沃农田", "肥沃な農地", "비옥한 농경지", "उपजाऊ कृषि मैदान")
a("Zengin maden yatağı", "Rich mineral deposit", "Reiche Erzlagerstätte", "Rico yacimiento mineral", "Riche gisement minier", "Ricco giacimento minerario", "Rico depósito mineral", "Богатое месторождение руд", "مكمن معدني غني", "کانسار معدنی غنی", "富矿床", "豊かな鉱床", "풍부한 광물 매장지", "समृद्ध खनिज भंडार")
a("Petrol ve gaz sahası", "Oil and gas field", "Öl- und Gasfeld", "Yacimiento de petróleo y gas", "Gisement de pétrole et de gaz", "Giacimento di petrolio e gas", "Campo de petróleo e gás", "Нефтегазовое месторождение", "حقل نفط وغاز", "میدان نفت و گاز", "油气田", "油田・ガス田", "석유·가스전", "तेल और गैस क्षेत्र")
a(" ★ zengin kaynak: %35 ucuz, getirisi +%30", " ★ rich resource: 35% cheaper, +30% yield", " ★ reiche Ressource: 35 % billiger, +30 % Ertrag", " ★ recurso rico: 35 % más barato, +30 % de rendimiento", " ★ ressource riche : 35 % moins cher, +30 % de rendement", " ★ risorsa ricca: 35% più economico, +30% di resa", " ★ recurso rico: 35% mais barato, +30% de rendimento", " ★ богатый ресурс: на 35% дешевле, доход +30%", " ★ مورد غني: أرخص بنسبة 35%، وعائد أعلى بنسبة 30%", " ★ منبع غنی: ۳۵٪ ارزان‌تر، بازده ۳۰٪ بیشتر", " ★ 富集资源：造价低35%，收益+30%", " ★ 豊富な資源：費用35%減、収益+30%", " ★ 풍부한 자원: 비용 35% 절감, 수익 +30%", " ★ समृद्ध संसाधन: 35% सस्ता, उपज +30%")

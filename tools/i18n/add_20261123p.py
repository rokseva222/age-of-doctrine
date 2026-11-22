# -*- coding: utf-8 -*-
# 2026-11-23: yeni binalar. Sıra: en de es fr it pt ru ar fa zh ja ko hi
L = ['en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'ar', 'fa', 'zh', 'ja', 'ko', 'hi']
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a('Okul ve kütüphane', 'School and library', 'Schule und Bibliothek', 'Escuela y biblioteca', 'École et bibliothèque', 'Scuola e biblioteca', 'Escola e biblioteca', 'Школа и библиотека', 'مدرسة ومكتبة', 'مدرسه و کتابخانه', '学校与图书馆', '学校と図書館', '학교와 도서관', 'स्कूल और पुस्तकालय')
a('Rafineri', 'Refinery', 'Raffinerie', 'Refinería', 'Raffinerie', 'Raffineria', 'Refinaria', 'Нефтепереработка', 'مصفاة', 'پالایشگاه', '炼油厂', '製油所', '정유소', 'रिफाइनरी')
a('İhracat limanı', 'Export port', 'Exporthafen', 'Puerto de exportación', "Port d'exportation", 'Porto di esportazione', 'Porto de exportação', 'Экспортный порт', 'ميناء تصدير', 'بندر صادراتی', '出口港', '輸出港', '수출항', 'निर्यात बंदरगाह')
a('Gelir +%8, teknolojiyi hızlandırır', 'Income +8%, speeds up technology', 'Einkommen +8 %, beschleunigt die Technologie', 'Ingresos +8 %, acelera la tecnología', 'Revenu +8 %, accélère la technologie', 'Entrate +8%, accelera la tecnologia', 'Renda +8%, acelera a tecnologia', 'Доход +8%, ускоряет технологии', 'الدخل +8%، يسرّع التقنية', 'درآمد +۸٪، فناوری را سریع\u200cتر می\u200cکند', '收入+8%，加快科技发展', '収入+8%、技術進歩を加速', '수입 +8%, 기술 발전 가속', 'आय +8%, तकनीक की गति बढ़ाता है')
a('Gelir +%25, petrol satışı +%8', 'Income +25%, oil sales +8%', 'Einkommen +25 %, Ölverkäufe +8 %', 'Ingresos +25 %, ventas de petróleo +8 %', 'Revenu +25 %, ventes de pétrole +8 %', 'Entrate +25%, vendite di petrolio +8%', 'Renda +25%, vendas de petróleo +8%', 'Доход +25%, продажи нефти +8%', 'الدخل +25%، مبيعات النفط +8%', 'درآمد +۲۵٪، فروش نفت +۸٪', '收入+25%，石油销售+8%', '収入+25%、石油販売+8%', '수입 +25%, 석유 판매 +8%', 'आय +25%, तेल बिक्री +8%')
a('Gelir +%15, tüm mal satışları +%6', 'Income +15%, all goods sales +6%', 'Einkommen +15 %, alle Warenverkäufe +6 %', 'Ingresos +15 %, todas las ventas de bienes +6 %', 'Revenu +15 %, toutes les ventes de biens +6 %', 'Entrate +15%, tutte le vendite di beni +6%', 'Renda +15%, todas as vendas de bens +6%', 'Доход +15%, продажи всех товаров +6%', 'الدخل +15%، مبيعات كل السلع +6%', 'درآمد +۱۵٪، فروش همهٔ کالاها +۶٪', '收入+15%，所有商品销售+6%', '収入+15%、全物資の販売+6%', '수입 +15%, 모든 상품 판매 +6%', 'आय +15%, सभी वस्तुओं की बिक्री +6%')

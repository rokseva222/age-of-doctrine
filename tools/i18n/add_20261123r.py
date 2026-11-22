# -*- coding: utf-8 -*-
# 2026-11-23: senaryo editörü (il seçimi). Dil koduna göre sözlük (arite hatası olmasın).
L = ['en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'ar', 'fa', 'zh', 'ja', 'ko', 'hi']
T = {}
def a(tr, d):
    assert set(d) == set(L), (tr, set(L) ^ set(d))
    T[tr] = d
prov = {'en': 'provinces', 'de': 'Provinzen', 'es': 'provincias', 'fr': 'provinces', 'it': 'province', 'pt': 'províncias', 'ru': 'провинций', 'ar': 'مقاطعات', 'fa': 'استان', 'zh': '个省', 'ja': '州', 'ko': '개 지방', 'hi': 'प्रांत'}
a('eyalet', prov)
a('il', prov)
a('Seçilen iller zaten hedef ülkenin; devredilecek il yok.', {
 'en': 'The selected provinces already belong to the target country; nothing to transfer.',
 'de': 'Die gewählten Provinzen gehören bereits dem Zielland; nichts zu übertragen.',
 'es': 'Las provincias elegidas ya son del país destino; no hay nada que transferir.',
 'fr': 'Les provinces choisies appartiennent déjà au pays cible ; rien à transférer.',
 'it': 'Le province scelte appartengono già al paese di destinazione; nulla da trasferire.',
 'pt': 'As províncias escolhidas já pertencem ao país de destino; nada a transferir.',
 'ru': 'Выбранные провинции уже принадлежат целевой стране; передавать нечего.',
 'ar': 'المقاطعات المختارة تابعة بالفعل للدولة المستهدفة؛ لا شيء للنقل.',
 'fa': 'استان‌های انتخاب‌شده از پیش متعلق به کشور مقصدند؛ چیزی برای انتقال نیست.',
 'zh': '所选省份已属于目标国家，无需转让。',
 'ja': '選んだ州はすでに移譲先の国のものです。移す州がありません。',
 'ko': '선택한 지방은 이미 대상 국가 소유입니다. 이양할 지방이 없습니다.',
 'hi': 'चुने गए प्रांत पहले से लक्ष्य देश के हैं; स्थानांतरित करने को कुछ नहीं।'})

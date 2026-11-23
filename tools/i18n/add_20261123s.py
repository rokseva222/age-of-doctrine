# -*- coding: utf-8 -*-
L = ['en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'ar', 'fa', 'zh', 'ja', 'ko', 'hi']
T = {}
def a(tr, d):
    assert set(d) == set(L), (tr, set(L) ^ set(d))
    T[tr] = d
a('Genel Kurmay', {'en': 'General Staff', 'de': 'Generalstab', 'es': 'Estado Mayor', 'fr': 'État-major', 'it': 'Stato maggiore', 'pt': 'Estado-Maior', 'ru': 'Генштаб', 'ar': 'هيئة الأركان', 'fa': 'ستاد کل', 'zh': '总参谋部', 'ja': '参謀本部', 'ko': '총참모부', 'hi': 'सेना मुख्यालय'})

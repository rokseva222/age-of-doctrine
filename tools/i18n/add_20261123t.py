# -*- coding: utf-8 -*-
L = ['en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'ar', 'fa', 'zh', 'ja', 'ko', 'hi']
T = {}
def a(tr, d):
    assert set(d) == set(L), (tr, set(L) ^ set(d))
    T[tr] = d
a('TARİHÎ AN', {'en': 'HISTORIC MOMENT', 'de': 'HISTORISCHER MOMENT', 'es': 'MOMENTO HISTÓRICO', 'fr': 'MOMENT HISTORIQUE', 'it': 'MOMENTO STORICO', 'pt': 'MOMENTO HISTÓRICO', 'ru': 'ИСТОРИЧЕСКИЙ МОМЕНТ', 'ar': 'لحظة تاريخية', 'fa': 'لحظه تاریخی', 'zh': '历史时刻', 'ja': '歴史的瞬間', 'ko': '역사적 순간', 'hi': 'ऐतिहासिक क्षण'})

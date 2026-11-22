# -*- coding: utf-8 -*-
L = ['en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'ar', 'fa', 'zh', 'ja', 'ko', 'hi']
T = {}
def a(tr, *v):
    assert len(v) == 13, (tr, len(v))
    T[tr] = dict(zip(L, v))

a('Alınacak yerler (elinde tutan ülke): %s', 'Lands to take (current holder): %s', 'Zu erobernde Gebiete (aktueller Besitzer): %s', 'Tierras por tomar (poseedor actual): %s', 'Terres à prendre (détenteur actuel) : %s', 'Terre da prendere (detentore attuale): %s', 'Terras a tomar (atual dono): %s', 'Земли для захвата (нынешний владелец): %s', 'الأراضي المطلوبة (الحائز الحالي): %s', 'سرزمین\u200cهای لازم (مالک فعلی): %s', '需夺取的土地（现持有者）：%s', '獲得すべき土地（現在の保有国）：%s', '확보할 영토(현 보유국): %s', 'लेने योग्य भूमि (वर्तमान स्वामी): %s')

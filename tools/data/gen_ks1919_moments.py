#!/usr/bin/env python3
"""Kurtuluş Savaşı 1919 çağının tarihî an kartları: data/moments/ks1919.json (Samsun, Sevr, Sakarya, Büyük Taarruz, Lozan ww1 tabanından miras gelir)."""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
EN = {}
def T(tr, en):
    EN[tr] = en
    return tr
def opt(t, d, fx, r):
    return {"t": T(*t), "d": T(*d), "fx": fx, "r": T(*r)}

M = []
M.append({"id": "amasya", "y": 1919, "m": 6, "title": T("Amasya Genelgesi", "Amasya Circular"), "scene": "pre_mobilize", "icon": "uprising_banner",
    "text": T("Mustafa Kemal Amasya'da genelge yayımladı: 'Vatanın bütünlüğü, milletin istiklali tehlikededir.' İstanbul hükûmeti etkisiz; millî irade Anadolu'dan doğacak.",
              "Mustafa Kemal issued a circular at Amasya: 'The integrity of the homeland and the independence of the nation are in danger.' The Istanbul government is powerless; the national will must rise from Anatolia."),
    "major": True, "default_fx": [["stab", "Turkey", 3]],
    "roles": {"Turkey": {"text": T("İstanbul seni geri çağırıyor, İngilizler baskı yapıyor. Genelge Anadolu'daki bütün komutanlara ve valilere gidecek: yazarsan geri dönüş yok.",
                                   "Istanbul is recalling you and the British are pressing. The circular will go to every commander and governor in Anatolia: once you send it, there is no way back."),
        "options": [
            opt(("Genelgeyi yayımla (tarihî)", "Issue the circular (historical)"), ("Millî örgütlenme başlar", "National organisation begins"),
                [["xstab", "Turkey", 8], ["troops", "Turkey", 8], ["buff", "Turkey", "recruit", 1.2, 26], ["flag", "amasya"]],
                ("Genelge Anadolu'ya yayıldı; cemiyetler örgütleniyor.", "The circular spread across Anatolia; resistance societies are organising.")),
            opt(("İstanbul'a dön", "Return to Istanbul"), ("Emirlere uy, direniş dağınık kalır", "Obey orders; resistance stays scattered"),
                [["xstab", "Turkey", -10], ["gold", "Turkey", 2]],
                ("Direniş başsız kaldı; Anadolu'da dağınık çeteler sürüyor.", "The resistance lost its head; scattered bands carry on in Anatolia."))]}}})
M.append({"id": "sivas", "y": 1919, "m": 9, "title": T("Sivas Kongresi", "Sivas Congress"), "scene": "pre_alliance", "icon": "treaty",
    "text": T("Anadolu ve Rumeli Müdafaa-i Hukuk Cemiyetleri Sivas'ta toplandı. Gündem: tek yönetim altında birleşmek ve manda fikri.",
              "The Anatolian and Rumelian defence-of-rights societies met at Sivas. On the agenda: uniting under one leadership, and the mandate idea."),
    "major": True, "default_fx": [["stab", "Turkey", 4]],
    "roles": {"Turkey": {"text": T("Bazı delegeler Amerikan mandasını bir çıkış yolu olarak görüyor. Kongre tek bir karar vermek zorunda.",
                                   "Some delegates see an American mandate as a way out. The congress must settle on a single line."),
        "options": [
            opt(("Mandayı reddet, tam bağımsızlık (tarihî)", "Reject the mandate: full independence (historical)"), ("Tek bir irade, tek bir cephe", "One will, one front"),
                [["xstab", "Turkey", 10], ["buff", "Turkey", "def", 1.15, 26], ["flag", "sivas"]],
                ("Sivas Kongresi tam bağımsızlık ilkesini kabul etti.", "The Sivas Congress adopted the principle of full independence.")),
            opt(("Amerikan mandasını araştır", "Explore an American mandate"), ("Wilson'un desteği, ama bağımsızlıktan ödün", "Wilson's backing at the cost of independence"),
                [["rel", "Turkey", "United States of America", 20], ["gold", "Turkey", 6], ["xstab", "Turkey", -6]],
                ("Washington'a heyet gönderildi; kongrede ikilik var.", "A delegation went to Washington; the congress is divided."))]}}})
M.append({"id": "tbmm", "y": 1920, "m": 4, "title": T("TBMM Açılıyor", "The Grand National Assembly Opens"), "scene": "pre_court", "icon": "treaty",
    "text": T("İstanbul işgal edildi, Meclis-i Mebusan basıldı. Ankara'da Büyük Millet Meclisi toplanıyor: 'Hâkimiyet kayıtsız şartsız milletindir.'",
              "Istanbul is occupied and the Ottoman parliament has been raided. In Ankara the Grand National Assembly convenes: 'Sovereignty belongs unconditionally to the nation.'"),
    "major": True, "default_fx": [["stab", "Turkey", 6]],
    "roles": {"Turkey": {"text": T("Ankara'da yeni bir meclis kurulabilir; ama padişah ve İstanbul hükûmeti seni asi ilan etti, fetvalar çıkıyor.",
                                   "A new assembly can be founded in Ankara, but the sultan and the Istanbul government have branded you a rebel and fatwas are being issued."),
        "options": [
            opt(("Meclisi aç, hükûmeti kur (tarihî)", "Open the assembly and form a government (historical)"), ("Millî egemenlik, ordu için kaynak", "National sovereignty and resources for the army"),
                [["xstab", "Turkey", 12], ["troops", "Turkey", 10], ["buff", "Turkey", "recruit", 1.2, 52], ["flag", "tbmm"]],
                ("23 Nisan 1920: TBMM açıldı; Ankara yeni devletin merkezi oldu.", "23 April 1920: the TBMM opened and Ankara became the centre of the new state.")),
            opt(("Padişaha bağlı kal", "Stay loyal to the sultan"), ("Tutuculuk: İngiltere ile ilişki düzelir", "Caution: relations with Britain improve"),
                [["xstab", "Turkey", -12], ["gold", "Turkey", 4], ["rel", "Turkey", "United Kingdom", 10]],
                ("Ankara'da meclis kurulamadı; ordu dağınık kaldı.", "No assembly was formed in Ankara and the army stayed fragmented."))]}}})
M.append({"id": "dogu_guney", "y": 1920, "m": 9, "title": T("Doğu mu, Güney mi?", "East or South?"), "scene": "pre_border", "icon": "sword",
    "text": T("Sevr'in gölgesinde Ermenistan doğuda, Fransa güneyde baskı yapıyor. Yunan ordusu batıda yeni bir taarruza hazırlanıyor. Birini seçmek zorundasın.",
              "In the shadow of Sèvres Armenia presses in the east and France in the south, while the Greek army prepares a new offensive in the west. You must choose one front."),
    "major": True, "default_fx": [["war", "Turkey", "Armenia", "solo"]],
    "roles": {"Turkey": {"text": T("Kâzım Karabekir doğuda hazır; güneyde Maraş, Antep ve Urfa direnişi sürüyor. Üç cepheyi aynı anda taşıyamazsın.",
                                   "Kâzım Karabekir is ready in the east; resistance in Maraş, Antep and Urfa continues in the south. You cannot carry three fronts at once."),
        "options": [
            opt(("Önce Doğu: Ermenistan'a taarruz (tarihî)", "East first: attack Armenia (historical)"), ("Kars'ı geri al, Rusya'yla yakınlaş", "Retake Kars and draw closer to Russia"),
                [["war", "Turkey", "Armenia", "solo"], ["buff", "Turkey", "att", 1.2, 12], ["xstab", "Turkey", 4], ["flag", "kars"]],
                ("Doğu Cephesi açıldı; Sarıkamış ve Kars hedefte.", "The Eastern Front opened; Sarıkamış and Kars are the objectives.")),
            opt(("Önce Güney: Kilikya'yı kuşat", "South first: besiege Cilicia"), ("Fransa'yla savaş, Fransız çekilmesi için baskı", "War with France; pressure for a French withdrawal"),
                [["war", "Turkey", "France", "solo"], ["buff", "Turkey", "def", 1.1, 12], ["xstab", "Turkey", -2]],
                ("Kuvayımilliye Kilikya'ya yöneldi; Fransa zor durumda.", "The national forces turned on Cilicia; France is in trouble.")),
            opt(("Moskova'yla görüş", "Talk to Moscow"), ("Sovyet altını ve silahı, ama yavaş", "Soviet gold and arms, but slowly"),
                [["rel", "Turkey", "Russia", 25], ["gold", "Turkey", 5], ["xstab", "Turkey", 2]],
                ("Moskova'ya heyet gönderildi; silah ve altın yardımı pazarlığı sürüyor.", "A delegation went to Moscow; talks on arms and gold aid continue."))]}}})
M.append({"id": "inonu", "y": 1921, "m": 1, "title": T("İnönü", "İnönü"), "scene": "pre_assault", "icon": "sword",
    "text": T("Yunan ordusu Bursa'dan Eskişehir'e doğru ilerliyor. Yeni kurulan düzenli ordunun ilk büyük sınavı İnönü'de.",
              "The Greek army is advancing from Bursa towards Eskişehir. İnönü is the first big test of the newly formed regular army."),
    "major": True, "default_fx": [["stab", "Greece", -3]],
    "roles": {"Turkey": {"text": T("İsmet Paşa İnönü mevzilerinde. Düzenli ordu daha çok genç; çekilirsen Eskişehir demiryolu düşer.",
                                   "İsmet Pasha is in the İnönü positions. The regular army is still young; if you fall back the Eskişehir railway is lost."),
        "options": [
            opt(("Mevzide dur (tarihî)", "Hold the line (historical)"), ("Düzenli ordunun ilk zaferi", "The regular army's first victory"),
                [["buff", "Turkey", "def", 1.2, 8], ["xstab", "Turkey", 6], ["troops", "Turkey", 5], ["flag", "inonu"]],
                ("İnönü kazanıldı: Yunan taarruzu püskürtüldü.", "İnönü was won: the Greek offensive was beaten back.")),
            opt(("Geri çekil, mevzi değiştir", "Fall back and regroup"), ("Orduyu koru, toprak ver", "Save the army, give up ground"),
                [["xstab", "Turkey", -5], ["buff", "Turkey", "def", 1.1, 6]],
                ("Ordu Sakarya doğrultusunda geri çekildi.", "The army withdrew toward the Sakarya line."))]},
        "Greece": {"text": T("Kral Konstantinos ordunun başında; Eskişehir'e ulaşırsan Ankara'nın demiryolu bağlantısı kesilir.",
                              "King Konstantinos is at the head of the army; if you reach Eskişehir Ankara's rail link is cut."),
        "options": [
            opt(("Eskişehir'e ilerle (tarihî)", "Advance on Eskişehir (historical)"), ("Büyük taarruz, ağır kayıp riski", "A big push with heavy losses likely"),
                [["buff", "Greece", "att", 1.15, 8], ["troops", "Greece", -5]],
                ("Yunan ordusu İnönü mevzilerine saldırdı.", "The Greek army attacked the İnönü positions.")),
            opt(("Hatları tahkim et", "Consolidate the lines"), ("Temkinli kal", "Stay cautious"),
                [["buff", "Greece", "def", 1.1, 8], ["stab", "Greece", 2]],
                ("Yunan ordusu Bursa hattında kaldı.", "The Greek army stayed on the Bursa line."))]}}})
M.append({"id": "saltanat", "y": 1922, "m": 11, "title": T("Saltanatın Kaldırılması", "Abolition of the Sultanate"), "scene": "pre_court", "icon": "treaty",
    "text": T("Zafer kazanıldı; Lozan'a hem Ankara hem İstanbul davet edildi. TBMM tek temsilci olacağını ilan etmek zorunda.",
              "Victory is won; both Ankara and Istanbul were invited to Lausanne. The TBMM must declare itself the only representative."),
    "major": True, "default_fx": [["stab", "Turkey", 4]],
    "roles": {"Turkey": {"text": T("İki hükûmetle Lozan'a gidilemez. Saltanatı kaldırmak devleti tek elde toplar ama muhafazakâr tepki doğurur.",
                                   "You cannot go to Lausanne with two governments. Abolishing the sultanate unifies the state but stirs conservative backlash."),
        "options": [
            opt(("Saltanatı kaldır (tarihî)", "Abolish the sultanate (historical)"), ("Tek temsilci, güçlü Ankara", "One representative, a strong Ankara"),
                [["xstab", "Turkey", 10], ["flag", "saltanat"], ["rel", "Turkey", "United Kingdom", -3]],
                ("1 Kasım 1922: saltanat kaldırıldı; Osmanlı hanedanının hükümdarlığı sona erdi.", "1 November 1922: the sultanate was abolished and Ottoman rule came to an end.")),
            opt(("Saltanatı koru", "Keep the sultanate"), ("Muhafazakârları yatıştır, Lozan'da iki ses", "Placate conservatives, two voices at Lausanne"),
                [["xstab", "Turkey", -3], ["rel", "Turkey", "United Kingdom", 6]],
                ("İtilaf iki ayrı heyetle muhatap oldu; Lozan zorlaştı.", "The Entente now faces two delegations; Lausanne gets harder."))]}}})

json.dump({"moments": M, "en": EN}, open(os.path.join(ROOT, "data/moments/ks1919.json"), "w"), ensure_ascii=False, indent=1)
print("ok", len(M), "an,", len(EN), "çeviri")

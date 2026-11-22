"""Tarihî/senaryo anları için ortak yardımcılar: iki dilli (TR kaynak + EN tablosu) kart üretimi.
Kullanım:  k = Kit();  m = k.moment(...);  k.en  -> {tr: en} tablosu (moments_en / moments/<era>.json "en")
Her metin (TR, EN) çifti olarak verilir."""

class Kit:
    def __init__(self):
        self.en = {}
        self.title_en = {}     # TR başlık -> EN başlık (başlık düz metin verilirse buradan alınır)

    def t(self, p):
        tr, en = p
        self.en[tr] = en
        return tr

    def opt(self, t, d, fx, r, keep=None):
        o = {"t": self.t(t), "d": self.t(d), "fx": fx, "r": self.t(r)}
        if keep:
            o["keep_default"] = True
        return o

    def role(self, text, *options):
        return {"text": self.t(text), "options": list(options)}

    def moment(self, id, title, text, roles, default_fx, turn=None, y=None, m=None, icon="landing", scene="pre_landing",
               major=True, requires=None, forbid=None, keep_default_others=True, only_role_keep=()):
        if isinstance(title, str):
            title = (title, self.title_en.get(title, title))
        d = {"id": id}
        if turn is not None:
            d["turn"] = turn
        if y is not None:
            d["y"] = y
            d["m"] = m
        d.update({"title": self.t(title), "scene": scene, "icon": icon, "text": self.t(text), "major": major,
                  "default_fx": default_fx, "roles": roles})
        if requires:
            d["requires"] = requires
        if forbid:
            d["forbid"] = forbid
        return d


def keep_defaults(moments, main_roles=()):
    """Ana aktörün (main_roles) dışındaki rollerin seçenekleri, oyuncu o roldeyken tarihî varsayılan etkileri de uygular."""
    for m in moments:
        for rn, r in m.get("roles", {}).items():
            if rn in main_roles:
                continue
            for o in r["options"]:
                o.setdefault("keep_default", True)
    return moments

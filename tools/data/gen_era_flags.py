#!/usr/bin/env python3
"""Dönem bayrakları (flag_db kısa tanımı) -> data/era_flags.json
Her çağ için {name_en: spec}. Eras.prepare bunları DEFS/JSON 'flag' alanı yoksa kullanır; alt_ çağlar base zincirinden miras alır."""
import json, os

RED, WHITE, BLK, GOLD, BLUE, GRN, SKY, DRED = "#c8102e", "#ffffff", "#141414", "#f4c430", "#1c3f94", "#2e7d32", "#4aa3df", "#8e1b2f"

def solid(c): return f"R:0,0,1,1,{c}"
def H(*c): return "H:" + ",".join(c)
def V(*c): return "V:" + ",".join(c)
def cross(bg, c, x=.5, w=.16): return f"{solid(bg)}|K:{c},{w},{x},.5"
def saltire(bg, c, w=.14): return f"{solid(bg)}|L:{c},{w},0,0,1,1|L:{c},{w},1,0,0,1"
def disc(bg, c, r=.22, x=.5, y=.5): return f"{solid(bg)}|C:{x},{y},{r},{c}"
def ring(bg, c, r=.22): return f"{solid(bg)}|O:{c},.03,.5,.5,{r}"
def star(bg, c, n=5, r=.24): return f"{solid(bg)}|S:.5,.5,{r},{c},{n}"
def cres(bg, c, x=.42, r=.22): return f"{solid(bg)}|C:{x},.5,{r},{c}|C:{x+.07},.5,{r-.03},{bg}"
def cresstar(bg, c, r=.22): return cres(bg, c, .42, r) + f"|S:.62,.5,.07,{c}"
def diamond(bg, c, r=.3): return f"{solid(bg)}|P:{c},.5,{.5-r},{.5+r*.7},.5,.5,{.5+r},{.5-r*.7},.5"
def three_rings(bg, c): return f"{solid(bg)}|O:{c},.025,.42,.4,.1|O:{c},.025,.58,.4,.1|O:{c},.025,.5,.6,.1"
def three(bg, c, r=.1): return f"{solid(bg)}|C:.33,.36,{r},{c}|C:.67,.36,{r},{c}|C:.5,.68,{r},{c}"
def serb(bg, c): return f"{solid(bg)}|K:{c},.07,.5,.5"
def bars(*c): return H(*c)

# ---------------- Osmanlı Çağı 1520
OTT = {
 "Turkey": cresstar(RED, WHITE),
 "Spain": saltire(WHITE, RED, .12),
 "France": solid(BLUE) + f"|S:.3,.3,.075,{GOLD},8|S:.7,.3,.075,{GOLD},8|S:.5,.68,.075,{GOLD},8",
 "Germany": diamond(GOLD, BLK),
 "Switzerland": cross(RED, WHITE, .5, .2),
 "Italy": V(GOLD, WHITE) + f"|C:.5,.5,.1,{RED}",
 "Malta": cross(RED, WHITE, .5, .2),
 "Portugal": cross(WHITE, BLUE, .5, .12) + f"|C:.5,.5,.08,{RED}",
 "United Kingdom": cross(WHITE, RED, .5, .16),
 "Ireland": disc(BLUE, GOLD, .15),
 "Denmark": cross(RED, WHITE, .37, .16),
 "Sweden": cross(BLUE, GOLD, .37, .16),
 "Poland": diamond(RED, WHITE, .26),
 "Hungary": H(RED, WHITE, RED, WHITE, RED, WHITE, RED, WHITE),
 "Russia": solid(RED) + f"|C:.5,.5,.17,{GOLD}|C:.5,.5,.09,{RED}",
 "Latvia": cross(WHITE, BLK, .4, .14),
 "Romania": V(RED, GOLD),
 "Georgia": cross(WHITE, RED, .5, .14) + f"|K:{RED},.05,.16,.2|K:{RED},.05,.84,.2",
 "Ukraine": disc(SKY, GOLD, .2) + f"|C:.5,.5,.09,{SKY}",
 "Iran": disc(GRN, GOLD, .22) + f"|S:.5,.5,.12,{RED},8",
 "Afghanistan": disc("#1b5e20", WHITE, .16),
 "Uzbekistan": cresstar(SKY, WHITE),
 "Kazakhstan": star(SKY, GOLD, 8, .22),
 "Mongolia": star("#14305c", GOLD, 8, .22),
 "Saudi Arabia": cres(WHITE, GRN),
 "Yemen": cres(GRN, WHITE),
 "Oman": solid(RED) + f"|P:{WHITE},0,0,.3,.5,0,1",
 "United Arab Emirates": H(BLUE, WHITE) + f"|C:.5,.5,.12,{GOLD}",
 "Algeria": cres(GRN, WHITE),
 "Tunisia": disc(WHITE, GRN, .2),
 "Morocco": star(WHITE, RED, 8, .22),
 "China": disc(GOLD, RED, .24) + f"|C:.5,.5,.11,{GOLD}",
 "Japan": star("#1c2a48", GOLD, 8, .2),
 "South Korea": f"{solid(WHITE)}|C:.5,.5,.2,{BLUE}|C:.5,.43,.1,{RED}",
 "India": H(GRN, GOLD) + f"|C:.5,.5,.1,{BLK}",
 "Sri Lanka": disc(GOLD, RED, .2) + f"|C:.5,.5,.08,{GOLD}",
 "Bangladesh": disc(GRN, WHITE, .16),
 "Pakistan": disc("#2e7d32", GOLD, .14),
 "Nepal": cres("#6a1b9a", WHITE),
 "Bhutan": H(GOLD, "#e65100") + f"|P:{WHITE},.2,.2,.8,.8,.2,.8",
 "Maldives": cres(GRN, WHITE),
 "Myanmar": disc(RED, WHITE, .2),
 "Thailand": H(RED, WHITE, RED),
 "Vietnam": ring(GOLD, RED, .22),
 "Laos": disc(RED, WHITE, .2),
 "Cambodia": disc(BLUE, GOLD, .2),
 "Malaysia": cres(GOLD, RED),
 "Brunei": solid(GOLD),
 "Indonesia": H(RED, WHITE),
 "Philippines": disc(BLUE, GOLD, .18),
 "Taiwan": solid(GRN),
 "Papua New Guinea": disc("#7b3f00", GOLD, .18),
 "Australia": disc("#a1572b", GOLD, .2),
 "Ethiopia": cross("#6a1b9a", GOLD, .5, .12),
 "Somalia": cres(WHITE, GRN),
 "Sudan": disc("#1b5e20", GOLD, .16),
 "Chad": disc(RED, GOLD, .18),
 "Mali": star(GOLD, BLK, 8, .22),
 "Nigeria": V(GRN, WHITE, RED),
 "Ghana": H(GOLD, BLK, GOLD),
 "Dem. Rep. Congo": cross("#00695c", GOLD, .5, .12),
 "Tanzania": H(SKY, WHITE) + f"|C:.5,.5,.1,{RED}",
 "Uganda": disc("#d84315", WHITE, .18),
 "Zimbabwe": disc("#7b3f00", GOLD, .2) + f"|S:.5,.5,.1,{BLK},8",
 "Madagascar": V(WHITE, RED),
 "Mexico": disc("#00838f", GOLD, .24) + f"|C:.5,.5,.11,{RED}",
 "Guatemala": H("#2e7d32", GOLD) + f"|S:.5,.5,.18,{WHITE},6",
 "Peru": disc(GOLD, RED, .24),
 "Colombia": ring(GOLD, "#2e7d32", .22),
 "Brazil": H("#2e7d32", GOLD, "#2e7d32"),
 "Cuba": disc(GRN, WHITE, .16),
 "United States of America": H("#6d4c41", "#8d6e63", "#6d4c41") + f"|C:.5,.5,.14,{GOLD}",
 "Canada": H("#2e5e3e", "#4a7c59", "#2e5e3e") + f"|C:.5,.5,.14,{WHITE}",
}

# ---------------- Timur Çağı 1380
TIM = dict(OTT)
TIM.update({
 "Uzbekistan": three_rings(DRED, GOLD),
 "Kazakhstan": disc(GOLD, RED, .12),
 "Kyrgyzstan": cres(SKY, WHITE),
 "Mongolia": star("#14305c", GOLD, 8, .22),
 "Iran": disc("#1b5e20", GOLD, .2) + f"|C:.5,.5,.1,#1b5e20",
 "Afghanistan": V("#2e7d32", WHITE),
 "Azerbaijan": solid("#212121") + f"|C:.5,.5,.2,{WHITE}",
 "Georgia": cross(WHITE, RED, .5, .14),
 "India": cres(GRN, WHITE),
 "Nepal": solid("#6a1b9a") + f"|C:.5,.5,.2,{GOLD}",
 "Turkey": cresstar(RED, WHITE),
 "North Macedonia": cres(SKY, GOLD),
 "Montenegro": disc("#455a64", WHITE, .2),
 "Greece": solid(DRED) + f"|K:{GOLD},.08,.5,.5|C:.25,.25,.05,{GOLD}|C:.75,.25,.05,{GOLD}|C:.25,.75,.05,{GOLD}|C:.75,.75,.05,{GOLD}",
 "Egypt": cres(GOLD, RED),
 "Germany": diamond(GOLD, BLK),
 "Spain": f"{solid(RED)}|R:.3,.25,.7,.75,{GOLD}|R:.4,.5,.6,.75,{RED}",
 "Andorra": H(GOLD, RED, GOLD, RED, GOLD, RED, GOLD, RED, GOLD),
 "Italy": V(RED, WHITE, GOLD) if False else solid(RED) + f"|C:.5,.5,.2,{GOLD}",
 "Malta": solid(BLUE) + f"|S:.3,.35,.08,{GOLD},8|S:.7,.35,.08,{GOLD},8|S:.5,.68,.08,{GOLD},8",
 "Belgium": disc(GOLD, BLK, .22),
 "Cyprus": cross(WHITE, GOLD, .5, .14),
 "Denmark": f"{solid(GOLD)}|C:.33,.36,.09,{BLUE}|C:.67,.36,.09,{BLUE}|C:.5,.68,.09,{BLUE}",
 "Sweden": three(BLUE, GOLD),
 "Poland": diamond(RED, WHITE, .26),
 "Hungary": H(RED, WHITE, RED, WHITE, RED, WHITE, RED, WHITE),
 "Lithuania": ring(RED, WHITE, .2),
 "Russia": solid(RED) + f"|C:.5,.5,.17,{WHITE}",
 "Greenland": V(RED, WHITE),
 "Latvia": cross(WHITE, BLK, .4, .14),
 "Bulgaria": disc(RED, GOLD, .2),
 "Serbia": serb(RED, GOLD),
 "Bosnia and Herz.": three(BLUE, GOLD, .08),
 "Albania": diamond(RED, BLK, .24),
 "Morocco": star(WHITE, RED, 8, .22),
 "Algeria": cres(GRN, WHITE),
 "Japan": disc(WHITE, RED, .25),
 "South Korea": ring(WHITE, BLUE, .2),
 "Myanmar": disc(RED, GOLD, .2),
 "Vietnam": solid(RED) + f"|C:.5,.5,.2,{GOLD}",
 "Indonesia": H(RED, WHITE),
 "Niger": disc(GOLD, "#2e7d32", .2),
 "Mali": star(GOLD, GRN, 8, .22),
 "Mexico": disc("#00838f", GOLD, .22),
 "Peru": disc(GOLD, RED, .2),
})

# ---------------- WW1 (1914)
UJ = "UJ:0,0,1,1"
WW1 = {
 "Turkey": cresstar(RED, WHITE),
 "Russia": H(WHITE, BLUE, RED) if False else H(BLK, GOLD, WHITE),
 "United Kingdom": UJ,
 "Japan": f"{solid(WHITE)}|C:.5,.5,.2,{RED}|L:{RED},.05,.0,.5,.3,.5|L:{RED},.05,.7,.5,1,.5|L:{RED},.05,.5,.0,.5,.3|L:{RED},.05,.5,.7,.5,1",
 "Italy": V("#009246", WHITE, "#ce2b37") + f"|R:.38,.3,.62,.7,{BLUE}|C:.5,.5,.1,{WHITE}",
 "Serbia": H(RED, BLUE, WHITE),
 "Belgium": V(BLK, GOLD, RED),
 "Bulgaria": H(WHITE, "#00966e", RED),
 "Romania": V(BLUE, GOLD, RED),
 "Greece": f"{H(BLUE, WHITE, BLUE, WHITE, BLUE, WHITE, BLUE, WHITE, BLUE)}|R:0,0,.4,.556,{BLUE}|K:{WHITE},.12,.2,.28",
 "Montenegro": H(RED, BLUE, WHITE) + f"|C:.5,.5,.1,{GOLD}",
 "Netherlands": H(RED, WHITE, "#21468b"),
 "Spain": H(RED, GOLD, RED) + "*1" if False else "H:#aa151b*1,#f1bf00*2,#aa151b*1",
 "Sweden": cross(BLUE, GOLD, .37, .16),
 "Norway": cross(RED, WHITE, .37, .22) + f"|K:{BLUE},.1,.37,.5",
 "Denmark": cross(RED, WHITE, .37, .16),
 "Portugal": V(GRN, RED) if False else "V:#2e7d32*2,#c8102e*3",
 "Canada": f"{solid(RED)}|R:0,0,.5,.5,#1c3f94|L:#ffffff,.06,0,0,.5,.5|L:#ffffff,.06,.5,0,0,.5",
 "Australia": f"{solid('#00247d')}|R:0,0,.5,.5,#00247d|S:.75,.7,.07,{WHITE},7",
 "New Zealand": f"{solid('#00247d')}|S:.75,.35,.05,{RED},5|S:.65,.55,.05,{RED},5|S:.85,.55,.05,{RED},5",
 "South Africa": H(RED, WHITE, BLUE) + f"|P:{GRN},0,0,.4,.5,0,1",
 "Iran": H(GRN, WHITE, RED) + f"|C:.5,.5,.1,{GOLD}",
 "Switzerland": cross(RED, WHITE, .5, .2),
 "Thailand": H(RED, WHITE, RED) + f"|C:.5,.5,.1,{WHITE}",
 "Brazil": H(GRN, WHITE, GRN, WHITE, GRN, WHITE, GRN, WHITE, GRN) if False else "R:0,0,1,1,#009c3b|P:#ffdf00,.5,.1,.92,.5,.5,.9,.08,.5|C:.5,.5,.2,#002776|S:.5,.5,.05,#ffffff,5",
 "Argentina": H(SKY, WHITE, SKY) + f"|C:.5,.5,.08,{GOLD}",
 "France": V(BLUE, WHITE, RED),
 "United States of America": "H:#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234|R:0,0,.4,.538,#3c3b6e|G:.03,.05,.37,.49,5,4,.03,w",
}

# ---------------- WW2 (1939)
WW2 = {
 "United Kingdom": UJ, "Canada": f"{solid('#c8102e')}|R:0,0,.5,.5,#c8102e|L:#ffffff,.06,0,0,.5,.5|L:#ffffff,.06,.5,0,0,.5",
 "Italy": V("#009246", WHITE, "#ce2b37") + f"|R:.38,.3,.62,.7,{RED}|C:.5,.5,.08,{WHITE}",
 "Japan": f"{solid(WHITE)}|C:.5,.5,.22,{RED}",
 "Poland": H(WHITE, RED),
 "Spain": H(RED, GOLD, RED) if False else "H:#aa151b*1,#f1bf00*2,#aa151b*1",
 "Turkey": cresstar(RED, WHITE),
 "Romania": V(BLUE, GOLD, RED) + f"|C:.5,.5,.08,{BLUE}",
 "Australia": f"{solid('#00247d')}|S:.75,.7,.07,{WHITE},7",
 "New Zealand": f"{solid('#00247d')}|S:.75,.35,.05,{RED},5|S:.65,.55,.05,{RED},5|S:.85,.55,.05,{RED},5",
 "South Africa": H(RED, WHITE, BLUE),
 "Finland": cross(WHITE, BLUE, .37, .16),
 "Hungary": H(RED, WHITE, GRN),
 "Bulgaria": H(WHITE, "#00966e", RED),
 "Greece": f"{H(BLUE, WHITE, BLUE, WHITE, BLUE, WHITE, BLUE, WHITE, BLUE)}|R:0,0,.4,.556,{BLUE}|K:{WHITE},.12,.2,.28",
 "Iran": H(GRN, WHITE, RED) + f"|C:.5,.5,.1,{GOLD}",
 "Egypt": H(RED, WHITE, "#2e7d32") if False else solid(GRN) + f"|C:.4,.5,.2,{WHITE}|C:.47,.5,.17,{GRN}|S:.62,.4,.05,{WHITE}|S:.62,.5,.05,{WHITE}|S:.62,.6,.05,{WHITE}",
 "Iraq": V(RED, WHITE, BLK) if False else H(BLK, WHITE, "#2e7d32") + f"|P:{RED},0,0,.4,.5,0,1",
 "Saudi Arabia": solid("#006c35") + f"|R:.2,.55,.8,.6,{WHITE}",
 "Thailand": H(RED, WHITE, BLUE, WHITE, RED) if False else "H:#a51931*1,#f4f5f8*1,#2d2a4a*2,#f4f5f8*1,#a51931*1",
 "Brazil": "R:0,0,1,1,#009c3b|P:#ffdf00,.5,.1,.92,.5,.5,.9,.08,.5|C:.5,.5,.2,#002776",
 "Mongolia": V(RED, BLUE, RED) + f"|C:.17,.5,.06,{GOLD}",
 "Ireland": V(GRN, WHITE, "#ff883e"),
 "Slovakia": H(WHITE, BLUE, RED) + f"|R:.15,.25,.4,.75,{RED}",
 "Netherlands": H(RED, WHITE, "#21468b"), "Belgium": V(BLK, GOLD, RED),
 "France": V(BLUE, WHITE, RED), "Norway": cross(RED, WHITE, .37, .22) + f"|K:{BLUE},.1,.37,.5",
 "Denmark": cross(RED, WHITE, .37, .16), "Sweden": cross(BLUE, GOLD, .37, .16),
 "Portugal": "V:#2e7d32*2,#c8102e*3", "Argentina": H(SKY, WHITE, SKY) + f"|C:.5,.5,.08,{GOLD}",
 "Mexico": V("#006847", WHITE, "#ce1126") + f"|C:.5,.5,.1,#8a5a2b",
}

# ---------------- Soğuk Savaş 1962
CW = {
 "United States of America": "H:#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234,w,#b22234|R:0,0,.4,.538,#3c3b6e|G:.03,.05,.37,.49,5,4,.03,w",
 "Russia": f"{solid('#cc0000')}|S:.14,.2,.09,#ffd700|P:#ffd700,.07,.38,.22,.34,.22,.4,.07,.42",
 "Germany": H(BLK, RED, GOLD),
 "China": f"{solid('#de2910')}|S:.17,.26,.15,#ffde00|S:.33,.1,.05,#ffde00|S:.4,.2,.05,#ffde00|S:.4,.34,.05,#ffde00|S:.33,.45,.05,#ffde00",
 "Cuba": "H:#002a8f,w,#002a8f,w,#002a8f|P:#cf142b,0,0,.45,.5,0,1|S:.15,.5,.1,#ffffff,5",
 "Egypt": H(RED, WHITE, BLK) + f"|S:.4,.5,.06,{GRN}|S:.6,.5,.06,{GRN}",
 "Serbia": H(BLUE, WHITE, RED) + f"|S:.5,.5,.1,{GOLD}",
 "Czechia": H(WHITE, RED) + f"|P:{BLUE},0,0,.5,.5,0,1",
 "Italy": V("#009246", WHITE, "#ce2b37"),
 "Poland": H(WHITE, RED), "Japan": f"{solid(WHITE)}|C:.5,.5,.22,{RED}",
 "Turkey": cresstar(RED, WHITE),
 "India": H("#ff9933", WHITE, "#138808") + f"|O:#000080,.012,.5,.5,.14",
}

# bugünkü bayrakla aynı olanlar listeden çıkar (gerçek PNG bayrak daha iyi görünür)
for _e, _ks in {"ww1": ["France", "Netherlands", "Belgium", "Sweden", "Denmark", "Switzerland", "United States of America", "Argentina", "Norway"],
				"ww2": ["France", "Netherlands", "Belgium", "Sweden", "Denmark", "Norway", "Argentina", "Japan", "Poland", "Hungary", "Turkey", "Belgium", "Mexico", "Brazil"],
				"cw62": ["United States of America", "Germany", "Italy", "Poland", "Japan", "India", "Turkey"]}.items():
	for _k in _ks:
		{"ww1": WW1, "ww2": WW2, "cw62": CW}[_e].pop(_k, None)

ERAS = {"ww1": WW1, "ww2": WW2, "cw62": CW, "ott1520": OTT, "tim1380": TIM}
if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "era_flags.json")
    json.dump(ERAS, open(out, "w"), ensure_ascii=False, indent=0)
    print({k: len(v) for k, v in ERAS.items()})

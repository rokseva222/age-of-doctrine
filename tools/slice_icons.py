#!/usr/bin/env python3
"""Tek görselde (ızgara) üretilmiş ikonları assets/icons/<ad>_c.png olarak keser.
Kullanım: python3 tools/slice_icons.py sayfa.png [sütun] [satır] [--set=objects|pack2|pack3|pack4|pack5|pack6|pack7|pack8|pack9|pack10|pack11|pack12|pack13|pack14|items01..items11|all] [--start=N] [--mono] [--tiles]
 - İkonlar soldan sağa, yukarıdan aşağıya tools/ICON_PROMPTS.md'deki sırayla dizilmeli.
 - Düz magenta (#FF00FF) arka plan (veya şeffaf) otomatik şeffaflaştırılır; renkli ikon korunur.
 - --mono: renkleri beyaz tek renk glife çevirir ve <ad>.png yazar (oyun bunu duruma göre boyar).
"""
import sys, os, re
from PIL import Image
OBJECTS = "coins sword swords shield news users globe flag crown handshake skull star trophy target factory flame home lock trend hourglass anchor book map siren castle plane ship tank wheat bolt scroll rifle afv arty jet heli drone sub missile radar cyber med shield_star badge eye oil trade embassy sanction gavel briefcase".split()
PACK2 = ['megaphone', 'bomb', 'spy', 'explosion', 'paratrooper', 'landing', 'nuke', 'white_flag', 'bank', 'money_bag', 'debt', 'chip', 'steel', 'gas', 'uranium', 'mine', 'virus', 'earthquake', 'flood', 'drought', 'protest', 'coup', 'refugees', 'storm', 'dove', 'treaty', 'summit', 'ballot', 'passport', 'medal', 'laurel', 'helmet', 'helmet_ww1', 'helmet_ww2', 'biplane', 'bomber', 'battleship', 'infantry', 'cavalry', 'trench', 'stability', 'industry', 'truck', 'flask', 'hacker', 'unrest', 'city', 'calendar']
PACK3 = ['port', 'airbase', 'oil_well', 'farm', 'power_plant', 'nuclear_plant', 'university', 'hospital', 'capital', 'bunker', 'barracks', 'arsenal', 'refinery', 'dam', 'railway', 'fortress', 'marines', 'special_forces', 'mlrs', 'aa_gun', 'stealth_bomber', 'carrier', 'destroyer', 'jammer', 'cargo_ship', 'train', 'crate', 'fuel', 'ammo', 'satellite', 'radio_tower', 'convoy', 'alliance_shield', 'bloc', 'embargo', 'aid', 'recruit', 'veteran', 'poster', 'tribute', 'warning', 'siege', 'occupied', 'annex', 'independence', 'ceasefire', 'reinforce', 'retreat']
PACK4 = ['pt_west_m', 'pt_west_f', 'pt_west_mm', 'pt_west_fm', 'pt_slav_m', 'pt_slav_f', 'pt_slav_mm', 'pt_slav_fm', 'pt_turk_m', 'pt_turk_f', 'pt_turk_mm', 'pt_turk_fm', 'pt_gulf_m', 'pt_gulf_f', 'pt_gulf_mm', 'pt_gulf_fm', 'pt_lev_m', 'pt_lev_f', 'pt_lev_mm', 'pt_lev_fm', 'pt_pers_m', 'pt_pers_f', 'pt_pers_mm', 'pt_pers_fm', 'pt_sasia_m', 'pt_sasia_f', 'pt_sasia_mm', 'pt_sasia_fm', 'pt_easia_m', 'pt_easia_f', 'pt_easia_mm', 'pt_easia_fm', 'pt_seasia_m', 'pt_seasia_f', 'pt_seasia_mm', 'pt_seasia_fm', 'pt_afr_m', 'pt_afr_f', 'pt_afr_mm', 'pt_afr_fm', 'pt_latam_m', 'pt_latam_f', 'pt_latam_mm', 'pt_latam_fm', 'pt_pac_m', 'pt_pac_f', 'pt_pac_mm', 'pt_pac_fm']
PACK5 = ['un_peacekeeper', 'assembly_hall', 'rebuild', 'develop', 'guarantee', 'probe', 'disarm', 'reparations', 'buffer_zone', 'hold_position', 'general', 'airstrike', 'fog_of_war', 'hint', 'chronicle', 'leader_bust', 'relations', 'war_declared', 'blockade', 'supply_cut', 'energy', 'tech', 'intel_report', 'mine_cart', 'medal_bronze', 'medal_silver', 'medal_gold', 'five_stars', 'sanction_lift', 'radiation', 'armistice_car', 'surrender_deck']
PACK6 = ['strait', 'canal', 'toll_gate', 'strait_closed', 'tanker', 'shipping_lane', 'strait_control', 'trade_shock', 'politics', 'martial_law', 'generals_plot', 'reform', 'constitution', 'democratize', 'power_tower', 'regime_change', 'war_room', 'attack_phases', 'phase_wait', 'phase_success', 'phase_fail', 'reserve_force', 'combined_arms', 'capital_falls', 'daily_challenge', 'score_star', 'streak_flame', 'alt_history', 'what_if', 'grand_operation', 'uprising_banner', 'founding_scroll']
PACK7 = ['phase_spark', 'phase_uprising', 'phase_negotiation', 'phase_statehood', 'phase_consolidation', 'method_uprising', 'method_coup', 'method_political', 'ideo_liberal', 'ideo_social', 'ideo_national', 'ideo_traditional', 'ideo_federal', 'ideo_techno', 'foreign_patron', 'recognition_stamp', 'card_leak', 'card_diaspora', 'card_students', 'card_raid', 'card_elders', 'card_swap', 'card_journalist', 'card_hunger', 'card_autonomy', 'card_hardliners', 'card_currency', 'card_militia', 'card_border', 'card_election', 'card_investors', 'card_constitution']
PACK8 = ['era_ott1520', 'era_tim1380', 'era_cw62', 'mode_story', 'mobilize', 'mob_active', 'rel_hostile', 'rel_cold', 'rel_warm', 'rel_close', 'passage_grant', 'passage_deny', 'army_split', 'vote_yes', 'vote_no', 'vote_abstain', 'un_hall', 'un_notice', 'border_clash', 'border_cede', 'border_talk', 'plague', 'famine', 'bombard', 'galley', 'matchlock', 'horse_archer', 'yurt', 'palace_domes', 'caravan', 'war_standard', 'decree']
PACK9 = ['carrier_strike', 'carrier_ready', 'carrier_refit', 'jet_launch', 'diplomacy', 'gift', 'improve_rel', 'embargo_lift']
PACK10 = ['u_azap', 'u_sipahi', 'u_akinci', 'u_kapikulu', 'u_darbzen', 'u_basilisk', 'u_galiot', 'u_hussar', 'u_elephant', 'u_trebuchet', 'u_siege_tower', 'u_crossbow', 'u_mamluk', 'u_knight', 'u_pikeman', 'u_arquebus', 'u_ming_cannon', 'u_siege_camp', 'u_castle', 'u_ladder', 'u_trench_mortar', 'u_zeppelin', 'u_gas_mask', 'u_dreadnought', 'u_mark_tank', 'u_biplane_bomber', 'u_mg_nest', 'u_armored_car', 'u_icbm_silo', 'u_spy_plane', 'u_nuclear_sub', 'u_helicopter']
PACK11 = ['b_caravanserai', 'b_bazaar', 'b_shipyard', 'b_mint', 'b_treasury', 'b_granary', 'b_mine', 'b_aqueduct', 'b_bridge', 'b_lighthouse', 'b_wall', 'b_library', 'b_observatory', 'b_toll', 'b_corsair', 'b_spice', 'b_silk', 'b_horse_market', 'b_harvest', 'b_well', 'e_ration', 'e_shelter', 'e_telegraph', 'e_war_bond', 'e_poster', 'e_field_hospital', 'e_codebreak', 'e_convoy', 'e_hotline', 'e_fallout', 'e_space_race', 'e_blockade']
PACK12 = ['w2_panzer', 'w2_sherman', 'w2_t34', 'w2_heavy_tank', 'w2_halftrack', 'w2_jeep', 'w2_flak88', 'w2_katyusha', 'w2_howitzer', 'w2_fighter', 'w2_stuka', 'w2_heavy_bomber', 'w2_zero', 'w2_uboat', 'w2_battleship', 'w2_landing_craft', 'w2_garand', 'w2_mp40', 'w2_mg42', 'w2_panzerfaust', 'w2_radar', 'w2_paratrooper', 'w2_torpedo', 'w2_mine', 'cw_mig', 'cw_t55', 'cw_b52', 'cw_polaris', 'cw_sam', 'cw_apc', 'cw_icbm', 'cw_spy_satellite']
PACK13 = ['op_night', 'op_armor', 'op_siege', 'op_encircle', 'op_deception', 'vassal', 'surrender', 'spy_send', 'focus', 'focus_eco', 'focus_mil', 'focus_dip', 'focus_pol', 'faith_christian', 'faith_islam', 'faith_dharmic', 'faith_other', 'faith', 'regime', 'currency', 'sandbox', 'year', 'map_paint', 'transfer', 'tribute', 'release_state', 'embargo_ship', 'treaty_scroll', 'dove_peace', 'spy_net', 'intel_report', 'radiation_warn']
PACK14 = ['m_abrams', 'm_patton', 'm_leopard', 'm_t72', 'm_t14', 'm_type99', 'm_merkava', 'm_k2', 'm_leclerc', 'm_f35', 'm_f15', 'm_f16', 'm_su57', 'm_su27', 'm_rafale', 'm_apache', 'm_tb2', 'm_kamikaze', 'm_kizilelma', 'm_su25', 'm_mig21', 'm_himars', 'm_grad', 'm_spg', 'm_spg_wheeled', 'm_tos', 'm_bmp', 'm_bradley', 'm_wheeled', 'm_apc_old', 'm_sub_nuke', 'm_sub_diesel']

PACK15 = ['uc_transport', 'uc_amphib', 'uc_frigate', 'uc_cruiser']

import json as _json, os as _os
_ITEMS = _json.load(open(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "item_sets.json")))
ITEMSETS = {k: ["x_" + i for i in v] for k, v in _ITEMS.items()}

RAW60 = ['pt_raw_%02d' % i for i in range(60)]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
src = open(os.path.join(root, "scripts/icons.gd")).read()
allnames = re.findall(r'"([a-z0-9_]+)"', re.search(r'const NAMES := \[(.*?)\]', src, re.S).group(1))
opts = {a.split("=")[0]: (a.split("=")[1] if "=" in a else True) for a in sys.argv[1:] if a.startswith("--")}
args = [a for a in sys.argv[1:] if not a.startswith("--")]
names = {"objects": OBJECTS, "pack2": PACK2, "pack3": PACK3, "pack4": PACK4, "pack5": PACK5, "pack6": PACK6, "pack7": PACK7, "pack8": PACK8, "pack9": PACK9, "pack10": PACK10, "pack11": PACK11, "pack12": PACK12, "pack13": PACK13, "pack14": PACK14, "pack15": PACK15, "raw60": RAW60, **ITEMSETS}.get(opts.get("--set", "objects"), allnames)
start = int(opts.get("--start", 0))
mono = "--mono" in opts
if "--tiles" in opts:
    # Gemini ikonları koyu yuvarlak karelerin içinde üretirse: kareleri bulur, kare arka planını siler
    import numpy as np
    from scipy import ndimage
    im = Image.open(args[0]).convert("RGB")
    a = np.array(im).astype(int)
    mag = (a[:, :, 0] > 190) & (a[:, :, 1] < 110) & (a[:, :, 2] > 190)
    lab, n = ndimage.label(~mag)
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        if h > 40 and w > 40:
            boxes.append((sl[0].start, sl[1].start, sl[0].stop, sl[1].stop))
    boxes.sort(key=lambda b: (round((b[0] + b[2]) / 2 / 60), b[1]))
    names = {"objects": OBJECTS, "pack2": PACK2, "pack3": PACK3, "pack4": PACK4, "pack5": PACK5, "pack6": PACK6, "pack7": PACK7, "pack8": PACK8, "pack9": PACK9, "pack10": PACK10, "pack11": PACK11, "pack12": PACK12, "pack13": PACK13, "pack14": PACK14, "pack15": PACK15, "raw60": RAW60, **ITEMSETS}.get(opts.get("--set", "objects"), allnames)
    out = os.path.join(root, "assets/icons"); os.makedirs(out, exist_ok=True)
    cnt = 0
    for name, (y0, x0, y1, x1) in zip(names[int(opts.get("--start", 0)):], boxes):
        c = a[y0:y1, x0:x1].copy()
        ring = np.concatenate([c[3:6, 8:-8].reshape(-1, 3), c[-6:-3, 8:-8].reshape(-1, 3), c[8:-8, 3:6].reshape(-1, 3), c[8:-8, -6:-3].reshape(-1, 3)])
        tile = np.median(ring, axis=0)
        d = np.abs(c - tile).sum(axis=2)
        flood = "--flood" in opts                              # yüzsüz portreler: koyu gövde karenin renginde, yalnızca dıştan taşan alan silinir
        near = d < (32 if flood else 45)
        bgm = ndimage.binary_dilation(mag[y0:y1, x0:x1], iterations=1)
        seed = (near & bgm) | (near & (np.arange(c.shape[0])[:, None] < 4)) | (near & (np.arange(c.shape[1])[None, :] < 4)) | (near & (np.arange(c.shape[0])[:, None] > c.shape[0] - 5)) | (near & (np.arange(c.shape[1])[None, :] > c.shape[1] - 5))
        if flood:
            near = ~ndimage.binary_dilation(~near, iterations=2)           # kontur boşluklarını kapat (sızmayı önler)
            yy0, xx0 = np.mgrid[0:c.shape[0], 0:c.shape[1]]
            W_ = c.shape[1]
            band = (((yy0 < 18) & ((xx0 < W_ * 0.2) | (xx0 > W_ * 0.8))) | (xx0 < 16) | (xx0 > W_ - 17)) & (yy0 < c.shape[0] * 0.8)
            seed = (seed | band) & near
        lab2, _ = ndimage.label(near)
        keep = np.unique(lab2[seed]); keep = keep[keep > 0]
        removed = np.isin(lab2, keep) | mag[y0:y1, x0:x1]
        if flood:
            removed = ndimage.binary_dilation(removed, iterations=2) & ((d < 70) | mag[y0:y1, x0:x1])
            yz, xz = np.mgrid[0:c.shape[0], 0:c.shape[1]]
            removed |= ((yz < 6) | (xz < 5) | (xz > c.shape[1] - 6)) & (d < 110)      # kare kenar çizgisi (altta gövde var, dokunma)
        else:
            removed |= (d < 20)                                # kapalı iç boşluklar
        edge = ndimage.binary_dilation(removed, iterations=1) & ~removed & (d < (60 if flood else 90))
        removed |= edge                                        # kenardaki lacivert halka
        yy, xx = np.mgrid[0:c.shape[0], 0:c.shape[1]]
        ring_zone = (yy < 8) | (xx < 8) | (yy > c.shape[0] - 9) | (xx > c.shape[1] - 9)
        tint = ((c[:, :, 0] - c[:, :, 1]) > 28) & ((c[:, :, 2] - c[:, :, 1]) > 28)   # magenta karışımı mor halka
        removed |= (ring_zone & tint)
        if not flood:
            removed |= ring_zone & (d < 110)                   # karenin kenar çizgisi
        alpha = np.where(removed, 0, 255).astype(np.uint8)
        rgba = np.dstack([c.astype(np.uint8), alpha])
        cell = Image.fromarray(rgba, "RGBA")
        bb = cell.getbbox()
        if bb is None: continue
        cell = cell.crop(bb); sz = max(cell.size)
        sq = Image.new("RGBA", (int(sz * 1.12), int(sz * 1.12)), (0, 0, 0, 0))
        sq.paste(cell, ((sq.width - cell.width) // 2, (sq.height - cell.height) // 2))
        sq.resize((256, 256), Image.LANCZOS).save(os.path.join(out, name + "_c.png")); cnt += 1
    print("kaydedilen ikon (kareli sayfa):", cnt, "/ kare:", len(boxes), "->", out)
    sys.exit(0)
img = Image.open(args[0]).convert("RGBA")
cols = int(args[1]) if len(args) > 1 else 8
rows = int(args[2]) if len(args) > 2 else (len(names) + cols - 1) // cols
cw, ch = img.width / cols, img.height / rows
out = os.path.join(root, "assets/icons"); os.makedirs(out, exist_ok=True)
bg = img.getpixel((2, 2))
if bg[3] > 10 and not (abs(bg[0] - 255) < 70 and bg[1] < 90 and abs(bg[2] - 255) < 70):
    print("uyarı: köşe rengi magenta değil, yine de bu renk arka plan sayılacak:", bg)
def dist(p):
    return abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2])
n = 0
for i, name in enumerate(names[start:]):
    r, c = divmod(i, cols)
    if r >= rows: break
    cell = img.crop((int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch)))
    px = cell.load()
    for y in range(cell.height):
        for x in range(cell.width):
            p = px[x, y]
            if bg[3] < 10:
                transparent = p[3] < 10
                a = 0 if transparent else 255
            else:
                d = dist(p)
                a = 0 if d < 90 else (255 if d > 200 else int((d - 90) / 110 * 255))   # kenar yumuşatma
            if a == 0:
                px[x, y] = (255, 255, 255, 0)
            elif mono:
                px[x, y] = (255, 255, 255, a)
            else:
                px[x, y] = (p[0], p[1], p[2], a)
    bb = cell.getbbox()
    if bb is None: continue
    cell = cell.crop(bb)
    s = max(cell.size)
    sq = Image.new("RGBA", (int(s * 1.15), int(s * 1.15)), (0, 0, 0, 0))
    sq.paste(cell, ((sq.width - cell.width) // 2, (sq.height - cell.height) // 2))
    sq = sq.resize((256, 256), Image.LANCZOS)
    sq.save(os.path.join(out, name + ("" if mono else "_c") + ".png")); n += 1
print("kaydedilen ikon:", n, "->", out)

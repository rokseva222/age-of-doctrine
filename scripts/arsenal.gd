extends RefCounted
## Silah kataloğu: isimli tüfek, tank, zırhlı araç, top/roketatar, uçak/İHA/helikopter, denizaltı.
## Fiyatlar yaklaşık (milyon $ / adet; "inf" için 1.000 kişilik set). Tier 1 = eski nesil … 4 = en yeni.

const CATS := ["inf", "tank", "afv", "arty", "air", "sub"]
const CAT_NAME := {"inf": "Piyade Tüfeği", "tank": "Tank", "afv": "Zırhlı Araç", "arty": "Top & Roketatar", "air": "Uçak & İHA", "sub": "Denizaltı"}
## Çağa göre sınıf adları (silah tablosunun "cat_names" alanı); yoksa modern adlar
static var cat_names_ovr: Dictionary = {}


static func cat_name(k: String) -> String:
	return String(cat_names_ovr.get(k, CAT_NAME[k]))


# ------------------------------------------------------------ simgeler (çağa ve birliğe göre)
const CAT_ICON := {"inf": "rifle", "tank": "tank", "afv": "afv", "arty": "arty", "air": "jet", "sub": "sub"}
const CAT_ICON_FAM := {
	"pre": {"inf": "u_azap", "tank": "u_sipahi", "afv": "u_akinci", "arty": "u_darbzen", "air": "jet", "sub": "u_galiot"},
	"ww1": {"inf": "w2_garand", "tank": "u_mark_tank", "afv": "u_armored_car", "arty": "w2_howitzer", "air": "biplane", "sub": "u_dreadnought"},
	"ww2": {"inf": "w2_garand", "tank": "w2_sherman", "afv": "w2_halftrack", "arty": "w2_howitzer", "air": "w2_fighter", "sub": "w2_uboat"},
	"cold": {"inf": "rifle", "tank": "cw_t55", "afv": "cw_apc", "arty": "arty", "air": "cw_mig", "sub": "u_nuclear_sub"},
}
## Birlik kimliğinden simge: önce birliğe özel, sonra çağın sınıf simgesi, en sonda modern sınıf simgesi (Icons.pick dosya yoksa yedeğe düşer)
const ITEM_ICON := {
	"i_azap": "u_azap", "i_jani": "era_ott1520", "i_jani2": "era_ott1520", "i_lands": "u_pikeman", "i_tercio": "u_pikeman", "i_swiss": "u_pikeman",
	"i_pike": "u_pikeman", "i_halb": "u_pikeman", "i_arqfr": "u_arquebus", "i_tofang": "u_arquebus", "i_mingf": "u_ming_cannon", "i_mughal": "u_arquebus",
	"i_longbow": "horse_archer", "i_bow2": "horse_archer", "i_archer": "u_crossbow", "i_kizil": "u_azap", "i_levy": "u_azap", "i_tribal": "u_azap",
	"i_ming": "u_azap", "i_ashig": "u_pikeman", "i_sword": "u_azap", "i_guard": "u_azap", "i_firelance": "u_arquebus",
	"t_sipahi": "u_sipahi", "t_kapikulu": "u_kapikulu", "t_knight": "u_knight", "t_gend": "u_knight", "t_reiter": "u_kapikulu", "t_hussar": "u_hussar",
	"t_kizilc": "u_sipahi", "t_ming_c": "u_sipahi", "t_samurai": "u_sipahi", "t_boyar": "u_kapikulu", "t_eleph": "u_elephant", "t_tribe_c": "u_sipahi",
	"t_cata": "u_knight", "t_mamluk": "u_mamluk", "t_timur": "u_kapikulu", "t_keshik": "u_kapikulu", "t_druzhina": "u_knight", "t_lith": "u_knight",
	"a_akinci": "u_akinci", "a_deli": "u_akinci", "a_hussar_l": "u_hussar", "a_strad": "u_akinci", "a_horsearch": "era_tim1380", "a_tatar": "era_tim1380",
	"a_ming_l": "u_akinci", "a_rajput": "u_mamluk", "a_turkmen": "era_tim1380", "a_camel": "caravan",
	"y_catap": "u_trebuchet", "y_bombard": "bombard", "y_darb": "u_darbzen", "y_basil": "u_basilisk", "y_culv": "u_darbzen", "y_falc": "u_darbzen",
	"y_rocket": "u_ming_cannon", "y_fo": "u_ming_cannon", "y_ram": "u_siege_tower", "y_trebu": "u_trebuchet",
	"s_dhow": "u_galiot", "s_galley": "galley", "s_galley2": "galley", "s_cog": "u_galiot", "s_carrack": "u_galiot", "s_kalite": "galley",
	"s_galleass": "galley", "s_galleon": "u_galiot", "s_junk": "u_galiot",
	# --- WW1 / WW2 / Soğuk Savaş
	"i_gew98": "w2_garand", "i_mg08": "w2_mg42", "i_mg1718": "w2_mg42", "i_mp18": "w2_mp40", "i_smle": "w2_garand", "i_vickers": "w2_mg42", "i_lewis": "w2_mg42",
	"i_lebel": "w2_garand", "i_chauchat": "w2_mg42", "i_berthier": "w2_garand", "i_mosin": "w2_garand", "i_maxim": "w2_mg42", "i_mann": "w2_garand", "i_mann2": "w2_mg42",
	"i_mauser": "w2_garand", "i_springfield": "w2_garand", "i_garand": "w2_garand", "i_arisaka": "w2_garand", "i_carcano": "w2_garand",
	"t_mk1": "u_mark_tank", "t_mk4": "u_mark_tank", "t_mk5": "u_mark_tank", "t_schn": "u_mark_tank", "t_ft17": "u_mark_tank", "t_a7v": "u_mark_tank",
	"a_rr": "u_armored_car", "a_aust": "u_armored_car", "a_eh": "u_armored_car", "a_peug": "u_armored_car", "y_fk96": "w2_howitzer", "y_21": "w2_howitzer",
	"i_k98": "w2_garand", "i_mp40": "w2_mp40", "i_g43": "w2_mg42", "i_stg44": "w2_mp40", "i_svt": "w2_garand", "i_ppsh": "w2_mp40", "i_enfield": "w2_garand",
	"i_sten": "w2_mp40", "i_carbine": "w2_mp40", "i_type100": "w2_mp40",
	"t_pz1": "w2_panzer", "t_pz3": "w2_panzer", "t_pz4": "w2_panzer", "t_panther": "w2_panzer", "t_tiger": "w2_heavy_tank", "t_t26": "w2_t34", "t_t34": "w2_t34",
	"t_kv1": "w2_heavy_tank", "t_t3485": "w2_t34", "t_is2": "w2_heavy_tank", "t_vick": "w2_sherman", "t_matilda": "w2_heavy_tank", "t_crus": "w2_sherman",
	"t_crom": "w2_sherman", "t_stuart": "w2_sherman", "t_sherman": "w2_sherman", "t_pershing": "w2_heavy_tank", "t_r35": "w2_sherman", "t_b1": "w2_heavy_tank",
	"t_l3": "w2_sherman", "t_m13": "w2_sherman", "t_chiha": "w2_t34", "t_chihan": "w2_t34", "t_7tp": "w2_sherman", "t_lt38": "w2_panzer",
	"a_sdkfz222": "u_armored_car", "a_sdkfz251": "w2_halftrack", "a_ba10": "u_armored_car", "a_ba64": "w2_jeep", "a_carrier": "w2_halftrack",
	"a_daimler": "w2_jeep", "a_m3": "w2_halftrack", "a_m8": "u_armored_car", "a_amr": "u_armored_car", "a_as37": "w2_jeep", "a_type94": "w2_halftrack",
	"y_lefh18": "w2_howitzer", "y_sfh18": "w2_howitzer", "y_nebel": "w2_katyusha", "y_m30": "w2_howitzer", "y_zis3": "w2_howitzer", "y_katyusha": "w2_katyusha",
	"y_25pdr": "w2_howitzer", "y_m101": "w2_howitzer", "y_m2": "w2_howitzer", "y_m1897": "w2_howitzer", "y_cann": "w2_howitzer", "y_type91": "w2_howitzer",
	"f_pzlp11": "w2_fighter", "f_i16": "w2_fighter", "f_yak9": "w2_stuka", "f_la7": "w2_fighter", "f_bf109": "w2_fighter", "f_fw190": "w2_fighter",
	"f_me262": "cw_mig", "f_hurr": "w2_fighter", "f_spit": "w2_heavy_bomber", "f_spit2": "w2_fighter", "f_p40": "w2_fighter", "f_p47": "w2_heavy_bomber",
	"f_p51": "w2_heavy_bomber", "f_ms406": "w2_fighter", "f_cr42": "biplane", "f_ki27": "w2_zero", "f_zero": "w2_zero",
	"s_s": "w2_uboat", "s_vii": "w2_uboat", "s_ix": "w2_uboat", "s_t": "w2_uboat", "s_gato": "w2_uboat", "s_redout": "w2_uboat", "s_marcello": "w2_uboat", "s_i": "w2_uboat",
	"i_m1": "w2_garand", "i_m14": "w2_mg42", "i_m16": "w2_mp40", "i_sks": "w2_garand", "i_ak47": "w2_mp40", "i_akm": "w2_mp40", "i_slr": "w2_garand",
	"i_mas49": "w2_garand", "i_fn": "w2_mg42", "i_g3": "w2_garand", "i_type56": "w2_mp40",
	"t_m47": "cw_t55", "t_m48": "cw_t55", "t_m60": "cw_t55", "t_t54": "cw_t55", "t_t55": "cw_t55", "t_t62": "cw_t55", "t_cent": "cw_t55", "t_cheft": "cw_t55",
	"t_amx13": "cw_t55", "t_amx30": "cw_t55", "t_type59": "cw_t55", "t_leo": "cw_t55",
	"a_m59": "cw_apc", "a_m113": "cw_apc", "a_btr152": "cw_apc", "a_btr60": "cw_apc", "a_bmp1": "cw_apc", "a_sar": "cw_apc", "a_fv432": "cw_apc",
	"a_panhard": "u_armored_car", "a_vci": "cw_apc", "a_type63": "cw_apc",
	"y_m114": "w2_howitzer", "y_m110": "w2_howitzer", "y_m46": "w2_howitzer", "y_d30": "w2_howitzer", "y_bm21": "w2_katyusha", "y_bl55": "w2_howitzer",
	"y_mle50": "w2_howitzer", "y_f3": "w2_howitzer", "y_type54": "w2_howitzer",
	"f_f86": "cw_mig", "f_f100": "cw_mig", "f_f4": "cw_mig", "f_mig15": "cw_mig", "f_mig17": "cw_mig", "f_mig21": "cw_mig", "f_su7": "cw_b52",
	"f_hunter": "cw_mig", "f_lightning": "cw_mig", "f_mystere": "cw_mig", "f_mirage": "cw_mig", "f_j5": "cw_mig",
	"s_guppy": "w2_uboat", "s_skipjack": "u_nuclear_sub", "s_gwash": "cw_polaris",
}


## Modern birlikler: modele özel simge (dosya yoksa sınıf simgesine düşer; tools/ICON_PROMPTS_14.md)
const MODERN_ICON := {
	"t_m1a1": "m_abrams", "t_m1a2v2": "m_abrams", "t_m1a2": "m_abrams", "t_m48": "m_patton",
	"t_m60": "m_patton", "t_m60t": "m_patton", "t_leo1": "m_leopard", "t_leo2a4": "m_leopard",
	"t_leo2a7": "m_leopard", "t_t55": "m_t72", "t_t72": "m_t72", "t_t90m": "m_t72",
	"t_t90s": "m_t72", "t_oplot": "m_t72", "t_pt91": "m_t72", "t_type59": "m_t72",
	"t_t14": "m_t14", "t_type96": "m_type99", "t_type99": "m_type99", "t_type90": "m_type99",
	"t_zulfiqar": "m_type99", "t_merkava": "m_merkava", "t_k1": "m_k2", "t_k2": "m_k2",
	"t_type10": "m_k2", "t_altay": "m_k2", "t_arjun": "m_k2", "t_khalid": "m_k2",
	"t_karrar": "m_k2", "t_leclerc": "m_leclerc", "t_ch2": "m_leclerc", "t_ch3": "m_leclerc",
	"f_f35a": "m_f35", "f_kf21": "m_f35", "f_kaan": "m_f35", "f_f15ex": "m_f15",
	"f_f14": "m_f15", "f_f16c": "m_f16", "f_f16v": "m_f16", "f_f18": "m_f16",
	"f_jf17": "m_f16", "f_tejas": "m_f16", "f_fa50": "m_f16", "f_hurjet": "m_f16",
	"f_su57": "m_su57", "f_j20": "m_su57", "f_su27": "m_su27", "f_su30": "m_su27",
	"f_su35": "m_su27", "f_j16": "m_su27", "f_mig29": "m_su27", "f_j10c": "m_su27",
	"f_rafale": "m_rafale", "f_m2000": "m_rafale", "f_typhoon": "m_rafale", "f_gripen": "m_rafale",
	"f_tornado": "m_rafale", "f_ah64": "m_apache", "f_t129": "m_apache", "f_mi24": "m_apache",
	"f_tb2": "m_tb2", "f_wingloong": "m_tb2", "f_heron": "m_tb2", "f_mohajer": "m_tb2",
	"f_akinci": "m_tb2", "f_shahed": "m_kamikaze", "f_kizilelma": "m_kizilelma", "f_su25": "m_su25",
	"f_mig21": "m_mig21", "f_j7": "m_mig21", "f_f4": "m_mig21", "f_f5": "m_mig21",
	"y_himars": "m_himars", "y_m270": "m_himars", "y_pcl181": "m_himars", "y_chunmoo": "m_himars",
	"y_tr300": "m_himars", "y_puls": "m_himars", "y_smerch": "m_himars", "y_pinaka": "m_himars",
	"y_phl03": "m_himars", "y_grad": "m_grad", "y_fajr": "m_grad", "y_koksan": "m_grad",
	"y_nk240": "m_grad", "y_pzh": "m_spg", "y_m109": "m_spg", "y_m109a7": "m_spg",
	"y_k9": "m_spg", "y_2s19": "m_spg", "y_2s35": "m_spg", "y_plz05": "m_spg",
	"y_firtina": "m_spg", "y_krab": "m_spg", "y_type99": "m_spg", "y_2s1": "m_spg",
	"y_2s3": "m_spg", "y_type83": "m_spg", "y_dhanush": "m_spg", "y_caesar": "m_spg_wheeled",
	"y_atmos": "m_spg_wheeled", "y_archer": "m_spg_wheeled", "y_sakarya": "m_spg_wheeled", "y_tos": "m_tos",
	"a_bmp1": "m_bmp", "a_bmp2": "m_bmp", "a_bmp3": "m_bmp", "a_kurgan": "m_bmp",
	"a_zbd04": "m_bmp", "a_k21": "m_bmp", "a_namer": "m_bmp", "a_eitan": "m_bmp",
	"a_m2": "m_bradley", "a_ampv": "m_bradley", "a_ajax": "m_bradley", "a_warrior": "m_bradley",
	"a_cv90": "m_bradley", "a_puma": "m_bradley", "a_marder": "m_bradley", "a_k200": "m_bradley",
	"a_acv15": "m_bradley", "a_stryker": "m_wheeled", "a_boxer": "m_wheeled", "a_vbci": "m_wheeled",
	"a_griffon": "m_wheeled", "a_patria": "m_wheeled", "a_kirpi": "m_wheeled", "a_tulpar": "m_wheeled",
	"a_btr82": "m_wheeled", "a_zbl08": "m_wheeled", "a_type96": "m_wheeled", "a_m113": "m_apc_old",
	"a_btr60": "m_apc_old", "a_fuchs": "m_apc_old", "a_vab": "m_apc_old", "a_wz551": "m_apc_old",
	"s_los": "m_sub_nuke", "s_virginia": "m_sub_nuke", "s_astute": "m_sub_nuke", "s_trafalgar": "m_sub_nuke",
	"s_yasen": "m_sub_nuke", "s_shang": "m_sub_nuke", "s_arihant": "m_sub_nuke", "s_barracuda": "m_sub_nuke",
	"s_sang": "m_sub_diesel", "s_romeo": "m_sub_diesel", "s_ghadir": "m_sub_diesel", "s_song": "m_sub_diesel",
	"s_yuan": "m_sub_diesel", "s_kilo": "m_sub_diesel", "s_lada": "m_sub_diesel", "s_type209": "m_sub_diesel",
	"s_type214": "m_sub_diesel", "s_dolphin": "m_sub_diesel", "s_reis": "m_sub_diesel", "s_agosta": "m_sub_diesel",
	"s_scorpene": "m_sub_diesel", "s_soryu": "m_sub_diesel", "s_ksss": "m_sub_diesel", "s_collins": "m_sub_diesel",
}


static func cat_icon(k: String, fam: String = "") -> String:
	if fam == "":
		fam = load("res://scripts/eras.gd").family()
	var Ic = load("res://scripts/icons.gd")
	var want: String = String(CAT_ICON_FAM.get(fam, {}).get(k, CAT_ICON[k]))
	return Ic.pick(want, CAT_ICON[k])


static func item_icon(id: String) -> String:
	var Ic = load("res://scripts/icons.gd")
	var cat: String = ITEMS[id][1] if ITEMS.has(id) else "inf"
	var fb: String = cat_icon(cat)
	if ITEM_ICON.has(id):
		fb = Ic.pick(ITEM_ICON[id], fb)
	elif MODERN_ICON.has(id) and load("res://scripts/eras.gd").family() == "":
		fb = Ic.pick(MODERN_ICON[id], fb)
	# her modele özel simge (assets/icons/x_<id>_c.png) varsa o kullanılır
	return Ic.pick("x_" + id, fb)


const CAT_UNIT := {"inf": "1.000 kişilik set", "tank": "adet", "afv": "adet", "arty": "adet", "air": "adet", "sub": "adet"}
const CAT_STEP := {"inf": 20, "tank": 10, "afv": 20, "arty": 10, "air": 4, "sub": 1}
# veri tablosundaki ortalama (1.000 asker başına) ağırlıklı referans: güç hesabında normalizasyon
const CAT_REF := {"tank": 10.0, "afv": 24.0, "arty": 4.5}

# id: [ad, kategori, menşei (name_en), tier, fiyat, satılabilir]
const ITEMS_MODERN := {
	# ---- tüfekler (1.000 kişilik set: tüfek + yelek + gece görüş)
	"i_g3": ["G3A3 / G3A7", "inf", "Germany", 1, 1.5, true],
	"i_g36": ["G36", "inf", "Germany", 2, 4.0, true],
	"i_hk416": ["HK416A5", "inf", "Germany", 3, 10.0, true],
	"i_ak74": ["AK-74M", "inf", "Russia", 1, 1.8, true],
	"i_ak12": ["AK-12 + Ratnik", "inf", "Russia", 3, 8.0, true],
	"i_type81": ["Tip 81 (QBZ-81)", "inf", "China", 1, 1.5, true],
	"i_qbz95": ["QBZ-95", "inf", "China", 2, 3.5, true],
	"i_qbz191": ["QBZ-191", "inf", "China", 3, 6.5, true],
	"i_m16": ["M16A4", "inf", "United States of America", 1, 2.2, true],
	"i_m4": ["M4A1 Karabina", "inf", "United States of America", 2, 5.0, true],
	"i_xm7": ["XM7 (NGSW) + Füzyon Seti", "inf", "United States of America", 4, 24.0, true],
	"i_scar": ["FN SCAR", "inf", "Belgium", 3, 11.0, true],
	"i_famas": ["FAMAS F1", "inf", "France", 2, 4.0, true],
	"i_mpt76": ["MPT-76", "inf", "Turkey", 3, 7.0, true],
	"i_mpt55": ["MPT-55", "inf", "Turkey", 2, 3.0, true],
	"i_tavor": ["IWI Tavor X95", "inf", "Israel", 3, 9.0, true],
	"i_galil": ["Galil ACE", "inf", "Israel", 2, 4.0, true],
	"i_k2": ["Daewoo K2", "inf", "South Korea", 2, 4.0, true],
	"i_k2c1": ["K2C1 + KNIFE Seti", "inf", "South Korea", 3, 9.0, true],
	"i_insas": ["INSAS", "inf", "India", 1, 2.0, true],
	"i_ak203": ["AK-203", "inf", "India", 2, 4.5, true],
	"i_sa80": ["L85A3 (SA80)", "inf", "United Kingdom", 2, 5.0, true],
	"i_type89": ["Tip 89 (Howa)", "inf", "Japan", 1, 2.5, true],
	"i_type20": ["Howa Tip 20", "inf", "Japan", 3, 8.5, true],
	# ---- tanklar
	"t_t55": ["T-55AM2", "tank", "Russia", 1, 0.8, false],
	"t_t72": ["T-72B3", "tank", "Russia", 2, 3.0, true],
	"t_t90m": ["T-90M Proryv", "tank", "Russia", 3, 4.5, true],
	"t_t14": ["T-14 Armata", "tank", "Russia", 4, 8.0, true],
	"t_type59": ["Tip 59 / 79", "tank", "China", 1, 0.7, false],
	"t_type96": ["Tip 96A", "tank", "China", 2, 2.5, true],
	"t_type99": ["Tip 99A", "tank", "China", 3, 5.0, true],
	"t_m48": ["M48A5T2", "tank", "United States of America", 1, 0.6, false],
	"t_m60": ["M60A3 Patton", "tank", "United States of America", 1, 1.0, false],
	"t_m60t": ["M60T Sabra", "tank", "Turkey", 2, 2.0, true],
	"t_m1a1": ["M1A1 Abrams", "tank", "United States of America", 2, 4.5, true],
	"t_m1a2v2": ["M1A2 SEPv2 Abrams", "tank", "United States of America", 3, 9.0, true],
	"t_m1a2": ["M1A2 SEPv3 Abrams", "tank", "United States of America", 4, 10.5, true],
	"t_leo1": ["Leopard 1A5", "tank", "Germany", 1, 1.2, false],
	"t_leo2a4": ["Leopard 2A4", "tank", "Germany", 2, 3.5, true],
	"t_leo2a7": ["Leopard 2A7+", "tank", "Germany", 4, 13.0, true],
	"t_leclerc": ["Leclerc XLR", "tank", "France", 3, 10.0, true],
	"t_ch2": ["Challenger 2", "tank", "United Kingdom", 3, 9.0, true],
	"t_ch3": ["Challenger 3", "tank", "United Kingdom", 4, 12.0, true],
	"t_merkava": ["Merkava Mk.4M Windbreaker", "tank", "Israel", 4, 7.5, true],
	"t_k1": ["K1A1", "tank", "South Korea", 2, 4.0, true],
	"t_k2": ["K2 Kara Panter", "tank", "South Korea", 4, 8.5, true],
	"t_altay": ["Altay", "tank", "Turkey", 4, 7.0, true],
	"t_arjun": ["Arjun Mk1A", "tank", "India", 3, 5.0, true],
	"t_t90s": ["T-90S Bhishma", "tank", "Russia", 3, 4.2, true],
	"t_type90": ["Tip 90", "tank", "Japan", 3, 7.0, true],
	"t_type10": ["Tip 10 (Hitomaru)", "tank", "Japan", 4, 10.0, true],
	"t_pt91": ["PT-91 Twardy", "tank", "Poland", 2, 3.3, true],
	"t_khalid": ["Al-Khalid (MBT-2000)", "tank", "Pakistan", 3, 4.3, true],
	"t_zulfiqar": ["Zulfikar", "tank", "Iran", 2, 1.5, false],
	"t_karrar": ["Karrar", "tank", "Iran", 3, 3.5, false],
	"t_oplot": ["T-84 Oplot-M", "tank", "Ukraine", 3, 4.0, true],
	# ---- zırhlı araçlar (TOMA / MRAP / SPZ)
	"a_btr60": ["BTR-60 / BTR-70", "afv", "Russia", 1, 0.4, false],
	"a_bmp1": ["BMP-1", "afv", "Russia", 1, 0.5, false],
	"a_bmp2": ["BMP-2M", "afv", "Russia", 2, 1.3, true],
	"a_btr82": ["BTR-82A", "afv", "Russia", 2, 1.8, true],
	"a_bmp3": ["BMP-3", "afv", "Russia", 3, 3.0, true],
	"a_kurgan": ["Kurganets-25", "afv", "Russia", 4, 4.5, true],
	"a_wz551": ["WZ-551", "afv", "China", 1, 0.4, false],
	"a_zbl08": ["ZBL-08 (VN-1)", "afv", "China", 2, 1.6, true],
	"a_zbd04": ["ZBD-04A", "afv", "China", 3, 3.0, true],
	"a_m113": ["M113", "afv", "United States of America", 1, 0.5, false],
	"a_stryker": ["Stryker", "afv", "United States of America", 2, 4.2, true],
	"a_m2": ["M2A3 Bradley", "afv", "United States of America", 3, 4.5, true],
	"a_ampv": ["AMPV", "afv", "United States of America", 4, 5.5, true],
	"a_fuchs": ["TPz Fuchs", "afv", "Germany", 1, 1.0, false],
	"a_marder": ["Marder 1A3", "afv", "Germany", 2, 2.5, true],
	"a_boxer": ["Boxer", "afv", "Germany", 3, 6.5, true],
	"a_puma": ["Puma", "afv", "Germany", 4, 8.0, true],
	"a_vab": ["VAB", "afv", "France", 1, 0.9, false],
	"a_vbci": ["VBCI", "afv", "France", 3, 4.5, true],
	"a_griffon": ["Griffon", "afv", "France", 4, 4.5, true],
	"a_warrior": ["Warrior", "afv", "United Kingdom", 2, 3.5, true],
	"a_ajax": ["Ajax", "afv", "United Kingdom", 4, 7.0, true],
	"a_cv90": ["CV90", "afv", "Sweden", 3, 5.0, true],
	"a_acv15": ["ACV-15 / AIFV", "afv", "Turkey", 1, 1.0, false],
	"a_kirpi": ["Kirpi (MRAP)", "afv", "Turkey", 2, 0.9, true],
	"a_tulpar": ["Tulpar", "afv", "Turkey", 4, 3.8, true],
	"a_k200": ["K200 KIFV", "afv", "South Korea", 1, 1.5, false],
	"a_k21": ["K21", "afv", "South Korea", 3, 4.8, true],
	"a_namer": ["Namer", "afv", "Israel", 4, 6.0, true],
	"a_eitan": ["Eitan", "afv", "Israel", 4, 4.0, true],
	"a_patria": ["Patria AMV", "afv", "Finland", 3, 3.8, true],
	"a_type96": ["Tip 96 WAPC", "afv", "Japan", 2, 2.5, true],
	# ---- top ve roketatar
	"y_grad": ["BM-21 Grad", "arty", "Russia", 1, 0.6, true],
	"y_2s1": ["2S1 Gvozdika", "arty", "Russia", 1, 1.0, false],
	"y_2s3": ["2S3 Akatsiya", "arty", "Russia", 1, 1.3, false],
	"y_2s19": ["2S19 Msta-S", "arty", "Russia", 2, 3.5, true],
	"y_smerch": ["BM-30 Smerç", "arty", "Russia", 3, 6.5, true],
	"y_tos": ["TOS-1A Solntsepyok", "arty", "Russia", 3, 6.0, true],
	"y_2s35": ["2S35 Koalitsiya-SV", "arty", "Russia", 4, 7.0, true],
	"y_type83": ["Tip 83 (152 mm)", "arty", "China", 1, 1.0, false],
	"y_plz05": ["PLZ-05", "arty", "China", 3, 3.6, true],
	"y_phl03": ["PHL-03", "arty", "China", 3, 3.5, true],
	"y_pcl181": ["PCL-181", "arty", "China", 4, 4.0, true],
	"y_m109": ["M109A6 Paladin", "arty", "United States of America", 2, 3.5, true],
	"y_m109a7": ["M109A7 Paladin", "arty", "United States of America", 3, 5.5, true],
	"y_m270": ["M270 MLRS", "arty", "United States of America", 3, 8.0, true],
	"y_himars": ["M142 HIMARS", "arty", "United States of America", 4, 6.5, true],
	"y_pzh": ["PzH 2000", "arty", "Germany", 4, 7.5, true],
	"y_caesar": ["CAESAR 8x8", "arty", "France", 4, 5.0, true],
	"y_archer": ["Archer (FH77 BW L52)", "arty", "Sweden", 4, 7.0, true],
	"y_sakarya": ["T-122 Sakarya", "arty", "Turkey", 2, 1.3, true],
	"y_firtina": ["T-155 Fırtına", "arty", "Turkey", 3, 3.8, true],
	"y_tr300": ["TRG-300 Kaplan", "arty", "Turkey", 4, 3.5, true],
	"y_k9": ["K9 Thunder", "arty", "South Korea", 3, 3.8, true],
	"y_chunmoo": ["K239 Chunmoo", "arty", "South Korea", 4, 5.5, true],
	"y_dhanush": ["Dhanush", "arty", "India", 2, 2.5, true],
	"y_pinaka": ["Pinaka Mk-I", "arty", "India", 3, 3.0, true],
	"y_fajr": ["Fecr-5", "arty", "Iran", 2, 0.8, false],
	"y_krab": ["AHS Krab", "arty", "Poland", 3, 3.5, true],
	"y_type99": ["Tip 99 (155 mm)", "arty", "Japan", 3, 6.0, true],
	"y_atmos": ["ATMOS 2000", "arty", "Israel", 3, 3.6, true],
	"y_puls": ["PULS", "arty", "Israel", 4, 6.0, true],
	"y_koksan": ["M-1978 Koksan (170 mm)", "arty", "North Korea", 1, 1.5, false],
	"y_nk240": ["M-1991 (240 mm)", "arty", "North Korea", 1, 0.8, false],
	# ---- uçaklar, helikopterler, İHA'lar
	"f_mig21": ["MiG-21 Fishbed", "air", "Russia", 1, 6.0, false],
	"f_su25": ["Su-25 Grach", "air", "Russia", 1, 12.0, false],
	"f_mig29": ["MiG-29 Fulcrum", "air", "Russia", 2, 20.0, true],
	"f_su27": ["Su-27SM", "air", "Russia", 2, 30.0, true],
	"f_su30": ["Su-30SM", "air", "Russia", 3, 45.0, true],
	"f_su35": ["Su-35S", "air", "Russia", 4, 65.0, true],
	"f_su57": ["Su-57", "air", "Russia", 4, 90.0, true],
	"f_j7": ["J-7 / F-7", "air", "China", 1, 6.0, false],
	"f_j10c": ["J-10C", "air", "China", 3, 45.0, true],
	"f_j16": ["J-16", "air", "China", 3, 55.0, true],
	"f_j20": ["J-20 Güçlü Ejderha", "air", "China", 4, 105.0, true],
	"f_wingloong": ["Wing Loong II", "air", "China", 2, 12.0, true],
	"f_jf17": ["JF-17 Thunder Blok III", "air", "Pakistan", 2, 28.0, true],
	"f_f4": ["F-4E Phantom II", "air", "United States of America", 1, 15.0, false],
	"f_f5": ["F-5E Tiger II", "air", "United States of America", 1, 9.0, false],
	"f_f14": ["F-14A Tomcat", "air", "United States of America", 1, 20.0, false],
	"f_f16c": ["F-16C/D Blok 50", "air", "United States of America", 2, 55.0, true],
	"f_f16v": ["F-16V Viper", "air", "United States of America", 3, 70.0, true],
	"f_f18": ["F/A-18E/F Super Hornet", "air", "United States of America", 3, 75.0, true],
	"f_f15ex": ["F-15EX Eagle II", "air", "United States of America", 4, 95.0, true],
	"f_f35a": ["F-35A Lightning II", "air", "United States of America", 4, 82.0, true],
	"f_ah64": ["AH-64E Apache", "air", "United States of America", 3, 35.0, true],
	"f_m2000": ["Mirage 2000-5", "air", "France", 2, 35.0, true],
	"f_rafale": ["Rafale F4", "air", "France", 4, 95.0, true],
	"f_tornado": ["Tornado IDS", "air", "Germany", 1, 25.0, false],
	"f_typhoon": ["Eurofighter Typhoon", "air", "Germany", 4, 110.0, true],
	"f_gripen": ["JAS 39E Gripen", "air", "Sweden", 3, 70.0, true],
	"f_kaan": ["KAAN (TF-X)", "air", "Turkey", 4, 85.0, true],
	"f_tb2": ["Bayraktar TB2", "air", "Turkey", 2, 5.0, true],
	"f_akinci": ["Bayraktar Akıncı", "air", "Turkey", 3, 18.0, true],
	"f_kizilelma": ["Bayraktar Kızılelma", "air", "Turkey", 4, 30.0, true],
	"f_t129": ["T129 ATAK", "air", "Turkey", 3, 22.0, true],
	"f_hurjet": ["Hürjet", "air", "Turkey", 2, 28.0, true],
	"f_kf21": ["KF-21 Boramae", "air", "South Korea", 3, 65.0, true],
	"f_fa50": ["FA-50 Fighting Eagle", "air", "South Korea", 2, 30.0, true],
	"f_tejas": ["Tejas Mk1A", "air", "India", 2, 42.0, true],
	"f_heron": ["Heron TP", "air", "Israel", 2, 12.0, true],
	"f_shahed": ["Şahid-136 (kamikaze İHA)", "air", "Iran", 2, 0.1, false],
	"f_mohajer": ["Mohajer-6", "air", "Iran", 2, 3.0, false],
	"f_mi24": ["Mi-24 Hind", "air", "Russia", 1, 6.0, false],
	# ---- denizaltılar
	"s_sang": ["Sang-O sınıfı", "sub", "North Korea", 1, 40.0, false],
	"s_romeo": ["Romeo sınıfı", "sub", "North Korea", 1, 100.0, false],
	"s_ghadir": ["Gadir (mini denizaltı)", "sub", "Iran", 1, 30.0, false],
	"s_song": ["Tip 039 Song", "sub", "China", 2, 250.0, true],
	"s_yuan": ["Tip 039A Yuan", "sub", "China", 3, 450.0, true],
	"s_shang": ["Tip 093 Shang (nükleer)", "sub", "China", 3, 1300.0, true],
	"s_kilo": ["Proje 636.3 Kilo", "sub", "Russia", 2, 350.0, true],
	"s_lada": ["Lada / Kalina", "sub", "Russia", 3, 450.0, true],
	"s_yasen": ["Yasen-M (nükleer)", "sub", "Russia", 4, 2200.0, true],
	"s_type209": ["Tip 209", "sub", "Germany", 2, 420.0, true],
	"s_type214": ["Tip 214", "sub", "Germany", 3, 650.0, true],
	"s_dolphin": ["Dolphin II", "sub", "Germany", 4, 700.0, true],
	"s_reis": ["Reis sınıfı (Tip 214TN)", "sub", "Turkey", 3, 600.0, true],
	"s_agosta": ["Agosta 90B", "sub", "France", 2, 400.0, true],
	"s_scorpene": ["Scorpène", "sub", "France", 3, 600.0, true],
	"s_barracuda": ["Suffren (Barracuda)", "sub", "France", 4, 1800.0, true],
	"s_trafalgar": ["Trafalgar (nükleer)", "sub", "United Kingdom", 2, 1200.0, false],
	"s_astute": ["Astute (nükleer)", "sub", "United Kingdom", 4, 2200.0, true],
	"s_los": ["Los Angeles (nükleer)", "sub", "United States of America", 2, 1800.0, false],
	"s_virginia": ["Virginia (nükleer)", "sub", "United States of America", 4, 3500.0, true],
	"s_soryu": ["Soryu / Taigei", "sub", "Japan", 4, 700.0, true],
	"s_ksss": ["KSS-III Dosan Ahn Changho", "sub", "South Korea", 4, 900.0, true],
	"s_arihant": ["Arihant (nükleer)", "sub", "India", 4, 2500.0, true],
	"s_collins": ["Collins sınıfı", "sub", "Australia", 2, 600.0, true],
}

# Güç ağırlığı: aksi belirtilmedikçe tier'a göre
const POW_OVR := {"f_shahed": 0.04, "f_mohajer": 0.3, "f_tb2": 0.35, "f_heron": 0.4, "f_wingloong": 0.5, "f_akinci": 1.0,
	"f_ah64": 1.4, "f_t129": 1.2, "f_mi24": 0.8, "f_su25": 0.8, "f_hurjet": 0.9, "f_fa50": 1.1, "f_f5": 0.7, "f_mig21": 0.6, "f_j7": 0.6}
const SUB_POW := {1: 0.5, 2: 1.4, 3: 2.6, 4: 4.5}

# Henüz envantere girmemiş (oyun başında 0 adet) sistemler: satın alınabilir, başlangıçta bir alt nesil görünür
const NEW_MODERN := ["t_altay", "f_kaan", "f_kizilelma", "t_t14", "f_su57", "i_xm7", "a_kurgan", "t_ch3", "f_kf21"]

# --- blok varsayılanları: 4 tier için kimlikler
const BLOC_MODERN := {
	"us": {
		"inf": ["i_m16", "i_m4", "i_scar", "i_xm7"],
		"tank": ["t_m60", "t_m1a1", "t_m1a2v2", "t_m1a2"],
		"afv": ["a_m113", "a_stryker", "a_m2", "a_ampv"],
		"arty": ["y_m109", "y_m109", "y_m109a7", "y_himars"],
		"air": ["f_f4", "f_f16c", "f_f16v", "f_f35a"],
		"sub": ["s_los", "s_los", "s_virginia", "s_virginia"]},
	"eu": {
		"inf": ["i_g3", "i_g36", "i_hk416", "i_hk416"],
		"tank": ["t_leo1", "t_leo2a4", "t_leo2a7", "t_leo2a7"],
		"afv": ["a_fuchs", "a_marder", "a_boxer", "a_puma"],
		"arty": ["y_m109", "y_m109", "y_pzh", "y_pzh"],
		"air": ["f_tornado", "f_f16c", "f_typhoon", "f_typhoon"],
		"sub": ["s_type209", "s_type209", "s_type214", "s_type214"]},
	"ru": {
		"inf": ["i_ak74", "i_ak74", "i_ak12", "i_ak12"],
		"tank": ["t_t55", "t_t72", "t_t90m", "t_t14"],
		"afv": ["a_bmp1", "a_bmp2", "a_bmp3", "a_kurgan"],
		"arty": ["y_grad", "y_2s3", "y_2s19", "y_2s35"],
		"air": ["f_mig21", "f_mig29", "f_su30", "f_su35"],
		"sub": ["s_kilo", "s_kilo", "s_lada", "s_yasen"]},
	"cn": {
		"inf": ["i_type81", "i_qbz95", "i_qbz191", "i_qbz191"],
		"tank": ["t_type59", "t_type96", "t_type99", "t_type99"],
		"afv": ["a_wz551", "a_zbl08", "a_zbd04", "a_zbd04"],
		"arty": ["y_type83", "y_plz05", "y_phl03", "y_pcl181"],
		"air": ["f_j7", "f_j7", "f_j10c", "f_j20"],
		"sub": ["s_song", "s_song", "s_yuan", "s_shang"]},
}

# --- ülkeye özel envanter isimleri (kısmi; eksik kategori blokdan gelir)
const FAMILY_MODERN := {
	"Turkey": {"inf": ["i_g3", "i_g3", "i_mpt55", "i_mpt76"], "tank": ["t_m48", "t_m60t", "t_leo2a4", "t_altay"],
		"afv": ["a_acv15", "a_kirpi", "a_tulpar", "a_tulpar"], "arty": ["y_m109", "y_sakarya", "y_firtina", "y_tr300"],
		"air": ["f_f4", "f_f16c", "f_f16v", "f_kaan"], "sub": ["s_type209", "s_type209", "s_reis", "s_reis"]},
	"France": {"inf": ["i_famas", "i_famas", "i_hk416", "i_hk416"], "tank": ["t_leclerc", "t_leclerc", "t_leclerc", "t_leclerc"],
		"afv": ["a_vab", "a_vab", "a_vbci", "a_griffon"], "arty": ["y_caesar", "y_caesar", "y_caesar", "y_caesar"],
		"air": ["f_m2000", "f_m2000", "f_rafale", "f_rafale"], "sub": ["s_agosta", "s_scorpene", "s_barracuda", "s_barracuda"]},
	"United Kingdom": {"inf": ["i_sa80", "i_sa80", "i_sa80", "i_sa80"], "tank": ["t_ch2", "t_ch2", "t_ch3", "t_ch3"],
		"afv": ["a_warrior", "a_warrior", "a_ajax", "a_ajax"], "arty": ["y_m109", "y_m109", "y_m109a7", "y_himars"],
		"air": ["f_tornado", "f_typhoon", "f_f35a", "f_f35a"], "sub": ["s_trafalgar", "s_trafalgar", "s_astute", "s_astute"]},
	"India": {"inf": ["i_insas", "i_insas", "i_ak203", "i_ak203"], "tank": ["t_t72", "t_t90s", "t_t90s", "t_arjun"],
		"afv": ["a_bmp1", "a_bmp2", "a_bmp2", "a_bmp3"], "arty": ["y_grad", "y_dhanush", "y_k9", "y_pinaka"],
		"air": ["f_mig21", "f_mig29", "f_su30", "f_rafale"], "sub": ["s_kilo", "s_kilo", "s_scorpene", "s_arihant"]},
	"Iran": {"inf": ["i_g3", "i_ak74", "i_ak74", "i_ak74"], "tank": ["t_t55", "t_zulfiqar", "t_karrar", "t_karrar"],
		"afv": ["a_bmp1", "a_bmp2", "a_bmp2", "a_bmp2"], "arty": ["y_grad", "y_fajr", "y_fajr", "y_fajr"],
		"air": ["f_f4", "f_f14", "f_mohajer", "f_shahed"], "sub": ["s_ghadir", "s_ghadir", "s_kilo", "s_kilo"]},
	"Israel": {"inf": ["i_galil", "i_galil", "i_tavor", "i_tavor"], "tank": ["t_m60", "t_merkava", "t_merkava", "t_merkava"],
		"afv": ["a_m113", "a_namer", "a_namer", "a_eitan"], "arty": ["y_m109", "y_atmos", "y_atmos", "y_puls"],
		"air": ["f_f4", "f_f16c", "f_f16v", "f_f35a"], "sub": ["s_dolphin", "s_dolphin", "s_dolphin", "s_dolphin"]},
	"South Korea": {"inf": ["i_k2", "i_k2", "i_k2c1", "i_k2c1"], "tank": ["t_k1", "t_k1", "t_k1", "t_k2"],
		"afv": ["a_k200", "a_k200", "a_k21", "a_k21"], "arty": ["y_k9", "y_k9", "y_k9", "y_chunmoo"],
		"air": ["f_f5", "f_f16c", "f_kf21", "f_f35a"], "sub": ["s_type209", "s_type209", "s_ksss", "s_ksss"]},
	"Japan": {"inf": ["i_type89", "i_type89", "i_type20", "i_type20"], "tank": ["t_type90", "t_type90", "t_type10", "t_type10"],
		"afv": ["a_m113", "a_type96", "a_type96", "a_type96"], "arty": ["y_type99", "y_type99", "y_type99", "y_himars"],
		"air": ["f_f4", "f_f16c", "f_f15ex", "f_f35a"], "sub": ["s_soryu", "s_soryu", "s_soryu", "s_soryu"]},
	"Pakistan": {"inf": ["i_g3", "i_g3", "i_qbz95", "i_qbz191"], "tank": ["t_type59", "t_type96", "t_khalid", "t_khalid"],
		"afv": ["a_m113", "a_m113", "a_zbd04", "a_zbd04"], "arty": ["y_m109", "y_m109", "y_phl03", "y_phl03"],
		"air": ["f_j7", "f_f16c", "f_jf17", "f_j10c"], "sub": ["s_agosta", "s_agosta", "s_yuan", "s_yuan"]},
	"North Korea": {"inf": ["i_type81", "i_type81", "i_ak74", "i_ak74"], "tank": ["t_t55", "t_t55", "t_t72", "t_t72"],
		"afv": ["a_btr60", "a_btr60", "a_bmp1", "a_bmp1"], "arty": ["y_koksan", "y_nk240", "y_2s1", "y_2s3"],
		"air": ["f_mig21", "f_mig21", "f_mig29", "f_mig29"], "sub": ["s_sang", "s_romeo", "s_sang", "s_romeo"]},
	"Ukraine": {"inf": ["i_ak74", "i_ak74", "i_m4", "i_m4"], "tank": ["t_t55", "t_t72", "t_oplot", "t_leo2a4"],
		"afv": ["a_btr60", "a_bmp2", "a_m2", "a_marder"], "arty": ["y_grad", "y_2s19", "y_caesar", "y_himars"],
		"air": ["f_mig29", "f_su27", "f_f16c", "f_f16v"], "sub": ["s_kilo", "s_kilo", "s_kilo", "s_kilo"]},
	"Poland": {"inf": ["i_ak74", "i_ak74", "i_m4", "i_m4"], "tank": ["t_t72", "t_pt91", "t_k2", "t_k2"],
		"afv": ["a_bmp1", "a_bmp1", "a_boxer", "a_boxer"], "arty": ["y_grad", "y_krab", "y_krab", "y_chunmoo"],
		"air": ["f_mig29", "f_f16c", "f_f16v", "f_f35a"], "sub": ["s_type209", "s_type209", "s_type209", "s_type209"]},
	"Sweden": {"afv": ["a_cv90", "a_cv90", "a_cv90", "a_cv90"], "arty": ["y_archer", "y_archer", "y_archer", "y_archer"],
		"air": ["f_gripen", "f_gripen", "f_gripen", "f_gripen"]},
	"Finland": {"afv": ["a_patria", "a_patria", "a_patria", "a_patria"], "air": ["f_f18", "f_f18", "f_f18", "f_f35a"]},
}

# --- ülke -> blok
const BLOC_OF_MODERN := {
	"United States of America": "us", "Canada": "us", "Australia": "us", "Saudi Arabia": "us", "United Arab Emirates": "us",
	"Qatar": "us", "Jordan": "us", "Egypt": "us", "Philippines": "us", "Taiwan": "us", "Singapore": "us", "Georgia": "us",
	"Russia": "ru", "Belarus": "ru", "Armenia": "ru", "Syria": "ru", "Iraq": "ru", "Vietnam": "ru", "Venezuela": "ru",
	"Azerbaijan": "ru", "Iran": "ru", "India": "ru", "Ukraine": "ru", "North Korea": "ru",
	"China": "cn", "Pakistan": "cn",
	"Germany": "eu", "France": "eu", "Italy": "eu", "Spain": "eu", "Netherlands": "eu", "Greece": "eu", "Turkey": "eu",
	"Brazil": "eu", "Indonesia": "eu", "Malaysia": "eu", "Switzerland": "eu", "Austria": "eu", "Denmark": "eu",
	"Norway": "eu", "Hungary": "eu", "Romania": "eu", "Estonia": "eu", "Latvia": "eu", "Lithuania": "eu",
	"Sweden": "eu", "Finland": "eu", "Poland": "eu", "United Kingdom": "eu", "Japan": "us", "South Korea": "us", "Israel": "us",
}

# --- gelişmişlik (tier karışımını belirler); yoksa kişi başı gelirden hesaplanır
const TECH_MODERN := {"Russia": 0.6, "China": 0.68, "Turkey": 0.6, "Iran": 0.4, "India": 0.5, "Israel": 1.0, "United States of America": 1.0,
	"Ukraine": 0.55, "North Korea": 0.1, "Pakistan": 0.35, "Egypt": 0.4, "Saudi Arabia": 0.75, "United Arab Emirates": 0.8,
	"Vietnam": 0.35, "Taiwan": 0.85, "Poland": 0.7, "Brazil": 0.45, "Venezuela": 0.2, "Syria": 0.15, "Iraq": 0.3,
	"Azerbaijan": 0.45, "Armenia": 0.35, "Belarus": 0.4}


const EraData = preload("res://scripts/arsenal_era.gd")
const EraExt = preload("res://scripts/era_ext.gd")

# Etkin tablolar: dönem moduna göre değişir (set_era)
static var ITEMS: Dictionary = ITEMS_MODERN
static var NEW_ITEMS: Array = NEW_MODERN
static var BLOC: Dictionary = BLOC_MODERN
static var FAMILY: Dictionary = FAMILY_MODERN
static var BLOC_OF: Dictionary = BLOC_OF_MODERN
static var TECH_OVR: Dictionary = TECH_MODERN
static var GATE: Dictionary = {}
static var era := ""
static var key := ""          # çözülmüş silah tablosu anahtarı ("ww1" / "ww2" / çağın kendi kimliği)


static func _resolve(id: String) -> Variant:
	if id == "":
		return null
	if EraExt.has_era(id):
		var a = EraExt.arsenal(id)
		if a is Dictionary and a.has("items"):
			key = id
			return a
		if a is String and EraData.DATA.has(a):
			key = a
			return EraData.DATA[a]
		# silah tablosu tanımlı değilse dönemin ait olduğu aileye bak
		var fam: String = EraExt.family(id)
		if EraData.DATA.has(fam):
			key = fam
			return EraData.DATA[fam]
		return null
	if EraData.DATA.has(id):
		key = id
		return EraData.DATA[id]
	return null


static func set_era(id: String) -> void:
	_cat_cache.clear()
	era = id
	key = ""
	var r: Variant = _resolve(id)
	if r == null:
		era = ""
		key = ""
		ITEMS = ITEMS_MODERN
		NEW_ITEMS = NEW_MODERN
		BLOC = BLOC_MODERN
		FAMILY = FAMILY_MODERN
		BLOC_OF = BLOC_OF_MODERN
		TECH_OVR = TECH_MODERN
		GATE = {}
		cat_names_ovr = {}
		return
	var e: Dictionary = r
	ITEMS = e["items"]
	NEW_ITEMS = e.get("new", [])
	BLOC = e["bloc"]
	FAMILY = e.get("family", {})
	BLOC_OF = e["bloc_of"]
	TECH_OVR = e.get("tech", {})
	GATE = e.get("gate", {})
	cat_names_ovr = e.get("cat_names", {})


static func name_of(id: String) -> String:
	return ITEMS[id][0] if ITEMS.has(id) else id


static func cat_of(id: String) -> String:
	return ITEMS[id][1]


static func origin_of(id: String) -> String:
	return ITEMS[id][2]


static func tier_of(id: String) -> int:
	return ITEMS[id][3]


static func cost_of(id: String) -> float:
	return ITEMS[id][4]


static func buyable(id: String) -> bool:
	return ITEMS[id][5]


static func power_of(id: String) -> float:
	if POW_OVR.has(id):
		return POW_OVR[id]
	var t: int = ITEMS[id][3]
	if ITEMS[id][1] == "sub":
		return SUB_POW[t]
	return 0.6 + 0.4 * t


static var _cat_cache: Dictionary = {}


static func list_cat(cat: String) -> Array:
	if _cat_cache.has(cat):
		return _cat_cache[cat]
	var out: Array = []
	for id in ITEMS:
		if ITEMS[id][1] == cat and ITEMS[id][5]:
			out.append(id)
	out.sort_custom(func(a, b): return ITEMS[a][3] < ITEMS[b][3] or (ITEMS[a][3] == ITEMS[b][3] and ITEMS[a][4] < ITEMS[b][4]))
	_cat_cache[cat] = out
	return out


## ülke için kategori başına 4 tier kimliği
static func family(name_en: String, cat: String, bloc: String) -> Array:
	var f: Dictionary = FAMILY.get(name_en, {})
	if f.has(cat):
		return f[cat]
	return BLOC[bloc][cat]


static func bloc_for(name_en: String, a3: String, cont: String, tech: float) -> String:
	if BLOC_OF.has(name_en):
		return BLOC_OF[name_en]
	if era != "":
		return "ot"
	var h: int = 0
	for i in a3.length():
		h += a3.unicode_at(i) * (i + 1)
	match cont:
		"Europe":
			return "eu" if tech > 0.4 else "ru"
		"North America", "South America", "Oceania":
			return "us"
		"Africa":
			return "ru" if h % 2 == 0 else "cn"
		"Asia":
			return ["cn", "ru", "us"][h % 3]
	return "us"

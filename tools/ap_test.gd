extends SceneTree
const AP = preload("res://scripts/ap.gd")
const P = preload("res://scripts/ap_provider.gd")
const M = preload("res://scripts/missions.gd")
const Saves = preload("res://scripts/saves.gd")
var fails := 0
func ck(name: String, cond: bool) -> void:
	print(("OK   " if cond else "FAIL ") + name)
	if not cond: fails += 1
func _init() -> void:
	AP.promo_off = true
	var St = load("res://scripts/settings.gd")
	St.load_all()
	var keep = St.ap.duplicate(true); var keep_m = St.missions.duplicate(true); var keep_xp = St.xp
	St.ap = {}; St.missions = {}
	ck("başlangıç bakiye 0", AP.balance() == 0)
	AP.earn(50); ck("earn", AP.balance() == 50)
	ck("harcama yetersiz", not AP.spend(80) and AP.balance() == 50)
	ck("harcama", AP.spend(30) and AP.balance() == 20)
	# içerik
	ck("ücretsiz: free/ukr/twn", AP.scenario_unlocked("free") and AP.scenario_unlocked("ukr") and AP.scenario_unlocked("twn"))
	ck("kilitli: kara/reich/ww1", not AP.scenario_unlocked("kara") and not AP.scenario_unlocked("reich") and AP.era_unlocked("ww1") and not AP.era_unlocked("ww2"))
	ck("AP yetmez -> açılmaz", not AP.unlock_with_ap("scn", "kara") and not AP.scenario_unlocked("kara"))
	AP.earn(1000)
	var b0 := AP.balance()
	ck("AP ile senaryo", AP.unlock_with_ap("scn", "kara") and AP.scenario_unlocked("kara") and AP.balance() == b0 - AP.PRICE_SCENARIO)
	ck("tekrar açma ücretsiz/çift düşmez", AP.unlock_with_ap("scn", "kara") and AP.balance() == b0 - AP.PRICE_SCENARIO)
	ck("AP ile çağ", AP.unlock_with_ap("era", "ww2") and AP.era_unlocked("ww2"))
	ck("kayıt yuvası 3", Saves.slot_count() == 3)
	AP.earn(200)
	ck("yuva AP ile", AP.unlock_with_ap("slots", "") and Saves.slot_count() == 5)
	# reklam
	St.ap["bal"] = 0
	var got := []
	for i in 8:
		St.ap["ad_last"] = 0
		AP.watch_ad(false, func(ok, g, m): got.append([ok, g]))
	var okn := 0
	for g in got: if g[0]: okn += 1
	ck("günlük reklam tavanı = %d" % AP.AD_DAILY_CAP, okn == AP.AD_DAILY_CAP)
	ck("reklam AP'si = 6*5", AP.balance() == AP.AD_DAILY_CAP * AP.AD_REWARD)
	ck("hak bitti", AP.ads_left() == 0 and not AP.ad_available())
	# yeni gün
	St.ap["ad_day"] = AP.today() - 1
	ck("yeni gün hak yenilenir", AP.ads_left() == AP.AD_DAILY_CAP)
	# bekleme
	St.ap["ad_last"] = int(Time.get_unix_time_from_system())
	ck("bekleme var", AP.ad_wait() > 0)
	var res := []
	AP.watch_ad(false, func(ok, g, m): res.append(ok))
	ck("bekleme sürerken izlenmez", res == [false])
	St.ap["ad_last"] = int(Time.get_unix_time_from_system()) + 99999
	ck("saat geri alınsa bekleme sınırlı", AP.ad_wait() <= AP.AD_COOLDOWN_DEV)
	St.ap["ad_last"] = 0
	# bonus reklam
	var b1 := AP.balance()
	var r2 := []
	AP.watch_ad(true, func(ok, g, m): r2.append([ok, g]))
	ck("bonus reklam +12", r2 == [[true, AP.BONUS_AD_REWARD]] and AP.balance() == b1 + AP.BONUS_AD_REWARD)
	St.ap["ad_last"] = 0
	var r3 := []
	AP.watch_ad(true, func(ok, g, m): r3.append(ok))
	ck("bonus günde bir kez", r3 == [false])
	# günlük ödül
	St.ap["login_day"] = -1; St.ap["login_n"] = 0
	var l1 := AP.claim_login()
	ck("günlük ödül 3", l1 == AP.LOGIN_REWARD)
	ck("aynı gün tekrar yok", AP.claim_login() == 0)
	St.ap["login_n"] = 6; St.ap["login_day"] = -1
	ck("7. gün 15", AP.claim_login() == AP.LOGIN_WEEK_REWARD)
	# zafer
	St.ap["wins"] = {}
	ck("ilk zafer serbest 40", AP.on_victory("free", 1) == 40)
	ck("tekrar %20 = 8", AP.on_victory("free", 1) == 8)
	ck("yeni zorluk +25", AP.on_victory("free", 2) == 25)
	ck("senaryo ilk 60", AP.on_victory("kara", 1) == 60)
	ck("çağ ilk 100", AP.on_victory("ww2", 1) == 100)
	# satın alma (dev sağlayıcı) + jeton tekrarı
	St.ap["bal"] = 0
	var pr := []
	AP.purchase("ap_250", func(ok, g, m): pr.append([ok, g]))
	ck("paket satın alma +250", pr == [[true, 250]] and AP.balance() == 250)
	ck("fulfill aynı jeton ikinci kez 0", AP.fulfill("ap_250", "tok1") == 250 and AP.fulfill("ap_250", "tok1") == 0 and AP.balance() == 500)
	AP.purchase("full_game", func(ok, g, m): pass)
	ck("tam sürüm tüm kilitler açık", AP.scenario_unlocked("siber") and AP.era_unlocked("ww2"))
	AP.purchase("starter", func(ok, g, m): pass)
	ck("başlangıç teklifi bir kez", not AP.starter_available())
	# yayın yapısı: addon yok -> bedava şey yok
	St.ap = {}
	P.force_release = true
	var rr := []
	AP.watch_ad(false, func(ok, g, m): rr.append([ok, g]))
	ck("release: reklam yok, AP verilmez", rr == [[false, 0]] and AP.balance() == 0)
	var rp := []
	AP.purchase("full_game", func(ok, g, m): rp.append(ok))
	ck("release: addon yoksa satın alma yok", rp == [false] and not AP.has_full())
	AP.set_dev_all(true)
	ck("release: dev_all etkisiz", not AP.dev_all() and not AP.scenario_unlocked("siber"))
	P.force_release = false
	# görev bonusu
	St.ap = {}; St.missions = {}
	M.ensure_current()
	var tot_ap := 0
	for k in ["turns", "captures", "battles", "orders", "peace", "alliance", "un", "landing", "strike", "war"]:
		var r = M.add(k, 40)
		tot_ap += int(r.ap)
	print("  görev toplam=", tot_ap, " bakiye=", AP.balance(), " beklenen=", 3 * AP.MISSION_DAILY + 3 * AP.MISSION_WEEKLY + AP.MISSION_DAILY_ALL + AP.MISSION_WEEKLY_ALL)
	ck("görev AP: 3 günlük + 3 haftalık + bonuslar", AP.balance() == tot_ap and tot_ap == 3 * AP.MISSION_DAILY + 3 * AP.MISSION_WEEKLY + AP.MISSION_DAILY_ALL + AP.MISSION_WEEKLY_ALL)
	var again := 0
	for k in ["turns", "captures"]: again += int(M.add(k, 40).ap)
	ck("görev tekrar AP vermez", again == 0)
	# kalıcılık
	St.save_all()
	var b2 := AP.balance()
	St.ap = {}
	St.load_all()
	ck("ayar dosyasından bakiye döner", AP.balance() == b2)
	St.ap = keep; St.missions = keep_m; St.xp = keep_xp
	St.save_all()
	print("FAILS=", fails)
	quit()

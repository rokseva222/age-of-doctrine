extends SceneTree
var main
func _shot(tag: String) -> void:
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/dlg_%s.png" % tag)
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER; St.tut_done = true
	St.ui_scale = float(a[0]); St.ui_scale_custom = true; St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.2).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	var txt := "Mayıs 1919: İstanbul İtilaf işgalinde, Yunan ordusu İzmir'e çıktı, güneyi Fransa ve İtalya tuttu. Mustafa Kemal Samsun'a çıkıp Anadolu'da direniş örgütlüyor. Ya istiklal, ya ölüm. Osmanlı hükûmeti teslimiyetçi, ordular terhis edilmiş, silahlar toplanmış durumda. Kuvâ-yi Millîye çeteleri dağınık; Erzurum ve Sivas kongreleri için delegeler yola çıkıyor. Doğuda Ermeni cephesi, güneyde Fransız işgali, batıda Yunan ilerleyişi var. Hedefin: Sakarya'da düşmanı durdurmak, Büyük Taarruz'la İzmir'i kurtarmak ve Lozan'da egemenliği tanıtmak. Her karar hazine, halk ve ordu dengesini etkiler; ittifak kurarken tarafsızlığını koru ve Moskova'yla ilişkini iyi yönet."
	main.ui.show_dialog("Kurtuluş Savaşı", txt, [{"text": "Başla", "kind": "good", "cb": func(): pass}])
	await _shot(a[0])
	quit()

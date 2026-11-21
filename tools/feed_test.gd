extends SceneTree
func _init():
	var M = load("res://scripts/net_master.gd").new()
	var now := 1000000
	var l1 := JSON.stringify({"k":"aod","ip":"1.2.3.4","port":47320,"name":"Erdem Odası","era":"","players":1,"max":4,"pass":false,"region":"TR","t":now-100,"closed":false})
	var l1b := JSON.stringify({"k":"aod","ip":"1.2.3.4","port":47320,"name":"Erdem Odası","players":2,"max":4,"t":now-10})
	var old := JSON.stringify({"k":"aod","ip":"5.6.7.8","port":47320,"name":"Eski","t":now-5000})
	var closed := JSON.stringify({"k":"aod","ip":"9.9.9.9","port":1,"name":"Kapalı","t":now-5,"closed":true})
	var junk := "bozuk"
	var lines := ""
	for m in [l1, l1b, old, closed, junk]:
		lines += JSON.stringify({"id":"x","event":"message","message":m}) + "\n"
	lines += "not json\n"
	var r: Array = M.parse_feed(lines, now)
	print("n=", r.size(), " ", r)
	print("OK" if r.size()==1 and r[0].players==2 and r[0].ip=="1.2.3.4" else "FAIL")
	quit()

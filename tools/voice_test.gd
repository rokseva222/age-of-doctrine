extends SceneTree
## Sesli görüşme: µ-law codec gidiş-dönüş hatası küçük mü, görüşme odası mantığı doğru mu
const V = preload("res://scripts/voice.gd")
const NetS = preload("res://scripts/net.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _init() -> void:
	var worst := 0.0
	for i in 200:
		var x: float = sin(float(i) * 0.37) * 0.8
		var y: float = V._dec(V._enc(x))
		worst = maxf(worst, absf(x - y) / maxf(absf(x), 0.05))
	ck("µ-law bağıl hata < %%10 (en kötü %.3f)" % worst, worst < 0.10)
	ck("sessizlik ~0", absf(V._dec(V._enc(0.0))) < 0.01)
	var n = NetS.new()
	n.is_server = true
	n.players = {2: {"name": "A", "cid": 5, "pass_ok": true}, 3: {"name": "B", "cid": 6, "pass_ok": true}, 4: {"name": "C", "cid": 7, "pass_ok": true}}
	n.voice_groups = {1: [2, 3, 4]}
	n.voice_of = {2: 1, 3: 1, 4: 1}
	n._voice_remove(3)
	ck("3 ayrılınca oda 2 kişi", n.voice_groups[1].size() == 2 and not n.voice_of.has(3))
	n._voice_remove(4)
	ck("tek kişi kalınca oda kapanır", not n.voice_groups.has(1) and n.voice_of.is_empty())
	print("HATA SAYISI=", fails)
	quit()

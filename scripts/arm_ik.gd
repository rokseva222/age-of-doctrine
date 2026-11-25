extends RefCounted
## İki kemikli sağ kol IK'si (omuz → dirsek → bilek). Herhangi bir insansı iskelette (Mixamo, Tripo, Blender...) kemikleri
## adından bulur ve bileği hedef noktaya götürür; kılıç bileğe ayrı düğüm olarak bağlanır, kemik eksenleri önemli değildir.
## Hedefler iskelet uzayındadır (Skeleton3D yerel koordinatı).

var side := "right"          # "right" | "left"
var upper_pats: Array = []
var fore_pats: Array = []
var hand_pats: Array = []

var skel: Skeleton3D
var up := -1
var fore := -1
var hand := -1
var l1 := 0.0
var l2 := 0.0


static func norm(n: String) -> String:
	var out := ""
	for ch in n.to_lower():
		if ch >= "a" and ch <= "z":
			out += ch
	return out


static func _find(s: Skeleton3D, pats: Array, not_has: Array) -> int:
	for i in s.get_bone_count():
		var n: String = norm(s.get_bone_name(i))
		var bad := false
		for x in not_has:
			if n.contains(String(x)):
				bad = true
		if bad:
			continue
		for pt in pats:
			if n.ends_with(String(pt)):
				return i
	return -1


## Kemikleri bulur ve segment uzunluklarını (dinlenme duruşundan) ölçer. Bulamazsa false. side: "right" | "left".
func setup(s: Skeleton3D, side_: String = "right") -> bool:
	skel = s
	side = side_
	var w: String = side            # right / left
	var c: String = w.left(1)       # r / l
	upper_pats = [w + "arm", w + "upperarm", "upperarm" + c, "upperarm" + w, c + "arm", c + "upperarm", "arm" + c]
	fore_pats = [w + "forearm", w + "lowerarm", "forearm" + c, "lowerarm" + c, "forearm" + w, c + "forearm", c + "lowerarm", "lowerarm" + w]
	hand_pats = [w + "hand", "hand" + c, "hand" + w, c + "hand"]
	if skel == null:
		return false
	fore = _find(skel, fore_pats, [])
	up = _find(skel, upper_pats, ["fore", "lower"])
	hand = _find(skel, hand_pats, [])
	if up < 0 or fore < 0 or hand < 0:
		return false
	var pu: Vector3 = skel.get_bone_global_rest(up).origin
	var pf: Vector3 = skel.get_bone_global_rest(fore).origin
	var ph: Vector3 = skel.get_bone_global_rest(hand).origin
	l1 = pu.distance_to(pf)
	l2 = pf.distance_to(ph)
	return l1 > 0.001 and l2 > 0.001


func shoulder() -> Vector3:
	return skel.get_bone_global_pose(up).origin


func reach() -> float:
	return l1 + l2


## Bileği hedefe götürür (erişilemiyorsa kolu o yönde uzatır). pole: dirseğin yöneleceği taraf (iskelet uzayı noktası).
func solve(target: Vector3, pole: Vector3) -> void:
	if skel == null or up < 0:
		return
	var s: Vector3 = skel.get_bone_global_pose(up).origin
	var d: Vector3 = target - s
	var dist: float = d.length()
	if dist < 0.0001:
		return
	var dir: Vector3 = d / dist
	dist = clampf(dist, absf(l1 - l2) + 0.002, l1 + l2 - 0.002)
	var a: float = (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h: float = sqrt(maxf(l1 * l1 - a * a, 0.0))
	var pv: Vector3 = pole - s
	var perp: Vector3 = pv - dir * pv.dot(dir)
	if perp.length() < 0.0001:
		perp = dir.cross(Vector3.UP)
		if perp.length() < 0.0001:
			perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized()
	var elbow: Vector3 = s + dir * a + perp * h
	var wrist: Vector3 = s + dir * dist
	_aim(up, fore, elbow)
	_aim(fore, hand, wrist)


## bone'un çocuğa giden yönünü (şu anki duruşta) to_pos yönüne çevirir.
func _aim(bone: int, child: int, to_pos: Vector3) -> void:
	var gp: Transform3D = skel.get_bone_global_pose(bone)
	var cur: Vector3 = skel.get_bone_global_pose(child).origin - gp.origin
	var want: Vector3 = to_pos - gp.origin
	if cur.length() < 0.0001 or want.length() < 0.0001:
		return
	var q := Quaternion(cur.normalized(), want.normalized())
	var nb: Basis = (Basis(q) * gp.basis).orthonormalized()
	var parent: int = skel.get_bone_parent(bone)
	var pb: Basis = Basis.IDENTITY if parent < 0 else skel.get_bone_global_pose(parent).basis.orthonormalized()
	skel.set_bone_pose_rotation(bone, (pb.inverse() * nb).get_rotation_quaternion())
	skel.force_update_all_bone_transforms()      # sonraki kemik güncel küresel duruşu görsün


func wrist_pos() -> Vector3:
	return skel.get_bone_global_pose(hand).origin

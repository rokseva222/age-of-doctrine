extends SceneTree
## Kol IK'si: Mixamo ve "_R" adlandırmalı sahte iskeletlerde bilek hedefe ulaşır; erişilemeyen hedefte kol o yönde uzar.
const IK = preload("res://scripts/arm_ik.gd")
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1

func make(names: Array) -> Skeleton3D:
	# kalça, omurga, omuz, kol, ön kol, el: T-pozu, sağ kol +X'e uzanır
	var s := Skeleton3D.new()
	var pos := [Vector3(0, 1.0, 0), Vector3(0, 1.3, 0), Vector3(0.15, 1.5, 0), Vector3(0.30, 1.5, 0), Vector3(0.60, 1.5, 0), Vector3(0.85, 1.5, 0)]
	var par := [-1, 0, 1, 2, 3, 4]
	for i in 6:
		s.add_bone(String(names[i]))
	for i in 6:
		s.set_bone_parent(i, int(par[i]))
		var local: Vector3 = pos[i] - (pos[int(par[i])] if int(par[i]) >= 0 else Vector3.ZERO)
		s.set_bone_rest(i, Transform3D(Basis(), local))
	s.reset_bone_poses()
	return s

func _init() -> void:
	var sets := {
		"mixamo": ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_RightShoulder", "mixamorig_RightArm", "mixamorig_RightForeArm", "mixamorig_RightHand"],
		"underscore": ["Hips", "Spine", "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R"],
		"blender": ["pelvis", "spine_01", "clavicle_r", "upperarm_r", "forearm_r", "hand_r"],
	}
	for k in sets:
		var s: Skeleton3D = make(sets[k])
		root.add_child(s)
		var ik = IK.new()
		ck("%s: kemikler bulundu" % k, ik.setup(s, "right"))
		ck("%s: uzunluklar doğru (%.2f, %.2f)" % [k, ik.l1, ik.l2], absf(ik.l1 - 0.30) < 0.01 and absf(ik.l2 - 0.25) < 0.01)
		var S: Vector3 = ik.shoulder()
		for tgt in [Vector3(0.3, 1.3, 0.35), Vector3(0.45, 1.8, 0.1), Vector3(0.1, 1.45, 0.3), Vector3(0.5, 1.55, 0.2)]:
			var tt: Vector3 = tgt as Vector3
			ik.solve(tt, S + Vector3(0, -1, -0.3))
			var w: Vector3 = ik.wrist_pos()
			var reachable: bool = S.distance_to(tt) < ik.reach() - 0.01 and S.distance_to(tt) > absf(ik.l1 - ik.l2) + 0.01
			if reachable:
				ck("%s: bilek hedefe ulaştı %s (hata %.3f)" % [k, str(tt), w.distance_to(tt)], w.distance_to(tt) < 0.015)
			var e: Vector3 = s.get_bone_global_pose(ik.fore).origin
			ck("%s: kol uzunlukları korundu" % k, absf(S.distance_to(e) - ik.l1) < 0.01 and absf(e.distance_to(w) - ik.l2) < 0.01)
		# erişilemeyen hedef: kol uzar, yön doğru
		var far := S + Vector3(2.0, 0.0, 0.0)
		ik.solve(far, S + Vector3(0, -1, 0))
		var w2: Vector3 = ik.wrist_pos()
		ck("%s: erişilemeyen hedefte kol hedefe doğru uzar (%.2f)" % [k, S.distance_to(w2)], S.distance_to(w2) > ik.reach() - 0.05 and (w2 - S).normalized().dot(Vector3.RIGHT) > 0.99)
		# dirsek kutup yönüne bakar (aşağı)
		ik.solve(S + Vector3(0.0, 0.0, 0.45), S + Vector3(0, -1, 0))
		var el: Vector3 = s.get_bone_global_pose(ik.fore).origin
		ck("%s: dirsek kutup tarafına (aşağı) bükülür" % k, el.y < S.y - 0.02)
		s.queue_free()
	# kemik bulunamazsa
	var bad := Skeleton3D.new()
	bad.add_bone("a")
	ck("kemik yoksa false", not IK.new().setup(bad))
	print("HATA SAYISI=", errs)
	quit()

extends Translation
## Çeviri kancası: her Control metni buradan geçer (bkz. loc.gd).
const Loc = preload("res://scripts/loc.gd")


func _get_message(src: StringName, _ctx: StringName) -> StringName:
	var r: String = Loc.translate(str(src))
	return StringName(r) if r != "" else &""

extends Node

var _walk_by_px:bool = true
var _walk_speed_px:float = 0

func get_walk_speed_px() -> float:
	return _walk_speed_px

func update_walk_speed_px(p_new_speed:float) -> void:
	_walk_speed_px = p_new_speed
	SignalManager.walk_speed_updated.emit()

func walk_by_px() -> bool:
	return _walk_by_px
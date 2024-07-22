extends Node

var _moving = true

var _walk_by_px:bool = true
var _walk_speed_px:float = 0

var _active_path:Array[PathSegment]

func moving() -> bool:
	return _moving

func set_moving(p_moving:bool) -> void:
	_moving = p_moving
	SignalManager.moving_updated.emit()

func toggle_moving() -> void:
	_moving = !_moving
	SignalManager.moving_updated.emit()

func get_walk_speed_px() -> float:
	return _walk_speed_px

func update_walk_speed_px(p_new_speed:float) -> void:
	_walk_speed_px = p_new_speed
	SignalManager.walk_speed_updated.emit()

func walk_by_px() -> bool:
	return _walk_by_px

func is_active_path() -> bool:
	return _active_path.size() > 0
	
func active_path() -> Array[PathSegment]:
	return _active_path

func clear_active_path() -> void:
	_active_path = []

func set_active_path(p_path:Array[PathSegment]) -> void:
	_active_path = p_path

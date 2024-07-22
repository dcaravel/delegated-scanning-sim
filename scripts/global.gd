extends Node

enum Event {START, END, RESET}
enum Pos {TOP, BOT}

const TRAIL_COLOR:Color = Color("afafff", 1.0)
const TRAIL_COLOR_ALT:Color = Color("ffff0f", 1.0)


# TODO: WalkManager?
var walk_by_px:bool = true
var walk_speed_px:float = 0

func get_walk_speed_px() -> float:
	return walk_speed_px

func update_walk_speed_px(p_new_speed:float) -> void:
	walk_speed_px = p_new_speed
	SignalManager.walk_speed_updated.emit()

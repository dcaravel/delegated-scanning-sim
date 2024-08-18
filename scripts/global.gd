extends Node

# Global == Domain, SHOULD NOT depend on other classes

enum Event {START, END, RESET}
enum Pos {TOP, BOT}


# CLUSTER values MUST match the dropdown in the dele registry config
enum CLUSTER {CENTRAL,PROD,DEV,OTHER}
const CLUSTERS=["None","prod","dev","other"]

const TRAIL_COLOR:Color = Color("afafff", 1.0)
const TRAIL_COLOR_ALT:Color = Color("ffff0f", 1.0)

const OVERLAY_ZINDEX:int = 20

const NO_IMAGE_AVAIL_ERR:String = "No image available"

# Delegated Scanning Config Enabled For
const MAX_DELE_CONFIG_REGISTRIES:int = 4
const CENTRAL_CLUSTER_IDX:int = -1
enum ENABLED_FOR {NONE, ALL, SPECIFIC}

class Registry:
	var _path:String
	var _cluster_idx:int

	func _init(p_path:String="", p_cluster_idx:int=CENTRAL_CLUSTER_IDX):
		_path = p_path
		_cluster_idx = p_cluster_idx

	func get_path() -> String:
		return _path
	
	func set_path(p_path:String) -> void:
		_path = p_path
	
	func get_cluster_idx() -> int:
		return _cluster_idx
	
	func set_cluster_idx(p_idx:int) -> void:
		_cluster_idx = p_idx
	
	func match(p_image:String) -> bool:
		return p_image.begins_with(_path)

extends Node

##################
## Walking / Moving
##################
var _moving = true

var _walk_by_px:bool = true
var _walk_speed_px:float = 0

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

##################
## Active Path
##################
var _active_path:Array[PathSegment]

func is_active_path() -> bool:
	return _active_path.size() > 0
	
func active_path() -> Array[PathSegment]:
	return _active_path

func clear_active_path() -> void:
	_active_path = []

func set_active_path(p_path:Array[PathSegment]) -> void:
	_active_path = p_path

##################
## Images
##################
var _images:Array[String] = [
	"docker.io/library/nginx:1.25.0",
	"quay.io/rhacs-eng/main:latest",
	"prod.registry.io/hello/world:stable",
	"dev.registry.io/repo/path:2.0",
]
var _max_images_size = 5
var _default_active_image = 0
var _active_image_idx:int = _default_active_image

func has_images() -> bool:
	return _images.size() > 0
	
func has_image(p_image:String) -> bool:
	for img in _images:
		if img == p_image:
			return true
	
	return false

func get_images() -> Array[String]:
	return _images

func add_image(p_image:String):
	p_image = p_image.strip_edges()
	
	if p_image.is_empty():
		return
		
	if has_image(p_image):
		return
		
	if _images.size() >= _max_images_size:
		return

	_images.append(p_image)
	SignalManager.images_updated.emit()

func delete_image(p_idx:int):
	_images.remove_at(p_idx)

	if _active_image_idx > _images.size()-1:
		_active_image_idx = _images.size()-1

	SignalManager.images_updated.emit()
	set_active_image(_active_image_idx)

func set_active_image(p_image_idx:int) -> void:
	if _images.size() == 0:
		_active_image_idx = _default_active_image
		return

	if p_image_idx > _images.size()-1:
		# do nothing if trying to set an index > max
		return

	if p_image_idx < 0:
		_active_image_idx = 0
	else:
		_active_image_idx = p_image_idx
		
	# print("Active image: ", _active_image, " ", _images[_active_image], " -- ", _images)
	SignalManager.active_image_updated.emit()

func get_active_image_idx() -> int:
	return _active_image_idx
	
func get_active_image() -> String:
	return _images[_active_image_idx]

func at_max_images() -> bool:
	return _images.size() == _max_images_size

#########################
## Current Cluster Click #TODO: Find better name for this
#########################

var _cluster_clicked:int=-1

func set_cluster_clicked(p_cluster_idx:int):
	if p_cluster_idx < -1:
		# Central is -1, can't go below that
		p_cluster_idx = -1
		return
	

	# TODO: Add list of clusters to global config when ready
	# if p_cluster_idx > cluster_list.size():
		# return

	_cluster_clicked = p_cluster_idx

func get_cluster_clicked() -> int:
	return _cluster_clicked

func reset_cluster_clicked() -> void:
	_cluster_clicked = -1

#########################
## Input?
#########################

var keyToAction = {
	KEY_1: Callable(self, "_handleNumKey").bind(0),
	KEY_2: Callable(self, "_handleNumKey").bind(1),
	KEY_3: Callable(self, "_handleNumKey").bind(2),
	KEY_4: Callable(self, "_handleNumKey").bind(3),
	KEY_5: Callable(self, "_handleNumKey").bind(4),
	KEY_6: Callable(self, "_handleNumKey").bind(5),
	KEY_7: Callable(self, "_handleNumKey").bind(6),
	KEY_8: Callable(self, "_handleNumKey").bind(7),
	KEY_9: Callable(self, "_handleNumKey").bind(8),
}

var _key_input_paused:bool = false

func pause_global_num_key_input_processing() -> void:
	_key_input_paused = true

func unpause_global_num_key_input_processing() -> void:
	_key_input_paused = false

func _handleNumKey(p_num:int) -> void:
	if !_key_input_paused:
		set_active_image(p_num)

func _input(event:InputEvent):
	if event is InputEventKey and event.pressed and keyToAction.has(event.keycode):
		keyToAction[event.keycode].call()

func clear_focus(v:Viewport) -> void:
	var c = v.gui_get_focus_owner()
	if c == null:
		return
	c.release_focus()
